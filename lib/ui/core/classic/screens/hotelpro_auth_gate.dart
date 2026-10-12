import 'dart:async';
import 'dart:io' show exit;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../config/classic_erp_theme.dart';
import '../../../../data/repositories/hotel_repository.dart';
import '../classic_erp_shell.dart';
import '../../../../data/services/app_update_service.dart';

// =============================================================================
// HotelProDesktopAuthGate
// Manages the Windows launch sequence:
// 1. About HotelPro Welcome Splash Screen (5 seconds auto-close)
// 2. Operator Authentication & Login Screen (Mandatory to enter dashboard)
// 3. Classic ERP Shell (Dashboard)
// =============================================================================

class HotelProDesktopAuthGate extends StatefulWidget {
  const HotelProDesktopAuthGate({super.key});

  @override
  State<HotelProDesktopAuthGate> createState() => _HotelProDesktopAuthGateState();
}

class _HotelProDesktopAuthGateState extends State<HotelProDesktopAuthGate> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdateService.checkAndPrompt(context, targetApp: AppTarget.windowsErp, silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();

    if (_showSplash) {
      return HotelProAboutSplashScreen(
        onFinished: () {
          if (mounted) {
            setState(() => _showSplash = false);
          }
        },
      );
    }

    if (!repo.isErpLoggedIn) {
      return const HotelProLoginScreen();
    }

    return const ClassicErpShell();
  }
}

// =============================================================================
// 1. HotelProAboutSplashScreen — 5 Seconds Auto-Closing Splash Screen
// =============================================================================

class HotelProAboutSplashScreen extends StatefulWidget {
  final VoidCallback onFinished;
  final int durationSeconds;

  const HotelProAboutSplashScreen({
    super.key,
    required this.onFinished,
    this.durationSeconds = 5,
  });

  @override
  State<HotelProAboutSplashScreen> createState() => _HotelProAboutSplashScreenState();
}

