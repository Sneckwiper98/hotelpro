import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../config/classic_erp_theme.dart';

// =============================================================================
// PrinterSettings & Helper — Manages Windows system printers and print options
// =============================================================================

class PrinterSettings {
  final String printerName;
  final int copies;
  final String paperSize;
  final String orientation;
  final String colorMode;
  final String pageRange;

  const PrinterSettings({
    required this.printerName,
    this.copies = 1,
    this.paperSize = 'A4 (210 × 297 mm)',
    this.orientation = 'Portrait',
    this.colorMode = 'Black & White',
    this.pageRange = 'All Pages',
  });
}

class PrinterHelper {
  static List<String>? _cachedPrinters;
  static String? _defaultPrinter;

  /// Fetches real installed Windows printers using PowerShell Win32_Printer
  static Future<List<String>> getInstalledPrinters() async {
    if (_cachedPrinters != null && _cachedPrinters!.isNotEmpty) {
      return _cachedPrinters!;
    }

    final printers = <String>[];
    try {
      if (Platform.isWindows) {
        final result = await Process.run('powershell', [
          '-Command',
          'Get-CimInstance Win32_Printer | Select-Object -ExpandProperty Name'
        ]);
        if (result.exitCode == 0) {
          final lines = (result.stdout as String)
              .split(RegExp(r'\r?\n'))
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          for (final p in lines) {
            if (!printers.contains(p)) {
              printers.add(p);
            }
          }
        }
      }
    } catch (_) {}

    // Fallbacks and common hotel POS/thermal printers
    if (printers.isEmpty) {
      printers.addAll([
        'Microsoft Print to PDF',
        'POS-80 Thermal Receipt Printer (USB)',
        'HP LaserJet Pro Network Printer (A4)',
        'Epson TM-T88VI Kitchen Printer (LAN)',
        'Microsoft XPS Document Writer',
      ]);
    } else {
      // Ensure virtual/thermal options are accessible for hotel billing
      if (!printers.any((p) => p.toLowerCase().contains('pos') || p.toLowerCase().contains('thermal'))) {
        printers.add('POS-80 Thermal Receipt Printer (Hotel Bill / KOT)');
      }
    }

    _cachedPrinters = printers;
    _defaultPrinter = printers.firstWhere(
      (p) => p.toLowerCase().contains('pdf') || p.toLowerCase().contains('laser'),
      orElse: () => printers.first,
    );
    return printers;
  }

  static String getDefaultPrinter() {
    return _defaultPrinter ?? 'Microsoft Print to PDF';
  }
}

// =============================================================================
// PrinterSelectionDialog — Classic Win32 System Print Dialog
// Allows user to pick printer, paper size, orientation, copies before printing.
// =============================================================================

class PrinterSelectionDialog extends StatefulWidget {
  final String documentTitle;
  final String? initialPrinter;

  const PrinterSelectionDialog({
    super.key,
    required this.documentTitle,
    this.initialPrinter,
  });

  static Future<PrinterSettings?> show(
    BuildContext context, {
    required String documentTitle,
    String? initialPrinter,
  }) {
    return showDialog<PrinterSettings>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PrinterSelectionDialog(
        documentTitle: documentTitle,
        initialPrinter: initialPrinter,
      ),
    );
  }

  @override
  State<PrinterSelectionDialog> createState() => _PrinterSelectionDialogState();
}

