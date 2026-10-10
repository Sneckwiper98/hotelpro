import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/hotel_repository.dart';
import '../../../data/services/geofence_service.dart';
import '../../../data/services/hotel_config_storage.dart';

class CustomerAuthView extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const CustomerAuthView({
    super.key,
    required this.onLoginSuccess,
  });

  @override
  State<CustomerAuthView> createState() => _CustomerAuthViewState();
}

enum AuthTab { signIn, register }
enum LoginMethod { smsOtp, emailOtp, password }

class _CustomerAuthViewState extends State<CustomerAuthView> {
  AuthTab _activeTab = AuthTab.signIn;
  LoginMethod _loginMethod = LoginMethod.smsOtp;

  bool _obscurePassword = true;

  // Login inputs
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _rememberCredentials = true;

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
            _phoneCtrl.text = saved['userId'] ?? '';
            _passwordCtrl.text = saved['password'] ?? '';
            _rememberCredentials = true;
          });
        }
      }
    } catch (_) {}
  }

  // Registration inputs
  final _regNameCtrl = TextEditingController();
  final _regPhoneCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regAddressCtrl = TextEditingController();
  final _regLandmarkCtrl = TextEditingController();
  final _regPasswordCtrl = TextEditingController();
  final _regConfirmPasswordCtrl = TextEditingController();

  String _selectedAddressType = 'Home'; // Home, Work, Hotel, Other
  double _detectedLat = 19.1136;
  double _detectedLng = 72.8697;
  double _detectedDistanceKm = 2.8;
  bool _isLocationDetected = false;
  bool _isDetectingLocation = false;

  // OTP State
  bool _isOtpSent = false;
  String? _simulatedBannerMessage;
  String? _simulatedBannerChannel; // 'SMS' or 'Email'
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _otpCtrl.dispose();
    _regNameCtrl.dispose();
    _regPhoneCtrl.dispose();
    _regEmailCtrl.dispose();
    _regAddressCtrl.dispose();
    _regLandmarkCtrl.dispose();
    _regPasswordCtrl.dispose();
    _regConfirmPasswordCtrl.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _resendCountdown = 30;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _handleSendOtp(HotelRepository repo, {required bool isSms}) async {
    final destination = isSms ? _phoneCtrl.text.trim() : _emailCtrl.text.trim();
    if (destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isSms ? 'Please enter a valid mobile number.' : 'Please enter a valid email address.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    String code;
    if (isSms) {
      code = await repo.sendSmsOtp(destination);
    } else {
      code = await repo.sendEmailOtp(destination);
    }

    setState(() {
      _isOtpSent = true;
      _simulatedBannerChannel = isSms ? 'SMS' : 'Email';
      _simulatedBannerMessage = isSms
          ? '📲 SMS from HotelPro: Your One-Time Password is $code'
          : '📬 Email from HotelPro: Your login verification code is $code';
    });

    _startCountdown();
  }

  void _verifyAndLogin(HotelRepository repo) {
    final otp = _otpCtrl.text.trim();
    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit OTP code.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (repo.verifyOtp(otp)) {
      final identifier = _loginMethod == LoginMethod.smsOtp ? _phoneCtrl.text.trim() : _emailCtrl.text.trim();
      repo.loginCustomer(identifier, 'pass123');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 OTP Verified! Welcome, ${repo.currentCustomer?.name ?? "Customer"}!'),
          backgroundColor: Colors.green.shade800,
        ),
      );
      widget.onLoginSuccess();
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP code. Please enter 123456.'), backgroundColor: Colors.red),
      );
    }
  }

  void _detectCurrentLocation(HotelRepository repo) async {
    setState(() => _isDetectingLocation = true);
    await Future.delayed(const Duration(milliseconds: 600));

    final branchCode = repo.activeBranch.code;
    final locations = GeofenceService.getDemoDeliveryLocations(branchCode);
    final nearby = locations.isNotEmpty ? locations.first : null;

    if (nearby != null && mounted) {
      final lat = nearby['lat'] as double;
      final lng = nearby['lng'] as double;
      final dist = GeofenceService.getDistanceForBranch(
        branchCode: branchCode,
        customerLat: lat,
        customerLng: lng,
      );

      setState(() {
        _detectedLat = lat;
        _detectedLng = lng;
        _detectedDistanceKm = dist;
        _isLocationDetected = true;
        _isDetectingLocation = false;
        if (_regAddressCtrl.text.isEmpty) {
          _regAddressCtrl.text = '${nearby['address']}';
          _regLandmarkCtrl.text = '${nearby['landmark']}';
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 Location Detected: $dist km from ${repo.activeBranch.name}'),
          backgroundColor: dist <= 10.0 ? Colors.green.shade800 : Colors.red.shade800,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final branch = repo.activeBranch;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _activeTab == AuthTab.signIn ? 'Sign In' : 'Create Account',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Simulated Notification Banner (Instant OTP Alert) ────────
            if (_simulatedBannerMessage != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _simulatedBannerChannel == 'SMS'
                        ? [const Color(0xFF1E88E5), const Color(0xFF1565C0)]
                        : [const Color(0xFF43A047), const Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _simulatedBannerChannel == 'SMS' ? Icons.sms_rounded : Icons.email_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _simulatedBannerMessage!,
                            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Click button to auto-fill code',
                            style: TextStyle(color: Colors.white70, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _otpCtrl.text = '123456';
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('⚡ OTP Auto-Filled: 123456'),
                            backgroundColor: Colors.black87,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Auto-Fill', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],

            // ── Hero Brand Header ──────────────────────────────────────────
            Center(
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE23744), Color(0xFFB01D28)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE23744).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 38),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                branch.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: Color(0xFF1B4F72)),
              ),
            ),
            const Center(
              child: Text(
                'Premium 5-Star Food Delivery & Table Dining',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 18),

            // ── Primary Switcher: Sign In vs Create Account ─────────────────
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _activeTab = AuthTab.signIn;
                        _isOtpSent = false;
                        _simulatedBannerMessage = null;
                      }),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _activeTab == AuthTab.signIn ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: _activeTab == AuthTab.signIn
                              ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
                              : null,
                        ),
                        child: Text(
                          '🔑 Sign In',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _activeTab == AuthTab.signIn ? const Color(0xFFE23744) : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _activeTab = AuthTab.register;
                        _isOtpSent = false;
                        _simulatedBannerMessage = null;
                      }),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _activeTab == AuthTab.register ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: _activeTab == AuthTab.register
                              ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
                              : null,
                        ),
                        child: Text(
                          '📝 Create Account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _activeTab == AuthTab.register ? const Color(0xFFE23744) : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Content ────────────────────────────────────────────────────
            if (_activeTab == AuthTab.signIn)
              _buildSignInSection(context, repo)
            else
              _buildRegisterSection(context, repo),

            const SizedBox(height: 20),
            _buildISecureFooter(),
          ],
        ),
      ),
    );
  }

  // ── Sign In Section ──────────────────────────────────────────────────────
  Widget _buildSignInSection(BuildContext context, HotelRepository repo) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sub-Tab Switcher: SMS OTP, Email OTP, Password
          Row(
            children: [
              _buildMethodChip(
                label: '📱 SMS OTP',
                method: LoginMethod.smsOtp,
              ),
              const SizedBox(width: 8),
              _buildMethodChip(
                label: '📧 Email OTP',
                method: LoginMethod.emailOtp,
              ),
              const SizedBox(width: 8),
              _buildMethodChip(
                label: '🔒 Password',
                method: LoginMethod.password,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Flow 1: SMS OTP ──
          if (_loginMethod == LoginMethod.smsOtp) ...[
            const Text('Mobile Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
            const SizedBox(height: 6),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Text('🇮🇳 +91', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE23744), width: 1.5)),
                hintText: '9876543210',
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFFAFAFA),
              ),
            ),
            const SizedBox(height: 14),

            if (!_isOtpSent) ...[
              ElevatedButton(
                onPressed: () => _handleSendOtp(repo, isSms: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE23744),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sms_rounded, size: 16),
                    SizedBox(width: 8),
                    Text('GET OTP VIA SMS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ] else ...[
              _buildOtpInputCard(repo, isSms: true),
            ],
          ]

          // ── Flow 2: Email OTP ──
          else if (_loginMethod == LoginMethod.emailOtp) ...[
            const Text('Email Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
            const SizedBox(height: 6),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.email_rounded, color: Color(0xFFE23744), size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE23744), width: 1.5)),
                hintText: 'amit.sharma@example.com',
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFFAFAFA),
              ),
            ),
            const SizedBox(height: 14),

            if (!_isOtpSent) ...[
              ElevatedButton(
                onPressed: () => _handleSendOtp(repo, isSms: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE23744),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mark_email_read_rounded, size: 16),
                    SizedBox(width: 8),
                    Text('GET OTP VIA EMAIL', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ] else ...[
              _buildOtpInputCard(repo, isSms: false),
            ],
          ]

          // ── Flow 3: Password ──
          else ...[
            const Text('Mobile Number or Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
            const SizedBox(height: 6),
            TextField(
              controller: _phoneCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_rounded, color: Color(0xFFE23744), size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE23744), width: 1.5)),
                hintText: 'e.g. 9876543210',
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFFAFAFA),
              ),
            ),
            const SizedBox(height: 12),

            const Text('Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
            const SizedBox(height: 6),
            TextField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_rounded, color: Color(0xFFE23744), size: 18),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: Colors.grey),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE23744), width: 1.5)),
                hintText: 'Enter password',
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFFAFAFA),
              ),
            ),
            const SizedBox(height: 10),

            // ── Save ID & Password Checkbox ──
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
                      'Save ID & Password on this device',
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

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                final input = _phoneCtrl.text.trim();
                final pass = _passwordCtrl.text.trim();
                if (input.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter phone or email.')));
                  return;
                }

                // Save or clear credentials based on checkbox
                HotelConfigStorage.saveSavedCredentials(
                  'customer',
                  userId: input,
                  password: pass,
                  remember: _rememberCredentials,
                );

                repo.loginCustomer(input, pass);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Welcome back, ${repo.currentCustomer?.name ?? "Customer"}!'), backgroundColor: Colors.green.shade800),
                );
                widget.onLoginSuccess();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE23744),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('SIGN IN', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMethodChip({required String label, required LoginMethod method}) {
    final isSelected = _loginMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _loginMethod = method;
          _isOtpSent = false;
          _simulatedBannerMessage = null;
        }),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE23744).withValues(alpha: 0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFFE23744) : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFFE23744) : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpInputCard(HotelRepository repo, {required bool isSms}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Enter 6-Digit OTP',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
            ),
            Text(
              _resendCountdown > 0 ? 'Resend in ${_resendCountdown}s' : 'OTP Expired',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, letterSpacing: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
          decoration: InputDecoration(
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE23744))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE23744), width: 2)),
            hintText: '••••••',
            hintStyle: TextStyle(letterSpacing: 10, color: Colors.grey.shade300),
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
          ),
        ),
        const SizedBox(height: 14),

        ElevatedButton(
          onPressed: () => _verifyAndLogin(repo),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE23744),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 2,
          ),
          child: const Text('VERIFY & PROCEED', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 6),
        if (_resendCountdown == 0)
          TextButton(
            onPressed: () => _handleSendOtp(repo, isSms: isSms),
            child: const Text('Resend OTP Code', style: TextStyle(color: Color(0xFFE23744), fontWeight: FontWeight.bold, fontSize: 12)),
          ),
      ],
    );
  }

  // ── Registration Section ────────────────────────────────────────────────
  Widget _buildRegisterSection(BuildContext context, HotelRepository repo) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('New Customer Onboarding', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 4),
          const Text('Register to enjoy 5-star hotel dining & live delivery tracking', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 16),

          // 1. Name
          const Text('Full Name *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
          const SizedBox(height: 6),
          TextField(
            controller: _regNameCtrl,
            decoration: _fieldDeco('e.g. Rahul Sharma', Icons.person_rounded),
          ),
          const SizedBox(height: 12),

          // 2. Mobile
          const Text('Mobile Number (for SMS OTP & Delivery Calls) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
          const SizedBox(height: 6),
          TextField(
            controller: _regPhoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: _fieldDeco('+91 98201 XXXXX', Icons.phone_android_rounded),
          ),
          const SizedBox(height: 12),

          // 3. Email
          const Text('Email Address (for Digital Invoices) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
          const SizedBox(height: 6),
          TextField(
            controller: _regEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: _fieldDeco('rahul.sharma@example.com', Icons.email_rounded),
          ),
          const SizedBox(height: 14),

          // 4. Address Type
          const Text('Address Tag *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ('Home', '🏠 Home'),
              ('Work', '🏢 Office / Work'),
              ('Hotel', '🏨 Hotel Room'),
              ('Other', '📍 Other'),
            ].map((t) {
              final isSel = _selectedAddressType == t.$1;
              return ChoiceChip(
                label: Text(t.$2),
                selected: isSel,
                onSelected: (sel) {
                  if (sel) setState(() => _selectedAddressType = t.$1);
                },
                selectedColor: const Color(0xFFE23744),
                labelStyle: TextStyle(
                  color: isSel ? Colors.white : Colors.black87,
                  fontSize: 11,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isSel ? const Color(0xFFE23744) : Colors.grey.shade300),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // 5. Address + GPS Location
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Delivery Address *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
              GestureDetector(
                onTap: _isDetectingLocation ? null : () => _detectCurrentLocation(repo),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE23744).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE23744).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isDetectingLocation)
                        const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE23744)))
                      else
                        const Icon(Icons.my_location_rounded, size: 12, color: Color(0xFFE23744)),
                      const SizedBox(width: 4),
                      Text(
                        _isDetectingLocation ? 'Detecting...' : '📍 Detect GPS Location',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFE23744)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _regAddressCtrl,
            maxLines: 2,
            decoration: _fieldDeco('Flat/Room No, Building Name, Street', Icons.location_on_rounded),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _regLandmarkCtrl,
            decoration: _fieldDeco('Landmark (e.g. Near Metro Station / Park)', Icons.near_me_rounded),
          ),

          if (_isLocationDetected) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _detectedDistanceKm <= 10.0 ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _detectedDistanceKm <= 10.0 ? Colors.green.shade300 : Colors.red.shade300, width: 0.8),
              ),
              child: Row(
                children: [
                  Icon(
                    _detectedDistanceKm <= 10.0 ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    size: 14,
                    color: _detectedDistanceKm <= 10.0 ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$_detectedDistanceKm km from ${repo.activeBranch.name} • Within 10 km Delivery Zone ✓',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: _detectedDistanceKm <= 10.0 ? Colors.green.shade900 : Colors.red.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // 6. Password
          const Text('Account Password *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
          const SizedBox(height: 6),
          TextField(
            controller: _regPasswordCtrl,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_rounded, color: Color(0xFFE23744), size: 18),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: Colors.grey),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE23744), width: 1.5)),
              hintText: 'Minimum 6 characters',
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
            ),
          ),
          const SizedBox(height: 18),

          ElevatedButton(
            onPressed: () => _handleRegistrationSubmit(context, repo),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE23744),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.how_to_reg_rounded, size: 18),
                SizedBox(width: 8),
                Text('CREATE ACCOUNT & CONTINUE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleRegistrationSubmit(BuildContext context, HotelRepository repo) {
    final name = _regNameCtrl.text.trim();
    final phone = _regPhoneCtrl.text.trim();
    final email = _regEmailCtrl.text.trim();
    final address = _regAddressCtrl.text.trim();
    final landmark = _regLandmarkCtrl.text.trim();
    final pass = _regPasswordCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your full name.')));
      return;
    }
    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid 10-digit mobile number.')));
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid email address.')));
      return;
    }
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your delivery address.')));
      return;
    }
    if (pass.isEmpty || pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters.')));
      return;
    }

    final fullAddress = landmark.isNotEmpty ? '$address, Near $landmark' : address;

    repo.registerCustomer(
      name: name,
      phone: phone,
      email: email,
      addressText: fullAddress,
      addressType: _selectedAddressType,
      password: pass,
      lat: _detectedLat,
      lng: _detectedLng,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Welcome, $name! Account created successfully.'),
        backgroundColor: Colors.green.shade800,
      ),
    );

    widget.onLoginSuccess();
    Navigator.of(context).pop();
  }

  InputDecoration _fieldDeco(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFFE23744), size: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE23744), width: 1.5)),
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
    );
  }

  Widget _buildISecureFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF1B4F72),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.security_rounded, color: Colors.white, size: 12),
              ),
              const SizedBox(width: 8),
              const Text(
                'Secured by ',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const Text(
                'iSecure Systems OTP Gateway',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF1B4F72), fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'SMS & Email Instant OTP Delivery with 256-Bit Encryption',
            style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
