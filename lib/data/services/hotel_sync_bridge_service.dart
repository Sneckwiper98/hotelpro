import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../config/app_constants.dart';
import '../../config/supabase_config.dart';
import '../models/pos_model.dart';
import '../models/customer_model.dart';
import '../models/room_model.dart';
import '../models/housekeeping_model.dart';
import '../repositories/hotel_repository.dart';
import 'hotel_config_storage.dart';

/// HotelSyncBridgeService
/// High-Performance Two-Way Synchronization Bridge connecting Android Mobile Apps
/// (Waiter POS, Delivery, Housekeeping, Manager, Guest) with the Windows Desktop ERP Software.
///
/// Features:
/// 1. Local Hotel LAN Sync Server (Runs on Windows ERP, Port 8088)
///    - Zero latency, 100% offline resilient on Hotel Wi-Fi
///    - Android devices push orders/cleanings/deliveries directly to Windows PC
///    - Real-time Server-Sent Events (SSE) broadcast to all connected tablets/phones
/// 2. Cloud Supabase Sync
///    - Synchronizes across internet/cellular 4G/5G when outside hotel Wi-Fi
/// 3. In-Process Shared State
///    - Instant reactive synchronization when running in unified simulation mode
class HotelSyncBridgeService extends ChangeNotifier {
  static final HotelSyncBridgeService instance = HotelSyncBridgeService._internal();
  HotelSyncBridgeService._internal();

  HttpServer? _localServer;
  String? _localIpAddress;
  int _serverPort = 8088;
  bool _isServerRunning = false;
  String _configuredServerHost = const String.fromEnvironment('SERVER_IP', defaultValue: '192.168.0.100');
  bool _isConnectedToHost = false;
  String? _lastSyncTimestamp;
  String _syncEngineMode = 'Offline / Local RAM';
  String? _syncSecurityToken;

  final List<HttpResponse> _sseClients = [];
  StreamSubscription? _supabaseOrdersSub;
  StreamSubscription? _supabaseCustomerOrdersSub;
  StreamSubscription? _supabaseRoomsSub;
  StreamSubscription? _supabaseHkSub;
  StreamSubscription? _supabaseReservationsSub;
  StreamSubscription? _supabaseBillsSub;
  StreamSubscription? _supabaseStockSub;
  Timer? _cloudPollTimer;
  HotelRepository? _attachedRepo;

  HotelRepository? get attachedRepo => _attachedRepo;
  String? get localIpAddress => _localIpAddress;
  int get serverPort => _serverPort;
  bool get isServerRunning => _isServerRunning;
  bool get isConnectedToHost => _isConnectedToHost;
  String get configuredServerHost => _configuredServerHost;
  String? get lastSyncTimestamp => _lastSyncTimestamp;
  String get syncEngineMode => _syncEngineMode;
  int get connectedMobileClientsCount => _sseClients.length;
  String? get syncSecurityToken => _syncSecurityToken;
  bool get isSecurityShieldActive => _syncSecurityToken != null && _syncSecurityToken!.isNotEmpty;

  /// Combined Project Connectivity: Auto-connected via Supabase Cloud and/or Local Windows LAN
  bool get isCloudConnected => SupabaseConfig.isInitialized && SupabaseConfig.client != null;
  bool get isAutoConnected => _isConnectedToHost || isCloudConnected;

  String get connectionTitle {
    if (_isConnectedToHost && isCloudConnected) return 'HotelPro: Cloud & LAN Synced';
    if (_isConnectedToHost) return 'Windows ERP: Local LAN Connected';
    if (isCloudConnected) return 'HotelPro Project: Cloud Auto-Connected';
    return 'Offline Mode (Local RAM)';
  }

  String get connectionStatusSubtitle {
    if (_isConnectedToHost && isCloudConnected) return 'Real-time LAN & Cloud Live Sync Active';
    if (_isConnectedToHost) return 'Local Hotel Wi-Fi • Port $_serverPort';
    if (isCloudConnected) return 'Live Online Sync with Project Database';
    return 'Tap to configure or reconnect';
  }

  /// Binds repository to sync engine
  void attachRepository(HotelRepository repo) {
    _attachedRepo = repo;
    _detectNetworkInterface();
    _loadSyncSecurityToken();
    if (!kIsWeb && Platform.isWindows) {
      startLocalServer(repo);
    } else {
      _loadSavedServerHost(repo);
    }
    _initSupabaseRealtime(repo);
  }

  Future<void> _loadSyncSecurityToken() async {
    try {
      _syncSecurityToken = await HotelConfigStorage.getOrCreateSyncToken();
      notifyListeners();
    } catch (_) {}
  }

  /// Sets Windows ERP host IP for Android Mobile Apps
  void setConfiguredHost(String host) {
    _configuredServerHost = host.trim();
    HotelConfigStorage.saveServerHost(_configuredServerHost);
    testConnectionToHost(_configuredServerHost);
    notifyListeners();
  }

  Future<void> _loadSavedServerHost([HotelRepository? repo]) async {
    final saved = await HotelConfigStorage.loadServerHost();
    if (saved != null && saved.trim().isNotEmpty && saved.trim() != '127.0.0.1') {
      _configuredServerHost = saved.trim();
    } else {
      _configuredServerHost = const String.fromEnvironment('SERVER_IP', defaultValue: '192.168.0.100');
    }
    testConnectionToHost(_configuredServerHost);
    _autoDiscoverHost();
    notifyListeners();
  }

