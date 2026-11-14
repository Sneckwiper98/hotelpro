import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../config/classic_erp_theme.dart';
import '../../../../data/repositories/hotel_repository.dart';

/// HotelPro Enterprise Security & Cryptographic Audit Trail Center
/// Displays immutable, tamper-evident logs for financial & operational actions.
class SecurityAuditDialog extends StatefulWidget {
  const SecurityAuditDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => const SecurityAuditDialog(),
    );
  }

  @override
  State<SecurityAuditDialog> createState() => _SecurityAuditDialogState();
}

class _SecurityAuditDialogState extends State<SecurityAuditDialog> {
  String _searchQuery = '';
  String _selectedSeverity = 'all';
  String _selectedCategory = 'all';
  bool _isVerifying = false;
  String? _verificationResult;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final allLogs = repo.auditLogs;

    // Filter logs
    final filteredLogs = allLogs.where((l) {
      if (_selectedSeverity != 'all' && l.severity.toLowerCase() != _selectedSeverity) {
        return false;
      }
      if (_selectedCategory != 'all' && l.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesAction = l.action.toLowerCase().contains(q);
        final matchesUser = l.username.toLowerCase().contains(q);
        final matchesDetails = l.details.toLowerCase().contains(q);
        final matchesEntity = l.entityId?.toLowerCase().contains(q) ?? false;
        if (!matchesAction && !matchesUser && !matchesDetails && !matchesEntity) return false;
      }
      return true;
    }).toList();

    final categories = ['all', ...allLogs.map((l) => l.category).toSet()];

