import 'package:flutter/material.dart';
import '../../config/ivf_erp_theme.dart';
import '../../data/repositories/ivf_hospital_repository.dart';
import '../widgets/win32_window_frame.dart';
import 'print_preview_dialog.dart';

/// Follicular Monitoring Ultrasound (USG) & Stimulation Day-by-Day Sheet Dialog
class FollicularTrackingDialog extends StatefulWidget {
  final IvfHospitalRepository repo;

  const FollicularTrackingDialog({super.key, required this.repo});

  static Future<void> show(BuildContext context, IvfHospitalRepository repo) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => FollicularTrackingDialog(repo: repo),
    );
  }

  @override
  State<FollicularTrackingDialog> createState() => _FollicularTrackingDialogState();
}

class _FollicularTrackingDialogState extends State<FollicularTrackingDialog> {
  String? _selectedCycleId;

  // Day-wise scan monitoring logs (Mock pre-seeded serial records)
  final List<Map<String, dynamic>> _scanRows = [
    {
      'day': 'Day 2 (Baseline)',
      'date': '04-Oct-2026',
      'rightOvary': 'AFC: 8 (4-6mm)',
      'leftOvary': 'AFC: 7 (3-5mm)',
      'endoMm': '3.2 mm',
      'endoPattern': 'Linear (Type C)',
      'e2': '42 pg/mL',
      'p4': '0.3 ng/mL',
      'dose': 'Gonal-F 225 IU',
      'notes': 'Baseline clear. Started stimulation.',
    },
    {
      'day': 'Day 6',
      'date': '08-Oct-2026',
      'rightOvary': '11, 10, 9, 9 mm',
      'leftOvary': '12, 10, 8 mm',
      'endoMm': '6.4 mm',
      'endoPattern': 'Triple Line (Type A)',
      'e2': '380 pg/mL',
      'p4': '0.4 ng/mL',
      'dose': 'Gonal-F 225 IU + Menopur 75 IU',
      'notes': 'Good ovarian response bilaterally.',
    },
    {
      'day': 'Day 8',
      'date': '10-Oct-2026',
      'rightOvary': '14, 13, 12, 11 mm',
      'leftOvary': '15, 13, 11 mm',
      'endoMm': '7.8 mm',
      'endoPattern': 'Triple Line (Type A)',
      'e2': '890 pg/mL',
      'p4': '0.5 ng/mL',
      'dose': 'Gonal-F + Menopur + Cetrotide 0.25mg',
      'notes': 'Added GnRH Antagonist (Cetrotide) to prevent premature LH surge.',
    },
    {
      'day': 'Day 10',
      'date': '12-Oct-2026',
      'rightOvary': '17, 16, 15, 13 mm',
      'leftOvary': '18, 15, 14 mm',
      'endoMm': '8.9 mm',
      'endoPattern': 'Triple Line (Type A)',
      'e2': '1740 pg/mL',
      'p4': '0.7 ng/mL',
      'dose': 'Same doses continued',
      'notes': 'Lead follicles approaching maturity (>17mm).',
    },
    {
      'day': 'Day 11 (Trigger Day)',
      'date': '13-Oct-2026',
      'rightOvary': '19, 18, 16, 15 mm',
      'leftOvary': '20, 17, 16 mm',
      'endoMm': '9.6 mm',
      'endoPattern': 'Triple Line (Type A)',
      'e2': '2650 pg/mL',
      'p4': '0.9 ng/mL',
      'dose': 'Inj. Ovitrelle 250 mcg at 22:30 hrs',
      'notes': 'Trigger given at 22:30 hrs. OPU scheduled on Day 13 at 09:30 hrs (35h later).',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.repo.ivfCycles.isNotEmpty) {
      _selectedCycleId = widget.repo.ivfCycles.first.cycleId;
    }
  }

