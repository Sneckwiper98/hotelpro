import 'package:flutter/material.dart';
import '../../config/ivf_erp_theme.dart';
import '../../data/repositories/ivf_hospital_repository.dart';
import '../widgets/win32_window_frame.dart';
import 'patient_record_360_dialog.dart';
import 'print_preview_dialog.dart';

/// OPD Token Queue & Daily Consultation Management (PDF Section 28 & 30)
class OpdTokenQueueDialog extends StatefulWidget {
  final IvfHospitalRepository repo;

  const OpdTokenQueueDialog({super.key, required this.repo});

  static Future<void> show(BuildContext context, IvfHospitalRepository repo) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => OpdTokenQueueDialog(repo: repo),
    );
  }

  @override
  State<OpdTokenQueueDialog> createState() => _OpdTokenQueueDialogState();
}

class _OpdTokenQueueDialogState extends State<OpdTokenQueueDialog> {
  String _selectedDoctor = 'All Doctors';
  String _filterStatus = 'ALL';

  // Sample active OPD queue tokens
  final List<Map<String, dynamic>> _queue = [
    {
      'token': 'TK-01',
      'uhid': 'SRH-P-2026-001',
      'patient': 'Sunita Sharma (31y / F)',
      'doctor': 'Dr. Sunita Rao, MD (OBGYN, IVF Specialist)',
      'category': 'IVF Stimulation Monitoring',
      'status': 'IN_CONSULTATION',
      'time': '09:15 AM',
    },
    {
      'token': 'TK-02',
      'uhid': 'SRH-P-2026-002',
      'patient': 'Pooja Verma (28y / F)',
      'doctor': 'Dr. Sunita Rao, MD (OBGYN, IVF Specialist)',
      'category': 'Follicular USG Tracking',
      'status': 'WAITING',
      'time': '09:30 AM',
    },
    {
      'token': 'TK-03',
      'uhid': 'SRH-P-2026-003',
      'patient': 'Meera Patel (34y / F)',
      'doctor': 'Dr. Rajesh Deshmukh, MS (Gynec & Obstetrician)',
      'category': 'High-Risk Antenatal (ANC) Check',
      'status': 'WAITING',
      'time': '09:45 AM',
    },
    {
      'token': 'TK-04',
      'uhid': 'SRH-P-2026-004',
      'patient': 'Ananya Kulkarni (29y / F)',
      'doctor': 'Dr. Sunita Rao, MD (OBGYN, IVF Specialist)',
      'category': 'First Infertility Consultation',
      'status': 'WAITING',
      'time': '10:00 AM',
    },
    {
      'token': 'TK-05',
      'uhid': 'SRH-P-2026-005',
      'patient': 'Kavita Joshi (32y / F)',
      'doctor': 'Dr. Rajesh Deshmukh, MS (Gynec & Obstetrician)',
      'category': 'Routine Gynec & USG Pelvis',
      'status': 'COMPLETED',
      'time': '08:45 AM',
    },
  ];

