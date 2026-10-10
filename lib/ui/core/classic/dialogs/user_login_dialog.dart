import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/classic_erp_theme.dart';
import '../../../../data/repositories/hotel_repository.dart';

/// Classic Win32 System Authentication & Operator Switcher Dialog
class UserLoginDialog extends StatefulWidget {
  const UserLoginDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const UserLoginDialog(),
    );
  }

  @override
  State<UserLoginDialog> createState() => _UserLoginDialogState();
}

class _UserLoginDialogState extends State<UserLoginDialog> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleDirectLogin(HotelRepository repo) {
    final user = _usernameController.text.trim();
    final pass = _passwordController.text.trim();

    if (user.isEmpty) {
      setState(() => _errorMessage = 'Please enter a username or operator ID.');
      return;
    }

    final success = repo.authenticateUser(user, pass);
    if (success) {
      Navigator.pop(context);
      final isDev = repo.currentErpUser.isDeveloper;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isDev
                ? '🛡️ Developer Mode Activated! Developer Settings are now visible.'
                : '✅ Logged in as ${repo.currentErpUser.displayName} (${repo.currentErpUser.role.label})',
          ),
          backgroundColor: isDev ? const Color(0xFF006266) : const Color(0xFF27AE60),
        ),
      );
    } else {
      setState(() => _errorMessage = 'Invalid username or password credentials.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final currentUser = repo.currentErpUser;

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        width: 520,
        decoration: BoxDecoration(
          color: ClassicErpTheme.dialogBg,
          border: Border.all(color: ClassicErpTheme.borderDark, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Win32 Dialog Title Bar ─────────────────────────────────
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B4F72), Color(0xFF2874A6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.manage_accounts_rounded, color: Colors.white, size: 15),
                  const SizedBox(width: 6),
                  const Text(
                    'Operator Login & System Authentication — [HotelPro Live]',
                    style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Current Active Operator Banner
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: currentUser.isDeveloper ? const Color(0xFF006266) : const Color(0xFF1B4F72),
                          child: Icon(
                            currentUser.isDeveloper ? Icons.shield_rounded : Icons.person_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentUser.displayName.toUpperCase(),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Role: ${currentUser.role.label} • Username: ${currentUser.username}',
                                style: const TextStyle(fontSize: 10.5, color: ClassicErpTheme.textMuted),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Allocated Branches: ${currentUser.branchAccess.length} node(s) (${currentUser.branchAccess.join(", ")})',
                                style: TextStyle(fontSize: 10, color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        if (currentUser.isDeveloper)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F8F5),
                              border: Border.all(color: const Color(0xFF1ABC9C)),
                            ),
                            child: const Text('DEV ROOT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF006266))),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Credential Login Section (Used for Developer Login or Password Auth)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DIRECT CREDENTIALS LOGIN (Or Enter Developer Credentials):',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            const SizedBox(
                              width: 80,
                              child: Text('User ID:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              child: SizedBox(
                                height: 28,
                                child: TextField(
                                  controller: _usernameController,
                                  style: const TextStyle(fontSize: 11),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    hintText: 'Enter User ID / Username',
                                    hintStyle: const TextStyle(fontSize: 10.5, color: Colors.grey),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.zero,
                                      borderSide: BorderSide(color: Colors.grey.shade400),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        Row(
                          children: [
                            const SizedBox(
                              width: 80,
                              child: Text('Password:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              child: SizedBox(
                                height: 28,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        style: const TextStyle(fontSize: 11),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          hintText: 'Enter password',
                                          hintStyle: const TextStyle(fontSize: 10.5, color: Colors.grey),
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.zero,
                                            borderSide: BorderSide(color: Colors.grey.shade400),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                                      child: Container(
                                        height: 28,
                                        width: 28,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade400),
                                          color: Colors.grey.shade100,
                                        ),
                                        child: Icon(
                                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                          size: 14,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 26,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1B4F72),
                                  foregroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                ),
                                onPressed: () => _handleDirectLogin(repo),
                                child: const Text('Login', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 10.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
