import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../config/app_constants.dart';
import '../services/hotel_config_storage.dart';
import '../models/branch_model.dart';
import '../models/room_model.dart';
import '../models/guest_model.dart';
import '../models/reservation_model.dart';
import '../models/folio_model.dart';
import '../models/pos_model.dart';
import '../models/housekeeping_model.dart';
import '../models/staff_model.dart';
import '../models/user_model.dart';
import '../models/customer_model.dart';
import '../models/invoice_model.dart';
import '../models/accounting_model.dart';
import '../models/inventory_model.dart';
import '../models/android_app_config.dart';
import '../services/geofence_service.dart';
import '../services/mock_hotel_data.dart';
import '../services/hotel_sync_bridge_service.dart';
import '../../config/supabase_config.dart';

class HotelRepository extends ChangeNotifier {
  final _uuid = const Uuid();

  // Master State In-Memory
  late List<BranchModel> _branches;
  late List<RoomTypeModel> _roomTypes;
  late List<RoomModel> _rooms;
  late List<GuestModel> _guests;
  late List<ReservationModel> _reservations;
  late List<FolioModel> _folios;
  late List<PosOutletModel> _posOutlets;
  late List<PosMenuItemModel> _posMenuItems;
  late List<PosOrderModel> _posOrders;
  List<BanquetHallModel> _banquetHalls = List.from(MockHotelData.initialBanquetHalls);
  List<PosBillRecord> _posBills = MockHotelData.getInitialPosBills();
  late List<HousekeepingTaskModel> _housekeepingTasks;
  late List<StaffModel> _staff;
  late List<AppUserModel> _appUsers;
  late AppUserModel _currentErpUser;
  // Floor list (per branch): "branchId|floorNumber" -> floorName
  late List<Map<String, dynamic>> _floors;
  // Accounting & Finance State (Purchases, Operating Expenses & Balance Sheet)
  late List<PurchaseEntry> _purchases;
  late List<ExpenseEntry> _expenses;
  // Stock & Inventory State
  late List<StockItemModel> _stockItems;
  // Online Delivery & Customer CRM State
  List<ErpInvoiceRecord> _invoices = [];

  late BranchModel _activeBranch;

  // Customer & Food Delivery State
  CustomerModel? _currentCustomer;
  CustomerAddressModel? _selectedDeliveryAddress;
  final List<CustomerCartItem> _customerCart = [];
  String? _appliedCouponCode;
  double _couponDiscountPercentage = 0.0;
  final List<CustomerFoodOrderModel> _customerOrders = [];
  List<DeliveryRiderModel> _deliveryRiders = [];
  String? _latestGeneratedOtp = '123456';
  String? _lastOtpChannel;
  String? _lastOtpDestination;

  // ── iSecure Systems Developer & Reseller Whitelabel State ───────────────
  String _clientBusinessName = 'The Grand Imperial Palace';
  String _clientTagline = 'Luxury Hotel, Suites & 5-Star Fine Dining';
  String _clientLicenseKey = 'ISECURE-HTPRO-2026-X892-LIFETIME';
  String _clientLicenseType = 'Perpetual Lifetime License';
  String _clientLicenseExpiry = '2099-12-31';
  String _clientContactPerson = 'General Manager';
  final String _resellerVendor = 'iSecure Systems';
  final String _resellerContact = '+91 98765 43210';
  bool _moduleRoomsEnabled = true;
  bool _modulePosEnabled = true;
  bool _moduleHousekeepingEnabled = true;
  bool _moduleCrsEnabled = true;
  bool _moduleBanquetEnabled = true;
  bool _moduleCustomerAppEnabled = true;
  double _roomGstRate = 12.0;
  double _foodGstRate = 5.0;
  Uint8List? _clientLogoBytes;
  String? _clientLogoPath;
  List<AndroidAppConfig> _androidAppsConfig = [];

  String get clientBusinessName => _clientBusinessName;
  String get clientTagline => _clientTagline;
  String get clientLicenseKey => _clientLicenseKey;
  String get clientLicenseType => _clientLicenseType;
  String get clientLicenseExpiry => _clientLicenseExpiry;
  String get clientContactPerson => _clientContactPerson;
  String get resellerVendor => _resellerVendor;
  String get resellerContact => _resellerContact;
  bool get moduleRoomsEnabled => _moduleRoomsEnabled;
  bool get modulePosEnabled => _modulePosEnabled;
  bool get moduleHousekeepingEnabled => _moduleHousekeepingEnabled;
  bool get moduleCrsEnabled => _moduleCrsEnabled;
  bool get moduleBanquetEnabled => _moduleBanquetEnabled;
  bool get moduleCustomerAppEnabled => _moduleCustomerAppEnabled;
  double get roomGstRate => _roomGstRate;
  double get foodGstRate => _foodGstRate;
  Uint8List? get clientLogoBytes => _clientLogoBytes;
  String? get clientLogoPath => _clientLogoPath;
  List<AndroidAppConfig> get androidAppsConfig => _androidAppsConfig;

  AndroidAppConfig getAndroidAppConfig(String appId) {
    if (_androidAppsConfig.isEmpty) _initDefaultAndroidConfigs();
    final match = _androidAppsConfig.where((c) => c.appId == appId);
    if (match.isNotEmpty) return match.first;

    // Check defaults if not found in loaded config
    final defaults = _getDefaultAndroidConfigsList();
    final defMatch = defaults.where((c) => c.appId == appId);
    if (defMatch.isNotEmpty) {
      _androidAppsConfig.add(defMatch.first);
      return defMatch.first;
    }
    return _androidAppsConfig.isNotEmpty
        ? _androidAppsConfig.first
        : _getDefaultAndroidConfigsList().first;
  }

  List<AndroidAppConfig> _getDefaultAndroidConfigsList() {
    final hotelName = _clientBusinessName;
    final address = _activeBranch.address;
    final city = _activeBranch.city;
    final state = _activeBranch.state;
    final phone = _activeBranch.phone;
    final gstin = _activeBranch.taxIdentifier;

    return [
      AndroidAppConfig(
        appId: 'customer',
        appTitle: 'Customer Food & Room Dining App',
        appName: '$hotelName – Food Order',
        packageName: 'com.isecuresystem.hotelpro.customer',
        versionName: 'v4.9.2',
        versionCode: 49,
        hotelName: hotelName,
        hotelTagline: _clientTagline,
        hotelAddress: address,
        hotelCity: city,
        hotelState: state,
        hotelPhone: phone,
        hotelGstin: gstin,
        hotelFssai: '11521000000001',
        supportEmail: _activeBranch.email,
        logoPreset: 'royal_palace',
        lastBuiltDate: DateTime.now().subtract(const Duration(days: 3)),
        apkFileSize: '48.5 MB',
      ),
      AndroidAppConfig(
        appId: 'waiter',
        appTitle: 'Staff Waiter & Captain POS App',
        appName: '$hotelName – Waiter',
        packageName: 'com.isecuresystem.hotelpro.waiter',
        versionName: 'v4.9.2',
        versionCode: 49,
        hotelName: hotelName,
        hotelTagline: _clientTagline,
        hotelAddress: address,
        hotelCity: city,
        hotelState: state,
        hotelPhone: phone,
        hotelGstin: gstin,
        hotelFssai: '11521000000002',
        supportEmail: _activeBranch.email,
        logoPreset: 'fine_dining',
        lastBuiltDate: DateTime.now().subtract(const Duration(days: 3)),
        apkFileSize: '42.1 MB',
      ),
      AndroidAppConfig(
        appId: 'housekeeping',
        appTitle: 'Housekeeping & Room Inspection App',
        appName: '$hotelName – Housekeeping',
        packageName: 'com.isecuresystem.hotelpro.housekeeping',
        versionName: 'v4.9.2',
        versionCode: 49,
        hotelName: hotelName,
        hotelTagline: _clientTagline,
        hotelAddress: address,
        hotelCity: city,
        hotelState: state,
        hotelPhone: phone,
        hotelGstin: gstin,
        hotelFssai: '',
        supportEmail: _activeBranch.email,
        logoPreset: 'butler_bell',
        lastBuiltDate: DateTime.now().subtract(const Duration(days: 3)),
        apkFileSize: '38.7 MB',
      ),
      AndroidAppConfig(
        appId: 'manager',
        appTitle: 'Owner & Manager Live ERP MIS App',
        appName: '$hotelName – Manager',
        packageName: 'com.isecuresystem.hotelpro.manager',
        versionName: 'v4.9.2',
        versionCode: 49,
        hotelName: hotelName,
        hotelTagline: _clientTagline,
        hotelAddress: address,
        hotelCity: city,
        hotelState: state,
        hotelPhone: phone,
        hotelGstin: gstin,
        hotelFssai: '',
        supportEmail: _activeBranch.email,
        logoPreset: 'express_delivery',
        lastBuiltDate: DateTime.now().subtract(const Duration(days: 3)),
        apkFileSize: '55.2 MB',
      ),
      AndroidAppConfig(
        appId: 'delivery_boy',
        appTitle: 'Delivery Boy & Rider Partner App',
        appName: '$hotelName – Rider',
        packageName: 'com.isecuresystem.hotelpro.rider',
        versionName: 'v4.9.2',
        versionCode: 49,
        hotelName: hotelName,
        hotelTagline: _clientTagline,
        hotelAddress: address,
        hotelCity: city,
        hotelState: state,
        hotelPhone: phone,
        hotelGstin: gstin,
        hotelFssai: '11521000000009',
        supportEmail: _activeBranch.email,
        logoPreset: 'express_delivery',
        lastBuiltDate: DateTime.now().subtract(const Duration(days: 3)),
        apkFileSize: '36.4 MB',
      ),
    ];
  }

  void _initDefaultAndroidConfigs() {
    _androidAppsConfig = _getDefaultAndroidConfigsList();
  }

  void updateAndroidAppConfig(AndroidAppConfig updated) {
    final idx = _androidAppsConfig.indexWhere((c) => c.appId == updated.appId);
    if (idx != -1) {
      _androidAppsConfig[idx] = updated;
    } else {
      _androidAppsConfig.add(updated);
    }
    // Persist the full config with the updated android apps list
    HotelConfigStorage.saveConfig(
      businessName: _clientBusinessName,
      tagline: _clientTagline,
      address: _activeBranch.address,
      city: _activeBranch.city,
      state: _activeBranch.state,
      phone: _activeBranch.phone,
      email: _activeBranch.email,
      gstin: _activeBranch.taxIdentifier,
      currency: _activeBranch.currency,
      licenseKey: _clientLicenseKey,
      licenseType: _clientLicenseType,
      expiryDate: _clientLicenseExpiry,
      contactPerson: _clientContactPerson,
      enableRooms: _moduleRoomsEnabled,
      enablePos: _modulePosEnabled,
      enableHousekeeping: _moduleHousekeepingEnabled,
      enableCrs: _moduleCrsEnabled,
      enableBanquet: _moduleBanquetEnabled,
      enableCustomerApp: _moduleCustomerAppEnabled,
      roomGst: _roomGstRate,
      foodGst: _foodGstRate,
      logoBytes: _clientLogoBytes,
      logoPath: _clientLogoPath,
      androidAppsConfig: _androidAppsConfig.map((c) => c.toJson()).toList(),
    );
    notifyListeners();
  }

  void updateClientBusinessConfig({
    required String businessName,
    required String tagline,
    required String address,
    required String city,
    required String state,
    required String phone,
    required String email,
    required String gstin,
    required String currency,
    required String licenseKey,
    required String licenseType,
    required String expiryDate,
    required String contactPerson,
    required bool enableRooms,
    required bool enablePos,
    required bool enableHousekeeping,
    required bool enableCrs,
    required bool enableBanquet,
    required bool enableCustomerApp,
    required double roomGst,
    required double foodGst,
    Uint8List? logoBytes,
    String? logoPath,
    bool resetLogo = false,
  }) {
    _clientBusinessName = businessName;
    _clientTagline = tagline;
    _clientLicenseKey = licenseKey;
    _clientLicenseType = licenseType;
    _clientLicenseExpiry = expiryDate;
    _clientContactPerson = contactPerson;
    _moduleRoomsEnabled = enableRooms;
    _modulePosEnabled = enablePos;
    _moduleHousekeepingEnabled = enableHousekeeping;
    _moduleCrsEnabled = enableCrs;
    _moduleBanquetEnabled = enableBanquet;
    _moduleCustomerAppEnabled = enableCustomerApp;
    _roomGstRate = roomGst;
    _foodGstRate = foodGst;
    if (resetLogo) {
      _clientLogoBytes = null;
      _clientLogoPath = null;
    } else if (logoBytes != null && logoBytes.isNotEmpty) {
      _clientLogoBytes = logoBytes;
      _clientLogoPath = logoPath;
    } else if (logoPath != null) {
      _clientLogoPath = logoPath;
    }

    // Synchronize into the active branch
    _activeBranch = _activeBranch.copyWith(
      name: businessName,
      address: address,
      city: city,
      state: state,
      phone: phone,
      email: email,
      taxIdentifier: gstin,
      currency: currency,
    );

    // Also update in branches list
    final idx = _branches.indexWhere((b) => b.id == _activeBranch.id);
    if (idx != -1) {
      _branches[idx] = _activeBranch;
    }

    if (SupabaseConfig.isInitialized && SupabaseConfig.client != null) {
      SupabaseConfig.client!.from('branches').update({
        'name': businessName,
        'address': address,
        'city': city,
        'state': state,
        'phone': phone,
        'email': email,
        'tax_identifier': gstin,
        'currency': currency,
      }).eq('id', _activeBranch.id).then((_) {}).catchError((_) {});
    }

    // Persist configuration to disk
    HotelConfigStorage.saveConfig(
      businessName: businessName,
      tagline: tagline,
      address: address,
      city: city,
      state: state,
      phone: phone,
      email: email,
      gstin: gstin,
      currency: currency,
      licenseKey: licenseKey,
      licenseType: licenseType,
      expiryDate: expiryDate,
      contactPerson: contactPerson,
      enableRooms: enableRooms,
      enablePos: enablePos,
      enableHousekeeping: enableHousekeeping,
      enableCrs: enableCrs,
      enableBanquet: enableBanquet,
      enableCustomerApp: enableCustomerApp,
      roomGst: roomGst,
      foodGst: foodGst,
      logoBytes: _clientLogoBytes,
      logoPath: _clientLogoPath,
      androidAppsConfig: _androidAppsConfig.map((c) => c.toJson()).toList(),
    );

    notifyListeners();
  }

  Future<void> _loadSavedBusinessConfig() async {
    try {
      final config = await HotelConfigStorage.loadConfig();
      if (config != null) {
        _clientBusinessName = config['businessName'] as String? ?? _clientBusinessName;
        _clientTagline = config['tagline'] as String? ?? _clientTagline;
        _clientLicenseKey = config['licenseKey'] as String? ?? _clientLicenseKey;
        _clientLicenseType = config['licenseType'] as String? ?? _clientLicenseType;
        _clientLicenseExpiry = config['expiryDate'] as String? ?? _clientLicenseExpiry;
        _clientContactPerson = config['contactPerson'] as String? ?? _clientContactPerson;
        _moduleRoomsEnabled = config['enableRooms'] as bool? ?? _moduleRoomsEnabled;
        _modulePosEnabled = config['enablePos'] as bool? ?? _modulePosEnabled;
        _moduleHousekeepingEnabled = config['enableHousekeeping'] as bool? ?? _moduleHousekeepingEnabled;
        _moduleCrsEnabled = config['enableCrs'] as bool? ?? _moduleCrsEnabled;
        _moduleBanquetEnabled = config['enableBanquet'] as bool? ?? _moduleBanquetEnabled;
        _moduleCustomerAppEnabled = config['enableCustomerApp'] as bool? ?? _moduleCustomerAppEnabled;
        _roomGstRate = (config['roomGst'] as num?)?.toDouble() ?? _roomGstRate;
        _foodGstRate = (config['foodGst'] as num?)?.toDouble() ?? _foodGstRate;

        if (config['logoBase64'] != null) {
          try {
            _clientLogoBytes = base64Decode(config['logoBase64'] as String);
          } catch (_) {}
        }
        _clientLogoPath = config['logoPath'] as String?;

        _activeBranch = _activeBranch.copyWith(
          name: _clientBusinessName,
          address: config['address'] as String? ?? _activeBranch.address,
          city: config['city'] as String? ?? _activeBranch.city,
          state: config['state'] as String? ?? _activeBranch.state,
          phone: config['phone'] as String? ?? _activeBranch.phone,
          email: config['email'] as String? ?? _activeBranch.email,
          taxIdentifier: config['gstin'] as String? ?? _activeBranch.taxIdentifier,
          currency: config['currency'] as String? ?? _activeBranch.currency,
        );

        final idx = _branches.indexWhere((b) => b.id == _activeBranch.id);
        if (idx != -1) {
          _branches[idx] = _activeBranch;
        }

        if (config['androidAppsConfig'] != null) {
          try {
            final rawList = config['androidAppsConfig'] as List;
            _androidAppsConfig = rawList
                .map((item) => AndroidAppConfig.fromJson(item as Map<String, dynamic>))
                .toList();
          } catch (_) {}
        }
        if (_androidAppsConfig.isEmpty) {
          _initDefaultAndroidConfigs();
        } else {
          // Ensure all 5 mobile app configs exist in loaded config
          final defaults = _getDefaultAndroidConfigsList();
          for (final def in defaults) {
            if (!_androidAppsConfig.any((c) => c.appId == def.appId)) {
              _androidAppsConfig.add(def);
            }
          }
        }

        notifyListeners();
      }
    } catch (_) {}
  }

  HotelRepository() {
    _initData();
    HotelSyncBridgeService.instance.attachRepository(this);
    fetchFromSupabase();
  }

  bool _isFetchingFromSupabase = false;
  bool get isFetchingFromSupabase => _isFetchingFromSupabase;

