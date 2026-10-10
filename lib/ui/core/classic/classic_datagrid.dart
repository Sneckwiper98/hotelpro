import 'package:flutter/material.dart';
import '../../../config/classic_erp_theme.dart';

class ClassicGridColumn {
  final String title;
  final double width;
  final TextAlign align;

  const ClassicGridColumn({
    required this.title,
    required this.width,
    this.align = TextAlign.left,
  });
}

class ClassicGridRow {
  final int srlNo;
  final List<dynamic> cells;
  final dynamic rawData;

  const ClassicGridRow({
    required this.srlNo,
    required this.cells,
    this.rawData,
  });
}

/// High-Density Enterprise Spreadsheet DataGrid
/// Replicates exact Windows Desktop ERP appearance from the reference image:
/// - Active row pointer arrow `►` in Srl No column
/// - Deep Navy Column Header with crisp dividers
/// - Alternating row zebra striping
/// - 1px grid borders on every cell
class ClassicDataGrid extends StatefulWidget {
  final List<ClassicGridColumn> columns;
  final List<ClassicGridRow> rows;
  final int selectedIndex;
  final Function(int, ClassicGridRow)? onRowSelected;
  final Function(int, ClassicGridRow)? onRowDoubleTapped;
  final double rowHeight;

  const ClassicDataGrid({
    super.key,
    required this.columns,
    required this.rows,
    this.selectedIndex = 0,
    this.onRowSelected,
    this.onRowDoubleTapped,
    this.rowHeight = 26.0,
  });

  @override
  State<ClassicDataGrid> createState() => _ClassicDataGridState();
}

class _ClassicDataGridState extends State<ClassicDataGrid> {
  late int _currentSelected;
  final ScrollController _hScrollController = ScrollController();
  final ScrollController _vScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentSelected = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(ClassicDataGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _currentSelected = widget.selectedIndex;
    }
  }

  @override
  void dispose() {
    _hScrollController.dispose();
    _vScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalWidth = widget.columns.fold(50.0, (sum, col) => sum + col.width);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final effectiveWidth = constraints.maxWidth < totalWidth ? totalWidth : constraints.maxWidth;

          return Scrollbar(
            controller: _hScrollController,
            thumbVisibility: true,
            trackVisibility: true,
            child: SingleChildScrollView(
              controller: _hScrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: effectiveWidth,
                child: Column(
                  children: [
                    // 1. Grid Column Headers (Deep Navy Blue)
                    Container(
                      height: 28,
                      decoration: const BoxDecoration(
                        color: ClassicErpTheme.gridHeaderBg,
                        border: Border(
                          bottom: BorderSide(color: ClassicErpTheme.gridHeaderBorder, width: 1.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Leftmost pointer column
                          Container(
                            width: 50,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              border: Border(right: BorderSide(color: Colors.white24, width: 1)),
                            ),
                            child: const Text(
                              'Srl No',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          // Dynamic Columns
                          for (int c = 0; c < widget.columns.length; c++)
                            Container(
                              width: widget.columns[c].width,
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              alignment: _getAlignment(widget.columns[c].align),
                              decoration: const BoxDecoration(
                                border: Border(right: BorderSide(color: Colors.white24, width: 1)),
                              ),
                              child: Text(
                                widget.columns[c].title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // 2. Data Rows
                    Expanded(
                      child: widget.rows.isEmpty
                          ? const Center(
                              child: Text(
                                'No records found in current filter criteria.',
                                style: TextStyle(color: ClassicErpTheme.textMuted, fontSize: 12),
                              ),
                            )
                          : Scrollbar(
                              controller: _vScrollController,
                              thumbVisibility: true,
                              trackVisibility: true,
                              child: ListView.builder(
                                controller: _vScrollController,
                                primary: false,
                                itemCount: widget.rows.length,
                                itemExtent: widget.rowHeight,
                                itemBuilder: (ctx, idx) {
                                  final row = widget.rows[idx];
                                  final isSelected = idx == _currentSelected;
                                  final rowBg = isSelected
                                      ? ClassicErpTheme.gridSelectedRow
                                      : (idx.isEven ? ClassicErpTheme.gridRowEven : ClassicErpTheme.gridRowOdd);

                                  return InkWell(
                                    onTap: () {
                                      setState(() => _currentSelected = idx);
                                      widget.onRowSelected?.call(idx, row);
                                    },
                                    onDoubleTap: () {
                                      widget.onRowDoubleTapped?.call(idx, row);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: rowBg,
                                        border: const Border(
                                          bottom: BorderSide(color: ClassicErpTheme.borderLight, width: 0.8),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // Srl No column with ► active row pointer & active left accent
                                          Container(
                                            width: 50,
                                            alignment: Alignment.center,
                                            decoration: const BoxDecoration(
                                              border: Border(right: BorderSide(color: ClassicErpTheme.borderLight, width: 0.8)),
                                            ),
                                            child: Stack(
                                              children: [
                                                if (isSelected)
                                                  Positioned(
                                                    left: 0,
                                                    top: 0,
                                                    bottom: 0,
                                                    child: Container(
                                                      width: 3,
                                                      color: ClassicErpTheme.gridSelectedBorder,
                                                    ),
                                                  ),
                                                Center(
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      if (isSelected)
                                                        const Text('►', style: TextStyle(color: Color(0xFF1B4F72), fontSize: 9, fontWeight: FontWeight.bold))
                                                      else
                                                        const SizedBox(width: 8),
                                                      const SizedBox(width: 2),
                                                      Text(
                                                        '${row.srlNo}',
                                                        style: TextStyle(
                                                          color: isSelected ? const Color(0xFF1B4F72) : ClassicErpTheme.textMain,
                                                          fontSize: 10.5,
                                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Row Data Cells
                                          for (int c = 0; c < widget.columns.length; c++)
                                            Container(
                                              width: widget.columns[c].width,
                                              padding: const EdgeInsets.symmetric(horizontal: 6),
                                              alignment: _getAlignment(widget.columns[c].align),
                                              decoration: const BoxDecoration(
                                                border: Border(right: BorderSide(color: ClassicErpTheme.borderLight, width: 0.8)),
                                              ),
                                              child: ClipRect(
                                                child: _buildCellContent(
                                                  row.cells.length > c ? row.cells[c] : '',
                                                  isSelected,
                                                  widget.columns[c].align,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCellContent(dynamic value, bool isSelected, TextAlign align) {
    if (value is Widget) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: _getAlignment(align),
        child: value,
      );
    }
    return Text(
      value?.toString() ?? '',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: isSelected ? const Color(0xFF154360) : ClassicErpTheme.textMain,
        fontSize: 10.5,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Alignment _getAlignment(TextAlign align) {
    switch (align) {
      case TextAlign.right:
        return Alignment.centerRight;
      case TextAlign.center:
        return Alignment.center;
      default:
        return Alignment.centerLeft;
    }
  }
}