  void _printQueueSchedule() {
    final config = widget.repo.config;
    PrintPreviewDialog.show(
      context: context,
      config: config,
      documentTitle: 'OPD APPOINTMENT SCHEDULE & TOKEN QUEUE SHEET',
      documentSubtitle: 'Daily Outpatient Department Clinical Roster',
      documentNumber: 'OPD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      initialPaperFormat: 'A4',
      previewContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: const Color(0xFFEBF5FB),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Date: ${DateTime.now().toString().split(' ')[0]}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5)),
                Text('Total Tokens: ${_queue.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: Color(0xFF003366))),
                Text('Filter Doctor: $_selectedDoctor', style: const TextStyle(fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            color: const Color(0xFF003366),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Token', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 4, child: Text('Patient / UHID', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 4, child: Text('Consulting Doctor', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('Category', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Time', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Status', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          ..._queue.map((q) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text(q['token'], style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 4, child: Text('${q['patient']}\n(${q['uhid']})', style: const TextStyle(fontSize: 9))),
                Expanded(flex: 4, child: Text(q['doctor'], style: const TextStyle(fontSize: 8.5))),
                Expanded(flex: 3, child: Text(q['category'], style: const TextStyle(fontSize: 8.5))),
                Expanded(flex: 2, child: Text(q['time'], style: const TextStyle(fontSize: 8.5))),
                Expanded(flex: 2, child: Text(q['status'], style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: q['status'] == 'WAITING' ? const Color(0xFFC0392B) : const Color(0xFF27AE60)))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _queue.where((t) {
      if (_selectedDoctor != 'All Doctors' && t['doctor'] != _selectedDoctor) return false;
      if (_filterStatus != 'ALL' && t['status'] != _filterStatus) return false;
      return true;
    }).toList();

    final waitingCount = _queue.where((t) => t['status'] == 'WAITING').length;
    final inConsultCount = _queue.where((t) => t['status'] == 'IN_CONSULTATION').length;
    final completedCount = _queue.where((t) => t['status'] == 'COMPLETED').length;

    return Win32WindowFrame(
      title: 'OPD APPOINTMENT & TOKEN QUEUE MANAGER (PDF Section 28 & 30)',
      subtitle: '${widget.repo.config.hospitalName} • ${widget.repo.config.activeBranch.branchName}',
      icon: Icons.people_alt_rounded,
      defaultWidth: 1040,
      defaultHeight: 680,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

            // Top Metrics Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: const Color(0xFFEAECEE),
              child: Row(
                children: [
                  _statusCard('Waiting Patients', '$waitingCount', IvfErpTheme.alertRuby, const Color(0xFFFADBD8)),
                  const SizedBox(width: 8),
                  _statusCard('In Consultation', '$inConsultCount', IvfErpTheme.primaryNavy, const Color(0xFFD6EAF8)),
                  const SizedBox(width: 8),
                  _statusCard('Completed Today', '$completedCount', IvfErpTheme.medicalEmerald, const Color(0xFFD4EFDF)),
                  const Spacer(),
                  // Filter by Doctor
                  const Text('Doctor Filter: ', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                  Container(
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: IvfErpTheme.borderDark)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedDoctor,
                        isDense: true,
                        style: const TextStyle(fontSize: 10.5, color: Colors.black87),
                        items: const [
                          DropdownMenuItem(value: 'All Doctors', child: Text('All Doctors')),
                          DropdownMenuItem(value: 'Dr. Sunita Rao, MD (OBGYN, IVF Specialist)', child: Text('Dr. Sunita Rao (IVF)')),
                          DropdownMenuItem(value: 'Dr. Rajesh Deshmukh, MS (Gynec & Obstetrician)', child: Text('Dr. Rajesh Deshmukh (Gynec)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedDoctor = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Filter by Status
                  Container(
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: IvfErpTheme.borderDark)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filterStatus,
                        isDense: true,
                        style: const TextStyle(fontSize: 10.5, color: Colors.black87),
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('All Statuses')),
                          DropdownMenuItem(value: 'WAITING', child: Text('Waiting')),
                          DropdownMenuItem(value: 'IN_CONSULTATION', child: Text('In Consultation')),
                          DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _filterStatus = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Queue DataGrid
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: IvfErpTheme.borderDark),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 28,
                      color: IvfErpTheme.gridHeaderBg,
                      child: const Row(
                        children: [
                          SizedBox(width: 60, child: Text('Token #', textAlign: TextAlign.center, style: IvfErpTheme.gridHeaderStyle)),
                          SizedBox(width: 100, child: Text('UHID', style: IvfErpTheme.gridHeaderStyle)),
                          Expanded(flex: 3, child: Text('Patient Name & Age', style: IvfErpTheme.gridHeaderStyle)),
                          Expanded(flex: 3, child: Text('Attending Doctor', style: IvfErpTheme.gridHeaderStyle)),
                          Expanded(flex: 3, child: Text('Clinical Category', style: IvfErpTheme.gridHeaderStyle)),
                          SizedBox(width: 80, child: Text('Appt Time', textAlign: TextAlign.center, style: IvfErpTheme.gridHeaderStyle)),
                          SizedBox(width: 110, child: Text('Queue Status', textAlign: TextAlign.center, style: IvfErpTheme.gridHeaderStyle)),
                          SizedBox(width: 130, child: Text('Quick Action', textAlign: TextAlign.center, style: IvfErpTheme.gridHeaderStyle)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, idx) {
                          final item = filtered[idx];
                          final status = item['status'] as String;
                          Color badgeBg;
                          Color badgeFg;
                          String badgeText;

                          if (status == 'IN_CONSULTATION') {
                            badgeBg = const Color(0xFFD6EAF8);
                            badgeFg = IvfErpTheme.primaryNavy;
                            badgeText = 'In Consultation';
                          } else if (status == 'WAITING') {
                            badgeBg = const Color(0xFFFADBD8);
                            badgeFg = IvfErpTheme.alertRuby;
                            badgeText = 'Waiting (Queue)';
                          } else {
                            badgeBg = const Color(0xFFD4EFDF);
                            badgeFg = IvfErpTheme.medicalEmerald;
                            badgeText = 'Consult Completed';
                          }

                          return Container(
                            height: 34,
                            color: idx.isEven ? IvfErpTheme.gridRowEven : IvfErpTheme.gridRowOdd,
                            child: Row(
                              children: [
                                SizedBox(width: 60, child: Text(item['token'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy))),
                                SizedBox(width: 100, child: Text(item['uhid'], style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
                                Expanded(flex: 3, child: Text(item['patient'], overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
                                Expanded(flex: 3, child: Text(item['doctor'], overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10))),
                                Expanded(flex: 3, child: Text(item['category'], overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: IvfErpTheme.ivfPurple, fontWeight: FontWeight.w600))),
                                SizedBox(width: 80, child: Text(item['time'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 10))),
                                SizedBox(
                                  width: 110,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      color: badgeBg,
                                      child: Text(badgeText, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: badgeFg)),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 130,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (status == 'WAITING')
                                        InkWell(
                                          onTap: () {
                                            setState(() => item['status'] = 'IN_CONSULTATION');
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                            decoration: BoxDecoration(color: IvfErpTheme.primaryNavy, borderRadius: BorderRadius.circular(2)),
                                            child: const Text('Call In', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      if (status == 'IN_CONSULTATION') ...[
                                        InkWell(
                                          onTap: () {
                                            // Open 360 Patient Record
                                            final pat = widget.repo.patients.firstWhere((p) => p.uhid == item['uhid'], orElse: () => widget.repo.patients.first);
                                            PatientRecord360Dialog.show(context, pat, widget.repo);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                            decoration: BoxDecoration(color: IvfErpTheme.ivfPurple, borderRadius: BorderRadius.circular(2)),
                                            child: const Text('Rx / File', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap: () {
                                            setState(() => item['status'] = 'COMPLETED');
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                            decoration: BoxDecoration(color: IvfErpTheme.medicalEmerald, borderRadius: BorderRadius.circular(2)),
                                            child: const Text('Done', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                      if (status == 'COMPLETED')
                                        const Text('Finished', style: TextStyle(fontSize: 9.5, color: Colors.grey, fontStyle: FontStyle.italic)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              color: IvfErpTheme.menuBarBg,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.print_rounded, size: 14),
                    label: const Text('Print OPD Token Queue (A4)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: IvfErpTheme.primaryNavy,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: _printQueueSchedule,
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      side: const BorderSide(color: IvfErpTheme.borderDark),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    ),
                    child: const Text('Close', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _statusCard(String label, String count, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, border: Border.all(color: fg.withValues(alpha: 0.3))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          Text(count, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
        ],
      ),
    );
  }
}
