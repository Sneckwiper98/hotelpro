import 'package:flutter/material.dart';
import '../../config/ivf_erp_theme.dart';
import '../../data/models/ivf_cycle_model.dart';
import '../../data/repositories/ivf_hospital_repository.dart';

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
  IvfCycleModel? _selectedCycle;

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
      _selectedCycle = widget.repo.ivfCycles.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final dialogWidth = (screen.width * 0.94).clamp(860.0, 1160.0);
    final dialogHeight = (screen.height * 0.90).clamp(520.0, 700.0);

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
            // Win32 Title Bar
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              color: IvfErpTheme.ivfPurple,
              child: Row(
                children: [
                  const Icon(Icons.show_chart_rounded, size: 15, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Follicular Monitoring Ultrasound (USG) & Serial Stimulation Sheet — IVFPro Win32 ERP',
                    style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 15, color: Colors.white),
                  ),
                ],
              ),
            ),

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
                      height: 26,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: IvfErpTheme.borderDark)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<IvfCycleModel>(
                          value: _selectedCycle,
                          isDense: true,
                          isExpanded: true,
                          items: widget.repo.ivfCycles.map((c) {
                            return DropdownMenuItem(value: c, child: Text('${c.cycleId} — ${c.patientName} (${c.protocol})'));
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedCycle = v),
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
      ),
    );
  }
}
