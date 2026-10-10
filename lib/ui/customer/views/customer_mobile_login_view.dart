import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/repositories/hotel_repository.dart';
import '../../../data/services/hotel_config_storage.dart';
import '../../../data/services/hotel_sync_bridge_service.dart';
import '../../core/components/hotel_logo_widget.dart';
import 'customer_auth_view.dart';

class CustomerMobileLoginView extends StatefulWidget {
  final VoidCallback onContinueAsGuest;
  final VoidCallback? onBackToErp;

  const CustomerMobileLoginView({
    super.key,
    required this.onContinueAsGuest,
    this.onBackToErp,
  });

  @override
  State<CustomerMobileLoginView> createState() => _CustomerMobileLoginViewState();
}

class _CustomerMobileLoginViewState extends State<CustomerMobileLoginView> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePin = true;
  bool _isLoading = false;
  bool _rememberCredentials = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedCustomerCredentials();
  }

  Future<void> _loadSavedCustomerCredentials() async {
    try {
      final saved = await HotelConfigStorage.loadSavedCredentials('customer');
      if (saved != null && saved['remember'] == true) {
        if (mounted) {
          setState(() {
            _phoneController.text = saved['userId'] ?? '';
            _passwordController.text = saved['password'] ?? '';
            _rememberCredentials = true;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _loginWithProfile(CustomerModel customer) {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = context.read<HotelRepository>();
    repo.setCustomer(customer);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Welcome back, ${customer.name}! (Wallet: ₹${customer.walletBalance.toStringAsFixed(0)})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E8449),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handlePhoneLogin() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.isEmpty || phone.replaceAll(RegExp(r'\D'), '').length < 10) {
      setState(() => _errorMessage = 'Please enter a valid 10-digit mobile number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Save or clear credentials based on checkbox
    await HotelConfigStorage.saveSavedCredentials(
      'customer',
      userId: phone,
      password: password,
      remember: _rememberCredentials,
    );

    final cleanDigits = phone.replaceAll(RegExp(r'\D'), '');
    final customer = CustomerModel(
      id: 'cust-usr-$cleanDigits',
      name: 'Guest ($phone)',
      phone: '+91 $phone',
      email: 'user.$cleanDigits@hotelpro.com',
      password: password.isNotEmpty ? password : 'pass',
      walletBalance: 200.0,
      joinedDate: DateTime.now(),
      addresses: const [
        CustomerAddressModel(
          id: 'addr-default',
          label: 'Current Location',
          fullAddress: 'Local Address / In-Hotel Delivery',
          city: 'Local City',
          pincode: '400001',
          latitude: 19.1136,
          longitude: 72.8697,
          distanceKmFromHotel: 2.0,
          isWithin10Km: true,
        ),
      ],
    );

    _loginWithProfile(customer);
  }

  void _showServerConfigDialog(BuildContext context) {
    final sync = HotelSyncBridgeService.instance;
    final hostCtrl = TextEditingController(text: sync.configuredServerHost);
    bool testing = false;
    String? testResult;
    bool? testSuccess;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: const [
                Icon(Icons.lan_rounded, color: Color(0xFFE23744), size: 22),
                SizedBox(width: 8),
                Text(
                  'Windows ERP Connection',
                  style: TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cloud_done_rounded, color: Colors.green.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HotelPro Project Database',
                              style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                            Text(
                              sync.isCloudConnected
                                  ? '🟢 Auto-Connected (Live Real-Time Sync)'
                                  : '🔴 Offline',
                              style: TextStyle(color: Colors.green.shade800, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'Local Hotel Wi-Fi Connection (Windows PC Server):',
                  style: TextStyle(color: Color(0xFF1E293B), fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: hostCtrl,
                  style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Windows PC Host / IP Address',
                    labelStyle: const TextStyle(fontSize: 12),
                    hintText: 'e.g. 192.168.0.100',
                    prefixIcon: const Icon(Icons.computer_rounded, color: Color(0xFFE23744), size: 20),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE23744), width: 1.5),
                    ),
                  ),
                ),
                if (testResult != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (testSuccess ?? false) ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (testSuccess ?? false) ? Colors.green.shade300 : Colors.red.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          (testSuccess ?? false) ? Icons.check_circle_rounded : Icons.error_rounded,
                          size: 16,
                          color: (testSuccess ?? false) ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            testResult!,
                            style: TextStyle(
                              color: (testSuccess ?? false) ? Colors.green.shade900 : Colors.red.shade900,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: testing
                    ? null
                    : () async {
                        setDlgState(() {
                          testing = true;
                          testResult = 'Pinging Windows ERP server...';
                          testSuccess = null;
                        });
                        final target = hostCtrl.text.trim();
                        final ok = await sync.testConnectionToHost(target);
                        setDlgState(() {
                          testing = false;
                          testSuccess = ok;
                          testResult = ok
                              ? 'Connected successfully to Windows ERP at $target:8088!'
                              : 'Could not connect to $target:8088. Check Wi-Fi & PC.';
                        });
                      },
                child: testing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE23744)),
                      )
                    : const Text('Test Ping', style: TextStyle(color: Color(0xFFE23744), fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE23744),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  final target = hostCtrl.text.trim();
                  if (target.isNotEmpty) {
                    sync.setConfiguredHost(target);
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Windows ERP Host set to $target:8088'),
                      backgroundColor: const Color(0xFF1E8449),
                    ),
                  );
                },
                child: const Text('Save & Connect', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<HotelRepository>(context);
    final hotelName = repo.clientBusinessName.isNotEmpty ? repo.clientBusinessName : 'The Grand Imperial Palace';
    final hotelTagline = repo.clientTagline.isNotEmpty ? repo.clientTagline : 'Luxury Hotel, Suites & Fine Dining';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Top Bar with Return to ERP Button ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE23744).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${hotelName.toUpperCase()} GUEST PORTAL',
                        style: const TextStyle(color: Color(0xFFE23744), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Brand Hero Card ──
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE23744), Color(0xFFB71C1C), Color(0xFF880E4F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE23744).withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amber.shade300, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const ClipOval(
                        child: HotelLogoWidget(
                          width: 76,
                          height: 76,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      hotelName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hotelTagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars_rounded, color: Colors.amberAccent, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Earn 5% Wallet Cashback on Every Order',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Windows ERP Connection Card ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: AnimatedBuilder(
                  animation: HotelSyncBridgeService.instance,
                  builder: (context, _) {
                    final sync = HotelSyncBridgeService.instance;
                    final isConnected = sync.isAutoConnected;
                    return Container(
                      decoration: BoxDecoration(
                        color: isConnected ? Colors.green.shade50 : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isConnected ? Colors.green.shade300 : Colors.amber.shade300,
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showServerConfigDialog(context),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Icon(
                                  isConnected ? Icons.cloud_done_rounded : Icons.cloud_sync_rounded,
                                  color: isConnected ? Colors.green.shade700 : Colors.amber.shade800,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sync.connectionTitle,
                                        style: TextStyle(
                                          color: isConnected ? Colors.green.shade900 : Colors.amber.shade900,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        sync.connectionStatusSubtitle,
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 10.5),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isConnected ? Colors.green.shade100 : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isConnected ? Colors.green.shade400 : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    isConnected ? 'Connected' : 'Setup IP',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: isConnected ? Colors.green.shade900 : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // ── Phone / Mobile Manual Login Card ──
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.phone_iphone_rounded, color: Color(0xFFE23744), size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Sign In with Mobile',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        prefixIcon: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          child: const Text('+91', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)),
                        ),
                        hintText: 'Enter 10-digit mobile number',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12.5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE23744), width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePin,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.grey, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 18),
                          onPressed: () => setState(() => _obscurePin = !_obscurePin),
                        ),
                        hintText: 'Password / 4-Digit PIN (Optional)',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12.5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE23744), width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ── Save Mobile & Password Checkbox ──
                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _rememberCredentials,
                            onChanged: (val) => setState(() => _rememberCredentials = val ?? false),
                            activeColor: const Color(0xFFE23744),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _rememberCredentials = !_rememberCredentials),
                            child: const Text(
                              'Save Mobile & Password on this device',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],

                    const SizedBox(height: 14),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _handlePhoneLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE23744),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('CONTINUE TO DINING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => CustomerAuthView(
                              onLoginSuccess: () {},
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.password_rounded, size: 15, color: Color(0xFF4A5568)),
                      label: const Text('Password / Full Registration', style: TextStyle(color: Color(0xFF4A5568), fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Continue as Guest Option ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextButton.icon(
                  onPressed: widget.onContinueAsGuest,
                  icon: const Icon(Icons.explore_rounded, color: Color(0xFF1B4F72), size: 18),
                  label: const Text(
                    'Explore Restaurant Menu as Guest',
                    style: TextStyle(
                      color: Color(0xFF1B4F72),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
