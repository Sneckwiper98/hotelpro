import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/ivf_erp_theme.dart';
import '../../data/repositories/ivf_hospital_repository.dart';

/// Hospital Pharmacy, IVF Injections & Drug Inventory Dialog
class PharmacyInventoryDialog extends StatelessWidget {
  final IvfHospitalRepository repo;

  const PharmacyInventoryDialog({super.key, required this.repo});

  static Future<void> show(BuildContext context, IvfHospitalRepository repo) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PharmacyInventoryDialog(repo: repo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final dialogWidth = (screen.width * 0.90).clamp(780.0, 960.0);
    final dialogHeight = (screen.height * 0.88).clamp(500.0, 650.0);

    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final items = repo.pharmacyItems;

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
                  const Icon(Icons.medication_rounded, size: 15, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Hospital Pharmacy & IVF Injections Stock Register — ${repo.config.hospitalName}',
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
                  itemCount: items.length + 1,
                  itemBuilder: (context, idx) {
                    if (idx == 0) {
                      return Container(
                        height: 28,
                        color: IvfErpTheme.gridHeaderBg,
                        child: const Row(
                          children: [
                            SizedBox(width: 35, child: Text('#', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                            SizedBox(width: 80, child: Text('Item Code', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                            Expanded(flex: 3, child: Text('Medicine Brand Name', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('Category', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                            SizedBox(width: 90, child: Text('Batch No', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                            SizedBox(width: 95, child: Text('Expiry Date', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                            SizedBox(width: 75, child: Text('Stock', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                            SizedBox(width: 85, child: Text('MRP (₹)', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      );
                    }

                    final m = items[idx - 1];
                    return Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: idx.isEven ? IvfErpTheme.gridRowEven : IvfErpTheme.gridRowOdd,
                        border: const Border(bottom: BorderSide(color: Color(0xFFEAEDED))),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 35, child: Text('$idx', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10))),
                          SizedBox(width: 80, child: Text(m.medicineId, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy))),
                          Expanded(flex: 3, child: Text(m.brandName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text(m.category, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: IvfErpTheme.textMuted))),
                          SizedBox(width: 90, child: Text(m.batchNumber, style: const TextStyle(fontSize: 10, fontFamily: 'monospace'))),
                          SizedBox(width: 95, child: Text(dateFormat.format(m.expiryDate), style: const TextStyle(fontSize: 10))),
                          SizedBox(width: 75, child: Text('${m.currentStock}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: IvfErpTheme.medicalEmerald))),
                          SizedBox(width: 85, child: Text(currency.format(m.mrpUnit), textAlign: TextAlign.right, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
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