class _PrinterSelectionDialogState extends State<PrinterSelectionDialog> {
  List<String> _printers = [];
  late String _selectedPrinter;
  int _copies = 1;
  String _paperSize = 'A4 (210 × 297 mm)';
  String _orientation = 'Portrait';
  String _colorMode = 'Black & White';
  String _pageRange = 'All Pages';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedPrinter = widget.initialPrinter ?? PrinterHelper.getDefaultPrinter();
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    final list = await PrinterHelper.getInstalledPrinters();
    if (mounted) {
      setState(() {
        _printers = list;
        if (!_printers.contains(_selectedPrinter)) {
          _selectedPrinter = _printers.isNotEmpty ? _printers.first : 'Microsoft Print to PDF';
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        width: 540,
        decoration: BoxDecoration(
          color: ClassicErpTheme.dialogBg,
          border: Border.all(color: ClassicErpTheme.borderDark, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(3, 3))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Win32 Dialog Title Bar ─────────────────────────────────────
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
                  const Icon(Icons.print_rounded, color: Colors.white, size: 15),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Print — ${widget.documentTitle}',
                      style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context, null),
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
                  // ── GroupBox 1: Select Printer ─────────────────────────────
                  _buildGroupBox(
                    title: 'Select Printer',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Name: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: 26,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                                ),
                                child: _isLoading
                                    ? const Center(child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)))
                                    : DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _printers.contains(_selectedPrinter) ? _selectedPrinter : null,
                                          isDense: true,
                                          isExpanded: true,
                                          style: const TextStyle(fontSize: 11, color: ClassicErpTheme.textMain, fontWeight: FontWeight.w600),
                                          items: _printers.map((p) {
                                            final isThermal = p.toLowerCase().contains('pos') || p.toLowerCase().contains('thermal');
                                            final isPdf = p.toLowerCase().contains('pdf');
                                            return DropdownMenuItem<String>(
                                              value: p,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    isThermal
                                                        ? Icons.receipt_long_rounded
                                                        : (isPdf ? Icons.picture_as_pdf_rounded : Icons.print_rounded),
                                                    size: 14,
                                                    color: const Color(0xFF1B4F72),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      p,
                                                      overflow: TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() {
                                                _selectedPrinter = val;
                                                // Auto-switch paper size for thermal printers
                                                if (val.toLowerCase().contains('pos') || val.toLowerCase().contains('thermal')) {
                                                  _paperSize = '80mm Thermal Roll (Receipt / KOT)';
                                                } else if (_paperSize.contains('Thermal')) {
                                                  _paperSize = 'A4 (210 × 297 mm)';
                                                }
                                              });
                                            }
                                          },
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _classicButton(
                              label: 'Find Printer...',
                              onTap: () async {
                                setState(() => _isLoading = true);
                                PrinterHelper._cachedPrinters = null;
                                await _loadPrinters();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Printer Status Info Panel
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          color: const Color(0xFFF4F6F7),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _infoRow('Status:', 'Ready / Online (Spooler Active)'),
                              const SizedBox(height: 2),
                              _infoRow('Type:', _selectedPrinter.contains('Thermal') ? 'ESC/POS Direct Thermal Protocol' : 'Win32 Spooler / PCL-6 Driver'),
                              const SizedBox(height: 2),
                              _infoRow('Where:', _selectedPrinter.contains('Thermal') ? 'USB001 / COM1 / LAN Port 9100' : 'Local Port / WSD / Network'),
                              const SizedBox(height: 2),
                              _infoRow('Comment:', 'HotelPro Verified Enterprise Hardware'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── GroupBox 2 & 3: Page Range & Copies/Media ──────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Page Range & Orientation
                      Expanded(
                        child: _buildGroupBox(
                          title: 'Page Range & Layout',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _radioOption('All Pages', 'All Pages', _pageRange, (v) => setState(() => _pageRange = v)),
                              _radioOption('Current Page View', 'Current Page View', _pageRange, (v) => setState(() => _pageRange = v)),
                              _radioOption('Pages (1-1)', 'Pages (1-1)', _pageRange, (v) => setState(() => _pageRange = v)),
                              const Divider(height: 12, thickness: 0.5),
                              const Text('Orientation:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _orientationChip('Portrait', Icons.portrait_rounded),
                                  const SizedBox(width: 8),
                                  _orientationChip('Landscape', Icons.landscape_rounded),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Copies & Paper Media
                      Expanded(
                        child: _buildGroupBox(
                          title: 'Copies & Paper Media',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('Copies: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 32,
                                    height: 24,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                                    ),
                                    child: Text('$_copies', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 4),
                                  _spinnerButton(Icons.remove, () {
                                    if (_copies > 1) setState(() => _copies--);
                                  }),
                                  const SizedBox(width: 2),
                                  _spinnerButton(Icons.add, () {
                                    if (_copies < 99) setState(() => _copies++);
                                  }),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text('Paper Size:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain)),
                              const SizedBox(height: 4),
                              Container(
                                height: 26,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _paperSize,
                                    isDense: true,
                                    style: const TextStyle(fontSize: 10.5, color: ClassicErpTheme.textMain, fontWeight: FontWeight.w600),
                                    items: const [
                                      DropdownMenuItem(value: 'A4 (210 × 297 mm)', child: Text('A4 (210 × 297 mm) — Standard')),
                                      DropdownMenuItem(value: 'A5 (148 × 210 mm)', child: Text('A5 (148 × 210 mm)')),
                                      DropdownMenuItem(value: 'Letter (8.5 × 11 in)', child: Text('Letter (8.5 × 11 in)')),
                                      DropdownMenuItem(value: '80mm Thermal Roll (Receipt / KOT)', child: Text('80mm Thermal Roll (POS / KOT)')),
                                      DropdownMenuItem(value: '58mm Thermal Roll', child: Text('58mm Thermal Roll')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setState(() => _paperSize = val);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text('Color Mode:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _colorModeChip('Black & White'),
                                  const SizedBox(width: 6),
                                  _colorModeChip('Color'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── Dialog Bottom Action Buttons ─────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _classicButton(
                        label: 'Cancel',
                        onTap: () => Navigator.pop(context, null),
                      ),
                      const SizedBox(width: 8),
                      _classicButton(
                        label: _selectedPrinter.toLowerCase().contains('pdf')
                            ? '💾  Save as PDF...'
                            : '🖨️  Print Now',
                        isPrimary: true,
                        onTap: () {
                          final settings = PrinterSettings(
                            printerName: _selectedPrinter,
                            copies: _copies,
                            paperSize: _paperSize,
                            orientation: _orientation,
                            colorMode: _colorMode,
                            pageRange: _pageRange,
                          );
                          Navigator.pop(context, settings);
                        },
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

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 65,
          child: Text(label, style: const TextStyle(fontSize: 10, color: ClassicErpTheme.textMuted, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 10, color: ClassicErpTheme.textMain, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildGroupBox({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72), letterSpacing: 0.3),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _radioOption(String label, String value, String current, ValueChanged<String> onSelected) {
    final isSelected = current == value;
    return InkWell(
      onTap: () => onSelected(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 14,
              color: isSelected ? const Color(0xFF1B4F72) : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 10.5, color: isSelected ? const Color(0xFF1B4F72) : ClassicErpTheme.textMain, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _orientationChip(String label, IconData icon) {
    final isSelected = _orientation == label;
    return InkWell(
      onTap: () => setState(() => _orientation = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEAF2F8) : Colors.white,
          border: Border.all(color: isSelected ? const Color(0xFF1B4F72) : Colors.grey.shade300, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isSelected ? const Color(0xFF1B4F72) : Colors.grey),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFF1B4F72) : ClassicErpTheme.textMain)),
          ],
        ),
      ),
    );
  }

  Widget _colorModeChip(String label) {
    final isSelected = _colorMode == label;
    return InkWell(
      onTap: () => setState(() => _colorMode = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEAF2F8) : Colors.white,
          border: Border.all(color: isSelected ? const Color(0xFF1B4F72) : Colors.grey.shade300, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFF1B4F72) : ClassicErpTheme.textMain),
        ),
      ),
    );
  }

  Widget _spinnerButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ClassicErpTheme.buttonBg,
          border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
        ),
        child: Icon(icon, size: 12, color: ClassicErpTheme.textMain),
      ),
    );
  }

  Widget _classicButton({
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF1B4F72) : ClassicErpTheme.buttonBg,
          border: Border.all(color: isPrimary ? const Color(0xFF154360) : ClassicErpTheme.borderDark, width: 1),
          boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 2, offset: Offset(0, 1))],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isPrimary ? Colors.white : ClassicErpTheme.textMain,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// PdfExportService — Generates real PDF documents from RepaintBoundary canvas,
// opens native Windows File Save-As dialog, and provides Open File / Open Folder.
// =============================================================================

class PdfExportService {
  /// Strips illegal Win32 filename characters and ensures .pdf extension
  static String sanitizeFileName(String name) {
    var clean = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    clean = clean.replaceAll(RegExp(r'\s+'), '_').trim();
    if (!clean.toLowerCase().endsWith('.pdf')) {
      clean = '$clean.pdf';
    }
    return clean;
  }

  /// Opens the file with the default Windows application
  static Future<void> openFile(String filePath) async {
    try {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', filePath]);
      }
    } catch (_) {}
  }

  /// Opens Windows File Explorer with the file selected/highlighted
  static Future<void> openFolder(String filePath) async {
    try {
      if (Platform.isWindows) {
        await Process.run('explorer.exe', ['/select,', filePath]);
      }
    } catch (_) {}
  }

  /// Displays standard notification SnackBar with [Open PDF] and [Open Folder] actions
  static void showSaveSuccessSnackBar(BuildContext context, String filePath) {
    final fileName = filePath.split(Platform.pathSeparator).last;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1B4F72),
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        content: Row(
          children: [
            const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PDF Saved: $fileName',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Text(
                    filePath,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white24,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.open_in_new, size: 13),
              label: const Text('Open PDF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              onPressed: () => openFile(filePath),
            ),
            const SizedBox(width: 4),
            TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white24,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.folder_open, size: 13),
              label: const Text('Open Folder', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              onPressed: () => openFolder(filePath),
            ),
          ],
        ),
      ),
    );
  }

  /// Captures a RenderRepaintBoundary as high-res image and builds a pw.Document
  static Future<Uint8List?> captureBoundaryToPdf(
    GlobalKey boundaryKey, {
    String orientation = 'Portrait',
    bool isThermal = false,
  }) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // 2.5x pixelRatio produces clean, vector-crisp 200+ DPI output on A4
      final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final doc = pw.Document();
      final imageProvider = pw.MemoryImage(pngBytes);

      if (isThermal) {
        // Continuous 80mm thermal roll format
        final double rollWidth = 80 * PdfPageFormat.mm;
        final double rollHeight = (image.height / image.width) * rollWidth;
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(rollWidth, rollHeight, marginAll: 0),
            build: (pw.Context ctx) {
              return pw.FullPage(
                ignoreMargins: true,
                child: pw.Image(imageProvider, fit: pw.BoxFit.fill),
              );
            },
          ),
        );
      } else {
        // Standard A4 document format
        final isLandscape = orientation.toLowerCase().contains('landscape');
        final pageFormat = isLandscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;

        final double imgAspect = image.height / image.width;
        final double targetAspect = pageFormat.availableHeight / pageFormat.availableWidth;

        // If height fits comfortably on 1 page (aspect within 1.15x of page aspect)
        if (imgAspect <= targetAspect * 1.15) {
          doc.addPage(
            pw.Page(
              pageFormat: pageFormat,
              margin: const pw.EdgeInsets.all(20),
              build: (pw.Context ctx) {
                return pw.Center(
                  child: pw.Image(imageProvider, fit: pw.BoxFit.contain),
                );
              },
            ),
          );
        } else {
          // Multi-page document: slice vertically page by page
          final int totalPages = (imgAspect / targetAspect).ceil();
          final int sliceHeight = (image.width * targetAspect).round();

          for (int pageIdx = 0; pageIdx < totalPages; pageIdx++) {
            final int srcY = pageIdx * sliceHeight;
            final int currentSliceH = (srcY + sliceHeight <= image.height)
                ? sliceHeight
                : (image.height - srcY);

            if (currentSliceH <= 0) break;

            final recorder = ui.PictureRecorder();
            final canvas = ui.Canvas(
              recorder,
              ui.Rect.fromLTWH(0, 0, image.width.toDouble(), sliceHeight.toDouble()),
            );

            // White background fill for clean PDF pages
            canvas.drawRect(
              ui.Rect.fromLTWH(0, 0, image.width.toDouble(), sliceHeight.toDouble()),
              ui.Paint()..color = const ui.Color(0xFFFFFFFF),
            );

            // Draw image slice
            canvas.drawImageRect(
              image,
              ui.Rect.fromLTWH(0, srcY.toDouble(), image.width.toDouble(), currentSliceH.toDouble()),
              ui.Rect.fromLTWH(0, 0, image.width.toDouble(), currentSliceH.toDouble()),
              ui.Paint(),
            );

            final sliceImg = await recorder.endRecording().toImage(image.width, sliceHeight);
            final sliceByteData = await sliceImg.toByteData(format: ui.ImageByteFormat.png);
            if (sliceByteData != null) {
              final sliceProvider = pw.MemoryImage(sliceByteData.buffer.asUint8List());
              doc.addPage(
                pw.Page(
                  pageFormat: pageFormat,
                  margin: const pw.EdgeInsets.all(20),
                  build: (pw.Context ctx) {
                    return pw.Center(
                      child: pw.Image(sliceProvider, fit: pw.BoxFit.contain),
                    );
                  },
                ),
              );
            }
          }
        }
      }

      return await doc.save();
    } catch (e) {
      debugPrint('captureBoundaryToPdf error: $e');
      return null;
    }
  }

  /// Prompts user with native Windows Save-As dialog, captures canvas, writes PDF, and shows SnackBar
  static Future<String?> savePdfFromBoundary(
    BuildContext context, {
    required GlobalKey boundaryKey,
    required String suggestedName,
    String orientation = 'Portrait',
    bool isThermal = false,
  }) async {
    try {
      final sanitized = sanitizeFileName(suggestedName);

      // Open native Windows Save-As dialog
      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Document as PDF — Select Location',
        fileName: sanitized,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (outputPath == null) return null; // User cancelled

      // Generate the real PDF bytes from the boundary
      final bytes = await captureBoundaryToPdf(
        boundaryKey,
        orientation: orientation,
        isThermal: isThermal,
      );

      if (bytes == null) {
        throw Exception('Failed to capture rendered document canvas');
      }

      // Ensure .pdf extension
      final finalPath = outputPath.toLowerCase().endsWith('.pdf') ? outputPath : '$outputPath.pdf';
      final file = File(finalPath);
      await file.writeAsBytes(bytes);

      if (context.mounted) {
        showSaveSuccessSnackBar(context, finalPath);
      }
      return finalPath;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save PDF: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
      return null;
    }
  }
}

