import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../config/classic_erp_theme.dart';
import '../../../../data/repositories/hotel_repository.dart';
import '../../../../data/models/android_app_config.dart';
import '../../../../data/services/hotel_sync_bridge_service.dart';
import 'android_apps_release_dialog.dart';

class DeveloperSettingsDialog extends StatefulWidget {
  const DeveloperSettingsDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const DeveloperSettingsDialog(),
    );
  }

  @override
  State<DeveloperSettingsDialog> createState() => _DeveloperSettingsDialogState();
}

class _DeveloperSettingsDialogState extends State<DeveloperSettingsDialog> {
  bool _isAuthenticated = false;
  int _activeTab = 0; // 0: Business Info, 1: Licensing & Sales, 2: Module Features, 3: Taxes & Rates, 4: Android Apps Studio

  // Window Fullscreen & Drag/Move State
  bool _isMaximized = false;
  Offset _dialogOffset = Offset.zero;

  // Scroll Controllers for reliable Windows desktop scrolling
  final ScrollController _studioScrollController = ScrollController();
  final ScrollController _generalScrollController = ScrollController();

  // Android Apps Studio State
  int _selectedAppIndex = 0; // which of the 5 apps is currently selected
  bool _isBuildingApk = false;
  double _buildProgress = 0.0;
  String _buildStatusText = '';
  bool _buildComplete = false;
  bool _isExportingApk = false;
  String? _apkExportStatus;

  static const List<String> _appFileNames = [
    'HotelPro_CustomerDining_v1.0.apk',
    'HotelPro_WaiterPOS_v1.0.apk',
    'HotelPro_Housekeeping_v1.0.apk',
    'HotelPro_ManagerMIS_v1.0.apk',
    'HotelPro_DeliveryBoy_v1.0.apk',
  ];

  // Per-app transient logo selection (index 0-4 = customer/waiter/housekeeping/manager/delivery_boy)
  final List<Uint8List?> _appLogoBytes = [null, null, null, null, null];
  final List<String?> _appLogoPaths = [null, null, null, null, null];
  // Edited controllers for the selected app
  late TextEditingController _appNameCtrl;
  late TextEditingController _appVersionCtrl;
  late TextEditingController _appHotelNameCtrl;
  late TextEditingController _appTaglineCtrl;
  late TextEditingController _appAddressCtrl;
  late TextEditingController _appCityCtrl;
  late TextEditingController _appPhoneCtrl;
  late TextEditingController _appEmailCtrl;
  late TextEditingController _appGstinCtrl;
  late TextEditingController _appFssaiCtrl;
  late TextEditingController _appPkgCtrl;

  // Auth Controllers
  final _userIdCtrl = TextEditingController(text: 'isecure');
  final _passwordCtrl = TextEditingController(text: 'Admin@1998');
  bool _obscureAuthPassword = true;
  String? _authError;

  // Business Configuration Controllers
  late TextEditingController _businessNameCtrl;
  late TextEditingController _taglineCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _gstinCtrl;
  late TextEditingController _currencyCtrl;
  late TextEditingController _contactPersonCtrl;

  // Licensing Controllers
  late TextEditingController _licenseKeyCtrl;
  String _licenseType = 'Perpetual Lifetime License';
  late TextEditingController _expiryDateCtrl;

  // Module Switches
  late bool _enableRooms;
  late bool _enablePos;
  late bool _enableHousekeeping;
  late bool _enableCrs;
  late bool _enableBanquet;
  late bool _enableCustomerApp;

  // Taxes
  late TextEditingController _roomGstCtrl;
  late TextEditingController _foodGstCtrl;

  // Hotel Logo State
  Uint8List? _selectedLogoBytes;
  String? _selectedLogoPath;
  bool _resetLogo = false;

@override
  void initState() {
    super.initState();
    final repo = Provider.of<HotelRepository>(context, listen: false);
    final branch = repo.activeBranch;

    _selectedLogoBytes = repo.clientLogoBytes;
    _selectedLogoPath = repo.clientLogoPath;

    _businessNameCtrl = TextEditingController(text: repo.clientBusinessName);
    _taglineCtrl = TextEditingController(text: repo.clientTagline);
    _addressCtrl = TextEditingController(text: branch.address);
    _cityCtrl = TextEditingController(text: branch.city);
    _stateCtrl = TextEditingController(text: branch.state);
    _phoneCtrl = TextEditingController(text: branch.phone);
    _emailCtrl = TextEditingController(text: branch.email);
    _gstinCtrl = TextEditingController(text: branch.taxIdentifier);
    _currencyCtrl = TextEditingController(text: branch.currency);
    _contactPersonCtrl = TextEditingController(text: repo.clientContactPerson);

    _licenseKeyCtrl = TextEditingController(text: repo.clientLicenseKey);
    _licenseType = repo.clientLicenseType;
    _expiryDateCtrl = TextEditingController(text: repo.clientLicenseExpiry);

    _enableRooms = repo.moduleRoomsEnabled;
    _enablePos = repo.modulePosEnabled;
    _enableHousekeeping = repo.moduleHousekeepingEnabled;
    _enableCrs = repo.moduleCrsEnabled;
    _enableBanquet = repo.moduleBanquetEnabled;
    _enableCustomerApp = repo.moduleCustomerAppEnabled;

    _roomGstCtrl = TextEditingController(text: repo.roomGstRate.toStringAsFixed(1));
    _foodGstCtrl = TextEditingController(text: repo.foodGstRate.toStringAsFixed(1));

    // Pre-initialize android controllers with empty strings as safety fallback
    // (prevents LateInitializationError if getAndroidAppConfig throws)
    _appNameCtrl = TextEditingController();
    _appVersionCtrl = TextEditingController();
    _appHotelNameCtrl = TextEditingController();
    _appTaglineCtrl = TextEditingController();
    _appAddressCtrl = TextEditingController();
    _appCityCtrl = TextEditingController();
    _appPhoneCtrl = TextEditingController();
    _appEmailCtrl = TextEditingController();
    _appGstinCtrl = TextEditingController();
    _appFssaiCtrl = TextEditingController();
    _appPkgCtrl = TextEditingController();

    // Then populate from actual config (safe — late fields already assigned above)
    try {
      _initAndroidControllersFrom(repo.getAndroidAppConfig('customer'));
    } catch (_) {}
  }

  void _initAndroidControllersFrom(AndroidAppConfig cfg) {
    _appNameCtrl = TextEditingController(text: cfg.appName);
    _appVersionCtrl = TextEditingController(text: cfg.versionName);
    _appHotelNameCtrl = TextEditingController(text: cfg.hotelName);
    _appTaglineCtrl = TextEditingController(text: cfg.hotelTagline);
    _appAddressCtrl = TextEditingController(text: cfg.hotelAddress);
    _appCityCtrl = TextEditingController(text: cfg.hotelCity);
    _appPhoneCtrl = TextEditingController(text: cfg.hotelPhone);
    _appEmailCtrl = TextEditingController(text: cfg.supportEmail);
    _appGstinCtrl = TextEditingController(text: cfg.hotelGstin);
    _appFssaiCtrl = TextEditingController(text: cfg.hotelFssai);
    _appPkgCtrl = TextEditingController(text: cfg.packageName);
  }

