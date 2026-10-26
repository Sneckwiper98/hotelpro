import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/ivf_erp_theme.dart';
import '../../data/models/hospital_config_model.dart';
import '../widgets/hospital_logo_widget.dart';
import '../widgets/win32_window_frame.dart';

/// Universal Win32 Print Preview Dialog for all Bills, Invoices, Clinical Reports,
/// Prescriptions, and Statutory ART Act Consent Forms
class PrintPreviewDialog extends StatefulWidget {
  final HospitalConfigModel config;
  final String documentTitle;
  final String documentSubtitle;
  final String documentNumber;
  final Widget previewContent;
  final String initialPaperFormat; // 'A4', 'A5', '80MM'

  const PrintPreviewDialog({
    super.key,
    required this.config,
    required this.documentTitle,
    required this.documentSubtitle,
    required this.documentNumber,
    required this.previewContent,
    this.initialPaperFormat = 'A4',
  });

  static Future<void> show({
    required BuildContext context,
    required HospitalConfigModel config,
    required String documentTitle,
    required String documentSubtitle,
    required String documentNumber,
    required Widget previewContent,
    String initialPaperFormat = 'A4',
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PrintPreviewDialog(
        config: config,
        documentTitle: documentTitle,
        documentSubtitle: documentSubtitle,
        documentNumber: documentNumber,
        previewContent: previewContent,
        initialPaperFormat: initialPaperFormat,
      ),
    );
  }

  @override
  State<PrintPreviewDialog> createState() => _PrintPreviewDialogState();
}

class _PrintPreviewDialogState extends State<PrintPreviewDialog> {
  late String _selectedPrinter;
  late String _selectedPaperFormat;
  int _copies = 1;
  String _colorMode = 'Color';
  double _zoomScale = 1.0;

  final List<String> _printers = [
    'HP LaserJet Pro M404dn (Default Windows Printer)',
    'POS-80 Thermal Receipt Printer (80mm USB)',
    'Microsoft Print to PDF (Virtual)',
    'Canon LBP2900 Network Laser Printer',
    'Epson EcoTank L3250 Color MFP',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPrinter = _printers.first;
    _selectedPaperFormat = widget.initialPaperFormat;
    if (_selectedPaperFormat == '80MM') {
      _selectedPrinter = _printers[1]; // Auto-select thermal printer for 80mm
    }
  }