  /// Fetches live data records from online Supabase cloud PostgreSQL cluster
  Future<void> fetchFromSupabase() async {
    if (!SupabaseConfig.isInitialized || SupabaseConfig.client == null) {
      debugPrint('[HotelRepository] Supabase not initialized. Using initial memory state.');
      return;
    }

    _isFetchingFromSupabase = true;
    final client = SupabaseConfig.client!;

    try {
      debugPrint('[HotelRepository] Fetching live data from online Supabase...');

      // 1. Branches
      try {
        final branchData = await client.from('branches').select();
        if (branchData.isNotEmpty) {
          _branches = branchData.map((b) => BranchModel.fromJson(b)).toList();
          if (!_branches.any((b) => b.id == _activeBranch.id)) {
            _activeBranch = _branches.first;
          }
        }
      } catch (e) {
        debugPrint('[HotelRepository] Branches fetch notice: $e');
      }

      // 2. Room Types
      try {
        final roomTypeData = await client.from('room_types').select();
        if (roomTypeData.isNotEmpty) {
          _roomTypes = roomTypeData.map((rt) => RoomTypeModel.fromJson(rt)).toList();
        }
      } catch (e) {
        debugPrint('[HotelRepository] Room types fetch notice: $e');
      }

      // 3. Rooms
      try {
        final roomData = await client.from('rooms').select();
        if (roomData.isNotEmpty) {
          _rooms = roomData.map((r) => RoomModel.fromJson(r)).toList();
        }
      } catch (e) {
        debugPrint('[HotelRepository] Rooms fetch notice: $e');
      }

      // 4. Guests
      try {
        final guestData = await client.from('guests').select();
        if (guestData.isNotEmpty) {
          _guests = guestData.map((g) => GuestModel.fromJson(g)).toList();
        }
      } catch (e) {
        debugPrint('[HotelRepository] Guests fetch notice: $e');
      }

      // 5. Reservations
      try {
        final resData = await client.from('reservations').select();
        if (resData.isNotEmpty) {
          _reservations = resData.map((res) => ReservationModel.fromJson(res)).toList();
        }
      } catch (e) {
        debugPrint('[HotelRepository] Reservations fetch notice: $e');
      }

      // 6. POS Outlets
      try {
        final outletData = await client.from('pos_outlets').select();
        if (outletData.isNotEmpty) {
          _posOutlets = outletData.map((o) => PosOutletModel.fromJson(o)).toList();
        }
      } catch (e) {
        debugPrint('[HotelRepository] Outlets fetch notice: $e');
      }

      // 7. POS Menu Items
      try {
        final menuData = await client.from('pos_menu_items').select();
        if (menuData.isNotEmpty) {
          _posMenuItems = menuData.map((m) => PosMenuItemModel.fromJson(m)).toList();
        }
      } catch (e) {
        debugPrint('[HotelRepository] Menu items fetch notice: $e');
      }

      // 8. POS Orders
      try {
        final orderData = await client.from('pos_orders').select().order('created_at', ascending: false);
        if (orderData.isNotEmpty) {
          _posOrders = orderData.map((o) => PosOrderModel.fromJson(o)).toList();
        }
      } catch (e) {
        debugPrint('[HotelRepository] POS orders fetch notice: $e');
      }

      // 9. POS Bills
      try {
        final billData = await client.from('pos_bills').select().order('created_at', ascending: false);
        if (billData.isNotEmpty) {
          _posBills = billData.map((b) => PosBillRecord.fromJson(b)).toList();
        }
      } catch (e) {
        debugPrint('[HotelRepository] POS bills fetch notice: $e');
      }

      // 10. Housekeeping Tasks
      try {
        final hkData = await client.from('housekeeping_tasks').select().order('created_at', ascending: false);
        if (hkData.isNotEmpty) {
          _housekeepingTasks = hkData.map((t) => HousekeepingTaskModel.fromJson(t)).toList();
        }
      } catch (e) {
        debugPrint('[HotelRepository] Housekeeping fetch notice: $e');
      }

      // 11. Delivery Riders
      try {
        final riderData = await client.from('delivery_riders').select();
        if (riderData.isNotEmpty) {
          _deliveryRiders = riderData.map((r) => DeliveryRiderModel.fromJson(r)).toList();
        }
      } catch (e) {
        debugPrint('[HotelRepository] Delivery riders fetch notice: $e');
      }

      // 12. Customer Orders
      try {
        final custOrderData = await client.from('customer_orders').select().order('created_at', ascending: false);
        if (custOrderData.isNotEmpty) {
          _customerOrders.clear();
          _customerOrders.addAll(custOrderData.map((co) => CustomerFoodOrderModel.fromJson(co)));
        }
      } catch (e) {
        debugPrint('[HotelRepository] Customer orders fetch notice: $e');
      }

      // 13. Stock Items
      try {
        final stockData = await client.from('stock_items').select();
        if (stockData.isNotEmpty) {
          _stockItems = stockData.map((s) => StockItemModel.fromJson(s)).toList();
        }
      } catch (e) {
        debugPrint('[HotelRepository] Stock items fetch notice: $e');
      }

      // 14. Banquet Halls
      try {
        final banquetData = await client.from('banquet_halls').select();
        if (banquetData.isNotEmpty) {
          _banquetHalls = banquetData.map((bh) => BanquetHallModel.fromJson(bh)).toList();
        }
      } catch (e) {
        debugPrint('[HotelRepository] Banquet halls fetch notice: $e');
      }

      // 15. Purchases
      try {
        final purchaseData = await client.from('purchases').select().order('purchase_date', ascending: false);
        if (purchaseData.isNotEmpty) {
          _purchases = purchaseData.map((p) => PurchaseEntry.fromJson(p)).toList();
        }
      } catch (e) {
        debugPrint('[HotelRepository] Purchases fetch notice: $e');
      }

      // 16. Expenses
      try {
        final expenseData = await client.from('expenses').select().order('expense_date', ascending: false);
        if (expenseData.isNotEmpty) {
          _expenses = expenseData.map((e) => ExpenseEntry.fromJson(e)).toList();
        }
      } catch (e) {
        debugPrint('[HotelRepository] Expenses fetch notice: $e');
      }

      // 17. Hotel Business Profile
      try {
        final configData = await client.from('hotel_business_config').select().limit(1).maybeSingle();
        if (configData != null) {
          _clientBusinessName = configData['business_name'] as String? ?? _clientBusinessName;
          _clientTagline = configData['tagline'] as String? ?? _clientTagline;
          _clientLicenseKey = configData['license_key'] as String? ?? _clientLicenseKey;
          _clientLicenseType = configData['license_type'] as String? ?? _clientLicenseType;
          _clientLicenseExpiry = configData['expiry_date'] as String? ?? _clientLicenseExpiry;
          _clientContactPerson = configData['contact_person'] as String? ?? _clientContactPerson;
          _moduleRoomsEnabled = configData['enable_rooms'] as bool? ?? _moduleRoomsEnabled;
          _modulePosEnabled = configData['enable_pos'] as bool? ?? _modulePosEnabled;
          _moduleHousekeepingEnabled = configData['enable_housekeeping'] as bool? ?? _moduleHousekeepingEnabled;
          _moduleCrsEnabled = configData['enable_crs'] as bool? ?? _moduleCrsEnabled;
          _moduleBanquetEnabled = configData['enable_banquet'] as bool? ?? _moduleBanquetEnabled;
          _moduleCustomerAppEnabled = configData['enable_customer_app'] as bool? ?? _moduleCustomerAppEnabled;
          _roomGstRate = (configData['room_gst'] as num?)?.toDouble() ?? _roomGstRate;
          _foodGstRate = (configData['food_gst'] as num?)?.toDouble() ?? _foodGstRate;

          _activeBranch = _activeBranch.copyWith(
            name: _clientBusinessName,
            address: configData['address'] as String? ?? _activeBranch.address,
            city: configData['city'] as String? ?? _activeBranch.city,
            state: configData['state'] as String? ?? _activeBranch.state,
            phone: configData['phone'] as String? ?? _activeBranch.phone,
            email: configData['email'] as String? ?? _activeBranch.email,
            taxIdentifier: configData['gstin'] as String? ?? _activeBranch.taxIdentifier,
            currency: configData['currency'] as String? ?? _activeBranch.currency,
          );
        }
      } catch (e) {
        debugPrint('[HotelRepository] Business config fetch notice: $e');
      }

      // 18. Staff Members
      try {
        final staffData = await client.from('staff_members').select();
        if (staffData.isNotEmpty) {
          _staff = staffData.map((s) => StaffModel.fromJson(s)).toList();
        }
      } catch (e) {
        debugPrint('[HotelRepository] Staff members fetch notice: $e');
      }

      // 19. App Users
      try {
        final userData = await client.from('app_users').select();
        if (userData.isNotEmpty) {
          _appUsers = userData.map((u) => AppUserModel.fromJson(u)).toList();
          if (!_appUsers.any((u) => u.id == _currentErpUser.id)) {
            _currentErpUser = _appUsers.firstWhere(
              (u) => u.username == 'rpatil.fd' || u.role == AppUserRole.superAdmin,
              orElse: () => _appUsers.first,
            );
          }
        }
      } catch (e) {
        debugPrint('[HotelRepository] App users fetch notice: $e');
      }

      // 20. Floors
      try {
        final floorData = await client.from('floors').select().order('floor_number');
        if (floorData.isNotEmpty) {
          _floors = floorData.map((f) => {
            'id': f['id'] as String,
            'branch_id': f['branch_id'] as String,
            'floor_number': (f['floor_number'] as num).toInt(),
            'label': f['label'] as String? ?? 'Floor ${f['floor_number']}',
          }).toList();
        }
      } catch (e) {
        debugPrint('[HotelRepository] Floors fetch notice: $e');
      }

      // 21. Folios & Transactions
      try {
        final folioData = await client.from('folios').select();
        final txnData = await client.from('folio_transactions').select();
        if (folioData.isNotEmpty) {
          final txnsByFolio = <String, List<FolioTransactionModel>>{};
          for (final t in txnData) {
            final fId = t['folio_id'] as String? ?? '';
            txnsByFolio.putIfAbsent(fId, () => []).add(FolioTransactionModel.fromJson(t));
          }
          _folios = folioData.map((f) {
            final fId = f['id'] as String;
            final txns = txnsByFolio[fId] ?? [];
            return FolioModel.fromJson(f, txns: txns);
          }).toList();
        }
      } catch (e) {
        debugPrint('[HotelRepository] Folios fetch notice: $e');
      }

      // 22. Customers
      try {
        final custData = await client.from('customers').select();
        if (custData.isNotEmpty) {
          _registeredCustomers = custData.map((c) => CustomerModel.fromJson(c)).toList();
        }
      } catch (e) {
        debugPrint('[HotelRepository] Customers fetch notice: $e');
      }

      debugPrint('[HotelRepository] Successfully synchronized live state with Supabase cloud!');
      notifyListeners();
    } catch (e) {
      debugPrint('[HotelRepository] Error fetching from Supabase cloud: $e');
    } finally {
      _isFetchingFromSupabase = false;
    }
  }

  void _pushPosOrderToSupabase(PosOrderModel order) {
    if (!SupabaseConfig.isInitialized || SupabaseConfig.client == null) return;
    try {
      SupabaseConfig.client!.from('pos_orders').upsert({
        'id': order.id,
        'outlet_id': order.outletId,
        'order_number': order.orderNumber,
        'table_number': order.tableNumber ?? 'T-01',
        'room_number': order.roomNumber,
        'guest_name': order.guestName,
        'status': order.status.name,
        'items': order.items.map((i) => {
          'menuItemId': i.menuItemId,
          'name': i.name,
          'price': i.price,
          'quantity': i.quantity,
          'notes': i.notes,
        }).toList(),
        'subtotal': order.subtotal,
        'tax': order.tax,
        'total': order.total,
        'charged_to_folio_id': order.chargedToFolioId,
        'created_at': order.createdAt.toIso8601String(),
      }).then((_) {
        debugPrint('[HotelRepository] POS Order ${order.orderNumber} pushed to Supabase online.');
      }).catchError((e) {
        debugPrint('[HotelRepository] Error pushing POS order to Supabase: $e');
      });
    } catch (_) {}
  }

  void _pushBillToSupabase(PosBillRecord bill) {
    if (!SupabaseConfig.isInitialized || SupabaseConfig.client == null) return;
    try {
      SupabaseConfig.client!.from('pos_bills').upsert({
        'id': bill.id,
        'bill_number': bill.billNumber,
        'billing_type': bill.billingType.name,
        'branch_id': bill.branchId,
        'outlet_id': bill.outletId,
        'outlet_name': bill.outletName,
        'table_number': bill.tableNumber,
        'room_number': bill.roomNumber,
        'guest_name': bill.guestName,
        'waiter_name': bill.waiterName,
        'covers': bill.covers ?? 2,
        'items': bill.items.map((i) => {
          'menuItemId': i.menuItemId,
          'name': i.name,
          'price': i.price,
          'quantity': i.quantity,
        }).toList(),
        'subtotal': bill.subtotal,
        'tax_amount': bill.taxAmount,
        'total_amount': bill.totalAmount,
        'payment_method': bill.paymentMethod,
        'payment_status': bill.paymentStatus,
        'created_at': bill.createdAt.toIso8601String(),
      }).then((_) {
        debugPrint('[HotelRepository] Bill ${bill.billNumber} pushed to Supabase online.');
      }).catchError((e) {
        debugPrint('[HotelRepository] Error saving bill to Supabase: $e');
      });
    } catch (_) {}
  }

  void _pushCustomerOrderToSupabase(CustomerFoodOrderModel order) {
    if (!SupabaseConfig.isInitialized || SupabaseConfig.client == null) return;
    try {
      SupabaseConfig.client!.from('customer_orders').upsert({
        'id': order.id,
        'branch_id': order.branchId,
        'branch_name': order.branchName,
        'customer_id': order.customerId,
        'customer_name': order.customerName,
        'customer_phone': order.customerPhone,
        'delivery_address': order.deliveryAddress.toJson(),
        'items': order.items.map((i) => {
          'menuItemId': i.menuItemId,
          'name': i.name,
          'price': i.price,
          'quantity': i.quantity,
          'category': i.category,
        }).toList(),
        'item_total': order.itemTotal,
        'gst_amount': order.gstAmount,
        'delivery_fee': order.deliveryFee,
        'packaging_charge': order.packagingCharge,
        'discount_amount': order.discountAmount,
        'coupon_code': order.couponCodeApplied,
        'grand_total': order.grandTotal,
        'payment_method': order.paymentMethod.name,
        'payment_status': order.paymentStatus.name,
        'transaction_id': order.transactionId,
        'order_status': order.orderStatus.name,
        'rider_name': order.riderName,
        'rider_phone': order.riderPhone,
        'rider_vehicle_no': order.riderVehicleNo,
        'channel': order.channel,
        'created_at': order.createdAt.toIso8601String(),
      }).then((_) {
        debugPrint('[HotelRepository] Customer order ${order.id} pushed to Supabase online.');
      }).catchError((e) {
        debugPrint('[HotelRepository] Error pushing customer order to Supabase: $e');
      });
    } catch (_) {}
  }

  void _pushRoomTypeToSupabase(RoomTypeModel type) {
    if (!SupabaseConfig.isInitialized || SupabaseConfig.client == null) return;
    try {
      SupabaseConfig.client!.from('room_types').upsert(type.toJson()).then((_) {
        debugPrint('[HotelRepository] RoomType ${type.name} pushed to Supabase online.');
      }).catchError((e) {
        debugPrint('[HotelRepository] Error pushing RoomType to Supabase: $e');
      });
    } catch (_) {}
  }

  void _pushRoomToSupabase(RoomModel room) {
    if (!SupabaseConfig.isInitialized || SupabaseConfig.client == null) return;
    try {
      SupabaseConfig.client!.from('rooms').upsert(room.toJson()).then((_) {
        debugPrint('[HotelRepository] Room ${room.roomNumber} pushed to Supabase online.');
      }).catchError((e) {
        debugPrint('[HotelRepository] Error pushing Room to Supabase: $e');
      });
    } catch (_) {}
  }

  void _pushFloorToSupabase(Map<String, dynamic> floor) {
    if (!SupabaseConfig.isInitialized || SupabaseConfig.client == null) return;
    try {
      SupabaseConfig.client!.from('floors').upsert(floor).then((_) {
        debugPrint('[HotelRepository] Floor ${floor['floor_number']} pushed to Supabase online.');
      }).catchError((e) {
        debugPrint('[HotelRepository] Error pushing Floor to Supabase: $e');
      });
    } catch (_) {}
  }

  void _pushMenuItemToSupabase(PosMenuItemModel item) {
    if (!SupabaseConfig.isInitialized || SupabaseConfig.client == null) return;
    try {
      SupabaseConfig.client!.from('pos_menu_items').upsert(item.toJson()).then((_) {
        debugPrint('[HotelRepository] Menu Item ${item.name} pushed to Supabase online.');
      }).catchError((e) {
        debugPrint('[HotelRepository] Error pushing Menu Item to Supabase: $e');
      });
    } catch (_) {}
  }

  void _pushStaffToSupabase(StaffModel staff) {
    if (!SupabaseConfig.isInitialized || SupabaseConfig.client == null) return;
    try {
      SupabaseConfig.client!.from('staff_members').upsert(staff.toSupabaseJson()).then((_) {
        debugPrint('[HotelRepository] Staff ${staff.fullName} pushed to Supabase online.');
      }).catchError((e) {
        debugPrint('[HotelRepository] Error pushing Staff to Supabase: $e');
      });
    } catch (_) {}
  }

  void _pushUserToSupabase(AppUserModel user) {
    if (!SupabaseConfig.isInitialized || SupabaseConfig.client == null) return;
    try {
      SupabaseConfig.client!.from('app_users').upsert(user.toJson()).then((_) {
        debugPrint('[HotelRepository] App User ${user.username} pushed to Supabase online.');
      }).catchError((e) {
        debugPrint('[HotelRepository] Error pushing App User to Supabase: $e');
      });
    } catch (_) {}
  }

