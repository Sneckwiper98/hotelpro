import 'package:flutter/material.dart';
import '../../config/ivf_erp_theme.dart';
import '../../data/repositories/ivf_hospital_repository.dart';

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

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final dialogWidth = (screen.width * 0.90).clamp(750.0, 920.0);
    final dialogHeight = (screen.height * 0.88).clamp(520.0, 660.0);

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

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        decoration: BoxDecoration(
          color: IvfErpTheme.dialogBg,
          border: Border.all(color: IvfErpTheme.borderDark, width: 2),
        ),
        child: Column(
          children: [
            // Title Bar
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              color: IvfErpTheme.ivfPurple,
              child: Row(
                children: [
                  const Icon(Icons.analytics_rounded, size: 15, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'IVF & Embryology Success Rate Analytics — ${repo.config.hospitalName}',
                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 15, color: Colors.white),
                  ),
                ],
              ),
            ),

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