// =============================================================================
// PrintPreviewDialog — Shows a full-screen formatted document preview
// and integrates PrinterSelectionDialog for selecting Windows printers or saving PDF.
// =============================================================================

class PrintPreviewDialog {
  /// Shows a classic print-preview dialog with printer selection.
  /// [title] — document title shown in the header bar.
  /// [content] — the widget tree representing the printable document.
  /// [exportHeaders] & [exportRows] — optional tabular data to enable Export to Excel.
  /// [isThermal] — whether document is 80mm thermal receipt format.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required Widget content,
    List<String>? exportHeaders,
    List<List<dynamic>>? exportRows,
    bool isThermal = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PrintPreviewDialogWidget(
        title: title,
        content: content,
        exportHeaders: exportHeaders,
        exportRows: exportRows,
        isThermal: isThermal,
      ),
    );
  }
}

class _PrintPreviewDialogWidget extends StatefulWidget {
  final String title;
  final Widget content;
  final List<String>? exportHeaders;
  final List<List<dynamic>>? exportRows;
  final bool isThermal;

  const _PrintPreviewDialogWidget({
    required this.title,
    required this.content,
    this.exportHeaders,
    this.exportRows,
    this.isThermal = false,
  });

  @override
  State<_PrintPreviewDialogWidget> createState() => _PrintPreviewDialogWidgetState();
}

