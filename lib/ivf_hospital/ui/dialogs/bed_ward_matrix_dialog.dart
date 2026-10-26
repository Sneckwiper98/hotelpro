import 'package:flutter/material.dart';
import '../../config/ivf_erp_theme.dart';
import '../../data/repositories/ivf_hospital_repository.dart';
import '../widgets/win32_window_frame.dart';
import 'print_preview_dialog.dart';

/// Inpatient (IPD) Bed & Ward Occupancy Matrix Dialog
class BedWardMatrixDialog extends StatefulWidget {
  final IvfHospitalRepository repo;

  const BedWardMatrixDialog({super.key, required this.repo});

  static Future<void> show(BuildContext context, IvfHospitalRepository repo) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => BedWardMatrixDialog(repo: repo),
    );
  }

  @override
  State<BedWardMatrixDialog> createState() => _BedWardMatrixDialogState();
}

class _BedWardMatrixDialogState extends State<BedWardMatrixDialog> {
  void _printBedCensus() {
    final beds = widget.repo.beds;
    final occupied = beds.where((b) => b.isOccupied).length;
    final available = beds.length - occupied;
    final config = widget.repo.config;

    PrintPreviewDialog.show(
      context: context,
      config: config,
      documentTitle: 'INPATIENT (IPD) WARD & BED OCCUPANCY CENSUS',
      documentSubtitle: 'Daily Inpatient Midnight / Current Census Report',
      documentNumber: 'BED-CENSUS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      initialPaperFormat: 'A4',
      previewContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: const Color(0xFFEBF5FB),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('Total Beds: ${beds.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                Text('Occupied: $occupied', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFC0392B))),
                Text('Available Vacant: $available', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF27AE60))),
                Text('Occupancy Rate: ${((occupied / (beds.isEmpty ? 1 : beds.length)) * 100).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF003366))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            color: const Color(0xFF003366),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Bed No.', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('Ward / Category', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 4, child: Text('Current Patient / UHID', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('Status', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Daily Tariff', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          ...beds.map((b) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text(b.bedNumber, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text(b.wardName, style: const TextStyle(fontSize: 9))),
                Expanded(flex: 4, child: Text(b.isOccupied ? '${b.patientName ?? "Patient"}\n(UHID: ${b.patientUhid ?? "N/A"})' : '— Vacant —', style: TextStyle(fontSize: 9, fontStyle: b.isOccupied ? FontStyle.normal : FontStyle.italic))),
                Expanded(flex: 3, child: Text(b.isOccupied ? 'OCCUPIED' : 'AVAILABLE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: b.isOccupied ? const Color(0xFFC0392B) : const Color(0xFF27AE60)))),
                Expanded(flex: 2, child: Text('₹${b.dailyCharges.toStringAsFixed(0)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 9.5))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final beds = widget.repo.beds;
    final occupiedCount = beds.where((b) => b.isOccupied).length;
    final availableCount = beds.length - occupiedCount;

    return Win32WindowFrame(
      title: 'HOSPITAL INPATIENT (IPD) WARDS & BED OCCUPANCY MATRIX',
      subtitle: '${widget.repo.config.hospitalName} • ${widget.repo.config.activeBranch.branchName}',
      icon: Icons.hotel_rounded,
      defaultWidth: 980,
      defaultHeight: 660,
      child: Column(
        children: [

            // Top Occupancy Metrics
            Container(
              padding: const EdgeInsets.all(8),
              color: const Color(0xFFEBF5FB),
              child: Row(
                children: [
                  _metricCard('Total Hospital Beds', '${beds.length} Beds', Icons.single_bed_rounded, IvfErpTheme.primaryNavy),
                  const SizedBox(width: 8),
                  _metricCard('Occupied Beds', '$occupiedCount Occupied', Icons.airline_seat_flat_rounded, IvfErpTheme.pinkMaternity),
                  const SizedBox(width: 8),
                  _metricCard('Available Vacant Beds', '$availableCount Available', Icons.check_circle_outline_rounded, IvfErpTheme.medicalEmerald),
                ],
              ),
            ),

            // Visual Bed Cards Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: beds.length,
                  itemBuilder: (context, idx) {
                    final b = beds[idx];
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: b.isOccupied ? IvfErpTheme.alertRuby : IvfErpTheme.medicalEmerald,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                b.isOccupied ? Icons.airline_seat_flat_rounded : Icons.check_circle_rounded,
                                size: 16,
                                color: b.isOccupied ? IvfErpTheme.alertRuby : IvfErpTheme.medicalEmerald,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  b.bedNumber,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                color: b.isOccupied ? const Color(0xFFFADBD8) : const Color(0xFFD4EFDF),
                                child: Text(
                                  b.isOccupied ? 'OCCUPIED' : 'VACANT',
                                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: b.isOccupied ? IvfErpTheme.alertRuby : IvfErpTheme.medicalEmerald),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(b.wardName, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          if (b.isOccupied) ...[
                            Text('Patient: ${b.occupiedByPatientName}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: IvfErpTheme.textMain)),
                            Text('UHID: ${b.occupiedByUhid}', style: const TextStyle(fontSize: 9.5, color: IvfErpTheme.textMuted)),
                          ] else ...[
                            const Text('Ready for Patient Admission', style: TextStyle(fontSize: 10, color: IvfErpTheme.medicalEmerald, fontWeight: FontWeight.bold)),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    b.isOccupied = !b.isOccupied;
                                    if (!b.isOccupied) {
                                      b.occupiedByPatientName = null;
                                      b.occupiedByUhid = null;
                                    } else {
                                      b.occupiedByPatientName = 'Admitted Patient';
                                      b.occupiedByUhid = 'SRH-P-AUTO';
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  color: IvfErpTheme.menuBarBg,
                                  child: Text(
                                    b.isOccupied ? 'Discharge / Release' : 'Admit Patient',
                                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy),
                                  ),
                                ),
                              ),
                            ],
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
                    label: const Text('Print Bed Census Summary (A4)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: IvfErpTheme.primaryNavy,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: _printBedCensus,
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close Matrix'),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: IvfErpTheme.borderLight)),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, color: IvfErpTheme.textMuted, fontWeight: FontWeight.w600)),
                  Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
