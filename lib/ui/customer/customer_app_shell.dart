import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/hotel_repository.dart';
import 'views/customer_food_home_view.dart';
import 'views/customer_cart_checkout_view.dart';
import 'views/customer_dining_view.dart';
import 'views/customer_rooms_view.dart';
import 'views/customer_orders_history_view.dart';
import 'views/customer_auth_view.dart';
import '../../data/services/app_update_service.dart';

class CustomerAppShell extends StatefulWidget {
  final VoidCallback? onSwitchToErp;

  const CustomerAppShell({
    super.key,
    this.onSwitchToErp,
  });

  @override
  State<CustomerAppShell> createState() => _CustomerAppShellState();
}

class _CustomerAppShellState extends State<CustomerAppShell> {
  int _activeTabIndex = 0;
  bool _isCartOpen = false;
  bool _isDesktopMobileFrame = true; // Toggle for simulated Android phone bezel on desktop
  bool _isGuestBrowsing = true; // Guest entry allowed by default

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdateService.checkAndPrompt(context, targetApp: AppTarget.customerDining, silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final cartCount = repo.customerCartCount;
    final isAuth = repo.isCustomerLoggedIn;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 650;

        Widget appContent;

        if (!isAuth && !_isGuestBrowsing) {
          appContent = CustomerAuthView(
            onLoginSuccess: () => setState(() {}),
            onContinueAsGuest: () => setState(() => _isGuestBrowsing = true),
            onBackToErp: widget.onSwitchToErp,
          );
        } else {
          appContent = Scaffold(
            body: _isCartOpen
                ? CustomerCartCheckoutView(
                    onBackToMenu: () => setState(() => _isCartOpen = false),
                  )
                : IndexedStack(
                    index: _activeTabIndex.clamp(0, 3),
                    children: [
                      CustomerFoodHomeView(
                        onOpenCart: () => setState(() => _isCartOpen = true),
                      ),
                      const CustomerDiningView(),
                      const CustomerRoomsView(),
                      CustomerOrdersHistoryView(
                        onRequestLogin: () => setState(() => _isGuestBrowsing = false),
                      ),
                    ],
                  ),
            bottomNavigationBar: _isCartOpen
                ? null
                : BottomNavigationBar(
                    currentIndex: _activeTabIndex,
                    onTap: (idx) {
                      setState(() {
                        _activeTabIndex = idx;
                        _isCartOpen = false;
                      });
                    },
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: const Color(0xFFE23744), // Zomato Red
                  unselectedItemColor: Colors.grey.shade600,
                  selectedFontSize: 11,
                  unselectedFontSize: 10,
                  elevation: 8,
                  backgroundColor: Colors.white,
                  items: [
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.delivery_dining_rounded),
                      activeIcon: Icon(Icons.delivery_dining_rounded, color: Color(0xFFE23744)),
                      label: 'Food Delivery',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.table_restaurant_rounded),
                      label: 'Dine-In & Hall',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.hotel_rounded),
                      label: 'Book Room',
                    ),
                    BottomNavigationBarItem(
                      icon: Badge(
                        isLabelVisible: cartCount > 0 && _activeTabIndex != 3,
                        label: Text('$cartCount'),
                        child: const Icon(Icons.receipt_long_rounded),
                      ),
                      label: 'My Orders',
                    ),
                  ],
                ),
          );
        }

        // On mobile devices (Android Emulator / Phone) or when running as pure standalone app:
        if (!isWideScreen || widget.onSwitchToErp == null || !_isDesktopMobileFrame) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
              systemNavigationBarColor: Colors.white,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
            child: appContent,
          );
        }

        // On desktop, render a beautiful simulated Android phone frame
        return Scaffold(
          backgroundColor: const Color(0xFF1C2833), // Elegant dark slate backdrop
          body: SafeArea(
            child: Column(
              children: [
                _buildTopErpSwitchBanner(),
                Expanded(
                  child: Center(
                    child: Container(
                      width: 412, // Standard Android viewport width (Google Pixel / Samsung Galaxy)
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: const Color(0xFF4A5568), width: 3),
                        boxShadow: const [
                          BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, 10)),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          // Android Status Bar & Punch-hole Camera
                          Container(
                            height: 28,
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '9:41',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                // Front Camera Punch-hole
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                                ),
                                const Row(
                                  children: [
                                    Icon(Icons.wifi, size: 12, color: Colors.black87),
                                    SizedBox(width: 4),
                                    Icon(Icons.signal_cellular_4_bar_rounded, size: 12, color: Colors.black87),
                                    SizedBox(width: 4),
                                    Icon(Icons.battery_full_rounded, size: 13, color: Colors.black87),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(child: appContent),
                          // Android Navigation Pill Bar
                          Container(
                            height: 16,
                            color: Colors.white,
                            alignment: Alignment.center,
                            child: Container(
                              width: 120,
                              height: 4,
                              decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopErpSwitchBanner() {
    return Material(
      color: const Color(0xFF0C2461), // Classic Navy
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.phone_android_rounded, color: Colors.amber, size: 15),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'HotelPro Customer Android App (Zomato-Style)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _isDesktopMobileFrame = !_isDesktopMobileFrame),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3799),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_isDesktopMobileFrame ? Icons.fullscreen_rounded : Icons.phone_iphone_rounded, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(_isDesktopMobileFrame ? 'Full Window' : 'Phone Frame', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.onSwitchToErp,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE23744),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.desktop_windows_rounded, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text('Return to ERP', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
