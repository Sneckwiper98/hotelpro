import 'package:flutter/material.dart';
import '../../../config/classic_erp_theme.dart';

/// Classic ERP Form & Filter Box
/// Faithfully reproduces the upper panel from the user's reference photo:
/// - Code + Lookup Search icon (`LocCd 🔍 [MG]`)
/// - Primary Action Buttons (`Load`, `Import Excel`, `Export Excel`, `Update`)
/// - Grouped Filter Box with criteria fields
class ClassicFilterBox extends StatelessWidget {
  final String locationCode;
  final String locationName;
  final String itemCode;
  final String itemName;
  final VoidCallback? onLocationLookup;
  final VoidCallback? onItemLookup;
  final VoidCallback? onLoadPressed;
  final VoidCallback? onExportExcel;
  final VoidCallback? onImportExcel;
  final VoidCallback? onPrintPreview;
  final VoidCallback? onAction1;
  final VoidCallback? onAction2;
  final String action1Label;
  final String action2Label;
  final ValueChanged<String>? onSearchFilterChanged;
  final String searchFilterValue;
  final String currentCountInfo;

  const ClassicFilterBox({
    super.key,
    required this.locationCode,
    required this.locationName,
    required this.itemCode,
    required this.itemName,
    this.onLocationLookup,
    this.onItemLookup,
    this.onLoadPressed,
    this.onExportExcel,
    this.onImportExcel,
    this.onPrintPreview,
    this.onAction1,
    this.onAction2,
    this.action1Label = 'Delete Levels',
    this.action2Label = 'Update Levels',
    this.onSearchFilterChanged,
    this.searchFilterValue = '',
    this.currentCountInfo = 'Filter(15) NoFilter',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ClassicErpTheme.panelBg,
        border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: Code Pickers & Right Action Buttons ──────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left fields (LocCd, ItemCd, LvlId)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Lvl Id
                    Row(
                      children: [
                        const SizedBox(
                          width: 60,
                          child: Text('Lvl Id', style: TextStyle(fontSize: 11, color: ClassicErpTheme.textMain, fontWeight: FontWeight.w600)),
                        ),
                        Container(
                          width: 80,
                          height: 22,
                          color: Colors.white,
                          child: TextFormField(
                            initialValue: '2026',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // LocCd (Location Code)
                    Row(
                      children: [
                        const SizedBox(
                          width: 60,
                          child: Text('LocCd', style: TextStyle(fontSize: 11, color: ClassicErpTheme.textMain, fontWeight: FontWeight.w600)),
                        ),
                        InkWell(
                          onTap: onLocationLookup,
                          child: Container(
                            height: 22,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search_rounded, size: 14, color: ClassicErpTheme.mdiHeaderActive),
                                const SizedBox(width: 4),
                                Text(locationCode, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            height: 22,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9EBEA), // Soft pink/beige tint like the photo
                              border: Border.all(color: ClassicErpTheme.borderLight, width: 1),
                            ),
                            child: Text(
                              locationName,
                              style: const TextStyle(color: Color(0xFFC0392B), fontSize: 11, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // ItemCd (Item / Room Type Code)
                    Row(
                      children: [
                        const SizedBox(
                          width: 60,
                          child: Text('ItemCd', style: TextStyle(fontSize: 11, color: ClassicErpTheme.textMain, fontWeight: FontWeight.w600)),
                        ),
                        InkWell(
                          onTap: onItemLookup,
                          child: Container(
                            height: 22,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search_rounded, size: 14, color: ClassicErpTheme.mdiHeaderActive),
                                const SizedBox(width: 4),
                                Text(itemCode, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            height: 22,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9EBEA),
                              border: Border.all(color: ClassicErpTheme.borderLight, width: 1),
                            ),
                            child: Text(
                              itemName,
                              style: const TextStyle(color: Color(0xFFC0392B), fontSize: 11, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // Right Action Buttons Block (Exactly matching the right column in photo)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildClassicButton(action1Label, onAction1),
                      const SizedBox(width: 6),
                      _buildClassicButton(action2Label, onAction2),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildClassicButton('Load', onLoadPressed, isBold: true, bgColor: const Color(0xFFE8F8F5)),
                      const SizedBox(width: 6),
                      _buildClassicButton('Import Excel', onImportExcel),
                      const SizedBox(width: 6),
                      _buildClassicButton('Export Excel', onExportExcel, isExcel: true),
                      if (onPrintPreview != null) ...[
                        const SizedBox(width: 6),
                        _buildClassicButton('Print', onPrintPreview),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Row 2: Classic Grouped Filter Box with title ─────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            decoration: BoxDecoration(
              border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: ClassicErpTheme.textMain,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterInput('Size Range', 85),
                      const SizedBox(width: 8),
                      _filterInput('Design Desc', 110, onChanged: onSearchFilterChanged, value: searchFilterValue),
                      const SizedBox(width: 8),
                      _filterInput('Wt Range', 85),
                      const SizedBox(width: 8),
                      _filterInput('Level >', 65),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                        ),
                        child: Text(
                          currentCountInfo,
                          style: const TextStyle(fontSize: 11, color: ClassicErpTheme.textMain, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassicButton(String text, VoidCallback? onPressed, {bool isBold = false, bool isExcel = false, Color? bgColor}) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor ?? ClassicErpTheme.buttonBg,
          border: Border.all(color: isExcel ? ClassicErpTheme.excelGreen : ClassicErpTheme.buttonBorder, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(1, 1),
              blurRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isExcel) ...[
              const Icon(Icons.table_view_rounded, size: 13, color: ClassicErpTheme.excelGreen),
              const SizedBox(width: 4),
            ],
            Text(
              text,
              style: TextStyle(
                color: isExcel ? ClassicErpTheme.excelGreen : ClassicErpTheme.textMain,
                fontSize: 11,
                fontWeight: isBold || isExcel ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterInput(String label, double width, {ValueChanged<String>? onChanged, String? value}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label ', style: const TextStyle(fontSize: 11, color: ClassicErpTheme.textMain)),
        Container(
          width: width,
          height: 22,
          color: Colors.white,
          child: TextFormField(
            initialValue: value,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 11),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              border: OutlineInputBorder(borderRadius: BorderRadius.zero),
            ),
          ),
        ),
      ],
    );
  }
}