class _HotelProAboutSplashScreenState extends State<HotelProAboutSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  Timer? _countdownTimer;
  int _secondsRemaining = 5;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.durationSeconds;

    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationSeconds),
    )..forward();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsRemaining--;
      });
      if (_secondsRemaining <= 0) {
        timer.cancel();
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
             event.logicalKey == LogicalKeyboardKey.space ||
             event.logicalKey == LogicalKeyboardKey.escape)) {
          widget.onFinished();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F2027),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Container(
              width: 540,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF1B4F72), width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Title Bar ──────────────────────────────────────────
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0C2461), Color(0xFF1B4F72)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          'lib/ui/features/master/assets/hotelpro.png',
                          height: 18,
                          width: 18,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'About Hotelpro — Hotelpro Management System',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            'Auto-close in ${_secondsRemaining}s',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Main Body Card ─────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Prominent Logo Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFD5DBDB), width: 1),
                          ),
                          child: Column(
                            children: [
                              Image.asset(
                                'lib/ui/features/master/assets/hotelpro.png',
                                height: 130,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Enterprise Hotel & Restaurant Management System',
                                style: TextStyle(
                                  color: Color(0xFF1B4F72),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // System Info Rows
                        _infoItem(
                          icon: Icons.verified_rounded,
                          label: 'Product Name',
                          value: 'Hotelpro',
                          isHighlight: true,
                        ),
                        const Divider(height: 12, thickness: 0.5),

                        _infoItem(
                          icon: Icons.business_center_rounded,
                          label: 'Work',
                          value:
                              'single branch, multibranch Hotel and Restrorants management system all in one solution',
                        ),
                        const Divider(height: 12, thickness: 0.5),

                        _infoItem(
                          icon: Icons.apartment_rounded,
                          label: 'Company',
                          value: 'iSecure Systems Pvt. Ltd.',
                        ),
                        const Divider(height: 12, thickness: 0.5),

                        _infoItem(
                          icon: Icons.phone_in_talk_rounded,
                          label: 'Contact No',
                          value: '9326770568',
                          isPhone: true,
                        ),

                        const SizedBox(height: 16),

                        // Animated Progress Bar (0 to 5 seconds)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Initializing HotelPro ERP Engine & Services...',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: ClassicErpTheme.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Login in ${_secondsRemaining}s',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xFF1B4F72),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            AnimatedBuilder(
                              animation: _progressController,
                              builder: (context, child) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: _progressController.value,
                                    minHeight: 6,
                                    backgroundColor: const Color(0xFFE2E8F0),
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      Color(0xFF2E86C1),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Bottom Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Version 2.4.1  •  © iSecure Systems Pvt. Ltd.',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: ClassicErpTheme.textMuted,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: widget.onFinished,
                              icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                              label: const Text('Proceed to Login [Enter]'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B4F72),
                                foregroundColor: Colors.white,
                                elevation: 1,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                textStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoItem({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlight = false,
    bool isPhone = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF1B4F72)),
        const SizedBox(width: 10),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
        ),
        const Text(': ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isHighlight || isPhone ? FontWeight.bold : FontWeight.w500,
              color: isHighlight
                  ? const Color(0xFF0C2461)
                  : isPhone
                      ? const Color(0xFF27AE60)
                      : const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 2. HotelProLoginScreen — Mandatory Operator Authentication Screen
// User cannot enter the ERP dashboard without successful credentials.
// =============================================================================

class HotelProLoginScreen extends StatefulWidget {
  const HotelProLoginScreen({super.key});

  @override
  State<HotelProLoginScreen> createState() => _HotelProLoginScreenState();
}

class _HotelProLoginScreenState extends State<HotelProLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin(HotelRepository repo) {
    final user = _usernameController.text.trim();
    final pass = _passwordController.text.trim();

    if (user.isEmpty) {
      setState(() => _errorMessage = 'Please enter operator username.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = repo.authenticateUser(user, pass);
    setState(() => _isLoading = false);

    if (!success) {
      setState(() {
        _errorMessage = 'Invalid username or password credentials. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();

    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Container(
            width: 520,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF1B4F72), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Win32 Header ─────────────────────────────────────────
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0C2461), Color(0xFF1B4F72)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'lib/ui/features/master/assets/hotelpro.png',
                        height: 18,
                        width: 18,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Hotelpro Management System — System Authentication',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Exit HotelPro ERP',
                        child: InkWell(
                          onTap: () => exit(0),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            color: Colors.red.shade700,
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Login Form Body ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Logo & Greeting
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Image.asset(
                              'lib/ui/features/master/assets/hotelpro.png',
                              height: 48,
                              width: 48,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hotelpro Management System',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Single & Multi-Branch Enterprise ERP — Operator Sign In',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: ClassicErpTheme.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Error message banner
                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            border: Border.all(color: const Color(0xFFEF4444)),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFB91C1C)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFB91C1C),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Username Input
                      const Text(
                        'Operator ID / Username:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFF94A3B8), width: 1),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF64748B)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _usernameController,
                                style: const TextStyle(fontSize: 12),
                                decoration: const InputDecoration(
                                  hintText: 'Enter operator username',
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                                ),
                                onSubmitted: (_) => _submitLogin(repo),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Password Input
                      const Text(
                        'Security Password:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFF94A3B8), width: 1),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            const Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF64748B)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(fontSize: 12),
                                decoration: const InputDecoration(
                                  hintText: 'Enter password',
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                                ),
                                onSubmitted: (_) => _submitLogin(repo),
                              ),
                            ),
                            InkWell(
                              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                child: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  size: 16,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Submit Login & Exit Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : () => _submitLogin(repo),
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.login_rounded, size: 16),
                              label: const Text('Log In to Dashboard [Enter]'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B4F72),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                elevation: 1,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => exit(0),
                            icon: const Icon(Icons.power_settings_new_rounded, size: 14, color: Colors.red),
                            label: const Text('Exit', style: TextStyle(color: Colors.red, fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red, width: 0.8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
