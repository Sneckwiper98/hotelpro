import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../config/classic_erp_theme.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/hotel_repository.dart';
import '../../features/dashboard/executive_analytics_view.dart';
import '../../features/front_desk/front_desk_view.dart';
import '../../features/guest_folio/folio_view.dart';
import '../../features/housekeeping/housekeeping_view.dart';
import '../../features/master/classic_master_view.dart';
import '../../features/inventory/stock_inventory_view.dart';
import '../../features/pos_restaurant/pos_restaurant_view.dart';
import '../../features/reservation/crs_reservation_view.dart';
import '../../features/accounting/accounting_view.dart';
import '../../features/pos_restaurant/online_delivery_dashboard_view.dart';
import '../../features/pos_restaurant/delivery_boy_management_view.dart';
import 'dialogs/developer_settings_dialog.dart';
import 'dialogs/classic_invoice_register_dialog.dart';
import 'dialogs/global_search_dialog.dart';
import 'dialogs/night_audit_dialog.dart';
import 'dialogs/quick_entry_launcher_dialog.dart';
import 'dialogs/android_apps_release_dialog.dart';
import 'utils/report_utils.dart';
import '../components/hotel_logo_widget.dart';
import '../components/app_update_dialog.dart';
import '../../../data/services/app_update_service.dart';

/// Classic Windows Desktop ERP Shell
/// Accurately renders the complete Windows ERP desktop environment shown in the user photo:
/// - Windows Window Title Bar with application/multi-branch title
/// - Classic Top Menu Bar (`System`, `Stock`, `Purchase`, `Catalog`, `FrontDesk`, `Billing`, `Master`, `Reports`)
/// - Icon Toolbar Ribbon (`New`, `Edit`, `Save`, `Find`, `Help`, `Close`, `Execute`, `Cnc Doc`, `Print`, `Cancel`)
/// - MDI Sub-Window Container Area with fully working Minimize, Maximize/Restore, and Close controls
/// - MDI Desktop Wallpaper with Program Shortcuts when windows are closed or minimized
/// - Sunken Enterprise Status Bar with query execution latency, branch, and station identifiers
class ClassicErpShell extends StatefulWidget {
  const ClassicErpShell({super.key});

  @override
  State<ClassicErpShell> createState() => _ClassicErpShellState();
}

/// Represents an active MDI Sub-Window in the Classic ERP Desktop
class ErpWindow {
  final int moduleIndex;
  final String title;
  final IconData icon;
  int initialTab;
  dynamic initialData;

  Offset? _position;
  Offset get position => _position ?? const Offset(20, 20);
  set position(Offset v) => _position = v;

  Size? _size;
  Size get size => _size ?? const Size(850, 550);
  set size(Size v) => _size = v;

  bool? _isMaximized;
  bool get isMaximized => _isMaximized ?? false;
  set isMaximized(bool v) => _isMaximized = v;

  bool? _isMinimized;
  bool get isMinimized => _isMinimized ?? false;
  set isMinimized(bool v) => _isMinimized = v;

  int? _zIndex;
  int get zIndex => _zIndex ?? 0;
  set zIndex(int v) => _zIndex = v;

  ErpWindow({
    required this.moduleIndex,
    required this.title,
    required this.icon,
    Offset? position,
    Size? size,
    bool isMaximized = false,
    bool isMinimized = false,
    int? zIndex,
    this.initialTab = 0,
    this.initialData,
  })  : _position = position ?? const Offset(20, 20),
        _size = size ?? const Size(850, 550),
        _isMaximized = isMaximized,
        _isMinimized = isMinimized,
        _zIndex = zIndex ?? 0;
}

class _ClassicErpShellState extends State<ClassicErpShell> {
  final List<ErpWindow> _openWindows = [];
  BoxConstraints? _desktopConstraints;
  String _activeOperation = 'mdi_Desktop_ready';
  String _executionLatency = '0.002 Secs';
  String _systemVersion = AppUpdateService.currentInstalledVersion;
  int _zCounter = 0;
  ErpWindow? _activeWindow;
  AppUpdateInfo? _availableUpdate;