  void _pushReservationToSupabase(ReservationModel res) {
    if (!SupabaseConfig.isInitialized || SupabaseConfig.client == null) return;
    try {
      SupabaseConfig.client!.from('reservations').upsert(res.toJson()).then((_) {
        debugPrint('[HotelRepository] Reservation ${res.bookingReference} pushed to Supabase online.');
      }).catchError((e) {
        debugPrint('[HotelRepository] Error pushing Reservation to Supabase: $e');
      });
    } catch (_) {}
  }

  void _pushFolioToSupabase(FolioModel folio) {
    if (!SupabaseConfig.isInitialized || SupabaseConfig.client == null) return;
    try {
      SupabaseConfig.client!.from('folios').upsert({
        'id': folio.id,
        'reservation_id': folio.reservationId,
        'folio_number': folio.folioNumber,
        'status': folio.status,
        'room_number': folio.roomNumber,
        'guest_name': folio.guestName,
        'total_charges': folio.totalCharges,
        'total_paid': folio.totalPaid,
        'balance_due': folio.balanceDue,
      }).then((_) {
        debugPrint('[HotelRepository] Folio ${folio.folioNumber} pushed to Supabase online.');
      }).catchError((e) {
        debugPrint('[HotelRepository] Error pushing Folio to Supabase: $e');
      });
    } catch (_) {}
  }

  void _pushFolioTransactionToSupabase(FolioTransactionModel txn) {
    if (!SupabaseConfig.isInitialized || SupabaseConfig.client == null) return;
    try {
      SupabaseConfig.client!.from('folio_transactions').upsert(txn.toJson()).then((_) {
        debugPrint('[HotelRepository] Folio Transaction ${txn.id} pushed to Supabase online.');
      }).catchError((e) {
        debugPrint('[HotelRepository] Error pushing Folio Transaction to Supabase: $e');
      });
    } catch (_) {}
  }

  void _pushCustomerToSupabase(CustomerModel cust) {
    if (!SupabaseConfig.isInitialized || SupabaseConfig.client == null) return;
    try {
      SupabaseConfig.client!.from('customers').upsert(cust.toJson()).then((_) {
        debugPrint('[HotelRepository] Customer ${cust.name} pushed to Supabase online.');
      }).catchError((e) {
        debugPrint('[HotelRepository] Error pushing Customer to Supabase: $e');
      });
    } catch (_) {}
  }

  void _pushStockItemToSupabase(StockItemModel item) {
    if (!SupabaseConfig.isInitialized || SupabaseConfig.client == null) return;
    try {
      SupabaseConfig.client!.from('stock_items').upsert(item.toSupabaseJson()).then((_) {
        debugPrint('[HotelRepository] Stock Item ${item.name} pushed to Supabase online.');
      }).catchError((e) {
        debugPrint('[HotelRepository] Error pushing Stock Item to Supabase: $e');
      });
    } catch (_) {}
  }

  void _pushDeliveryRiderToSupabase(DeliveryRiderModel rider) {
    if (!SupabaseConfig.isInitialized || SupabaseConfig.client == null) return;
    try {
      SupabaseConfig.client!.from('delivery_riders').upsert(rider.toJson()).then((_) {
        debugPrint('[HotelRepository] Delivery Rider ${rider.name} pushed to Supabase online.');
      }).catchError((e) {
        debugPrint('[HotelRepository] Error pushing Delivery Rider to Supabase: $e');
      });
    } catch (_) {}
  }

  void _pushPurchaseToSupabase(PurchaseEntry entry) {
    if (!SupabaseConfig.isInitialized || SupabaseConfig.client == null) return;
    try {
      SupabaseConfig.client!.from('purchases').upsert(entry.toSupabaseJson()).then((_) {
        debugPrint('[HotelRepository] Purchase ${entry.invoiceNumber} pushed to Supabase online.');
      }).catchError((e) {
        debugPrint('[HotelRepository] Error pushing Purchase to Supabase: $e');
      });
    } catch (_) {}
  }

  void _pushExpenseToSupabase(ExpenseEntry entry) {
    if (!SupabaseConfig.isInitialized || SupabaseConfig.client == null) return;
    try {
      SupabaseConfig.client!.from('expenses').upsert(entry.toSupabaseJson()).then((_) {
        debugPrint('[HotelRepository] Expense ${entry.voucherNo} pushed to Supabase online.');
      }).catchError((e) {
        debugPrint('[HotelRepository] Error pushing Expense to Supabase: $e');
      });
    } catch (_) {}
  }

  void _pushHousekeepingTaskToSupabase(HousekeepingTaskModel task) {
    if (!SupabaseConfig.isInitialized || SupabaseConfig.client == null) return;
    try {
      SupabaseConfig.client!.from('housekeeping_tasks').upsert(task.toJson()).then((_) {
        debugPrint('[HotelRepository] Housekeeping Task ${task.id} pushed to Supabase online.');
      }).catchError((e) {
        debugPrint('[HotelRepository] Error pushing Housekeeping Task to Supabase: $e');
      });
    } catch (_) {}
  }

  void _initData() {
    _branches = List.from(MockHotelData.initialBranches);
    _roomTypes = List.from(MockHotelData.initialRoomTypes);
    _rooms = MockHotelData.generateInitialRooms();
    _guests = List.from(MockHotelData.initialGuests);
    _reservations = MockHotelData.generateInitialReservations();
    _folios = MockHotelData.generateInitialFolios();
    _posOutlets = List.from(MockHotelData.initialOutlets);
    _posMenuItems = List.from(MockHotelData.initialMenuItems);
    _posOrders = [];
    _banquetHalls = List.from(MockHotelData.initialBanquetHalls);
    _posBills = MockHotelData.getInitialPosBills();
    _housekeepingTasks = MockHotelData.generateInitialHousekeeping();
    _staff = MockHotelData.generateInitialStaff();
    _appUsers = MockHotelData.generateInitialUsers();
    _currentErpUser = _appUsers.firstWhere((u) => u.username == 'rpatil.fd', orElse: () => _appUsers.first);
    _floors = MockHotelData.generateInitialFloors();
    _purchases = MockHotelData.generateInitialPurchases();
    _expenses = MockHotelData.generateInitialExpenses();
    _stockItems = MockHotelData.getInitialStockItems();
    _deliveryRiders = List.from(MockHotelData.initialDeliveryRiders);

    _activeBranch = _branches.firstWhere(
      (b) => _currentErpUser.hasAccessToBranch(b.id),
      orElse: () => _branches.first,
    );

    // Clear any obsolete local files so system runs purely on online Supabase
    HotelConfigStorage.clearAllLocalDataFiles();

    // Restore saved client business profile, custom logo & accounting data
    _loadSavedBusinessConfig();
    _loadSavedAccountingData();

    // Fresh Enterprise State: No auto-logged-in customer by default
    _currentCustomer = null;
    _selectedDeliveryAddress = null;

    _customerOrders.clear();

    // Initial Registered Customers Directory for CRM
    _registeredCustomers = [
      CustomerModel(
        id: 'cust-102',
        name: 'Pooja Verma',
        phone: '+91 98201 55432',
        email: 'pooja.verma@gmail.com',
        city: 'Mumbai',
        gstin: '27AAFPV9821R1Z8',
        companyName: 'Verma Designs Studio',
        addresses: const [
          CustomerAddressModel(
            id: 'addr-102',
            label: 'Home',
            fullAddress: 'Tower 3, Apt 1402, Hiranandani Gardens, Powai, Mumbai',
            city: 'Mumbai',
            pincode: '400076',
            latitude: 19.1197,
            longitude: 72.9051,
          ),
        ],
        walletBalance: 420.0,
        totalVisits: 6,
        joinedDate: DateTime.now().subtract(const Duration(days: 90)),
      ),
      CustomerModel(
        id: 'cust-103',
        name: 'Rajesh Singhania',
        phone: '+91 98110 77654',
        email: 'rajesh@singhaniasteels.com',
        city: 'Mumbai',
        gstin: '27AAACS1482K1Z5',
        companyName: 'Singhania Steels & Infra Ltd',
        addresses: const [
          CustomerAddressModel(
            id: 'addr-103',
            label: 'Corporate HQ',
            fullAddress: 'Level 12, Maker Chambers V, Nariman Point, Mumbai',
            city: 'Mumbai',
            pincode: '400021',
            latitude: 18.9281,
            longitude: 72.8226,
          ),
        ],
        walletBalance: 12500.0,
        totalVisits: 14,
        joinedDate: DateTime.now().subtract(const Duration(days: 180)),
      ),
      CustomerModel(
        id: 'cust-104',
        name: 'Neha Kapoor',
        phone: '+91 97690 12345',
        email: 'neha.kapoor88@yahoo.com',
        city: 'Goa',
        addresses: const [
          CustomerAddressModel(
            id: 'addr-104',
            label: 'Villa',
            fullAddress: 'B-12, Heritage Greens, Candolim, North Goa',
            city: 'Goa',
            pincode: '403515',
            latitude: 15.5178,
            longitude: 73.7667,
          ),
        ],
        walletBalance: 80.0,
        totalVisits: 3,
        joinedDate: DateTime.now().subtract(const Duration(days: 20)),
      ),
      CustomerModel(
        id: 'cust-105',
        name: 'Dr. Vikram Malhotra',
        phone: '+91 98220 99881',
        email: 'v.malhotra@fortishospital.org',
        city: 'Mumbai',
        gstin: '27AABCM8920D1ZQ',
        companyName: 'Malhotra Medicare Consultants',
        addresses: const [
          CustomerAddressModel(
            id: 'addr-105',
            label: 'Clinic',
            fullAddress: 'Suite 201, Medical Enclave, Mulund West, Mumbai',
            city: 'Mumbai',
            pincode: '400080',
            latitude: 19.1726,
            longitude: 72.9425,
          ),
        ],
        walletBalance: 1500.0,
        totalVisits: 8,
        joinedDate: DateTime.now().subtract(const Duration(days: 120)),
      ),
      CustomerModel(
        id: 'cust-106',
        name: 'Sanjay Mehta',
        phone: '+91 99200 44321',
        email: 'sanjay.m@techmahindra.com',
        city: 'Pune',
        gstin: '27AABCT2391Q1ZP',
        companyName: 'Tech Mahindra Corporate Travel Desk',
        addresses: const [
          CustomerAddressModel(
            id: 'addr-106',
            label: 'Office',
            fullAddress: 'Plot 1, Phase 3, Hinjawadi Rajiv Gandhi Infotech Park, Pune',
            city: 'Pune',
            pincode: '411057',
            latitude: 18.5913,
            longitude: 73.7389,
          ),
        ],
        walletBalance: 8400.0,
        totalVisits: 22,
        joinedDate: DateTime.now().subtract(const Duration(days: 300)),
      ),
    ];

    // Initial Invoices Register
    _invoices = [
      ErpInvoiceRecord(
        invoiceNumber: 'INV-RM-1024',
        type: ErpInvoiceType.roomStay,
        customerName: 'Rajesh Singhania',
        customerPhone: '+91 98110 77654',
        customerGstin: '27AAACS1482K1Z5',
        customerAddress: 'Nariman Point, Mumbai',
        date: DateTime.now().subtract(const Duration(hours: 4)),
        taxableAmount: 18500.0,
        cgst: 1665.0,
        sgst: 1665.0,
        totalAmount: 21830.0,
        paymentMode: 'Corporate BTC (Credit)',
        status: ErpInvoiceStatus.credit,
        referenceId: 'FOL-101',
        items: const [
          ErpInvoiceLineItem(description: 'Presidential Suite (2 Nights)', hsnSacCode: '996311', quantity: 2, unitRate: 8500.0, amount: 17000.0, gstRate: 18.0),
          ErpInvoiceLineItem(description: 'Airport Luxury Sedan Transfer', hsnSacCode: '996412', quantity: 1, unitRate: 1500.0, amount: 1500.0, gstRate: 18.0),
        ],
      ),
      ErpInvoiceRecord(
        invoiceNumber: 'INV-POS-4401',
        type: ErpInvoiceType.restaurantPos,
        customerName: 'Pooja Verma',
        customerPhone: '+91 98201 55432',
        customerGstin: '27AAFPV9821R1Z8',
        customerAddress: 'Powai, Mumbai',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        taxableAmount: 2450.0,
        cgst: 61.25,
        sgst: 61.25,
        totalAmount: 2572.50,
        paymentMode: 'UPI (GPay)',
        status: ErpInvoiceStatus.paid,
        referenceId: 'BILL-4401',
        items: const [
          ErpInvoiceLineItem(description: 'Paneer Tikka Platter', hsnSacCode: '996331', quantity: 2, unitRate: 380.0, amount: 760.0, gstRate: 5.0),
          ErpInvoiceLineItem(description: 'Dal Makhani Special', hsnSacCode: '996331', quantity: 1, unitRate: 320.0, amount: 320.0, gstRate: 5.0),
          ErpInvoiceLineItem(description: 'Butter Garlic Naan', hsnSacCode: '996331', quantity: 4, unitRate: 75.0, amount: 300.0, gstRate: 5.0),
          ErpInvoiceLineItem(description: 'Hyderabadi Dum Biryani', hsnSacCode: '996331', quantity: 2, unitRate: 420.0, amount: 840.0, gstRate: 5.0),
          ErpInvoiceLineItem(description: 'Sizzling Brownie with Ice Cream', hsnSacCode: '996331', quantity: 1, unitRate: 230.0, amount: 230.0, gstRate: 5.0),
        ],
      ),
      ErpInvoiceRecord(
        invoiceNumber: 'INV-DEL-8421',
        type: ErpInvoiceType.onlineDelivery,
        customerName: 'Amit Sharma',
        customerPhone: '+91 98765 43210',
        customerAddress: 'Chakala, Andheri East, Mumbai',
        date: DateTime.now().subtract(const Duration(minutes: 45)),
        taxableAmount: 890.0,
        cgst: 22.25,
        sgst: 22.25,
        totalAmount: 934.50,
        paymentMode: 'Razorpay Online',
        status: ErpInvoiceStatus.paid,
        referenceId: 'ORD-HP-8421',
        items: const [
          ErpInvoiceLineItem(description: 'Chicken Biryani Royal', hsnSacCode: '996331', quantity: 1, unitRate: 450.0, amount: 450.0, gstRate: 5.0),
          ErpInvoiceLineItem(description: 'Butter Chicken Masala', hsnSacCode: '996331', quantity: 1, unitRate: 440.0, amount: 440.0, gstRate: 5.0),
        ],
      ),
      ErpInvoiceRecord(
        invoiceNumber: 'INV-RM-1025',
        type: ErpInvoiceType.roomStay,
        customerName: 'Sanjay Mehta',
        customerPhone: '+91 99200 44321',
        customerGstin: '27AABCT2391Q1ZP',
        customerAddress: 'Hinjawadi, Pune',
        date: DateTime.now().subtract(const Duration(days: 1)),
        taxableAmount: 9600.0,
        cgst: 864.0,
        sgst: 864.0,
        totalAmount: 11328.0,
        paymentMode: 'Credit Card (HDFC)',
        status: ErpInvoiceStatus.paid,
        referenceId: 'FOL-102',
        items: const [
          ErpInvoiceLineItem(description: 'Deluxe Executive Room (2 Nights)', hsnSacCode: '996311', quantity: 2, unitRate: 4800.0, amount: 9600.0, gstRate: 18.0),
        ],
      ),
      ErpInvoiceRecord(
        invoiceNumber: 'INV-POS-4402',
        type: ErpInvoiceType.restaurantPos,
        customerName: 'Dr. Vikram Malhotra',
        customerPhone: '+91 98220 99881',
        customerGstin: '27AABCM8920D1ZQ',
        customerAddress: 'Mulund West, Mumbai',
        date: DateTime.now().subtract(const Duration(hours: 6)),
        taxableAmount: 3800.0,
        cgst: 95.0,
        sgst: 95.0,
        totalAmount: 3990.0,
        paymentMode: 'Cash Counter',
        status: ErpInvoiceStatus.paid,
        referenceId: 'BILL-4402',
        items: const [
          ErpInvoiceLineItem(description: 'Chef Special Royal Seafood Thali', hsnSacCode: '996331', quantity: 4, unitRate: 950.0, amount: 3800.0, gstRate: 5.0),
        ],
      ),
    ];
  }

  // ── Getters ──────────────────────────────────────────────────────────
  List<BranchModel> get branches => _branches;
  BranchModel get activeBranch => _activeBranch;
  List<RoomModel> get rooms => _rooms;
  List<HousekeepingTaskModel> get housekeepingTasks => _housekeepingTasks;

  List<RoomModel> get activeBranchRooms =>
      _rooms.where((r) => r.branchId == _activeBranch.id).toList();

  List<RoomTypeModel> get activeBranchRoomTypes =>
      _roomTypes.where((rt) => rt.branchId == _activeBranch.id).toList();

  List<RoomTypeModel> get allRoomTypes => _roomTypes;

  List<ReservationModel> get activeBranchReservations =>
      _reservations.where((res) => res.branchId == _activeBranch.id).toList();

  List<FolioModel> get activeBranchFolios => _folios;

  List<PosOutletModel> get activeBranchOutlets =>
      _posOutlets.where((o) => o.branchId == _activeBranch.id).toList();

  List<PosMenuItemModel> get activeBranchMenuItems {
    final outletIds = activeBranchOutlets.map((o) => o.id).toSet();
    return _posMenuItems.where((m) => outletIds.contains(m.outletId)).toList();
  }

  List<PosOrderModel> get posOrders => _posOrders;

  List<BanquetHallModel> get activeBranchBanquetHalls {
    return _banquetHalls.where((h) => h.branchId == _activeBranch.id).toList();
  }

