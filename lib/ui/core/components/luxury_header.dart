import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../../../data/repositories/hotel_repository.dart';

class LuxuryHeader extends StatelessWidget {
  const LuxuryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final activeBranch = repo.activeBranch;
    final currentTime = DateFormat('EEE, d MMM yyyy • hh:mm a').format(DateTime.now());

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppTheme.slateCard,
        border: Border(
          bottom: BorderSide(color: AppTheme.slateBorder, width: 1),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showTime = constraints.maxWidth >= 1250;
          final showStatusChips = constraints.maxWidth >= 1150;
          final showNightAuditText = constraints.maxWidth >= 700;
          final showStaffDetails = constraints.maxWidth >= 850;

          return Row(
            children: [
              // 1. Multi-Branch Switcher Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.obsidianBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.imperialGold.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hotel_class_rounded, color: AppTheme.imperialGold, size: 20),
                    const SizedBox(width: 8),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: activeBranch.id,
                        dropdownColor: AppTheme.slateCardElevated,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.imperialGold),
                        items: repo.branches.map((branch) {
                          return DropdownMenuItem<String>(
                            value: branch.id,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(branch.name),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.imperialGold.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${branch.starRating}★ ${branch.city}',
                                    style: const TextStyle(
                                      color: AppTheme.imperialGold,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newBranchId) {
                          if (newBranchId != null) {
                            repo.switchBranch(newBranchId);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Real-time Status Counters (visible on medium & large screens)
              if (showStatusChips) ...[
                const SizedBox(width: 14),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatusChip(
                      label: 'Available',
                      count: repo.availableRoomsCount,
                      color: AppTheme.statusClean,
                      icon: Icons.check_circle_outline_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(
                      label: 'Occupied',
                      count: repo.occupiedRoomsCount,
                      color: AppTheme.statusOccupied,
                      icon: Icons.person_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(
                      label: 'Dirty',
                      count: repo.dirtyRoomsCount,
                      color: AppTheme.statusDirty,
                      icon: Icons.cleaning_services_rounded,
                    ),
                  ],
                ),
              ],

              const Spacer(),

              // 3. Current Time & Date (visible on wide screens)
              if (showTime) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded, color: AppTheme.champagneAccent, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      currentTime,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
              ],

              // 4. Night Audit Action Button
              OutlinedButton.icon(
                onPressed: () {
                  _showNightAuditDialog(context, repo);
                },
                icon: const Icon(Icons.nightlight_round, size: 15, color: AppTheme.imperialGold),
                label: Text(
                  showNightAuditText ? 'Night Audit' : 'Audit',
                  style: const TextStyle(color: AppTheme.imperialGold, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.imperialGold),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),

              const SizedBox(width: 14),

              // 5. Staff Profile Avatar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.obsidianBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.slateBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 13,
                      backgroundColor: AppTheme.imperialGold,
                      child: Text(
                        'GM',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                    if (showStaffDetails) ...[
                      const SizedBox(width: 8),
                      const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Vikramaditya (GM)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                          Text('HQ Super Admin', style: TextStyle(fontSize: 9, color: AppTheme.imperialGold)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showNightAuditDialog(BuildContext context, HotelRepository repo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.slateCardElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.imperialGold)),
        title: const Row(
          children: [
            Icon(Icons.nightlight_round, color: AppTheme.imperialGold),
            SizedBox(width: 10),
            Text('Execute Daily Night Audit', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aap property "${repo.activeBranch.name}" ke liye Daily Night Audit process initiate kar rahe hain.',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            const Text('Night Audit automated actions:', style: TextStyle(color: AppTheme.champagneAccent, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            _buildAuditBullet('Auto-post nightly room tariffs & 18% GST to active guest folios.'),
            _buildAuditBullet('Close all restaurant POS open cash shifts.'),
            _buildAuditBullet('Calculate today\'s RevPAR, ADR, and Occupancy metrics.'),
            _buildAuditBullet('Synchronize accounting ledgers with secure cloud server.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              repo.runNightAudit();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Night Audit successfully executed. All folios & ledger updated.'),
                  backgroundColor: AppTheme.statusClean,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.imperialGold),
            child: const Text('Run Night Audit Now', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static Widget _buildAuditBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 14, color: AppTheme.imperialGold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
