import 'package:flutter/material.dart';
import '../../config/ivf_erp_theme.dart';
import '../../data/repositories/ivf_hospital_repository.dart';

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
  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final dialogWidth = (screen.width * 0.90).clamp(780.0, 960.0);
    final dialogHeight = (screen.height * 0.88).clamp(500.0, 660.0);

    final beds = widget.repo.beds;
    final occupiedCount = beds.where((b) => b.isOccupied).length;
    final availableCount = beds.length - occupiedCount;

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
              color: IvfErpTheme.primaryNavy,
              child: Row(
                children: [
                  const Icon(Icons.hotel_rounded, size: 15, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Hospital Inpatient (IPD) Wards & Bed Occupancy Matrix — ${widget.repo.config.hospitalName}',
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