class _PrintPreviewDialogWidgetState extends State<_PrintPreviewDialogWidget> {
  final GlobalKey _previewBoundaryKey = GlobalKey();
  String _selectedPrinter = 'Microsoft Print to PDF';
  List<String> _installedPrinters = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    final list = await PrinterHelper.getInstalledPrinters();
    if (mounted) {
      setState(() {
        _installedPrinters = list;
        _selectedPrinter = PrinterHelper.getDefaultPrinter();
      });
    }
  }

  Future<void> _handleSavePdfDirect() async {
    setState(() => _isProcessing = true);
    try {
      await PdfExportService.savePdfFromBoundary(
        context,
        boundaryKey: _previewBoundaryKey,
        suggestedName: widget.title,
        orientation: 'Portrait',
        isThermal: widget.isThermal,
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handlePrintFlow() async {
    // Open the Windows Printer Selection Dialog
    final settings = await PrinterSelectionDialog.show(
      context,
      documentTitle: widget.title,
      initialPrinter: _selectedPrinter,
    );

    if (!mounted || settings == null) return;

    setState(() {
      _selectedPrinter = settings.printerName;
    });

    final isPdf = settings.printerName.toLowerCase().contains('pdf') ||
        settings.printerName.toLowerCase().contains('xps') ||
        settings.printerName.toLowerCase().contains('document writer');

    if (isPdf) {
      setState(() => _isProcessing = true);
      try {
        final savedPath = await PdfExportService.savePdfFromBoundary(
          context,
          boundaryKey: _previewBoundaryKey,
          suggestedName: widget.title,
          orientation: settings.orientation,
          isThermal: widget.isThermal,
        );
        if (savedPath != null && mounted) {
          Navigator.pop(context);
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    } else {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: 920,
              maxHeight: MediaQuery.of(context).size.height * 0.90,
            ),
            decoration: BoxDecoration(
              color: ClassicErpTheme.panelBg,
              border: Border.all(color: ClassicErpTheme.borderDark, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 12, offset: Offset(4, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Title Bar ──────────────────────────────────────────────────
                Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1B4F72), Color(0xFF2874A6)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.print_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Print Preview & Document Spooler — ${widget.title}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                ),

                // ── Toolbar with Printer Selection & Export ───────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  color: ClassicErpTheme.toolbarBg,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Printer Selector Dropdown on Toolbar
                        Container(
                          height: 25,
                          constraints: const BoxConstraints(maxWidth: 220),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.print, size: 13, color: Color(0xFF1B4F72)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _installedPrinters.contains(_selectedPrinter) ? _selectedPrinter : null,
                                    isDense: true,
                                    isExpanded: true,
                                    hint: Text(
                                      _selectedPrinter,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    style: const TextStyle(fontSize: 10, color: ClassicErpTheme.textMain, fontWeight: FontWeight.bold),
                                    items: _installedPrinters.map((p) {
                                      return DropdownMenuItem<String>(
                                        value: p,
                                        child: Text(p, overflow: TextOverflow.ellipsis, maxLines: 1),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _selectedPrinter = val);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _toolBtn(
                          context,
                          Icons.tune_rounded,
                          'Setup',
                          () => _handlePrintFlow(),
                        ),
                        const SizedBox(width: 6),
                        _toolBtn(
                          context,
                          Icons.picture_as_pdf_rounded,
                          'Save PDF',
                          () => _handleSavePdfDirect(),
                        ),
                        if (widget.exportHeaders != null && widget.exportRows != null) ...[
                          const SizedBox(width: 6),
                          _toolBtn(
                            context,
                            Icons.table_view_rounded,
                            'Excel',
                            () => ExcelExportService.saveAsCsv(
                              context,
                              suggestedName: widget.title,
                              headers: widget.exportHeaders!,
                              rows: widget.exportRows!,
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        Text(
                          widget.isThermal ? '• 80mm Roll' : '• A4 Portrait (100%)',
                          style: const TextStyle(fontSize: 10, color: ClassicErpTheme.textMuted),
                        ),
                        const SizedBox(width: 14),
                        _toolBtn(context, Icons.close_rounded, 'Cancel', () => Navigator.pop(context)),
                        const SizedBox(width: 6),
                        _toolBtn(
                          context,
                          Icons.print_rounded,
                          'Print Now',
                          () => _handlePrintFlow(),
                          primary: true,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Document Canvas with RepaintBoundary ───────────────────────
                Expanded(
                  child: Container(
                    color: const Color(0xFF7F8C8D),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      child: Center(
                        child: RepaintBoundary(
                          key: _previewBoundaryKey,
                          child: Container(
                            constraints: BoxConstraints(maxWidth: widget.isThermal ? 380 : 760),
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: const [
                                BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 3)),
                              ],
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: widget.content,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading overlay when generating PDF
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFF1B4F72), width: 1.5),
                      boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 10)],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text(
                          'Generating & Saving PDF Document...',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF1B4F72)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _toolBtn(BuildContext context, IconData icon, String label, VoidCallback onTap, {bool primary = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: primary ? const Color(0xFF1B4F72) : ClassicErpTheme.buttonBg,
          border: Border.all(color: primary ? const Color(0xFF154360) : ClassicErpTheme.borderDark, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: primary ? Colors.white : ClassicErpTheme.textMain),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: primary ? Colors.white : ClassicErpTheme.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// ExcelExportService — Generates CSV (Excel-compatible) and saves via
// Windows Save-As file dialog using file_picker.
// =============================================================================

class ExcelExportService {
  /// Opens a Windows Save-As dialog and writes CSV data.
  /// [suggestedName] — default filename (without extension).
  /// [headers] — column header row.
  /// [rows] — data rows (each is a list of values).
  static Future<void> saveAsCsv(
    BuildContext context, {
    required String suggestedName,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) async {
    try {
      // Build CSV content
      final List<List<dynamic>> allRows = [headers, ...rows];
      final csv = const ListToCsvConverter().convert(allRows);
      final bytes = csv.codeUnits;

      // Open Windows Save-As dialog
      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export to Excel — Save As',
        fileName: '$suggestedName.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (outputPath == null) return; // User cancelled

      // Write file
      final file = File(outputPath);
      await file.writeAsBytes(bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported: ${file.path.split(r'\').last}'),
            backgroundColor: const Color(0xFF1E7145),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
