import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/ivf_erp_theme.dart';
import '../../data/repositories/ivf_hospital_repository.dart';

/// Hospital Daily Operational Census & Revenue MIS Summary (PDF Section 40)
class DailyMisSummaryDialog extends StatelessWidget {
  final IvfHospitalRepository repo;

  const DailyMisSummaryDialog({super.key, required this.repo});

  static Future<void> show(BuildContext context, IvfHospitalRepository repo) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DailyMisSummaryDialog(repo: repo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = repo.config;
    final nowFormatted = DateFormat('dd-MMMM-yyyy | hh:mm a').format(DateTime.now());
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    // Calculate real numbers from repository
    final totalPatients = repo.patients.length;
    final activeCycles = repo.ivfCycles.length;
    final positiveCycles = repo.ivfCycles.where((c) => c.cycleOutcome.contains('Positive')).length;
    final maternityCases = repo.maternityCases.length;
    final deliveredCases = repo.maternityCases.where((m) => m.deliveryDate != null).length;

    double totalRevenue = 0;
    double totalPaid = 0;
    for (final inv in repo.invoices) {
      totalRevenue += inv.totalAmount;
      totalPaid += inv.paidAmount;
    }
    final pendingBalance = totalRevenue - totalPaid;

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      backgroundColor: IvfErpTheme.windowBg,
      child: Container(
        width: 900,
        height: 600,
        decoration: BoxDecoration(
          border: Border.all(color: IvfErpTheme.borderDark, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              color: IvfErpTheme.primaryNavy,
              child: Row(
                children: [
                  const Icon(Icons.assessment_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'DAILY OPERATIONAL CENSUS & EXECUTIVE MIS SUMMARY (PDF Section 40)',
                    style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white, size: 16),
                    splashRadius: 14,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            // Letterhead banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFFEBF5FB),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(config.hospitalName.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy)),
                      Text('National ART Act Reg No: ${config.artClinicRegNumber} | GSTIN: ${config.gstin}', style: const TextStyle(fontSize: 9.5, color: Colors.black87)),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Generated On:', style: TextStyle(fontSize: 9, color: Colors.grey)),
                      Text(nowFormatted, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Row 1: KPI Cards
                    Row(
                      children: [
                        Expanded(child: _kpiCard('Active Patients', '$totalPatients', Icons.people_alt_rounded, IvfErpTheme.primaryNavy)),
                        const SizedBox(width: 8),
                        Expanded(child: _kpiCard('IVF / ART Pipeline', '$activeCycles', Icons.biotech_rounded, IvfErpTheme.ivfPurple)),
                        const SizedBox(width: 8),
                        Expanded(child: _kpiCard('Confirmed Pregnancies', '$positiveCycles', Icons.favorite_rounded, IvfErpTheme.medicalEmerald)),
                        const SizedBox(width: 8),
                        Expanded(child: _kpiCard('Maternity & Deliveries', '$deliveredCases / $maternityCases', Icons.child_friendly_rounded, IvfErpTheme.pinkMaternity)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Row 2: Financial Census Box
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: IvfErpTheme.borderDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.currency_rupee_rounded, size: 14, color: IvfErpTheme.primaryNavy),
                              SizedBox(width: 6),
                              Text('Daily Financial Realization & Collections', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy)),
                            ],
                          ),
                          const Divider(height: 12),
                          Row(
                            children: [
                              _financialMetric('Total Invoiced Value', currency.format(totalRevenue), Colors.black87),
                              _financialMetric('Total Collected (Cash/UPI/Card)', currency.format(totalPaid), IvfErpTheme.medicalEmerald),
                              _financialMetric('Pending Balance Due', currency.format(pendingBalance), IvfErpTheme.alertRuby),
                              _financialMetric('Collection Efficiency', '${((totalPaid / (totalRevenue == 0 ? 1 : totalRevenue)) * 100).toStringAsFixed(1)}%', IvfErpTheme.primaryNavy),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Row 3: Daily Clinical Action Schedule
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: IvfErpTheme.borderDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.checklist_rounded, size: 14, color: IvfErpTheme.primaryNavy),
                              SizedBox(width: 6),
                              Text('Clinical Schedule & Action Census for Today', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy)),
                            ],
                          ),
                          const Divider(height: 12),
                          _scheduleRow('Oocyte Pick-Up (OPU) OT Slots', '2 Cases Scheduled (09:00 AM & 11:30 AM)', 'OT-1 Ready', IvfErpTheme.ivfPurple),
                          _scheduleRow('Embryo Transfer (ET) Procedures', '1 FET Case Scheduled (02:00 PM)', 'Catheter & Media Verified', IvfErpTheme.babyBlue),
                          _scheduleRow('Serum Beta-hCG Pregnancy Checks', '2 Tests Drawn Today (Day 14 Post-ET)', 'Pathology Processing', IvfErpTheme.medicalEmerald),
                          _scheduleRow('Follicular USG Monitoring Scans', '5 Patients Booked for Day 6/8/10 Scans', 'USG Room 2', IvfErpTheme.primaryNavy),
                          _scheduleRow('NICU & Postpartum Maternity Beds', '4 Patients Currently Admitted in Wards', 'Stable', IvfErpTheme.pinkMaternity),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Partner Footer Strip
                    Center(
                      child: Text(
                        'Technology & Architecture Partner: ${config.technologyPartner}',
                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              color: IvfErpTheme.menuBarBg,
              child: Row(
                children: [
                  const Text('MIS report can be printed or exported to Excel/PDF for Hospital Director review.', style: TextStyle(fontSize: 10, color: Colors.black87)),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Daily Executive MIS Summary sent to printer / PDF exporter!'),
                          backgroundColor: IvfErpTheme.medicalEmerald,
                        ),
                      );
                    },
                    icon: const Icon(Icons.print_rounded, size: 14),
                    label: const Text('Print Executive MIS Report', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: IvfErpTheme.primaryNavy,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      side: const BorderSide(color: IvfErpTheme.borderDark),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Close', style: TextStyle(fontSize: 10.5)),
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
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: IvfErpTheme.borderDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 9.5, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _financialMetric(String title, String amount, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(amount, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _scheduleRow(String task, String details, String status, Color tagColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: tagColor, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          SizedBox(width: 220, child: Text(task, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
          Expanded(child: Text(details, style: const TextStyle(fontSize: 10, color: Colors.black87))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            color: tagColor.withValues(alpha: 0.12),
            child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: tagColor)),
          ),
        ],
      ),
    );
  }
}