    return Dialog(
      backgroundColor: ClassicErpTheme.panelBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        width: 950,
        height: 620,
        decoration: BoxDecoration(
          color: ClassicErpTheme.panelBg,
          border: Border.all(color: ClassicErpTheme.borderDark, width: 2),
        ),
        child: Column(
          children: [
            // ── 1. Classic Windows Dialog Title Bar ───────────────────────────
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded, color: Color(0xFF38BDF8), size: 14),
                  const SizedBox(width: 8),
                  const Text(
                    'HotelPro Enterprise Security Center • Tamper-Proof Cryptographic Audit Trail',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
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

            // ── 2. Top Filter Ribbon ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  // Search
                  Container(
                    width: 240,
                    height: 26,
                    decoration: BoxDecoration(
                      border: Border.all(color: ClassicErpTheme.borderDark),
                      color: Colors.white,
                    ),
                    child: TextField(
                      style: const TextStyle(fontSize: 11),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        border: InputBorder.none,
                        hintText: 'Search audit action, user, entity...',
                        hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                        prefixIcon: Icon(Icons.search, size: 14, color: Colors.grey),
                        prefixIconConstraints: BoxConstraints(minWidth: 24, maxHeight: 20),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Category Filter
                  const Text('Category: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: ClassicErpTheme.borderDark),
                      color: Colors.white,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isDense: true,
                        style: const TextStyle(fontSize: 11, color: Colors.black87),
                        items: categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat,
                            child: Text(cat == 'all' ? 'All Categories' : cat),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCategory = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Severity Filter
                  const Text('Severity: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: ClassicErpTheme.borderDark),
                      color: Colors.white,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSeverity,
                        isDense: true,
                        style: const TextStyle(fontSize: 11, color: Colors.black87),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Severities')),
                          DropdownMenuItem(value: 'info', child: Text('Info')),
                          DropdownMenuItem(value: 'warning', child: Text('Warning')),
                          DropdownMenuItem(value: 'critical', child: Text('Critical')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedSeverity = val);
                        },
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Verify HMAC Signatures Button
                  ElevatedButton.icon(
                    onPressed: _isVerifying
                        ? null
                        : () async {
                            setState(() {
                              _isVerifying = true;
                              _verificationResult = null;
                            });
                            await Future.delayed(const Duration(milliseconds: 600));
                            bool allValid = true;
                            for (final log in allLogs) {
                              if (!log.isTamperProofValid) {
                                allValid = false;
                                break;
                              }
                            }
                            if (mounted) {
                              setState(() {
                                _isVerifying = false;
                                _verificationResult = allValid
                                    ? '✓ 100% Cryptographic Integrity Verified: All ${allLogs.length} signatures match HMAC-SHA256'
                                    : '⚠ Tamper Alert: Hash mismatch detected in log entries!';
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      elevation: 1,
                    ),
                    icon: _isVerifying
                        ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white))
                        : const Icon(Icons.verified_user_rounded, size: 13, color: Colors.greenAccent),
                    label: const Text('Verify Digital Signatures', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            // ── 3. Verification Result Banner (if run) ────────────────────────
            if (_verificationResult != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                color: _verificationResult!.contains('100%') ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                child: Text(
                  _verificationResult!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _verificationResult!.contains('100%') ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                  ),
                ),
              ),

            // ── 4. High-Density Spreadsheet Table ─────────────────────────────
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: ClassicErpTheme.borderDark),
                ),
                child: Column(
                  children: [
                    // Grid Header
                    Container(
                      height: 24,
                      color: const Color(0xFFE2E8F0),
                      child: Row(
                        children: [
                          _headerCell('Timestamp', 130),
                          _headerCell('Action', 160),
                          _headerCell('Category', 110),
                          _headerCell('Severity', 80),
                          _headerCell('Operator / Role', 140),
                          _headerCell('Entity / ID', 100),
                          _headerCell('Tamper Status', 100),
                          Expanded(child: _headerCell('Event Details & Audit Remarks', null)),
                        ],
                      ),
                    ),
                    // Grid Body
                    Expanded(
                      child: filteredLogs.isEmpty
                          ? const Center(
                              child: Text('No security audit events match the current filter criteria.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            )
                          : ListView.builder(
                              itemCount: filteredLogs.length,
                              itemBuilder: (ctx, idx) {
                                final log = filteredLogs[idx];
                                final isAlt = idx % 2 == 1;

                                Color sevColor;
                                switch (log.severity.toLowerCase()) {
                                  case 'critical':
                                    sevColor = const Color(0xFFC0392B);
                                    break;
                                  case 'warning':
                                    sevColor = const Color(0xFFD35400);
                                    break;
                                  default:
                                    sevColor = const Color(0xFF27AE60);
                                }

                                final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(log.timestamp);

                                return Container(
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: isAlt ? const Color(0xFFF8FAFC) : Colors.white,
                                    border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.5)),
                                  ),
                                  child: Row(
                                    children: [
                                      _dataCell(timeStr, 130, isMono: true),
                                      _dataCell(log.action, 160, isBold: true),
                                      _dataCell(log.category, 110),
                                      Container(
                                        width: 80,
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: sevColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(2),
                                            border: Border.all(color: sevColor, width: 0.5),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            log.severity.toUpperCase(),
                                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: sevColor),
                                          ),
                                        ),
                                      ),
                                      _dataCell('@${log.username} (${log.userRole})', 140),
                                      _dataCell(log.entityId ?? '-', 100, isMono: true),
                                      Container(
                                        width: 100,
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        child: Row(
                                          children: [
                                            Icon(
                                              log.isTamperProofValid ? Icons.check_circle_rounded : Icons.warning_rounded,
                                              size: 12,
                                              color: log.isTamperProofValid ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              log.isTamperProofValid ? 'VERIFIED' : 'TAMPERED',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                                color: log.isTamperProofValid ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: _dataCell(log.details, null, tooltip: log.details),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 5. Bottom Status Ribbon ───────────────────────────────────────
            Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              color: const Color(0xFFE2E8F0),
              child: Row(
                children: [
                  const Icon(Icons.lock_rounded, size: 12, color: Color(0xFF475569)),
                  const SizedBox(width: 6),
                  Text(
                    'Audit Entries: ${filteredLogs.length} of ${allLogs.length} total  •  Cryptographic Salt: HMAC-SHA256 Signed  •  ISO 27001 / PCI-DSS Compliant',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 12, color: Color(0xFF475569)),
                    label: const Text('Close [Esc]', style: TextStyle(fontSize: 10.5, color: Color(0xFF475569))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String title, double? width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: ClassicErpTheme.borderLight, width: 0.5)),
      ),
      child: Text(
        title,
        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
      ),
    );
  }

  Widget _dataCell(String text, double? width, {bool isBold = false, bool isMono = false, String? tooltip}) {
    final child = Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        fontFamily: isMono ? 'Consolas' : null,
        color: const Color(0xFF1E293B),
      ),
    );

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFFF1F5F9), width: 0.5)),
      ),
      child: tooltip != null ? Tooltip(message: tooltip, child: child) : child,
    );
  }
}

