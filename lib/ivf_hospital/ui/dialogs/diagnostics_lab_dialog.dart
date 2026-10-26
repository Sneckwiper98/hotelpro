import 'package:flutter/material.dart';
import '../../config/ivf_erp_theme.dart';
import '../../data/repositories/ivf_hospital_repository.dart';
import '../widgets/win32_window_frame.dart';
import 'print_preview_dialog.dart';

/// Diagnostics, Hormone Pathology & Semen Analysis Dialog
class DiagnosticsLabDialog extends StatelessWidget {
  final IvfHospitalRepository repo;

  const DiagnosticsLabDialog({super.key, required this.repo});

  static Future<void> show(BuildContext context, IvfHospitalRepository repo) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DiagnosticsLabDialog(repo: repo),
    );
  }

  void _printLabRegister(BuildContext context) {
    final tests = repo.labInvestigations;
    final config = repo.config;

    PrintPreviewDialog.show(
      context: context,
      config: config,
      documentTitle: 'PATHOLOGY & ENDOCRINE LABORATORY TEST REGISTER',
      documentSubtitle: 'Hormone Assays, Serology & Biochemical Analysis Report',
      documentNumber: 'LAB-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
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
                Text('Total Investigations: ${tests.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5)),
                Text('Pathologist: Dr. Sunita Deshmukh, MD Path', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: Color(0xFF003366))),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            color: const Color(0xFF003366),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Order ID', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 4, child: Text('Patient / UHID', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 4, child: Text('Test Name', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 4, child: Text('Measured Result', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Status', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          ...tests.map((t) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text(t.orderId, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 4, child: Text('${t.patientName}\n(${t.patientUhid})', style: const TextStyle(fontSize: 9))),
                Expanded(flex: 4, child: Text(t.testName, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                Expanded(flex: 4, child: Text('${t.resultValue} ${t.unit}', style: const TextStyle(fontSize: 9.5, color: Color(0xFF27AE60), fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text(t.status, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFF27AE60)))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tests = repo.labInvestigations;

    return Win32WindowFrame(
      title: 'LABORATORY & DIAGNOSTIC PATHOLOGY REGISTER',
      subtitle: '${repo.config.hospitalName} • ${repo.config.activeBranch.branchName}',
      icon: Icons.biotech_rounded,
      defaultWidth: 980,
      defaultHeight: 660,
      child: Column(
        children: [

            // Data Table
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(border: Border.all(color: IvfErpTheme.borderDark)),
                child: ListView.builder(
                  itemCount: tests.length + 1,
                  itemBuilder: (context, idx) {
                    if (idx == 0) {
                      return Container(
                        height: 28,
                        color: IvfErpTheme.gridHeaderBg,
                        child: const Row(
                          children: [
                            SizedBox(width: 35, child: Text('#', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                            SizedBox(width: 100, child: Text('Order ID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                            SizedBox(width: 85, child: Text('UHID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('Patient / Couple Name', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('Test / Investigation', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                            Expanded(flex: 3, child: Text('Measured Result Value', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                            SizedBox(width: 80, child: Text('Status', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      );
                    }

                    final t = tests[idx - 1];
                    return Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: idx.isEven ? IvfErpTheme.gridRowEven : IvfErpTheme.gridRowOdd,
                        border: const Border(bottom: BorderSide(color: Color(0xFFEAEDED))),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 35, child: Text('$idx', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10))),
                          SizedBox(width: 100, child: Text(t.orderId, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy))),
                          SizedBox(width: 85, child: Text(t.patientUhid, style: const TextStyle(fontSize: 10))),
                          Expanded(flex: 2, child: Text(t.patientName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600))),
                          Expanded(flex: 2, child: Text(t.testName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
                          Expanded(flex: 3, child: Text('${t.resultValue} ${t.unit}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: IvfErpTheme.medicalEmerald, fontWeight: FontWeight.bold))),
                          SizedBox(
                            width: 80,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                color: const Color(0xFFD4EFDF),
                                child: Text(t.status, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: IvfErpTheme.medicalEmerald)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
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
                    label: const Text('Print Diagnostic Register (A4)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: IvfErpTheme.primaryNavy,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: () => _printLabRegister(context),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close Window'),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }
}
