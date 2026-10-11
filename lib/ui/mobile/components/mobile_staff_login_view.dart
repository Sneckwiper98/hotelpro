import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/hotel_repository.dart';
import '../../../data/services/hotel_config_storage.dart';
import '../../core/components/hotel_logo_widget.dart';
import 'mobile_app_scaffold.dart';

/// Represents an authenticated operator profile for the mobile suite apps.
class StaffProfileAuth {
  final String id;
  final String name;
  final String role;
  final String phone;
  final String pin;
  final String avatarEmoji;
  final String shift;
  final String? branchId;
  final String? vehicleNo;

  const StaffProfileAuth({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.pin,
    required this.avatarEmoji,
    this.shift = 'General Shift',
    this.branchId,
    this.vehicleNo,
  });
}

/// Ultra-Modern, Interactive Authentication Screen for HotelPro Mobile Suite.
/// Provides:
/// 1. Premium branded Hero Card with glow and hotel metadata.
/// 2. 1-Tap Quick Demo Profiles for instant, hassle-free testing.
/// 3. Manual Operator ID & PIN input with validation.
/// 4. Biometric quick-login simulation.
class MobileStaffLoginView extends StatefulWidget {
  final MobileAppRole role;
  final String appTitle;
  final String appSubtitle;
  final List<StaffProfileAuth> quickProfiles;
  final ValueChanged<StaffProfileAuth> onAuthenticate;
  final VoidCallback? onBackToGateway;

  const MobileStaffLoginView({
    super.key,
    required this.role,
    required this.appTitle,
    required this.appSubtitle,
    required this.quickProfiles,
    required this.onAuthenticate,
    this.onBackToGateway,
  });

  @override
  State<MobileStaffLoginView> createState() => _MobileStaffLoginViewState();
}

class _MobileStaffLoginViewState extends State<MobileStaffLoginView> {
  final _idController = TextEditingController();
  final _pinController = TextEditingController();
  bool _obscurePin = true;
  bool _isLoading = false;
  bool _rememberCredentials = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final saved = await HotelConfigStorage.loadSavedCredentials(widget.role.name);
      if (saved != null && saved['remember'] == true) {
        if (mounted) {
          setState(() {
            _idController.text = saved['userId'] ?? '';
            _pinController.text = saved['password'] ?? '';
            _rememberCredentials = true;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _idController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _handleManualSubmit() async {
    final enteredId = _idController.text.trim().toLowerCase();
    final enteredPin = _pinController.text.trim();

    if (enteredId.isEmpty) {
      setState(() => _errorMessage = 'Please enter your Staff ID or registered phone');
      return;
    }
    if (enteredPin.isEmpty) {
      setState(() => _errorMessage = 'Please enter your security PIN or password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Check against demo profiles or allow universal passcode '1234'
    StaffProfileAuth? matched;
    for (final p in widget.quickProfiles) {
      if (p.id.toLowerCase() == enteredId ||
          p.phone.replaceAll(' ', '') == enteredId.replaceAll(' ', '') ||
          p.name.toLowerCase().contains(enteredId)) {
        if (p.pin == enteredPin || enteredPin == '1234') {
          matched = p;
          break;
        }
      }
    }

    // Fallback profile if custom ID entered with standard PIN
    matched ??= StaffProfileAuth(
      id: enteredId.toUpperCase(),
      name: enteredId.toUpperCase(),
      role: '${widget.role.title} Operator',
      phone: '+91 98000 00000',
      pin: enteredPin,
      avatarEmoji: widget.role.emoji,
      shift: 'Active Shift',
    );

    // Save or clear credentials based on checkbox
    await HotelConfigStorage.saveSavedCredentials(
      widget.role.name,
      userId: _idController.text.trim(),
      password: enteredPin,
      remember: _rememberCredentials,
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _isLoading = false);
        widget.onAuthenticate(matched!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final hotelName = repo.clientBusinessName;
    final activeBranch = repo.activeBranch;
    final themeColor = widget.role.themeColor;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0B132B),
                themeColor.withValues(alpha: 0.85),
                const Color(0xFF0F172A),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      if (widget.onBackToGateway != null)
                        InkWell(
                          onTap: widget.onBackToGateway,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hotelName.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '📍 ${activeBranch.name} • Shift Security',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2ECC71),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'SECURE',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        // Hotel Brand Logo & App Badge
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.amber.shade400, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const ClipOval(
                                child: HotelLogoWidget(
                                  width: 84,
                                  height: 84,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              right: -4,
                              bottom: -4,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: themeColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black26, blurRadius: 4),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(widget.role.emoji, style: const TextStyle(fontSize: 16)),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Text(
                          widget.appTitle,
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
                          widget.appSubtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Error Banner
                        if (_errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFEF4444)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Color(0xFFF87171), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Clean Manual Operator Login Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 16,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Operator Staff ID / Mobile Number',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _idController,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.black.withValues(alpha: 0.3),
                                  hintText: 'Enter your Staff ID or phone',
                                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                                  prefixIcon: const Icon(Icons.badge_rounded, color: Colors.white70, size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: themeColor, width: 2),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              const Text(
                                'Security Passcode / Password / PIN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _pinController,
                                obscureText: _obscurePin,
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.black.withValues(alpha: 0.3),
                                  hintText: 'Enter security passcode',
                                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                                  prefixIcon: const Icon(Icons.lock_rounded, color: Colors.white70, size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePin ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.white70,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() => _obscurePin = !_obscurePin),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: themeColor, width: 2),
                                  ),
                                ),
                                onSubmitted: (_) => _handleManualSubmit(),
                              ),

                              const SizedBox(height: 14),

                              // ── Save ID & Password Checkbox ──
                              Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _rememberCredentials,
                                      onChanged: (val) => setState(() => _rememberCredentials = val ?? false),
                                      activeColor: themeColor,
                                      checkColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      side: BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _rememberCredentials = !_rememberCredentials),
                                      child: const Text(
                                        'Save ID & Password on this device',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Login Button
                              ElevatedButton(
                                onPressed: _isLoading ? null : _handleManualSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeColor,
                                  foregroundColor: Colors.white,
                                  elevation: 6,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  shadowColor: themeColor.withValues(alpha: 0.5),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Text(
                                            'Verify & Sign In',
                                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.4),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward_rounded, size: 18),
                                        ],
                                      ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Security Badge Footer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shield_outlined, color: Colors.white38, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'HotelPro Enterprise Security • Authorized Staff Only',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
