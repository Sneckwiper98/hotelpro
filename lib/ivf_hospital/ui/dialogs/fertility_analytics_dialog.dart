import 'package:flutter/material.dart';
import '../../config/ivf_erp_theme.dart';
import '../../data/repositories/ivf_hospital_repository.dart';
import '../widgets/win32_window_frame.dart';
import 'print_preview_dialog.dart';

/// Clinical IVF & Fertility Analytics Dashboard Dialog
class FertilityAnalyticsDialog extends StatelessWidget {
  final IvfHospitalRepository repo;

  const FertilityAnalyticsDialog({super.key, required this.repo});

  static Future<void> show(BuildContext context, IvfHospitalRepository repo) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => FertilityAnalyticsDialog(repo: repo),
    );
  }

  void _printAnalyticsReport(BuildContext context) {
    final cycles = repo.ivfCycles;
    final totalCycles = cycles.length;
    final positiveOutcomes = cycles.where((c) => c.cycleOutcome.contains('Positive') || c.cycleOutcome.contains('Delivered')).length;
    final clinicalPregnancyRate = totalCycles > 0 ? ((positiveOutcomes / totalCycles) * 100).toStringAsFixed(1) : '0.0';

    int totalM2 = 0;
    int total2Pn = 0;
    int totalBlastocysts = 0;
    for (var c in cycles) {
      totalM2 += c.m2Oocytes;
      total2Pn += c.fertilization2pnCount;
      totalBlastocysts += c.day5BlastocystCount;
    }
    final fertRate = totalM2 > 0 ? ((total2Pn / totalM2) * 100).toStringAsFixed(1) : '0.0';
    final blastRate = total2Pn > 0 ? ((totalBlastocysts / total2Pn) * 100).toStringAsFixed(1) : '0.0';
    final config = repo.config;

    PrintPreviewDialog.show(
      context: context,
      config: config,
      documentTitle: 'IVF & EMBRYOLOGY LAB CLINICAL SUCCESS AUDIT REPORT',
      documentSubtitle: 'Quality Key Performance Indicators (KPIs) & ART Act Registry Summary',
      documentNumber: 'ANALYTICS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      initialPaperFormat: 'A4',
      previewContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            color: const Color(0xFFF4ECF7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(children: [const Text('CLINICAL PREGNANCY RATE', style: TextStyle(fontSize: 8.5, color: Colors.grey, fontWeight: FontWeight.bold)), Text('$clinicalPregnancyRate%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E8449)))]),
                Column(children: [const Text('FERTILIZATION RATE (2PN)', style: TextStyle(fontSize: 8.5, color: Colors.grey, fontWeight: FontWeight.bold)), Text('$fertRate%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF8E44AD)))]),
                Column(children: [const Text('BLASTOCYST CONVERSION', style: TextStyle(fontSize: 8.5, color: Colors.grey, fontWeight: FontWeight.bold)), Text('$blastRate%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2980B9)))]),
                Column(children: [const Text('TOTAL AUDITED CYCLES', style: TextStyle(fontSize: 8.5, color: Colors.grey, fontWeight: FontWeight.bold)), Text('$totalCycles', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF003366)))]),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            color: const Color(0xFF4A148C),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Cycle ID', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 4, child: Text('Patient Name', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Type', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('OPU', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('2PN', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Blast', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('Outcome', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          ...cycles.map((c) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text(c.cycleId, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                Expanded(flex: 4, child: Text(c.patientName, style: const TextStyle(fontSize: 9))),
                Expanded(flex: 2, child: Text(c.cycleType, style: const TextStyle(fontSize: 9))),
                Expanded(flex: 2, child: Text('${c.totalOocytesRetrieved}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 9))),
                Expanded(flex: 2, child: Text('${c.fertilization2pnCount}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 9))),
                Expanded(flex: 2, child: Text('${c.day5BlastocystCount}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text(c.cycleOutcome, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: c.cycleOutcome.contains('Positive') || c.cycleOutcome.contains('Delivered') ? const Color(0xFF27AE60) : const Color(0xFF7D6608)))),
              ],
            ),
          )),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            color: const Color(0xFFF9FAFB),
            child: const Text(
              'REGULATORY COMPLIANCE NOTE: All clinical performance indicators compiled in accordance with National ART Act 2021 statutory register standards. Benchmarked against ESHRE & ISAR quality guidelines.',
              style: TextStyle(fontSize: 9, fontStyle: FontStyle.italic, color: Color(0xFF555555)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cycles = repo.ivfCycles;
    final totalCycles = cycles.length;
    final positiveOutcomes = cycles.where((c) => c.cycleOutcome.contains('Positive') || c.cycleOutcome.contains('Delivered')).length;
    final clinicalPregnancyRate = totalCycles > 0 ? ((positiveOutcomes / totalCycles) * 100).toStringAsFixed(1) : '0.0';

    int totalM2 = 0;
    int total2Pn = 0;
    int totalBlastocysts = 0;

    for (var c in cycles) {
      totalM2 += c.m2Oocytes;
      total2Pn += c.fertilization2pnCount;
      totalBlastocysts += c.day5BlastocystCount;
    }

    final fertRate = totalM2 > 0 ? ((total2Pn / totalM2) * 100).toStringAsFixed(1) : '0.0';
    final blastRate = total2Pn > 0 ? ((totalBlastocysts / total2Pn) * 100).toStringAsFixed(1) : '0.0';

    return Win32WindowFrame(
      title: 'IVF & EMBRYOLOGY SUCCESS RATE ANALYTICS',
      subtitle: '${repo.config.hospitalName} • ${repo.config.activeBranch.branchName}',
      icon: Icons.analytics_rounded,
      defaultWidth: 1000,
      defaultHeight: 680,
      child: Column(
        children: [

            // Metrics Cards Row
            Container(
              padding: const EdgeInsets.all(10),
              color: const Color(0xFFF4ECF7),
              child: Row(
                children: [
                  _kpiCard('Clinical Pregnancy Rate', '$clinicalPregnancyRate%', Icons.favorite_rounded, const Color(0xFF1E8449)),
                  const SizedBox(width: 8),
                  _kpiCard('Fertilization Rate (2PN)', '$fertRate%', Icons.science_rounded, IvfErpTheme.ivfPurple),
                  const SizedBox(width: 8),
                  _kpiCard('Blastocyst Conversion', '$blastRate%', Icons.biotech_rounded, const Color(0xFF2980B9)),
                  const SizedBox(width: 8),
                  _kpiCard('Total IVF Cycles', '$totalCycles', Icons.auto_graph_rounded, IvfErpTheme.primaryNavy),
                ],
              ),
            ),

            // Detailed Analytics List
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('Cycle-wise Outcomes & Clinical Success Summary'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: IvfErpTheme.borderDark)),
                      child: Table(
                        border: TableBorder.all(color: IvfErpTheme.borderLight),
                        columnWidths: const {
                          0: FixedColumnWidth(110),
                          1: FlexColumnWidth(2),
                          2: FixedColumnWidth(100),
                          3: FixedColumnWidth(100),
                          4: FixedColumnWidth(120),
                          5: FixedColumnWidth(120),
                        },
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(color: IvfErpTheme.gridHeaderBg),
                            children: [
                              _th('Cycle ID'),
                              _th('Patient Name'),
                              _th('Oocytes (MII)'),
                              _th('Day 5 Blast'),
                              _th('Beta-hCG (mIU)'),
                              _th('Clinical Outcome'),
                            ],
                          ),
                          for (var c in cycles)
                            TableRow(
                              children: [
                                _td(c.cycleId, bold: true, color: IvfErpTheme.primaryNavy),
                                _td(c.patientName),
                                _td('${c.m2Oocytes} MII', align: TextAlign.center),
                                _td('${c.day5BlastocystCount} Blast', align: TextAlign.center),
                                _td(c.betaHcgValue != null ? '${c.betaHcgValue}' : 'Pending', align: TextAlign.right),
                                _td(c.cycleOutcome, bold: true, color: c.cycleOutcome.contains('Positive') ? IvfErpTheme.medicalEmerald : IvfErpTheme.ivfPurple),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _sectionHeader('National ART Act 2021 Regulatory & Clinical Reporting Note'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      color: Colors.white,
                      child: const Text(
                        'All clinical statistics (OPU, Embryology, Blastocyst conversion, Pregnancy outcome, and Cryopreservation records) are recorded in compliance with the National Assisted Reproductive Technology and Surrogacy Act 2021. Data is digitally stored for regulatory inspection.',
                        style: TextStyle(fontSize: 10.5, color: IvfErpTheme.textMuted, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Close Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: IvfErpTheme.menuBarBg,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.print_rounded, size: 14),
                    label: const Text('Print Clinical Success Audit (A4)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: IvfErpTheme.ivfPurple,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: () => _printAnalyticsReport(context),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close Analytics'),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: IvfErpTheme.borderLight)),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, color: IvfErpTheme.textMuted, fontWeight: FontWeight.w600)),
                  Text(value, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: IvfErpTheme.gridHeaderBg,
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy),
      ),
    );
  }

  static const _thStyle = TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy);
  static Widget _th(String text) => Padding(padding: const EdgeInsets.all(6), child: Text(text, style: _thStyle, textAlign: TextAlign.center));
  static Widget _td(String text, {bool bold = false, Color? color, TextAlign align = TextAlign.left}) => Padding(
        padding: const EdgeInsets.all(6),
        child: Text(text, textAlign: align, style: TextStyle(fontSize: 10.5, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color ?? IvfErpTheme.textMain)),
      );
}