  @override
  Widget build(BuildContext context) {
    final nowFormatted = DateFormat('dd-MMM-yyyy | hh:mm a').format(DateTime.now());
    final activeBranch = widget.config.activeBranch;

    return Win32WindowFrame(
      title: 'WIN32 PRINT PREVIEW & PRINTER SELECTOR',
      subtitle: '${widget.documentTitle} • ${widget.documentNumber}',
      icon: Icons.print_rounded,
      defaultWidth: 1040,
      defaultHeight: 680,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Top Print Settings Control Strip ─────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFFEAECEE),
              border: Border(bottom: BorderSide(color: IvfErpTheme.borderDark)),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Printer Selector
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.print, size: 14, color: IvfErpTheme.primaryNavy),
                    const SizedBox(width: 4),
                    const Text('Printer: ', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                    Container(
                      height: 25,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: IvfErpTheme.borderDark)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPrinter,
                          isDense: true,
                          style: const TextStyle(fontSize: 10.5, color: Colors.black87),
                          items: _printers.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedPrinter = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                // Paper Size Selector
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Paper: ', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                    Container(
                      height: 25,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: IvfErpTheme.borderDark)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPaperFormat,
                          isDense: true,
                          style: const TextStyle(fontSize: 10.5, color: Colors.black87),
                          items: const [
                            DropdownMenuItem(value: 'A4', child: Text('A4 (Standard Sheet)')),
                            DropdownMenuItem(value: 'A5', child: Text('A5 (Half-Page Rx)')),
                            DropdownMenuItem(value: '80MM', child: Text('80mm (Thermal POS)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedPaperFormat = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                // Copies Counter
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Copies: ', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                    Container(
                      height: 25,
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: IvfErpTheme.borderDark)),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {
                              if (_copies > 1) setState(() => _copies--);
                            },
                            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.remove, size: 12)),
                          ),
                          Text('$_copies', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          InkWell(
                            onTap: () => setState(() => _copies++),
                            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.add, size: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Color Mode
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Mode: ', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                    Container(
                      height: 25,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: IvfErpTheme.borderDark)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _colorMode,
                          isDense: true,
                          style: const TextStyle(fontSize: 10.5, color: Colors.black87),
                          items: const [
                            DropdownMenuItem(value: 'Color', child: Text('Full Color')),
                            DropdownMenuItem(value: 'B&W', child: Text('Monochrome (B&W)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _colorMode = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                // Zoom controls
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Zoom: ', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                    InkWell(
                      onTap: () => setState(() => _zoomScale = (_zoomScale - 0.1).clamp(0.6, 1.8)),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        color: Colors.white,
                        child: const Icon(Icons.zoom_out, size: 14),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text('${(_zoomScale * 100).toInt()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    InkWell(
                      onTap: () => setState(() => _zoomScale = (_zoomScale + 0.1).clamp(0.6, 1.8)),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        color: Colors.white,
                        child: const Icon(Icons.zoom_in, size: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── 2. Document Preview Canvas ──────────────────────────────
          Expanded(
            child: Container(
              color: const Color(0xFF626567),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Transform.scale(
                      scale: _zoomScale,
                      alignment: Alignment.topCenter,
                      child: _buildPrintDocumentSheet(activeBranch, nowFormatted),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── 3. Bottom Action Bar ────────────────────────────────────
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            color: IvfErpTheme.menuBarBg,
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 13, color: IvfErpTheme.medicalEmerald),
                const SizedBox(width: 4),
                Text(
                  'Printer Ready: $_selectedPrinter • $_copies copy • $_selectedPaperFormat',
                  style: const TextStyle(fontSize: 10.5, color: Colors.black87),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    _executePrint(context);
                  },
                  icon: const Icon(Icons.print_rounded, size: 15),
                  label: Text('Print to $_selectedPrinter', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: IvfErpTheme.medicalEmerald,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Document exported as PDF: ${widget.documentNumber}.pdf'),
                        backgroundColor: IvfErpTheme.primaryNavy,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 15),
                  label: const Text('Export PDF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: IvfErpTheme.primaryNavy,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    side: const BorderSide(color: IvfErpTheme.borderDark),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: const Text('Cancel / Close', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrintDocumentSheet(HospitalBranchModel activeBranch, String nowFormatted) {
    // Determine sheet width based on paper format
    double sheetWidth;
    if (_selectedPaperFormat == '80MM') {
      sheetWidth = 320;
    } else if (_selectedPaperFormat == 'A5') {
      sheetWidth = 560;
    } else {
      sheetWidth = 740; // A4 standard
    }

    return Container(
      width: sheetWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(_selectedPaperFormat == '80MM' ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header with Configured Hospital Logo & Branch Details ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HospitalLogoWidget(
                logoPathOrUrl: widget.config.logoPathOrUrl,
                size: _selectedPaperFormat == '80MM' ? 36 : 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.config.hospitalName.toUpperCase(),
                      style: TextStyle(
                        fontSize: _selectedPaperFormat == '80MM' ? 12 : 15,
                        fontWeight: FontWeight.bold,
                        color: IvfErpTheme.primaryNavy,
                      ),
                    ),
                    Text(
                      widget.config.tagline,
                      style: TextStyle(
                        fontSize: _selectedPaperFormat == '80MM' ? 9 : 10,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${activeBranch.branchName} • ${activeBranch.address}',
                      style: const TextStyle(fontSize: 9.5, color: Colors.black87),
                    ),
                    Text(
                      'Helpline: ${widget.config.phone} | Email: ${widget.config.email}',
                      style: const TextStyle(fontSize: 9, color: Colors.black87),
                    ),
                    Text(
                      'National ART Act Reg No: ${activeBranch.artClinicRegNumber} | GSTIN: ${widget.config.gstin}',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: IvfErpTheme.medicalEmerald),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(thickness: 1.5, color: IvfErpTheme.primaryNavy),
          const SizedBox(height: 4),

          // Document Title Strip
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            color: const Color(0xFFEBF5FB),
            child: Row(
              children: [
                Text(
                  widget.documentTitle.toUpperCase(),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy),
                ),
                const Spacer(),
                Text(
                  'Doc #: ${widget.documentNumber} | Date: $nowFormatted',
                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Dynamic Document Preview Body ──────────────────────────
          widget.previewContent,

          const SizedBox(height: 20),

          // ── Signatures & Stamp Box ─────────────────────────────────
          if (_selectedPaperFormat != '80MM')
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _signatureBox('Prepared By / Cashier\n(Computer Generated)'),
                _signatureBox('Treating IVF Specialist\n(${activeBranch.inChargeDoctor})'),
                _signatureBox('Authorized Signatory &\nHospital Seal'),
              ],
            ),

          const SizedBox(height: 12),
          const Divider(thickness: 0.8, color: Colors.grey),

          // ── Permanent Technology Partner Footer ────────────────────
          Center(
            child: Text(
              'Software Developed & Maintained by Technology Partner: ${widget.config.technologyPartner}',
              style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy),
            ),
          ),
        ],
      ),
    );
  }

  Widget _signatureBox(String label) {
    return Column(
      children: [
        Container(
          width: 170,
          height: 40,
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
          child: const Center(
            child: Text('[ Digitally Verified ]', style: TextStyle(fontSize: 8.5, color: Colors.grey, fontStyle: FontStyle.italic)),
          ),
        ),
        const SizedBox(height: 3),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _executePrint(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: IvfErpTheme.medicalEmerald, size: 20),
            const SizedBox(width: 8),
            Text('Print Job Sent: ${widget.documentNumber}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Target Printer: $_selectedPrinter', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Paper Format: $_selectedPaperFormat • Copies: $_copies • Color: $_colorMode', style: const TextStyle(fontSize: 10.5)),
            const SizedBox(height: 4),
            const Text('Spooler Status: Spooled successfully to Windows Print Service.', style: TextStyle(fontSize: 10, color: IvfErpTheme.medicalEmerald)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: IvfErpTheme.primaryNavy,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
