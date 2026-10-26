import 'package:flutter/material.dart';
import '../../config/ivf_erp_theme.dart';
import '../../data/repositories/ivf_hospital_repository.dart';

/// Cryopreservation, Vitrification & Liquid Nitrogen Tank Inventory Dialog
class CryoStorageDialog extends StatefulWidget {
  final IvfHospitalRepository repo;

  const CryoStorageDialog({super.key, required this.repo});

  static Future<void> show(BuildContext context, IvfHospitalRepository repo) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CryoStorageDialog(repo: repo),
    );
  }

  @override
  State<CryoStorageDialog> createState() => _CryoStorageDialogState();
}

class _CryoStorageDialogState extends State<CryoStorageDialog> {
  String _tankFilter = 'ALL';

  final List<Map<String, dynamic>> _cryoInventory = [
    {
      'strawId': 'STR-2026-9021',
      'tank': 'Tank 1 (LN2 -196°C)',
      'canister': 'Canister 2',
      'goblet': 'Goblet Green #04',
      'uhid': 'SRH-P-1001',
      'patientName': 'Snehal Deshmukh',
      'specimen': '4 x Day 5 Blastocysts (4AA, 4AB)',
      'freezeDate': '11-Oct-2026',
      'embryologist': 'Dr. Rajesh Patel',
      'status': 'FROZEN / STORED',
    },
    {
      'strawId': 'STR-2026-8821',
      'tank': 'Tank 2 (LN2 -196°C)',
      'canister': 'Canister 3',
      'goblet': 'Goblet Yellow #12',
      'uhid': 'SRH-P-1003',
      'patientName': 'Kavita Chawla',
      'specimen': '3 x Day 3 Cleavage Embryos (Grade A)',
      'freezeDate': '18-Oct-2026',
      'embryologist': 'Dr. Rajesh Patel',
      'status': 'FROZEN / STORED',
    },
    {
      'strawId': 'STR-2025-4102',
      'tank': 'Tank 1 (LN2 -196°C)',
      'canister': 'Canister 1',
      'goblet': 'Goblet Blue #01',
      'uhid': 'SRH-P-1002',
      'patientName': 'Priyanka Kulkarni',
      'specimen': '2 x Blastocysts (FET Successful - Delivered)',
      'freezeDate': '15-Nov-2025',
      'embryologist': 'Dr. Rajesh Patel',
      'status': 'THAWED & TRANSFERRED',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final dialogWidth = (screen.width * 0.94).clamp(840.0, 1140.0);
    final dialogHeight = (screen.height * 0.90).clamp(520.0, 680.0);

    final filtered = _cryoInventory.where((item) {
      if (_tankFilter != 'ALL' && !item['tank'].toString().contains(_tankFilter)) return false;
      return true;
    }).toList();

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
              color: const Color(0xFF1B4F72),
              child: Row(
                children: [
                  const Icon(Icons.ac_unit_rounded, size: 15, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Cryopreservation, Vitrification & Liquid Nitrogen (LN2) Tank Storage — ${widget.repo.config.hospitalName}',
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

            // Tank Summary Metric Cards
            Container(
              padding: const EdgeInsets.all(8),
              color: const Color(0xFFEBF5FB),
              child: Row(
                children: [
                  _metricCard('Tank 1 Status (35L LN2)', 'Temp: -196°C • Level: 92%', Icons.science_rounded, IvfErpTheme.medicalEmerald),
                  const SizedBox(width: 8),
                  _metricCard('Tank 2 Status (35L LN2)', 'Temp: -196°C • Level: 88%', Icons.science_rounded, IvfErpTheme.medicalEmerald),
                  const SizedBox(width: 8),
                  _metricCard('Total Cryopreserved Straws', '${_cryoInventory.length} Straws Active', Icons.inventory_2_rounded, IvfErpTheme.primaryNavy),
                ],
              ),
            ),

            // Filter Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: IvfErpTheme.toolbarBg,
              child: Row(
                children: [
                  const Text('Filter by Cryo Tank: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: IvfErpTheme.borderDark)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _tankFilter,
                        isDense: true,
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('All Tanks (1 & 2)')),
                          DropdownMenuItem(value: 'Tank 1', child: Text('Tank 1 Only')),
                          DropdownMenuItem(value: 'Tank 2', child: Text('Tank 2 Only')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _tankFilter = v);
                        },
                      ),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 14),
                    label: const Text('+ Cryo Straw Entry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: IvfErpTheme.primaryNavy,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vitrification entry modal.')),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Inventory DataGrid
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(border: Border.all(color: IvfErpTheme.borderDark)),
                child: ListView.builder(
                  itemCount: filtered.length + 1,
                  itemBuilder: (context, idx) {
                    if (idx == 0) {
                      return Container(
                        height: 28,
                        color: IvfErpTheme.gridHeaderBg,
                        child: const Row(
                          children: [
                            SizedBox(width: 120, child: Text('Straw ID / Barcode', style: IvfErpTheme.gridHeaderStyle)),
                            SizedBox(width: 130, child: Text('Tank / Canister', style: IvfErpTheme.gridHeaderStyle)),
                            SizedBox(width: 120, child: Text('Goblet Location', style: IvfErpTheme.gridHeaderStyle)),
                            SizedBox(width: 90, child: Text('UHID', style: IvfErpTheme.gridHeaderStyle)),
                            Expanded(flex: 2, child: Text('Patient / Couple Name', style: IvfErpTheme.gridHeaderStyle)),
                            Expanded(flex: 3, child: Text('Cryopreserved Specimen', style: IvfErpTheme.gridHeaderStyle)),
                            SizedBox(width: 90, child: Text('Freeze Date', style: IvfErpTheme.gridHeaderStyle)),
                            SizedBox(width: 110, child: Text('Status', textAlign: TextAlign.center, style: IvfErpTheme.gridHeaderStyle)),
                          ],
                        ),
                      );
                    }

                    final item = filtered[idx - 1];
                    final isStored = item['status'].toString().contains('FROZEN');

                    return Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: idx.isEven ? IvfErpTheme.gridRowEven : IvfErpTheme.gridRowOdd,
                        border: const Border(bottom: BorderSide(color: Color(0xFFEAEDED))),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 120, child: Text(item['strawId'], style: const TextStyle(fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy))),
                          SizedBox(width: 130, child: Text('${item["tank"]} • ${item["canister"]}', style: const TextStyle(fontSize: 10))),
                          SizedBox(width: 120, child: Text(item['goblet'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: IvfErpTheme.ivfPurple))),
                          SizedBox(width: 90, child: Text(item['uhid'], style: const TextStyle(fontSize: 10))),
                          Expanded(flex: 2, child: Text(item['patientName'], overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
                          Expanded(flex: 3, child: Text(item['specimen'], overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 90, child: Text(item['freezeDate'], style: const TextStyle(fontSize: 10))),
                          SizedBox(
                            width: 110,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                color: isStored ? const Color(0xFFD4EFDF) : const Color(0xFFE5E7E9),
                                child: Text(
                                  item['status'],
                                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isStored ? IvfErpTheme.medicalEmerald : Colors.grey),
                                ),
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
                    child: const Text('Close Cryo Register'),
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
