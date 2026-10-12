import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/services/app_update_service.dart';

class AppUpdateDialog extends StatefulWidget {
  final AppUpdateInfo updateInfo;
  final VoidCallback onDismiss;

  const AppUpdateDialog({
    super.key,
    required this.updateInfo,
    required this.onDismiss,
  });

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  bool _isUpdating = false;
  double _progress = 0.0;
  String _statusMessage = '';
  String? _errorMessage;

  Future<void> _handleUpdate() async {
    final isWindows = !kIsWeb && Platform.isWindows;

    if (isWindows) {
      setState(() {
        _isUpdating = true;
        _errorMessage = null;
        _progress = 0.05;
        _statusMessage = 'Connecting to GitHub server...';
      });

      try {
        await AppUpdateService.performWindowsInAppUpdate(
          widget.updateInfo,
          onProgress: (pct, msg) {
            if (mounted) {
              setState(() {
                _progress = pct;
                _statusMessage = msg;
              });
            }
          },
        );
      } catch (e) {
        if (mounted) {
          setState(() {
            _isUpdating = false;
            _errorMessage = 'In-app update notice: $e';
          });
        }
      }
    } else {
      // Android / Other mobile: Launch direct APK download
      widget.onDismiss();
      AppUpdateService.downloadUpdate(widget.updateInfo.downloadUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWindows = !kIsWeb && Platform.isWindows;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 24,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E222D) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
          border: Border.all(
            color: const Color(0xFF1E8449).withOpacity(0.35),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Premium Header ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0E3A24), Color(0xFF1E8449)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                    ),
                    child: Icon(
                      _isUpdating ? Icons.sync_rounded : Icons.system_update_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isUpdating
                              ? 'Updating In-Place • ऐप अपडेट हो रहा है'
                              : 'Update Available! • नया अपडेट उपलब्ध है',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.updateInfo.targetApp.displayName} • v${widget.updateInfo.latestVersion}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_isUpdating) ...[
              // ── Live Progress Section (For Seamless In-App Updating) ──────
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Updating System Files...',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          '${(_progress * 100).toInt()}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1E8449),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progress.clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E8449)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E8449).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF1E8449).withOpacity(0.25)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, color: Color(0xFF1E8449), size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Software will automatically restart into the new version once ready. No manual setup needed.',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF1E8449)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // ── Version Comparison Badges ────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CURRENT VERSION',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'v${widget.updateInfo.currentVersion}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.arrow_forward_rounded, color: Color(0xFF1E8449), size: 24),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E8449).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF1E8449).withOpacity(0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'LATEST RELEASE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E8449).withOpacity(0.9),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E8449),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'NEW',
                                    style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'v${widget.updateInfo.latestVersion}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E8449),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── What's New / Release Notes ───────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFFD4AC0D)),
                        const SizedBox(width: 6),
                        Text(
                          "What's New in v${widget.updateInfo.latestVersion}:",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (widget.updateInfo.publishedAt != null) ...[
                          const Spacer(),
                          Text(
                            DateFormat('dd MMM yyyy').format(widget.updateInfo.publishedAt!),
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF14171E) : const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.withOpacity(0.15)),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          widget.updateInfo.releaseNotes.trim().isNotEmpty
                              ? widget.updateInfo.releaseNotes.trim()
                              : '• Seamless In-App Updater for Windows Desktop.\n• 2-way Realtime Cloud Sync across all 5 Android Apps.\n• Stability & performance upgrades.',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.45,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isWindows
                          ? '⚡ सॉफ्टवेयर के अंदर ही अपडेट डाउनलोड होकर 2 सेकंड में रीस्टार्ट हो जाएगा (अलग से डाउनलोड या री-इंस्टॉल करने की कोई जरूरत नहीं)।'
                          : '⚡ "Update Now" पर क्लिक करते ही नया APK डाउनलोड होकर तुरंत इंस्टॉल हो जाएगा।',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 11.5, color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Action Buttons ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onDismiss,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'Later • बाद में',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _handleUpdate,
                        icon: Icon(
                          isWindows ? Icons.auto_mode_rounded : Icons.download_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: Text(
                          isWindows
                              ? 'Update Inside App • तुरंत अपडेट करें'
                              : 'Update Now • अभी अपडेट करें',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E8449),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