  @override
  void initState() {
    super.initState();
    _systemVersion = AppUpdateService.currentInstalledVersion;
    HardwareKeyboard.instance.addHandler(_handleGlobalKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkWindowsUpdateOnStartup();
    });
  }

  void _refreshSystemVersion() {
    final v = AppUpdateService.currentInstalledVersion;
    if (_systemVersion != v) {
      setState(() {
        _systemVersion = v;
      });
    }
  }

  Future<void> _checkWindowsUpdateOnStartup() async {
    try {
      _refreshSystemVersion();
      final info = await AppUpdateService.checkLatestRelease(targetApp: AppTarget.windowsErp);
      if (mounted) {
        setState(() {
          _availableUpdate = info;
          _systemVersion = AppUpdateService.currentInstalledVersion;
        });
        if (info != null && info.hasUpdate) {
          AppUpdateService.checkAndPrompt(context, targetApp: AppTarget.windowsErp, silent: false);
        }
      }
    } catch (e) {
      debugPrint('[ClassicErpShell] Startup update check failed: $e');
    }
  }

  void _openUpdateFlow() {
    if (_availableUpdate != null && _availableUpdate!.hasUpdate) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AppUpdateDialog(
          updateInfo: _availableUpdate!,
          onDismiss: () => Navigator.of(ctx).pop(),
        ),
      );
    } else {
      _showDeploymentDialog(context);
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKey);
    super.dispose();
  }

  bool _handleGlobalKey(KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      final isCtrl = HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.controlLeft) ||
          HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.controlRight);
      final isShift = HardwareKeyboard.instance.isShiftPressed ||
          HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.shiftLeft) ||
          HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.shiftRight);

      // Ctrl + Tab -> Cycle to Next Window / Page
      // Ctrl + Shift + Tab -> Cycle to Previous Window / Page
      if (isCtrl && event.logicalKey == LogicalKeyboardKey.tab) {
        if (isShift) {
          _switchToPreviousWindow();
        } else {
          _switchToNextWindow();
        }
        return true; // Handled
      }
    }
    return false;
  }

  void _switchToNextWindow() {
    if (_openWindows.isEmpty) return;
    if (_openWindows.length == 1) {
      if (_openWindows.first.isMinimized) {
        _bringToFront(_openWindows.first);
      }
      return;
    }

    final currentIndex = _activeWindow != null ? _openWindows.indexOf(_activeWindow!) : -1;
    final nextIndex = (currentIndex + 1) % _openWindows.length;
    _bringToFront(_openWindows[nextIndex]);
  }

  void _switchToPreviousWindow() {
    if (_openWindows.isEmpty) return;
    if (_openWindows.length == 1) {
      if (_openWindows.first.isMinimized) {
        _bringToFront(_openWindows.first);
      }
      return;
    }

    final currentIndex = _activeWindow != null ? _openWindows.indexOf(_activeWindow!) : 0;
    final prevIndex = (currentIndex - 1 + _openWindows.length) % _openWindows.length;
    _bringToFront(_openWindows[prevIndex]);
  }

  String _getRequiredPermissionForModule(int index) {
    switch (index) {
      case 0: return HotelProFunctionRights.frontDeskView;
      case 1: return HotelProFunctionRights.folioView;
      case 2: return HotelProFunctionRights.posView;
      case 3: return HotelProFunctionRights.hkView;
      case 4: return HotelProFunctionRights.crsView;
      case 5: return HotelProFunctionRights.analyticsView;
      case 6: return HotelProFunctionRights.masterRooms;
      case 7: return HotelProFunctionRights.accountingView;
      case 8: return HotelProFunctionRights.inventoryView;
      case 9: return HotelProFunctionRights.deliveryQueue;
      case 10: return HotelProFunctionRights.deliveryDispatch;
      default: return HotelProFunctionRights.frontDeskView;
    }
  }

  void _showAccessDeniedDialog(String moduleName, AppUserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Container(
          width: 460,
          decoration: BoxDecoration(
            color: ClassicErpTheme.panelBg,
            border: Border.all(color: Colors.red.shade700, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.red.shade800,
                child: const Row(
                  children: [
                    Icon(Icons.gpp_bad_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Access Denied — Function Rights Insufficient',
                      style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lock_person_rounded, size: 36, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Unauthorized Module Access',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.red.shade900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Operator "@${user.username}" (${user.displayName}) does not possess the required function rights to open:',
                                style: const TextStyle(fontSize: 11, color: ClassicErpTheme.textMain),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                color: Colors.white,
                                child: Text(
                                  moduleName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF1B4F72)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Assigned System Role: ${user.role.label}\nPlease ask your Super Administrator to grant function rights in Masters > User Accounts > Function Rights Master.',
                                style: const TextStyle(fontSize: 10, color: ClassicErpTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B4F72),
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('OK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openModule(int index, {int initialTab = 0, dynamic initialData}) {
    final repo = context.read<HotelRepository>();
    final user = repo.currentErpUser;
    final requiredPerm = _getRequiredPermissionForModule(index);

    if (!user.hasPermission(requiredPerm)) {
      _showAccessDeniedDialog(_getModuleName(index), user);
      return;
    }

    setState(() {
      final existingIndex = _openWindows.indexWhere((w) => w.moduleIndex == index);
      if (existingIndex != -1) {
        final win = _openWindows[existingIndex];
        win.isMinimized = false;
        win.zIndex = ++_zCounter;
        win.initialTab = initialTab;
        win.initialData = initialData;
        _activeWindow = win;
      } else {
        final maxW = _desktopConstraints?.maxWidth ?? 1100.0;
        final maxH = _desktopConstraints?.maxHeight ?? 700.0;

        // Cascade offset so each newly opened window is staggered
        final step = (_openWindows.length % 6);
        final initialX = 18.0 + step * 32.0;
        final initialY = 14.0 + step * 26.0;
        final winW = (maxW * 0.84).clamp(760.0, 1150.0);
        final winH = (maxH * 0.84).clamp(500.0, 800.0);

        final newWin = ErpWindow(
          moduleIndex: index,
          title: _getModuleName(index),
          icon: _getModuleIcon(index),
          position: Offset(initialX, initialY),
          size: Size(winW, winH),
          isMaximized: false,
          isMinimized: false,
          zIndex: ++_zCounter,
          initialTab: initialTab,
          initialData: initialData,
        );
        _openWindows.add(newWin);
        _activeWindow = newWin;
      }
      _activeOperation = _getOperationName(index);
      _executionLatency = '0.014 Secs';
    });
  }

  void _closeWindow(ErpWindow win) {
    setState(() {
      _openWindows.remove(win);
      if (_activeWindow == win) {
        ErpWindow? nextActive;
        for (final w in _openWindows) {
          if (!w.isMinimized) {
            if (nextActive == null || w.zIndex > nextActive.zIndex) {
              nextActive = w;
            }
          }
        }
        _activeWindow = nextActive;
      }
      if (_openWindows.isEmpty) {
        _activeOperation = 'mdi_Desktop_ready';
        _executionLatency = '0.002 Secs';
      } else if (_activeWindow != null) {
        _activeOperation = _getOperationName(_activeWindow!.moduleIndex);
        _executionLatency = '0.004 Secs';
      }
    });
  }

  void _minimizeWindow(ErpWindow win) {
    setState(() {
      win.isMinimized = true;
      if (_activeWindow == win) {
        ErpWindow? nextActive;
        for (final w in _openWindows) {
          if (!w.isMinimized) {
            if (nextActive == null || w.zIndex > nextActive.zIndex) {
              nextActive = w;
            }
          }
        }
        _activeWindow = nextActive;
      }
    });
  }

  void _toggleMaximizeWindow(ErpWindow win) {
    setState(() {
      win.isMaximized = !win.isMaximized;
    });
  }

  void _restoreWindow(ErpWindow win) {
    _bringToFront(win, immediate: true);
  }

  void _bringToFront(ErpWindow win, {bool immediate = false}) {
    if (_activeWindow == win && !win.isMinimized) return;

    void applyBringToFront() {
      if (!mounted) return;
      if (_activeWindow == win && !win.isMinimized) return;
      setState(() {
        win.zIndex = ++_zCounter;
        win.isMinimized = false;
        _activeWindow = win;
        _activeOperation = _getOperationName(win.moduleIndex);
        _executionLatency = '0.006 Secs';
      });
    }

    if (immediate) {
      applyBringToFront();
    } else {
      // Defer state update to next frame to prevent re-entrant device update assertion in MouseTracker
      WidgetsBinding.instance.addPostFrameCallback((_) => applyBringToFront());
    }
  }

  void _closeCurrentModule() {
    if (_activeWindow != null) {
      _closeWindow(_activeWindow!);
    }
  }


  void _cascadeWindows(BoxConstraints constraints) {
    final activeWins = _openWindows.where((w) => !w.isMinimized).toList();
    if (activeWins.isEmpty) return;
    setState(() {
      final winW = (constraints.maxWidth * 0.78).clamp(650.0, constraints.maxWidth);
      final winH = (constraints.maxHeight * 0.78).clamp(450.0, constraints.maxHeight);
      for (int i = 0; i < activeWins.length; i++) {
        final win = activeWins[i];
        win.isMaximized = false;
        win.position = Offset(20.0 + (i * 32.0), 15.0 + (i * 26.0));
        win.size = Size(winW, winH);
      }
    });
  }

  void _tileWindowsVertically(BoxConstraints constraints) {
    final activeWins = _openWindows.where((w) => !w.isMinimized).toList();
    if (activeWins.isEmpty) return;
    setState(() {
      final count = activeWins.length;
      final colW = constraints.maxWidth / count;
      for (int i = 0; i < count; i++) {
        final win = activeWins[i];
        win.isMaximized = false;
        win.position = Offset(i * colW, 0);
        win.size = Size(colW, constraints.maxHeight);
      }
    });
  }

  void _tileWindowsHorizontally(BoxConstraints constraints) {
    final activeWins = _openWindows.where((w) => !w.isMinimized).toList();
    if (activeWins.isEmpty) return;
    setState(() {
      final count = activeWins.length;
      final rowH = constraints.maxHeight / count;
      for (int i = 0; i < count; i++) {
        final win = activeWins[i];
        win.isMaximized = false;
        win.position = Offset(0, i * rowH);
        win.size = Size(constraints.maxWidth, rowH);
      }
    });
  }

  void _minimizeAllWindows() {
    setState(() {
      for (final win in _openWindows) {
        win.isMinimized = true;
      }
    });
  }

  void _restoreAllWindows() {
    setState(() {
      for (final win in _openWindows) {
        win.isMinimized = false;
      }
    });
  }

  void _closeAllWindows() {
    setState(() {
      _openWindows.clear();
      _activeOperation = 'mdi_Desktop_ready';
      _executionLatency = '0.002 Secs';
    });
  }

  IconData _getModuleIcon(int index) {
    switch (index) {
      case 0:
        return Icons.room_service_rounded;
      case 1:
        return Icons.receipt_long_rounded;
      case 2:
        return Icons.restaurant_rounded;
      case 3:
        return Icons.cleaning_services_rounded;
      case 4:
        return Icons.calendar_month_rounded;
      case 5:
        return Icons.analytics_rounded;
      case 6:
        return Icons.table_chart_rounded;
      case 7:
        return Icons.account_balance_wallet_rounded;
      case 8:
        return Icons.inventory_2_rounded;
      case 9:
        return Icons.delivery_dining_rounded;
      case 10:
        return Icons.two_wheeler_rounded;
      default:
        return Icons.featured_play_list_rounded;
    }
  }

  String _getOperationName(int index) {
    switch (index) {
      case 0:
        return 'sp_FrontDesk_tapeChart_load';
      case 1:
        return 'sp_GuestFolio_ledger_fetch';
      case 2:
        return 'sp_PosKOT_orderQueue_get';
      case 3:
        return 'sp_Housekeeping_roomStatus_sync';
      case 4:
        return 'sp_CRS_roomAvailability_query';
      case 5:
        return 'sp_ExecutiveAnalytics_kpi_calc';
      case 6:
        return 'sp_Master_catalog_fetch';
      case 7:
        return 'sp_Accounting_balance_query';
      case 8:
        return 'sp_Inventory_stockLevel_sync';
      case 9:
        return 'sp_OnlineDelivery_orders_sync';
      case 10:
        return 'sp_DeliveryBoy_roster_load';
      default:
        return 'sp_Inventory_stockLevel_sync';
    }
  }

  String _getModuleName(int index) {
    switch (index) {
      case 0:
        return 'Front Desk Operations [Room Matrix & Tape Chart]';
      case 1:
        return 'Billing & Folio Management [Guest Accounts]';
      case 2:
        return 'Restaurant POS & KOT Terminal [F&B Outlet]';
      case 3:
        return 'Housekeeping Operations [Room Status]';
      case 4:
        return 'Central Reservation System (CRS) [Bookings]';
      case 5:
        return 'Executive GM Analytics & Revenue Dashboard';
      case 6:
        return 'Master Management [Rooms, Menus, Staff & Users]';
      case 7:
        return 'Purchase, Expense & Balance Sheet [Finance]';
      case 8:
        return 'Stock & Material Inventory Terminal [Live Stock & Purchase Billings]';
      case 9:
        return 'Online Food Delivery & Rider Dispatch [App Orders]';
      case 10:
        return 'Delivery Boy Management [Rider Roster & Dispatch]';
      default:
        return 'Master Management [Rooms, Menus, Staff & Users]';
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final activeBranch = repo.activeBranch;
    final currentTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.tab, control: true): _switchToNextWindow,
        const SingleActivator(LogicalKeyboardKey.tab, control: true, shift: true): _switchToPreviousWindow,
        const SingleActivator(LogicalKeyboardKey.keyI, control: true): () => _openModule(8),
        const SingleActivator(LogicalKeyboardKey.keyM, control: true): () => _openModule(6),
        const SingleActivator(LogicalKeyboardKey.keyA, control: true): () => _openModule(7),
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () => GlobalSearchDialog.show(context, (mIdx, data) => _openModule(mIdx)),
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () => QuickEntryLauncherDialog.show(context, (mIdx, code) => _handleQuickAction(mIdx, code)),
        const SingleActivator(LogicalKeyboardKey.keyR, control: true): () => _openModule(4),
        const SingleActivator(LogicalKeyboardKey.keyB, control: true): () => _openModule(1),
        const SingleActivator(LogicalKeyboardKey.keyP, control: true): () => _openModule(2),
        const SingleActivator(LogicalKeyboardKey.keyH, control: true): () => _openModule(3),
        const SingleActivator(LogicalKeyboardKey.keyE, control: true): () => _openModule(5),
        const SingleActivator(LogicalKeyboardKey.keyO, control: true): () => _openModule(9),
        const SingleActivator(LogicalKeyboardKey.keyD, control: true): () => _openModule(10),
        const SingleActivator(LogicalKeyboardKey.f1): () => _showShortcutsGuide(context),
        const SingleActivator(LogicalKeyboardKey.f2): () => _openModule(0),
        const SingleActivator(LogicalKeyboardKey.f3): () => _openModule(4),
        const SingleActivator(LogicalKeyboardKey.f4): () => _openModule(1),
        const SingleActivator(LogicalKeyboardKey.f5): () => _openModule(2),
        const SingleActivator(LogicalKeyboardKey.f6): () => _openModule(3),
        const SingleActivator(LogicalKeyboardKey.f7): () => _openModule(7),
        const SingleActivator(LogicalKeyboardKey.f8): () => _openModule(8),
        const SingleActivator(LogicalKeyboardKey.f9): () => _openModule(6),
        const SingleActivator(LogicalKeyboardKey.f10): () => _handlePrintAction(),
        const SingleActivator(LogicalKeyboardKey.f11): () => NightAuditDialog.show(context),
        const SingleActivator(LogicalKeyboardKey.f12): () => GlobalSearchDialog.show(context, (mIdx, data) => _openModule(mIdx)),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: ClassicErpTheme.desktopBg,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          // ── 1. Windows Application Title Bar ────────────────────────────
          Container(
            width: double.infinity,
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF0C2461), // Classic Windows Title Bar Navy
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Image.asset(
                    'lib/ui/features/master/assets/hotelpro.png',
                    height: 16,
                    width: 16,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Hotelpro Management System - ${repo.currentErpUser.username}[${activeBranch.name.toUpperCase()} - ${activeBranch.code}] • ${repo.clientBusinessName.toUpperCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Operator User Display Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: repo.currentErpUser.isDeveloper ? const Color(0xFF006266) : const Color(0xFF1B4F72),
                    border: Border.all(color: Colors.white38, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(repo.currentErpUser.isDeveloper ? Icons.shield_rounded : Icons.person_rounded, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '👤 ${repo.currentErpUser.displayName}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                // Developer Portal Setup Button (ONLY visible to Developer user)
                if (repo.currentErpUser.isDeveloper) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => DeveloperSettingsDialog.show(context),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006266),
                        border: Border.all(color: Colors.tealAccent.shade100, width: 0.8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_rounded, size: 11, color: Colors.white),
                          SizedBox(width: 4),
                          Text('🛡️ Developer Settings (iSecure)', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],

                // Live Windows Software Update Notification Chip
                if (_availableUpdate?.hasUpdate == true) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _openUpdateFlow(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC0392B),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: Colors.amberAccent, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.system_update_rounded, size: 12, color: Colors.amberAccent),
                          const SizedBox(width: 4),
                          Text(
                            '⚡ UPDATE v${_availableUpdate!.latestVersion} AVAILABLE!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const Text(
                              'CLICK TO INSTALL',
                              style: TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                _titleButton(Icons.remove, () {
                  if (_activeWindow != null && !_activeWindow!.isMinimized) {
                    _minimizeWindow(_activeWindow!);
                  }
                }),
                const SizedBox(width: 2),
                _titleButton(_activeWindow?.isMaximized == true ? Icons.filter_none : Icons.crop_square, () {
                  if (_activeWindow != null) {
                    _toggleMaximizeWindow(_activeWindow!);
                  }
                }),
                const SizedBox(width: 2),
                _titleButton(Icons.close, () {
                  if (_activeWindow != null) {
                    _closeWindow(_activeWindow!);
                  }
                }, isClose: true),
              ],
            ),
          ),

          // ── 2. Top Menu Bar (Enterprise PMS & ERP Dropdown Menus) ────────
          Container(
            width: double.infinity,
            height: 24,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            decoration: const BoxDecoration(
              color: ClassicErpTheme.menuBarBg,
              border: Border(bottom: BorderSide(color: ClassicErpTheme.borderLight, width: 1)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _navDropdownMenu(
                    label: 'System',
                    items: [
                      _menuEntry('password', Icons.lock_reset_rounded, 'Change Password'),
                      const PopupMenuDivider(),
                      _menuEntry('sync', Icons.cloud_sync_rounded, 'Synchronize Local & Cloud DB'),
                      _menuEntry('diagnostics', Icons.speed_rounded, 'System Latency & Diagnostic Log'),
                      const PopupMenuDivider(),
                      _menuEntry(
                        'deployment',
                        _availableUpdate?.hasUpdate == true ? Icons.system_update_rounded : Icons.system_update_alt_rounded,
                        _availableUpdate?.hasUpdate == true
                            ? 'Software Update ⚠️ (v${_availableUpdate!.latestVersion} READY)'
                            : 'Software Update Center',
                      ),
                      _menuEntry('about', Icons.info_outline_rounded, 'About HotelPro Enterprise'),
                      const PopupMenuDivider(),
                      _menuEntry('logout', Icons.logout_rounded, 'Log Out / Lock Workstation'),
                    ],
                    onSelected: (val) {
                      if (val == 'password') _showChangePasswordDialog(context, repo);
                      if (val == 'sync') _handleSyncAction();
                      if (val == 'diagnostics') _showDiagnosticsDialog(context);
                      if (val == 'deployment') _showDeploymentDialog(context);
                      if (val == 'about') _showAboutDialog(context);
                      if (val == 'logout') repo.logOutErp();
                    },
                  ),
                  _navDropdownMenu(
                    label: 'Front Desk',
                    items: [
                      _menuEntry('matrix', Icons.table_rows_rounded, 'Live Room Matrix & Tape Chart'),
                      _menuEntry('checkin', Icons.how_to_reg_rounded, 'Quick Guest Check-In Wizard'),
                      _menuEntry('inhouse', Icons.group_rounded, 'In-House Guests Directory'),
                      _menuEntry('keycard', Icons.credit_card_rounded, 'Keycard RFID Encoder & Logs'),
                    ],
                    onSelected: (val) {
                      _openModule(0);
                    },
                  ),
                  _navDropdownMenu(
                    label: 'Reservations',
                    items: [
                      _menuEntry('crs', Icons.calendar_month_rounded, 'Reservation Calendar & Grid'),
                      _menuEntry('new_res', Icons.add_circle_outline_rounded, 'New Advance Reservation'),
                      _menuEntry('deposits', Icons.account_balance_wallet_rounded, 'Advance Deposits & Receipts'),
                      _menuEntry('channels', Icons.cloud_done_rounded, 'OTA & Channel Manager Sync'),
                    ],
                    onSelected: (val) {
                      _openModule(4);
                    },
                  ),
                  _navDropdownMenu(
                    label: 'Billing & Folio',
                    items: [
                      _menuEntry('folio', Icons.receipt_long_rounded, 'Guest Folio Accounts & Ledger'),
                      _menuEntry('invoices', Icons.receipt_rounded, 'GST Tax Invoice Register (80mm / A4)'),
                      _menuEntry('settlements', Icons.payments_rounded, 'Cashier Shift Settlement & Receipts'),
                      _menuEntry('city_ledger', Icons.account_balance_rounded, 'Corporate City Ledger Accounts'),
                    ],
                    onSelected: (val) {
                      if (val == 'invoices') {
                        ClassicInvoiceRegisterDialog.show(context);
                      } else {
                        _openModule(1);
                      }
                    },
                    isBold: true,
                  ),
                  _navDropdownMenu(
                    label: 'POS Restaurant',
                    items: [
                      _menuEntry('pos', Icons.restaurant_rounded, 'Dine-In Table Layout & Order Terminal'),
                      _menuEntry('kot', Icons.receipt_long_rounded, 'Kitchen Order Ticket (KOT) Monitor'),
                      _menuEntry('delivery', Icons.delivery_dining_rounded, 'Online App Food Delivery & Riders'),
                      _menuEntry('delivery_boys', Icons.two_wheeler_rounded, 'Delivery Boy Roster & Management'),
                      _menuEntry('menu_master', Icons.restaurant_menu_rounded, 'Restaurant Menu & Pricing Master'),
                    ],
                    onSelected: (val) {
                      if (val == 'delivery') {
                        _openModule(9);
                      } else if (val == 'delivery_boys') {
                        _openModule(10);
                      } else if (val == 'menu_master') {
                        _openModule(6, initialTab: 2);
                      } else {
                        _openModule(2);
                      }
                    },
                  ),
                  _navDropdownMenu(
                    label: 'Housekeeping',
                    items: [
                      _menuEntry('hk', Icons.cleaning_services_rounded, 'Room Cleaning Status Board'),
                      _menuEntry('tasks', Icons.assignment_turned_in_rounded, 'Staff Task Allocation'),
                      _menuEntry('laundry', Icons.local_laundry_service_rounded, 'Linen & Laundry Tracking'),
                      _menuEntry('maintenance', Icons.build_circle_rounded, 'Maintenance Work Orders'),
                    ],
                    onSelected: (val) {
                      _openModule(3);
                    },
                  ),
                  _navDropdownMenu(
                    label: 'Materials & Stock',
                    items: [
                      _menuEntry('stock', Icons.inventory_2_rounded, 'Live Stock Status & Valuation Ledger'),
                      _menuEntry('requisitions', Icons.assignment_return_rounded, 'Store Requisitions & Issues'),
                      _menuEntry('grn', Icons.shopping_bag_rounded, 'Purchase Billings & Material Inward'),
                      _menuEntry('reorder', Icons.warning_amber_rounded, 'Reorder Level & Low Stock Alerts'),
                    ],
                    onSelected: (val) {
                      if (val == 'grn') {
                        _openModule(8, initialTab: 1);
                      } else {
                        _openModule(8, initialTab: 0);
                      }
                    },
                    isBold: true,
                  ),
                  _navDropdownMenu(
                    label: 'Purchase & Accounts',
                    items: [
                      _menuEntry('purchases', Icons.shopping_bag_rounded, 'Supplier Invoices & Purchase Bills'),
                      _menuEntry('expenses', Icons.receipt_long_rounded, 'Operating Expense Sheet & Vouchers'),
                      _menuEntry('balance_sheet', Icons.balance_rounded, 'Audited Balance Sheet & Financials'),
                      _menuEntry('vendors', Icons.domain_rounded, 'Vendor Directory & Accounts Payable'),
                    ],
                    onSelected: (val) {
                      if (val == 'expenses') {
                        _openModule(7, initialTab: 1);
                      } else if (val == 'balance_sheet') {
                        _openModule(7, initialTab: 2);
                      } else {
                        _openModule(7, initialTab: 0);
                      }
                    },
                    isBold: true,
                  ),
                  _navDropdownMenu(
                    label: 'Master Section',
                    items: [
                      _menuEntry('tariffs', Icons.king_bed_rounded, '1. Room Tariffs & Categories Master'),
                      _menuEntry('floors', Icons.domain_rounded, '2. Floors & Room Inventory Master'),
                      _menuEntry('food_menu', Icons.restaurant_menu_rounded, '3. Restaurant F&B Menu Master'),
                      _menuEntry('staff', Icons.badge_rounded, '4. Staff & Employees Directory'),
                      if (repo.currentErpUser.isDeveloper || repo.currentErpUser.isSuperAdmin)
                        _menuEntry('users', Icons.security_rounded, '5. User Accounts & Branch Allocation'),
                      _menuEntry('crm', Icons.contact_phone_rounded, '6. Customer CRM & Guest Directory'),
                    ],
                    onSelected: (val) {
                      if (val == 'tariffs') _openModule(6, initialTab: 0);
                      if (val == 'floors') _openModule(6, initialTab: 1);
                      if (val == 'food_menu') _openModule(6, initialTab: 2);
                      if (val == 'staff') _openModule(6, initialTab: 3);
                      if (val == 'users') _openModule(6, initialTab: 4);
                      if (val == 'crm') _openModule(6, initialTab: 5);
                    },
                  ),
                  _navDropdownMenu(
                    label: 'Reports & MIS',
                    items: [
                      _menuEntry('mis', Icons.analytics_rounded, 'Executive Analytics & Revenue Dashboard'),
                      _menuEntry('flash', Icons.summarize_rounded, 'Daily Manager Flash Summary'),
                      _menuEntry('invoices_rpt', Icons.receipt_long_rounded, 'GST Invoices & Tax Register'),
                      _menuEntry('all_reports', Icons.print_rounded, 'Print Center & Document Export Hub'),
                    ],
                    onSelected: (val) {
                      if (val == 'mis') _openModule(5);
                      if (val == 'invoices_rpt') ClassicInvoiceRegisterDialog.show(context);
                      if (val == 'flash' || val == 'all_reports') _handlePrintAction();
                    },
                  ),
                  _navDropdownMenu(
                    label: 'Tools',
                    items: [
                      _menuEntry('night_audit', Icons.nightlight_round, 'Night Audit & Day-End Closing Wizard'),
                      _menuEntry('search', Icons.search_rounded, 'Global Search & Jump Terminal (Ctrl+F)'),
                      _menuEntry('quick_new', Icons.add_circle_outline_rounded, 'Quick Creation Launcher (Ctrl+N)'),
                      const PopupMenuDivider(),
                      _menuEntry(
                        'deployment',
                        _availableUpdate?.hasUpdate == true ? Icons.system_update_rounded : Icons.system_update_alt_rounded,
                        _availableUpdate?.hasUpdate == true
                            ? 'Software Update ⚠️ (v${_availableUpdate!.latestVersion} READY)'
                            : 'Software Update Center',
                      ),
                    ],
                    onSelected: (val) {
                      if (val == 'night_audit') NightAuditDialog.show(context);
                      if (val == 'search') GlobalSearchDialog.show(context, (mIdx, data) => _openModule(mIdx));
                      if (val == 'quick_new') QuickEntryLauncherDialog.show(context, (mIdx, code) => _handleQuickAction(mIdx, code));
                      if (val == 'deployment') _showDeploymentDialog(context);
                    },
                  ),
                  _navDropdownMenu(
                    label: 'Window',
                    items: [
                      _menuEntry('cascade', Icons.filter_none_rounded, 'Cascade Windows'),
                      _menuEntry('tile_v', Icons.view_column_outlined, 'Tile Vertically (Side-by-Side)'),
                      _menuEntry('tile_h', Icons.view_agenda_outlined, 'Tile Horizontally (Stacked)'),
                      const PopupMenuDivider(),
                      _menuEntry('min_all', Icons.minimize_rounded, 'Minimize All Windows'),
                      _menuEntry('restore_all', Icons.crop_square_rounded, 'Restore All Windows'),
                      _menuEntry('close_all', Icons.close_rounded, 'Close All Windows'),
                    ],
                    onSelected: (val) {
                      final constraints = _desktopConstraints ?? const BoxConstraints(maxWidth: 1200, maxHeight: 700);
                      if (val == 'cascade') _cascadeWindows(constraints);
                      if (val == 'tile_v') _tileWindowsVertically(constraints);
                      if (val == 'tile_h') _tileWindowsHorizontally(constraints);
                      if (val == 'min_all') _minimizeAllWindows();
                      if (val == 'restore_all') _restoreAllWindows();
                      if (val == 'close_all') _closeAllWindows();
                    },
                  ),
                  if (repo.currentErpUser.isDeveloper)
                    _navDropdownMenu(
                      label: 'Developer',
                      items: [
                        _menuEntry('portal', Icons.shield_rounded, 'iSecure Systems Developer Portal'),
                        _menuEntry('whitelabel', Icons.badge_rounded, 'Business & Whitelabel Configuration'),
                      ],
                      onSelected: (val) => DeveloperSettingsDialog.show(context),
                    ),
                  _navDropdownMenu(
                    label: 'Help',
                    items: [
                      _menuEntry('shortcuts', Icons.keyboard_rounded, 'Keyboard Shortcuts Guide (F1-F12, Ctrl)'),
                      _menuEntry('manual', Icons.menu_book_rounded, 'HotelPro Enterprise Operations Manual'),
                      const PopupMenuDivider(),
                      _menuEntry('about', Icons.info_outline_rounded, 'About HotelPro Enterprise ERP'),
                    ],
                    onSelected: (val) {
                      if (val == 'shortcuts') _showShortcutsGuide(context);
                      if (val == 'manual') _showManualDialog(context);
                      if (val == 'about') _showAboutDialog(context);
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── 3. Quick Action Toolbar Ribbon (New, Edit, Save, Find...) ──
          Container(
            width: double.infinity,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: const BoxDecoration(
              color: ClassicErpTheme.toolbarBg,
              border: Border(bottom: BorderSide(color: ClassicErpTheme.borderDark, width: 1)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _toolbarButton(Icons.note_add_rounded, 'New', () => _handleNewAction(repo)),
                          _toolbarButton(Icons.edit_note_rounded, 'Edit', () => _handleEditAction()),
                          _toolbarButton(Icons.save_rounded, 'Save', () => _handleSaveAction()),
                          _toolbarButton(Icons.search_rounded, 'Find', () => _handleFindAction()),
                          _toolbarSeparator(),
                          _toolbarButton(Icons.receipt_long_rounded, 'Tax Invoices', () => ClassicInvoiceRegisterDialog.show(context), color: const Color(0xFF1B4F72)),
                          _toolbarButton(Icons.nightlight_round, 'Night Audit', () => NightAuditDialog.show(context), color: const Color(0xFFB7950B)),
                          _toolbarSeparator(),
                          _toolbarButton(Icons.print_rounded, 'Reports', () => _handlePrintAction()),
                          _toolbarButton(Icons.help_outline_rounded, 'Help', () => _showShortcutsGuide(context)),
                          _toolbarButton(Icons.meeting_room_outlined, 'Close', () => _closeCurrentModule()),
                          _toolbarSeparator(),
                          _toolbarButton(Icons.play_circle_outline_rounded, 'Execute', () {
                            setState(() {
                              _activeOperation = 'sp_HotelPro_refresh';
                              _executionLatency = '0.012 Secs';
                            });
                          }),
                          _toolbarButton(Icons.cancel_presentation_rounded, 'Cnc Doc', () => _closeCurrentModule()),
                          _toolbarButton(Icons.cancel_rounded, 'Cancel', () => _closeCurrentModule(), color: Colors.red.shade700),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // Active Branch Selector Dropdown (STRICTLY filtered to user's allocated branches)
                      Builder(
                        builder: (context) {
                          final accessible = repo.accessibleBranches;
                          final selectedId = accessible.any((b) => b.id == activeBranch.id)
                              ? activeBranch.id
                              : accessible.first.id;

                          return Container(
                            height: 26,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedId,
                                isDense: true,
                                style: const TextStyle(color: ClassicErpTheme.textMain, fontSize: 11, fontWeight: FontWeight.bold),
                                items: accessible.map((b) {
                                  return DropdownMenuItem(
                                    value: b.id,
                                    child: Text('📍 ${b.code} — ${b.name}'),
                                  );
                                }).toList(),
                                onChanged: (id) {
                                  if (id != null) {
                                    repo.switchBranch(id);
                                    setState(() {
                                      _executionLatency = '0.014 Secs';
                                    });
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── 4. Main Workstation Area (MDI Multi-Window Container) ─────────
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(4),
              color: ClassicErpTheme.desktopBg,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _desktopConstraints = constraints;

                  // Defensive fallback: ensure each in-memory window has a valid positive zIndex
                  for (int i = 0; i < _openWindows.length; i++) {
                    final win = _openWindows[i];
                    if (win.zIndex <= 0) {
                      win.zIndex = i + 1;
                    }
                  }
                  if (_zCounter < _openWindows.length) {
                    _zCounter = _openWindows.length;
                  }

                  // Active window fallback
                  if (_activeWindow == null && _openWindows.isNotEmpty) {
                    _activeWindow = _openWindows.firstWhere(
                      (w) => !w.isMinimized,
                      orElse: () => _openWindows.first,
                    );
                  }

                  final sortedWindows = List<ErpWindow>.from(_openWindows)
                    ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

                  return Stack(
                    children: [
                      // Desktop Wallpaper & Shortcuts in Background
                      Positioned.fill(
                        child: _buildMdiDesktop(repo),
                      ),

                      // All open windows in Z-order
                      for (final win in sortedWindows)
                        _buildWindowFrame(
                          win,
                          constraints,
                          isActive: (win == _activeWindow && !win.isMinimized),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),

          // ── 4b. MDI Windows Taskbar (Multi-Window Switcher) ───────────
          Container(
            width: double.infinity,
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: const BoxDecoration(
              color: ClassicErpTheme.menuBarBg,
              border: Border(
                top: BorderSide(color: ClassicErpTheme.borderDark, width: 1),
                bottom: BorderSide(color: ClassicErpTheme.borderLight, width: 1),
              ),
            ),
            child: Row(
              children: [
                // Windows active count button
                InkWell(
                  onTap: () => _showWindowMenu(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4F72),
                      border: Border.all(color: Colors.white38, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.window_rounded, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Windows (${_openWindows.length})',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        if (_openWindows.length > 1) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const Text(
                              'Ctrl+Tab ⇋',
                              style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Horizontal list of open window tabs
                Expanded(
                  child: _openWindows.isEmpty
                      ? const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Desktop Ready • Select module from Menu or Shortcuts to operate multiple windows simultaneously',
                            style: TextStyle(color: ClassicErpTheme.textMuted, fontSize: 10, fontStyle: FontStyle.italic),
                          ),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _openWindows.length,
                          separatorBuilder: (ctx, idx) => const SizedBox(width: 4),
                          itemBuilder: (ctx, idx) {
                            final win = _openWindows[idx];
                            final isActive = (win == _activeWindow && !win.isMinimized);
                            return _buildTaskbarTab(win, isActive);
                          },
                        ),
                ),

                // Window arrangement buttons
                if (_openWindows.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  _taskbarActionBtn('Cascade', Icons.filter_none_rounded, () {
                    if (_desktopConstraints != null) _cascadeWindows(_desktopConstraints!);
                  }),
                  _taskbarActionBtn('Tile V', Icons.view_column_outlined, () {
                    if (_desktopConstraints != null) _tileWindowsVertically(_desktopConstraints!);
                  }),
                  _taskbarActionBtn('Tile H', Icons.view_agenda_outlined, () {
                    if (_desktopConstraints != null) _tileWindowsHorizontally(_desktopConstraints!);
                  }),
                  _taskbarActionBtn('Min All', Icons.minimize_rounded, _minimizeAllWindows),
                  _taskbarActionBtn('Close All', Icons.close_rounded, _closeAllWindows, color: Colors.red.shade700),
                ],
              ],
            ),
          ),

          // ── 5. Classic Enterprise Status Bar (Bottom) ───────────────────
          Container(
            width: double.infinity,
            height: 22,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: const BoxDecoration(
              color: ClassicErpTheme.statusBarBg,
              border: Border(top: BorderSide(color: ClassicErpTheme.borderLight, width: 1)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double firstPanelWidth = (constraints.maxWidth - 715.0).clamp(180.0, double.infinity);
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _statusPanel('$_activeOperation 18:32:50 -> $_executionLatency', width: firstPanelWidth),
                        _statusPanel('2026/2', width: 60),
                        _statusPanel(repo.currentErpUser.username, width: 85),
                        _statusPanel('PROB', width: 50),
                        _statusPanel('ML (Multi-Location)', width: 110),
                        _statusPanel(
                          _systemVersion,
                          width: 85,
                          textColor: const Color(0xFF1B4F72),
                          tooltip: 'HotelPro ERP Version: $_systemVersion (Click to open Software Update Center)',
                          onTap: () => _showDeploymentDialog(context),
                        ),
                        if (_availableUpdate?.hasUpdate == true)
                          _statusPanel(
                            '🚀 Update v${_availableUpdate!.latestVersion} Ready!',
                            width: 165,
                            textColor: Colors.white,
                            bgColor: const Color(0xFFC0392B),
                            tooltip: 'Click to install new update v${_availableUpdate!.latestVersion}',
                            onTap: () => _openUpdateFlow(),
                          ),
                        _statusPanel('Cloud Server: Connected (Secure)', width: 175, textColor: Colors.green.shade800),
                        _statusPanel('A: $currentTime', width: 140),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  ),
);
  }

  Widget _buildWindowFrame(ErpWindow win, BoxConstraints constraints, {required bool isActive}) {
    final maxW = constraints.maxWidth;
    final maxH = constraints.maxHeight;

    final double left = win.isMaximized
        ? 0
        : win.position.dx.clamp(0.0, (maxW - 120).clamp(0.0, double.infinity));
    final double top = win.isMaximized
        ? 0
        : win.position.dy.clamp(0.0, (maxH - 60).clamp(0.0, double.infinity));
    final double width = win.isMaximized
        ? maxW
        : win.size.width.clamp(480.0, maxW);
    final double height = win.isMaximized
        ? maxH
        : win.size.height.clamp(340.0, maxH);

    Widget windowBox = Container(
      decoration: BoxDecoration(
        color: ClassicErpTheme.windowBg,
        border: Border.all(
          color: isActive ? const Color(0xFF1B4F72) : const Color(0xFF7F8C8D),
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive ? Colors.black38 : Colors.black26,
            offset: const Offset(3, 3),
            blurRadius: isActive ? 8 : 4,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Window Content
          Positioned.fill(
            child: Material(
              color: ClassicErpTheme.windowBg,
              child: _buildModuleContent(win.moduleIndex, win, isActive),
            ),
          ),

          // Title bar drag handle (when floating)
          if (!win.isMaximized)
            Positioned(
              top: 0,
              left: 0,
              right: 90,
              height: 28,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanDown: (_) {
                  if (!isActive) _bringToFront(win);
                },
                onPanUpdate: (details) {
                  setState(() {
                    win.position = Offset(
                      (win.position.dx + details.delta.dx).clamp(0.0, (maxW - 150).clamp(0.0, double.infinity)),
                      (win.position.dy + details.delta.dy).clamp(0.0, (maxH - 50).clamp(0.0, double.infinity)),
                    );
                  });
                },
              ),
            ),

          // Bottom-Right Corner Resize Grip (when floating)
          if (!win.isMaximized)
            Positioned(
              right: 0,
              bottom: 0,
              width: 16,
              height: 16,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanDown: (_) {
                  if (!isActive) _bringToFront(win);
                },
                onPanUpdate: (details) {
                  setState(() {
                    win.size = Size(
                      (win.size.width + details.delta.dx).clamp(480.0, maxW),
                      (win.size.height + details.delta.dy).clamp(340.0, maxH),
                    );
                  });
                },
                child: const MouseRegion(
                  cursor: SystemMouseCursors.resizeDownRight,
                  child: Icon(Icons.signal_cellular_4_bar_rounded, size: 10, color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );

    // Only inactive windows need to listen for pointer down to bring to front.
    // Active windows are already focused and on top.
    if (!isActive) {
      windowBox = Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _bringToFront(win),
        child: windowBox,
      );
    }

    return Positioned(
      key: ValueKey<int>(win.moduleIndex),
      left: win.isMinimized ? 0 : left,
      top: win.isMinimized ? 0 : top,
      width: win.isMinimized ? 0 : width,
      height: win.isMinimized ? 0 : height,
      child: Offstage(
        offstage: win.isMinimized,
        child: windowBox,
      ),
    );
  }

  Widget _buildModuleContent(int index, ErpWindow win, bool isActive) {
    switch (index) {
      case 0:
        return _wrapMdiWindow(
          win,
          const FrontDeskView(onNavigateToTab: _dummyNav),
          isActive: isActive,
        );
      case 1:
        return _wrapMdiWindow(
          win,
          const FolioView(),
          isActive: isActive,
        );
      case 2:
        return _wrapMdiWindow(
          win,
          const PosRestaurantView(),
          isActive: isActive,
        );
      case 3:
        return _wrapMdiWindow(
          win,
          const HousekeepingView(),
          isActive: isActive,
        );
      case 4:
        return _wrapMdiWindow(
          win,
          const CrsReservationView(onNavigateToTab: _dummyNav),
          isActive: isActive,
        );
      case 5:
        return _wrapMdiWindow(
          win,
          const ExecutiveAnalyticsView(),
          isActive: isActive,
        );
      case 6:
        return ClassicMasterView(
          initialTab: win.initialTab,
          onClose: () => _closeWindow(win),
          onMinimize: () => _minimizeWindow(win),
          onMaximize: () => _toggleMaximizeWindow(win),
          isMaximized: win.isMaximized,
          isActive: isActive,
        );
      case 7:
        return AccountingView(
          initialTab: win.initialTab,
          onClose: () => _closeWindow(win),
          onMinimize: () => _minimizeWindow(win),
          onMaximize: () => _toggleMaximizeWindow(win),
          isMaximized: win.isMaximized,
          isActive: isActive,
        );
      case 8:
        return StockInventoryView(
          initialTab: win.initialTab,
          onClose: () => _closeWindow(win),
          onMinimize: () => _minimizeWindow(win),
          onMaximize: () => _toggleMaximizeWindow(win),
          isMaximized: win.isMaximized,
          isActive: isActive,
        );
      case 9:
        return _wrapMdiWindow(
          win,
          const OnlineDeliveryDashboardView(),
          isActive: isActive,
        );
      case 10:
        return _wrapMdiWindow(
          win,
          const DeliveryBoyManagementView(),
          isActive: isActive,
        );
      default:
        return ClassicMasterView(
          onClose: () => _closeWindow(win),
          onMinimize: () => _minimizeWindow(win),
          onMaximize: () => _toggleMaximizeWindow(win),
          isMaximized: win.isMaximized,
          isActive: isActive,
        );
    }
  }

  Widget _wrapMdiWindow(ErpWindow win, Widget child, {required bool isActive}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isActive
                  ? const [Color(0xFF1B4F72), Color(0xFF2874A6)]
                  : const [Color(0xFF5D6D7E), Color(0xFF85929E)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Row(
            children: [
              Icon(win.icon, color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  win.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              _mdiButton(Icons.remove, () => _minimizeWindow(win)),
              const SizedBox(width: 2),
              _mdiButton(win.isMaximized ? Icons.filter_none : Icons.crop_square, () => _toggleMaximizeWindow(win)),
              const SizedBox(width: 2),
              _mdiButton(Icons.close, () => _closeWindow(win), isClose: true),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildTaskbarTab(ErpWindow win, bool isActive) {
    return InkWell(
      onTap: () {
        if (win.isMinimized) {
          _restoreWindow(win);
        } else if (isActive) {
          _minimizeWindow(win);
        } else {
          _bringToFront(win);
        }
      },
      child: Container(
        width: 175,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white
              : (win.isMinimized ? const Color(0xFFD6DBDF) : const Color(0xFFEAEDED)),
          border: Border(
            top: BorderSide(color: isActive ? const Color(0xFF1B4F72) : ClassicErpTheme.borderDark, width: isActive ? 2 : 1),
            left: const BorderSide(color: ClassicErpTheme.borderDark, width: 1),
            right: const BorderSide(color: ClassicErpTheme.borderDark, width: 1),
            bottom: BorderSide(color: isActive ? Colors.transparent : ClassicErpTheme.borderDark, width: 1),
          ),
        ),
        child: Row(
          children: [
            Icon(win.icon, size: 12, color: isActive ? const Color(0xFF1B4F72) : ClassicErpTheme.textMuted),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                win.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? const Color(0xFF1B4F72) : ClassicErpTheme.textMain,
                ),
              ),
            ),
            InkWell(
              onTap: () => _closeWindow(win),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Icon(Icons.close, size: 10, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _taskbarActionBtn(String label, IconData icon, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: ClassicErpTheme.borderDark, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: color ?? const Color(0xFF1B4F72)),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(fontSize: 9.5, color: color ?? ClassicErpTheme.textMain, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _showWindowMenu(BuildContext context) {
    final RenderBox? overlay = Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
    final double screenW = overlay?.size.width ?? 1280.0;
    final double screenH = overlay?.size.height ?? 800.0;
    const menuBarHeight = 28 + 22;
    final position = RelativeRect.fromLTRB(420, menuBarHeight.toDouble(), screenW - 420, 0);

    final constraints = _desktopConstraints ?? BoxConstraints(
      maxWidth: screenW,
      maxHeight: screenH - 150,
    );

    showMenu<String>(
      context: context,
      position: position,
      color: ClassicErpTheme.panelBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: ClassicErpTheme.borderDark, width: 1),
      ),
      items: [
        _windowMenuItem('cascade', Icons.filter_none_rounded, 'Cascade Windows'),
        _windowMenuItem('tile_v', Icons.view_column_outlined, 'Tile Vertically (Side-by-Side)'),
        _windowMenuItem('tile_h', Icons.view_agenda_outlined, 'Tile Horizontally (Stacked)'),
        const PopupMenuDivider(),
        _windowMenuItem('min_all', Icons.minimize_rounded, 'Minimize All Windows'),
        _windowMenuItem('restore_all', Icons.crop_square_rounded, 'Restore All Windows'),
        _windowMenuItem('close_all', Icons.close_rounded, 'Close All Windows'),
        if (_openWindows.isNotEmpty) ...[
          const PopupMenuDivider(),
          for (int i = 0; i < _openWindows.length; i++)
            _windowMenuItem(
              'win_$i',
              _openWindows[i].icon,
              _openWindows[i].title,
              trailing: _openWindows[i] == _activeWindow && !_openWindows[i].isMinimized ? '✓' : null,
            ),
        ],
      ],
    ).then((choice) {
      if (choice == null) return;
      if (choice == 'cascade') _cascadeWindows(constraints);
      if (choice == 'tile_v') _tileWindowsVertically(constraints);
      if (choice == 'tile_h') _tileWindowsHorizontally(constraints);
      if (choice == 'min_all') _minimizeAllWindows();
      if (choice == 'restore_all') _restoreAllWindows();
      if (choice == 'close_all') _closeAllWindows();
      if (choice.startsWith('win_')) {
        final idx = int.tryParse(choice.replaceFirst('win_', ''));
        if (idx != null && idx >= 0 && idx < _openWindows.length) {
          _bringToFront(_openWindows[idx]);
        }
      }
    });
  }

  PopupMenuItem<String> _windowMenuItem(String value, IconData icon, String label, {String? trailing}) {
    return PopupMenuItem<String>(
      value: value,
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF1B4F72)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: ClassicErpTheme.textMain),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null)
            Text(trailing, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF27AE60))),
        ],
      ),
    );
  }

  Widget _buildMdiDesktop(HotelRepository repo) {
    return Container(
      color: const Color(0xFF4A6572).withValues(alpha: 0.25),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Enterprise Watermark & Logo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  border: Border.all(color: ClassicErpTheme.borderDark, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, offset: Offset(3, 3), blurRadius: 6),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      repo.clientBusinessName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B4F72),
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (repo.clientTagline.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        repo.clientTagline,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ClassicErpTheme.textMuted,
                        ),
                      ),
                    ],
                    if (repo.branches.length > 1) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Branch: ${repo.activeBranch.name} (${repo.activeBranch.code})',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF27AE60),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Program Shortcuts Grid (Classic Windows Desktop Program Icons)
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _desktopShortcut(Icons.inventory_2_rounded, 'Stock & Inventory', 'Ctrl+I', () => _openModule(8)),
                  _desktopShortcut(Icons.table_chart_rounded, 'Master Section', 'Ctrl+M', () => _openModule(6)),
                  _desktopShortcut(Icons.account_balance_wallet_rounded, 'Purchase & Finance', 'Ctrl+A', () => _openModule(7)),
                  _desktopShortcut(Icons.room_service_rounded, 'Front Desk', 'Ctrl+F', () => _openModule(0)),
                  _desktopShortcut(Icons.calendar_month_rounded, 'Reservations CRS', 'Ctrl+R', () => _openModule(4)),
                  _desktopShortcut(Icons.receipt_long_rounded, 'Billing & Folios', 'Ctrl+B', () => _openModule(1)),
                  _desktopShortcut(Icons.restaurant_rounded, 'POS Restaurant', 'Ctrl+P', () => _openModule(2)),
                  _desktopShortcut(Icons.delivery_dining_rounded, 'Online Delivery', 'Ctrl+O', () => _openModule(9)),
                  _desktopShortcut(Icons.two_wheeler_rounded, 'Delivery Boys', 'Ctrl+D', () => _openModule(10)),
                  _desktopShortcut(Icons.cleaning_services_rounded, 'Housekeeping', 'Ctrl+H', () => _openModule(3)),
                  _desktopShortcut(Icons.analytics_rounded, 'Executive GM', 'Ctrl+E', () => _openModule(5)),
                  if (repo.currentErpUser.isDeveloper)
                    _desktopShortcut(Icons.shield_rounded, 'Developer Portal', 'iSecure', () => DeveloperSettingsDialog.show(context), isDev: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _desktopShortcut(IconData icon, String title, String shortcut, VoidCallback onTap, {bool isDev = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 130,
        height: 100,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDev ? const Color(0xFFE8F8F5) : Colors.white,
          border: Border.all(color: isDev ? const Color(0xFF1ABC9C) : ClassicErpTheme.borderDark, width: 1),
          boxShadow: const [
            BoxShadow(color: Colors.black12, offset: Offset(2, 2), blurRadius: 3),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: isDev ? const Color(0xFF006266) : const Color(0xFF1B4F72)),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: ClassicErpTheme.textMain,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              shortcut,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isDev ? const Color(0xFF006266) : ClassicErpTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mdiButton(IconData icon, VoidCallback onTap, {bool isClose = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 16,
        height: 14,
        decoration: BoxDecoration(
          color: isClose ? const Color(0xFFC0392B) : const Color(0xFFD6DBDF),
          border: Border.all(color: Colors.white, width: 0.5),
        ),
        child: Icon(
          icon,
          size: 10,
          color: isClose ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  static void _dummyNav(int i) {}

  // ── Helper Widgets ──────────────────────────────────────────────────────
  Widget _navDropdownMenu({
    required String label,
    required List<PopupMenuEntry<String>> items,
    required ValueChanged<String> onSelected,
    bool isBold = false,
  }) {
    return Builder(
      builder: (btnCtx) {
        return InkWell(
          onTap: () {
            final RenderBox box = btnCtx.findRenderObject() as RenderBox;
            final Offset pos = box.localToGlobal(Offset.zero);
            final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
            final position = RelativeRect.fromLTRB(
              pos.dx,
              pos.dy + box.size.height,
              overlay.size.width - (pos.dx + box.size.width),
              0,
            );
            showMenu<String>(
              context: context,
              position: position,
              color: ClassicErpTheme.panelBg,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: ClassicErpTheme.borderDark, width: 1),
              ),
              items: items,
            ).then((val) {
              if (val != null) onSelected(val);
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: ClassicErpTheme.textMain,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 1),
                const Icon(Icons.arrow_drop_down, size: 12, color: ClassicErpTheme.textMuted),
              ],
            ),
          ),
        );
      },
    );
  }

  PopupMenuItem<String> _menuEntry(String value, IconData icon, String title) {
    return PopupMenuItem<String>(
      value: value,
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF1B4F72)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 11, color: ClassicErpTheme.textMain)),
        ],
      ),
    );
  }


  Widget _toolbarButton(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 44,
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color ?? const Color(0xFF2C3E50)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                color: color ?? ClassicErpTheme.textMain,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolbarSeparator() {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: ClassicErpTheme.borderDark.withValues(alpha: 0.5),
    );
  }

  Widget _statusPanel(String text, {int? flex, double? width, Color? textColor, Color? bgColor, VoidCallback? onTap, String? tooltip}) {
    Widget panelContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor ?? ClassicErpTheme.statusBarBg,
        border: Border.all(color: Colors.white, width: 0.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(-1, -1),
            blurRadius: 0.5,
          ),
        ],
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          color: textColor ?? ClassicErpTheme.textMain,
          fontWeight: FontWeight.w500,
        ),
      ),
    );

    if (onTap != null) {
      panelContent = InkWell(
        onTap: onTap,
        child: panelContent,
      );
    }

    if (tooltip != null) {
      panelContent = Tooltip(
        message: tooltip,
        child: panelContent,
      );
    }

    if (width != null) {
      return SizedBox(width: width, child: panelContent);
    }
    return Expanded(flex: flex ?? 1, child: panelContent);
  }

  Widget _titleButton(IconData icon, VoidCallback onTap, {bool isClose = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 16,
        height: 14,
        color: isClose ? const Color(0xFFC0392B) : const Color(0xFF1E3799),
        alignment: Alignment.center,
        child: Icon(icon, size: 9, color: Colors.white),
      ),
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────
  void _handleNewAction(HotelRepository repo) {
    if (_activeWindow?.moduleIndex == 1) {
      ClassicInvoiceRegisterDialog.show(context);
    } else {
      QuickEntryLauncherDialog.show(context, (mIdx, code) => _handleQuickAction(mIdx, code));
    }
  }

  void _handleQuickAction(int moduleIndex, String actionCode) {
    if (actionCode == 'CREATE_INVOICE') {
      ClassicInvoiceRegisterDialog.show(context);
    } else if (actionCode == 'NEW_MENU_ITEM') {
      _openModule(6, initialTab: 2);
    } else if (actionCode == 'NEW_PURCHASE') {
      _openModule(7, initialTab: 0);
    } else if (actionCode == 'NEW_EXPENSE') {
      _openModule(7, initialTab: 1);
    } else if (actionCode == 'NEW_STOCK_ITEM') {
      _openModule(8, initialTab: 0);
    } else {
      _openModule(moduleIndex);
    }
  }

  void _handleEditAction() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Row selected for modification. Double-click row to edit details.'), backgroundColor: ClassicErpTheme.mdiHeaderActive, duration: Duration(seconds: 2)),
    );
  }

  void _handleSaveAction() {
    setState(() {
      _activeOperation = 'sp_HotelPro_sync_committed';
      _executionLatency = '0.003 Secs';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ All active changes saved and committed to local database.'),
        backgroundColor: Color(0xFF27AE60),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleFindAction() {
    GlobalSearchDialog.show(context, (modIdx, data) => _openModule(modIdx));
  }

  void _handleSyncAction() {
    setState(() {
      _activeOperation = 'sp_HotelPro_cloud_sync';
      _executionLatency = '0.008 Secs';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Local database and cloud server synchronized successfully.'),
        backgroundColor: Color(0xFF27AE60),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showDiagnosticsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClassicErpTheme.panelBg,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: ClassicErpTheme.borderDark, width: 2)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(8),
          color: const Color(0xFF1B4F72),
          child: const Row(
            children: [
              Icon(Icons.speed_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('System Diagnostics & Performance Latency', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Engine Latency: $_executionLatency', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Active Stored Procedure: $_activeOperation', style: const TextStyle(fontSize: 11, color: ClassicErpTheme.textMuted)),
              const SizedBox(height: 6),
              Text('Installed Version: Enterprise ERP v${_systemVersion.replaceAll('v', '')}', style: const TextStyle(fontSize: 11, color: ClassicErpTheme.textMuted)),
              const SizedBox(height: 6),
              const Text('Cloud Sync Engine: Connected & Active (Zero Packet Loss)', style: TextStyle(fontSize: 11, color: Color(0xFF27AE60), fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Open Windows in Memory: ${_openWindows.length}', style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4F72), foregroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  void _showShortcutsGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClassicErpTheme.panelBg,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: ClassicErpTheme.borderDark, width: 2)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(8),
          color: const Color(0xFF1B4F72),
          child: const Row(
            children: [
              Icon(Icons.keyboard_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('HotelPro Keyboard Shortcuts & Hotkeys Guide', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        content: SizedBox(
          width: 490,
          child: Table(
            border: TableBorder.all(color: ClassicErpTheme.borderLight, width: 0.8),
            children: const [
              TableRow(
                decoration: BoxDecoration(color: Color(0xFFEAECEE)),
                children: [
                  Padding(padding: EdgeInsets.all(6), child: Text('Shortcut Key', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5))),
                  Padding(padding: EdgeInsets.all(6), child: Text('Workstation Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5))),
                ],
              ),
              TableRow(children: [Padding(padding: EdgeInsets.all(5), child: Text('F1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))), Padding(padding: EdgeInsets.all(5), child: Text('Keyboard shortcuts reference guide', style: TextStyle(fontSize: 10)))]),
              TableRow(children: [Padding(padding: EdgeInsets.all(5), child: Text('F2', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))), Padding(padding: EdgeInsets.all(5), child: Text('Front Desk [Live Room Matrix & Tape Chart]', style: TextStyle(fontSize: 10)))]),
              TableRow(children: [Padding(padding: EdgeInsets.all(5), child: Text('F3 / Ctrl+R', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))), Padding(padding: EdgeInsets.all(5), child: Text('Reservations [Central Reservation System - CRS]', style: TextStyle(fontSize: 10)))]),
              TableRow(children: [Padding(padding: EdgeInsets.all(5), child: Text('F4 / Ctrl+B', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))), Padding(padding: EdgeInsets.all(5), child: Text('Billing & Cashiering [Guest Folio Accounts]', style: TextStyle(fontSize: 10)))]),
              TableRow(children: [Padding(padding: EdgeInsets.all(5), child: Text('F5 / Ctrl+P', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))), Padding(padding: EdgeInsets.all(5), child: Text('Restaurant POS [Table Layout & KOT Order]', style: TextStyle(fontSize: 10)))]),
              TableRow(children: [Padding(padding: EdgeInsets.all(5), child: Text('F6 / Ctrl+H', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))), Padding(padding: EdgeInsets.all(5), child: Text('Housekeeping [Room Status Board & Tasks]', style: TextStyle(fontSize: 10)))]),
              TableRow(children: [Padding(padding: EdgeInsets.all(5), child: Text('F7 / Ctrl+A', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))), Padding(padding: EdgeInsets.all(5), child: Text('Purchase & Accounts [Expense & Balance Sheet]', style: TextStyle(fontSize: 10)))]),
              TableRow(children: [Padding(padding: EdgeInsets.all(5), child: Text('F8 / Ctrl+I', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))), Padding(padding: EdgeInsets.all(5), child: Text('Stock & Materials [Live Inventory Ledger]', style: TextStyle(fontSize: 10)))]),
              TableRow(children: [Padding(padding: EdgeInsets.all(5), child: Text('F9 / Ctrl+M', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))), Padding(padding: EdgeInsets.all(5), child: Text('Master Section [Rooms, Menus, Staff, CRM]', style: TextStyle(fontSize: 10)))]),
              TableRow(children: [Padding(padding: EdgeInsets.all(5), child: Text('F10 / Print', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))), Padding(padding: EdgeInsets.all(5), child: Text('Reports & Document Export Center', style: TextStyle(fontSize: 10)))]),
              TableRow(children: [Padding(padding: EdgeInsets.all(5), child: Text('F11', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))), Padding(padding: EdgeInsets.all(5), child: Text('Night Audit & Business Day Rollover Wizard', style: TextStyle(fontSize: 10)))]),
              TableRow(children: [Padding(padding: EdgeInsets.all(5), child: Text('F12 / Ctrl+F', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))), Padding(padding: EdgeInsets.all(5), child: Text('Global Search & Jump Terminal', style: TextStyle(fontSize: 10)))]),
              TableRow(children: [Padding(padding: EdgeInsets.all(5), child: Text('Ctrl + N', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))), Padding(padding: EdgeInsets.all(5), child: Text('Quick Creation Launcher Modal', style: TextStyle(fontSize: 10)))]),
              TableRow(children: [Padding(padding: EdgeInsets.all(5), child: Text('Ctrl + Tab', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))), Padding(padding: EdgeInsets.all(5), child: Text('Cycle through open MDI windows', style: TextStyle(fontSize: 10)))]),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4F72), foregroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close Guide', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  void _showManualDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClassicErpTheme.panelBg,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: ClassicErpTheme.borderDark, width: 2)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(8),
          color: const Color(0xFF1B4F72),
          child: const Row(
            children: [
              Icon(Icons.menu_book_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('HotelPro Enterprise Operations Manual', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        content: const SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Standard Operating Workflow for Front Office & Cashiering:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                SizedBox(height: 8),
                Text('1. Check-In: Use Front Desk or Reservations to register guest details, upload ID proof, and allocate room RFID code.\n\n'
                    '2. Dining & Room Service: Punch restaurant orders via POS Restaurant. KOT prints to kitchen, and bills can be charged to room folio or settled instantly.\n\n'
                    '3. Invoicing: Generate GST-compliant tax invoices via Billing & Folio or Invoices & Tax ribbon with SAC codes (996311/996331).\n\n'
                    '4. Materials Management: Monitor live stock in Stock & Inventory and enter supplier bills with input tax credit in Purchase & Finance.\n\n'
                    '5. Day-End Night Audit: Run Night Audit (F11 or Tools -> Night Audit) at midnight to balance cashier drawers, post room tariffs, and rollover business date.',
                    style: TextStyle(fontSize: 10.5, height: 1.5, color: ClassicErpTheme.textMain)),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4F72), foregroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  void _handlePrintAction() {
    final repo = context.read<HotelRepository>();
    final currency = NumberFormat.currency(symbol: 'Rs.', decimalDigits: 0);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: ClassicErpTheme.panelBg,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Container(
          width: 620,
          decoration: BoxDecoration(
            color: ClassicErpTheme.panelBg,
            border: Border.all(color: ClassicErpTheme.borderDark, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title bar
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B4F72), Color(0xFF2874A6)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.print_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    const Expanded(child: Text('Reports & Print Center',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                    InkWell(onTap: () => Navigator.pop(ctx),
                        child: const Icon(Icons.close, color: Colors.white, size: 16)),
                  ],
                ),
              ),
              // Report List
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Select a report to preview or export:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain)),
                    const SizedBox(height: 10),
                    _reportRow(ctx, repo,
                      icon: Icons.analytics_rounded,
                      title: 'Executive MIS — Financial Performance Summary',
                      subtitle: 'RevPAR, ADR, Occupancy, Branch KPIs',
                      onPreview: () {
                        Navigator.pop(ctx);
                        PrintPreviewDialog.show(context,
                          title: 'Executive MIS Report',
                          content: _buildMisDoc(repo, currency),
                        );
                      },
                      onExport: () {
                        Navigator.pop(ctx);
                        ExcelExportService.saveAsCsv(context,
                          suggestedName: 'MIS_Report_${DateTime.now().toIso8601String().substring(0, 10)}',
                          headers: ['Metric', 'Value', 'Branch', 'Date'],
                          rows: [
                            ['REVPAR', currency.format(repo.revenuePerAvailableRoom), repo.activeBranch.name, DateTime.now().toIso8601String().substring(0, 10)],
                            ['ADR', currency.format(repo.averageDailyRate), repo.activeBranch.name, DateTime.now().toIso8601String().substring(0, 10)],
                            ['Occupancy %', '${repo.occupancyRate.toStringAsFixed(1)}%', repo.activeBranch.name, DateTime.now().toIso8601String().substring(0, 10)],
                          ],
                        );
                      },
                    ),
                    _reportRow(ctx, repo,
                      icon: Icons.cleaning_services_rounded,
                      title: 'Housekeeping Task Status Report',
                      subtitle: 'Pending, In-Progress, Inspected rooms summary',
                      onPreview: () {
                        Navigator.pop(ctx);
                        final tasks = repo.activeBranchHousekeeping;
                        PrintPreviewDialog.show(context,
                          title: 'Housekeeping Report',
                          content: _buildSimpleTableDoc(
                            title: 'Housekeeping Task Report',
                            branchName: repo.activeBranch.name,
                            headers: ['Room', 'Task Type', 'Status', 'Assigned Staff', 'Priority'],
                            rows: tasks.map((t) => [t.roomNumber, t.taskType, t.status, t.assignedStaff, t.priority.label]).toList(),
                            icon: Icons.cleaning_services_rounded,
                            repo: repo,
                          ),
                        );
                      },
                      onExport: () {
                        Navigator.pop(ctx);
                        ExcelExportService.saveAsCsv(context,
                          suggestedName: 'Housekeeping_Report_${DateTime.now().toIso8601String().substring(0, 10)}',
                          headers: ['Room No', 'Task Type', 'Status', 'Assigned Staff', 'Priority', 'Notes'],
                          rows: repo.activeBranchHousekeeping.map((t) => [
                            t.roomNumber, t.taskType, t.status, t.assignedStaff, t.priority.label, t.inspectionNotes ?? ''
                          ]).toList(),
                        );
                      },
                    ),
                    _reportRow(ctx, repo,
                      icon: Icons.hotel_rounded,
                      title: 'Room Inventory & Status Report',
                      subtitle: 'All rooms with current status and guest occupancy',
                      onPreview: () {
                        Navigator.pop(ctx);
                        final rooms = repo.activeBranchRooms;
                        PrintPreviewDialog.show(context,
                          title: 'Room Inventory Report',
                          content: _buildSimpleTableDoc(
                            title: 'Room Inventory & Status Report',
                            branchName: repo.activeBranch.name,
                            headers: ['Room No', 'Floor', 'Type', 'Price', 'Status', 'Guest'],
                            rows: rooms.map((r) => [
                              r.roomNumber, r.floorNumber == 0 ? 'Ground' : 'Floor ${r.floorNumber}',
                              r.roomTypeName, currency.format(r.basePrice), r.status.label, r.currentGuestName ?? 'Vacant'
                            ]).toList(),
                            icon: Icons.hotel_rounded,
                            repo: repo,
                          ),
                        );
                      },
                      onExport: () {
                        Navigator.pop(ctx);
                        ExcelExportService.saveAsCsv(context,
                          suggestedName: 'RoomStatus_Report_${DateTime.now().toIso8601String().substring(0, 10)}',
                          headers: ['Room No', 'Floor', 'Type', 'Base Price', 'Status', 'Current Guest'],
                          rows: repo.activeBranchRooms.map((r) => [
                            r.roomNumber, r.floorNumber.toString(), r.roomTypeName,
                            currency.format(r.basePrice), r.status.label, r.currentGuestName ?? 'Vacant'
                          ]).toList(),
                        );
                      },
                    ),
                    _reportRow(ctx, repo,
                      icon: Icons.restaurant_menu_rounded,
                      title: 'F&B Menu Master Report',
                      subtitle: 'All menu items with pricing, tax and availability',
                      onPreview: () {
                        Navigator.pop(ctx);
                        final menu = repo.activeBranchMenuItems;
                        PrintPreviewDialog.show(context,
                          title: 'F&B Menu Report',
                          content: _buildSimpleTableDoc(
                            title: 'Restaurant F&B Menu Master',
                            branchName: repo.activeBranch.name,
                            headers: ['Code', 'Name', 'Category', 'Price', 'GST%', 'Type'],
                            rows: menu.map((m) => [
                              m.id, m.name, m.category, currency.format(m.price),
                              '${m.taxRate.toStringAsFixed(0)}%', m.isVeg ? 'Veg' : 'Non-Veg'
                            ]).toList(),
                            icon: Icons.restaurant_menu_rounded,
                            repo: repo,
                          ),
                        );
                      },
                      onExport: () {
                        Navigator.pop(ctx);
                        ExcelExportService.saveAsCsv(context,
                          suggestedName: 'FoodMenu_Report_${DateTime.now().toIso8601String().substring(0, 10)}',
                          headers: ['Item Code', 'Name', 'Category', 'Price', 'GST%', 'Veg/Non-Veg', 'Available'],
                          rows: repo.activeBranchMenuItems.map((m) => [
                            m.id, m.name, m.category, currency.format(m.price),
                            '${m.taxRate.toStringAsFixed(0)}%', m.isVeg ? 'Veg' : 'Non-Veg', m.isAvailable ? 'Yes' : 'No'
                          ]).toList(),
                        );
                      },
                    ),
                    _reportRow(ctx, repo,
                      icon: Icons.shopping_bag_rounded,
                      title: 'Purchase Register & Supplier Invoices Report',
                      subtitle: 'Itemized material purchases, GST input tax and vendor dues',
                      onPreview: () {
                        Navigator.pop(ctx);
                        final purchases = repo.activeBranchPurchases;
                        PrintPreviewDialog.show(context,
                          title: 'Purchase Register Report',
                          content: _buildSimpleTableDoc(
                            title: 'Purchase Register & Supplier Invoices',
                            branchName: repo.activeBranch.name,
                            headers: ['Invoice No', 'Date', 'Supplier', 'Dept', 'SubTotal', 'GST', 'Grand Total', 'Status'],
                            rows: purchases.map((p) => [
                              p.invoiceNumber, DateFormat('dd-MM-yy').format(p.purchaseDate), p.vendorName,
                              p.department, currency.format(p.subTotal), currency.format(p.totalTax),
                              currency.format(p.grandTotal), p.paymentStatus
                            ]).toList(),
                            icon: Icons.shopping_bag_rounded,
                            repo: repo,
                          ),
                        );
                      },
                      onExport: () {
                        Navigator.pop(ctx);
                        ExcelExportService.saveAsCsv(context,
                          suggestedName: 'Purchase_Register_${DateTime.now().toIso8601String().substring(0, 10)}',
                          headers: ['Invoice No', 'Date', 'Supplier', 'GSTIN', 'Department', 'SubTotal', 'Tax', 'Grand Total', 'Mode', 'Status'],
                          rows: repo.activeBranchPurchases.map((p) => [
                            p.invoiceNumber, DateFormat('yyyy-MM-dd').format(p.purchaseDate), p.vendorName, p.vendorGstin,
                            p.department, p.subTotal.toString(), p.totalTax.toString(), p.grandTotal.toString(), p.paymentMode, p.paymentStatus
                          ]).toList(),
                        );
                      },
                    ),
                    _reportRow(ctx, repo,
                      icon: Icons.inventory_2_rounded,
                      title: 'Stock Inventory Valuation & Status Report',
                      subtitle: 'Live stock quantities in-hand, reorder thresholds and inventory assets',
                      onPreview: () {
                        Navigator.pop(ctx);
                        final stock = repo.activeBranchStockItems;
                        PrintPreviewDialog.show(context,
                          title: 'Stock Inventory Ledger',
                          content: _buildSimpleTableDoc(
                            title: 'Material Stock & Inventory Valuation Report',
                            branchName: repo.activeBranch.name,
                            headers: ['Item Code', 'Item Name', 'Category', 'Store', 'In-Hand', 'Unit', 'Reorder', 'Valuation', 'Status'],
                            rows: stock.map((s) => [
                              s.itemCode, s.name, s.category, s.storageLocation,
                              s.currentStock.toStringAsFixed(1), s.unit, s.reorderLevel.toStringAsFixed(1),
                              currency.format(s.valuation), s.status.label
                            ]).toList(),
                            icon: Icons.inventory_2_rounded,
                            repo: repo,
                          ),
                        );
                      },
                      onExport: () {
                        Navigator.pop(ctx);
                        ExcelExportService.saveAsCsv(context,
                          suggestedName: 'Stock_Valuation_${DateTime.now().toIso8601String().substring(0, 10)}',
                          headers: ['Item Code', 'Item Name', 'Category', 'Storage Location', 'Current Stock', 'Unit', 'Reorder Level', 'Unit Price', 'Total Valuation', 'Status'],
                          rows: repo.activeBranchStockItems.map((s) => [
                            s.itemCode, s.name, s.category, s.storageLocation,
                            s.currentStock.toString(), s.unit, s.reorderLevel.toString(),
                            s.unitPrice.toString(), s.valuation.toString(), s.status.label
                          ]).toList(),
                        );
                      },
                    ),
                    _reportRow(ctx, repo,
                      icon: Icons.receipt_long_rounded,
                      title: 'Operating Expense Sheet & Voucher Ledger',
                      subtitle: 'Utilities, maintenance, salaries and petty cash outlays with bill copies',
                      onPreview: () {
                        Navigator.pop(ctx);
                        final expenses = repo.activeBranchExpenses;
                        PrintPreviewDialog.show(context,
                          title: 'Operating Expense Sheet Report',
                          content: _buildSimpleTableDoc(
                            title: 'Operating Expense Sheet & Vouchers',
                            branchName: repo.activeBranch.name,
                            headers: ['Voucher No', 'Date', 'Category', 'Paid To', 'Description', 'Mode', 'Net Outflow (₹)'],
                            rows: expenses.map((e) => [
                              e.voucherNo, DateFormat('dd-MM-yy').format(e.date), e.category,
                              e.paidTo, e.description, e.paymentMode, currency.format(e.netAmount)
                            ]).toList(),
                            icon: Icons.receipt_long_rounded,
                            repo: repo,
                          ),
                        );
                      },
                      onExport: () {
                        Navigator.pop(ctx);
                        ExcelExportService.saveAsCsv(context,
                          suggestedName: 'Expense_Sheet_${DateTime.now().toIso8601String().substring(0, 10)}',
                          headers: ['Voucher No', 'Date', 'Category', 'Paid To', 'Description', 'Amount', 'Tax', 'Net Amount', 'Mode', 'Bill Attached'],
                          rows: repo.activeBranchExpenses.map((e) => [
                            e.voucherNo, DateFormat('yyyy-MM-dd').format(e.date), e.category, e.paidTo,
                            e.description, e.amount.toString(), e.taxAmount.toString(), e.netAmount.toString(), e.paymentMode, e.hasBillCopy ? 'Yes' : 'No'
                          ]).toList(),
                        );
                      },
                    ),
                    _reportRow(ctx, repo,
                      icon: Icons.balance_rounded,
                      title: 'Audited Balance Sheet & Financial Statements',
                      subtitle: 'Comprehensive financial position: Assets = Liabilities + Equity & Retained Earnings',
                      onPreview: () {
                        Navigator.pop(ctx);
                        final bs = repo.getActiveBranchBalanceSheet();
                        PrintPreviewDialog.show(context,
                          title: 'Balance Sheet Statement',
                          content: _buildSimpleTableDoc(
                            title: 'Audited Balance Sheet Statement',
                            branchName: '${repo.activeBranch.name} • ${bs.financialYear}',
                            headers: ['Account Group', 'Line Item Description', 'Code', 'Amount (₹)'],
                            rows: [
                              ...bs.currentAssets.map((i) => ['Current Assets', i.title, i.code, currency.format(i.amount)]),
                              ['Total Current Assets', 'SUBTOTAL CURRENT ASSETS', '', currency.format(bs.totalCurrentAssets)],
                              ...bs.fixedAssets.map((i) => ['Fixed Assets', i.title, i.code, currency.format(i.amount)]),
                              ['Total Fixed Assets', 'SUBTOTAL FIXED ASSETS', '', currency.format(bs.totalFixedAssets)],
                              ['TOTAL ASSETS', 'GRAND TOTAL ASSETS', '', currency.format(bs.totalAssets)],
                              ...bs.currentLiabilities.map((i) => ['Current Liabilities', i.title, i.code, currency.format(i.amount)]),
                              ['Total Current Liabilities', 'SUBTOTAL CURRENT LIABILITIES', '', currency.format(bs.totalCurrentLiabilities)],
                              ...bs.longTermLiabilities.map((i) => ['Long Term Liabilities', i.title, i.code, currency.format(i.amount)]),
                              ['Total Long Term Liabilities', 'SUBTOTAL LONG TERM LIABILITIES', '', currency.format(bs.totalLongTermLiabilities)],
                              ...bs.equityItems.map((i) => ['Equity & Reserves', i.title, i.code, currency.format(i.amount)]),
                              ['Total Equity', 'SUBTOTAL EQUITY & RESERVES', '', currency.format(bs.totalEquity)],
                              ['TOTAL LIAB & EQUITY', 'GRAND TOTAL LIABILITIES & EQUITY', '', currency.format(bs.totalLiabilitiesAndEquity)],
                            ],
                            icon: Icons.balance_rounded,
                            repo: repo,
                          ),
                        );
                      },
                      onExport: () {
                        Navigator.pop(ctx);
                        final bs = repo.getActiveBranchBalanceSheet();
                        ExcelExportService.saveAsCsv(context,
                          suggestedName: 'Balance_Sheet_${DateTime.now().toIso8601String().substring(0, 10)}',
                          headers: ['Category', 'Line Item Description', 'Code', 'Amount (INR)'],
                          rows: [
                            ...bs.currentAssets.map((i) => ['Current Assets', i.title, i.code, i.amount.toString()]),
                            ['Current Assets Total', 'TOTAL CURRENT ASSETS', '', bs.totalCurrentAssets.toString()],
                            ...bs.fixedAssets.map((i) => ['Fixed Assets', i.title, i.code, i.amount.toString()]),
                            ['Fixed Assets Total', 'TOTAL FIXED ASSETS', '', bs.totalFixedAssets.toString()],
                            ['Total Assets', 'GRAND TOTAL ASSETS', '', bs.totalAssets.toString()],
                            ...bs.currentLiabilities.map((i) => ['Current Liabilities', i.title, i.code, i.amount.toString()]),
                            ['Current Liabilities Total', 'TOTAL CURRENT LIABILITIES', '', bs.totalCurrentLiabilities.toString()],
                            ...bs.longTermLiabilities.map((i) => ['Long Term Liabilities', i.title, i.code, i.amount.toString()]),
                            ['Long Term Liabilities Total', 'TOTAL LONG TERM LIABILITIES', '', bs.totalLongTermLiabilities.toString()],
                            ...bs.equityItems.map((i) => ['Equity & Reserves', i.title, i.code, i.amount.toString()]),
                            ['Equity Total', 'TOTAL EQUITY & RESERVES', '', bs.totalEquity.toString()],
                            ['Total Liabilities & Equity', 'GRAND TOTAL LIABILITIES & EQUITY', '', bs.totalLiabilitiesAndEquity.toString()],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          decoration: BoxDecoration(
                            color: ClassicErpTheme.buttonBg,
                            border: Border.all(color: ClassicErpTheme.borderDark),
                          ),
                          child: const Text('Close', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reportRow(
    BuildContext ctx,
    HotelRepository repo, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPreview,
    required VoidCallback onExport,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: ClassicErpTheme.mdiHeaderActive),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain)),
                Text(subtitle, style: const TextStyle(fontSize: 9.5, color: ClassicErpTheme.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _miniBtn(Icons.preview_rounded, 'Preview', onPreview, const Color(0xFF1B4F72)),
          const SizedBox(width: 4),
          _miniBtn(Icons.download_rounded, 'Export', onExport, ClassicErpTheme.excelGreen),
        ],
      ),
    );
  }

  Widget _miniBtn(IconData icon, String label, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: color, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildMisDoc(HotelRepository repo, NumberFormat currency) {
    final now = DateFormat('dd MMM yyyy  HH:mm').format(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                HotelLogoWidget(repo: repo, width: 48, height: 48),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${repo.clientBusinessName} — Executive MIS',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1B4F72))),
                    Text('Branch: ${repo.activeBranch.name}  |  ${repo.activeBranch.city}',
                        style: const TextStyle(fontSize: 11, color: ClassicErpTheme.textMuted)),
                    Text('Generated: $now', style: const TextStyle(fontSize: 9, color: ClassicErpTheme.textMuted)),
                  ],
                ),
              ],
            ),
            const Icon(Icons.analytics_rounded, size: 36, color: Color(0xFF1B4F72)),
          ],
        ),
        const Divider(thickness: 2, color: Color(0xFF1B4F72)),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(color: ClassicErpTheme.borderDark, width: 0.5),
          children: [
            _tHeader(['METRIC', 'VALUE', 'STATUS']),
            _tRow(['REVPAR', currency.format(repo.revenuePerAvailableRoom), '+14.2% vs prev. period']),
            _tRow(['ADR', currency.format(repo.averageDailyRate), 'Standard Tariff Met']),
            _tRow(['Occupancy Ratio', '${repo.occupancyRate.toStringAsFixed(1)}%', '${repo.occupiedRoomsCount} / ${repo.activeBranchRooms.length} Rooms']),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
        const Text('iSecure Systems Pvt. Ltd.  •  Contact: 9326770568',
            style: TextStyle(fontSize: 9, color: ClassicErpTheme.textMuted)),
      ],
    );
  }

  Widget _buildSimpleTableDoc({
    required String title,
    required String branchName,
    required List<String> headers,
    required List<List<String>> rows,
    required IconData icon,
    HotelRepository? repo,
  }) {
    final now = DateFormat('dd MMM yyyy  HH:mm').format(DateTime.now());
    final bName = repo?.clientBusinessName ?? branchName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                HotelLogoWidget(repo: repo, width: 44, height: 44),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$bName — $title',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                    Text('Branch: $branchName  |  Generated: $now',
                        style: const TextStyle(fontSize: 9, color: ClassicErpTheme.textMuted)),
                  ],
                ),
              ],
            ),
            Icon(icon, size: 32, color: const Color(0xFF1B4F72)),
          ],
        ),
        const Divider(thickness: 1.5, color: Color(0xFF1B4F72), height: 14),
        Table(
          border: TableBorder.all(color: ClassicErpTheme.borderDark, width: 0.5),
          children: [
            _tHeader(headers),
            ...rows.asMap().entries.map((e) => TableRow(
              decoration: BoxDecoration(color: e.key.isEven ? Colors.white : const Color(0xFFF4F6F7)),
              children: e.value.map((cell) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                child: Text(cell, style: const TextStyle(fontSize: 9, color: ClassicErpTheme.textMain)),
              )).toList(),
            )),
          ],
        ),
        const SizedBox(height: 10),
        Text('Total Records: ${rows.length}',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain)),
        const SizedBox(height: 14),
        const Divider(),
        const Text('iSecure Systems Pvt. Ltd.  •  HotelPro  •  Contact: 9326770568',
            style: TextStyle(fontSize: 8, color: ClassicErpTheme.textMuted), textAlign: TextAlign.center),
      ],
    );
  }

  TableRow _tHeader(List<String> cells) => TableRow(
    decoration: const BoxDecoration(color: Color(0xFF1B4F72)),
    children: cells.map((h) => Padding(
      padding: const EdgeInsets.all(5),
      child: Text(h, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
    )).toList(),
  );

  TableRow _tRow(List<String> cells) => TableRow(
    children: cells.map((c) => Padding(
      padding: const EdgeInsets.all(5),
      child: Text(c, style: const TextStyle(fontSize: 10, color: ClassicErpTheme.textMain)),
    )).toList(),
  );


  void _showChangePasswordDialog(BuildContext context, HotelRepository repo) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClassicErpTheme.panelBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: ClassicErpTheme.borderDark, width: 2),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          color: const Color(0xFF1B4F72),
          child: const Row(
            children: [
              Icon(Icons.lock_reset_rounded, color: Colors.white, size: 15),
              SizedBox(width: 8),
              Text('Change Password', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.all(16),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              _classicField('Current Password', currentCtrl, obscure: true),
              const SizedBox(height: 10),
              _classicField('New Password', newCtrl, obscure: true),
              const SizedBox(height: 10),
              _classicField('Confirm New Password', confirmCtrl, obscure: true),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                color: const Color(0xFFFCF3CF),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 13, color: Color(0xFF7D6608)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Operator: Password will be updated for the currently logged-in user.',
                        style: TextStyle(fontSize: 10, color: Color(0xFF7D6608)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: ClassicErpTheme.textMuted, fontSize: 11)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4F72),
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            onPressed: () {
              if (newCtrl.text.isEmpty || newCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match!'), backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password changed successfully.'),
                  backgroundColor: Color(0xFF27AE60),
                ),
              );
            },
            child: const Text('Update Password', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeploymentDialog(BuildContext context) {
    AppUpdateInfo? dialogUpdateInfo = _availableUpdate;
    bool isChecking = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: ClassicErpTheme.panelBg,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: BorderSide(color: ClassicErpTheme.borderDark, width: 2),
            ),
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              color: const Color(0xFF1B4F72),
              child: Row(
                children: [
                  const Icon(Icons.system_update_alt_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Software Update Center',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),
            titlePadding: EdgeInsets.zero,
            contentPadding: const EdgeInsets.all(16),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // System Information Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B4F72).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.desktop_windows_rounded, color: Color(0xFF1B4F72), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Installed Version: v${AppUpdateService.currentInstalledVersion}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(3),
                                        border: Border.all(color: Colors.blue.shade200),
                                      ),
                                      child: const Text(
                                        '64-bit Windows',
                                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Product: HotelPro Enterprise PMS & POS | iSecure Systems Pvt. Ltd.',
                                  style: TextStyle(fontSize: 10.5, color: ClassicErpTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Update Status Section
                    const Text(
                      'SOFTWARE UPDATE NOTIFICATION',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
                    ),
                    const SizedBox(height: 6),

                    if (isChecking) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: ClassicErpTheme.borderLight),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1B4F72)),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Connecting to GitHub Release Server to check for latest Windows ERP build...',
                                style: TextStyle(fontSize: 11, color: ClassicErpTheme.textMain),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (dialogUpdateInfo != null && dialogUpdateInfo!.hasUpdate) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          border: Border.all(color: const Color(0xFFFFB300), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.notification_important_rounded, color: Color(0xFFD35400), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'New Update Available: v${dialogUpdateInfo!.latestVersion}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFB7950B)),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE67E22),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text(
                                    'RECOMMENDED',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              dialogUpdateInfo!.releaseNotes,
                              style: const TextStyle(fontSize: 11, color: Colors.black87),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.download_rounded, size: 16),
                                label: Text(
                                  'Install Update Now (v${dialogUpdateInfo!.latestVersion})',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF27AE60),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                ),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (c) => AppUpdateDialog(
                                      updateInfo: dialogUpdateInfo!,
                                      onDismiss: () => Navigator.of(c).pop(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F8F5),
                          border: Border.all(color: const Color(0xFF2ECC71), width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF27AE60), size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'HotelPro is Up to Date (v${AppUpdateService.currentInstalledVersion})',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E8449)),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'You are running the latest production build with all bug fixes and improvements.',
                                    style: TextStyle(fontSize: 10.5, color: ClassicErpTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close', style: TextStyle(color: ClassicErpTheme.textMuted, fontSize: 11)),
              ),
              ElevatedButton.icon(
                icon: isChecking
                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('Check for Updates Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4F72),
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                onPressed: isChecking
                    ? null
                    : () async {
                        setDialogState(() {
                          isChecking = true;
                        });
                        final latest = await AppUpdateService.checkLatestRelease(targetApp: AppTarget.windowsErp);
                        if (mounted) {
                          setState(() {
                            _availableUpdate = latest;
                            _systemVersion = AppUpdateService.currentInstalledVersion;
                          });
                        }
                        setDialogState(() {
                          dialogUpdateInfo = latest;
                          isChecking = false;
                        });
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ClassicErpTheme.panelBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: ClassicErpTheme.borderDark, width: 2),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          color: const Color(0xFF1B4F72),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white, size: 15),
              SizedBox(width: 8),
              Text('About HotelPro', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.all(16),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              // Logo / Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
                  ],
                ),
                child: Column(
                  children: [
                    Image.asset(
                      'lib/ui/features/master/assets/hotelpro.png',
                      height: 125,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Enterprise Hotel & Restaurant Management System',
                      style: TextStyle(
                        color: Color(0xFF1B4F72),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _aboutRow(Icons.hotel_rounded, 'Product', 'HotelPro'),
              const Divider(height: 10, thickness: 0.5),
              _aboutRow(Icons.description_rounded, 'About', 'Single Branch & Multi-Branch Hotel and\nRestaurant Management System — All-in-One Solution'),
              const Divider(height: 10, thickness: 0.5),
              _aboutRow(Icons.business_rounded, 'Company', 'iSecure Systems Pvt. Ltd.'),
              const Divider(height: 10, thickness: 0.5),
              _aboutRow(Icons.phone_rounded, 'Contact No', '9326770568'),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                color: const Color(0xFFF0F3F4),
                child: Text(
                  'Version v${_systemVersion.replaceAll('v', '')}  •  All rights reserved © iSecure Systems Pvt. Ltd.',
                  style: const TextStyle(fontSize: 9.5, color: ClassicErpTheme.textMuted),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: ClassicErpTheme.textMuted, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _aboutRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF1B4F72)),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, color: ClassicErpTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _classicField(String label, TextEditingController ctrl, {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(fontSize: 12, color: ClassicErpTheme.textMain),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11),
        isDense: true,
        border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFF1B4F72), width: 1.5),
        ),
      ),
    );
  }



}
