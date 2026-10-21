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

/// Ultra-Modern, Strict Role-Based Authentication Screen for HotelPro Mobile Suite.
/// Security Principles:
/// 1. Only registered system users can log in.
/// 2. Users MUST have valid credentials (Password verified).
/// 3. Users MUST have explicit authority / role permissions for the specific mobile app.
/// 4. Any unregistered or unauthorized user access is strictly blocked.
class MobileStaffLoginView extends StatefulWidget {
  final MobileAppRole role;
  final String appTitle;
  final String appSubtitle;
  final ValueChanged<StaffProfileAuth> onAuthenticate;
  final VoidCallback? onBackToGateway;

  const MobileStaffLoginView({
    super.key,
    required this.role,
    required this.appTitle,
    required this.appSubtitle,
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

  String _getAppCodeForRole(MobileAppRole role) {
    switch (role) {
      case MobileAppRole.waiter:
        return 'waiter_pos';
      case MobileAppRole.deliveryBoy:
        return 'delivery_boy';
      case MobileAppRole.housekeeping:
        return 'housekeeping';
      case MobileAppRole.manager:
        return 'manager_mis';
      default:
        return 'windows_erp';
    }
  }

  void _handleManualSubmit() async {
    final repo = context.read<HotelRepository>();
    final enteredId = _idController.text.trim();
    final enteredPassword = _pinController.text.trim();

    if (enteredId.isEmpty) {
      setState(() => _errorMessage = 'Please enter your registered Username or Operator ID.');
      return;
    }
    if (enteredPassword.isEmpty) {
      setState(() => _errorMessage = 'Please enter your security password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final targetAppCode = _getAppCodeForRole(widget.role);
    final authResult = repo.authenticateUserWithDetails(
      enteredId,
      enteredPassword,
      requiredApp: targetAppCode,
    );

    if (!authResult.success) {
      setState(() {
        _isLoading = false;
        _errorMessage = authResult.errorMessage ?? 'Authentication failed.';
      });
      return;
    }

    final user = authResult.user!;
    repo.setActiveMobileUser(user);

    // Save or clear credentials based on checkbox
    await HotelConfigStorage.saveSavedCredentials(
      widget.role.name,
      userId: enteredId,
      password: enteredPassword,
      remember: _rememberCredentials,
    );

    String staffPhone = '+91 98000 00000';
    if (user.staffId != null) {
      final matchingStaff = repo.activeBranchStaff.where((s) => s.id == user.staffId).firstOrNull;
      if (matchingStaff != null && matchingStaff.phone.isNotEmpty) {
        staffPhone = matchingStaff.phone;
      }
    }

    final matched = StaffProfileAuth(
      id: user.id,
      name: user.displayName,
      role: user.role.label,
      phone: staffPhone,
      pin: enteredPassword,
      avatarEmoji: widget.role.emoji,
      shift: 'Active Duty',
      branchId: user.branchAccess.isNotEmpty ? user.branchAccess.first : repo.activeBranch.id,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      widget.onAuthenticate(matched);
    }
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
                              '📍 ${activeBranch.name} • Security Gate',
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
                              'VERIFIED',
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
                              width: 84,
                              height: 84,
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
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              right: -4,
                              bottom: -4,
                              child: Container(
                                width: 32,
                                height: 32,
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

                        const SizedBox(height: 14),

                        Text(
                          widget.appTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
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
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Error Banner with clear explanation
                        if (_errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFEF4444)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.gpp_bad_rounded, color: Color(0xFFF87171), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFFFEE2E2),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Clean Operator Authentication Form Card
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
                                'Operator Username / Login ID',
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
                                  hintText: 'Enter your registered Username or ID',
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
                                'Security Password',
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
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.black.withValues(alpha: 0.3),
                                  hintText: 'Enter operator password',
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

                              const SizedBox(height: 12),

                              // Save ID & Password Checkbox
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
                                        'Remember login on this device',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              // Sign In Button
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
                                            'Verify Credentials & Enter',
                                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, letterSpacing: 0.4),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward_rounded, size: 18),
                                        ],
                                      ),
                              ),
                            ],
                          ),
                        ),



                        const SizedBox(height: 20),

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
