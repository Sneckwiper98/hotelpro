import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../config/app_constants.dart';
import '../../../config/classic_erp_theme.dart';
import '../../../data/models/housekeeping_model.dart';
import '../../../data/repositories/hotel_repository.dart';
import '../../core/classic/utils/report_utils.dart';
import '../../core/components/hotel_logo_widget.dart';

/// Classic Windows Desktop Housekeeping & Room Turnover Matrix
/// High-density Kanban board, 1px borders, classic status ribbons, and task progression.
class HousekeepingView extends StatelessWidget {
  const HousekeepingView({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final tasks = repo.activeBranchHousekeeping;

    final pendingTasks = tasks.where((t) => t.status == 'pending').toList();
    final inProgressTasks = tasks.where((t) => t.status == 'in_progress').toList();
    final inspectedTasks = tasks.where((t) => t.status == 'inspected_approved' || t.status == 'cleaned').toList();

    return Container(
      color: ClassicErpTheme.windowBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Top Ribbon & KPI Bar ──────────────────────────────────────
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
                            const Icon(Icons.cleaning_services_rounded, size: 16, color: ClassicErpTheme.mdiHeaderActive),
                            const SizedBox(width: 6),
                            const Text(
                              'Housekeeping Operations & Room Turnover Queue',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• [${repo.activeBranch.name.toUpperCase()}]',
                              style: const TextStyle(fontSize: 11, color: ClassicErpTheme.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // Counters & Buttons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _kpiCounter('Pending Dirty', pendingTasks.length, const Color(0xFFD35400)),
                            const SizedBox(width: 6),
                            _kpiCounter('In Progress', inProgressTasks.length, const Color(0xFF2980B9)),
                            const SizedBox(width: 6),
                            _kpiCounter('Inspected & Clean', inspectedTasks.length, const Color(0xFF27AE60)),
                            const SizedBox(width: 12),
                            _ribbonButton(Icons.download_rounded, 'Export', () {
                              ExcelExportService.saveAsCsv(
                                context,
                                suggestedName: 'Housekeeping_Report_${DateTime.now().toIso8601String().substring(0, 10)}',
                                headers: ['Room No', 'Task Type', 'Status', 'Assigned To', 'Priority', 'Notes'],
                                rows: tasks.map((t) => [
                                  t.roomNumber, t.taskType, t.status, t.assignedStaff, t.priority.label, t.inspectionNotes ?? ''
                                ]).toList(),
                              );
                            }),
                            const SizedBox(width: 4),
                            _ribbonButton(Icons.print_rounded, 'Print Report', () {
                              PrintPreviewDialog.show(
                                context,
                                title: 'Housekeeping Report — ${repo.activeBranch.name}',
                                content: _buildHkPrintDoc(tasks, repo),
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

          // ── 2. 3-Stage Classic Task Progression Board ─────────────────────
          Expanded(
            child: Container(
              color: const Color(0xFFECEFF1),
              padding: const EdgeInsets.all(8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const minTotalWidth = 780.0;
                  final width = constraints.maxWidth > minTotalWidth ? constraints.maxWidth : minTotalWidth;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: width,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Stage 1: Dirty / Vacant
                          Expanded(
                            child: _buildClassicColumn(
                              context,
                              title: 'DIRTY / VACANT (NEEDS TURNOVER)',
                              tasks: pendingTasks,
                              headerColor: const Color(0xFFD35400),
                              repo: repo,
                              stage: 'pending',
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Stage 2: Cleaning In Progress
                          Expanded(
                            child: _buildClassicColumn(
                              context,
                              title: 'CLEANING IN PROGRESS',
                              tasks: inProgressTasks,
                              headerColor: const Color(0xFF2980B9),
                              repo: repo,
                              stage: 'in_progress',
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Stage 3: Cleaned & Approved
                          Expanded(
                            child: _buildClassicColumn(
                              context,
                              title: 'CLEANED & INSPECTED (VIP READY)',
                              tasks: inspectedTasks,
                              headerColor: const Color(0xFF27AE60),
                              repo: repo,
                              stage: 'inspected',
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
    );
  }

  Widget _kpiCounter(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: $count',
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain),
          ),
        ],
      ),
    );
  }

  Widget _buildClassicColumn(
    BuildContext context, {
    required String title,
    required List<HousekeepingTaskModel> tasks,
    required Color headerColor,
    required HotelRepository repo,
    required String stage,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: ClassicErpTheme.panelBg,
        border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Column Header Bar
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: headerColor,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  color: Colors.black26,
                  child: Text(
                    '${tasks.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Cards List
          Expanded(
            child: tasks.isEmpty
                ? const Center(
                    child: Text('No tasks in this queue', style: TextStyle(color: ClassicErpTheme.textMuted, fontSize: 11)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(6),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _buildClassicTaskCard(context, task, repo, stage);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassicTaskCard(BuildContext context, HousekeepingTaskModel task, HotelRepository repo, String stage) {
    Color priorityColor;
    switch (task.priority) {
      case HousekeepingPriority.urgentRush:
        priorityColor = const Color(0xFFC0392B);
        break;
      case HousekeepingPriority.high:
        priorityColor = const Color(0xFFD35400);
        break;
      default:
        priorityColor = const Color(0xFF1B4F72);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
        boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(1, 1), blurRadius: 1)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                color: const Color(0xFF1B4F72),
                child: Text(
                  'ROOM ${task.roomNumber}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                color: priorityColor.withValues(alpha: 0.15),
                child: Text(
                  task.priority.label.toUpperCase(),
                  style: TextStyle(color: priorityColor, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),
          Text(
            task.taskType,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain),
          ),
          const SizedBox(height: 2),

          Row(
            children: [
              const Icon(Icons.person_outline, size: 12, color: ClassicErpTheme.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  task.assignedStaff,
                  style: const TextStyle(fontSize: 10, color: ClassicErpTheme.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                DateFormat('HH:mm').format(task.createdAt),
                style: const TextStyle(fontSize: 9.5, color: ClassicErpTheme.textMuted),
              ),
            ],
          ),

          if (task.inspectionNotes != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(4),
              color: const Color(0xFFF2F4F4),
              child: Text(
                'Note: ${task.inspectionNotes}',
                style: const TextStyle(fontSize: 9.5, fontStyle: FontStyle.italic, color: ClassicErpTheme.textMain),
              ),
            ),
          ],

          const SizedBox(height: 6),

          // Action Button
          if (stage == 'pending') ...[
            SizedBox(
              width: double.infinity,
              height: 24,
              child: _classicTaskButton('▶ Start Cleaning', () {
                repo.progressHousekeepingTask(task.id, 'in_progress');
              }, color: const Color(0xFF2980B9)),
            ),
          ] else if (stage == 'in_progress') ...[
            SizedBox(
              width: double.infinity,
              height: 24,
              child: _classicTaskButton('✔ Mark Cleaned', () {
                repo.progressHousekeepingTask(task.id, 'cleaned');
              }, color: const Color(0xFF27AE60)),
            ),
          ] else ...[
            if (task.status != 'inspected_approved')
              SizedBox(
                width: double.infinity,
                height: 24,
                child: _classicTaskButton('★ Supervisor Approval', () {
                  repo.progressHousekeepingTask(
                    task.id,
                    'inspected_approved',
                    notes: 'Executive inspection approved 100%.',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Room ${task.roomNumber} inspected and approved!'), backgroundColor: const Color(0xFF27AE60)),
                  );
                }, color: const Color(0xFF1B4F72)),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 2),
                color: const Color(0xFFD4EFDF),
                alignment: Alignment.center,
                child: const Text(
                  '✔ APPROVED • READY FOR GUEST',
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF1E8449)),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _classicTaskButton(String label, VoidCallback onTap, {required Color color}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: color,
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _ribbonButton(IconData icon, String label, VoidCallback onTap) {
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
            Icon(icon, size: 13, color: ClassicErpTheme.mdiHeaderActive),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain)),
          ],
        ),
      ),
    );
  }

  Widget _buildHkPrintDoc(List<HousekeepingTaskModel> tasks, HotelRepository repo) {
    final now = DateFormat('dd MMM yyyy  HH:mm').format(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                    Text('${repo.clientBusinessName} — Housekeeping Report',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                    Text('Branch: ${repo.activeBranch.name}  |  Generated: $now',
                        style: const TextStyle(fontSize: 9, color: ClassicErpTheme.textMuted)),
                  ],
                ),
              ],
            ),
            const Icon(Icons.cleaning_services_rounded, size: 32, color: Color(0xFF1B4F72)),
          ],
        ),
        const Divider(thickness: 1.5, color: Color(0xFF1B4F72), height: 14),
        Table(
          border: TableBorder.all(color: ClassicErpTheme.borderDark, width: 0.5),
          columnWidths: const {
            0: FixedColumnWidth(60),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(1.5),
            3: FlexColumnWidth(1.5),
            4: FixedColumnWidth(60),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFF1B4F72)),
              children: ['Room', 'Task Type', 'Status', 'Assigned To', 'Priority'].map((h) => Padding(
                padding: const EdgeInsets.all(5),
                child: Text(h, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              )).toList(),
            ),
            ...tasks.asMap().entries.map((e) => TableRow(
              decoration: BoxDecoration(color: e.key.isEven ? Colors.white : const Color(0xFFF4F6F7)),
              children: [
                e.value.roomNumber, e.value.taskType, e.value.status, e.value.assignedStaff, e.value.priority.label
              ].map((cell) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                child: Text(cell, style: const TextStyle(fontSize: 9, color: ClassicErpTheme.textMain)),
              )).toList(),
            )),
          ],
        ),
        const SizedBox(height: 12),
        Text('Total Tasks: ${tasks.length}  |  Pending: ${tasks.where((t) => t.status == 'pending').length}  |  Completed: ${tasks.where((t) => t.status == 'inspected_approved').length}',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain)),
        const SizedBox(height: 16),
        const Divider(),
        const Text('iSecure Systems Pvt. Ltd.  •  HotelPro  •  Contact: 9326770568',
            style: TextStyle(fontSize: 8, color: ClassicErpTheme.textMuted), textAlign: TextAlign.center),
      ],
    );
  }
}
