import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/classic_erp_theme.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/hotel_repository.dart';

/// Function Rights Master Dialog
/// Provides a Win32 enterprise master interface for viewing and assigning
/// granular function rights and permissions to system operators.
class UserFunctionRightsDialog extends StatefulWidget {
  final AppUserModel? targetUser;

  const UserFunctionRightsDialog({super.key, this.targetUser});

  static Future<void> show(BuildContext context, {AppUserModel? user}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UserFunctionRightsDialog(targetUser: user),
    );
  }

  @override
  State<UserFunctionRightsDialog> createState() => _UserFunctionRightsDialogState();
}

class _UserFunctionRightsDialogState extends State<UserFunctionRightsDialog> {
  late String _selectedUserId;
  late Set<String> _selectedRights;
  String _activeCategory = 'Front Desk';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final repo = context.read<HotelRepository>();
    final user = widget.targetUser ?? (repo.appUsers.isNotEmpty ? repo.appUsers.first : repo.currentErpUser);
    _selectedUserId = user.id;
    _selectedRights = Set<String>.from(user.effectivePermissions);
  }

  void _onUserChanged(AppUserModel user) {
    setState(() {
      _selectedUserId = user.id;
      _selectedRights = Set<String>.from(user.effectivePermissions);
    });
  }

  void _grantAll() {
    setState(() {
      _selectedRights = HotelProFunctionRights.allRights.map((r) => r.id).toSet();
    });
  }

  void _revokeAll() {
    setState(() {
      _selectedRights.clear();
    });
  }

  void _applyRoleDefaults(AppUserModel user) {
    setState(() {
      _selectedRights = Set<String>.from(user.role.permissions);
    });
  }

  void _toggleCategoryAll(String category, bool select) {
    final rights = HotelProFunctionRights.getRightsForCategory(category);
    setState(() {
      for (final r in rights) {
        if (select) {
          _selectedRights.add(r.id);
        } else {
          _selectedRights.remove(r.id);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final users = repo.appUsers;
    final currentUser = users.firstWhere(
      (u) => u.id == _selectedUserId,
      orElse: () => repo.currentErpUser,
    );

    final categories = HotelProFunctionRights.categories;
    final categoryRights = HotelProFunctionRights.getRightsForCategory(_activeCategory).where((r) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return r.title.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q) ||
          r.id.toLowerCase().contains(q);
    }).toList();

    final totalGranted = _selectedRights.length;
    final totalAvailable = HotelProFunctionRights.allRights.length;

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Container(
        width: 860,
        height: 620,
        decoration: BoxDecoration(
          color: ClassicErpTheme.panelBg,
          border: Border.all(color: ClassicErpTheme.borderDark, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(4, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Windows Title Bar ───────────────────────────────────────────
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [ClassicErpTheme.navyHeader, Color(0xFF2471A3)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded, size: 16, color: ClassicErpTheme.titleGold),
                  const SizedBox(width: 8),
                  const Text(
                    'Function Rights Master — User Access Control & Security Matrix',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        border: Border.all(color: Colors.white24),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // ── Operator Selection Bar ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFD4E6F1),
                border: Border(bottom: BorderSide(color: ClassicErpTheme.borderDark)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_pin_rounded, size: 18, color: Color(0xFF1B4F72)),
                  const SizedBox(width: 8),
                  const Text(
                    'Select Operator:',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: ClassicErpTheme.textMain,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: ClassicErpTheme.borderDark),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: currentUser.id,
                        isDense: true,
                        style: const TextStyle(fontSize: 11.5, color: ClassicErpTheme.textMain),
                        items: users.map((u) {
                          return DropdownMenuItem<String>(
                            value: u.id,
                            child: Row(
                              children: [
                                Text(
                                  '${u.displayName} (@${u.username})',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEBF5FB),
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(color: const Color(0xFFAED6F1)),
                                  ),
                                  child: Text(
                                    u.role.label,
                                    style: const TextStyle(fontSize: 9.5, color: Color(0xFF1B4F72)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (id) {
                          if (id != null) {
                            final selected = users.firstWhere((u) => u.id == id);
                            _onUserChanged(selected);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // App Access Badges
                  Wrap(
                    spacing: 4,
                    children: [
                      if (currentUser.canAccessApp('windows_erp'))
                        _appChip('Windows ERP', const Color(0xFF1B4F72)),
                      if (currentUser.canAccessApp('waiter_pos'))
                        _appChip('Waiter POS', const Color(0xFF1E8449)),
                      if (currentUser.canAccessApp('delivery_boy'))
                        _appChip('Delivery App', const Color(0xFFD35400)),
                      if (currentUser.canAccessApp('housekeeping'))
                        _appChip('Housekeeping', const Color(0xFF6C3483)),
                      if (currentUser.canAccessApp('manager_mis'))
                        _appChip('Manager MIS', const Color(0xFF922B21)),
                    ],
                  ),
                  const Spacer(),
                  // Search Box
                  SizedBox(
                    width: 170,
                    height: 26,
                    child: TextField(
                      style: const TextStyle(fontSize: 11, color: ClassicErpTheme.textMain),
                      decoration: InputDecoration(
                        hintText: 'Search rights...',
                        hintStyle: const TextStyle(fontSize: 10.5, color: ClassicErpTheme.textMuted),
                        prefixIcon: const Icon(Icons.search, size: 14, color: ClassicErpTheme.textMuted),
                        prefixIconConstraints: const BoxConstraints(minWidth: 24),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                ],
              ),
            ),

            // ── Main Body: Category Sidebar + Rights Checklist ───────────────
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left: Category Sidebar
                  Container(
                    width: 220,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAECEE),
                      border: Border(right: BorderSide(color: ClassicErpTheme.borderDark)),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: categories.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFD5D8DC)),
                      itemBuilder: (ctx, i) {
                        final cat = categories[i];
                        final rights = HotelProFunctionRights.getRightsForCategory(cat);
                        final grantedInCat = rights.where((r) => _selectedRights.contains(r.id)).length;
                        final isSelected = cat == _activeCategory;

                        return InkWell(
                          onTap: () => setState(() => _activeCategory = cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            color: isSelected ? const Color(0xFF1B4F72) : Colors.transparent,
                            child: Row(
                              children: [
                                Icon(
                                  _categoryIcon(cat),
                                  size: 15,
                                  color: isSelected ? ClassicErpTheme.titleGold : const Color(0xFF5D6D7E),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    cat,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? Colors.white : ClassicErpTheme.textMain,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.2)
                                        : (grantedInCat > 0 ? const Color(0xFFD4EFDF) : const Color(0xFFEAEDED)),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    '$grantedInCat/${rights.length}',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : (grantedInCat > 0 ? const Color(0xFF196F3D) : const Color(0xFF7F8C8D)),
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

                  // Right: Rights Checklist for Selected Category
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          // Category Header & Sub-toolbar
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF8F9F9),
                              border: Border(bottom: BorderSide(color: Color(0xFFD5D8DC))),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '$_activeCategory Permissions',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: ClassicErpTheme.textMain,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(${categoryRights.length} function operations)',
                                  style: const TextStyle(fontSize: 10.5, color: ClassicErpTheme.textMuted),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () => _toggleCategoryAll(_activeCategory, true),
                                  icon: const Icon(Icons.done_all, size: 13, color: Color(0xFF1E8449)),
                                  label: const Text('Select Category All', style: TextStyle(fontSize: 10.5, color: Color(0xFF1E8449), fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 6),
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () => _toggleCategoryAll(_activeCategory, false),
                                  icon: const Icon(Icons.clear, size: 13, color: Color(0xFFC0392B)),
                                  label: const Text('Deselect All', style: TextStyle(fontSize: 10.5, color: Color(0xFFC0392B))),
                                ),
                              ],
                            ),
                          ),

                          // Rights Items
                          Expanded(
                            child: categoryRights.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No matching function rights found.',
                                      style: TextStyle(color: ClassicErpTheme.textMuted, fontSize: 11),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    itemCount: categoryRights.length,
                                    separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEBEDEF)),
                                    itemBuilder: (ctx, i) {
                                      final r = categoryRights[i];
                                      final isGranted = _selectedRights.contains(r.id);

                                      return InkWell(
                                        onTap: () {
                                          setState(() {
                                            if (isGranted) {
                                              _selectedRights.remove(r.id);
                                            } else {
                                              _selectedRights.add(r.id);
                                            }
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          color: isGranted ? const Color(0xFFF4FBF7) : Colors.white,
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Checkbox(
                                                value: isGranted,
                                                activeColor: const Color(0xFF1E8449),
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                onChanged: (val) {
                                                  setState(() {
                                                    if (val == true) {
                                                      _selectedRights.add(r.id);
                                                    } else {
                                                      _selectedRights.remove(r.id);
                                                    }
                                                  });
                                                },
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(
                                                          r.title,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: isGranted ? FontWeight.bold : FontWeight.w600,
                                                            color: isGranted ? const Color(0xFF145A32) : ClassicErpTheme.textMain,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFEAECEE),
                                                            borderRadius: BorderRadius.circular(3),
                                                          ),
                                                          child: Text(
                                                            r.id,
                                                            style: const TextStyle(
                                                              fontSize: 8.5,
                                                              fontFamily: 'monospace',
                                                              color: Color(0xFF5D6D7E),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      r.description,
                                                      style: const TextStyle(
                                                        fontSize: 10.5,
                                                        color: ClassicErpTheme.textMuted,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Footer Toolbar & Action Buttons ──────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: ClassicErpTheme.panelBg,
                border: Border(top: BorderSide(color: ClassicErpTheme.borderDark)),
              ),
              child: Row(
                children: [
                  // Summary Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: totalGranted > 0 ? const Color(0xFFD4EFDF) : const Color(0xFFFADBD8),
                      border: Border.all(color: totalGranted > 0 ? const Color(0xFFA9DFBF) : const Color(0xFFF5B7B1)),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'Rights Granted: $totalGranted / $totalAvailable',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: totalGranted > 0 ? const Color(0xFF196F3D) : const Color(0xFF922B21),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _toolButton('Reset Role Defaults', Icons.restore_rounded, () => _applyRoleDefaults(currentUser)),
                  const SizedBox(width: 6),
                  _toolButton('Select All (37)', Icons.select_all_rounded, _grantAll),
                  const SizedBox(width: 6),
                  _toolButton('Clear All', Icons.deselect_rounded, _revokeAll),
                  const Spacer(),
                  _dialogButton('Close', () => Navigator.pop(context)),
                  const SizedBox(width: 8),
                  _dialogButton('Save Rights & Apply', () {
                    repo.updateUserFunctionRights(currentUser.id, _selectedRights);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Function rights successfully updated for ${currentUser.displayName}!'),
                        backgroundColor: const Color(0xFF1E8449),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }, isPrimary: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _toolButton(String label, IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: ClassicErpTheme.borderDark),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: const Color(0xFF1B4F72)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogButton(String text, VoidCallback onPressed, {bool isPrimary = false}) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF1B4F72) : Colors.white,
          border: Border.all(
            color: isPrimary ? const Color(0xFF0E3A5B) : ClassicErpTheme.borderDark,
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black12, offset: Offset(1, 1)),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: isPrimary ? Colors.white : ClassicErpTheme.textMain,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Front Desk': return Icons.room_service_rounded;
      case 'Billing & Folio': return Icons.receipt_long_rounded;
      case 'Restaurant POS': return Icons.restaurant_rounded;
      case 'Housekeeping': return Icons.cleaning_services_rounded;
      case 'Reservations (CRS)': return Icons.calendar_month_rounded;
      case 'Stock & Inventory': return Icons.inventory_2_rounded;
      case 'Accounting & Finance': return Icons.account_balance_wallet_rounded;
      case 'Online Delivery': return Icons.delivery_dining_rounded;
      case 'Analytics & Reports': return Icons.analytics_rounded;
      case 'Master Setup': return Icons.settings_suggest_rounded;
      default: return Icons.security_rounded;
    }
  }
}
