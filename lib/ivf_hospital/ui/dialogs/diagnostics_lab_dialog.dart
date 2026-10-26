import 'package:flutter/material.dart';
import '../../config/ivf_erp_theme.dart';
import '../../data/repositories/ivf_hospital_repository.dart';

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

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final dialogWidth = (screen.width * 0.90).clamp(780.0, 960.0);
    final dialogHeight = (screen.height * 0.88).clamp(500.0, 650.0);

    final tests = repo.labInvestigations;

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
              color: IvfErpTheme.primaryNavy,
              child: Row(
                children: [
                  const Icon(Icons.biotech_rounded, size: 15, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Laboratory & Diagnostic Pathology Register — ${repo.config.hospitalName}',
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
      ),
    );
  }
}
