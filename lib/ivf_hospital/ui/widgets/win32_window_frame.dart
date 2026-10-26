import 'package:flutter/material.dart';
import '../../config/ivf_erp_theme.dart';

/// Classic Win32 Window Frame with Minimize, Maximize/Restore, and Close Controls
/// Provides standard desktop ERP behavior across all dialogs and pages
class Win32WindowFrame extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final double defaultWidth;
  final double defaultHeight;
  final Widget child;
  final Widget? headerAction;
  final VoidCallback? onClose;

  const Win32WindowFrame({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.defaultWidth = 980,
    this.defaultHeight = 620,
    required this.child,
    this.headerAction,
    this.onClose,
  });

  @override
  State<Win32WindowFrame> createState() => _Win32WindowFrameState();
}

class _Win32WindowFrameState extends State<Win32WindowFrame> {
  bool _isMaximized = false;
  bool _isMinimized = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Calculate dimensions based on window state
    double targetWidth;
    double targetHeight;

    if (_isMinimized) {
      targetWidth = 420;
      targetHeight = 36;
    } else if (_isMaximized) {
      targetWidth = screenSize.width * 0.98;
      targetHeight = screenSize.height * 0.96;
    } else {
      targetWidth = widget.defaultWidth.clamp(320.0, screenSize.width * 0.95);
      targetHeight = widget.defaultHeight.clamp(200.0, screenSize.height * 0.94);
    }

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      backgroundColor: IvfErpTheme.windowBg,
      insetPadding: const EdgeInsets.all(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        width: targetWidth,
        height: targetHeight,
        decoration: BoxDecoration(
          border: Border.all(color: IvfErpTheme.borderDark, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Win32 Title Bar with Minimize, Maximize & Close ───
            Container(
              height: 34,
              padding: const EdgeInsets.only(left: 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [IvfErpTheme.primaryNavy, Color(0xFF1B4F72)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.title.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '• ${widget.subtitle}',
                              style: const TextStyle(color: Colors.white70, fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (widget.headerAction != null) ...[
                    widget.headerAction!,
                    const SizedBox(width: 6),
                  ],

                  // ── Win32 Window Controls ───
                  // 1. Minimize Button
                  _win32ControlButton(
                    tooltip: _isMinimized ? 'Restore Dialog' : 'Minimize Dialog',
                    icon: _isMinimized ? Icons.expand_more_rounded : Icons.remove_rounded,
                    onTap: () {
                      setState(() {
                        _isMinimized = !_isMinimized;
                        if (_isMinimized) _isMaximized = false;
                      });
                    },
                  ),

                  // 2. Maximize / Restore Button
                  _win32ControlButton(
                    tooltip: _isMaximized ? 'Restore Default Size' : 'Maximize Fullscreen',
                    icon: _isMaximized ? Icons.fullscreen_exit_rounded : Icons.crop_square_rounded,
                    onTap: () {
                      setState(() {
                        if (_isMinimized) _isMinimized = false;
                        _isMaximized = !_isMaximized;
                      });
                    },
                  ),

                  // 3. Close Button (Hover red in Win32 style)
                  _win32ControlButton(
                    tooltip: 'Close Window (Esc)',
                    icon: Icons.close_rounded,
                    isClose: true,
                    onTap: () {
                      if (widget.onClose != null) {
                        widget.onClose!();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              ),
            ),

            // ── Dialog Body ───
            if (!_isMinimized)
              Expanded(
                child: widget.child,
              ),

            if (_isMinimized)
              Container(
                height: 0,
              ),
          ],
        ),
      ),
    );
  }

  Widget _win32ControlButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onTap,
    bool isClose = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        hoverColor: isClose ? const Color(0xFFC0392B) : Colors.white24,
        child: Container(
          width: 38,
          height: 34,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 15,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