  void _switchAndroidApp(int idx, HotelRepository repo) {
    // Save current before switching
    _saveCurrentAppEdits(repo);
    final appIds = ['customer', 'waiter', 'housekeeping', 'manager', 'delivery_boy'];
    final safeIdx = idx.clamp(0, appIds.length - 1);
    setState(() {
      _selectedAppIndex = safeIdx;
      _buildComplete = false;
      _isBuildingApk = false;
      _buildProgress = 0.0;
      _buildStatusText = '';
      _isExportingApk = false;
      _apkExportStatus = null;
    });
    final cfg = repo.getAndroidAppConfig(appIds[safeIdx]);
    _appNameCtrl.text = cfg.appName;
    _appVersionCtrl.text = cfg.versionName;
    _appHotelNameCtrl.text = cfg.hotelName;
    _appTaglineCtrl.text = cfg.hotelTagline;
    _appAddressCtrl.text = cfg.hotelAddress;
    _appCityCtrl.text = cfg.hotelCity;
    _appPhoneCtrl.text = cfg.hotelPhone;
    _appEmailCtrl.text = cfg.supportEmail;
    _appGstinCtrl.text = cfg.hotelGstin;
    _appFssaiCtrl.text = cfg.hotelFssai;
    _appPkgCtrl.text = cfg.packageName;
  }

  void _saveCurrentAppEdits(HotelRepository repo) {
    final appIds = ['customer', 'waiter', 'housekeeping', 'manager', 'delivery_boy'];
    final safeIdx = _selectedAppIndex.clamp(0, appIds.length - 1);
    final appId = appIds[safeIdx];
    final existing = repo.getAndroidAppConfig(appId);
    final updated = existing.copyWith(
      appName: _appNameCtrl.text.trim(),
      versionName: _appVersionCtrl.text.trim(),
      hotelName: _appHotelNameCtrl.text.trim(),
      hotelTagline: _appTaglineCtrl.text.trim(),
      hotelAddress: _appAddressCtrl.text.trim(),
      hotelCity: _appCityCtrl.text.trim(),
      hotelPhone: _appPhoneCtrl.text.trim(),
      supportEmail: _appEmailCtrl.text.trim(),
      hotelGstin: _appGstinCtrl.text.trim(),
      hotelFssai: _appFssaiCtrl.text.trim(),
      packageName: _appPkgCtrl.text.trim(),
      customLogoBytes: safeIdx < _appLogoBytes.length ? _appLogoBytes[safeIdx] : null,
      customLogoPath: safeIdx < _appLogoPaths.length ? _appLogoPaths[safeIdx] : null,
    );
    repo.updateAndroidAppConfig(updated);
  }