  void _printFollicularChart() {
    final cycle = widget.repo.ivfCycles.isNotEmpty
        ? widget.repo.ivfCycles.firstWhere(
            (c) => c.cycleId == _selectedCycleId,
            orElse: () => widget.repo.ivfCycles.first,
          )
        : null;
    final config = widget.repo.config;
    PrintPreviewDialog.show(
      context: context,
      config: config,
      documentTitle: 'FOLLICULAR ULTRASOUND MONITORING & STIMULATION SHEET',
      documentSubtitle: 'Serial Ovarian Response & Endometrial Receptivity Chart',
      documentNumber: cycle != null ? 'CYC-${cycle.cycleId}' : 'SCAN-RECORD',
      initialPaperFormat: 'A4',
      previewContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              border: Border.all(color: const Color(0xFFCCCCCC)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PATIENT: ${cycle?.patientName.toUpperCase() ?? "TEST PATIENT"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      Text('CYCLE ID: ${cycle?.cycleId ?? "N/A"}  |  PROTOCOL: ${cycle?.protocol ?? "Antagonist Protocol"}', style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('OPU PLANNED: ${cycle?.opuDate != null ? cycle!.opuDate.toString().split(' ')[0] : "TBD"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF8E44AD))),
                    Text('IN-CHARGE: ${config.activeBranch.doctorInCharge}', style: const TextStyle(fontSize: 9.5)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            color: const Color(0xFF4A148C),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Day / Date', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('Right Ovary Follicles', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('Left Ovary Follicles', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Endometrium', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('E2 (pg/mL)', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('Stimulation Dosage', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          ..._scanRows.map((r) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('${r['day']}\n${r['date']}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text(r['rightOvary'], style: const TextStyle(fontSize: 9))),
                Expanded(flex: 3, child: Text(r['leftOvary'], style: const TextStyle(fontSize: 9))),
                Expanded(flex: 2, child: Text('${r['endoMm']}\n${r['endoPattern']}', style: const TextStyle(fontSize: 9))),
                Expanded(flex: 2, child: Text(r['e2'], style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text(r['dose'], style: const TextStyle(fontSize: 9))),
              ],
            ),
          )),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            color: const Color(0xFFFCF3CF),
            child: const Text(
              'CLINICAL ADVICE & TRIGGER DECISION:\nLead cohort >18mm reached. Trigger with Inj Ovitrelle 250mcg. Egg retrieval (OPU) strict 35 hours post-trigger. Patient fasting strictly from midnight.',
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF7D6608)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Win32WindowFrame(
      title: 'FOLLICULAR MONITORING ULTRASOUND (USG) & SERIAL STIMULATION SHEET',
      subtitle: '${widget.repo.config.hospitalName} • ${widget.repo.config.activeBranch.branchName}',
      icon: Icons.show_chart_rounded,
      defaultWidth: 1050,
      defaultHeight: 680,
      child: Column(
        children: [

            // Cycle Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: const Color(0xFFF4ECF7),
              child: Row(
                children: [
                  const Text('Active IVF Cycle: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: IvfErpTheme.borderDark)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: widget.repo.ivfCycles.any((c) => c.cycleId == _selectedCycleId)
                              ? _selectedCycleId
                              : (widget.repo.ivfCycles.isNotEmpty ? widget.repo.ivfCycles.first.cycleId : null),
                          isDense: true,
                          isExpanded: true,
                          items: widget.repo.ivfCycles.map((c) {
                            return DropdownMenuItem(
                              value: c.cycleId,
                              child: Text('${c.cycleId} — ${c.patientName} (${c.protocol})', overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedCycleId = v),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 14),
                    label: const Text('+ Add Daily Scan Entry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: IvfErpTheme.ivfPurple,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Add Scan entry modal opened.')),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Follicular Monitoring DataGrid
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: IvfErpTheme.borderDark)),
                child: ListView.builder(
                  itemCount: _scanRows.length + 1,
                  itemBuilder: (context, idx) {
                    if (idx == 0) {
                      return Container(
                        height: 28,
                        color: IvfErpTheme.gridHeaderBg,
                        child: const Row(
                          children: [
                            SizedBox(width: 110, child: Text('Cycle Day', style: IvfErpTheme.gridHeaderStyle)),
                            SizedBox(width: 90, child: Text('Date', style: IvfErpTheme.gridHeaderStyle)),
                            Expanded(flex: 2, child: Text('Right Ovary Follicles (mm)', style: IvfErpTheme.gridHeaderStyle)),
                            Expanded(flex: 2, child: Text('Left Ovary Follicles (mm)', style: IvfErpTheme.gridHeaderStyle)),
                            SizedBox(width: 80, child: Text('Endo (mm)', style: IvfErpTheme.gridHeaderStyle)),
                            SizedBox(width: 120, child: Text('Endo Pattern', style: IvfErpTheme.gridHeaderStyle)),
                            SizedBox(width: 90, child: Text('Serum E2', textAlign: TextAlign.right, style: IvfErpTheme.gridHeaderStyle)),
                            Expanded(flex: 2, child: Text('Daily Injections Dose', style: IvfErpTheme.gridHeaderStyle)),
                          ],
                        ),
                      );
                    }

                    final r = _scanRows[idx - 1];
                    final isTrigger = r['day'].toString().contains('Trigger');

                    return Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: isTrigger
                            ? const Color(0xFFFCF3CF)
                            : (idx.isEven ? IvfErpTheme.gridRowEven : IvfErpTheme.gridRowOdd),
                        border: const Border(bottom: BorderSide(color: Color(0xFFEAEDED))),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 110, child: Text(r['day'], style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: isTrigger ? const Color(0xFF7D6608) : IvfErpTheme.primaryNavy))),
                          SizedBox(width: 90, child: Text(r['date'], style: const TextStyle(fontSize: 10))),
                          Expanded(flex: 2, child: Text(r['rightOvary'], style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600))),
                          Expanded(flex: 2, child: Text(r['leftOvary'], style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text(r['endoMm'], style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
                          SizedBox(width: 120, child: Text(r['endoPattern'], style: const TextStyle(fontSize: 10, color: IvfErpTheme.medicalEmerald, fontWeight: FontWeight.bold))),
                          SizedBox(width: 90, child: Text(r['e2'], textAlign: TextAlign.right, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text(r['dose'], overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: isTrigger ? FontWeight.bold : FontWeight.normal, color: isTrigger ? IvfErpTheme.alertRuby : IvfErpTheme.textMain))),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Trigger & OPU Planning Summary Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFFFCF3CF),
              child: const Row(
                children: [
                  Icon(Icons.alarm_on_rounded, size: 20, color: Color(0xFF7D6608)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'TRIGGER INSTRUCTION: Inj. Ovitrelle 250 mcg administered on Day 11 at 22:30 hrs. OPU / Egg Retrieval scheduled on Day 13 at 09:30 hrs (Exact 35 hours post-trigger window).',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF7D6608)),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Actions Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: IvfErpTheme.menuBarBg,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.print_rounded, size: 14),
                    label: const Text('Print Follicular Tracking Chart (A4)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: IvfErpTheme.ivfPurple,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: _printFollicularChart,
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close Tracking Sheet'),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }
}
