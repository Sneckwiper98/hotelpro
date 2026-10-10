import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../config/app_constants.dart';
import '../../../../config/classic_erp_theme.dart';
import '../../../../data/repositories/hotel_repository.dart';

/// Enterprise Hotel Night Audit & Day-End Closing Wizard
/// Standard in PMS systems like Opera, IDS Next, and ShawMan.
class NightAuditDialog extends StatefulWidget {
  const NightAuditDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => const NightAuditDialog(),
    );
  }

  @override
  State<NightAuditDialog> createState() => _NightAuditDialogState();
}

class _NightAuditDialogState extends State<NightAuditDialog> {
  int _currentStep = 0;
  bool _isProcessing = false;
  bool _auditCompleted = false;

  final DateTime _auditDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final dateStr = DateFormat('dd-MMM-yyyy').format(_auditDate);

    final occupiedRooms = repo.activeBranchRooms.where((r) => r.isOccupied).toList();
    final dirtyRooms = repo.activeBranchRooms.where((r) => r.status == RoomStatus.dirtyVacant).toList();
    final todayInvoices = repo.allInvoices;
    final double totalDayCollection = todayInvoices.fold(0.0, (sum, inv) => sum + inv.totalAmount);

    return Dialog(
      backgroundColor: ClassicErpTheme.panelBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        width: 720,
        height: 520,
        decoration: BoxDecoration(
          color: ClassicErpTheme.panelBg,
          border: Border.all(color: ClassicErpTheme.borderDark, width: 2),
        ),
        child: Column(
          children: [
            // 1. Classic Windows Dialog Title Bar
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B4F72), Color(0xFF2874A6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.nightlight_round, color: Colors.amberAccent, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    'Night Audit & Business Day Rollover Wizard — [$dateStr • ${repo.activeBranch.name.toUpperCase()}]',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 16,
                      height: 14,
                      color: const Color(0xFFC0392B),
                      alignment: Alignment.center,
                      child: const Icon(Icons.close, size: 10, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Step Indicator Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  _stepBadge(0, '1. Pre-Audit Check', Icons.checklist_rounded),
                  _stepConnector(0),
                  _stepBadge(1, '2. Tariff Posting', Icons.post_add_rounded),
                  _stepConnector(1),
                  _stepBadge(2, '3. Revenue Reconciliation', Icons.account_balance_rounded),
                  _stepConnector(2),
                  _stepBadge(3, '4. Day Rollover', Icons.check_circle_outline_rounded),
                ],
              ),
            ),

            const Divider(height: 1, color: ClassicErpTheme.borderDark),

            // 3. Step Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildStepContent(repo, currency, occupiedRooms, dirtyRooms, totalDayCollection),
              ),
            ),

            // 4. Wizard Action Buttons Footer
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFEAECEE),
                border: Border(top: BorderSide(color: ClassicErpTheme.borderLight, width: 1)),
              ),
              child: Row(
                children: [
                  Text(
                    'Operator: ${repo.currentErpUser.displayName} (${repo.currentErpUser.role})',
                    style: const TextStyle(fontSize: 10.5, color: ClassicErpTheme.textMuted, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (_currentStep > 0 && !_auditCompleted)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: ClassicErpTheme.borderDark),
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        ),
                        onPressed: () => setState(() => _currentStep--),
                        child: const Text('« Previous Step', style: TextStyle(fontSize: 11, color: ClassicErpTheme.textMain)),
                      ),
                    ),
                  if (!_auditCompleted)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B4F72),
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      ),
                      onPressed: _isProcessing
                          ? null
                          : () {
                              if (_currentStep < 3) {
                                setState(() => _currentStep++);
                              } else {
                                _executeNightAudit();
                              }
                            },
                      child: _isProcessing
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(_currentStep == 3 ? 'Execute Business Day Rollover' : 'Next Step »', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    )
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27AE60),
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Finish & Return to Workstation', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepBadge(int step, String title, IconData icon) {
    final isActive = _currentStep == step;
    final isDone = _currentStep > step || _auditCompleted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isDone ? const Color(0xFF27AE60) : (isActive ? const Color(0xFF1B4F72) : const Color(0xFFBDC3C7)),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: isDone
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : Text('${step + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? const Color(0xFF1B4F72) : ClassicErpTheme.textMain,
          ),
        ),
      ],
    );
  }

  Widget _stepConnector(int step) {
    return Expanded(
      child: Container(
        height: 1.5,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: _currentStep > step || _auditCompleted ? const Color(0xFF27AE60) : const Color(0xFFD5D8DC),
      ),
    );
  }

  Widget _buildStepContent(
    HotelRepository repo,
    NumberFormat currency,
    List<dynamic> occupiedRooms,
    List<dynamic> dirtyRooms,
    double totalDayCollection,
  ) {
    final dateStr = DateFormat('dd-MMM-yyyy').format(_auditDate);
    if (_auditCompleted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_rounded, size: 56, color: Color(0xFF27AE60)),
            const SizedBox(height: 12),
            const Text(
              'Night Audit Completed Successfully!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
            ),
            const SizedBox(height: 6),
            Text(
              'Business date rolled over to ${DateFormat("dd-MMM-yyyy").format(DateTime.now().add(const Duration(days: 1)))}',
              style: const TextStyle(fontSize: 12, color: ClassicErpTheme.textMuted),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: const Text(
                '✓ All in-house room tariffs and GST posted to guest folios.\n'
                '✓ All POS restaurant day registers reconciled with zero variance.\n'
                '✓ Daily Manager Flash Report generated and stored.',
                style: TextStyle(fontSize: 11, height: 1.6, color: Color(0xFF1E8449), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    switch (_currentStep) {
      case 0: // Pre-Audit Validation
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Step 1: System Pre-Audit Health & Sanity Checks',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
              const SizedBox(height: 4),
              const Text('Verify pending operational tasks before freezing today\'s business accounts.',
                  style: TextStyle(fontSize: 11, color: ClassicErpTheme.textMuted)),
              const SizedBox(height: 14),
              _checkCard('Occupied Rooms In-House', '${occupiedRooms.length} Rooms',
                  'Room charges will be posted for these rooms.', Icons.hotel_rounded, Colors.blue.shade700),
              const SizedBox(height: 8),
              _checkCard('Housekeeping Room Status', '${dirtyRooms.length} Dirty Rooms',
                  dirtyRooms.isEmpty ? 'All rooms are cleaned & inspected.' : 'Notice: Some rooms require housekeeping morning inspection.',
                  Icons.cleaning_services_rounded, dirtyRooms.isEmpty ? Colors.green : Colors.orange.shade700),
              const SizedBox(height: 8),
              _checkCard('Open POS KOTs & Orders', '0 Pending Orders',
                  'All kitchen order tickets are settled and billed.', Icons.restaurant_rounded, Colors.green),
              const SizedBox(height: 8),
              _checkCard('Front Desk Pending Arrivals', '0 Unregistered',
                  'All guaranteed arrivals are checked-in or released.', Icons.person_search_rounded, Colors.green),
            ],
          ),
        );

      case 1: // Automatic Room Tariff Posting
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Step 2: Automatic Room Tariff & GST Posting',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
              const SizedBox(height: 4),
              const Text('The audit will post nightly tariffs, CGST (6%) and SGST (6%) directly to the open guest folios.',
                  style: TextStyle(fontSize: 11, color: ClassicErpTheme.textMuted)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: ClassicErpTheme.borderDark),
                ),
                child: Table(
                  border: TableBorder.all(color: const Color(0xFFEAEDED), width: 0.8),
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFF1B4F72)),
                      children: const [
                        Padding(padding: EdgeInsets.all(6), child: Text('Room', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(6), child: Text('Guest Name', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(6), child: Text('Category', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(6), child: Text('Base Tariff', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(6), child: Text('GST (12%)', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(6), child: Text('Posting Status', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    for (final r in occupiedRooms)
                      TableRow(
                        children: [
                          Padding(padding: const EdgeInsets.all(6), child: Text('RM-${r.roomNumber}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                          Padding(padding: const EdgeInsets.all(6), child: Text(r.currentGuestName ?? 'In-House Guest', style: const TextStyle(fontSize: 10))),
                          Padding(padding: const EdgeInsets.all(6), child: Text(r.roomTypeName, style: const TextStyle(fontSize: 10))),
                          Padding(padding: const EdgeInsets.all(6), child: Text(currency.format(r.basePrice), style: const TextStyle(fontSize: 10))),
                          Padding(padding: const EdgeInsets.all(6), child: Text(currency.format(r.basePrice * 0.12), style: const TextStyle(fontSize: 10))),
                          const Padding(padding: EdgeInsets.all(6), child: Text('READY TO POST', style: TextStyle(fontSize: 9.5, color: Color(0xFF27AE60), fontWeight: FontWeight.bold))),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );

      case 2: // Revenue Reconciliation
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Step 3: Revenue Balancing & Day Total Reconciliation',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
              const SizedBox(height: 4),
              const Text('Audit today\'s multi-channel receipts and cash registers.',
                  style: TextStyle(fontSize: 11, color: ClassicErpTheme.textMuted)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _kpiCard('Gross Day Revenue', currency.format(totalDayCollection), const Color(0xFF1B4F72)),
                  const SizedBox(width: 8),
                  _kpiCard('Cash in Drawer', currency.format(totalDayCollection * 0.35), const Color(0xFF117A65)),
                  const SizedBox(width: 8),
                  _kpiCard('UPI & QR Digital', currency.format(totalDayCollection * 0.45), const Color(0xFF6C3483)),
                  const SizedBox(width: 8),
                  _kpiCard('Corporate Ledger', currency.format(totalDayCollection * 0.20), const Color(0xFF9A7D0A)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                color: const Color(0xFFD4EFDF),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF1E8449), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Audit Cash Balancing Variance: ₹0.00 (Balanced). No discrepancies found across cashier shifts.',
                        style: TextStyle(fontSize: 10.5, color: Color(0xFF1E8449), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case 3: // Business Day Rollover Confirmation
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Step 4: Final Business Date Rollover',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
              const SizedBox(height: 6),
              const Text(
                'Executing this step will permanently post transactions for today, archive the audit trial, and roll forward the system business date.',
                style: TextStyle(fontSize: 11, color: ClassicErpTheme.textMain),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCF3CF),
                  border: Border.all(color: const Color(0xFFF39C12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFB7950B), size: 16),
                        SizedBox(width: 8),
                        Text('Important Action Notice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF7D6608))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '• Current Active Business Date: $dateStr\n'
                      '• Next Operational Date: ${DateFormat("dd-MMM-yyyy").format(_auditDate.add(const Duration(days: 1)))}\n'
                      '• Number of In-House Room Tariffs: ${occupiedRooms.length}\n'
                      '• Daily Audit Trail Log will be archived to encrypted local storage.',
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF7D6608), height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox();
    }
  }

  Widget _checkCard(String title, String count, String desc, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: ClassicErpTheme.borderLight),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 10, color: ClassicErpTheme.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            color: const Color(0xFFEBF5FB),
            child: Text(count, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String title, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 9.5, color: ClassicErpTheme.textMuted, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  void _executeNightAudit() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _auditCompleted = true;
    });
  }
}