  List<PosBillRecord> get activeBranchPosBills {
    return _posBills.where((b) => b.branchId == _activeBranch.id).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<PosBillRecord> get tableDiningBills =>
      activeBranchPosBills.where((b) => b.billingType == PosBillingType.tableDining).toList();

  List<PosBillRecord> get roomFolioBills =>
      activeBranchPosBills.where((b) => b.billingType == PosBillingType.roomFolio).toList();

  List<PosBillRecord> get hallBookingBills =>
      activeBranchPosBills.where((b) => b.billingType == PosBillingType.hallBooking).toList();

  List<HousekeepingTaskModel> get activeBranchHousekeeping =>
      _housekeepingTasks.where((h) => h.branchId == _activeBranch.id).toList();

  List<GuestModel> get guests => _guests;

  // Master Section getters
  List<StaffModel> get activeBranchStaff =>
      _staff.where((s) => s.branchId == _activeBranch.id).toList();

  List<AppUserModel> get appUsers => _appUsers;
  AppUserModel get currentErpUser => _currentErpUser;

  List<BranchModel> get accessibleBranches {
    if (_currentErpUser.role == AppUserRole.superAdmin || _currentErpUser.isDeveloper) {
      return _branches;
    }
    final allowed = _branches.where((b) => _currentErpUser.hasAccessToBranch(b.id)).toList();
    return allowed.isNotEmpty ? allowed : [_branches.first];
  }

  List<Map<String, dynamic>> get activeBranchFloors =>
      _floors.where((f) => f['branch_id'] == _activeBranch.id).toList()
        ..sort((a, b) => (a['floor_number'] as int).compareTo(b['floor_number'] as int));

  // Customer CRM & Invoices Getters
  List<CustomerModel> get registeredCustomers => _registeredCustomers;
  List<ErpInvoiceRecord> get allInvoices => _invoices;


  // 1. Branch Switcher (Guarded by user allocation)
  void switchBranch(String branchId) {
    if (!accessibleBranches.any((b) => b.id == branchId)) return;
    final found = _branches.firstWhere(
      (b) => b.id == branchId,
      orElse: () => _activeBranch,
    );
    _activeBranch = found;
    _initDefaultAndroidConfigs();
    notifyListeners();
  }

  // 1b. ERP User Switcher & Authentication
  bool _isErpLoggedIn = false;
  bool get isErpLoggedIn => _isErpLoggedIn;

  void logOutErp() {
    _isErpLoggedIn = false;
    notifyListeners();
  }

  void markErpLoggedIn() {
    _isErpLoggedIn = true;
    notifyListeners();
  }

  void switchErpUser(String userId) {
    final found = _appUsers.firstWhere((u) => u.id == userId || u.username == userId, orElse: () => _currentErpUser);
    _currentErpUser = found;
    _isErpLoggedIn = true;
    final allowed = accessibleBranches;
    if (!allowed.any((b) => b.id == _activeBranch.id)) {
      _activeBranch = allowed.first;
    }
    notifyListeners();
  }

  bool authenticateUser(String username, String password) {
    final user = username.trim().toLowerCase();
    if (user == 'isecure' && password.trim() == 'Admin@1998') {
      final devUser = _appUsers.firstWhere(
        (u) => u.username == 'isecure',
        orElse: () => AppUserModel(
          id: 'usr-dev',
          username: 'isecure',
          displayName: 'iSecure Systems Developer',
          role: AppUserRole.developer,
          branchAccess: _branches.map((b) => b.id).toList(),
          createdAt: DateTime.now(),
        ),
      );
      _currentErpUser = devUser;
      _isErpLoggedIn = true;
      notifyListeners();
      return true;
    }

    final found = _appUsers.where((u) => u.username.toLowerCase() == user).firstOrNull;
    if (found != null) {
      _currentErpUser = found;
      _isErpLoggedIn = true;
      final allowed = accessibleBranches;
      if (!allowed.any((b) => b.id == _activeBranch.id)) {
        _activeBranch = allowed.first;
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  void updateUserBranchAccess(String userId, List<String> branchIds) {
    final idx = _appUsers.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      _appUsers[idx] = _appUsers[idx].copyWith(branchAccess: branchIds);
      _pushUserToSupabase(_appUsers[idx]);
      if (_currentErpUser.id == userId) {
        _currentErpUser = _appUsers[idx];
        final allowed = accessibleBranches;
        if (!allowed.any((b) => b.id == _activeBranch.id)) {
          _activeBranch = allowed.first;
        }
      }
      notifyListeners();
    }
  }

  void addAppUser({
    required String username,
    required String displayName,
    required AppUserRole role,
    required List<String> branchAccess,
  }) {
    final newUser = AppUserModel(
      id: 'usr-${_uuid.v4().substring(0, 6)}',
      username: username,
      displayName: displayName,
      role: role,
      branchAccess: branchAccess,
      createdAt: DateTime.now(),
    );
    _appUsers.add(newUser);
    _pushUserToSupabase(newUser);
    notifyListeners();
  }

  void deleteAppUser(String userId) {
    _appUsers.removeWhere((u) => u.id == userId);
    if (SupabaseConfig.isInitialized && SupabaseConfig.client != null) {
      SupabaseConfig.client!.from('app_users').delete().eq('id', userId).then((_) {}).catchError((_) {});
    }
    if (_currentErpUser.id == userId && _appUsers.isNotEmpty) {
      _currentErpUser = _appUsers.first;
      final allowed = accessibleBranches;
      if (!allowed.any((b) => b.id == _activeBranch.id)) {
        _activeBranch = allowed.first;
      }
    }
    notifyListeners();
  }

  // 2. Room Status Management
  void updateRoomStatus(String roomId, RoomStatus newStatus, {String? notes}) {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx != -1) {
      _rooms[idx] = _rooms[idx].copyWith(
        status: newStatus,
        notes: notes ?? _rooms[idx].notes,
      );
      if (SupabaseConfig.isInitialized && SupabaseConfig.client != null) {
        SupabaseConfig.client!.from('rooms').update({
          'status': newStatus.code,
          'notes': notes ?? _rooms[idx].notes,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', roomId).then((_) {}).catchError((_) {});
      }
      notifyListeners();
    }
  }

  // 3. Express Check-In Workflow
  void checkInGuest({
    required String roomId,
    required String guestName,
    required String guestPhone,
    required VipTier vipTier,
    required String roomTypeName,
    required double ratePerNight,
    required int numberOfNights,
    required double advancePayment,
    required PaymentMethod advanceMethod,
    String? specialRequests,
    String? keycardRfid,
  }) {
    final roomIdx = _rooms.indexWhere((r) => r.id == roomId);
    if (roomIdx == -1) return;

    final room = _rooms[roomIdx];
    final reservationRef = 'RES-${_activeBranch.code}-${1000 + _reservations.length + 1}';
    final folioRef = 'FOL-${_activeBranch.code}-${2000 + _folios.length + 1}';
    final guestId = 'gst-${_uuid.v4().substring(0, 8)}';
    final reservationId = 'res-${_uuid.v4().substring(0, 8)}';
    final folioId = 'fol-${_uuid.v4().substring(0, 8)}';

    // 1. Create Guest profile
    final nameParts = guestName.split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    final newGuest = GuestModel(
      id: guestId,
      organizationId: _activeBranch.organizationId,
      firstName: firstName,
      lastName: lastName,
      email: '${firstName.toLowerCase()}@luxuryguest.com',
      phone: guestPhone,
      vipTier: vipTier,
      idNumber: 'ID-${_uuid.v4().substring(0, 6).toUpperCase()}',
      specialRequests: specialRequests ?? '',
      totalStays: 1,
    );
    _guests.add(newGuest);

    // 2. Create Reservation
    final checkIn = DateTime.now();
    final checkOut = checkIn.add(Duration(days: numberOfNights));
    final newReservation = ReservationModel(
      id: reservationId,
      bookingReference: reservationRef,
      branchId: _activeBranch.id,
      guestId: guestId,
      roomId: roomId,
      roomTypeId: room.roomTypeId,
      checkInDate: checkIn,
      checkOutDate: checkOut,
      actualCheckIn: checkIn,
      bookingStatus: ReservationStatus.checkedIn,
      bookingSource: 'Front Desk Express Check-In',
      ratePerNight: ratePerNight,
      advancePaid: advancePayment,
      specialNotes: specialRequests ?? '',
      guestName: guestName,
      guestPhone: guestPhone,
      guestVipTier: vipTier,
      roomNumber: room.roomNumber,
      roomTypeName: roomTypeName,
    );
    _reservations.add(newReservation);

    // 3. Create Master Folio with initial Room Charges and Advance Credit
    final roomTariffTotal = ratePerNight * numberOfNights;
    final roomTax = roomTariffTotal * 0.18; // 18% Luxury Hotel GST

    final transactions = <FolioTransactionModel>[
      FolioTransactionModel(
        id: 'ft-${_uuid.v4().substring(0, 6)}',
        folioId: folioId,
        category: FolioCategory.roomCharge,
        description: '$roomTypeName ($numberOfNights Nights Stay)',
        amount: roomTariffTotal,
        taxAmount: roomTax,
        isCredit: false,
        timestamp: DateTime.now(),
      ),
    ];

    if (advancePayment > 0) {
      transactions.add(
        FolioTransactionModel(
          id: 'ft-${_uuid.v4().substring(0, 6)}',
          folioId: folioId,
          category: FolioCategory.payment,
          description: 'Advance Deposit Collected at Check-In',
          amount: advancePayment,
          isCredit: true,
          paymentMethod: advanceMethod,
          referenceId: 'DEP-${_uuid.v4().substring(0, 6).toUpperCase()}',
          timestamp: DateTime.now(),
        ),
      );
    }

    final newFolio = FolioModel(
      id: folioId,
      reservationId: reservationId,
      folioNumber: folioRef,
      status: 'open',
      roomNumber: room.roomNumber,
      guestName: guestName,
      transactions: transactions,
    );
    _folios.add(newFolio);

    // 4. Update Room status to occupied
    _rooms[roomIdx] = room.copyWith(
      status: RoomStatus.occupied,
      currentGuestName: guestName,
      currentReservationId: reservationId,
      currentGuestVip: vipTier,
      keycardRfid: keycardRfid ?? 'RFID-${room.roomNumber}-A',
    );

    if (SupabaseConfig.isInitialized && SupabaseConfig.client != null) {
      final client = SupabaseConfig.client!;
      client.from('guests').upsert({
        'id': newGuest.id,
        'organization_id': newGuest.organizationId,
        'first_name': newGuest.firstName,
        'last_name': newGuest.lastName,
        'email': newGuest.email,
        'phone': newGuest.phone,
        'vip_tier': newGuest.vipTier.code,
        'id_number': newGuest.idNumber,
      }).then((_) {}).catchError((_) {});

      client.from('reservations').upsert({
        'id': newReservation.id,
        'booking_reference': newReservation.bookingReference,
        'branch_id': newReservation.branchId,
        'guest_id': newReservation.guestId,
        'room_id': newReservation.roomId,
        'room_type_id': newReservation.roomTypeId,
        'check_in_date': newReservation.checkInDate.toIso8601String(),
        'check_out_date': newReservation.checkOutDate.toIso8601String(),
        'actual_check_in': newReservation.actualCheckIn?.toIso8601String(),
        'booking_status': newReservation.bookingStatus.code,
        'booking_source': newReservation.bookingSource,
        'rate_per_night': newReservation.ratePerNight,
        'advance_paid': newReservation.advancePaid,
        'guest_name': newReservation.guestName,
        'guest_phone': newReservation.guestPhone,
        'room_number': newReservation.roomNumber,
        'room_type_name': newReservation.roomTypeName,
      }).then((_) {}).catchError((_) {});

      client.from('rooms').update({
        'status': RoomStatus.occupied.code,
        'current_guest_name': guestName,
        'current_reservation_id': reservationId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', roomId).then((_) {}).catchError((_) {});

      _pushFolioToSupabase(newFolio);
      for (final txn in transactions) {
        _pushFolioTransactionToSupabase(txn);
      }
    }

    notifyListeners();
  }

  // 3b. Create Central Reservation (CRS)
  void createReservation({
    required String guestName,
    required String guestPhone,
    required VipTier vipTier,
    required String roomTypeId,
    required String roomTypeName,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required double ratePerNight,
    double advancePaid = 0.0,
    String bookingSource = 'Direct CRS',
    String specialNotes = '',
  }) {
    final guestId = 'gst-${_uuid.v4().substring(0, 8)}';
    final reservationId = 'res-${_uuid.v4().substring(0, 8)}';
    final reservationRef = 'RES-${_activeBranch.code}-${1000 + _reservations.length + 1}';

    final nameParts = guestName.trim().split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    final newGuest = GuestModel(
      id: guestId,
      organizationId: _activeBranch.organizationId,
      firstName: firstName,
      lastName: lastName,
      email: '${firstName.toLowerCase()}@luxuryguest.com',
      phone: guestPhone,
      vipTier: vipTier,
      idNumber: 'ID-${_uuid.v4().substring(0, 6).toUpperCase()}',
      specialRequests: specialNotes,
      totalStays: 1,
    );
    _guests.add(newGuest);

    final newReservation = ReservationModel(
      id: reservationId,
      bookingReference: reservationRef,
      branchId: _activeBranch.id,
      guestId: guestId,
      roomTypeId: roomTypeId,
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      bookingStatus: ReservationStatus.confirmed,
      bookingSource: bookingSource,
      ratePerNight: ratePerNight,
      advancePaid: advancePaid,
      specialNotes: specialNotes,
      guestName: guestName,
      guestPhone: guestPhone,
      guestVipTier: vipTier,
      roomNumber: 'Unassigned',
      roomTypeName: roomTypeName,
    );
    _reservations.insert(0, newReservation);

    if (SupabaseConfig.isInitialized && SupabaseConfig.client != null) {
      SupabaseConfig.client!.from('guests').upsert(newGuest.toSupabaseJson()).then((_) {}).catchError((_) {});
    }
    _pushReservationToSupabase(newReservation);

    notifyListeners();
  }

  // 4. Express Check-Out Workflow
  void checkOutGuest({
    required String roomId,
    PaymentMethod settlementMethod = PaymentMethod.creditCard,
  }) {
    final roomIdx = _rooms.indexWhere((r) => r.id == roomId);
    if (roomIdx == -1) return;

    final room = _rooms[roomIdx];
    final roomNumber = room.roomNumber;

    // Settle folio
    final folioIdx = _folios.indexWhere(
      (f) => f.roomNumber == roomNumber && f.status == 'open',
    );
    if (folioIdx != -1) {
      final currentFolio = _folios[folioIdx];
      final balance = currentFolio.balanceDue;

      final updatedTxns = List<FolioTransactionModel>.from(currentFolio.transactions);
      if (balance > 0) {
        updatedTxns.add(
          FolioTransactionModel(
            id: 'ft-${_uuid.v4().substring(0, 6)}',
            folioId: currentFolio.id,
            category: FolioCategory.payment,
            description: 'Final Checkout Settlement (${settlementMethod.label})',
            amount: balance,
            isCredit: true,
            paymentMethod: settlementMethod,
            referenceId: 'SETTLE-${_uuid.v4().substring(0, 6).toUpperCase()}',
            timestamp: DateTime.now(),
          ),
        );
      }

      _folios[folioIdx] = currentFolio.copyWith(
        status: 'settled',
        transactions: updatedTxns,
      );
      _pushFolioToSupabase(_folios[folioIdx]);
      if (balance > 0) {
        _pushFolioTransactionToSupabase(updatedTxns.last);
      }
    }

    // Update Reservation if exists
    final resIdx = _reservations.indexWhere(
      (res) => res.roomNumber == roomNumber && res.bookingStatus == ReservationStatus.checkedIn,
    );
    if (resIdx != -1) {
      _reservations[resIdx] = _reservations[resIdx].copyWith(
        bookingStatus: ReservationStatus.checkedOut,
        actualCheckOut: DateTime.now(),
      );
      _pushReservationToSupabase(_reservations[resIdx]);
    }

    // Mark Room Dirty & Generate Housekeeping Task
    _rooms[roomIdx] = room.copyWith(
      status: RoomStatus.dirtyVacant,
      clearGuest: true,
      notes: 'Guest checked out. Ready for turnover cleaning.',
    );
    _pushRoomToSupabase(_rooms[roomIdx]);

    final newTask = HousekeepingTaskModel(
      id: 'hk-${_uuid.v4().substring(0, 8)}',
      branchId: _activeBranch.id,
      roomId: room.id,
      roomNumber: room.roomNumber,
      floorNumber: room.floorNumber,
      taskType: 'Checkout Deep Clean & Linen Turnover',
      priority: HousekeepingPriority.urgentRush,
      status: 'pending',
      assignedStaff: 'Housekeeping Team',
      createdAt: DateTime.now(),
    );
    _housekeepingTasks.insert(0, newTask);
    _pushHousekeepingTaskToSupabase(newTask);

    notifyListeners();
  }

  // 5. Post Transaction to Guest Room Folio (e.g. F&B Restaurant, Spa, Minibar)
  bool postChargeToRoomFolio({
    required String roomNumber,
    required FolioCategory category,
    required String description,
    required double amount,
    required double taxAmount,
    String? referenceId,
  }) {
    final folioIdx = _folios.indexWhere(
      (f) => f.roomNumber == roomNumber && f.status == 'open',
    );
    if (folioIdx == -1) return false;

    final currentFolio = _folios[folioIdx];
    final newTxn = FolioTransactionModel(
      id: 'ft-${_uuid.v4().substring(0, 8)}',
      folioId: currentFolio.id,
      category: category,
      description: description,
      amount: amount,
      taxAmount: taxAmount,
      isCredit: false,
      referenceId: referenceId,
      timestamp: DateTime.now(),
    );

    final updatedTxns = List<FolioTransactionModel>.from(currentFolio.transactions)..add(newTxn);
    _folios[folioIdx] = currentFolio.copyWith(transactions: updatedTxns);

    _pushFolioToSupabase(_folios[folioIdx]);
    _pushFolioTransactionToSupabase(newTxn);

    notifyListeners();
    return true;
  }

  // 6. Record Payment on Folio (Split Payment / Partial Payment)
  void recordFolioPayment({
    required String folioId,
    required double amount,
    required PaymentMethod method,
    String? reference,
  }) {
    final folioIdx = _folios.indexWhere((f) => f.id == folioId);
    if (folioIdx == -1) return;

    final currentFolio = _folios[folioIdx];
    final newPayment = FolioTransactionModel(
      id: 'ft-${_uuid.v4().substring(0, 8)}',
      folioId: folioId,
      category: FolioCategory.payment,
      description: 'Payment Received via ${method.label}',
      amount: amount,
      taxAmount: 0.0,
      isCredit: true,
      paymentMethod: method,
      referenceId: reference ?? 'PAY-${_uuid.v4().substring(0, 6).toUpperCase()}',
      timestamp: DateTime.now(),
    );

    final updatedTxns = List<FolioTransactionModel>.from(currentFolio.transactions)..add(newPayment);
    final isFullyPaid = (currentFolio.copyWith(transactions: updatedTxns).balanceDue <= 0.01);

    _folios[folioIdx] = currentFolio.copyWith(
      transactions: updatedTxns,
      status: isFullyPaid ? 'settled' : 'open',
    );

    _pushFolioToSupabase(_folios[folioIdx]);
    _pushFolioTransactionToSupabase(newPayment);

    notifyListeners();
  }

  // 7. Housekeeping Workflow Progression
  void progressHousekeepingTask(String taskId, String newStatus, {String? notes}) {
    final idx = _housekeepingTasks.indexWhere((h) => h.id == taskId);
    if (idx == -1) return;

    final task = _housekeepingTasks[idx];
    _housekeepingTasks[idx] = task.copyWith(
      status: newStatus,
      inspectionNotes: notes ?? task.inspectionNotes,
      completedAt: newStatus == 'inspected_approved' ? DateTime.now() : null,
    );

    // Sync Room status
    final roomIdx = _rooms.indexWhere((r) => r.id == task.roomId);
    if (roomIdx != -1) {
      if (newStatus == 'in_progress') {
        _rooms[roomIdx] = _rooms[roomIdx].copyWith(status: RoomStatus.cleaningInProgress);
      } else if (newStatus == 'cleaned') {
        _rooms[roomIdx] = _rooms[roomIdx].copyWith(status: RoomStatus.availableClean);
      } else if (newStatus == 'inspected_approved') {
        _rooms[roomIdx] = _rooms[roomIdx].copyWith(status: RoomStatus.cleanInspected);
      }
    }

    if (SupabaseConfig.isInitialized && SupabaseConfig.client != null) {
      SupabaseConfig.client!.from('housekeeping_tasks').update({
        'status': newStatus,
        'inspection_notes': notes ?? task.inspectionNotes,
        'completed_at': newStatus == 'inspected_approved' ? DateTime.now().toIso8601String() : null,
      }).eq('id', taskId).then((_) {}).catchError((_) {});

      if (roomIdx != -1) {
        SupabaseConfig.client!.from('rooms').update({
          'status': _rooms[roomIdx].status.code,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', task.roomId).then((_) {}).catchError((_) {});
      }
    }

    notifyListeners();
  }

  // 8. F&B Restaurant POS Order & KOT Generation
  void placePosOrder({
    required String outletId,
    String? tableNumber,
    String? roomNumber,
    required List<PosOrderItem> items,
    bool chargeToRoom = false,
  }) {
    if (items.isEmpty) return;

    final orderNumber = 'KOT-${1000 + _posOrders.length + 1}';
    final subtotal = items.fold(0.0, (sum, i) => sum + i.subtotal);
    final tax = items.fold(0.0, (sum, i) => sum + i.tax);
    final total = subtotal + tax;

    String? folioId;
    if (chargeToRoom && roomNumber != null) {
      final folio = _folios.firstWhere(
        (f) => f.roomNumber == roomNumber && f.status == 'open',
        orElse: () => _folios.first,
      );
      folioId = folio.id;

      postChargeToRoomFolio(
        roomNumber: roomNumber,
        category: FolioCategory.restaurant,
        description: 'F&B Order $orderNumber (${items.length} items)',
        amount: subtotal,
        taxAmount: tax,
        referenceId: orderNumber,
      );
    }

    final newOrder = PosOrderModel(
      id: 'pos-${_uuid.v4().substring(0, 8)}',
      outletId: outletId,
      orderNumber: orderNumber,
      tableNumber: tableNumber,
      roomNumber: roomNumber,
      status: PosOrderStatus.kotPrinted,
      items: items,
      subtotal: subtotal,
      tax: tax,
      total: total,
      chargedToFolioId: folioId,
      createdAt: DateTime.now(),
    );

    _posOrders.insert(0, newOrder);
    _pushPosOrderToSupabase(newOrder);
    notifyListeners();
  }

  // ── Dedicated POS Billing Generators ──────────────────────────────────────

  // A. Create & Settle Table Dining Bill
  PosBillRecord createTableDiningBill({
    required String outletId,
    required String outletName,
    required String tableNumber,
    required int covers,
    required String waiterName,
    required List<PosOrderItem> items,
    required double subtotal,
    required double taxAmount,
    required double totalAmount,
    required String paymentMethod,
  }) {
    final billNumber = 'BILL-TAB-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final bill = PosBillRecord(
      id: 'bill-${_uuid.v4().substring(0, 8)}',
      billNumber: billNumber,
      billingType: PosBillingType.tableDining,
      branchId: _activeBranch.id,
      outletId: outletId,
      outletName: outletName,
      tableNumber: tableNumber,
      covers: covers,
      waiterName: waiterName,
      items: List.from(items),
      subtotal: subtotal,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      paymentStatus: 'paid',
      createdAt: DateTime.now(),
    );

    _posBills.insert(0, bill);
    _pushBillToSupabase(bill);

    // Also register KOT ticket
    placePosOrder(
      outletId: outletId,
      tableNumber: tableNumber,
      items: items,
      chargeToRoom: false,
    );

    notifyListeners();
    return bill;
  }

  // B. Create & Post Room Folio Bill
  PosBillRecord? createRoomFolioBill({
    required String outletId,
    required String outletName,
    required String roomNumber,
    String? deliverySteward,
    required List<PosOrderItem> items,
    required double subtotal,
    required double taxAmount,
    required double totalAmount,
  }) {
    final folioIdx = _folios.indexWhere((f) => f.roomNumber == roomNumber && f.status == 'open');
    if (folioIdx == -1) return null;

    final targetFolio = _folios[folioIdx];
    final billNumber = 'BILL-RM-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    // Post charge directly into guest master folio ledger
    postChargeToRoomFolio(
      roomNumber: roomNumber,
      category: FolioCategory.restaurant,
      description: 'In-Room Dining: ${items.map((e) => "${e.quantity}x ${e.name}").join(", ")}',
      amount: subtotal,
      taxAmount: taxAmount,
      referenceId: billNumber,
    );

    final bill = PosBillRecord(
      id: 'bill-${_uuid.v4().substring(0, 8)}',
      billNumber: billNumber,
      billingType: PosBillingType.roomFolio,
      branchId: _activeBranch.id,
      outletId: outletId,
      outletName: outletName,
      roomNumber: roomNumber,
      guestName: targetFolio.guestName,
      folioId: targetFolio.id,
      deliverySteward: deliverySteward ?? 'Room Service Steward',
      items: List.from(items),
      subtotal: subtotal,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
      paymentMethod: 'Room Folio',
      paymentStatus: 'posted_to_folio',
      createdAt: DateTime.now(),
    );

    _posBills.insert(0, bill);
    _pushBillToSupabase(bill);

    placePosOrder(
      outletId: outletId,
      roomNumber: roomNumber,
      items: items,
      chargeToRoom: true,
    );

    notifyListeners();
    return bill;
  }

  // C. Create Hall & Banquet Booking Bill
  PosBillRecord createHallBookingBill({
    required String outletId,
    required String outletName,
    required String hallName,
    required String eventName,
    required String hostName,
    required String hostPhone,
    required String eventSlot,
    required int paxCount,
    required double hallRentAmount,
    required double cateringAmount,
    required double taxAmount,
    required double advancePaid,
    required String paymentMethod,
    List<PosOrderItem>? items,
  }) {
    final billNumber = 'BILL-BANQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final subtotal = hallRentAmount + cateringAmount;
    final totalAmount = subtotal + taxAmount;
    final balanceDue = (totalAmount - advancePaid).clamp(0.0, double.infinity);
    final isSettled = balanceDue <= 0.01;

    final defaultItem = PosOrderItem(
      menuItemId: 'banq-pkg-${_uuid.v4().substring(0, 4)}',
      name: '$hallName — $eventName ($paxCount Pax Event & Catering Package)',
      quantity: 1,
      price: cateringAmount > 0 ? cateringAmount : subtotal,
    );

    final bill = PosBillRecord(
      id: 'bill-${_uuid.v4().substring(0, 8)}',
      billNumber: billNumber,
      billingType: PosBillingType.hallBooking,
      branchId: _activeBranch.id,
      outletId: outletId,
      outletName: outletName,
      hallName: hallName,
      eventName: eventName,
      hostName: hostName,
      hostPhone: hostPhone,
      eventSlot: eventSlot,
      paxCount: paxCount,
      hallRentAmount: hallRentAmount,
      cateringAmount: cateringAmount,
      advancePaid: advancePaid,
      balanceDue: balanceDue,
      items: (items != null && items.isNotEmpty) ? List.from(items) : [defaultItem],
      subtotal: subtotal,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      paymentStatus: isSettled ? 'paid' : 'partial_advance',
      createdAt: DateTime.now(),
    );

    _posBills.insert(0, bill);
    _pushBillToSupabase(bill);
    notifyListeners();
    return bill;
  }


  // 9. Night Audit Simulation
  void runNightAudit() {
    // Auto-post nightly room charge for occupied rooms
    for (final room in activeBranchRooms) {
      if (room.status == RoomStatus.occupied) {
        postChargeToRoomFolio(
          roomNumber: room.roomNumber,
          category: FolioCategory.roomCharge,
          description: 'Nightly Room Tariff & Tax (Daily Night Audit)',
          amount: room.basePrice,
          taxAmount: room.basePrice * 0.18,
          referenceId: 'AUDIT-${DateTime.now().day}-${DateTime.now().month}',
        );
      }
    }
    notifyListeners();
  }

  // 10. Analytics Metrics (ADR, RevPAR, Occupancy Rate)
  double get occupancyRate {
    final total = activeBranchRooms.length;
    if (total == 0) return 0.0;
    final occupied = activeBranchRooms.where((r) => r.status == RoomStatus.occupied).length;
    return (occupied / total) * 100;
  }

  double get averageDailyRate {
    final occupiedRooms = activeBranchRooms.where((r) => r.status == RoomStatus.occupied);
    if (occupiedRooms.isEmpty) return 0.0;
    final totalTariff = occupiedRooms.fold(0.0, (sum, r) => sum + r.basePrice);
    return totalTariff / occupiedRooms.length;
  }

  double get revenuePerAvailableRoom {
    final total = activeBranchRooms.length;
    if (total == 0) return 0.0;
    final occupiedRooms = activeBranchRooms.where((r) => r.status == RoomStatus.occupied);
    final totalTariff = occupiedRooms.fold(0.0, (sum, r) => sum + r.basePrice);
    return totalTariff / total;
  }

  int get availableRoomsCount =>
      activeBranchRooms.where((r) => r.status == RoomStatus.availableClean || r.status == RoomStatus.cleanInspected).length;

  int get occupiedRoomsCount =>
      activeBranchRooms.where((r) => r.status == RoomStatus.occupied).length;

  int get dirtyRoomsCount =>
      activeBranchRooms.where((r) => r.status == RoomStatus.dirtyVacant || r.status == RoomStatus.cleaningInProgress).length;

  // ── MASTER SECTION CRUD ──────────────────────────────────────────────

  // ── Room Type Management ──
  void addRoomType({
    required String name,
    required String code,
    required double basePrice,
    required String bedType,
    required int maxAdults,
    String? description,
  }) {
    final newType = RoomTypeModel(
      id: 'rt-${_uuid.v4().substring(0, 8)}',
      branchId: _activeBranch.id,
      name: name,
      code: code.toUpperCase(),
      basePrice: basePrice,
      maxAdults: maxAdults,
      maxChildren: 1,
      bedType: bedType,
      description: description ?? '',
      amenities: [],
    );
    _roomTypes.add(newType);
    _pushRoomTypeToSupabase(newType);
    notifyListeners();
  }

  void updateRoomTypePrice(String roomTypeId, double newPrice) {
    final idx = _roomTypes.indexWhere((rt) => rt.id == roomTypeId);
    if (idx != -1) {
      _roomTypes[idx] = _roomTypes[idx].copyWith(basePrice: newPrice);
      _pushRoomTypeToSupabase(_roomTypes[idx]);
      // Also update all rooms of this type
      for (int i = 0; i < _rooms.length; i++) {
        if (_rooms[i].roomTypeId == roomTypeId) {
          _rooms[i] = _rooms[i].copyWith(basePrice: newPrice);
          _pushRoomToSupabase(_rooms[i]);
        }
      }
      notifyListeners();
    }
  }

  void updateRoomType(String roomTypeId, {String? name, String? bedType, int? maxAdults, String? description}) {
    final idx = _roomTypes.indexWhere((rt) => rt.id == roomTypeId);
    if (idx != -1) {
      _roomTypes[idx] = _roomTypes[idx].copyWith(
        name: name,
        bedType: bedType,
        maxAdults: maxAdults,
        description: description,
      );
      _pushRoomTypeToSupabase(_roomTypes[idx]);
      notifyListeners();
    }
  }

  void deleteRoomType(String roomTypeId) {
    // Only delete if no rooms are assigned to it
    final hasRooms = _rooms.any((r) => r.roomTypeId == roomTypeId && r.branchId == _activeBranch.id);
    if (!hasRooms) {
      _roomTypes.removeWhere((rt) => rt.id == roomTypeId);
      if (SupabaseConfig.isInitialized && SupabaseConfig.client != null) {
        SupabaseConfig.client!.from('room_types').delete().eq('id', roomTypeId).then((_) {}).catchError((_) {});
      }
      notifyListeners();
    }
  }

  // ── Floor Management ──
  void addFloor(int floorNumber, {String? label}) {
    final exists = _floors.any(
      (f) => f['branch_id'] == _activeBranch.id && f['floor_number'] == floorNumber,
    );
    if (!exists) {
      final newFloor = {
        'id': 'floor-${_uuid.v4().substring(0, 6)}',
        'branch_id': _activeBranch.id,
        'floor_number': floorNumber,
        'label': label ?? 'Floor $floorNumber',
      };
      _floors.add(newFloor);
      _pushFloorToSupabase(newFloor);
      notifyListeners();
    }
  }

  void deleteFloor(int floorNumber) {
    final hasRooms = _rooms.any(
      (r) => r.branchId == _activeBranch.id && r.floorNumber == floorNumber,
    );
    if (!hasRooms) {
      _floors.removeWhere(
        (f) => f['branch_id'] == _activeBranch.id && f['floor_number'] == floorNumber,
      );
      if (SupabaseConfig.isInitialized && SupabaseConfig.client != null) {
        SupabaseConfig.client!.from('floors').delete().eq('branch_id', _activeBranch.id).eq('floor_number', floorNumber).then((_) {}).catchError((_) {});
      }
      notifyListeners();
    }
  }

  // ── Room Management ──
  void addRoom({
    required String roomNumber,
    required int floorNumber,
    required String roomTypeId,
    required double basePrice,
    String? bedType,
    int? maxOccupancy,
  }) {
    final roomType = _roomTypes.firstWhere(
      (rt) => rt.id == roomTypeId,
      orElse: () => _roomTypes.first,
    );
    final newRoom = RoomModel(
      id: 'room-${_uuid.v4().substring(0, 8)}',
      branchId: _activeBranch.id,
      roomNumber: roomNumber,
      floorNumber: floorNumber,
      roomTypeId: roomTypeId,
      roomTypeName: roomType.name,
      basePrice: basePrice,
      bedType: bedType ?? roomType.bedType,
      maxOccupancy: maxOccupancy ?? roomType.maxAdults,
      status: RoomStatus.availableClean,
      amenities: roomType.amenities,
    );
    _rooms.add(newRoom);
    _pushRoomToSupabase(newRoom);
    notifyListeners();
  }

  void updateRoom(String roomId, {String? roomNumber, double? basePrice, String? bedType, int? maxOccupancy}) {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx != -1) {
      _rooms[idx] = _rooms[idx].copyWith(
        roomNumber: roomNumber,
        basePrice: basePrice,
        bedType: bedType,
        maxOccupancy: maxOccupancy,
      );
      _pushRoomToSupabase(_rooms[idx]);
      notifyListeners();
    }
  }

  void deleteRoom(String roomId) {
    final room = _rooms.firstWhere((r) => r.id == roomId, orElse: () => _rooms.first);
    if (room.status != RoomStatus.occupied) {
      _rooms.removeWhere((r) => r.id == roomId);
      if (SupabaseConfig.isInitialized && SupabaseConfig.client != null) {
        SupabaseConfig.client!.from('rooms').delete().eq('id', roomId).then((_) {}).catchError((_) {});
      }
      notifyListeners();
    }
  }

  // ── Menu Item Management ──
  void addMenuItem({
    required String outletId,
    required String name,
    required String category,
    required double price,
    required double taxRate,
    bool isVeg = true,
    String? description,
    String? imageUrl,
  }) {
    final newItem = PosMenuItemModel(
      id: 'menu-${_uuid.v4().substring(0, 8)}',
      outletId: outletId,
      name: name,
      category: category,
      price: price,
      taxRate: taxRate,
      isVeg: isVeg,
      description: description ?? '',
      imageUrl: imageUrl,
      isAvailable: true,
    );
    _posMenuItems.add(newItem);
    _pushMenuItemToSupabase(newItem);
    notifyListeners();
  }

  void updateMenuItemPrice(String itemId, double newPrice) {
    final idx = _posMenuItems.indexWhere((m) => m.id == itemId);
    if (idx != -1) {
      _posMenuItems[idx] = _posMenuItems[idx].copyWith(price: newPrice);
      _pushMenuItemToSupabase(_posMenuItems[idx]);
      notifyListeners();
    }
  }

  void updateMenuItem(String itemId, {
    String? name,
    String? category,
    double? price,
    bool? isVeg,
    bool? isAvailable,
    double? taxRate,
    String? description,
    String? imageUrl,
    String? emoji,
  }) {
    final idx = _posMenuItems.indexWhere((m) => m.id == itemId);
    if (idx != -1) {
      _posMenuItems[idx] = _posMenuItems[idx].copyWith(
        name: name,
        category: category,
        price: price,
        isVeg: isVeg,
        isAvailable: isAvailable,
        taxRate: taxRate,
        description: description,
        imageUrl: imageUrl,
        emoji: emoji,
      );
      _pushMenuItemToSupabase(_posMenuItems[idx]);
      notifyListeners();
    }
  }

  void deleteMenuItem(String itemId) {
    _posMenuItems.removeWhere((m) => m.id == itemId);
    if (SupabaseConfig.isInitialized && SupabaseConfig.client != null) {
      SupabaseConfig.client!.from('pos_menu_items').delete().eq('id', itemId).then((_) {}).catchError((_) {});
    }
    notifyListeners();
  }

  // ── Staff Management ──
  void addStaff({
    required String fullName,
    required String phone,
    String? email,
    required StaffDepartment department,
    required StaffRole role,
    required StaffShift shift,
    String? idNumber,
  }) {
    final newStaff = StaffModel(
      id: 'staff-${_uuid.v4().substring(0, 8)}',
      branchId: _activeBranch.id,
      fullName: fullName,
      phone: phone,
      email: email,
      department: department,
      role: role,
      shift: shift,
      joinedDate: DateTime.now(),
      idNumber: idNumber,
    );
    _staff.add(newStaff);
    _pushStaffToSupabase(newStaff);
    notifyListeners();
  }

  void updateStaff(String staffId, {
    String? fullName,
    String? phone,
    String? email,
    StaffDepartment? department,
    StaffRole? role,
    StaffShift? shift,
  }) {
    final idx = _staff.indexWhere((s) => s.id == staffId);
    if (idx != -1) {
      _staff[idx] = _staff[idx].copyWith(
        fullName: fullName,
        phone: phone,
        email: email,
        department: department,
        role: role,
        shift: shift,
      );
      _pushStaffToSupabase(_staff[idx]);
      notifyListeners();
    }
  }

  void toggleStaffActive(String staffId) {
    final idx = _staff.indexWhere((s) => s.id == staffId);
    if (idx != -1) {
      _staff[idx] = _staff[idx].copyWith(isActive: !_staff[idx].isActive);
      _pushStaffToSupabase(_staff[idx]);
      notifyListeners();
    }
  }

  void removeStaff(String staffId) {
    _staff.removeWhere((s) => s.id == staffId);
    if (SupabaseConfig.isInitialized && SupabaseConfig.client != null) {
      SupabaseConfig.client!.from('staff_members').delete().eq('id', staffId).then((_) {}).catchError((_) {});
    }
    notifyListeners();
  }

  // ── User Management ──
  void addUser({
    required String username,
    required String displayName,
    required AppUserRole role,
    required List<String> branchAccess,
    String? staffId,
  }) {
    final newUser = AppUserModel(
      id: 'usr-${_uuid.v4().substring(0, 8)}',
      staffId: staffId,
      username: username,
      displayName: displayName,
      role: role,
      branchAccess: branchAccess,
      createdAt: DateTime.now(),
    );
    _appUsers.add(newUser);
    _pushUserToSupabase(newUser);
    notifyListeners();
  }

  void updateUser(String userId, {AppUserRole? role, List<String>? branchAccess, bool? isActive}) {
    final idx = _appUsers.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      _appUsers[idx] = _appUsers[idx].copyWith(
        role: role,
        branchAccess: branchAccess,
        isActive: isActive,
      );
      _pushUserToSupabase(_appUsers[idx]);
      notifyListeners();
    }
  }

  void removeUser(String userId) {
    _appUsers.removeWhere((u) => u.id == userId);
    if (SupabaseConfig.isInitialized && SupabaseConfig.client != null) {
      SupabaseConfig.client!.from('app_users').delete().eq('id', userId).then((_) {}).catchError((_) {});
    }
    notifyListeners();
  }

  // ── Customer & Online Food Delivery Logic ─────────────────────────────
  CustomerModel? get currentCustomer => _currentCustomer;
  bool get isCustomerLoggedIn => _currentCustomer != null;
  CustomerAddressModel? get selectedDeliveryAddress => _selectedDeliveryAddress;
  List<CustomerCartItem> get customerCart => List.unmodifiable(_customerCart);
  int get customerCartCount => _customerCart.fold(0, (sum, i) => sum + i.quantity);
  double get customerCartSubtotal => _customerCart.fold(0.0, (sum, i) => sum + i.subtotal);
  double get customerCartGst => customerCartSubtotal * 0.05;
  double get customerCartDeliveryFee => _selectedDeliveryAddress != null
      ? GeofenceService.calculateDeliveryFee(
          distanceKm: _selectedDeliveryAddress!.distanceKmFromHotel,
          subtotal: customerCartSubtotal,
        )
      : 0.0;
  double get customerCartPackaging => _customerCart.isNotEmpty ? 25.0 : 0.0;
  double get customerCartDiscount => customerCartSubtotal * (_couponDiscountPercentage / 100.0);
  double get customerCartGrandTotal =>
      (customerCartSubtotal + customerCartGst + customerCartDeliveryFee + customerCartPackaging - customerCartDiscount)
          .clamp(0.0, double.infinity);
  String? get appliedCouponCode => _appliedCouponCode;
  double get couponDiscountPercentage => _couponDiscountPercentage;
  List<CustomerFoodOrderModel> get customerOrders => List.unmodifiable(_customerOrders);
  List<DeliveryRiderModel> get deliveryRiders => List.unmodifiable(_deliveryRiders);
  String? get latestGeneratedOtp => _latestGeneratedOtp;
  String? get lastOtpChannel => _lastOtpChannel;
  String? get lastOtpDestination => _lastOtpDestination;
  bool get isDeliveryAllowed => _selectedDeliveryAddress?.isWithin10Km ?? true;

  List<CustomerModel> _registeredCustomers = [
    CustomerModel(
      id: 'cust-amit-01',
      name: 'Amit Sharma',
      phone: '9876543210',
      email: 'amit.sharma@example.com',
      password: 'pass123',
      addresses: [
        CustomerAddressModel(
          id: 'addr-01',
          label: 'Home',
          fullAddress: 'Flat 604, Orchid Heights, Chakala, Andheri East, Mumbai',
          landmark: 'Near Chakala Metro Station',
          city: 'Mumbai',
          pincode: '400069',
          latitude: 19.1136,
          longitude: 72.8697,
          distanceKmFromHotel: 2.8,
          isWithin10Km: true,
        ),
      ],
      walletBalance: 250.0,
      joinedDate: DateTime(2026, 1, 15),
    ),
  ];

  bool loginCustomer(String phoneOrEmail, String password) {
    final cleanInput = phoneOrEmail.replaceAll(RegExp(r'[\s\-+]'), '');
    final match = _registeredCustomers.firstWhere(
      (c) {
        final cleanPhone = c.phone.replaceAll(RegExp(r'[\s\-+]'), '');
        final matchesPhone = cleanPhone == cleanInput || cleanPhone.endsWith(cleanInput) || cleanInput.endsWith(cleanPhone);
        final matchesEmail = c.email.toLowerCase() == phoneOrEmail.trim().toLowerCase();
        return (matchesPhone || matchesEmail) && c.password == password;
      },
      orElse: () => CustomerModel(
        id: 'cust-${_uuid.v4().substring(0, 6)}',
        name: phoneOrEmail.contains('@') ? phoneOrEmail.split('@').first : 'Customer',
        phone: phoneOrEmail,
        email: phoneOrEmail.contains('@') ? phoneOrEmail : '$cleanInput@customer.com',
        password: password,
        addresses: _selectedDeliveryAddress != null ? [_selectedDeliveryAddress!] : [],
        walletBalance: 150.0,
        joinedDate: DateTime.now(),
      ),
    );

    _currentCustomer = match;
    if (match.addresses.isNotEmpty) {
      _selectedDeliveryAddress = match.primaryAddress;
    }
    notifyListeners();
    return true;
  }

  void registerCustomer({
    required String name,
    required String phone,
    String? email,
    String addressText = '',
    String? address,
    String addressType = 'Home',
    String password = 'pass',
    double lat = 19.1136,
    double lng = 72.8697,
    String? city,
    String? gstin,
    String? companyName,
    double walletBalance = 150.0,
  }) {
    final finalAddress = addressText.trim().isNotEmpty ? addressText.trim() : (address?.trim() ?? '');
    final distance = GeofenceService.getDistanceForBranch(
      branchCode: _activeBranch.code,
      customerLat: lat,
      customerLng: lng,
    );
    CustomerAddressModel? newAddress;
    if (finalAddress.isNotEmpty) {
      newAddress = CustomerAddressModel(
        id: 'addr-${_uuid.v4().substring(0, 6)}',
        label: addressType,
        fullAddress: finalAddress,
        city: city ?? _activeBranch.city,
        latitude: lat,
        longitude: lng,
        distanceKmFromHotel: distance,
        isWithin10Km: distance <= GeofenceService.maxDeliveryRadiusKm,
      );
      _selectedDeliveryAddress = newAddress;
    }
    final cleanEmail = (email != null && email.trim().isNotEmpty) ? email.trim() : '$phone@customer.com';
    final newCust = CustomerModel(
      id: 'cust-${_uuid.v4().substring(0, 6)}',
      name: name.trim(),
      phone: phone.trim(),
      email: cleanEmail,
      password: password,
      city: city?.trim() ?? _activeBranch.city,
      gstin: gstin?.trim().toUpperCase(),
      companyName: companyName?.trim(),
      addresses: newAddress != null ? [newAddress] : [],
      walletBalance: walletBalance,
      totalVisits: 1,
      joinedDate: DateTime.now(),
    );
    _registeredCustomers.insert(0, newCust);
    _currentCustomer = newCust;
    _pushCustomerToSupabase(newCust);
    notifyListeners();
  }

  void setCustomer(CustomerModel customer) {
    _currentCustomer = customer;
    if (customer.addresses.isNotEmpty) {
      _selectedDeliveryAddress = customer.primaryAddress;
    }
    notifyListeners();
  }

  void logoutCustomer() {
    _currentCustomer = null;
    notifyListeners();
  }

  void setSelectedDeliveryAddress(CustomerAddressModel address) {
    _selectedDeliveryAddress = address;
    notifyListeners();
  }

  void addCustomerAddress(CustomerAddressModel address) {
    if (_currentCustomer != null) {
      final updated = List<CustomerAddressModel>.from(_currentCustomer!.addresses)..add(address);
      _currentCustomer = _currentCustomer!.copyWith(addresses: updated);
      _selectedDeliveryAddress = address;
      final cIdx = _registeredCustomers.indexWhere((c) => c.id == _currentCustomer!.id);
      if (cIdx != -1) {
        _registeredCustomers[cIdx] = _currentCustomer!;
      }
      _pushCustomerToSupabase(_currentCustomer!);
      notifyListeners();
    }
  }

  void addToCustomerCart(PosMenuItemModel item) {
    final index = _customerCart.indexWhere((c) => c.menuItemId == item.id);
    if (index != -1) {
      _customerCart[index].quantity += 1;
    } else {
      _customerCart.add(
        CustomerCartItem(
          menuItemId: item.id,
          name: item.name,
          price: item.price,
          isVeg: item.isVeg,
          imageUrl: item.imageUrl,
          category: item.category,
          quantity: 1,
        ),
      );
    }
    notifyListeners();
  }

  void updateCartItemQuantity(String menuItemId, int delta) {
    final index = _customerCart.indexWhere((c) => c.menuItemId == menuItemId);
    if (index != -1) {
      _customerCart[index].quantity += delta;
      if (_customerCart[index].quantity <= 0) {
        _customerCart.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeFromCustomerCart(String menuItemId) {
    _customerCart.removeWhere((c) => c.menuItemId == menuItemId);
    notifyListeners();
  }

  void clearCustomerCart() {
    _customerCart.clear();
    _appliedCouponCode = null;
    _couponDiscountPercentage = 0.0;
    notifyListeners();
  }

  bool applyCoupon(String code) {
    final upper = code.trim().toUpperCase();
    if (upper == 'HOTELPRO50' || upper == 'WELCOME50') {
      _appliedCouponCode = upper;
      _couponDiscountPercentage = 50.0;
      notifyListeners();
      return true;
    } else if (upper == 'FLAT20' || upper == 'HOTELPRO20') {
      _appliedCouponCode = upper;
      _couponDiscountPercentage = 20.0;
      notifyListeners();
      return true;
    } else if (upper == 'ROYAL10') {
      _appliedCouponCode = upper;
      _couponDiscountPercentage = 10.0;
      notifyListeners();
      return true;
    }
    return false;
  }

  void removeCoupon() {
    _appliedCouponCode = null;
    _couponDiscountPercentage = 0.0;
    notifyListeners();
  }

  CustomerFoodOrderModel? placeCustomerFoodOrder({
    required OnlinePaymentMethod paymentMethod,
    required String transactionId,
  }) {
    if (_customerCart.isEmpty || _selectedDeliveryAddress == null) return null;

    final distance = _selectedDeliveryAddress!.distanceKmFromHotel;
    final etaMinutes = GeofenceService.calculateEstimatedMinutes(distance);

    final newOrder = CustomerFoodOrderModel(
      id: 'ORD-HP-${1000 + _customerOrders.length + 1}',
      branchId: _activeBranch.id,
      branchName: _activeBranch.name,
      customerId: _currentCustomer?.id ?? 'guest-cust',
      customerName: _currentCustomer?.name ?? 'Guest Customer',
      customerPhone: _currentCustomer?.phone ?? '+91 99999 88888',
      deliveryAddress: _selectedDeliveryAddress!,
      items: List.from(_customerCart),
      itemTotal: customerCartSubtotal,
      gstAmount: customerCartGst,
      deliveryFee: customerCartDeliveryFee,
      packagingCharge: customerCartPackaging,
      discountAmount: customerCartDiscount,
      couponCodeApplied: _appliedCouponCode,
      grandTotal: customerCartGrandTotal,
      paymentMethod: paymentMethod,
      paymentStatus: OnlinePaymentStatus.success,
      transactionId: transactionId,
      orderStatus: CustomerOrderStatus.placed,
      riderName: 'Ramesh Patel',
      riderPhone: '+91 98201 54321',
      riderVehicleNo: 'MH 02 CZ 4421',
      estimatedDeliveryMinutes: etaMinutes,
      createdAt: DateTime.now(),
    );

    _customerOrders.insert(0, newOrder);
    _pushCustomerOrderToSupabase(newOrder);

    // Synchronize to Hotel ERP POS Kitchen Orders Ticket (KOT)!
    final kotOrder = PosOrderModel(
      id: 'pos-${_uuid.v4().substring(0, 8)}',
      outletId: _posOutlets.isNotEmpty ? _posOutlets.first.id : 'outlet-1',
      orderNumber: 'KOT-DEL-${newOrder.id}',
      tableNumber: 'DELIVERY (${distance}km)',
      guestName: '${newOrder.customerName} [${newOrder.customerPhone}]',
      status: PosOrderStatus.kotPrinted,
      items: newOrder.items
          .map((ci) => PosOrderItem(
                menuItemId: ci.menuItemId,
                name: ci.name,
                price: ci.price,
                quantity: ci.quantity,
              ))
          .toList(),
      subtotal: newOrder.itemTotal,
      tax: newOrder.gstAmount,
      total: newOrder.grandTotal,
      createdAt: DateTime.now(),
    );
    _posOrders.insert(0, kotOrder);
    _pushPosOrderToSupabase(kotOrder);

    // Synchronize to Windows Desktop ERP Kitchen POS
    HotelSyncBridgeService.instance.sendKotToWindowsErp(
      tableNumber: kotOrder.tableNumber ?? 'DELIVERY',
      items: kotOrder.items,
      guestName: kotOrder.guestName ?? 'Online Customer',
      guestPhone: newOrder.customerPhone,
      guestAddress: newOrder.deliveryAddress.fullAddress,
      notes: 'Online Delivery Order ${newOrder.id}',
    );

    // Clear cart after successful placement
    _customerCart.clear();
    _appliedCouponCode = null;
    _couponDiscountPercentage = 0.0;

    notifyListeners();
    return newOrder;
  }

  void updateCustomerOrderStatus(String orderId, CustomerOrderStatus newStatus) {
    final idx = _customerOrders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      final existing = _customerOrders[idx];
      double? lat = existing.currentRiderLat ?? (existing.deliveryAddress.latitude - 0.012);
      double? lng = existing.currentRiderLng ?? (existing.deliveryAddress.longitude - 0.010);
      if (newStatus == CustomerOrderStatus.delivered) {
        lat = existing.deliveryAddress.latitude;
        lng = existing.deliveryAddress.longitude;
      }
      _customerOrders[idx] = existing.copyWith(
        orderStatus: newStatus,
        currentRiderLat: lat,
        currentRiderLng: lng,
        estimatedDeliveryMinutes: newStatus == CustomerOrderStatus.delivered
            ? 0
            : (newStatus == CustomerOrderStatus.outForDelivery ? 10 : 25),
      );

      if (SupabaseConfig.isInitialized && SupabaseConfig.client != null) {
        SupabaseConfig.client!.from('customer_orders').update({
          'order_status': newStatus.name,
        }).eq('id', orderId).then((_) {}).catchError((_) {});
      }

      notifyListeners();
    }
  }

  void assignDeliveryRider(String orderId, DeliveryRiderModel rider) {
    final idx = _customerOrders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      final existing = _customerOrders[idx];
      _customerOrders[idx] = existing.copyWith(
        riderName: rider.name,
        riderPhone: rider.phone,
        riderVehicleNo: rider.vehicleNo,
        riderRating: rider.rating,
        riderPhotoUrl: rider.photoUrl,
        currentRiderLat: existing.deliveryAddress.latitude - 0.016,
        currentRiderLng: existing.deliveryAddress.longitude - 0.012,
      );

      if (SupabaseConfig.isInitialized && SupabaseConfig.client != null) {
        SupabaseConfig.client!.from('customer_orders').update({
          'rider_name': rider.name,
          'rider_phone': rider.phone,
          'rider_vehicle_no': rider.vehicleNo,
        }).eq('id', orderId).then((_) {}).catchError((_) {});
      }

      notifyListeners();
    }
  }

  // ── Delivery Rider CRUD ───────────────────────────────────────────────────
  void addDeliveryRider(DeliveryRiderModel rider) {
    _deliveryRiders.add(rider);
    _pushDeliveryRiderToSupabase(rider);
    notifyListeners();
  }

  void updateDeliveryRider(DeliveryRiderModel updated) {
    final idx = _deliveryRiders.indexWhere((r) => r.id == updated.id);
    if (idx != -1) {
      _deliveryRiders[idx] = updated;
      _pushDeliveryRiderToSupabase(updated);
      notifyListeners();
    }
  }

  void removeDeliveryRider(String riderId) {
    _deliveryRiders.removeWhere((r) => r.id == riderId);
    if (SupabaseConfig.isInitialized && SupabaseConfig.client != null) {
      SupabaseConfig.client!.from('delivery_riders').delete().eq('id', riderId).then((_) {}).catchError((_) {});
    }
    notifyListeners();
  }

  void toggleRiderAvailability(String riderId) {
    final idx = _deliveryRiders.indexWhere((r) => r.id == riderId);
    if (idx != -1) {
      final r = _deliveryRiders[idx];
      final updated = r.copyWith(isAvailable: !r.isAvailable);
      _deliveryRiders[idx] = updated;
      _pushDeliveryRiderToSupabase(updated);
      notifyListeners();
    }
  }

  // ── Mobile App Suite Helper Methods ────────────────────────────────────────

  /// Waiter POS: Punches digital KOT order directly to the restaurant order stream
  PosOrderModel punchWaiterKotOrder({
    required String tableNumber,
    required List<PosOrderItem> items,
    String? waiterName,
    String? notes,
    String? guestName,
    String? guestPhone,
    String? guestDob,
    String? guestAddress,
  }) {
    final subtotal = items.fold(0.0, (sum, i) => sum + (i.price * i.quantity));
    final tax = subtotal * 0.05;
    final total = subtotal + tax;
    final orderNum = 'KOT-WTR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    String guestTag = 'Table $tableNumber';
    if (guestName != null && guestName.trim().isNotEmpty) {
      guestTag = guestName.trim();
      if (guestPhone != null && guestPhone.trim().isNotEmpty) {
        guestTag += ' • ${guestPhone.trim()}';
      }
    } else if (waiterName != null) {
      guestTag = 'Waiter: $waiterName';
    }

    final newOrder = PosOrderModel(
      id: 'wtr-kot-${DateTime.now().millisecondsSinceEpoch}',
      outletId: _posOutlets.isNotEmpty ? _posOutlets.first.id : 'outlet-1',
      orderNumber: orderNum,
      tableNumber: tableNumber,
      guestName: guestTag,
      status: PosOrderStatus.kotPrinted,
      items: items,
      subtotal: subtotal,
      tax: tax,
      total: total,
      createdAt: DateTime.now(),
    );

    _posOrders.insert(0, newOrder);
    _pushPosOrderToSupabase(newOrder);
    notifyListeners();
    return newOrder;
  }

  /// Waiter POS: Settles and finalizes bill for a table order with payment and discount
  PosOrderModel settleWaiterTableOrder({
    required String orderId,
    required String paymentMethod,
    double discount = 0.0,
  }) {
    final idx = _posOrders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      final existing = _posOrders[idx];
      final settled = existing.copyWith(
        status: PosOrderStatus.settled,
      );
      _posOrders[idx] = settled;

      // Automatically register bill in POS Bills Master Register so Windows ERP displays it immediately
      final discountedSubtotal = (existing.subtotal - discount).clamp(0.0, double.infinity);
      final taxAmt = discountedSubtotal * 0.05;
      final grandTotal = discountedSubtotal + taxAmt;
      final billNum = 'BILL-WTR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      String cleanWaiterName = 'Waiter Staff';
      if (existing.guestName?.contains('Waiter:') == true) {
        cleanWaiterName = existing.guestName?.replaceFirst('Waiter: ', '').trim() ?? 'Waiter Staff';
      }

      final bill = PosBillRecord(
        id: 'bill-${_uuid.v4().substring(0, 8)}',
        billNumber: billNum,
        billingType: PosBillingType.tableDining,
        branchId: _activeBranch.id,
        outletId: existing.outletId,
        outletName: _posOutlets.where((o) => o.id == existing.outletId).firstOrNull?.name ?? 'The Royal Bistro',
        tableNumber: existing.tableNumber,
        covers: 2,
        waiterName: cleanWaiterName,
        items: List.from(existing.items),
        subtotal: discountedSubtotal,
        taxAmount: taxAmt,
        totalAmount: grandTotal,
        paymentMethod: paymentMethod,
        paymentStatus: 'paid',
        createdAt: DateTime.now(),
      );
      _posBills.insert(0, bill);
      _pushBillToSupabase(bill);

      // Update Supabase online status
      if (SupabaseConfig.isInitialized && SupabaseConfig.client != null) {
        SupabaseConfig.client!.from('pos_orders').update({
          'status': 'settled',
        }).eq('order_number', existing.orderNumber).then((_) {}).catchError((_) {});
      }

      // Handle Room Folio settlement: automatically post to guest master folio
      if (paymentMethod == 'Room Folio' || paymentMethod.toLowerCase().contains('room')) {
        final roomMatch = RegExp(r'\b(10[1-9]|20[1-9]|30[1-9]|40[1-9]|PH-[0-9]+)\b')
            .firstMatch('${existing.tableNumber} ${existing.guestName ?? ""}');
        if (roomMatch != null) {
          final rmNo = roomMatch.group(1)!;
          postChargeToRoomFolio(
            roomNumber: rmNo,
            category: FolioCategory.restaurant,
            description: 'Table ${existing.tableNumber} Dining: ${existing.items.map((e) => "${e.quantity}x ${e.name}").join(", ")}',
            amount: discountedSubtotal,
            taxAmount: taxAmt,
            referenceId: billNum,
          );
        }
      }

      notifyListeners();
      return settled;
    }
    return _posOrders.first;
  }

  /// Housekeeping: Updates room cleaning state and synchronizes corresponding task
  void updateRoomHousekeepingStatus({
    required String roomId,
    required RoomStatus newStatus,
    String? staffName,
    String? notes,
  }) {
    final roomIdx = _rooms.indexWhere((r) => r.id == roomId);
    if (roomIdx != -1) {
      _rooms[roomIdx] = _rooms[roomIdx].copyWith(
        status: newStatus,
        notes: notes ?? _rooms[roomIdx].notes,
      );

      final taskIdx = _housekeepingTasks.indexWhere((t) => t.roomId == roomId);
      if (taskIdx != -1) {
        String taskStatus = 'pending';
        DateTime? completedAt;
        if (newStatus == RoomStatus.cleaningInProgress) {
          taskStatus = 'in_progress';
        } else if (newStatus == RoomStatus.availableClean) {
          taskStatus = 'cleaned';
          completedAt = DateTime.now();
        } else if (newStatus == RoomStatus.cleanInspected) {
          taskStatus = 'inspected_approved';
          completedAt = DateTime.now();
        }
        _housekeepingTasks[taskIdx] = _housekeepingTasks[taskIdx].copyWith(
          status: taskStatus,
          assignedStaff: staffName ?? _housekeepingTasks[taskIdx].assignedStaff,
          completedAt: completedAt,
        );
      }

      // Asynchronously dispatch to Windows Desktop ERP & Cloud
      HotelSyncBridgeService.instance.sendHousekeepingUpdateToWindowsErp(
        roomId: roomId,
        newStatus: newStatus,
        staffName: staffName,
        notes: notes,
      );

      if (SupabaseConfig.isInitialized && SupabaseConfig.client != null) {
        SupabaseConfig.client!.from('rooms').update({
          'status': newStatus.code,
          'notes': notes ?? _rooms[roomIdx].notes,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', roomId).then((_) {}).catchError((_) {});

        if (taskIdx != -1) {
          SupabaseConfig.client!.from('housekeeping_tasks').update({
            'status': _housekeepingTasks[taskIdx].status,
            'assigned_staff_name': staffName ?? _housekeepingTasks[taskIdx].assignedStaff,
            'completed_at': _housekeepingTasks[taskIdx].completedAt?.toIso8601String(),
          }).eq('room_id', roomId).then((_) {}).catchError((_) {});
        }
      }

      notifyListeners();
    }
  }

  /// Housekeeping: Marks inspection checklist as approved and ready for guests
  void completeHousekeepingTask({
    required String taskId,
    required String inspectionNotes,
  }) {
    final taskIdx = _housekeepingTasks.indexWhere((t) => t.id == taskId);
    if (taskIdx != -1) {
      final task = _housekeepingTasks[taskIdx];
      _housekeepingTasks[taskIdx] = task.copyWith(
        status: 'inspected_approved',
        inspectionNotes: inspectionNotes,
        completedAt: DateTime.now(),
      );
      final roomIdx = _rooms.indexWhere((r) => r.id == task.roomId);
      if (roomIdx != -1) {
        _rooms[roomIdx] = _rooms[roomIdx].copyWith(status: RoomStatus.cleanInspected);
      }

      if (SupabaseConfig.isInitialized && SupabaseConfig.client != null) {
        SupabaseConfig.client!.from('housekeeping_tasks').update({
          'status': 'inspected_approved',
          'inspection_notes': inspectionNotes,
          'completed_at': DateTime.now().toIso8601String(),
        }).eq('id', taskId).then((_) {}).catchError((_) {});

        SupabaseConfig.client!.from('rooms').update({
          'status': RoomStatus.cleanInspected.code,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', task.roomId).then((_) {}).catchError((_) {});
      }

      notifyListeners();
    }
  }

  /// Housekeeping: Logs out-of-order room defect / maintenance requirement
  void reportRoomMaintenanceIssue({
    required String roomId,
    required String issueDescription,
    String? reportedBy,
  }) {
    final roomIdx = _rooms.indexWhere((r) => r.id == roomId);
    if (roomIdx != -1) {
      _rooms[roomIdx] = _rooms[roomIdx].copyWith(
        status: RoomStatus.outOfOrder,
        notes: 'Maintenance: $issueDescription [Reported: ${reportedBy ?? "Housekeeping Mobile"}]',
      );
      _pushRoomToSupabase(_rooms[roomIdx]);
      notifyListeners();
    }
  }

  /// Delivery Boy: Advances rider delivery order status through fulfillment lifecycle
  void advanceDeliveryOrderStatus({
    required String orderId,
    required CustomerOrderStatus newStatus,
    String? riderId,
  }) {
    final idx = _customerOrders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      final order = _customerOrders[idx];
      String? riderName = order.riderName;
      String? riderPhone = order.riderPhone;
      String? riderVehicleNo = order.riderVehicleNo;

      if (riderId != null) {
        final rider = _deliveryRiders.firstWhere(
          (r) => r.id == riderId,
          orElse: () => _deliveryRiders.first,
        );
        riderName = rider.name;
        riderPhone = rider.phone;
        riderVehicleNo = rider.vehicleNo;
      }

      final paymentStatus = newStatus == CustomerOrderStatus.delivered
          ? OnlinePaymentStatus.success
          : order.paymentStatus;

      _customerOrders[idx] = order.copyWith(
        orderStatus: newStatus,
        paymentStatus: paymentStatus,
        riderName: riderName,
        riderPhone: riderPhone,
        riderVehicleNo: riderVehicleNo,
      );

      // Asynchronously dispatch to Windows Desktop ERP & Cloud
      HotelSyncBridgeService.instance.sendDeliveryUpdateToWindowsErp(
        orderId: orderId,
        status: newStatus,
      );

      if (SupabaseConfig.isInitialized && SupabaseConfig.client != null) {
        SupabaseConfig.client!.from('customer_orders').update({
          'order_status': newStatus.name,
          'payment_status': paymentStatus.name,
          'rider_name': riderName,
          'rider_phone': riderPhone,
          'rider_vehicle_no': riderVehicleNo,
        }).eq('id', orderId).then((_) {}).catchError((_) {});
      }

      notifyListeners();
    }
  }

  /// Manager MIS: Aggregates real-time executive pulse & financial metrics
  Map<String, dynamic> getManagerMisStats() {
    final totalRooms = activeBranchRooms.length;
    final occupiedRooms = activeBranchRooms.where((r) => r.isOccupied).length;
    final dirtyRooms = activeBranchRooms.where((r) => r.status == RoomStatus.dirtyVacant || r.status == RoomStatus.cleaningInProgress).length;
    final cleanRooms = activeBranchRooms.where((r) => r.status == RoomStatus.availableClean || r.status == RoomStatus.cleanInspected).length;
    final oooRooms = activeBranchRooms.where((r) => r.status == RoomStatus.outOfOrder).length;
    final occupancyPct = totalRooms > 0 ? (occupiedRooms / totalRooms) * 100.0 : 0.0;

    final roomRevenue = activeBranchFolios.fold(0.0, (sum, f) => sum + f.totalCharges);
    final posRevenue = activeBranchPosBills.fold(0.0, (sum, b) => sum + b.totalAmount);
    final deliveryRevenue = customerOrders
        .where((o) => o.orderStatus != CustomerOrderStatus.cancelled)
        .fold(0.0, (sum, o) => sum + o.grandTotal);
    final totalRevenue = roomRevenue + posRevenue + deliveryRevenue;

    final adr = occupiedRooms > 0 ? (roomRevenue / occupiedRooms) : 2850.0;
    final revPar = totalRooms > 0 ? (roomRevenue / totalRooms) : (adr * occupancyPct / 100);

    final activeKotCount = posOrders.where((o) => o.status != PosOrderStatus.settled && o.status != PosOrderStatus.cancelled).length;
    final pendingDeliveries = customerOrders.where((o) => o.orderStatus == CustomerOrderStatus.placed || o.orderStatus == CustomerOrderStatus.kitchenPreparing || o.orderStatus == CustomerOrderStatus.outForDelivery).length;

    return {
      'totalRooms': totalRooms,
      'occupiedRooms': occupiedRooms,
      'dirtyRooms': dirtyRooms,
      'cleanRooms': cleanRooms,
      'oooRooms': oooRooms,
      'occupancyPct': occupancyPct,
      'roomRevenue': roomRevenue,
      'posRevenue': posRevenue,
      'deliveryRevenue': deliveryRevenue,
      'totalRevenue': totalRevenue,
      'adr': adr,
      'revPar': revPar,
      'activeKotCount': activeKotCount,
      'pendingDeliveries': pendingDeliveries,
      'activeRidersCount': deliveryRiders.where((r) => r.isAvailable).length,
    };
  }

  void addSimulatedCustomerOrder(CustomerFoodOrderModel order) {
    _customerOrders.insert(0, order);
    _pushCustomerOrderToSupabase(order);
    notifyListeners();
  }

  Future<String> sendSmsOtp(String phone) async {
    const code = '123456';
    _latestGeneratedOtp = code;
    _lastOtpChannel = 'SMS';
    _lastOtpDestination = phone.isNotEmpty ? phone : '+91 98765 43210';
    notifyListeners();
    return code;
  }

  Future<String> sendEmailOtp(String email) async {
    const code = '123456';
    _latestGeneratedOtp = code;
    _lastOtpChannel = 'Email';
    _lastOtpDestination = email.isNotEmpty ? email : 'user@example.com';
    notifyListeners();
    return code;
  }

  bool verifyOtp(String inputOtp) {
    final clean = inputOtp.trim();
    return clean == '123456' || clean == '1234' || clean == _latestGeneratedOtp;
  }

  void addCustomerDeliveryAddress(CustomerAddressModel address) {
    if (_currentCustomer != null) {
      final updatedAddresses = List<CustomerAddressModel>.from(_currentCustomer!.addresses)..add(address);
      _currentCustomer = _currentCustomer!.copyWith(addresses: updatedAddresses);
      final cIdx = _registeredCustomers.indexWhere((c) => c.id == _currentCustomer!.id);
      if (cIdx != -1) {
        _registeredCustomers[cIdx] = _currentCustomer!;
      }
      _pushCustomerToSupabase(_currentCustomer!);
    }
    _selectedDeliveryAddress = address;
    notifyListeners();
  }

  // ===========================================================================
  // Accounting, Purchase, Expense & Balance Sheet Management
  // ===========================================================================

  List<PurchaseEntry> get purchases => List.unmodifiable(_purchases);
  List<ExpenseEntry> get expenses => List.unmodifiable(_expenses);

  List<PurchaseEntry> get activeBranchPurchases =>
      _purchases.where((p) => p.branchId == _activeBranch.id).toList();

  List<ExpenseEntry> get activeBranchExpenses =>
      _expenses.where((e) => e.branchId == _activeBranch.id).toList();

  void addPurchaseEntry(PurchaseEntry entry) {
    _purchases.insert(0, entry);
    _pushPurchaseToSupabase(entry);

    // Automatically synchronize & increment live Stock & Inventory levels!
    for (final item in entry.items) {
      final matchIdx = _stockItems.indexWhere((s) =>
          s.branchId == entry.branchId &&
          (s.name.trim().toLowerCase() == item.name.trim().toLowerCase() ||
           s.id == item.id));

      if (matchIdx != -1) {
        final existing = _stockItems[matchIdx];
        final updated = existing.copyWith(
          currentStock: existing.currentStock + item.quantity,
          unitPrice: item.unitPrice > 0 ? item.unitPrice : existing.unitPrice,
          lastRestockedAt: entry.purchaseDate,
        );
        _stockItems[matchIdx] = updated;
        _pushStockItemToSupabase(updated);
      } else {
        final prefix = item.category.length >= 2 ? item.category.substring(0, 2).toUpperCase() : 'SK';
        final newStock = StockItemModel(
          id: 'stk-${_uuid.v4().substring(0, 8)}',
          branchId: entry.branchId,
          itemCode: 'STK-$prefix-${(100 + _stockItems.length + 1)}',
          name: item.name,
          category: item.category,
          unit: item.unit,
          currentStock: item.quantity,
          reorderLevel: (item.quantity * 0.25).clamp(5.0, 50.0),
          unitPrice: item.unitPrice,
          storageLocation: 'Central Store',
          lastRestockedAt: entry.purchaseDate,
        );
        _stockItems.add(newStock);
        _pushStockItemToSupabase(newStock);
      }
    }

    notifyListeners();
    _saveAccountingData();
  }

  // ===========================================================================
  // Stock & Inventory Management
  // ===========================================================================
  List<StockItemModel> get stockItems => List.unmodifiable(_stockItems);

  List<StockItemModel> get activeBranchStockItems =>
      _stockItems.where((s) => s.branchId == _activeBranch.id).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  double get totalStockValuation =>
      activeBranchStockItems.fold(0.0, (sum, i) => sum + i.stockValue);

  int get lowStockCount =>
      activeBranchStockItems.where((i) => i.isLowStock).length;

  int get outOfStockCount =>
      activeBranchStockItems.where((i) => i.isOutOfStock).length;

  void addStockItem(StockItemModel item) {
    _stockItems.add(item);
    _pushStockItemToSupabase(item);
    notifyListeners();
  }

  void updateStockItem(StockItemModel item) {
    final idx = _stockItems.indexWhere((s) => s.id == item.id);
    if (idx != -1) {
      _stockItems[idx] = item;
      _pushStockItemToSupabase(item);
      notifyListeners();
    }
  }

  void adjustStockQuantity(String itemId, double delta) {
    final idx = _stockItems.indexWhere((s) => s.id == itemId);
    if (idx != -1) {
      final existing = _stockItems[idx];
      final newQty = (existing.currentStock + delta).clamp(0.0, 999999.0);
      final updated = existing.copyWith(currentStock: newQty);
      _stockItems[idx] = updated;
      _pushStockItemToSupabase(updated);
      notifyListeners();
    }
  }

  void deleteStockItem(String itemId) {
    _stockItems.removeWhere((s) => s.id == itemId);
    if (SupabaseConfig.isInitialized && SupabaseConfig.client != null) {
      SupabaseConfig.client!.from('stock_items').delete().eq('id', itemId).then((_) {}).catchError((_) {});
    }
    notifyListeners();
  }

  void updatePurchaseEntry(PurchaseEntry entry) {
    final idx = _purchases.indexWhere((p) => p.id == entry.id);
    if (idx != -1) {
      _purchases[idx] = entry;
      _pushPurchaseToSupabase(entry);
      notifyListeners();
      _saveAccountingData();
    }
  }

  void deletePurchaseEntry(String id) {
    _purchases.removeWhere((p) => p.id == id);
    if (SupabaseConfig.isInitialized && SupabaseConfig.client != null) {
      SupabaseConfig.client!.from('purchases').delete().eq('id', id).then((_) {}).catchError((_) {});
    }
    notifyListeners();
    _saveAccountingData();
  }

  void addExpenseEntry(ExpenseEntry entry) {
    _expenses.insert(0, entry);
    _pushExpenseToSupabase(entry);
    notifyListeners();
    _saveAccountingData();
  }

  void updateExpenseEntry(ExpenseEntry entry) {
    final idx = _expenses.indexWhere((e) => e.id == entry.id);
    if (idx != -1) {
      _expenses[idx] = entry;
      _pushExpenseToSupabase(entry);
      notifyListeners();
      _saveAccountingData();
    }
  }

  void deleteExpenseEntry(String id) {
    _expenses.removeWhere((e) => e.id == id);
    if (SupabaseConfig.isInitialized && SupabaseConfig.client != null) {
      SupabaseConfig.client!.from('expenses').delete().eq('id', id).then((_) {}).catchError((_) {});
    }
    notifyListeners();
    _saveAccountingData();
  }

  Future<void> _saveAccountingData() async {
    try {
      await HotelConfigStorage.saveAccountingData(
        purchases: _purchases.map((p) => p.toJson()).toList(),
        expenses: _expenses.map((e) => e.toJson()).toList(),
      );
    } catch (_) {}
  }

  Future<void> _loadSavedAccountingData() async {
    try {
      final data = await HotelConfigStorage.loadAccountingData();
      if (data != null) {
        final pList = data['purchases'] as List?;
        if (pList != null && pList.isNotEmpty) {
          _purchases = pList.map((i) => PurchaseEntry.fromJson(i as Map<String, dynamic>)).toList();
        }
        final eList = data['expenses'] as List?;
        if (eList != null && eList.isNotEmpty) {
          _expenses = eList.map((i) => ExpenseEntry.fromJson(i as Map<String, dynamic>)).toList();
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  BalanceSheetData getActiveBranchBalanceSheet({DateTime? asOfDate}) {
    final date = asOfDate ?? DateTime.now();
    final branchId = _activeBranch.id;

    // Current Assets
    final branchRoomNumbers = _rooms.where((r) => r.branchId == branchId).map((r) => r.roomNumber).toSet();
    final branchFolios = _folios.where((f) => branchRoomNumbers.contains(f.roomNumber)).toList();

    final cashPayments = branchFolios
        .expand((f) => f.transactions)
        .where((t) => t.isCredit && (t.paymentMethod == PaymentMethod.cash || t.description.toLowerCase().contains('cash')))
        .fold(0.0, (s, t) => s + t.amount);
    final cashExpenses = _expenses
        .where((e) => e.branchId == branchId && e.paymentMode.toLowerCase().contains('cash'))
        .fold(0.0, (s, e) => s + e.netAmount);
    final cashOnHand = (150000.0 + cashPayments - cashExpenses).clamp(25000.0, 5000000.0);

    final bankPayments = branchFolios
        .expand((f) => f.transactions)
        .where((t) => t.isCredit && t.paymentMethod != PaymentMethod.cash && !t.description.toLowerCase().contains('cash'))
        .fold(0.0, (s, t) => s + t.amount);
    final bankPurchases = _purchases
        .where((p) => p.branchId == branchId && p.paymentStatus == 'Paid')
        .fold(0.0, (s, p) => s + p.grandTotal);
    final bankExpenses = _expenses
        .where((e) => e.branchId == branchId && !e.paymentMode.toLowerCase().contains('cash'))
        .fold(0.0, (s, e) => s + e.netAmount);
    final bankBalance = (850000.0 + bankPayments - bankPurchases - bankExpenses).clamp(100000.0, 25000000.0);

    final guestLedgerReceivables = branchFolios
        .where((f) => f.status == 'open')
        .fold(0.0, (s, f) => s + f.balanceDue);

    final totalPurchases = _purchases
        .where((p) => p.branchId == branchId)
        .fold(0.0, (s, p) => s + p.grandTotal);
    final inventoryStock = (totalPurchases * 0.45).clamp(85000.0, 1500000.0);

    final currentAssets = [
      FinancialLineItem(code: 'CA-101', title: 'Cash on Hand (Front Desk & Petty Cash)', amount: cashOnHand),
      FinancialLineItem(code: 'CA-102', title: 'Bank Operating Accounts (Current Accounts)', amount: bankBalance),
      FinancialLineItem(code: 'CA-103', title: 'Accounts Receivable (In-House Guest Ledger)', amount: guestLedgerReceivables),
      FinancialLineItem(code: 'CA-104', title: 'Closing Inventory (F&B Provisions & Operating Supplies)', amount: inventoryStock),
      const FinancialLineItem(code: 'CA-105', title: 'Prepaid Insurance & Operational Advances', amount: 125000.0),
    ];

    // Fixed Assets
    double propertyValue = 125000000.0;
    if (branchId.contains('goa')) propertyValue = 85000000.0;
    if (branchId.contains('pun')) propertyValue = 62000000.0;

    final fixedAssets = [
      FinancialLineItem(code: 'FA-201', title: 'Hotel Land & Freehold Building Property', amount: propertyValue),
      const FinancialLineItem(code: 'FA-202', title: 'Plant, Central HVAC & Heavy Generators', amount: 4500000.0),
      const FinancialLineItem(code: 'FA-203', title: 'Commercial Kitchen & Restaurant Equipment', amount: 2850000.0),
      const FinancialLineItem(code: 'FA-204', title: 'Guest Room Furniture, Fixtures & Fittings', amount: 3600000.0),
      const FinancialLineItem(code: 'FA-205', title: 'Computers, POS Hardware & Software Licenses', amount: 950000.0),
      const FinancialLineItem(code: 'FA-206', title: 'Less: Accumulated Depreciation Allowance', amount: -2800000.0),
    ];

    final totalAssetsCalculated = currentAssets.fold(0.0, (s, i) => s + i.amount) +
        fixedAssets.fold(0.0, (s, i) => s + i.amount);

    // Current Liabilities
    final pendingAccountsPayable = _purchases
        .where((p) => p.branchId == branchId && p.paymentStatus != 'Paid')
        .fold(0.0, (s, p) => s + p.grandTotal);
    final guestAdvanceDeposits = branchFolios
        .where((f) => f.balanceDue < 0)
        .fold(0.0, (s, f) => s + f.balanceDue.abs());
    final gstPayable = (branchFolios.fold(0.0, (s, f) => s + f.totalTaxes) * 0.5)
        .clamp(15000.0, 500000.0);

    final currentLiabilities = [
      FinancialLineItem(code: 'CL-301', title: 'Accounts Payable (Pending Supplier Invoices)', amount: pendingAccountsPayable > 0 ? pendingAccountsPayable : 42500.0),
      FinancialLineItem(code: 'CL-302', title: 'Guest Advance Booking Deposits & Credits', amount: guestAdvanceDeposits > 0 ? guestAdvanceDeposits : 85000.0),
      FinancialLineItem(code: 'CL-303', title: 'Statutory GST & Output Tax Payable', amount: gstPayable),
      const FinancialLineItem(code: 'CL-304', title: 'Accrued Operating Expenses & Staff Salaries', amount: 185000.0),
    ];

    // Long-Term Liabilities
    double termLoans = 25000000.0;
    if (branchId.contains('goa')) termLoans = 16000000.0;
    if (branchId.contains('pun')) termLoans = 11000000.0;

    final longTermLiabilities = [
      FinancialLineItem(code: 'LL-401', title: 'Secured Commercial Bank Term Loan', amount: termLoans),
      const FinancialLineItem(code: 'LL-402', title: 'Equipment Hypothecation & Vehicle Loans', amount: 1450000.0),
    ];

    final totalLiab = currentLiabilities.fold(0.0, (s, i) => s + i.amount) +
        longTermLiabilities.fold(0.0, (s, i) => s + i.amount);

    // Equity & Retained Earnings
    final totalRevenue = branchFolios.fold(0.0, (s, f) => s + f.totalCharges);
    final totalOutflow = totalPurchases + _expenses.where((e) => e.branchId == branchId).fold(0.0, (s, e) => s + e.netAmount);
    final netOperatingProfit = totalRevenue - totalOutflow;

    final targetEquity = totalAssetsCalculated - totalLiab;
    final partnerCapital = targetEquity - netOperatingProfit;

    final equityItems = [
      FinancialLineItem(code: 'EQ-501', title: "Partners' / Shareholders' Capital Account", amount: partnerCapital),
      FinancialLineItem(code: 'EQ-502', title: 'Current Year Retained Earnings (Net Operating Income)', amount: netOperatingProfit),
      const FinancialLineItem(code: 'EQ-503', title: 'General Reserve & Asset Revaluation Surplus', amount: 1500000.0),
    ];

    // Ensure mathematical balance
    final sumEquity = equityItems.fold(0.0, (s, i) => s + i.amount);
    final diff = totalAssetsCalculated - (totalLiab + sumEquity);
    if (diff.abs() > 0.01) {
      equityItems[0] = FinancialLineItem(
        code: 'EQ-501',
        title: "Partners' / Shareholders' Capital Account",
        amount: equityItems[0].amount + diff,
      );
    }

    final year = date.month >= 4 ? '${date.year}-${date.year + 1}' : '${date.year - 1}-${date.year}';

    return BalanceSheetData(
      branchId: branchId,
      branchName: _activeBranch.name,
      asOfDate: date,
      financialYear: 'FY $year',
      currentAssets: currentAssets,
      fixedAssets: fixedAssets,
      currentLiabilities: currentLiabilities,
      longTermLiabilities: longTermLiabilities,
      equityItems: equityItems,
    );
  }

  // ── Customer CRM Directory Management ──
  void updateCustomerDetails(
    String customerId, {
    required String name,
    required String phone,
    String? email,
    String? city,
    String? gstin,
    String? companyName,
    String? address,
    double? walletBalance,
  }) {
    final idx = _registeredCustomers.indexWhere((c) => c.id == customerId);
    if (idx != -1) {
      final old = _registeredCustomers[idx];
      List<CustomerAddressModel> addresses = List.from(old.addresses);
      if (address != null && address.trim().isNotEmpty) {
        if (addresses.isNotEmpty) {
          addresses[0] = CustomerAddressModel(
            id: addresses[0].id,
            label: addresses[0].label,
            fullAddress: address.trim(),
            landmark: addresses[0].landmark,
            city: city ?? addresses[0].city,
            pincode: addresses[0].pincode,
            latitude: addresses[0].latitude,
            longitude: addresses[0].longitude,
          );
        } else {
          addresses.add(
            CustomerAddressModel(
              id: 'addr-${_uuid.v4().substring(0, 6)}',
              label: 'Primary',
              fullAddress: address.trim(),
              city: city ?? _activeBranch.city,
            ),
          );
        }
      }
      _registeredCustomers[idx] = CustomerModel(
        id: old.id,
        name: name.trim(),
        phone: phone.trim(),
        email: email?.trim() ?? old.email,
        city: city?.trim() ?? old.city,
        gstin: gstin?.trim().toUpperCase() ?? old.gstin,
        companyName: companyName?.trim() ?? old.companyName,
        addresses: addresses,
        walletBalance: walletBalance ?? old.walletBalance,
        totalVisits: old.totalVisits,
        joinedDate: old.joinedDate,
      );
      _pushCustomerToSupabase(_registeredCustomers[idx]);
      notifyListeners();
    }
  }

  void deleteCustomer(String customerId) {
    _registeredCustomers.removeWhere((c) => c.id == customerId);
    if (SupabaseConfig.isInitialized && SupabaseConfig.client != null) {
      SupabaseConfig.client!.from('customers').delete().eq('id', customerId).then((_) {}).catchError((_) {});
    }
    notifyListeners();
  }

  void addCustomerWalletCredits(String customerId, double amount) {
    final idx = _registeredCustomers.indexWhere((c) => c.id == customerId);
    if (idx != -1) {
      final old = _registeredCustomers[idx];
      _registeredCustomers[idx] = CustomerModel(
        id: old.id,
        name: old.name,
        phone: old.phone,
        email: old.email,
        city: old.city,
        gstin: old.gstin,
        companyName: old.companyName,
        addresses: old.addresses,
        walletBalance: old.walletBalance + amount,
        totalVisits: old.totalVisits,
        joinedDate: old.joinedDate,
      );
      _pushCustomerToSupabase(_registeredCustomers[idx]);
      notifyListeners();
    }
  }

  // ── Unified GST & ERP Invoicing Management ──
  void addInvoice(ErpInvoiceRecord invoice) {
    _invoices.insert(0, invoice);
    notifyListeners();
  }

  void markInvoicePaid(String invoiceNumber, String paymentMode) {
    final idx = _invoices.indexWhere((inv) => inv.invoiceNumber == invoiceNumber);
    if (idx != -1) {
      final old = _invoices[idx];
      _invoices[idx] = ErpInvoiceRecord(
        invoiceNumber: old.invoiceNumber,
        type: old.type,
        customerName: old.customerName,
        customerPhone: old.customerPhone,
        customerGstin: old.customerGstin,
        customerAddress: old.customerAddress,
        date: old.date,
        taxableAmount: old.taxableAmount,
        cgst: old.cgst,
        sgst: old.sgst,
        totalAmount: old.totalAmount,
        paymentMode: paymentMode,
        status: ErpInvoiceStatus.paid,
        referenceId: old.referenceId,
        items: old.items,
      );
      if (SupabaseConfig.isInitialized && SupabaseConfig.client != null) {
        SupabaseConfig.client!.from('pos_bills').update({
          'payment_status': 'paid',
          'payment_method': paymentMode,
        }).eq('bill_number', invoiceNumber).then((_) {}).catchError((_) {});
      }
      notifyListeners();
    }
  }

  // ── Banquet & Conference Halls Management ──
  void _pushBanquetHallToSupabase(BanquetHallModel hall) {
    if (SupabaseConfig.isInitialized && SupabaseConfig.client != null) {
      SupabaseConfig.client!.from('banquet_halls').upsert(hall.toJson()).then((_) {}).catchError((_) {});
    }
  }

  void addBanquetHall({
    required String name,
    required int capacity,
    required double baseRental,
    required String features,
  }) {
    final newHall = BanquetHallModel(
      id: 'hall-${_uuid.v4().substring(0, 8)}',
      branchId: _activeBranch.id,
      name: name,
      capacity: capacity,
      baseRental: baseRental,
      features: features,
    );
    _banquetHalls.add(newHall);
    _pushBanquetHallToSupabase(newHall);
    notifyListeners();
  }

  void updateBanquetHall(BanquetHallModel hall) {
    final idx = _banquetHalls.indexWhere((h) => h.id == hall.id);
    if (idx != -1) {
      _banquetHalls[idx] = hall;
      _pushBanquetHallToSupabase(hall);
      notifyListeners();
    }
  }

  void deleteBanquetHall(String hallId) {
    _banquetHalls.removeWhere((h) => h.id == hallId);
    if (SupabaseConfig.isInitialized && SupabaseConfig.client != null) {
      SupabaseConfig.client!.from('banquet_halls').delete().eq('id', hallId).then((_) {}).catchError((_) {});
    }
    notifyListeners();
  }
}


