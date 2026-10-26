import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/ivf_erp_theme.dart';
import '../../data/repositories/ivf_hospital_repository.dart';
import '../widgets/win32_window_frame.dart';
import 'print_preview_dialog.dart';

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

  void _printStockRegister(BuildContext context) {
    final items = repo.pharmacyItems;
    final config = repo.config;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final dateFormat = DateFormat('dd-MMM-yyyy');

    PrintPreviewDialog.show(
      context: context,
      config: config,
      documentTitle: 'HOSPITAL PHARMACY & DRUG INVENTORY STOCK REGISTER',
      documentSubtitle: 'IVF Injections, Hormones, Culture Media & Emergency Drug Inventory',
      documentNumber: 'PHARM-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
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
                Text('Total Formulations Tracked: ${items.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5)),
                Text('Chief Pharmacist: Qualified D.Pharm / B.Pharm', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: Color(0xFF003366))),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            color: const Color(0xFF003366),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Code', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 5, child: Text('Drug Brand & Formulation', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('Category', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('Batch No.', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('Expiry', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Stock', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('MRP', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          ...items.map((m) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text(m.medicineId, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                Expanded(flex: 5, child: Text(m.brandName, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text(m.category, style: const TextStyle(fontSize: 8.5))),
                Expanded(flex: 3, child: Text(m.batchNumber, style: const TextStyle(fontSize: 8.5, fontFamily: 'monospace'))),
                Expanded(flex: 3, child: Text(dateFormat.format(m.expiryDate), style: const TextStyle(fontSize: 8.5))),
                Expanded(flex: 2, child: Text('${m.currentStock}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF27AE60)))),
                Expanded(flex: 3, child: Text(currency.format(m.mrpUnit), textAlign: TextAlign.right, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final items = repo.pharmacyItems;

    return Win32WindowFrame(
      title: 'HOSPITAL PHARMACY & IVF INJECTIONS STOCK REGISTER',
      subtitle: '${repo.config.hospitalName} • ${repo.config.activeBranch.branchName}',
      icon: Icons.medication_rounded,
      defaultWidth: 1000,
      defaultHeight: 660,
      child: Column(
        children: [

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
                  ElevatedButton.icon(
                    icon: const Icon(Icons.print_rounded, size: 14),
                    label: const Text('Print Stock Register (A4)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: IvfErpTheme.primaryNavy,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: () => _printStockRegister(context),
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
