import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/classic_erp_theme.dart';
import 'config/supabase_config.dart';
import 'data/repositories/hotel_repository.dart';
import 'ui/core/classic/screens/hotelpro_auth_gate.dart';
import 'ui/customer/customer_app_shell.dart';
import 'ui/mobile/components/mobile_app_scaffold.dart';
import 'ui/mobile/mobile_role_gateway.dart';
import 'ui/mobile/waiter/waiter_pos_app_shell.dart';
import 'ui/mobile/housekeeping/housekeeping_app_shell.dart';
import 'ui/mobile/manager/manager_mis_app_shell.dart';
import 'ui/mobile/delivery/delivery_boy_app_shell.dart';
import 'data/services/app_update_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (with fallback to high-fidelity local engine)
  await SupabaseConfig.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HotelRepository()),
      ],
      child: const HotelProApp(),
    ),
  );
}

enum AppDisplayMode {
  classicErp,
  mobileGateway,
  customerMobileApp,
  waiterMobileApp,
  housekeepingMobileApp,
  managerMobileApp,
  deliveryBoyMobileApp,
}

class HotelProApp extends StatefulWidget {
  const HotelProApp({super.key});

  @override
  State<HotelProApp> createState() => _HotelProAppState();
}

class _HotelProAppState extends State<HotelProApp> {
  late AppDisplayMode _appMode;

  @override
  void initState() {
    super.initState();
    // Auto-detect target platform:
    // • Android Emulator / Phone / iOS Device -> Unified Mobile Role Gateway & Apps Suite
    // • Windows Desktop -> Full Enterprise Classic Windows ERP Software
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _appMode = AppDisplayMode.mobileGateway;
    } else {
      _appMode = AppDisplayMode.classicErp;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdateService.checkAndPrompt(context, silent: true);
    });
  }

  void _handleRoleSwitch(MobileAppRole role) {
    setState(() {
      switch (role) {
        case MobileAppRole.gateway:
          _appMode = AppDisplayMode.mobileGateway;
          break;
        case MobileAppRole.customer:
          _appMode = AppDisplayMode.customerMobileApp;
          break;
        case MobileAppRole.waiter:
          _appMode = AppDisplayMode.waiterMobileApp;
          break;
        case MobileAppRole.housekeeping:
          _appMode = AppDisplayMode.housekeepingMobileApp;
          break;
        case MobileAppRole.manager:
          _appMode = AppDisplayMode.managerMobileApp;
          break;
        case MobileAppRole.deliveryBoy:
          _appMode = AppDisplayMode.deliveryBoyMobileApp;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData activeTheme;
    Widget activeContent;

    final isMobilePlatform = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    switch (_appMode) {
      case AppDisplayMode.classicErp:
        activeTheme = ClassicErpTheme.themeData;
        activeContent = const HotelProDesktopAuthGate();
        break;

      case AppDisplayMode.mobileGateway:
        activeTheme = ThemeData(
          useMaterial3: true,
          primaryColor: const Color(0xFF1B4F72),
          scaffoldBackgroundColor: const Color(0xFFF4F6F9),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B4F72)),
        );
        activeContent = MobileRoleGateway(
          onSelectRole: _handleRoleSwitch,
          onSwitchToDesktopErp: isMobilePlatform
              ? null
              : () => setState(() => _appMode = AppDisplayMode.classicErp),
        );
        break;

      case AppDisplayMode.customerMobileApp:
        activeTheme = ThemeData(
          useMaterial3: true,
          primaryColor: const Color(0xFFE23744),
          scaffoldBackgroundColor: const Color(0xFFF8F9FA),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE23744)),
        );
        activeContent = CustomerAppShell(
          onSwitchToErp: () => setState(() => _appMode = AppDisplayMode.mobileGateway),
        );
        break;

      case AppDisplayMode.waiterMobileApp:
        activeTheme = ThemeData(
          useMaterial3: true,
          primaryColor: const Color(0xFF1E8449),
          scaffoldBackgroundColor: const Color(0xFFF4F6F9),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E8449)),
        );
        activeContent = WaiterPosAppShell(
          onBackToGateway: () => setState(() => _appMode = AppDisplayMode.mobileGateway),
          onSwitchRole: _handleRoleSwitch,
        );
        break;

      case AppDisplayMode.housekeepingMobileApp:
        activeTheme = ThemeData(
          useMaterial3: true,
          primaryColor: const Color(0xFF6C3483),
          scaffoldBackgroundColor: const Color(0xFFF4F6F9),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C3483)),
        );
        activeContent = HousekeepingAppShell(
          onBackToGateway: () => setState(() => _appMode = AppDisplayMode.mobileGateway),
          onSwitchRole: _handleRoleSwitch,
        );
        break;

      case AppDisplayMode.managerMobileApp:
        activeTheme = ThemeData(
          useMaterial3: true,
          primaryColor: const Color(0xFF922B21),
          scaffoldBackgroundColor: const Color(0xFFF4F6F9),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF922B21)),
        );
        activeContent = ManagerMisAppShell(
          onBackToGateway: () => setState(() => _appMode = AppDisplayMode.mobileGateway),
          onSwitchRole: _handleRoleSwitch,
        );
        break;

      case AppDisplayMode.deliveryBoyMobileApp:
        activeTheme = ThemeData(
          useMaterial3: true,
          primaryColor: const Color(0xFFD35400),
          scaffoldBackgroundColor: const Color(0xFFF4F6F9),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD35400)),
        );
        activeContent = DeliveryBoyAppShell(
          onBackToGateway: () => setState(() => _appMode = AppDisplayMode.mobileGateway),
          onSwitchRole: _handleRoleSwitch,
        );
        break;
    }

    // On Desktop, if viewing a mobile app, render in a sleek smartphone frame
    Widget finalScreen = activeContent;
    if (!isMobilePlatform && _appMode != AppDisplayMode.classicErp && _appMode != AppDisplayMode.customerMobileApp) {
      finalScreen = _buildDesktopPhoneFrame(activeContent);
    }

    return MaterialApp(
      title: 'Hotelpro Management System',
      debugShowCheckedModeBanner: false,
      theme: activeTheme,
      home: finalScreen,
    );
  }

  Widget _buildDesktopPhoneFrame(Widget mobileApp) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C2833),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar on Desktop to switch back to Windows ERP
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF11171D),
              child: Row(
                children: [
                  const Icon(Icons.phone_android_rounded, color: Color(0xFF5DADE2), size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'HOTELPRO MOBILE SUITE • ANDROID & IOS SIMULATION PREVIEW',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    onPressed: () => setState(() => _appMode = AppDisplayMode.classicErp),
                    icon: const Icon(Icons.desktop_windows_rounded, size: 14),
                    label: const Text('Back to Windows ERP', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
            // Centered Mobile Screen
            Expanded(
              child: Center(
                child: Container(
                  width: 412,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.black, width: 8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: mobileApp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