  /// Seamless Auto-Discovery for Android Mobile Devices
  Future<void> _autoDiscoverHost() async {
    // Probe candidates in background without blocking
    if (!_isConnectedToHost) {
      final candidates = ['192.168.0.100', '192.168.1.100', '10.0.2.2', '192.168.0.1', '192.168.1.1'];
      for (final ip in candidates) {
        if (_isConnectedToHost) break;
        if (ip == _configuredServerHost) continue;
        try {
          final ok = await testConnectionToHost(ip);
          if (ok) {
            _configuredServerHost = ip;
            await HotelConfigStorage.saveServerHost(ip);
            debugPrint('[HotelSyncBridge] Auto-discovered Windows ERP at: $ip');
            notifyListeners();
            break;
          }
        } catch (_) {}
      }
    }
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // 1. LOCAL WI-FI NETWORK DISCOVERY & EMBEDDED SERVER (ON WINDOWS ERP)
  // ═════════════════════════════════════════════════════════════════════════════

  Future<void> _detectNetworkInterface() async {
    try {
      if (kIsWeb) return;
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && !addr.isLinkLocal) {
            _localIpAddress = addr.address;
            break;
          }
        }
        if (_localIpAddress != null) break;
      }
      _localIpAddress ??= '127.0.0.1';
      notifyListeners();
    } catch (e) {
      debugPrint('[HotelSyncBridge] Network detection notice: $e');
      _localIpAddress = '127.0.0.1';
    }
  }

  /// Starts the embedded HTTP & SSE Sync Server on Windows ERP
  Future<void> startLocalServer(HotelRepository repo, {int port = 8088}) async {
    if (kIsWeb || _isServerRunning) return;
    _serverPort = port;

    try {
      _localServer = await HttpServer.bind(InternetAddress.anyIPv4, _serverPort);
      _isServerRunning = true;
      _syncEngineMode = '⚡ Local Hotel LAN Server (Active at $_localIpAddress:$_serverPort)';
      debugPrint('[HotelSyncBridge] Master Sync Server listening on $_localIpAddress:$_serverPort');
      notifyListeners();

      _localServer!.listen((HttpRequest request) async {
        _handleIncomingHttpRequest(request, repo);
      });
    } catch (e) {
      debugPrint('[HotelSyncBridge] Failed to bind local server on port $_serverPort: $e');
      // Attempt fallback to 8089 if 8088 is occupied
      if (port == 8088) {
        startLocalServer(repo, port: 8089);
      }
    }
  }

  Future<void> _handleIncomingHttpRequest(HttpRequest request, HotelRepository repo) async {
    // Enable CORS for all local requests
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-HotelPro-Token');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    final path = request.uri.path;

    // Security Gatekeeper: Validate Auth Token for Protected Hotel Operations
    final isPublicRoute = path == '/api/status' ||
        path == '/api/pair' ||
        path.startsWith('/releases/') ||
        path.startsWith('/download/') ||
        path == '/api/aggregator/webhook' ||
        path.startsWith('/api/webhook/');

    if (!isPublicRoute) {
      final incomingToken = request.headers.value('X-HotelPro-Token') ??
          request.headers.value('Authorization')?.replaceFirst('Bearer ', '').trim();

      if (_syncSecurityToken != null && _syncSecurityToken!.isNotEmpty) {
        if (incomingToken == null || incomingToken.trim() != _syncSecurityToken!.trim()) {
          request.response.statusCode = HttpStatus.unauthorized;
          _sendJsonResponse(request.response, {
            'error': 'Access Denied: Shield active. Valid X-HotelPro-Token or Authorization header required.',
            'code': 'UNAUTHORIZED_ACCESS_BLOCKED',
            'timestamp': DateTime.now().toIso8601String(),
          });
          return;
        }
      }
    }

    try {
      // 1. Health & Status
      if (path == '/api/status') {
        _sendJsonResponse(request.response, {
          'status': 'online',
          'server': 'HotelPro Windows Master ERP',
          'hotelName': repo.clientBusinessName,
          'branch': repo.activeBranch.name,
          'localIp': _localIpAddress,
          'port': _serverPort,
          'activeTablesCount': repo.posOrders
              .where((o) => o.status != PosOrderStatus.settled && o.status != PosOrderStatus.cancelled)
              .length,
          'activeOnlineOrders': repo.customerOrders.length,
          'shieldActive': isSecurityShieldActive,
          'timestamp': DateTime.now().toIso8601String(),
        });
        return;
      }

      // 1.2. Staff Device Pairing Handshake
      if (path == '/api/pair' && request.method == 'POST') {
        final content = await utf8.decoder.bind(request).join();
        final data = (content.isNotEmpty ? jsonDecode(content) : <String, dynamic>{}) as Map<String, dynamic>;
        final pin = (data['pin'] ?? data['password'])?.toString().trim();

        if (pin == 'hotel@123' || pin == 'admin' || pin == '1234') {
          _sendJsonResponse(request.response, {
            'success': true,
            'token': _syncSecurityToken ?? '',
            'hotelName': repo.clientBusinessName,
            'message': 'Device successfully paired and authorized with HotelPro Security Shield',
            'timestamp': DateTime.now().toIso8601String(),
          });
        } else {
          request.response.statusCode = HttpStatus.forbidden;
          _sendJsonResponse(request.response, {
            'success': false,
            'error': 'Invalid Security PIN. Access denied.',
          });
        }
        return;
      }

      // 1.5. Direct APK File Download over Wi-Fi LAN
      if (path.startsWith('/releases/') || path.startsWith('/download/')) {
        final fileName = Uri.decodeComponent(path.split('/').last);
        File targetFile = File('releases/$fileName');
        if (!targetFile.existsSync()) {
          targetFile = File('build/app/outputs/flutter-apk/$fileName');
        }
        if (!targetFile.existsSync() && fileName.endsWith('.apk')) {
          targetFile = File('build/app/outputs/flutter-apk/app-release.apk');
        }

        if (targetFile.existsSync()) {
          request.response.headers.contentType = ContentType('application', 'vnd.android.package-archive');
          request.response.headers.add('Content-Disposition', 'attachment; filename="$fileName"');
          await targetFile.openRead().pipe(request.response);
          return;
        } else {
          request.response.statusCode = 404;
          request.response.write('APK file not found on server.');
          await request.response.close();
          return;
        }
      }

      // 2. Full State Snapshot
      if (path == '/api/snapshot') {
        _sendJsonResponse(request.response, {
          'hotelName': repo.clientBusinessName,
          'activeBranch': {
            'id': repo.activeBranch.id,
            'name': repo.activeBranch.name,
            'city': repo.activeBranch.city,
            'phone': repo.activeBranch.phone,
            'gstin': repo.activeBranch.taxIdentifier,
          },
          'posOrders': repo.posOrders.map((o) => _posOrderToMap(o)).toList(),
          'posBills': repo.activeBranchPosBills.map((b) => _posBillToMap(b)).toList(),
          'rooms': repo.activeBranchRooms.map((r) => _roomToMap(r)).toList(),
          'customerOrders': repo.customerOrders.map((co) => _customerOrderToMap(co)).toList(),
          'timestamp': DateTime.now().toIso8601String(),
        });
        return;
      }

      // 3. Waiter POS: Punch KOT
      if (path == '/api/pos/punch' && request.method == 'POST') {
        final content = await utf8.decoder.bind(request).join();
        final data = jsonDecode(content) as Map<String, dynamic>;

        final itemsList = (data['items'] as List<dynamic>? ?? []).map((i) {
          return PosOrderItem(
            menuItemId: i['menuItemId'] ?? 'item-1',
            name: i['name'] ?? 'Item',
            price: (i['price'] as num?)?.toDouble() ?? 0.0,
            quantity: (i['quantity'] as num?)?.toInt() ?? 1,
            notes: i['notes'],
          );
        }).toList();

        final order = repo.punchWaiterKotOrder(
          tableNumber: data['tableNumber'] ?? 'T-01',
          items: itemsList,
          waiterName: data['waiterName'],
          notes: data['notes'],
          guestName: data['guestName'],
          guestPhone: data['guestPhone'],
          guestDob: data['guestDob'],
          guestAddress: data['guestAddress'],
        );

        _broadcastSseEvent('pos_kot_punched', _posOrderToMap(order));
        _sendJsonResponse(request.response, {'success': true, 'order': _posOrderToMap(order)});
        return;
      }

      // 4. Waiter POS: Settle Bill
      if (path == '/api/pos/settle' && request.method == 'POST') {
        final content = await utf8.decoder.bind(request).join();
        final data = jsonDecode(content) as Map<String, dynamic>;

        final settled = repo.settleWaiterTableOrder(
          orderId: data['orderId'] ?? '',
          paymentMethod: data['paymentMethod'] ?? 'Cash',
          discount: (data['discount'] as num?)?.toDouble() ?? 0.0,
        );

        _broadcastSseEvent('pos_bill_settled', _posOrderToMap(settled));
        _sendJsonResponse(request.response, {'success': true, 'order': _posOrderToMap(settled)});
        return;
      }

      // 5. Housekeeping: Update Room
      if (path == '/api/housekeeping/update' && request.method == 'POST') {
        final content = await utf8.decoder.bind(request).join();
        final data = jsonDecode(content) as Map<String, dynamic>;

        final statusCode = data['status'] as String? ?? 'availableClean';
        RoomStatus targetStatus = RoomStatus.availableClean;
        for (final s in RoomStatus.values) {
          if (s.name == statusCode || s.code == statusCode) {
            targetStatus = s;
            break;
          }
        }

        repo.updateRoomHousekeepingStatus(
          roomId: data['roomId'] ?? '',
          newStatus: targetStatus,
          staffName: data['staffName'],
          notes: data['notes'],
        );

        _broadcastSseEvent('room_updated', {'roomId': data['roomId'], 'status': targetStatus.name});
        _sendJsonResponse(request.response, {'success': true});
        return;
      }

      // 6. Online Delivery: Status Transition
      if (path == '/api/delivery/update' && request.method == 'POST') {
        final content = await utf8.decoder.bind(request).join();
        final data = jsonDecode(content) as Map<String, dynamic>;

        final orderId = data['orderId'] as String? ?? '';
        final statusName = data['status'] as String? ?? '';
        CustomerOrderStatus newStatus = CustomerOrderStatus.placed;
        for (final st in CustomerOrderStatus.values) {
          if (st.name == statusName) {
            newStatus = st;
            break;
          }
        }

        repo.updateCustomerOrderStatus(orderId, newStatus);
        _broadcastSseEvent('delivery_updated', {'orderId': orderId, 'status': newStatus.name});
        _sendJsonResponse(request.response, {'success': true});
        return;
      }

      // 6.5. Customer Online Food Order Placement over LAN
      if (path == '/api/customer/order' && request.method == 'POST') {
        final content = await utf8.decoder.bind(request).join();
        final data = jsonDecode(content) as Map<String, dynamic>;

        final itemsList = (data['items'] as List<dynamic>? ?? []).map((i) {
          return CustomerCartItem(
            menuItemId: i['menuItemId'] ?? 'item-1',
            name: i['name'] ?? 'Item',
            price: (i['price'] as num?)?.toDouble() ?? 0.0,
            quantity: (i['quantity'] as num?)?.toInt() ?? 1,
            isVeg: i['isVeg'] ?? true,
          );
        }).toList();

        final newOrder = CustomerFoodOrderModel(
          id: data['orderId'] ?? 'ORD-HP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          branchId: repo.activeBranch.id,
          branchName: repo.activeBranch.name,
          customerId: data['customerId'] ?? 'cust-lan',
          customerName: data['customerName'] ?? 'Guest Customer',
          customerPhone: data['customerPhone'] ?? '+91 99999 88888',
          deliveryAddress: CustomerAddressModel(
            id: 'addr-lan',
            label: data['addressLabel'] ?? 'Delivery Address',
            fullAddress: data['address'] ?? 'Hotel Room / Local Delivery',
            city: repo.activeBranch.city,
            pincode: '400001',
            latitude: 19.1136,
            longitude: 72.8697,
            distanceKmFromHotel: 1.5,
            isWithin10Km: true,
          ),
          items: itemsList,
          itemTotal: (data['itemTotal'] as num?)?.toDouble() ?? 0.0,
          gstAmount: (data['gstAmount'] as num?)?.toDouble() ?? 0.0,
          deliveryFee: (data['deliveryFee'] as num?)?.toDouble() ?? 0.0,
          packagingCharge: (data['packagingCharge'] as num?)?.toDouble() ?? 0.0,
          discountAmount: (data['discountAmount'] as num?)?.toDouble() ?? 0.0,
          couponCodeApplied: data['couponCode'],
          grandTotal: (data['grandTotal'] as num?)?.toDouble() ?? 0.0,
          paymentMethod: OnlinePaymentMethod.cashOnDelivery,
          paymentStatus: OnlinePaymentStatus.success,
          transactionId: data['transactionId'] ?? 'TXN-LAN',
          orderStatus: CustomerOrderStatus.placed,
          createdAt: DateTime.now(),
        );

        repo.addSimulatedCustomerOrder(newOrder);
        _broadcastSseEvent('customer_order_placed', _customerOrderToMap(newOrder));
        _sendJsonResponse(request.response, {'success': true, 'orderId': newOrder.id});
        return;
      }

      // 6.8. Restaurant Aggregator & Middleware Webhooks (Zomato / Swiggy / UrbanPiper / ONDC / Magicpin)
      if ((path == '/api/aggregator/webhook' ||
           path.startsWith('/api/webhook/')) &&
          request.method == 'POST') {
        final content = await utf8.decoder.bind(request).join();
        final data = (content.isNotEmpty ? jsonDecode(content) : <String, dynamic>{}) as Map<String, dynamic>;

        // Determine platform / channel
        String channel = 'Zomato';
        if (path.contains('swiggy') || (data['channel'] as String? ?? '').toLowerCase().contains('swiggy')) {
          channel = 'Swiggy';
        } else if (path.contains('magicpin') || (data['channel'] as String? ?? '').toLowerCase().contains('magicpin')) {
          channel = 'Magicpin';
        } else if (path.contains('ondc') || (data['channel'] as String? ?? '').toLowerCase().contains('ondc')) {
          channel = 'ONDC';
        } else if (path.contains('urbanpiper') || (data['channel'] as String? ?? '').toLowerCase().contains('urbanpiper')) {
          channel = data['platform'] ?? 'UrbanPiper';
        } else if (data.containsKey('channel')) {
          channel = data['channel'].toString();
        }

        final extOrderId = data['order_id'] ?? data['orderId'] ?? '${channel.substring(0, channel.length.clamp(1, 3)).toUpperCase()}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

        // Customer details
        final custMap = data['customer'] is Map<String, dynamic> ? data['customer'] as Map<String, dynamic> : <String, dynamic>{};
        final customerName = custMap['name'] ?? data['customerName'] ?? 'Guest Customer ($channel)';
        final customerPhone = custMap['phone'] ?? data['customerPhone'] ?? '+91 98000 00000';
        final addressStr = custMap['address'] ?? data['deliveryAddress'] ?? 'Delivery Address Provided via $channel';

        // Parse items
        final rawItems = (data['items'] as List<dynamic>? ?? []);
        final itemsList = rawItems.map((i) {
          return CustomerCartItem(
            menuItemId: i['menuItemId']?.toString() ?? i['id']?.toString() ?? 'mi-agg',
            name: i['name']?.toString() ?? i['title']?.toString() ?? 'Deluxe Meal',
            price: (i['price'] as num?)?.toDouble() ?? 250.0,
            quantity: (i['quantity'] as num?)?.toInt() ?? 1,
            isVeg: i['isVeg'] as bool? ?? true,
            cookingInstructions: i['instructions']?.toString() ?? '',
          );
        }).toList();

        if (itemsList.isEmpty) {
          itemsList.add(CustomerCartItem(
            menuItemId: 'mi-agg-1',
            name: 'Chef Special Dum Biryani Combo ($channel)',
            price: 520.0,
            quantity: 1,
            isVeg: false,
          ));
        }

        final double itemTotal = (data['item_total'] ?? data['itemTotal'] as num?)?.toDouble() ??
            itemsList.fold(0.0, (sum, it) => sum + it.subtotal);
        final double gstAmount = (data['gst'] ?? data['gstAmount'] as num?)?.toDouble() ?? (itemTotal * 0.05);
        final double deliveryFee = (data['delivery_fee'] ?? data['deliveryFee'] as num?)?.toDouble() ?? 35.0;
        final double packagingCharge = (data['packaging'] ?? data['packagingCharge'] as num?)?.toDouble() ?? 25.0;
        final double discountAmount = (data['discount'] ?? data['discountAmount'] as num?)?.toDouble() ?? 0.0;
        final double grandTotal = (data['grand_total'] ?? data['grandTotal'] as num?)?.toDouble() ??
            (itemTotal + gstAmount + packagingCharge - discountAmount);

        // Platform commission
        final double commissionPct = channel == 'Zomato' ? 18.0 : (channel == 'Swiggy' ? 20.0 : (channel == 'Magicpin' ? 12.0 : 3.5));
        final double commissionAmount = (data['commission_amount'] ?? data['commissionAmount'] as num?)?.toDouble() ??
            (grandTotal * (commissionPct / 100.0));

        // Rider details provided by platform
        final riderMap = data['rider'] is Map<String, dynamic> ? data['rider'] as Map<String, dynamic> : <String, dynamic>{};
        final riderName = riderMap['name'] ?? data['riderName'] ?? '$channel Rider Assigned';
        final riderPhone = riderMap['phone'] ?? data['riderPhone'] ?? '+91 98765 11223';
        final riderVehicleNo = riderMap['vehicle'] ?? data['riderVehicleNo'] ?? 'MH 02 EV 2026';
        final otp = data['otp']?.toString() ?? '${1000 + DateTime.now().millisecond % 9000}';

        final newOrder = CustomerFoodOrderModel(
          id: 'ORD-AG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          branchId: repo.activeBranch.id,
          branchName: repo.activeBranch.name,
          customerId: 'cust-$channel',
          customerName: customerName.toString(),
          customerPhone: customerPhone.toString(),
          deliveryAddress: CustomerAddressModel(
            id: 'addr-$channel',
            label: '$channel Order Address',
            fullAddress: addressStr.toString(),
            city: repo.activeBranch.city,
            pincode: '400001',
            latitude: 19.1136,
            longitude: 72.8697,
            distanceKmFromHotel: 2.8,
            isWithin10Km: true,
          ),
          items: itemsList,
          itemTotal: itemTotal,
          gstAmount: gstAmount,
          deliveryFee: deliveryFee,
          packagingCharge: packagingCharge,
          discountAmount: discountAmount,
          grandTotal: grandTotal,
          paymentMethod: OnlinePaymentMethod.creditDebitCard,
          paymentStatus: OnlinePaymentStatus.success,
          transactionId: 'TXN-$channel-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          orderStatus: CustomerOrderStatus.placed,
          riderName: riderName.toString(),
          riderPhone: riderPhone.toString(),
          riderVehicleNo: riderVehicleNo.toString(),
          channel: channel,
          aggregatorOrderId: extOrderId.toString(),
          commissionAmount: commissionAmount,
          otp: otp,
          specialInstructions: data['instructions']?.toString() ?? data['specialInstructions']?.toString(),
          createdAt: DateTime.now(),
        );

        repo.addSimulatedCustomerOrder(newOrder);
        _broadcastSseEvent('aggregator_order_received', {
          'orderId': newOrder.id,
          'aggregatorOrderId': extOrderId,
          'channel': channel,
          'customerName': customerName,
          'grandTotal': grandTotal,
          'timestamp': DateTime.now().toIso8601String(),
        });

        _sendJsonResponse(request.response, {
          'status': 'success',
          'acknowledged': true,
          'message': 'Order $extOrderId acknowledged by HotelPro POS',
          'orderId': newOrder.id,
          'channel': channel,
          'grandTotal': grandTotal,
          'hotelName': repo.clientBusinessName,
          'timestamp': DateTime.now().toIso8601String(),
        });
        return;
      }

      // 7. Realtime Server-Sent Events (SSE) Stream
      if (path == '/api/stream') {
        request.response.headers.contentType = ContentType('text', 'event-stream', charset: 'utf-8');
        request.response.headers.set('Cache-Control', 'no-cache, no-transform');
        request.response.headers.set('Connection', 'keep-alive');
        _sseClients.add(request.response);
        notifyListeners();

        request.response.write('event: connected\ndata: {"status":"connected"}\n\n');
        await request.response.flush();

        request.response.done.then((_) {
          _sseClients.remove(request.response);
          notifyListeners();
        });
        return;
      }

      // Default 404
      request.response.statusCode = HttpStatus.notFound;
      request.response.write(jsonEncode({'error': 'Endpoint not found: $path'}));
      await request.response.close();
    } catch (err) {
      debugPrint('[HotelSyncBridge] HTTP Handler Error: $err');
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write(jsonEncode({'error': err.toString()}));
      await request.response.close();
    }
  }

  void _sendJsonResponse(HttpResponse response, Map<String, dynamic> data) async {
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(data));
    await response.close();
  }

  void _broadcastSseEvent(String eventType, Map<String, dynamic> payload) {
    final ssePayload = 'event: $eventType\ndata: ${jsonEncode(payload)}\n\n';
    for (final client in List<HttpResponse>.from(_sseClients)) {
      try {
        client.write(ssePayload);
        client.flush();
      } catch (_) {
        _sseClients.remove(client);
      }
    }
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // 2. MOBILE CLIENT SYNC METHODS (RUNS ON ANDROID PHONES & TABLETS)
  // ═════════════════════════════════════════════════════════════════════════════

  void _applySecurityHeaders(HttpClientRequest req) {
    req.headers.contentType = ContentType.json;
    if (_syncSecurityToken != null && _syncSecurityToken!.isNotEmpty) {
      req.headers.add('X-HotelPro-Token', _syncSecurityToken!);
      req.headers.add('Authorization', 'Bearer $_syncSecurityToken');
    }
  }

  /// Test connection to Windows ERP Server
  Future<bool> testConnectionToHost(String host, {int port = 8088, String pin = 'hotel@123'}) async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final req = await client.getUrl(Uri.parse('http://$host:$port/api/status'));
      final res = await req.close();
      if (res.statusCode == 200) {
        _configuredServerHost = host;
        _isConnectedToHost = true;
        _lastSyncTimestamp = DateTime.now().toIso8601String();
        _syncEngineMode = '🟢 Connected to Windows ERP ($host:$port)';

        // Auto-negotiate security handshake if not yet paired
        if (_syncSecurityToken == null || _syncSecurityToken!.isEmpty) {
          try {
            final pairReq = await client.postUrl(Uri.parse('http://$host:$port/api/pair'));
            pairReq.headers.contentType = ContentType.json;
            pairReq.write(jsonEncode({'pin': pin}));
            final pairRes = await pairReq.close();
            if (pairRes.statusCode == 200) {
              final pairBody = await utf8.decoder.bind(pairRes).join();
              final pairData = jsonDecode(pairBody) as Map<String, dynamic>;
              final token = pairData['token']?.toString();
              if (token != null && token.isNotEmpty) {
                _syncSecurityToken = token;
                await HotelConfigStorage.savePairedSyncToken(token);
                debugPrint('[HotelSyncBridge] Device successfully paired with token: $token');
              }
            }
          } catch (pairErr) {
            debugPrint('[HotelSyncBridge] Auto-pair notice: $pairErr');
          }
        }

        notifyListeners();
        client.close();
        return true;
      }
      client.close();
    } catch (e) {
      debugPrint('[HotelSyncBridge] Host test connection failed: $e');
    }
    _isConnectedToHost = false;
    notifyListeners();
    return false;
  }

  /// Sends KOT order from Android Waiter App to Windows ERP
  Future<bool> sendKotToWindowsErp({
    required String tableNumber,
    required List<PosOrderItem> items,
    String? waiterName,
    String? notes,
    String? guestName,
    String? guestPhone,
    String? guestDob,
    String? guestAddress,
  }) async {
    final payload = {
      'tableNumber': tableNumber,
      'items': items.map((i) => {
        'menuItemId': i.menuItemId,
        'name': i.name,
        'price': i.price,
        'quantity': i.quantity,
        'notes': i.notes,
      }).toList(),
      'waiterName': waiterName,
      'notes': notes,
      'guestName': guestName,
      'guestPhone': guestPhone,
      'guestDob': guestDob,
      'guestAddress': guestAddress,
    };

    // 1. Send to Local Windows ERP Server
    bool localSuccess = false;
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final req = await client.postUrl(Uri.parse('http://$_configuredServerHost:$_serverPort/api/pos/punch'));
      _applySecurityHeaders(req);
      req.write(jsonEncode(payload));
      final res = await req.close();
      if (res.statusCode == 200) {
        localSuccess = true;
        _isConnectedToHost = true;
        _lastSyncTimestamp = DateTime.now().toIso8601String();
      }
      client.close();
    } catch (e) {
      debugPrint('[HotelSyncBridge] Local send failed: $e');
    }

    // 2. Also push to Supabase Cloud if available
    _pushKotToSupabase(payload);

    notifyListeners();
    return localSuccess;
  }

  /// Sends bill settlement from Android Waiter App to Windows ERP
  Future<bool> sendSettleToWindowsErp({
    required String orderId,
    required String paymentMethod,
    double discount = 0.0,
  }) async {
    final payload = {
      'orderId': orderId,
      'paymentMethod': paymentMethod,
      'discount': discount,
    };

    bool localSuccess = false;
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final req = await client.postUrl(Uri.parse('http://$_configuredServerHost:$_serverPort/api/pos/settle'));
      _applySecurityHeaders(req);
      req.write(jsonEncode(payload));
      final res = await req.close();
      if (res.statusCode == 200) {
        localSuccess = true;
        _isConnectedToHost = true;
        _lastSyncTimestamp = DateTime.now().toIso8601String();
      }
      client.close();
    } catch (e) {
      debugPrint('[HotelSyncBridge] Local settle failed: $e');
    }

    notifyListeners();
    return localSuccess;
  }

  /// Sends housekeeping status update from Android App to Windows ERP
  Future<bool> sendHousekeepingUpdateToWindowsErp({
    required String roomId,
    required RoomStatus newStatus,
    String? staffName,
    String? notes,
  }) async {
    final payload = {
      'roomId': roomId,
      'status': newStatus.name,
      'staffName': staffName,
      'notes': notes,
    };

    bool localSuccess = false;
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final req = await client.postUrl(Uri.parse('http://$_configuredServerHost:$_serverPort/api/housekeeping/update'));
      _applySecurityHeaders(req);
      req.write(jsonEncode(payload));
      final res = await req.close();
      if (res.statusCode == 200) {
        localSuccess = true;
        _isConnectedToHost = true;
      }
      client.close();
    } catch (e) {
      debugPrint('[HotelSyncBridge] Local housekeeping update failed: $e');
    }

    return localSuccess;
  }

  /// Sends delivery status update from Android App to Windows ERP
  Future<bool> sendDeliveryUpdateToWindowsErp({
    required String orderId,
    required CustomerOrderStatus status,
  }) async {
    final payload = {
      'orderId': orderId,
      'status': status.name,
    };

    bool localSuccess = false;
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final req = await client.postUrl(Uri.parse('http://$_configuredServerHost:$_serverPort/api/delivery/update'));
      _applySecurityHeaders(req);
      req.write(jsonEncode(payload));
      final res = await req.close();
      if (res.statusCode == 200) {
        localSuccess = true;
      }
      client.close();
    } catch (e) {
      debugPrint('[HotelSyncBridge] Local delivery update failed: $e');
    }

    return localSuccess;
  }

  /// Sends customer food order from mobile Customer App to Windows Desktop ERP over LAN
  Future<bool> sendCustomerOrderToWindowsErp(CustomerFoodOrderModel order) async {
    final payload = {
      'orderId': order.id,
      'customerId': order.customerId,
      'customerName': order.customerName,
      'customerPhone': order.customerPhone,
      'addressLabel': order.deliveryAddress.label,
      'address': order.deliveryAddress.fullAddress,
      'itemTotal': order.itemTotal,
      'gstAmount': order.gstAmount,
      'deliveryFee': order.deliveryFee,
      'packagingCharge': order.packagingCharge,
      'discountAmount': order.discountAmount,
      'couponCode': order.couponCodeApplied,
      'grandTotal': order.grandTotal,
      'transactionId': order.transactionId,
      'items': order.items.map((i) => {
        'menuItemId': i.menuItemId,
        'name': i.name,
        'price': i.price,
        'quantity': i.quantity,
        'isVeg': i.isVeg,
      }).toList(),
    };

    bool localSuccess = false;
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final req = await client.postUrl(Uri.parse('http://$_configuredServerHost:$_serverPort/api/customer/order'));
      _applySecurityHeaders(req);
      req.write(jsonEncode(payload));
      final res = await req.close();
      if (res.statusCode == 200) {
        localSuccess = true;
        _isConnectedToHost = true;
        _lastSyncTimestamp = DateTime.now().toIso8601String();
        notifyListeners();
      }
      client.close();
    } catch (e) {
      debugPrint('[HotelSyncBridge] Local customer order send failed: $e');
    }

    return localSuccess;
  }

  /// Fetches state snapshot from Windows ERP to sync mobile app with current desktop state
  Future<bool> fetchSnapshotFromWindowsErp({HotelRepository? repo}) async {
    final targetRepo = repo ?? _attachedRepo;
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final req = await client.getUrl(Uri.parse('http://$_configuredServerHost:$_serverPort/api/snapshot'));
      _applySecurityHeaders(req);
      final res = await req.close();
      if (res.statusCode == 200) {
        final body = await utf8.decoder.bind(res).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        _isConnectedToHost = true;
        _lastSyncTimestamp = DateTime.now().toIso8601String();

        if (targetRepo != null) {
          // If customer orders present in snapshot, sync into repo
          if (data['customerOrders'] is List) {
            final ordersList = data['customerOrders'] as List;
            for (final o in ordersList) {
              final id = o['id']?.toString() ?? '';
              final exists = targetRepo.customerOrders.any((co) => co.id == id);
              if (!exists) {
                // Add order into customer orders list
                final statusStr = o['orderStatus']?.toString() ?? 'placed';
                CustomerOrderStatus status = CustomerOrderStatus.placed;
                for (final st in CustomerOrderStatus.values) {
                  if (st.name == statusStr) {
                    status = st;
                    break;
                  }
                }

                targetRepo.addSimulatedCustomerOrder(
                  CustomerFoodOrderModel(
                    id: id,
                    branchId: targetRepo.activeBranch.id,
                    branchName: targetRepo.activeBranch.name,
                    customerId: 'cust-snapshot',
                    customerName: o['customerName'] ?? 'Customer',
                    customerPhone: o['customerPhone'] ?? '+91 99999 00000',
                    deliveryAddress: CustomerAddressModel(
                      id: 'addr-snap',
                      label: 'Delivery Address',
                      fullAddress: 'Local Address',
                      city: targetRepo.activeBranch.city,
                      pincode: '400001',
                      latitude: 19.1136,
                      longitude: 72.8697,
                      distanceKmFromHotel: 2.0,
                      isWithin10Km: true,
                    ),
                    items: const [],
                    itemTotal: (o['grandTotal'] as num?)?.toDouble() ?? 0.0,
                    gstAmount: 0.0,
                    deliveryFee: 0.0,
                    packagingCharge: 0.0,
                    grandTotal: (o['grandTotal'] as num?)?.toDouble() ?? 0.0,
                    paymentMethod: OnlinePaymentMethod.cashOnDelivery,
                    paymentStatus: OnlinePaymentStatus.success,
                    transactionId: 'TXN-SNAP',
                    orderStatus: status,
                    riderName: o['riderName'],
                    createdAt: DateTime.tryParse(o['createdAt'] ?? '') ?? DateTime.now(),
                  ),
                );
              }
            }
          }
          targetRepo.notifyListeners();
        }

        notifyListeners();
        client.close();
        return true;
      }
      client.close();
    } catch (e) {
      debugPrint('[HotelSyncBridge] Snapshot fetch error: $e');
    }
    return false;
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // 3. SUPABASE CLOUD SYNCHRONIZATION LAYER
  // ═════════════════════════════════════════════════════════════════════════════

  void _initSupabaseRealtime(HotelRepository repo) {
    if (!SupabaseConfig.isInitialized || SupabaseConfig.client == null) {
      debugPrint('[HotelSyncBridge] Supabase not in live cluster mode. Using Local LAN Sync Engine.');
      return;
    }

    try {
      final client = SupabaseConfig.client!;

      // 1. Stream pos_orders changes (Real-time live synchronization for Waiter, POS, Kitchen)
      _supabaseOrdersSub?.cancel();
      _supabaseOrdersSub = client.from('pos_orders').stream(primaryKey: ['id']).listen((data) {
        debugPrint('[HotelSyncBridge] Supabase Realtime received ${data.length} pos_orders');
        for (final row in data) {
          final orderId = row['id']?.toString() ?? '';
          final orderNum = row['order_number']?.toString() ?? '';
          final statusStr = row['status']?.toString() ?? 'kot_printed';
          PosOrderStatus status = PosOrderStatus.kotPrinted;
          for (final s in PosOrderStatus.values) {
            if (s.name == statusStr || s.code == statusStr) {
              status = s;
              break;
            }
          }

          final existingIdx = repo.posOrders.indexWhere((o) => o.id == orderId || o.orderNumber == orderNum);
          if (existingIdx != -1) {
            if (repo.posOrders[existingIdx].status != status) {
              repo.posOrders[existingIdx] = repo.posOrders[existingIdx].copyWith(status: status);
              repo.notifyListeners();
            }
          } else {
            // New live order punched from another phone or Windows ERP!
            try {
              final newOrder = PosOrderModel.fromJson(row);
              repo.posOrders.insert(0, newOrder);
              repo.notifyListeners();
            } catch (e) {
              debugPrint('[HotelSyncBridge] Error parsing incoming pos_order: $e');
            }
          }
        }
      }, onError: (e) {
        debugPrint('[HotelSyncBridge] Supabase Realtime pos_orders fallback: $e');
      });

      // 2. Stream customer_orders changes (Customer App, Delivery Boy, Kitchen KDS, Windows ERP)
      _supabaseCustomerOrdersSub?.cancel();
      _supabaseCustomerOrdersSub = client.from('customer_orders').stream(primaryKey: ['id']).listen((data) {
        debugPrint('[HotelSyncBridge] Supabase Realtime received ${data.length} customer_orders');
        for (final row in data) {
          final orderId = row['id']?.toString() ?? '';
          final existingIdx = repo.customerOrders.indexWhere((o) => o.id == orderId);
          if (existingIdx != -1) {
            try {
              final updated = CustomerFoodOrderModel.fromJson(row);
              repo.customerOrders[existingIdx] = updated;
              repo.notifyListeners();
            } catch (_) {}
          } else {
            try {
              final newOrder = CustomerFoodOrderModel.fromJson(row);
              repo.customerOrders.insert(0, newOrder);
              repo.notifyListeners();
            } catch (e) {
              debugPrint('[HotelSyncBridge] Error parsing incoming customer_order: $e');
            }
          }
        }
      }, onError: (e) {
        debugPrint('[HotelSyncBridge] Supabase Realtime customer_orders fallback: $e');
      });

      // 3. Stream rooms changes (Live room status sync across Front Desk, Housekeeping, Manager)
      _supabaseRoomsSub?.cancel();
      _supabaseRoomsSub = client.from('rooms').stream(primaryKey: ['id']).listen((data) {
        for (final row in data) {
          final roomId = row['id']?.toString() ?? '';
          final existingIdx = repo.rooms.indexWhere((r) => r.id == roomId);
          if (existingIdx != -1) {
            try {
              final statusStr = row['status']?.toString() ?? 'available_clean';
              final newStatus = RoomStatus.fromCode(statusStr);
              if (repo.rooms[existingIdx].status != newStatus) {
                repo.rooms[existingIdx] = repo.rooms[existingIdx].copyWith(
                  status: newStatus,
                  notes: row['notes']?.toString() ?? repo.rooms[existingIdx].notes,
                  currentGuestName: row['current_guest_name']?.toString(),
                  currentReservationId: row['current_reservation_id']?.toString(),
                );
                repo.notifyListeners();
              }
            } catch (_) {}
          }
        }
      }, onError: (e) {
        debugPrint('[HotelSyncBridge] Supabase Realtime rooms fallback: $e');
      });

      // 4. Stream housekeeping_tasks changes
      _supabaseHkSub?.cancel();
      _supabaseHkSub = client.from('housekeeping_tasks').stream(primaryKey: ['id']).listen((data) {
        for (final row in data) {
          final taskId = row['id']?.toString() ?? '';
          final existingIdx = repo.housekeepingTasks.indexWhere((t) => t.id == taskId);
          if (existingIdx != -1) {
            try {
              repo.housekeepingTasks[existingIdx] = HousekeepingTaskModel.fromJson(row);
              repo.notifyListeners();
            } catch (_) {}
          } else {
            try {
              repo.housekeepingTasks.insert(0, HousekeepingTaskModel.fromJson(row));
              repo.notifyListeners();
            } catch (_) {}
          }
        }
      }, onError: (e) {
        debugPrint('[HotelSyncBridge] Supabase Realtime housekeeping fallback: $e');
      });

      // 5. Stream reservations changes
      _supabaseReservationsSub?.cancel();
      _supabaseReservationsSub = client.from('reservations').stream(primaryKey: ['id']).listen((data) {
        debugPrint('[HotelSyncBridge] Supabase Realtime received ${data.length} reservations');
        repo.fetchFromSupabase();
      }, onError: (e) {
        debugPrint('[HotelSyncBridge] Supabase Realtime reservations fallback: $e');
      });

      // 6. Stream pos_bills changes
      _supabaseBillsSub?.cancel();
      _supabaseBillsSub = client.from('pos_bills').stream(primaryKey: ['id']).listen((data) {
        debugPrint('[HotelSyncBridge] Supabase Realtime received ${data.length} pos_bills');
        repo.fetchFromSupabase();
      }, onError: (e) {
        debugPrint('[HotelSyncBridge] Supabase Realtime pos_bills fallback: $e');
      });

      // 7. Stream stock_items changes
      _supabaseStockSub?.cancel();
      _supabaseStockSub = client.from('stock_items').stream(primaryKey: ['id']).listen((data) {
        debugPrint('[HotelSyncBridge] Supabase Realtime received ${data.length} stock_items');
        repo.fetchFromSupabase();
      }, onError: (e) {
        debugPrint('[HotelSyncBridge] Supabase Realtime stock_items fallback: $e');
      });

      // 8. Periodic Background Live Cloud Refresh (Ensures full data sync every 10 seconds)
      _cloudPollTimer?.cancel();
      _cloudPollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        if (SupabaseConfig.isInitialized && SupabaseConfig.client != null) {
          repo.fetchFromSupabase();
        }
      });
    } catch (e) {
      debugPrint('[HotelSyncBridge] Supabase setup fallback: $e');
    }
  }

  Future<void> _pushKotToSupabase(Map<String, dynamic> payload) async {
    if (!SupabaseConfig.isInitialized || SupabaseConfig.client == null) return;
    try {
      final client = SupabaseConfig.client!;
      final id = 'kot-${DateTime.now().millisecondsSinceEpoch}';
      await client.from('pos_orders').upsert({
        'id': id,
        'order_number': 'KOT-WTR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        'table_number': payload['tableNumber'] ?? 'T-01',
        'status': 'kot_printed',
        'items': payload['items'],
        'subtotal': 0.0,
        'tax': 0.0,
        'total': 0.0,
      });
      debugPrint('[HotelSyncBridge] KOT pushed to Supabase Cloud.');
    } catch (e) {
      debugPrint('[HotelSyncBridge] Cloud push skipped/fallback: $e');
    }
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // 4. MAP SERIALIZATION HELPERS
  // ═════════════════════════════════════════════════════════════════════════════

  Map<String, dynamic> _posOrderToMap(PosOrderModel o) {
    return {
      'id': o.id,
      'outletId': o.outletId,
      'orderNumber': o.orderNumber,
      'tableNumber': o.tableNumber,
      'guestName': o.guestName,
      'status': o.status.name,
      'statusLabel': o.status.label,
      'subtotal': o.subtotal,
      'tax': o.tax,
      'total': o.total,
      'createdAt': o.createdAt.toIso8601String(),
      'items': o.items.map((i) => {
        'menuItemId': i.menuItemId,
        'name': i.name,
        'price': i.price,
        'quantity': i.quantity,
        'notes': i.notes,
      }).toList(),
    };
  }

  Map<String, dynamic> _posBillToMap(PosBillRecord b) {
    return {
      'id': b.id,
      'billNumber': b.billNumber,
      'billingType': b.billingType.name,
      'outletName': b.outletName,
      'tableNumber': b.tableNumber,
      'waiterName': b.waiterName,
      'subtotal': b.subtotal,
      'taxAmount': b.taxAmount,
      'totalAmount': b.totalAmount,
      'paymentMethod': b.paymentMethod,
      'paymentStatus': b.paymentStatus,
      'createdAt': b.createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _roomToMap(RoomModel r) {
    return {
      'id': r.id,
      'roomNumber': r.roomNumber,
      'floorNumber': r.floorNumber,
      'roomTypeId': r.roomTypeId,
      'status': r.status.name,
      'statusLabel': r.status.label,
      'notes': r.notes,
    };
  }

  Map<String, dynamic> _customerOrderToMap(CustomerFoodOrderModel co) {
    return {
      'id': co.id,
      'customerName': co.customerName,
      'customerPhone': co.customerPhone,
      'orderStatus': co.orderStatus.name,
      'grandTotal': co.grandTotal,
      'paymentMethod': co.paymentMethod.toString(),
      'riderName': co.riderName,
      'channel': co.channel,
      'aggregatorOrderId': co.aggregatorOrderId,
      'commissionAmount': co.commissionAmount,
      'otp': co.otp,
      'createdAt': co.createdAt.toIso8601String(),
    };
  }

  @override
  void dispose() {
    _localServer?.close();
    _supabaseOrdersSub?.cancel();
    super.dispose();
  }
}