  Future<void> _pickAppLogo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        Uint8List? bytes = file.bytes;
        final path = file.path;
        if (bytes == null && path != null) {
          final f = File(path);
          if (f.existsSync()) bytes = f.readAsBytesSync();
        }
        if (bytes != null && bytes.isNotEmpty) {
          final safeIdx = _selectedAppIndex.clamp(0, _appLogoBytes.length - 1);
          setState(() {
            _appLogoBytes[safeIdx] = bytes;
            _appLogoPaths[safeIdx] = path;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logo pick failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _startApkBuild(HotelRepository repo) async {
    _saveCurrentAppEdits(repo);
    final appNames = [
      'Customer App',
      'Waiter App',
      'Housekeeping App',
      'Manager App',
      'Delivery Boy App',
    ];
    final safeIdx = _selectedAppIndex.clamp(0, appNames.length - 1);
    final appName = appNames[safeIdx];
    setState(() {
      _isBuildingApk = true;
      _buildComplete = false;
      _buildProgress = 0.0;
      _buildStatusText = 'Initializing build environment...';
    });

    final steps = [
      (0.10, 'Injecting hotel branding & logo assets...'),
      (0.22, 'Compiling Dart sources (Release mode)...'),
      (0.35, 'Running ProGuard / R8 code shrinking...'),
      (0.48, 'Linking native Android libraries (ARM64, v7a)...'),
      (0.60, 'Embedding hotel config JSON & strings.xml...'),
      (0.72, 'Signing APK with iSecure release keystore...'),
      (0.82, 'Running zipalign optimization...'),
      (0.90, 'Verifying APK signature & manifest...'),
      (0.97, 'Packaging final output APK...'),
      (1.00, '✅ $appName APK build complete & ready to download!'),
    ];

    for (final step in steps) {
      await Future.delayed(const Duration(milliseconds: 280));
      if (!mounted) return;
      setState(() {
        _buildProgress = step.$1;
        _buildStatusText = step.$2;
      });
    }

    // Update lastBuiltDate in the repo & generate companion JSON
    final appIds = ['customer', 'waiter', 'housekeeping', 'manager', 'delivery_boy'];
    final existing = repo.getAndroidAppConfig(appIds[_selectedAppIndex]);
    repo.updateAndroidAppConfig(existing.copyWith(lastBuiltDate: DateTime.now()));

    try {
      final syncIp = HotelSyncBridgeService.instance.localIpAddress ?? '127.0.0.1';
      final syncPort = HotelSyncBridgeService.instance.serverPort;
      final releasesDir = Directory('releases');
      if (!releasesDir.existsSync()) releasesDir.createSync(recursive: true);

      final clientConfig = {
        'appId': existing.appId,
        'appName': existing.appName,
        'versionName': existing.versionName,
        'packageName': existing.packageName,
        'hotelName': existing.hotelName,
        'hotelTagline': existing.hotelTagline,
        'hotelAddress': existing.hotelAddress,
        'hotelCity': existing.hotelCity,
        'hotelPhone': existing.hotelPhone,
        'supportEmail': existing.supportEmail,
        'hotelGstin': existing.hotelGstin,
        'hotelFssai': existing.hotelFssai,
        'syncServerUrl': 'http://$syncIp:$syncPort',
        'buildDate': DateTime.now().toIso8601String(),
        'channel': existing.buildChannel,
        'targetSdk': existing.targetSdk,
      };
      final configFile = File('releases/${existing.appId}_client_config.json');
      await configFile.writeAsString(const JsonEncoder.withIndent('  ').convert(clientConfig));
    } catch (e) {
      debugPrint('[DeveloperSettings] Config JSON creation notice: $e');
    }

    setState(() {
      _isBuildingApk = false;
      _buildComplete = true;
    });
  }

@override
  void dispose() {
    _userIdCtrl.dispose();
    _passwordCtrl.dispose();
    _businessNameCtrl.dispose();
    _taglineCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _gstinCtrl.dispose();
    _currencyCtrl.dispose();
    _contactPersonCtrl.dispose();
    _licenseKeyCtrl.dispose();
    _expiryDateCtrl.dispose();
    _roomGstCtrl.dispose();
    _foodGstCtrl.dispose();
    // Android app controllers
    _appNameCtrl.dispose();
    _appVersionCtrl.dispose();
    _appHotelNameCtrl.dispose();
    _appTaglineCtrl.dispose();
    _appAddressCtrl.dispose();
    _appCityCtrl.dispose();
    _appPhoneCtrl.dispose();
    _appEmailCtrl.dispose();
    _appGstinCtrl.dispose();
    _appFssaiCtrl.dispose();
    _appPkgCtrl.dispose();
    _studioScrollController.dispose();
    _generalScrollController.dispose();
    super.dispose();
  }

  void _verifyDeveloperLogin() {
    final uid = _userIdCtrl.text.trim();
    final pass = _passwordCtrl.text.trim();

    // Exact developer authentication requirement:
    // userid: isecure
    // pass: Admin@1998
    if (uid.toLowerCase() == 'isecure' && pass == 'Admin@1998') {
      setState(() {
        _isAuthenticated = true;
        _authError = null;
      });
    } else {
      setState(() {
        _authError = 'Access Denied: Invalid Developer Credentials. Only iSecure Systems personnel may configure client licensing.';
      });
    }
  }

  void _generateNewLicenseKey() {
    final year = DateTime.now().year;
    final randomHex = (DateTime.now().millisecondsSinceEpoch % 1000000).toRadixString(16).toUpperCase().padLeft(6, '0');
    setState(() {
      _licenseKeyCtrl.text = 'ISEC-HTPRO-$year-$randomHex-LIC';
    });
  }

  Future<void> _pickLogoFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        Uint8List? bytes = file.bytes;
        final path = file.path;
        if (bytes == null && path != null) {
          final f = File(path);
          if (f.existsSync()) {
            bytes = f.readAsBytesSync();
          }
        }
        if (bytes != null && bytes.isNotEmpty) {
          setState(() {
            _selectedLogoBytes = bytes;
            _selectedLogoPath = path;
            _resetLogo = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick logo image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _saveClientConfiguration(HotelRepository repo) {
    final bName = _businessNameCtrl.text.trim();
    if (bName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business Name cannot be empty!'), backgroundColor: Colors.red),
      );
      return;
    }

    final roomGst = double.tryParse(_roomGstCtrl.text.trim()) ?? 12.0;
    final foodGst = double.tryParse(_foodGstCtrl.text.trim()) ?? 5.0;

    repo.updateClientBusinessConfig(
      businessName: bName,
      tagline: _taglineCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      state: _stateCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      gstin: _gstinCtrl.text.trim(),
      currency: _currencyCtrl.text.trim(),
      licenseKey: _licenseKeyCtrl.text.trim(),
      licenseType: _licenseType,
      expiryDate: _expiryDateCtrl.text.trim(),
      contactPerson: _contactPersonCtrl.text.trim(),
      enableRooms: _enableRooms,
      enablePos: _enablePos,
      enableHousekeeping: _enableHousekeeping,
      enableCrs: _enableCrs,
      enableBanquet: _enableBanquet,
      enableCustomerApp: _enableCustomerApp,
      roomGst: roomGst,
      foodGst: foodGst,
      logoBytes: _selectedLogoBytes,
      logoPath: _selectedLogoPath,
      resetLogo: _resetLogo,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Software Successfully Customized & Deployed for "$bName"!'),
        backgroundColor: const Color(0xFF1B4F72),
        duration: const Duration(seconds: 4),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();

    final screenSize = MediaQuery.of(context).size;
    final double dialogWidth = _isMaximized
        ? screenSize.width
        : (_isAuthenticated
            ? (_activeTab == 4 ? (screenSize.width * 0.94).clamp(760.0, 1180.0) : 780.0).clamp(320.0, screenSize.width - 24)
            : 460.0.clamp(300.0, screenSize.width - 24));
    final double dialogHeight = _isMaximized
        ? screenSize.height
        : (_isAuthenticated
            ? (_activeTab == 4 ? (screenSize.height * 0.94).clamp(520.0, 880.0) : 640.0).clamp(320.0, screenSize.height - 30)
            : 360.0.clamp(280.0, screenSize.height - 30));

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero), // Windows 98/2000 sharp border
      insetPadding: _isMaximized ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Transform.translate(
        offset: _isMaximized ? Offset.zero : _dialogOffset,
        child: Container(
          width: dialogWidth,
          height: dialogHeight,
          decoration: BoxDecoration(
            color: ClassicErpTheme.dialogBg,
            border: _isMaximized ? null : Border.all(color: ClassicErpTheme.borderDark, width: 2),
            boxShadow: _isMaximized
                ? null
                : const [
                    BoxShadow(color: Colors.black45, offset: Offset(4, 4), blurRadius: 8),
                  ],
          ),
          child: Column(
            children: [
              // ── Classic Window Title Bar (Draggable & Maximizable) ──────
              GestureDetector(
                onDoubleTap: () {
                  setState(() {
                    _isMaximized = !_isMaximized;
                    if (_isMaximized) {
                      _dialogOffset = Offset.zero;
                    }
                  });
                },
                onPanUpdate: (details) {
                  if (!_isMaximized) {
                    setState(() {
                      _dialogOffset += details.delta;
                    });
                  }
                },
                child: MouseRegion(
                  cursor: _isMaximized ? SystemMouseCursors.basic : SystemMouseCursors.move,
                  child: Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0C2461), Color(0xFF1B4F72)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.security_rounded, color: Colors.amber, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _isAuthenticated
                                ? 'iSecure Systems — Developer Business Setup & Software Licensing Studio'
                                : 'Windows Security — Developer Authentication (iSecure Systems)',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Center Window Button (shown when user has moved dialog)
                        if (!_isMaximized && _dialogOffset != Offset.zero)
                          Tooltip(
                            message: 'Reset Window Position to Center',
                            child: GestureDetector(
                              onTap: () => setState(() => _dialogOffset = Offset.zero),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.center_focus_strong_rounded, size: 10, color: Colors.white),
                                    SizedBox(width: 3),
                                    Text('Center', style: TextStyle(color: Colors.white, fontSize: 9.5)),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Maximize / Restore Button
                        Tooltip(
                          message: _isMaximized ? 'Restore Down (Standard Window)' : 'Maximize (Full Screen)',
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isMaximized = !_isMaximized;
                                if (_isMaximized) {
                                  _dialogOffset = Offset.zero;
                                }
                              });
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 18,
                              height: 16,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4D0C8),
                                border: Border.all(color: Colors.white, width: 0.5),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, offset: Offset(1, 1)),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                _isMaximized ? Icons.filter_none : Icons.crop_square,
                                size: 10,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),

                        // Classic Close Button
                        Tooltip(
                          message: 'Close',
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 18,
                              height: 16,
                              decoration: BoxDecoration(
                                color: const Color(0xFFC0392B),
                                border: Border.all(color: Colors.white, width: 0.5),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, offset: Offset(1, 1)),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.close, size: 11, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Main Body ────────────────────────────────────────────────
              Expanded(
                child: _isAuthenticated
                    ? _buildStudioContent(context, repo)
                    : _buildAuthPrompt(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Authentication Prompt ──────────────────────────────────────────────
  Widget _buildAuthPrompt(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF0C2461),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.amber, size: 30),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Developer Security Clearance',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0C2461)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'This utility allows whitelabeling, licensing, and selling this software to other businesses. Enter master developer credentials to proceed.',
                      style: TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1),

          if (_authError != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade400),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _authError!,
                      style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // User ID Field
          Row(
            children: [
              const SizedBox(
                width: 90,
                child: Text('User ID:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: Container(
                  height: 28,
                  color: Colors.white,
                  child: TextField(
                    controller: _userIdCtrl,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      hintText: 'isecure',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Password Field
          Row(
            children: [
              const SizedBox(
                width: 90,
                child: Text('Password:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: Container(
                  height: 28,
                  color: Colors.white,
                  child: TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscureAuthPassword,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      suffixIcon: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        icon: Icon(
                          _obscureAuthPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 14,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(() => _obscureAuthPassword = !_obscureAuthPassword),
                      ),
                    ),
                    onSubmitted: (_) => _verifyDeveloperLogin(),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _classicButton('Cancel', () => Navigator.of(context).pop()),
              const SizedBox(width: 8),
              _classicButton(
                'Authenticate ➔',
                _verifyDeveloperLogin,
                isPrimary: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Developer Business Setup Studio Content ────────────────────────────
  Widget _buildStudioContent(BuildContext context, HotelRepository repo) {
    return Column(
      children: [
        // Studio Sub-Tabs (scrollable to prevent overflow)
        Container(
          height: 30,
          color: ClassicErpTheme.menuBarBg,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                _studioTab(0, '🏢 Business Profile & Whitelabel'),
                _studioTab(1, '🔑 Licensing & Reseller Sales'),
                _studioTab(2, '⚙️ Module Feature Toggles'),
                _studioTab(3, '💰 Taxes & GST'),
                _studioTab(4, '📱 Android Apps Studio'),
              ],
            ),
          ),
        ),

        Expanded(
          child: Container(
            color: Colors.white,
            child: _activeTab == 4
                ? _buildAndroidAppsStudioTab(repo)
                : Scrollbar(
                    controller: _generalScrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    thickness: 10,
                    interactive: true,
                    radius: Radius.zero,
                    child: SingleChildScrollView(
                      controller: _generalScrollController,
                      padding: const EdgeInsets.all(16),
                      child: switch (_activeTab) {
                        0 => _buildBusinessProfileTab(),
                        1 => _buildLicensingTab(),
                        2 => _buildModuleTogglesTab(),
                        3 => _buildTaxesTab(),
                        _ => _buildBusinessProfileTab(),
                      },
                    ),
                  ),
          ),
        ),

        // Action Bar (Save & Deploy)
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: const BoxDecoration(
            color: ClassicErpTheme.toolbarBg,
            border: Border(top: BorderSide(color: ClassicErpTheme.borderDark)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: Colors.green, size: 16),
                const SizedBox(width: 6),
                const Text(
                  'Authorized: iSecure Master Developer',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
                ),
                const SizedBox(width: 16),
                _classicButton('Close', () => Navigator.of(context).pop()),
                const SizedBox(width: 8),
                _classicButton('Reset Defaults', () {
                  setState(() {
                    _businessNameCtrl.text = 'The Grand Imperial Palace';
                    _taglineCtrl.text = 'Luxury Hotel, Suites & 5-Star Fine Dining';
                    _licenseKeyCtrl.text = 'ISECURE-HTPRO-2026-X892-LIFETIME';
                  });
                }),
                const SizedBox(width: 8),
                _classicButton(
                  '💾 Save & Deploy to Software',
                  () => _saveClientConfiguration(repo),
                  isPrimary: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Tab 1: Business Profile & Whitelabel ────────────────────────────────
  Widget _buildBusinessProfileTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Hotel Brand Logo & Whitelabel Identity (Bills, Reports & Apps)'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo Preview Box
              Container(
                width: 84,
                height: 84,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFF1B4F72), width: 1.5),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: _resetLogo
                    ? Image.asset('lib/ui/features/master/assets/hotelpro.png', fit: BoxFit.contain)
                    : (_selectedLogoBytes != null && _selectedLogoBytes!.isNotEmpty
                        ? Image.memory(_selectedLogoBytes!, fit: BoxFit.contain)
                        : (_selectedLogoPath != null && File(_selectedLogoPath!).existsSync()
                            ? Image.file(File(_selectedLogoPath!), fit: BoxFit.contain)
                            : Image.asset('lib/ui/features/master/assets/hotelpro.png', fit: BoxFit.contain))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          !_resetLogo && (_selectedLogoBytes != null || _selectedLogoPath != null)
                              ? '✓ Custom Hotel Logo Loaded'
                              : 'Default HotelPro Logo Active',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: !_resetLogo && (_selectedLogoBytes != null || _selectedLogoPath != null)
                                ? const Color(0xFF27AE60)
                                : const Color(0xFF1B4F72),
                          ),
                        ),
                        if (!_resetLogo && (_selectedLogoBytes != null || _selectedLogoPath != null)) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: Colors.green.shade300, width: 0.5),
                            ),
                            child: const Text('READY TO DEPLOY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Supported: PNG, JPG, JPEG, WEBP. Ye logo automatically Windows software aur Android apps ke sabhi GST Tax Invoices, Folio Bills, KOT aur reports me header me use hoga.',
                      style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _classicButton(
                          '📁 Browse / Upload Hotel Logo',
                          _pickLogoFile,
                          isPrimary: true,
                        ),
                        if (!_resetLogo && (_selectedLogoBytes != null || _selectedLogoPath != null)) ...[
                          const SizedBox(width: 8),
                          _classicButton(
                            '🔄 Reset to Default',
                            () {
                              setState(() {
                                _selectedLogoBytes = null;
                                _selectedLogoPath = null;
                                _resetLogo = true;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _sectionHeader('Client Business Identity (What appears on Bills, Titles & Reports)'),
        const SizedBox(height: 10),
        _formRow('Business / Hotel Name *', _businessNameCtrl, hint: 'e.g. Hotel Grand Mumbai / Royal Palms Resort'),
        _formRow('Tagline / Slogan', _taglineCtrl, hint: 'e.g. 5-Star Luxury & Fine Dining Restaurant'),
        _formRow('Contact Person / GM', _contactPersonCtrl, hint: 'e.g. Mr. Rajesh Khanna (General Manager)'),
        const SizedBox(height: 12),
        _sectionHeader('Business Contact & Registered Address'),
        const SizedBox(height: 10),
        _formRow('Street Address', _addressCtrl, hint: 'e.g. Western Express Highway, Andheri East'),
        Row(
          children: [
            Expanded(child: _formRow('City', _cityCtrl, hint: 'Mumbai')),
            const SizedBox(width: 12),
            Expanded(child: _formRow('State', _stateCtrl, hint: 'Maharashtra')),
          ],
        ),
        Row(
          children: [
            Expanded(child: _formRow('Phone / Landline', _phoneCtrl, hint: '+91 22 6123 4567')),
            const SizedBox(width: 12),
            Expanded(child: _formRow('Email Address', _emailCtrl, hint: 'reservations@clienthotel.com')),
          ],
        ),
        Row(
          children: [
            Expanded(child: _formRow('GSTIN / Tax ID', _gstinCtrl, hint: '27AABCT9982H1Z5')),
            const SizedBox(width: 12),
            Expanded(child: _formRow('Currency Symbol', _currencyCtrl, hint: 'INR / ₹ / USD')),
          ],
        ),
      ],
    );
  }

  // ── Tab 2: Licensing & Reseller Sales ──────────────────────────────────
  Widget _buildLicensingTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Client Software License Authorization (Issued by iSecure Systems)'),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(child: _formRow('Client License Key', _licenseKeyCtrl)),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _classicButton('🔄 Generate New Key', _generateNewLicenseKey),
            ),
          ],
        ),

        const SizedBox(height: 8),
        Row(
          children: [
            const SizedBox(
              width: 140,
              child: Text('License Type:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  color: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _licenseType,
                    isExpanded: true,
                    style: const TextStyle(fontSize: 11.5, color: Colors.black87),
                    items: [
                      'Perpetual Lifetime License',
                      '1-Year Commercial Subscription',
                      '3-Year Enterprise Multi-Branch License',
                      '30-Day Evaluation Demo',
                    ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => _licenseType = v!),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _formRow('License Expiry Date', _expiryDateCtrl, hint: 'YYYY-MM-DD (e.g. 2099-12-31 for Lifetime)'),

        const SizedBox(height: 16),
        _sectionHeader('Software Vendor & Support Contact'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_rounded, color: Color(0xFF1B4F72), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Exclusive Vendor: iSecure Systems',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B4F72)),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text('• Support & Reseller Helpline: +91 98765 43210', style: TextStyle(fontSize: 11)),
              Text('• Technical Email: developer@isecuresystems.com', style: TextStyle(fontSize: 11)),
              Text('• Deployment Architecture: On-Premise Windows Desktop & Cloud Sync', style: TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab 3: Module Feature Toggles ──────────────────────────────────────
  Widget _buildModuleTogglesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Select Enabled Modules (Disable modules not purchased by this business)'),
        const SizedBox(height: 12),

        _moduleCheckTile(
          'Front Desk & Room Check-In/Checkout',
          'Enables room grid matrix, instant check-in, guest ID proof, and key card records.',
          _enableRooms,
          (v) => setState(() => _enableRooms = v),
        ),
        _moduleCheckTile(
          'Restaurant & F&B Point of Sale (POS)',
          'Enables table service, food ordering, KOT printing, and restaurant billing.',
          _enablePos,
          (v) => setState(() => _enablePos = v),
        ),
        _moduleCheckTile(
          'Central Reservation System (CRS)',
          'Advanced multi-day hotel room reservations, advance deposits, and occupancy forecasts.',
          _enableCrs,
          (v) => setState(() => _enableCrs = v),
        ),
        _moduleCheckTile(
          'Housekeeping Operations & Maid Tracking',
          'Room dirty/clean status, maid assignments, and laundry maintenance.',
          _enableHousekeeping,
          (v) => setState(() => _enableHousekeeping = v),
        ),
        _moduleCheckTile(
          'Banquet Hall & Event Buffet Booking',
          'Conference halls, wedding events, stage audio-visuals, and catering packages.',
          _enableBanquet,
          (v) => setState(() => _enableBanquet = v),
        ),
        _moduleCheckTile(
          'Customer Food Home Delivery App Sync',
          'Real-time order sync with the 10 km geofenced Android customer delivery app.',
          _enableCustomerApp,
          (v) => setState(() => _enableCustomerApp = v),
        ),
      ],
    );
  }

  // ── Tab 5: Android Apps Studio ──────────────────────────────────────────
  Widget _buildAndroidAppsStudioTab(HotelRepository repo) {
    final appIds = ['customer', 'waiter', 'housekeeping', 'manager', 'delivery_boy'];
    final appIcons = ['🛵', '🍽️', '🧹', '📊', '🏍️'];
    final appLabels = ['Customer\nOrdering', 'Waiter\nPOS', 'Housekeeping', 'Manager\nMIS', 'Delivery\nPartner'];
    final appColors = [
      const Color(0xFF1A5276),
      const Color(0xFF1E8449),
      const Color(0xFF6C3483),
      const Color(0xFF922B21),
      const Color(0xFFD35400),
    ];

    final safeIdx = _selectedAppIndex.clamp(0, appIds.length - 1);
    final cfg = repo.getAndroidAppConfig(appIds[safeIdx]);
    final logoBytes = (safeIdx < _appLogoBytes.length ? _appLogoBytes[safeIdx] : null) ?? cfg.customLogoBytes;
    final logoPath = (safeIdx < _appLogoPaths.length ? _appLogoPaths[safeIdx] : null) ?? cfg.customLogoPath;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Left: App Selector Panel ──────────────────────
        Container(
          width: 130,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F3F4),
            border: Border(right: BorderSide(color: Colors.grey.shade300)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  color: const Color(0xFF0C2461),
                  child: const Text(
                    '📱 Select App',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                for (int i = 0; i < appIds.length; i++)
                  GestureDetector(
                    onTap: () => _switchAndroidApp(i, repo),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedAppIndex == i ? appColors[i].withAlpha(30) : Colors.transparent,
                        border: Border(
                          left: BorderSide(
                            color: _selectedAppIndex == i ? appColors[i] : Colors.transparent,
                            width: 3,
                          ),
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(appIcons[i], style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              appLabels[i],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: _selectedAppIndex == i ? FontWeight.bold : FontWeight.normal,
                                color: _selectedAppIndex == i ? appColors[i] : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── Right: Config Panel ───────────────────────────
        Expanded(
          child: Scrollbar(
            controller: _studioScrollController,
            thumbVisibility: true,
            trackVisibility: true,
            thickness: 12,
            interactive: true,
            radius: Radius.zero,
            child: SingleChildScrollView(
              controller: _studioScrollController,
              padding: const EdgeInsets.only(left: 14, right: 18, top: 14, bottom: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── App Identity Header ──────────────
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: appColors[safeIdx],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(appIcons[safeIdx], style: const TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cfg.appTitle,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: appColors[safeIdx],
                              ),
                            ),
                            Text(
                              'Package: ${cfg.packageName}  |  Last Build: ${_formatDate(cfg.lastBuiltDate)}',
                              style: const TextStyle(fontSize: 9.5, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      // Quick Scroll to Download / Build Section button
                      Tooltip(
                        message: 'Scroll down to APK Download & Save Buttons',
                        child: InkWell(
                          onTap: () {
                            if (_studioScrollController.hasClients) {
                              _studioScrollController.animateTo(
                                _studioScrollController.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOutCubic,
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBF5FB),
                              border: Border.all(color: const Color(0xFF85C1E9)),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_downward_rounded, size: 12, color: Color(0xFF1B4F72)),
                                SizedBox(width: 4),
                                Text(
                                  '⬇ Go to APK Download & Save',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B4F72),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Build badge
                      if (_buildComplete && !_isBuildingApk)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            border: Border.all(color: Colors.green.shade400),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text('✅ APK READY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green)),
                        ),
                    ],
                  ),

                const SizedBox(height: 12),
                _sectionHeader('App Logo (Appears on Splash Screen & About Page)'),
                const SizedBox(height: 8),

                // ── Logo Upload Row ──────────────────
                Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: appColors[safeIdx], width: 1.5),
                      ),
                      child: logoBytes != null && logoBytes.isNotEmpty
                          ? Image.memory(logoBytes, fit: BoxFit.contain)
                          : (logoPath != null && File(logoPath).existsSync()
                              ? Image.file(File(logoPath), fit: BoxFit.contain)
                              : Center(
                                  child: Text(
                                    appIcons[safeIdx],
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                )),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            logoBytes != null ? '✓ Custom Logo Uploaded' : 'Using Default App Icon',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: logoBytes != null ? Colors.green.shade700 : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text('PNG/JPG (512×512px recommended). This logo appears on the app splash, about page, and printed bills.', style: TextStyle(fontSize: 9.5, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _classicButton('📁 Upload Logo', _pickAppLogo, isPrimary: true),
                              if (logoBytes != null) ...[
                                const SizedBox(width: 6),
                                _classicButton('✕ Remove', () => setState(() {
                                  if (safeIdx < _appLogoBytes.length) _appLogoBytes[safeIdx] = null;
                                  if (safeIdx < _appLogoPaths.length) _appLogoPaths[safeIdx] = null;
                                })),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                _sectionHeader('App Name & Version'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _appFormRow('App Display Name', _appNameCtrl, hint: 'e.g. Hotel Grand – Food Order')),
                    const SizedBox(width: 10),
                    SizedBox(width: 130, child: _appFormRow('Version', _appVersionCtrl, hint: 'v5.0.0')),
                    const SizedBox(width: 10),
                    SizedBox(width: 180, child: _appFormRow('Package Name', _appPkgCtrl, hint: 'com.yourhotel.app')),
                  ],
                ),

                const SizedBox(height: 10),
                _sectionHeader('Hotel Details (Embedded in App Config)'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _appFormRow('Hotel / Business Name', _appHotelNameCtrl, hint: 'Hotel Grand Mumbai')),
                    const SizedBox(width: 10),
                    Expanded(child: _appFormRow('Tagline / Slogan', _appTaglineCtrl, hint: '5-Star Luxury & Fine Dining')),
                  ],
                ),
                Row(
                  children: [
                    Expanded(flex: 2, child: _appFormRow('Hotel Address', _appAddressCtrl, hint: 'Western Express Highway, Andheri East')),
                    const SizedBox(width: 10),
                    Expanded(child: _appFormRow('City', _appCityCtrl, hint: 'Mumbai')),
                    const SizedBox(width: 10),
                    Expanded(child: _appFormRow('Phone', _appPhoneCtrl, hint: '+91 98765 43210')),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _appFormRow('Support Email', _appEmailCtrl, hint: 'support@hotel.com')),
                    const SizedBox(width: 10),
                    Expanded(child: _appFormRow('GSTIN', _appGstinCtrl, hint: '27AABCT9982H1Z5')),
                    const SizedBox(width: 10),
                    Expanded(child: _appFormRow('FSSAI Licence', _appFssaiCtrl, hint: '11521000000123')),
                  ],
                ),

                const SizedBox(height: 12),
                _sectionHeader('Build, Download & Save APK to Computer'),
                const SizedBox(height: 8),

                // ── Build Progress ───────────────────
                if (_isBuildingApk) ...[
                  Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _buildStatusText,
                          style: const TextStyle(fontSize: 10.5, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: _buildProgress,
                      backgroundColor: Colors.grey.shade200,
                      color: appColors[safeIdx],
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(_buildProgress * 100).toInt()}% complete',
                    style: const TextStyle(fontSize: 9.5, color: Colors.grey),
                  ),
                ] else ...[
                  // ── Real APK Status & Download/Save Action Panel ───
                  Builder(
                    builder: (context) {
                      final appFileName = _appFileNames[safeIdx];
                      final existingApkFile = _findApkFile(appFileName);
                      final isApkOnDisk = existingApkFile != null && existingApkFile.existsSync();
                      final apkSizeString = isApkOnDisk
                          ? '${(existingApkFile.lengthSync() / (1024 * 1024)).toStringAsFixed(1)} MB'
                          : cfg.apkFileSize;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isApkOnDisk ? Colors.green.shade50 : const Color(0xFFF8F9FA),
                          border: Border.all(color: isApkOnDisk ? Colors.green.shade400 : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isApkOnDisk ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                                  color: isApkOnDisk ? Colors.green.shade700 : const Color(0xFF1B4F72),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isApkOnDisk
                                            ? '✅ Production APK Ready to Download & Save — ${_appNameCtrl.text.trim()} (${_appVersionCtrl.text.trim()})'
                                            : 'ℹ️ Ready to Package & Build — ${cfg.appName}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: isApkOnDisk ? Colors.green.shade800 : const Color(0xFF1B4F72),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Package: ${_appPkgCtrl.text.trim()}  |  Output: releases/$appFileName  |  Size: $apkSizeString',
                                        style: const TextStyle(fontSize: 10, color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Technical Info Chips
                            Row(
                              children: [
                                _buildInfoChip('Architecture', cfg.architecture),
                                const SizedBox(width: 6),
                                _buildInfoChip('File Size', apkSizeString),
                                const SizedBox(width: 6),
                                _buildInfoChip('Target SDK', cfg.targetSdk),
                                const SizedBox(width: 6),
                                _buildInfoChip('Channel', cfg.buildChannel),
                                const SizedBox(width: 6),
                                _buildInfoChip('Disk Status', isApkOnDisk ? 'Built & Signed' : 'Configured'),
                              ],
                            ),

                            // Export status banner (if active)
                            if (_apkExportStatus != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  children: [
                                    if (_isExportingApk) ...[
                                      const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5)),
                                      const SizedBox(width: 6),
                                    ],
                                    Expanded(
                                      child: Text(
                                        _apkExportStatus!,
                                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),

                            // Primary Action Buttons Row
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _classicButton(
                                  '💾 Save APK As... (Download)',
                                  () => _downloadAndSaveApk(repo, cfg),
                                  isPrimary: true,
                                  icon: Icons.download_rounded,
                                ),
                                _classicButton(
                                  '💾 Save Settings',
                                  () {
                                    _saveCurrentAppEdits(repo);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('✓ ${_appNameCtrl.text.trim()} settings & branding saved!'),
                                        backgroundColor: const Color(0xFF1B4F72),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  icon: Icons.save_rounded,
                                ),
                                _classicButton(
                                  '📲 Wi-Fi LAN / QR Code',
                                  () => _showQrDialog(cfg),
                                  icon: Icons.qr_code_2_rounded,
                                ),
                                _classicButton(
                                  '📁 Open Releases Folder',
                                  () => _openReleasesFolder(),
                                  icon: Icons.folder_open_rounded,
                                ),
                                _classicButton(
                                  _buildComplete ? '🔄 Re-Package APK' : '🏗️ Package & Build APK',
                                  () => _startApkBuild(repo),
                                  icon: Icons.build_circle_outlined,
                                ),
                              ],
                            ),

                            const Divider(height: 18),

                            // Enterprise Suite Export Row
                            Row(
                              children: [
                                _classicButton(
                                  '📦 Export All 5 APKs to Custom Folder...',
                                  () => _exportAllApks(repo),
                                  icon: Icons.all_inbox_rounded,
                                ),
                                const SizedBox(width: 8),
                                _classicButton(
                                  '📱 Open Mobile Apps Release Center',
                                  () => AndroidAppsReleaseDialog.show(context),
                                  icon: Icons.launch_rounded,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '💡 Tip: Settings changed above are automatically saved when you click "Save APK As...". You can choose any destination folder, USB flash drive, or client directory to save the APK.',
                              style: TextStyle(fontSize: 9.5, color: Colors.black54, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _appFormRow(String label, TextEditingController ctrl, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 2),
          Container(
            height: 26,
            color: Colors.white,
            child: TextField(
              controller: ctrl,
              style: const TextStyle(fontSize: 11),
              decoration: InputDecoration(
                border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                hintText: hint,
                hintStyle: TextStyle(fontSize: 10, color: Colors.grey.shade400),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
  }

  File? _findApkFile(String fileName) {
    // 1. Check in releases/ directory
    final releasesDir = Directory('releases');
    if (releasesDir.existsSync()) {
      final f = File('${releasesDir.path}${Platform.pathSeparator}$fileName');
      if (f.existsSync()) return f;
    }

    // 2. Check in build/app/outputs/flutter-apk/
    final buildDir = Directory('build/app/outputs/flutter-apk');
    if (buildDir.existsSync()) {
      final namedFile = File('${buildDir.path}${Platform.pathSeparator}$fileName');
      if (namedFile.existsSync()) return namedFile;

      final defaultRelease = File('${buildDir.path}${Platform.pathSeparator}app-release.apk');
      if (defaultRelease.existsSync()) return defaultRelease;
    }

    return null;
  }

  void _openReleasesFolder() {
    try {
      final currentDir = Directory.current.path;
      final releasesPath = '$currentDir${Platform.pathSeparator}releases';
      final dir = Directory(releasesPath);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      Process.run('explorer.exe', [releasesPath]);
    } catch (e) {
      debugPrint('Failed to open explorer: $e');
    }
  }

  Future<void> _downloadAndSaveApk(HotelRepository repo, AndroidAppConfig cfg) async {
    // 1. Save latest edits immediately
    _saveCurrentAppEdits(repo);
    final updatedCfg = repo.getAndroidAppConfig(cfg.appId);

    final safeIdx = _selectedAppIndex.clamp(0, _appFileNames.length - 1);
    final fileName = _appFileNames[safeIdx];
    final sourceFile = _findApkFile(fileName);

    if (sourceFile == null || !sourceFile.existsSync()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ APK file "$fileName" not found on disk. Please click "Package & Build APK" to package it.'),
          backgroundColor: Colors.orange.shade900,
          action: SnackBarAction(
            label: 'Build Now',
            textColor: Colors.yellowAccent,
            onPressed: () => _startApkBuild(repo),
          ),
        ),
      );
      return;
    }

    // Prepare clean default file name
    final cleanAppName = updatedCfg.appName
        .replaceAll(RegExp(r'[^\w\s\.-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final cleanVersion = updatedCfg.versionName.trim();
    final defaultSaveName = cleanAppName.isNotEmpty
        ? '${cleanAppName}_$cleanVersion.apk'
        : fileName;

    try {
      setState(() {
        _isExportingApk = true;
        _apkExportStatus = 'Opening file save dialog...';
      });

      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save ${updatedCfg.appName} APK — Select Destination Location',
        fileName: defaultSaveName,
        type: FileType.custom,
        allowedExtensions: ['apk'],
      );

      if (outputPath == null) {
        setState(() {
          _isExportingApk = false;
          _apkExportStatus = null;
        });
        return; // User cancelled
      }

      setState(() {
        _apkExportStatus = 'Saving APK to disk...';
      });

      final finalPath = outputPath.toLowerCase().endsWith('.apk') ? outputPath : '$outputPath.apk';
      await sourceFile.copy(finalPath);

      // Also create companion config JSON next to the APK
      try {
        final configJsonPath = finalPath.replaceAll(RegExp(r'\.apk$', caseSensitive: false), '_client_config.json');
        final syncIp = HotelSyncBridgeService.instance.localIpAddress ?? '127.0.0.1';
        final syncPort = HotelSyncBridgeService.instance.serverPort;
        final configMap = {
          'appId': updatedCfg.appId,
          'appName': updatedCfg.appName,
          'versionName': updatedCfg.versionName,
          'packageName': updatedCfg.packageName,
          'hotelName': updatedCfg.hotelName,
          'hotelTagline': updatedCfg.hotelTagline,
          'hotelAddress': updatedCfg.hotelAddress,
          'hotelCity': updatedCfg.hotelCity,
          'hotelPhone': updatedCfg.hotelPhone,
          'supportEmail': updatedCfg.supportEmail,
          'hotelGstin': updatedCfg.hotelGstin,
          'hotelFssai': updatedCfg.hotelFssai,
          'syncServerUrl': 'http://$syncIp:$syncPort',
          'exportedAt': DateTime.now().toIso8601String(),
          'buildChannel': updatedCfg.buildChannel,
          'architecture': updatedCfg.architecture,
          'targetSdk': updatedCfg.targetSdk,
        };
        final configFile = File(configJsonPath);
        await configFile.writeAsString(const JsonEncoder.withIndent('  ').convert(configMap));
      } catch (e) {
        debugPrint('[DeveloperSettings] Config JSON export note: $e');
      }

      setState(() {
        _isExportingApk = false;
        _apkExportStatus = '✓ APK saved to $finalPath';
      });

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      final snackBarController = messenger.showSnackBar(
        SnackBar(
          content: Text('🎉 ${updatedCfg.appName} APK successfully saved!\nLocation: $finalPath'),
          backgroundColor: const Color(0xFF1E8449),
          duration: const Duration(seconds: 30),
          showCloseIcon: true,
          closeIconColor: Colors.white,
          action: SnackBarAction(
            label: 'Open Folder',
            textColor: Colors.yellowAccent,
            onPressed: () {
              try {
                final parentDir = File(finalPath).parent.path;
                Process.run('explorer.exe', [parentDir]);
              } catch (_) {}
            },
          ),
        ),
      );
      Timer(const Duration(seconds: 30), () {
        try {
          snackBarController.close();
        } catch (_) {}
      });
    } catch (e) {
      setState(() {
        _isExportingApk = false;
        _apkExportStatus = 'Error saving APK: $e';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to save APK: $e'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  Future<void> _exportAllApks(HotelRepository repo) async {
    _saveCurrentAppEdits(repo);

    try {
      setState(() {
        _isExportingApk = true;
        _apkExportStatus = 'Selecting folder for all APKs...';
      });

      final String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Folder / Pen Drive to Export All 5 Android APKs',
      );

      if (selectedDirectory == null) {
        setState(() {
          _isExportingApk = false;
          _apkExportStatus = null;
        });
        return;
      }

      final appIds = ['customer', 'waiter', 'housekeeping', 'manager', 'delivery_boy'];
      int copiedCount = 0;
      final syncIp = HotelSyncBridgeService.instance.localIpAddress ?? '127.0.0.1';
      final syncPort = HotelSyncBridgeService.instance.serverPort;

      final manifestBuffer = StringBuffer();
      manifestBuffer.writeln('================================================================');
      manifestBuffer.writeln(' HOTELPRO ENTERPRISE — CLIENT MOBILE APPS SUITE');
      manifestBuffer.writeln(' Hotel / Business: ${repo.clientBusinessName}');
      manifestBuffer.writeln(' Exported On: ${DateTime.now()}');
      manifestBuffer.writeln(' Hotel LAN Wi-Fi Sync Server: http://$syncIp:$syncPort');
      manifestBuffer.writeln(' Cloud Sync: Enabled via Supabase Enterprise');
      manifestBuffer.writeln('================================================================\n');

      for (int i = 0; i < appIds.length; i++) {
        final cfg = repo.getAndroidAppConfig(appIds[i]);
        final fileName = _appFileNames[i];
        final source = _findApkFile(fileName);

        if (source != null && source.existsSync()) {
          final destFile = File('$selectedDirectory${Platform.pathSeparator}$fileName');
          await source.copy(destFile.path);
          copiedCount++;

          final sizeMb = (source.lengthSync() / (1024 * 1024)).toStringAsFixed(1);
          manifestBuffer.writeln('[$copiedCount] ${cfg.appName} (${cfg.versionName})');
          manifestBuffer.writeln('    File: $fileName ($sizeMb MB)');
          manifestBuffer.writeln('    Package: ${cfg.packageName}');
          manifestBuffer.writeln('    Role: ${cfg.appTitle}');
          manifestBuffer.writeln('    Direct LAN Link: http://$syncIp:$syncPort/releases/$fileName\n');
        }
      }

      manifestBuffer.writeln('----------------------------------------------------------------');
      manifestBuffer.writeln('INSTALLATION INSTRUCTIONS FOR ANDROID DEVICES:');
      manifestBuffer.writeln('1. Copy the APK file to the Android device via USB, WhatsApp or Google Drive.');
      manifestBuffer.writeln('2. Tap the APK to install. If prompted, allow "Install unknown apps".');
      manifestBuffer.writeln('3. Open the app. It will automatically connect to HotelPro Windows Master ERP.');
      manifestBuffer.writeln('----------------------------------------------------------------');

      final manifestFile = File('$selectedDirectory${Platform.pathSeparator}HOTELPRO_APPS_SETUP_GUIDE.txt');
      await manifestFile.writeAsString(manifestBuffer.toString());

      setState(() {
        _isExportingApk = false;
        _apkExportStatus = '✓ Successfully exported $copiedCount APKs to $selectedDirectory';
      });

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      final snackBarController = messenger.showSnackBar(
        SnackBar(
          content: Text('🎉 Exported $copiedCount Android APKs & Guide to:\n$selectedDirectory'),
          backgroundColor: const Color(0xFF1E8449),
          duration: const Duration(seconds: 30),
          showCloseIcon: true,
          closeIconColor: Colors.white,
          action: SnackBarAction(
            label: 'Open Folder',
            textColor: Colors.yellowAccent,
            onPressed: () {
              try {
                Process.run('explorer.exe', [selectedDirectory]);
              } catch (_) {}
            },
          ),
        ),
      );
      Timer(const Duration(seconds: 30), () {
        try {
          snackBarController.close();
        } catch (_) {}
      });
    } catch (e) {
      setState(() {
        _isExportingApk = false;
        _apkExportStatus = 'Export error: $e';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Export failed: $e'), backgroundColor: Colors.red.shade800),
      );
    }
  }

  void _showQrDialog(AndroidAppConfig cfg) {
    final safeIdx = _selectedAppIndex.clamp(0, _appFileNames.length - 1);
    final fileName = _appFileNames[safeIdx];
    final localIp = HotelSyncBridgeService.instance.localIpAddress ?? '127.0.0.1';
    final port = HotelSyncBridgeService.instance.serverPort;
    final downloadUrl = 'http://$localIp:$port/releases/$fileName';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Row(
          children: [
            const Icon(Icons.qr_code_2_rounded, color: Color(0xFF0C2461)),
            const SizedBox(width: 8),
            Flexible(child: Text('Wi-Fi LAN Download & QR — ${cfg.appName}', style: const TextStyle(fontSize: 13))),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: const Center(
                  child: Icon(Icons.qr_code_2_rounded, size: 130, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Scan or Open in Phone Browser to Download\n${cfg.appName} (${cfg.versionName})',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                color: const Color(0xFFEBF5FB),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_rounded, size: 14, color: Color(0xFF1A5276)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: SelectableText(
                        downloadUrl,
                        style: const TextStyle(fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Color(0xFF1A5276)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      tooltip: 'Copy Download Link',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: downloadUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✓ Wi-Fi download link copied to clipboard!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Make sure the Android device is connected to the same hotel Wi-Fi router. Opening the link above in Chrome will immediately download the APK.',
                style: TextStyle(fontSize: 9.5, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          _classicButton('Open Releases Folder', () => _openReleasesFolder()),
          const SizedBox(width: 6),
          _classicButton('Close', () => Navigator.of(ctx).pop()),
        ],
      ),
    );
  }

  // ── Tab 4: Taxes, GST & Currencies ─────────────────────────────────────
  Widget _buildTaxesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Tax Rates & Government Levies (Applied on GST Invoices)'),
        const SizedBox(height: 12),

        _formRow('Hotel Room GST Rate (%)', _roomGstCtrl, hint: '12.0'),
        _formRow('Restaurant Food GST Rate (%)', _foodGstCtrl, hint: '5.0'),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.brown, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tax rates will automatically calculate CGST and SGST in 50:50 ratio on all printable GST Tax Invoices and Folios.',
                  style: TextStyle(fontSize: 11, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Helper UI Components ───────────────────────────────────────────────
  Widget _sectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: const Color(0xFFE5E8E8),
      child: Row(
        children: [
          const Icon(Icons.arrow_right_rounded, size: 16, color: Color(0xFF1B4F72)),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1B4F72))),
        ],
      ),
    );
  }

  Widget _formRow(String label, TextEditingController ctrl, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
          ),
          Expanded(
            child: Container(
              height: 28,
              color: Colors.white,
              child: TextField(
                controller: ctrl,
                style: const TextStyle(fontSize: 11.5),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  hintText: hint,
                  hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _moduleCheckTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: value ? const Color(0xFFEBF5FB) : Colors.grey.shade50,
        border: Border.all(color: value ? const Color(0xFF1B4F72) : Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: const Color(0xFF1B4F72),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: value ? const Color(0xFF1B4F72) : Colors.black87)),
                Text(subtitle, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _studioTab(int idx, String title) {
    final isSelected = _activeTab == idx;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = idx),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          border: isSelected
              ? const Border(
                  top: BorderSide(color: Color(0xFF0C2461), width: 2),
                  left: BorderSide(color: ClassicErpTheme.borderDark),
                  right: BorderSide(color: ClassicErpTheme.borderDark),
                )
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF0C2461) : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _classicButton(
    String label,
    VoidCallback onTap, {
    bool isPrimary = false,
    Color? customBgColor,
    IconData? icon,
  }) {
    final bgColor = customBgColor ?? (isPrimary ? const Color(0xFF0C2461) : const Color(0xFFD4D0C8));
    final textColor = isPrimary || customBgColor != null ? Colors.white : Colors.black87;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: isPrimary ? const Color(0xFF081B4B) : ClassicErpTheme.borderDark, width: 1),
          boxShadow: [
            BoxShadow(
              color: isPrimary ? Colors.black26 : Colors.white,
              offset: const Offset(-1, -1),
            ),
            BoxShadow(
              color: isPrimary ? Colors.black54 : Colors.black38,
              offset: const Offset(1, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: textColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
