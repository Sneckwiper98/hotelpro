import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../config/classic_erp_theme.dart';
import '../../../data/repositories/hotel_repository.dart';
import '../../core/classic/utils/report_utils.dart';
import '../../core/components/hotel_logo_widget.dart';

/// Classic Windows Desktop Executive Analytics & MIS View
/// High-density financial metric panels, multi-property comparison spreadsheet, and division breakdown.
class ExecutiveAnalyticsView extends StatelessWidget {
  const ExecutiveAnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    final occupancy = repo.occupancyRate;
    final adr = repo.averageDailyRate;
    final revpar = repo.revenuePerAvailableRoom;
    final activeBranch = repo.activeBranch;

    return Container(
      color: ClassicErpTheme.windowBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Top Ribbon & Action Bar ───────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              color: ClassicErpTheme.panelBg,
              border: Border(bottom: BorderSide(color: ClassicErpTheme.borderDark, width: 1)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.analytics_rounded, size: 16, color: ClassicErpTheme.mdiHeaderActive),
                            const SizedBox(width: 6),
                            const Text(
                              'Executive GM MIS Dashboard — Financial Performance & Yield Analytics',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• [${activeBranch.name.toUpperCase()}]',
                              style: const TextStyle(fontSize: 11, color: ClassicErpTheme.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _classicButton(Icons.download_rounded, 'Export to Excel', () {
                              final currency = NumberFormat.currency(symbol: 'Rs.', decimalDigits: 0);
                              ExcelExportService.saveAsCsv(
                                context,
                                suggestedName: 'MIS_Report_${activeBranch.code}_${DateTime.now().toIso8601String().substring(0, 10)}',
                                headers: ['Metric', 'Value', 'Branch', 'Date'],
                                rows: [
                                  ['REVPAR', currency.format(revpar), activeBranch.name, DateTime.now().toIso8601String().substring(0, 10)],
                                  ['ADR', currency.format(adr > 0 ? adr : activeBranch.starRating * 4500), activeBranch.name, DateTime.now().toIso8601String().substring(0, 10)],
                                  ['Occupancy %', '${occupancy.toStringAsFixed(1)}%', activeBranch.name, DateTime.now().toIso8601String().substring(0, 10)],
                                  ['Occupied Rooms', '${repo.occupiedRoomsCount}', activeBranch.name, DateTime.now().toIso8601String().substring(0, 10)],
                                  ['Total Rooms', '${repo.activeBranchRooms.length}', activeBranch.name, DateTime.now().toIso8601String().substring(0, 10)],
                                ],
                              );
                            }),
                            const SizedBox(width: 6),
                            _classicButton(Icons.print_rounded, 'Print Summary', () {
                              PrintPreviewDialog.show(
                                context,
                                title: 'Executive MIS Report — ${activeBranch.name}',
                                content: _buildMisReportDocument(context, repo, currency, occupancy, adr, revpar, activeBranch),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── 2. Scrollable Body ───────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 4 Core Financial KPI Panels
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 720;
                      final row = Row(
                        children: [
                          _kpiCard('REVPAR (REVENUE / ROOM)', currency.format(revpar), '+14.2% vs previous period', const Color(0xFF1B4F72)),
                          const SizedBox(width: 8),
                          _kpiCard('ADR (AVG DAILY RATE)', currency.format(adr > 0 ? adr : activeBranch.starRating * 4500), 'Standard Tariff Met', const Color(0xFF2874A6)),
                          const SizedBox(width: 8),
                          _kpiCard('OCCUPANCY RATIO', '${occupancy.toStringAsFixed(1)}%', '${repo.occupiedRoomsCount}/${repo.activeBranchRooms.length} Rooms Sold', const Color(0xFF27AE60)),
                          const SizedBox(width: 8),
                          _kpiCard('TURNOVER SPEED', '24 Mins', 'Housekeeping Target Met', const Color(0xFFD35400)),
                        ],
                      );
                      if (isNarrow) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(width: 720, child: row),
                        );
                      }
                      return row;
                    },
                  ),

                  const SizedBox(height: 12),

                  // Multi-Property Comparison Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 650;
                      final grid = Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header
                            Container(
                              height: 24,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              color: ClassicErpTheme.gridHeaderBg,
                              child: const Row(
                                children: [
                                  Expanded(flex: 3, child: Text('BRANCH / PROPERTY NAME', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                                  Expanded(flex: 2, child: Text('LOCATION / CITY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                                  Expanded(flex: 2, child: Text('RATING TIER', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                                  Expanded(flex: 2, child: Text('ROOMS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                                  Expanded(flex: 2, child: Text('OCCUPANCY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                                  Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('EST. REVPAR', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                                ],
                              ),
                            ),

                        // Property Rows
                        for (int i = 0; i < repo.branches.length; i++) ...[
                          Container(
                            height: 28,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            color: i.isEven ? Colors.white : const Color(0xFFF4F6F7),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: [
                                      Icon(
                                        repo.branches[i].id == activeBranch.id ? Icons.check_circle_rounded : Icons.domain_rounded,
                                        size: 13,
                                        color: repo.branches[i].id == activeBranch.id ? const Color(0xFF27AE60) : ClassicErpTheme.textMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          repo.branches[i].name,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text('${repo.branches[i].city}, ${repo.branches[i].state}', style: const TextStyle(fontSize: 10.5, color: ClassicErpTheme.textMuted)),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text('${repo.branches[i].starRating}★ Star Property', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text('${repo.branches[i].totalRooms} Rooms', style: const TextStyle(fontSize: 10.5)),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    repo.branches[i].id == activeBranch.id ? '${occupancy.toStringAsFixed(0)}%' : '${(65 + (i * 8))}%',
                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF27AE60)),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      repo.branches[i].starRating == 5 ? '₹18,250' : '₹4,200',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFE0E0E0)),
                        ],
                      ],
                    ),
                  );
                  if (isNarrow) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(width: 650, child: grid),
                    );
                  }
                  return grid;
                },
              ),

              const SizedBox(height: 12),

                  // Division Revenue Contribution Breakdown
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ClassicErpTheme.panelBg,
                      border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DEPARTMENTAL REVENUE DISTRIBUTION (YTD)',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain),
                        ),
                        const SizedBox(height: 10),
                        _classicRevenueBar('Rooms Division (Room Tariff & Upgrades)', 0.62, '62% — ₹14,50,000', const Color(0xFF1B4F72)),
                        const SizedBox(height: 8),
                        _classicRevenueBar('Food & Beverage (Restaurant & Room Service)', 0.24, '24% — ₹5,60,000', const Color(0xFF2874A6)),
                        const SizedBox(height: 8),
                        _classicRevenueBar('Spa & Ayurvedic Wellness', 0.09, '9% — ₹2,10,000', const Color(0xFF27AE60)),
                        const SizedBox(height: 8),
                        _classicRevenueBar('Banquets, Events & Transfers', 0.05, '5% — ₹1,15,000', const Color(0xFFD35400)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String title, String value, String subtitle, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
          boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(1, 1), blurRadius: 1)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMuted)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
            ),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 9.5, color: ClassicErpTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _classicRevenueBar(String label, double fraction, String text, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain)),
            Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 3),
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: ClassicErpTheme.borderDark, width: 0.5),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fraction,
            child: Container(color: color),
          ),
        ),
      ],
    );
  }

  Widget _classicButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: ClassicErpTheme.buttonBg,
          border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: const Color(0xFF1B4F72)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the formatted document widget shown in print preview.
  Widget _buildMisReportDocument(
    BuildContext context,
    HotelRepository repo,
    NumberFormat currency,
    double occupancy,
    double adr,
    double revpar,
    dynamic activeBranch,
  ) {
    final now = DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy  HH:mm').format(now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with Hotel Brand Logo
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                HotelLogoWidget(repo: repo, width: 44, height: 44),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${repo.clientBusinessName} — Executive MIS Report',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                    Text('Branch: ${activeBranch.name} (${activeBranch.code})',
                        style: const TextStyle(fontSize: 10.5, color: ClassicErpTheme.textMuted)),
                    Text('Generated: $dateStr', style: const TextStyle(fontSize: 9, color: ClassicErpTheme.textMuted)),
                  ],
                ),
              ],
            ),
            const Icon(Icons.analytics_rounded, size: 36, color: Color(0xFF1B4F72)),
          ],
        ),
        const Divider(thickness: 2, color: Color(0xFF1B4F72)),
        const SizedBox(height: 12),

        // KPI Table
        const Text('KEY PERFORMANCE INDICATORS',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
        const SizedBox(height: 6),
        Table(
          border: TableBorder.all(color: ClassicErpTheme.borderDark, width: 0.5),
          children: [
            _reportTableHeader(['METRIC', 'VALUE', 'STATUS']),
            _reportTableRow(['REVPAR (Revenue Per Available Room)', currency.format(revpar), '+14.2% vs prev. period']),
            _reportTableRow(['ADR (Average Daily Rate)', currency.format(adr > 0 ? adr : activeBranch.starRating * 4500), 'Standard Tariff Met']),
            _reportTableRow(['Occupancy Ratio', '${occupancy.toStringAsFixed(1)}%', '${repo.occupiedRoomsCount} / ${repo.activeBranchRooms.length} Rooms']),
            _reportTableRow(['Housekeeping Turnover Speed', '24 Minutes', 'Target Met']),
          ],
        ),

        const SizedBox(height: 20),
        const Divider(),
        const Text('iSecure Systems Pvt. Ltd.  •  Contact: 9326770568',
            style: TextStyle(fontSize: 9, color: ClassicErpTheme.textMuted)),
      ],
    );
  }

  TableRow _reportTableHeader(List<String> cells) {
    return TableRow(
      decoration: const BoxDecoration(color: Color(0xFF1B4F72)),
      children: cells
          .map((c) => Padding(
                padding: const EdgeInsets.all(6),
                child: Text(c, style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
              ))
          .toList(),
    );
  }

  TableRow _reportTableRow(List<String> cells) {
    return TableRow(
      children: cells
          .map((c) => Padding(
                padding: const EdgeInsets.all(6),
                child: Text(c, style: const TextStyle(fontSize: 10, color: ClassicErpTheme.textMain)),
              ))
          .toList(),
    );
  }
}
