import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/ivf_erp_theme.dart';
import '../../data/repositories/ivf_hospital_repository.dart';
import '../widgets/hospital_logo_widget.dart';
import '../widgets/win32_window_frame.dart';
import 'print_preview_dialog.dart';

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

    return Win32WindowFrame(
      title: 'DAILY OPERATIONAL CENSUS & EXECUTIVE MIS SUMMARY',
      subtitle: '${config.hospitalName} • ${config.activeBranch.branchName}',
      icon: Icons.assessment_rounded,
      defaultWidth: 920,
      defaultHeight: 640,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

            // Letterhead banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFFEBF5FB),
              child: Row(
                children: [
                  HospitalLogoWidget(
                    logoPathOrUrl: config.hospitalLogoUrl,
                    size: 34,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          config.hospitalName.toUpperCase(),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'National ART Act Reg No: ${config.artClinicRegNumber} | GSTIN: ${config.gstin}',
                          style: const TextStyle(fontSize: 9.5, color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
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
                      _openMisPrintPreview(context, currency, totalRevenue, totalPaid, pendingBalance, totalPatients, activeCycles, positiveCycles, deliveredCases, maternityCases);
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
    );
  }

  void _openMisPrintPreview(
    BuildContext context,
    NumberFormat currency,
    double totalRevenue,
    double totalPaid,
    double pendingBalance,
    int totalPatients,
    int activeCycles,
    int positiveCycles,
    int deliveredCases,
    int maternityCases,
  ) {
    PrintPreviewDialog.show(
      context: context,
      config: repo.config,
      documentTitle: 'HOSPITAL OPERATIONAL CENSUS & EXECUTIVE MIS SUMMARY',
      documentSubtitle: 'Daily Medical & Financial Overview for Director & Medical Superintendent',
      documentNumber: 'MIS-${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
      initialPaperFormat: 'A4',
      previewContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: const Color(0xFFF9FAFB),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Active Patients Registered: $totalPatients', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                Text('IVF / ART Cycles: $activeCycles Active ($positiveCycles Positive)', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: IvfErpTheme.ivfPurple)),
                Text('Maternity Deliveries: $deliveredCases / $maternityCases', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: IvfErpTheme.pinkMaternity)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: IvfErpTheme.gridHeaderBg,
            child: const Text('1. FINANCIAL REALIZATION & COLLECTIONS SUMMARY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy)),
          ),
          Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(2), 2: FlexColumnWidth(2), 3: FlexColumnWidth(2)},
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFEBF5FB)),
                children: [
                  _th('Metric Description'),
                  _th('Total Billed'),
                  _th('Collected (Paid)'),
                  _th('Balance Due'),
                ],
              ),
              TableRow(
                children: [
                  _td('OPD, IPD & All-Inclusive IVF Packages'),
                  _td(currency.format(totalRevenue), isBold: true),
                  _td(currency.format(totalPaid), isBold: true, color: IvfErpTheme.medicalEmerald),
                  _td(currency.format(pendingBalance), isBold: true, color: IvfErpTheme.alertRuby),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: IvfErpTheme.gridHeaderBg,
            child: const Text('2. CLINICAL PROCEDURES SCHEDULED TODAY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy)),
          ),
          Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            columnWidths: const {0: FlexColumnWidth(2.5), 1: FlexColumnWidth(3.5), 2: FlexColumnWidth(2)},
            children: [
              TableRow(
                children: [
                  _td('Oocyte Pick-Up (OPU)'),
                  _td('2 Cases Scheduled in Main IVF OT'),
                  _td('09:00 AM & 11:30 AM', color: IvfErpTheme.ivfPurple, isBold: true),
                ],
              ),
              TableRow(
                children: [
                  _td('Embryo Transfer (FET)'),
                  _td('1 Day-5 Blastocyst FET Scheduled'),
                  _td('02:00 PM', color: IvfErpTheme.babyBlue, isBold: true),
                ],
              ),
              TableRow(
                children: [
                  _td('Beta-hCG Serum Tests'),
                  _td('2 Post-ET Pregnancy Blood Draws'),
                  _td('Pathology Drawn', color: IvfErpTheme.medicalEmerald, isBold: true),
                ],
              ),
              TableRow(
                children: [
                  _td('Labour Room & Maternity'),
                  _td('4 Patients in Inpatient Delivery / Postpartum Wards'),
                  _td('Stable / Monitoring', color: IvfErpTheme.pinkMaternity, isBold: true),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _th(String text) {
    return Padding(padding: const EdgeInsets.all(5), child: Text(text, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)));
  }

  static Widget _td(String text, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Text(text, style: TextStyle(fontSize: 9.5, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? Colors.black87)),
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
