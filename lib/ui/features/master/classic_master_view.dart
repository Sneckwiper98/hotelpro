import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../config/app_constants.dart';
import '../../../config/classic_erp_theme.dart';
import '../../../data/models/pos_model.dart';
import '../../../data/models/room_model.dart';
import '../../../data/models/staff_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/repositories/hotel_repository.dart';
import '../../core/classic/classic_datagrid.dart';
import '../../core/classic/classic_form_widgets.dart';
// import '../../core/classic/classic_filter_box.dart';
import '../../core/classic/dialogs/classic_invoice_register_dialog.dart';
import '../../core/classic/utils/report_utils.dart';
import '../../core/components/hotel_logo_widget.dart';
import 'dialogs/user_function_rights_dialog.dart';

/// Classic Windows Desktop Hotel ERP Master View
/// High-density spreadsheets for:
/// 1. Room Tariffs & Categories Master
/// 2. Floors & Room Inventory Master
/// 3. Restaurant F&B Menu Master
/// 4. Staff & Employees Master
/// 5. User Accounts & Branch Allocation Master
class ClassicMasterView extends StatefulWidget {
  final VoidCallback? onClose;
  final VoidCallback? onMinimize;
  final VoidCallback? onMaximize;
  final bool isMaximized;
  final bool isActive;
  final int initialTab;

  const ClassicMasterView({
    super.key,
    this.onClose,
    this.onMinimize,
    this.onMaximize,
    this.isMaximized = true,
    this.isActive = true,
    this.initialTab = 0,
  });

  @override
  State<ClassicMasterView> createState() => _ClassicMasterViewState();
}

class _ClassicMasterViewState extends State<ClassicMasterView> {
  // 0: Room Tariffs, 1: Floors & Rooms, 2: F&B Menu, 3: Staff, 4: User Accounts, 5: Customer CRM
  late int _activeMasterTab;
  int _selectedRowIndex = 0;
  String _searchFilter = '';
  String _subFilter = 'ALL';
  final TextEditingController _searchController = TextEditingController();
  final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _activeMasterTab = widget.initialTab;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<HotelRepository>();
    final activeBranch = repo.activeBranch;
    final currentUser = repo.currentErpUser;
    final bool canManageUsers = currentUser.isDeveloper || currentUser.role == AppUserRole.superAdmin;

    // Safety fallback: if an unauthorized user was on tab 4, fallback to tab 0
    if (!canManageUsers && _activeMasterTab == 4) {
      _activeMasterTab = 0;
    }

    return Material(
      color: ClassicErpTheme.windowBg,
      child: Container(
        decoration: BoxDecoration(
        color: ClassicErpTheme.windowBg,
        border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── 1. MDI Sub-Window Title Bar ─────────────────────────────────
          Container(
            height: 26,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.isActive
                    ? const [Color(0xFF1B4F72), Color(0xFF2874A6)]
                    : const [Color(0xFF5D6D7E), Color(0xFF85929E)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.table_chart_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Hotel Configuration Master — [${_getTabTitle()} • ${activeBranch.name.toUpperCase()}]',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Classic Windows Minimize, Maximize, Close Buttons
                _windowButton(Icons.remove, widget.onMinimize ?? () {}),
                const SizedBox(width: 2),
                _windowButton(widget.isMaximized ? Icons.filter_none : Icons.crop_square, widget.onMaximize ?? () {}),
                const SizedBox(width: 2),
                _windowButton(Icons.close, widget.onClose ?? () {}, isClose: true),
              ],
            ),
          ),

          // ── 2. Master Module Tabs (Ribbon Row) ───────────────────────────
          Container(
            height: 28,
            color: ClassicErpTheme.menuBarBg,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _moduleTab(0, '1. Room Tariffs & Categories'),
                  _moduleTab(1, '2. Floors & Room Inventory'),
                  _moduleTab(2, '3. Restaurant F&B Menu'),
                  _moduleTab(3, '4. Staff & Employees'),
                  if (canManageUsers)
                    _moduleTab(4, '5. User Accounts & Branch Allocation', isHighlighted: true),
                  _moduleTab(5, '6. Customer CRM & Guest Directory'),
                ],
              ),
            ),
          ),

          // ── 3. Hotel Operations Toolbar (Replaced old LvlId/LocCd/ItemCd) ─
          _buildMasterToolbar(repo, activeBranch),

          // ── 4. Smart Search & Relevant Hotel Filters ──────────────────────
          _buildSearchAndFilterStrip(repo),

          // ── 4. Main DataGrid Canvas ─────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: _buildActiveDataGrid(repo),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildActiveDataGrid(HotelRepository repo) {
    final canManageUsers = repo.currentErpUser.isDeveloper || repo.currentErpUser.role == AppUserRole.superAdmin;
    switch (_activeMasterTab) {
      case 0:
        return _buildRoomTypesGrid(repo);
      case 1:
        return _buildRoomsGrid(repo);
      case 2:
        return _buildFoodMenuGrid(repo);
      case 3:
        return _buildStaffGrid(repo);
      case 4:
        if (!canManageUsers) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Access Restricted: Only Developer and Super Admin can access User Accounts & Branch Allocation.',
                style: TextStyle(
                  color: Color(0xFFC0392B),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }
        return _buildUserAccountsGrid(repo);
      case 5:
        return _buildCustomerCrmGrid(repo);
      default:
        return _buildRoomTypesGrid(repo);
    }
  }

  // ── Tab 0: Room Types & Tariffs Grid ───────────────────────────────────
  Widget _buildRoomTypesGrid(HotelRepository repo) {
    final types = repo.activeBranchRoomTypes.where((t) {
      if (_subFilter != 'ALL' && t.bedType != _subFilter) return false;
      if (_searchFilter.isEmpty) return true;
      final q = _searchFilter.toLowerCase();
      return t.name.toLowerCase().contains(q) || t.code.toLowerCase().contains(q);
    }).toList();

    final columns = const [
      ClassicGridColumn(title: 'Type Code', width: 90),
      ClassicGridColumn(title: 'Room Category Name', width: 230),
      ClassicGridColumn(title: 'Bed Type & Configuration', width: 170),
      ClassicGridColumn(title: 'Max Occupancy', width: 100, align: TextAlign.center),
      ClassicGridColumn(title: 'Base Tariff (₹)', width: 110, align: TextAlign.right),
      ClassicGridColumn(title: 'Tax Slab', width: 85, align: TextAlign.center),
      ClassicGridColumn(title: 'Master Status', width: 90, align: TextAlign.center),
    ];

    final rows = [
      for (int i = 0; i < types.length; i++)
        ClassicGridRow(
          srlNo: i + 1,
          rawData: types[i],
          cells: [
            types[i].code.toUpperCase(),
            types[i].name.toUpperCase(),
            types[i].bedType,
            '${types[i].maxAdults} Adults',
            currency.format(types[i].basePrice),
            '18% GST',
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              color: const Color(0xFFD4EFDF),
              child: const Text('ACTIVE', style: TextStyle(color: Color(0xFF1E8449), fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
    ];

    return ClassicDataGrid(
      columns: columns,
      rows: rows,
      selectedIndex: _selectedRowIndex,
      onRowSelected: (idx, row) => setState(() => _selectedRowIndex = idx),
      onRowDoubleTapped: (idx, row) => _editRoomType(row.rawData as RoomTypeModel, repo),
    );
  }

  // ── Tab 1: Floors & Room Inventory Grid ────────────────────────────────
  Widget _buildRoomsGrid(HotelRepository repo) {
    final rooms = repo.activeBranchRooms.where((r) {
      if (_subFilter != 'ALL') {
        if (_subFilter.startsWith('FLOOR_')) {
          final fl = int.tryParse(_subFilter.replaceFirst('FLOOR_', ''));
          if (fl != null && r.floorNumber != fl) return false;
        } else if (_subFilter.startsWith('STATUS_')) {
          final st = _subFilter.replaceFirst('STATUS_', '');
          if (r.status.name != st) return false;
        }
      }
      if (_searchFilter.isEmpty) return true;
      final q = _searchFilter.toLowerCase();
      return r.roomNumber.contains(q) || r.roomTypeName.toLowerCase().contains(q);
    }).toList();

    final columns = const [
      ClassicGridColumn(title: 'Room No', width: 85),
      ClassicGridColumn(title: 'Floor Lvl', width: 80, align: TextAlign.center),
      ClassicGridColumn(title: 'Room Category', width: 220),
      ClassicGridColumn(title: 'Nightly Tariff', width: 110, align: TextAlign.right),
      ClassicGridColumn(title: 'Room Status', width: 130, align: TextAlign.center),
      ClassicGridColumn(title: 'Guest In House / Res Ref', width: 210),
      ClassicGridColumn(title: 'Keycard RFID Code', width: 130, align: TextAlign.center),
    ];

    final rows = [
      for (int i = 0; i < rooms.length; i++)
        ClassicGridRow(
          srlNo: i + 1,
          rawData: rooms[i],
          cells: [
            'RM-${rooms[i].roomNumber}',
            rooms[i].floorNumber == 0 ? 'G (Lobby)' : 'Floor ${rooms[i].floorNumber}',
            rooms[i].roomTypeName.toUpperCase(),
            currency.format(rooms[i].basePrice),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: _getStatusBg(rooms[i].status),
              child: Text(
                rooms[i].status.label.toUpperCase(),
                style: TextStyle(color: _getStatusColor(rooms[i].status), fontSize: 9.5, fontWeight: FontWeight.bold),
              ),
            ),
            rooms[i].currentGuestName != null ? '${rooms[i].currentGuestName} [${rooms[i].currentReservationId ?? ""}]' : '— (VACANT) —',
            rooms[i].keycardRfid ?? 'RFID-${rooms[i].roomNumber}-A',
          ],
        ),
    ];

    return ClassicDataGrid(
      columns: columns,
      rows: rows,
      selectedIndex: _selectedRowIndex,
      onRowSelected: (idx, row) => setState(() => _selectedRowIndex = idx),
      onRowDoubleTapped: (idx, row) => _editRoomStatus(row.rawData as RoomModel, repo),
    );
  }

  // ── Tab 2: Restaurant F&B Menu Grid ───────────────────────────────────
  Widget _buildFoodMenuGrid(HotelRepository repo) {
    final menu = repo.activeBranchMenuItems.where((m) {
      if (_subFilter != 'ALL') {
        if (_subFilter == 'VEG' && !m.isVeg) return false;
        if (_subFilter == 'NON_VEG' && m.isVeg) return false;
        if (_subFilter.startsWith('CAT_') && m.category != _subFilter.replaceFirst('CAT_', '')) return false;
      }
      if (_searchFilter.isEmpty) return true;
      final q = _searchFilter.toLowerCase();
      return m.name.toLowerCase().contains(q) || m.category.toLowerCase().contains(q) || m.id.toLowerCase().contains(q);
    }).toList();

    final columns = const [
      ClassicGridColumn(title: 'Item Code', width: 80),
      ClassicGridColumn(title: 'Photo', width: 50, align: TextAlign.center),
      ClassicGridColumn(title: 'Food Item Description', width: 200),
      ClassicGridColumn(title: 'Menu Category', width: 110),
      ClassicGridColumn(title: 'Base Rate (₹)', width: 85, align: TextAlign.right),
      ClassicGridColumn(title: 'GST %', width: 55, align: TextAlign.center),
      ClassicGridColumn(title: 'Net Rate (₹)', width: 90, align: TextAlign.right),
      ClassicGridColumn(title: 'Dietary', width: 70, align: TextAlign.center),
      ClassicGridColumn(title: 'Kitchen Outlet', width: 110),
      ClassicGridColumn(title: 'Availability', width: 85, align: TextAlign.center),
    ];

    final rows = [
      for (int i = 0; i < menu.length; i++)
        ClassicGridRow(
          srlNo: i + 1,
          rawData: menu[i],
          cells: [
            menu[i].id.toUpperCase(),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: menu[i].imageUrl != null && menu[i].imageUrl!.isNotEmpty
                  ? Image.network(
                      menu[i].imageUrl!,
                      width: 34,
                      height: 24,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Text(menu[i].emoji, style: const TextStyle(fontSize: 14)),
                    )
                  : Text(menu[i].emoji, style: const TextStyle(fontSize: 14)),
            ),
            '${menu[i].emoji} ${menu[i].name.toUpperCase()}',
            menu[i].category.toUpperCase(),
            currency.format(menu[i].price),
            '${menu[i].taxRate.toStringAsFixed(0)}%',
            Text(
              currency.format(menu[i].totalPriceWithTax),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              color: menu[i].isVeg ? const Color(0xFFD4EFDF) : const Color(0xFFFADBD8),
              child: Text(
                menu[i].isVeg ? 'VEG' : 'NON-VEG',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: menu[i].isVeg ? const Color(0xFF1E8449) : const Color(0xFFC0392B), fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
            'MAIN RESTAURANT',
            menu[i].isAvailable
                ? const Text('AVAILABLE', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Color(0xFF1E8449), fontSize: 9.5, fontWeight: FontWeight.bold))
                : const Text('OFFLINE', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Color(0xFFC0392B), fontSize: 9.5, fontWeight: FontWeight.bold)),
          ],
        ),
    ];

    return ClassicDataGrid(
      columns: columns,
      rows: rows,
      selectedIndex: _selectedRowIndex,
      onRowSelected: (idx, row) => setState(() => _selectedRowIndex = idx),
      onRowDoubleTapped: (idx, row) => _editMenuItem(row.rawData as PosMenuItemModel, repo),
    );
  }

  // ── Tab 5: Customer CRM & Guest Directory Grid ────────────────────────
  Widget _buildCustomerCrmGrid(HotelRepository repo) {
    final customers = repo.registeredCustomers.where((c) {
      if (_subFilter != 'ALL') {
        if (_subFilter == 'CORPORATE' && (c.gstin == null || c.gstin!.isEmpty)) return false;
        if (_subFilter == 'INDIVIDUAL' && (c.gstin != null && c.gstin!.isNotEmpty)) return false;
        if (_subFilter == 'WALLET_CREDIT' && c.walletBalance <= 0) return false;
      }
      if (_searchFilter.isEmpty) return true;
      final q = _searchFilter.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.phone.contains(q) ||
          c.email.toLowerCase().contains(q) ||
          (c.gstin?.toLowerCase().contains(q) ?? false) ||
          (c.companyName?.toLowerCase().contains(q) ?? false) ||
          c.city.toLowerCase().contains(q);
    }).toList();

    final columns = const [
      ClassicGridColumn(title: 'Cust ID', width: 85),
      ClassicGridColumn(title: 'Customer / Guest Name', width: 180),
      ClassicGridColumn(title: 'Mobile Phone', width: 120),
      ClassicGridColumn(title: 'Email Address', width: 170),
      ClassicGridColumn(title: 'Company / Firm (B2B)', width: 190),
      ClassicGridColumn(title: 'GSTIN (Tax ID)', width: 140, align: TextAlign.center),
      ClassicGridColumn(title: 'City / Location', width: 110),
      ClassicGridColumn(title: 'Wallet Balance (₹)', width: 115, align: TextAlign.right),
      ClassicGridColumn(title: 'Total Visits', width: 85, align: TextAlign.center),
      ClassicGridColumn(title: 'Guest Category', width: 110, align: TextAlign.center),
    ];

    final rows = [
      for (int i = 0; i < customers.length; i++)
        ClassicGridRow(
          srlNo: i + 1,
          rawData: customers[i],
          cells: [
            customers[i].id.toUpperCase(),
            customers[i].name.toUpperCase(),
            customers[i].phone,
            customers[i].email.isNotEmpty ? customers[i].email : '—',
            customers[i].companyName != null && customers[i].companyName!.isNotEmpty
                ? customers[i].companyName!
                : '— (Individual Guest)',
            customers[i].gstin != null && customers[i].gstin!.isNotEmpty
                ? customers[i].gstin!
                : '— (B2C)',
            customers[i].city.isNotEmpty ? customers[i].city : (customers[i].addresses.isNotEmpty ? customers[i].addresses.first.city : '—'),
            Text(
              currency.format(customers[i].walletBalance),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: customers[i].walletBalance > 0 ? const Color(0xFF1E8449) : Colors.grey[700],
              ),
            ),
            '${customers[i].totalVisits} stays',
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              color: (customers[i].gstin != null && customers[i].gstin!.isNotEmpty)
                  ? const Color(0xFFD4E6F1)
                  : const Color(0xFFE8F8F5),
              child: Text(
                (customers[i].gstin != null && customers[i].gstin!.isNotEmpty)
                    ? 'B2B CORPORATE'
                    : 'B2C RETAIL',
                style: TextStyle(
                  color: (customers[i].gstin != null && customers[i].gstin!.isNotEmpty)
                      ? const Color(0xFF1B4F72)
                      : const Color(0xFF0E6251),
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
    ];

    return ClassicDataGrid(
      columns: columns,
      rows: rows,
      selectedIndex: _selectedRowIndex,
      onRowSelected: (idx, row) => setState(() => _selectedRowIndex = idx),
      onRowDoubleTapped: (idx, row) => _showEditCustomerDialog(row.rawData as CustomerModel, repo),
    );
  }


  // ── Tab 3: Staff & Employees Grid ─────────────────────────────────────
  Widget _buildStaffGrid(HotelRepository repo) {
    final staff = repo.activeBranchStaff.where((s) {
      if (_subFilter != 'ALL') {
        if (s.department.name != _subFilter) return false;
      }
      if (_searchFilter.isEmpty) return true;
      final q = _searchFilter.toLowerCase();
      return s.fullName.toLowerCase().contains(q) || s.id.toLowerCase().contains(q) || s.role.label.toLowerCase().contains(q);
    }).toList();

    final columns = const [
      ClassicGridColumn(title: 'Emp ID', width: 85),
      ClassicGridColumn(title: 'Employee Full Name', width: 190),
      ClassicGridColumn(title: 'Department', width: 140),
      ClassicGridColumn(title: 'Assigned Role', width: 150),
      ClassicGridColumn(title: 'Working Shift', width: 110, align: TextAlign.center),
      ClassicGridColumn(title: 'Mobile Phone', width: 120),
      ClassicGridColumn(title: 'Employment Status', width: 100, align: TextAlign.center),
    ];

    final rows = [
      for (int i = 0; i < staff.length; i++)
        ClassicGridRow(
          srlNo: i + 1,
          rawData: staff[i],
          cells: [
            staff[i].id.toUpperCase(),
            staff[i].fullName.toUpperCase(),
            staff[i].department.label.toUpperCase(),
            staff[i].role.label.toUpperCase(),
            staff[i].shift.label.split('(').first.trim().toUpperCase(),
            staff[i].phone,
            staff[i].isActive
                ? const Text('ACTIVE', style: TextStyle(color: Color(0xFF1E8449), fontSize: 9.5, fontWeight: FontWeight.bold))
                : const Text('DISABLED', style: TextStyle(color: Color(0xFFC0392B), fontSize: 9.5, fontWeight: FontWeight.bold)),
          ],
        ),
    ];

    return ClassicDataGrid(
      columns: columns,
      rows: rows,
      selectedIndex: _selectedRowIndex,
      onRowSelected: (idx, row) => setState(() => _selectedRowIndex = idx),
      onRowDoubleTapped: (idx, row) => _editStaff(row.rawData as StaffModel, repo),
    );
  }

  // ── Tab 4: User Accounts & Branch Allocation Grid (CORE REQUIREMENT) ──
  Widget _buildUserAccountsGrid(HotelRepository repo) {
    final users = repo.appUsers.where((u) {
      if (_subFilter != 'ALL') {
        if (u.role.name != _subFilter) return false;
      }
      if (_searchFilter.isEmpty) return true;
      final q = _searchFilter.toLowerCase();
      return u.username.toLowerCase().contains(q) ||
          u.displayName.toLowerCase().contains(q) ||
          u.role.label.toLowerCase().contains(q);
    }).toList();

    final branches = repo.branches;
    final branchesMap = {for (var b in branches) b.id: b};

    final columns = const [
      ClassicGridColumn(title: 'User ID', width: 75),
      ClassicGridColumn(title: 'Login Username', width: 110),
      ClassicGridColumn(title: 'Operator Display Name', width: 160),
      ClassicGridColumn(title: 'System Role', width: 135),
      ClassicGridColumn(title: 'Allowed Platforms & Apps', width: 220),
      ClassicGridColumn(title: 'Password', width: 75, align: TextAlign.center),
      ClassicGridColumn(title: 'Allocated Branches (Allowed)', width: 200),
      ClassicGridColumn(title: 'Status', width: 75, align: TextAlign.center),
    ];

    final rows = [
      for (int i = 0; i < users.length; i++)
        ClassicGridRow(
          srlNo: i + 1,
          rawData: users[i],
          cells: [
            users[i].id.toUpperCase(),
            '@${users[i].username}',
            users[i].displayName,
            users[i].role.label,
            // Display allowed apps as badges
            Wrap(
              spacing: 3,
              runSpacing: 2,
              children: [
                if (users[i].canAccessApp('windows_erp'))
                  _win32AppBadge('Win ERP', const Color(0xFF1B4F72)),
                if (users[i].canAccessApp('waiter_pos'))
                  _win32AppBadge('Waiter', const Color(0xFF1E8449)),
                if (users[i].canAccessApp('delivery_boy'))
                  _win32AppBadge('Rider', const Color(0xFFD35400)),
                if (users[i].canAccessApp('housekeeping'))
                  _win32AppBadge('HK', const Color(0xFF6C3483)),
                if (users[i].canAccessApp('manager_mis'))
                  _win32AppBadge('MIS', const Color(0xFF922B21)),
              ],
            ),
            // Password status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              color: users[i].password.isNotEmpty ? const Color(0xFFD4EFDF) : const Color(0xFFFADBD8),
              child: Text(
                users[i].password.isNotEmpty ? 'SET' : 'NONE',
                style: TextStyle(
                  color: users[i].password.isNotEmpty ? const Color(0xFF196F3D) : const Color(0xFF922B21),
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Display allocated branches as readable names
            Text(
              users[i].branchAccess
                  .map((bid) => branchesMap[bid]?.name ?? bid)
                  .join(' • '),
              style: TextStyle(
                fontSize: 10,
                color: users[i].branchAccess.length > 1 ? const Color(0xFF1B4F72) : const Color(0xFF27AE60),
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            users[i].isActive
                ? const Text('ACTIVE', style: TextStyle(color: Color(0xFF1E8449), fontSize: 9.5, fontWeight: FontWeight.bold))
                : const Text('DISABLED', style: TextStyle(color: Color(0xFFC0392B), fontSize: 9.5, fontWeight: FontWeight.bold)),
          ],
        ),
    ];

    return ClassicDataGrid(
      columns: columns,
      rows: rows,
      selectedIndex: _selectedRowIndex,
      onRowSelected: (idx, row) => setState(() => _selectedRowIndex = idx),
      onRowDoubleTapped: (idx, row) => _showBranchAllocationDialog(row.rawData as AppUserModel, repo),
    );
  }

  Widget _win32AppBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ── Win32 Dialog: Edit User Security, Password & App Access ───────────
  void _showBranchAllocationDialog(AppUserModel user, HotelRepository repo) {
    final currentUser = repo.currentErpUser;
    final canManageUsers = currentUser.isDeveloper || currentUser.role == AppUserRole.superAdmin;
    if (!canManageUsers) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied: Only Developer and Super Admin can manage user accounts.'),
          backgroundColor: Color(0xFFC0392B),
        ),
      );
      return;
    }

    final allBranches = repo.branches;
    final selectedBranchIds = Set<String>.from(user.branchAccess);
    final selectedAppAccess = Set<String>.from(user.appAccess);
    final passCtrl = TextEditingController(text: user.password);
    bool obscurePass = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            child: Container(
              width: 540,
              decoration: BoxDecoration(
                color: ClassicErpTheme.panelBg,
                border: Border.all(color: ClassicErpTheme.borderDark, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title Bar
                  Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1B4F72), Color(0xFF2874A6)],
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.security_rounded, color: ClassicErpTheme.titleGold, size: 15),
                        const SizedBox(width: 6),
                        Text(
                          'User Security & Authority — [${user.displayName} (@${user.username})]',
                          style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => Navigator.pop(ctx),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Info Header
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                user.isDeveloper ? Icons.shield_rounded : Icons.account_box_rounded,
                                size: 28,
                                color: user.isDeveloper ? const Color(0xFF006266) : const Color(0xFF1B4F72),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${user.displayName} (Username: ${user.username})',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    Text(
                                      'System Role: ${user.role.label} • Active Status: ${user.isActive ? "Enabled" : "Disabled"}',
                                      style: const TextStyle(fontSize: 10.5, color: ClassicErpTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              // Function Rights Master Button
                              InkWell(
                                onTap: () {
                                  UserFunctionRightsDialog.show(context, user: user);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1B4F72),
                                    border: Border.all(color: const Color(0xFF0E3A5B)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.shield_rounded, size: 12, color: ClassicErpTheme.titleGold),
                                      SizedBox(width: 4),
                                      Text(
                                        'Rights Master',
                                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),
                        // Password Setting Field
                        Row(
                          children: [
                            const Text('Login Password:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: 26,
                                color: Colors.white,
                                child: TextField(
                                  controller: passCtrl,
                                  obscureText: obscurePass,
                                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: ClassicErpTheme.textMain),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.grey.shade400)),
                                    suffixIcon: IconButton(
                                      icon: Icon(obscurePass ? Icons.visibility_off : Icons.visibility, size: 14, color: ClassicErpTheme.textMuted),
                                      onPressed: () => setModalState(() => obscurePass = !obscurePass),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),
                        const Text(
                          'ALLOWED PLATFORMS & MOBILE APPS (STRICT ACCESS CONTROL):',
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: ClassicErpTheme.borderDark),
                          ),
                          child: Column(
                            children: [
                              _appCheckRow('Windows Desktop ERP Software', 'windows_erp', selectedAppAccess, setModalState),
                              _appCheckRow('Staff Waiter & Captain POS App', 'waiter_pos', selectedAppAccess, setModalState),
                              _appCheckRow('Delivery Boy & Rider Partner App', 'delivery_boy', selectedAppAccess, setModalState),
                              _appCheckRow('Housekeeping & Inspection App', 'housekeeping', selectedAppAccess, setModalState),
                              _appCheckRow('Manager & Owner Live MIS App', 'manager_mis', selectedAppAccess, setModalState),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),
                        const Text(
                          'ALLOCATED BRANCHES:',
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
                        ),
                        const SizedBox(height: 3),

                        // Checkboxes for all branches
                        Material(
                          color: Colors.white,
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                            ),
                            child: ListView(
                              padding: EdgeInsets.zero,
                              children: allBranches.map((b) {
                                final isAllocated = selectedBranchIds.contains(b.id);
                                return CheckboxListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                  controlAffinity: ListTileControlAffinity.leading,
                                  value: isAllocated,
                                  title: Text(
                                    '${b.code} — ${b.name} (${b.city})',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: isAllocated ? FontWeight.bold : FontWeight.normal,
                                      color: isAllocated ? const Color(0xFF1B4F72) : Colors.black87,
                                    ),
                                  ),
                                  activeColor: const Color(0xFF1B4F72),
                                  onChanged: (val) {
                                    setModalState(() {
                                      if (val == true) {
                                        selectedBranchIds.add(b.id);
                                      } else if (selectedBranchIds.length > 1) {
                                        selectedBranchIds.remove(b.id);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Actions Row
                        Row(
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.switch_account_rounded, size: 14),
                              label: const Text('Switch To This User', style: TextStyle(fontSize: 10.5)),
                              onPressed: () {
                                repo.switchErpUser(user.id);
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Active operator switched to ${user.displayName}. Branch filter applied!'),
                                    backgroundColor: ClassicErpTheme.mdiHeaderActive,
                                  ),
                                );
                              },
                            ),
                            const Spacer(),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                              ),
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel', style: TextStyle(fontSize: 11)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B4F72),
                                foregroundColor: Colors.white,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                              ),
                              onPressed: () {
                                if (passCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Password cannot be empty.'), backgroundColor: Colors.red),
                                  );
                                  return;
                                }
                                repo.updateAppUserDetails(
                                  user.id,
                                  password: passCtrl.text.trim(),
                                  branchAccess: selectedBranchIds.toList(),
                                  appAccess: selectedAppAccess,
                                );
                                Navigator.pop(ctx);
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Security and authority updated for ${user.displayName}!'),
                                    backgroundColor: const Color(0xFF27AE60),
                                  ),
                                );
                              },
                              child: const Text('Save Security & Authority', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
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
    );
  }

  Widget _appCheckRow(String title, String appCode, Set<String> selectedAppAccess, StateSetter setModalState) {
    final checked = selectedAppAccess.contains(appCode);
    return InkWell(
      onTap: () {
        setModalState(() {
          if (checked) {
            selectedAppAccess.remove(appCode);
          } else {
            selectedAppAccess.add(appCode);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: checked,
                activeColor: const Color(0xFF1B4F72),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (val) {
                  setModalState(() {
                    if (val == true) {
                      selectedAppAccess.add(appCode);
                    } else {
                      selectedAppAccess.remove(appCode);
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontSize: 11, color: ClassicErpTheme.textMain)),
          ],
        ),
      ),
    );
  }

  // Helper Tabs & Titles
  Widget _moduleTab(int tabIndex, String label, {bool isHighlighted = false}) {
    final isSelected = _activeMasterTab == tabIndex;
    return InkWell(
      onTap: () => setState(() {
        _activeMasterTab = tabIndex;
        _selectedRowIndex = 0;
        _searchFilter = '';
        _searchController.clear();
        _subFilter = 'ALL';
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        margin: const EdgeInsets.only(right: 2),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : (isHighlighted ? const Color(0xFFEAF2F8) : Colors.transparent),
          border: isSelected
              ? const Border(
                  top: BorderSide(color: Color(0xFF1B4F72), width: 2),
                  left: BorderSide(color: ClassicErpTheme.borderDark, width: 0.8),
                  right: BorderSide(color: ClassicErpTheme.borderDark, width: 0.8),
                )
              : (isHighlighted ? Border.all(color: Colors.blue.shade200, width: 0.8) : null),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isSelected ? const Color(0xFF1B4F72) : (isHighlighted ? Colors.blue.shade900 : ClassicErpTheme.textMain),
            fontWeight: isSelected || isHighlighted ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _getTabTitle() {
    switch (_activeMasterTab) {
      case 0: return 'Room Tariff & Categories Master';
      case 1: return 'Floors & Room Inventory Master';
      case 2: return 'Restaurant F&B Menu Master';
      case 3: return 'Staff & Payroll Master';
      case 4: return 'User Accounts & Branch Allocation Master';
      case 5: return 'Customer CRM & Guest Directory Master';
      default: return 'Hotel Master System';
    }
  }

  // ── 3. Hotel Operations Toolbar ──────────────────────────────────────────
  Widget _buildMasterToolbar(HotelRepository repo, dynamic activeBranch) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        color: ClassicErpTheme.panelBg,
        border: Border(
          bottom: BorderSide(color: ClassicErpTheme.borderDark, width: 1),
        ),
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
                  // Branch Information Badge with change branch button
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Color(0xFFC0392B)),
                            const SizedBox(width: 4),
                            Text(
                              '${activeBranch.code} — ${activeBranch.name}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B4F72),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => _showBranchLookupDialog(context, repo),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                color: const Color(0xFFEAF2F8),
                                child: const Text('Change', style: TextStyle(fontSize: 9.5, color: Color(0xFF1B4F72), fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Active Section Summary Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAFAF1),
                          border: Border.all(color: const Color(0xFFA9DFBF), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF27AE60)),
                            const SizedBox(width: 4),
                            Text(
                              _getSectionSummaryText(repo),
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF196F3D), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 10),

                  // Win32 Action Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _toolbarButton(
                        icon: Icons.add_circle_rounded,
                        label: _getAddButtonLabel(),
                        isPrimary: true,
                        onTap: () => _handleAddNewRecord(repo),
                      ),
                      const SizedBox(width: 5),
                      _toolbarButton(
                        icon: _activeMasterTab == 4 ? Icons.security_rounded : Icons.edit_note_rounded,
                        label: _activeMasterTab == 4 ? 'Edit & Security' : 'Edit Selected',
                        onTap: () => _handleEditSelected(repo),
                      ),
                      if (_activeMasterTab == 4) ...[
                        const SizedBox(width: 5),
                        _toolbarButton(
                          icon: Icons.shield_rounded,
                          label: 'Function Rights Master',
                          isPrimary: true,
                          onTap: () {
                            final list = repo.appUsers;
                            final selectedUser = (list.isNotEmpty && _selectedRowIndex < list.length)
                                ? list[_selectedRowIndex]
                                : null;
                            UserFunctionRightsDialog.show(context, user: selectedUser);
                          },
                        ),
                      ],
                      const SizedBox(width: 5),
                      _toolbarButton(
                        icon: Icons.refresh_rounded,
                        label: 'Refresh',
                        onTap: () {
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Master records reloaded and synchronized successfully.'),
                              backgroundColor: ClassicErpTheme.mdiHeaderActive,
                              duration: Duration(milliseconds: 900),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 5),
                      _toolbarButton(
                        icon: Icons.upload_file_rounded,
                        label: 'Import Excel',
                        onTap: () => _importExcel(),
                      ),
                      const SizedBox(width: 5),
                      _toolbarButton(
                        icon: Icons.table_view_rounded,
                        label: 'Export Excel',
                        isExcel: true,
                        onTap: () => _exportToExcel(),
                      ),
                      const SizedBox(width: 5),
                      _toolbarButton(
                        icon: Icons.print_rounded,
                        label: 'Print Report',
                        onTap: () => _printCurrentGrid(),
                      ),
                      const SizedBox(width: 5),
                      _toolbarButton(
                        icon: Icons.receipt_long_rounded,
                        label: 'Invoices & Tax',
                        isPrimary: true,
                        onTap: () => ClassicInvoiceRegisterDialog.show(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── 4. Smart Search & Relevant Hotel Filters ─────────────────────────────
  Widget _buildSearchAndFilterStrip(HotelRepository repo) {
    final subFilterOptions = _getSubFilterOptions();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F6F7),
        border: Border(
          bottom: BorderSide(color: ClassicErpTheme.borderDark, width: 1),
        ),
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
                      // Search Box
                      Container(
                        width: 290,
                        height: 25,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                        ),
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.search, size: 14, color: ClassicErpTheme.textMuted),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(fontSize: 11, color: ClassicErpTheme.textMain),
                                decoration: InputDecoration(
                                  hintText: _getSearchHintText(),
                                  hintStyle: const TextStyle(fontSize: 10.5, color: Colors.grey),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _searchFilter = val.trim();
                                    _selectedRowIndex = 0;
                                  });
                                },
                              ),
                            ),
                            if (_searchFilter.isNotEmpty)
                              InkWell(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchFilter = '';
                                    _selectedRowIndex = 0;
                                  });
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: Icon(Icons.close, size: 13, color: Colors.grey),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Secondary Filter (Real Hotel Filter)
                      const Text('Filter: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain)),
                      Container(
                        height: 25,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: subFilterOptions.containsKey(_subFilter) ? _subFilter : 'ALL',
                            isDense: true,
                            style: const TextStyle(fontSize: 11, color: ClassicErpTheme.textMain, fontWeight: FontWeight.w600),
                            items: subFilterOptions.entries.map((e) {
                              return DropdownMenuItem<String>(
                                value: e.key,
                                child: Text(e.value),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _subFilter = val;
                                  _selectedRowIndex = 0;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 12),

                  // Records count badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAECEE),
                      border: Border.all(color: ClassicErpTheme.borderLight, width: 1),
                    ),
                    child: Text(
                      'Showing: ${_getFilteredRowCount(repo)} records',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _toolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool isExcel = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 25,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isPrimary
              ? const Color(0xFF1B4F72)
              : (isExcel ? const Color(0xFF1E8449) : Colors.white),
          border: Border.all(
            color: isPrimary
                ? const Color(0xFF154360)
                : (isExcel ? const Color(0xFF145A32) : ClassicErpTheme.borderDark),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x10000000), blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: (isPrimary || isExcel) ? Colors.white : const Color(0xFF1B4F72),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: (isPrimary || isExcel) ? Colors.white : ClassicErpTheme.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, String> _getSubFilterOptions() {
    switch (_activeMasterTab) {
      case 0:
        return const {
          'ALL': 'All Bed Types',
          'King Bed': 'King Bed',
          'Queen Bed': 'Queen Bed',
          'Single Bed': 'Single Bed',
          'Twin Beds': 'Twin Beds',
          'Suite': 'Suite Room',
        };
      case 1:
        return const {
          'ALL': 'All Rooms',
          'STATUS_availableClean': 'Available Clean',
          'STATUS_occupied': 'Occupied',
          'STATUS_cleanInspected': 'Inspected',
          'FLOOR_0': 'Ground Floor (Lobby)',
          'FLOOR_1': 'Floor 1',
          'FLOOR_2': 'Floor 2',
        };
      case 2:
        return const {
          'ALL': 'All Menu Items',
          'VEG': 'Pure Veg (🟢)',
          'NON_VEG': 'Non-Veg (🔴)',
          'CAT_Beverages': 'Beverages',
          'CAT_Breakfast': 'Breakfast',
          'CAT_Main Course': 'Main Course',
          'CAT_Desserts': 'Desserts',
        };
      case 3:
        return const {
          'ALL': 'All Departments',
          'frontDesk': 'Front Desk',
          'housekeeping': 'Housekeeping',
          'kitchen': 'Kitchen / Chef',
          'fbService': 'F&B Service',
          'maintenance': 'Maintenance',
          'accounts': 'Accounts',
        };
      case 4:
        return const {
          'ALL': 'All Roles',
          'developer': 'Developer',
          'superAdmin': 'Super Admin',
          'branchManager': 'Branch Manager',
          'frontDesk': 'Front Desk Agent',
          'cashier': 'Cashier / POS',
        };
      case 5:
        return const {
          'ALL': 'All Guests & Clients',
          'CORPORATE': 'Corporate & GST (B2B)',
          'INDIVIDUAL': 'Individual Guests (B2C)',
          'WALLET_CREDIT': 'With Wallet Credit (> ₹0)',
        };
      default:
        return const {'ALL': 'All'};
    }
  }

  int _getFilteredRowCount(HotelRepository repo) {
    switch (_activeMasterTab) {
      case 0:
        return repo.activeBranchRoomTypes.where((t) {
          if (_subFilter != 'ALL' && t.bedType != _subFilter) return false;
          if (_searchFilter.isEmpty) return true;
          final q = _searchFilter.toLowerCase();
          return t.name.toLowerCase().contains(q) || t.code.toLowerCase().contains(q);
        }).length;
      case 1:
        return repo.activeBranchRooms.where((r) {
          if (_subFilter != 'ALL') {
            if (_subFilter.startsWith('FLOOR_')) {
              final fl = int.tryParse(_subFilter.replaceFirst('FLOOR_', ''));
              if (fl != null && r.floorNumber != fl) return false;
            } else if (_subFilter.startsWith('STATUS_')) {
              final st = _subFilter.replaceFirst('STATUS_', '');
              if (r.status.name != st) return false;
            }
          }
          if (_searchFilter.isEmpty) return true;
          final q = _searchFilter.toLowerCase();
          return r.roomNumber.contains(q) || r.roomTypeName.toLowerCase().contains(q);
        }).length;
      case 2:
        return repo.activeBranchMenuItems.where((m) {
          if (_subFilter != 'ALL') {
            if (_subFilter == 'VEG' && !m.isVeg) return false;
            if (_subFilter == 'NON_VEG' && m.isVeg) return false;
            if (_subFilter.startsWith('CAT_') && m.category != _subFilter.replaceFirst('CAT_', '')) return false;
          }
          if (_searchFilter.isEmpty) return true;
          final q = _searchFilter.toLowerCase();
          return m.name.toLowerCase().contains(q) || m.category.toLowerCase().contains(q) || m.id.toLowerCase().contains(q);
        }).length;
      case 3:
        return repo.activeBranchStaff.where((s) {
          if (_subFilter != 'ALL') {
            if (s.department.name != _subFilter) return false;
          }
          if (_searchFilter.isEmpty) return true;
          final q = _searchFilter.toLowerCase();
          return s.fullName.toLowerCase().contains(q) || s.id.toLowerCase().contains(q) || s.role.label.toLowerCase().contains(q);
        }).length;
      case 4:
        return repo.appUsers.where((u) {
          if (_subFilter != 'ALL') {
            if (u.role.name != _subFilter) return false;
          }
          if (_searchFilter.isEmpty) return true;
          final q = _searchFilter.toLowerCase();
          return u.username.toLowerCase().contains(q) ||
              u.displayName.toLowerCase().contains(q) ||
              u.role.label.toLowerCase().contains(q);
        }).length;
      case 5:
        return repo.registeredCustomers.where((c) {
          if (_subFilter != 'ALL') {
            if (_subFilter == 'CORPORATE' && (c.gstin == null || c.gstin!.isEmpty)) return false;
            if (_subFilter == 'INDIVIDUAL' && (c.gstin != null && c.gstin!.isNotEmpty)) return false;
            if (_subFilter == 'WALLET_CREDIT' && c.walletBalance <= 0) return false;
          }
          if (_searchFilter.isEmpty) return true;
          final q = _searchFilter.toLowerCase();
          return c.name.toLowerCase().contains(q) ||
              c.phone.contains(q) ||
              c.email.toLowerCase().contains(q) ||
              (c.gstin?.toLowerCase().contains(q) ?? false) ||
              (c.companyName?.toLowerCase().contains(q) ?? false) ||
              c.city.toLowerCase().contains(q);
        }).length;
      default:
        return 0;
    }
  }

  String _getSectionSummaryText(HotelRepository repo) {
    switch (_activeMasterTab) {
      case 0:
        return '${repo.activeBranchRoomTypes.length} Room Tariffs Configured';
      case 1:
        final rooms = repo.activeBranchRooms;
        final avail = rooms.where((r) => r.status == RoomStatus.availableClean).length;
        final occ = rooms.where((r) => r.status == RoomStatus.occupied).length;
        return '${rooms.length} Rooms (Vacant: $avail • Occupied: $occ)';
      case 2:
        final items = repo.activeBranchMenuItems;
        final veg = items.where((m) => m.isVeg).length;
        return '${items.length} Menu Dishes (Veg: $veg • Non-Veg: ${items.length - veg})';
      case 3:
        return '${repo.activeBranchStaff.length} Employees in Active Roster';
      case 4:
        return '${repo.appUsers.length} Operators Registered';
      case 5:
        final b2b = repo.registeredCustomers.where((c) => c.gstin != null && c.gstin!.isNotEmpty).length;
        return '${repo.registeredCustomers.length} Guests in CRM (Corporate B2B: $b2b)';
      default:
        return 'Active Master System';
    }
  }

  String _getAddButtonLabel() {
    switch (_activeMasterTab) {
      case 0: return '+ Add Tariff';
      case 1: return '+ Add Room';
      case 2: return '+ Add Menu Item';
      case 3: return '+ Add Staff';
      case 4: return '+ Add User';
      case 5: return '+ Register Guest';
      default: return '+ Add Record';
    }
  }

  String _getSearchHintText() {
    switch (_activeMasterTab) {
      case 0: return 'Search room category or type code...';
      case 1: return 'Search room number, category, or guest...';
      case 2: return 'Search dish name, code, or category...';
      case 3: return 'Search employee name, ID, or role...';
      case 4: return 'Search username, operator name, or role...';
      case 5: return 'Search guest name, phone, GSTIN, company, or city...';
      default: return 'Search master records...';
    }
  }

  Widget _windowButton(IconData icon, VoidCallback onTap, {bool isClose = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 18,
        height: 16,
        color: isClose ? const Color(0xFFC0392B) : const Color(0xFF2C3E50),
        alignment: Alignment.center,
        child: Icon(icon, size: 10, color: Colors.white),
      ),
    );
  }

  Color _getStatusBg(RoomStatus s) {
    switch (s) {
      case RoomStatus.availableClean: return const Color(0xFFD4EFDF);
      case RoomStatus.occupied: return const Color(0xFFFADBD8);
      case RoomStatus.cleanInspected: return const Color(0xFFD5F5E3);
      default: return const Color(0xFFFCF3CF);
    }
  }

  Color _getStatusColor(RoomStatus s) {
    switch (s) {
      case RoomStatus.availableClean: return const Color(0xFF1E8449);
      case RoomStatus.occupied: return const Color(0xFFC0392B);
      case RoomStatus.cleanInspected: return const Color(0xFF196F3D);
      default: return const Color(0xFFB7950B);
    }
  }

  void _exportToExcel() {
    final repo = context.read<HotelRepository>();
    final currency = NumberFormat.currency(symbol: 'Rs.', decimalDigits: 0);
    final tabNames = ['RoomTypes', 'Rooms', 'FoodMenu', 'Staff', 'UserAccounts', 'CustomerCRM'];
    final tabName = _activeMasterTab < tabNames.length ? tabNames[_activeMasterTab] : 'Master';

    List<String> headers;
    List<List<dynamic>> rows;

    switch (_activeMasterTab) {
      case 0:
        headers = ['Code', 'Name', 'Bed Type', 'Max Adults', 'Base Price', 'Tax Slab'];
        rows = repo.activeBranchRoomTypes.map((t) => [
          t.code, t.name, t.bedType, '${t.maxAdults}', currency.format(t.basePrice), '18% GST'
        ]).toList();
        break;
      case 1:
        headers = ['Room No', 'Floor', 'Category', 'Base Price', 'Status', 'Current Guest'];
        rows = repo.activeBranchRooms.map((r) => [
          r.roomNumber,
          r.floorNumber == 0 ? 'Ground' : 'Floor ${r.floorNumber}',
          r.roomTypeName,
          currency.format(r.basePrice),
          r.status.label,
          r.currentGuestName ?? 'Vacant',
        ]).toList();
        break;
      case 2:
        headers = ['Item Code', 'Name', 'Category', 'Base Rate', 'GST%', 'Net Rate', 'Veg/Non-Veg', 'Available'];
        rows = repo.activeBranchMenuItems.map((m) => [
          m.id, m.name, m.category, currency.format(m.price),
          '${m.taxRate.toStringAsFixed(0)}%', currency.format(m.totalPriceWithTax),
          m.isVeg ? 'Veg' : 'Non-Veg',
          m.isAvailable ? 'Yes' : 'No',
        ]).toList();
        break;
      case 3:
        headers = ['Staff ID', 'Name', 'Department', 'Role', 'Status'];
        rows = repo.activeBranchStaff.map((s) => [
          s.id, s.fullName, s.department.label, s.role.label, s.isActive ? 'Active' : 'Inactive'
        ]).toList();
        break;
      case 4:
        headers = ['User ID', 'Name', 'Role', 'Branch', 'Status'];
        rows = repo.appUsers.map((u) => [
          u.username, u.displayName, u.role.label, u.branchAccess.join(', '), u.isActive ? 'Active' : 'Inactive'
        ]).toList();
        break;
      case 5:
      default:
        headers = ['Cust ID', 'Name', 'Phone', 'Email', 'Company', 'GSTIN', 'City', 'Wallet Balance', 'Visits'];
        rows = repo.registeredCustomers.map((c) => [
          c.id, c.name, c.phone, c.email, c.companyName ?? '', c.gstin ?? '', c.city, '${c.walletBalance}', '${c.totalVisits}'
        ]).toList();
    }

    ExcelExportService.saveAsCsv(
      context,
      suggestedName: 'HotelPro_Master_${tabName}_${DateTime.now().toIso8601String().substring(0, 10)}',
      headers: headers,
      rows: rows,
    );
  }

  void _printCurrentGrid() {
    final repo = context.read<HotelRepository>();
    final currency = NumberFormat.currency(symbol: 'Rs.', decimalDigits: 0);
    final tabTitles = [
      'Room Types & Tariffs Master',
      'Room Inventory Master',
      'F&B Menu Master',
      'Staff & Employees Master',
      'User Accounts Master',
      'Customer CRM & Guest Directory Master',
    ];
    final title = _activeMasterTab < tabTitles.length ? tabTitles[_activeMasterTab] : 'Hotel Master Report';

    // Build table data
    List<String> headers;
    List<List<String>> rows;
    switch (_activeMasterTab) {
      case 0:
        headers = ['Code', 'Name', 'Bed Type', 'Max Adults', 'Base Price', 'Tax'];
        rows = repo.activeBranchRoomTypes.map((t) => [
          t.code, t.name, t.bedType, '${t.maxAdults}', currency.format(t.basePrice), '18% GST'
        ]).toList();
        break;
      case 1:
        headers = ['Room No', 'Floor', 'Category', 'Price', 'Status', 'Guest'];
        rows = repo.activeBranchRooms.map((r) => [
          r.roomNumber,
          r.floorNumber == 0 ? 'Ground' : 'Floor ${r.floorNumber}',
          r.roomTypeName, currency.format(r.basePrice), r.status.label, r.currentGuestName ?? 'Vacant'
        ]).toList();
        break;
      case 2:
        headers = ['Code', 'Item Name', 'Category', 'Base Rate', 'GST%', 'Net Rate', 'Type'];
        rows = repo.activeBranchMenuItems.map((m) => [
          m.id, m.name, m.category, currency.format(m.price),
          '${m.taxRate.toStringAsFixed(0)}%', currency.format(m.totalPriceWithTax), m.isVeg ? 'Veg' : 'Non-Veg'
        ]).toList();
        break;
      case 3:
        headers = ['ID', 'Name', 'Department', 'Role', 'Status'];
        rows = repo.activeBranchStaff.map((s) => [
          s.id, s.fullName, s.department.label, s.role.label, s.isActive ? 'Active' : 'Inactive'
        ]).toList();
        break;
      case 4:
        headers = ['User ID', 'Name', 'Role', 'Branch', 'Status'];
        rows = repo.appUsers.map((u) => [
          u.username, u.displayName, u.role.label, u.branchAccess.join(', '), u.isActive ? 'Active' : 'Inactive'
        ]).toList();
        break;
      case 5:
      default:
        headers = ['Cust ID', 'Guest Name', 'Phone', 'Company (B2B)', 'GSTIN', 'City', 'Balance'];
        rows = repo.registeredCustomers.map((c) => [
          c.id, c.name, c.phone, c.companyName ?? 'Individual', c.gstin ?? '—', c.city, currency.format(c.walletBalance)
        ]).toList();
    }

    PrintPreviewDialog.show(
      context,
      title: title,
      content: _buildMasterPrintDocument(title, headers, rows, repo),
    );
  }

  Widget _buildMasterPrintDocument(
    String title,
    List<String> headers,
    List<List<String>> rows,
    HotelRepository repo,
  ) {
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
                    Text('${repo.clientBusinessName} — Master Section Report',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                    Text(title, style: const TextStyle(fontSize: 10.5, color: ClassicErpTheme.textMuted)),
                    Text('Branch: ${repo.activeBranch.name}  |  Generated: $now',
                        style: const TextStyle(fontSize: 9, color: ClassicErpTheme.textMuted)),
                  ],
                ),
              ],
            ),
            const Icon(Icons.table_chart_rounded, size: 32, color: Color(0xFF1B4F72)),
          ],
        ),
        const Divider(thickness: 1.5, color: Color(0xFF1B4F72), height: 16),
        Table(
          border: TableBorder.all(color: ClassicErpTheme.borderDark, width: 0.5),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFF1B4F72)),
              children: headers.map((h) => Padding(
                padding: const EdgeInsets.all(5),
                child: Text(h, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              )).toList(),
            ),
            ...rows.asMap().entries.map((e) => TableRow(
              decoration: BoxDecoration(color: e.key.isEven ? Colors.white : const Color(0xFFF4F6F7)),
              children: e.value.map((cell) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                child: Text(cell, style: const TextStyle(fontSize: 9, color: ClassicErpTheme.textMain)),
              )).toList(),
            )),
          ],
        ),
        const SizedBox(height: 12),
        Text('Total Records: ${rows.length}',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain)),
        const SizedBox(height: 16),
        const Divider(),
        const Text('iSecure Systems Pvt. Ltd.  •  HotelPro  •  Contact: 9326770568',
            style: TextStyle(fontSize: 8, color: ClassicErpTheme.textMuted), textAlign: TextAlign.center),
      ],
    );
  }

  void _importExcel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Excel Import Wizard opened. Select .xlsx / .csv template to bulk import master records.'),
        backgroundColor: ClassicErpTheme.mdiHeaderActive,
      ),
    );
  }

  void _handleAddNewRecord(HotelRepository repo) {
    switch (_activeMasterTab) {
      case 0:
        _showAddRoomTypeDialog(repo);
        break;
      case 1:
        _showAddRoomDialog(repo);
        break;
      case 2:
        _showAddMenuItemDialog(repo);
        break;
      case 3:
        _showAddStaffDialog(repo);
        break;
      case 4:
        final canManageUsers = repo.currentErpUser.isDeveloper || repo.currentErpUser.role == AppUserRole.superAdmin;
        if (canManageUsers) {
          _showAddUserDialog(repo);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access Denied: Only Developer and Super Admin can create user accounts.'),
              backgroundColor: Color(0xFFC0392B),
            ),
          );
        }
        break;
      case 5:
        _showRegisterCustomerDialog(repo);
        break;
    }
  }

  void _handleEditSelected(HotelRepository repo) {
    switch (_activeMasterTab) {
      case 0:
        final list = repo.activeBranchRoomTypes;
        if (list.isNotEmpty && _selectedRowIndex < list.length) {
          _editRoomType(list[_selectedRowIndex], repo);
        }
        break;
      case 1:
        final list = repo.activeBranchRooms;
        if (list.isNotEmpty && _selectedRowIndex < list.length) {
          _editRoomStatus(list[_selectedRowIndex], repo);
        }
        break;
      case 2:
        final list = repo.activeBranchMenuItems;
        if (list.isNotEmpty && _selectedRowIndex < list.length) {
          _editMenuItem(list[_selectedRowIndex], repo);
        }
        break;
      case 3:
        final list = repo.activeBranchStaff;
        if (list.isNotEmpty && _selectedRowIndex < list.length) {
          _editStaff(list[_selectedRowIndex], repo);
        }
        break;
      case 4:
        final canManageUsers = repo.currentErpUser.isDeveloper || repo.currentErpUser.role == AppUserRole.superAdmin;
        if (!canManageUsers) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access Denied: Only Developer and Super Admin can allocate branches.'),
              backgroundColor: Color(0xFFC0392B),
            ),
          );
          return;
        }
        final list = repo.appUsers;
        if (list.isNotEmpty && _selectedRowIndex < list.length) {
          _showBranchAllocationDialog(list[_selectedRowIndex], repo);
        }
        break;
      case 5:
        final list = repo.registeredCustomers;
        if (list.isNotEmpty && _selectedRowIndex < list.length) {
          _showEditCustomerDialog(list[_selectedRowIndex], repo);
        }
        break;
    }
  }

  Widget _win32DialogShell({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget content,
    required List<Widget> actions,
    double width = 450,
  }) {
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: ClassicErpTheme.panelBg,
          border: Border.all(color: ClassicErpTheme.borderDark, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Win32 Blue Title Bar
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B4F72), Color(0xFF2874A6)],
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      color: const Color(0xFFC0392B),
                      child: const Icon(Icons.close, color: Colors.white, size: 12),
                    ),
                  ),
                ],
              ),
            ),

            // Content Form Area
            Padding(
              padding: const EdgeInsets.all(12),
              child: content,
            ),

            // Win32 Button Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFE5E8E8),
                border: Border(top: BorderSide(color: ClassicErpTheme.borderLight, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _win32InputField(String label, TextEditingController ctrl, {bool isNumeric = false, String? hint, String? prefixText, ValueChanged<String>? onChanged}) {
    return ClassicErpInput(
      label: label,
      controller: ctrl,
      isNumeric: isNumeric,
      hintText: hint,
      prefixText: prefixText,
      onChanged: onChanged,
    );
  }

  Widget _win32DialogButton(String label, VoidCallback onTap, {bool isPrimary = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF1B4F72) : ClassicErpTheme.buttonBg,
          border: Border.all(
            color: isPrimary ? const Color(0xFF154360) : ClassicErpTheme.borderDark,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isPrimary ? Colors.white : ClassicErpTheme.textMain,
          ),
        ),
      ),
    );
  }

  void _editRoomType(RoomTypeModel rt, HotelRepository repo) {
    final priceCtrl = TextEditingController(text: rt.basePrice.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => _win32DialogShell(
        context: ctx,
        title: 'Edit Room Tariff — ${rt.name}',
        icon: Icons.price_change_rounded,
        width: 380,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8F5),
                border: Border.all(color: const Color(0xFFA3E4D7)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF117864)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Category Code: ${rt.code.toUpperCase()} • Bed: ${rt.bedType}',
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF117864), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _win32InputField('Nightly Base Tariff (₹) *', priceCtrl, isNumeric: true, prefixText: '₹ '),
          ],
        ),
        actions: [
          _win32DialogButton('Cancel', () => Navigator.pop(ctx)),
          const SizedBox(width: 8),
          _win32DialogButton('Save & Update', () {
            final newPrice = double.tryParse(priceCtrl.text);
            if (newPrice != null) {
              repo.updateRoomTypePrice(rt.id, newPrice);
              Navigator.pop(ctx);
              setState(() {});
            }
          }, isPrimary: true),
        ],
      ),
    );
  }

  void _editRoomStatus(RoomModel room, HotelRepository repo) {
    RoomStatus selected = room.status;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => _win32DialogShell(
          context: ctx,
          title: 'Room ${room.roomNumber} — Update Status',
          icon: Icons.hotel_rounded,
          width: 380,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClassicErpDropdown<RoomStatus>(
                label: 'Select Operational Status',
                isRequired: true,
                value: selected,
                items: RoomStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selected = val);
                },
              ),
            ],
          ),
          actions: [
            _win32DialogButton('Cancel', () => Navigator.pop(ctx)),
            const SizedBox(width: 8),
            _win32DialogButton('Update Status', () {
              repo.updateRoomStatus(room.id, selected);
              Navigator.pop(ctx);
              setState(() {});
            }, isPrimary: true),
          ],
        ),
      ),
    );
  }

  void _editMenuItem(PosMenuItemModel item, HotelRepository repo) {
    final nameCtrl = TextEditingController(text: item.name);
    final priceCtrl = TextEditingController(text: item.price.toStringAsFixed(0));
    final imageUrlCtrl = TextEditingController(text: item.imageUrl ?? '');
    String category = item.category;
    double taxRate = item.taxRate;
    bool isAvailable = item.isAvailable;
    bool isVeg = item.isVeg;
    String emoji = item.emoji;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final double base = double.tryParse(priceCtrl.text) ?? item.price;
          final double cgst = (base * (taxRate / 2)) / 100;
          final double sgst = (base * (taxRate / 2)) / 100;
          final double totalWithGst = base + cgst + sgst;

          return _win32DialogShell(
            context: ctx,
            title: 'Edit F&B Menu Item & Tax — ${item.name}',
            icon: Icons.restaurant_menu_rounded,
            width: 540,
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _win32InputField('Item Name *', nameCtrl),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClassicErpDropdown<String>(
                          label: 'Menu Category',
                          isRequired: true,
                          value: ['Starters', 'Main Course', 'Breads & Rice', 'Desserts', 'Beverages', 'Cocktails'].contains(category) ? category : 'Main Course',
                          items: ['Starters', 'Main Course', 'Breads & Rice', 'Desserts', 'Beverages', 'Cocktails']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setModalState(() => category = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _win32InputField(
                          'Base Selling Price (₹) *',
                          priceCtrl,
                          isNumeric: true,
                          prefixText: '₹ ',
                          onChanged: (_) => setModalState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClassicErpDropdown<double>(
                          label: 'GST Tax Slab Rate',
                          isRequired: true,
                          value: [0.0, 5.0, 12.0, 18.0].contains(taxRate) ? taxRate : 5.0,
                          items: const [
                            DropdownMenuItem(value: 0.0, child: Text('0% — Tax Exempt')),
                            DropdownMenuItem(value: 5.0, child: Text('5% — Restaurant Food GST')),
                            DropdownMenuItem(value: 12.0, child: Text('12% — AC Dining / Banquet')),
                            DropdownMenuItem(value: 18.0, child: Text('18% — Bar & Luxury Dining')),
                          ],
                          onChanged: (v) {
                            if (v != null) setModalState(() => taxRate = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Live Tax Calculation Strip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF5FB),
                      border: Border.all(color: const Color(0xFFAED6F1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Base Rate: ₹${base.toStringAsFixed(2)}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
                            Text('CGST (${(taxRate / 2).toStringAsFixed(1)}%): ₹${cgst.toStringAsFixed(2)}  •  SGST (${(taxRate / 2).toStringAsFixed(1)}%): ₹${sgst.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 10, color: Color(0xFF7D6608))),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Net MRP (GST Included)', style: TextStyle(fontSize: 9.5, color: ClassicErpTheme.textMuted)),
                            Text('₹${totalWithGst.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Photo & Image URL with Live Thumbnail Preview
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F4),
                          border: Border.all(color: ClassicErpTheme.borderDark),
                        ),
                        child: imageUrlCtrl.text.trim().isNotEmpty
                            ? ClipRRect(
                                child: Image.network(
                                  imageUrlCtrl.text.trim(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
                                ),
                              )
                            : Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _win32InputField(
                              'Dish Photo / Image URL',
                              imageUrlCtrl,
                              hint: 'https://images.unsplash.com/...',
                              onChanged: (_) => setModalState(() {}),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Or click a preset photo below to quickly assign:',
                              style: TextStyle(fontSize: 9.5, color: ClassicErpTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Preset Photo Chips
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _presetPhotoChip('🍛 Biryani', 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=300&q=80', imageUrlCtrl, () => setModalState(() => emoji = '🍛')),
                      _presetPhotoChip('🧀 Paneer', 'https://images.unsplash.com/photo-1567184109890-9a660c14dd59?w=300&q=80', imageUrlCtrl, () => setModalState(() => emoji = '🧀')),
                      _presetPhotoChip('🍗 Chicken', 'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=300&q=80', imageUrlCtrl, () => setModalState(() => emoji = '🍗')),
                      _presetPhotoChip('🍲 Dal Makhani', 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=300&q=80', imageUrlCtrl, () => setModalState(() => emoji = '🍲')),
                      _presetPhotoChip('🫓 Naan', 'https://images.unsplash.com/photo-1626074353765-517a681e40be?w=300&q=80', imageUrlCtrl, () => setModalState(() => emoji = '🫓')),
                      _presetPhotoChip('🥞 Dosa', 'https://images.unsplash.com/photo-1668236543090-82eba5ee5976?w=300&q=80', imageUrlCtrl, () => setModalState(() => emoji = '🥞')),
                      _presetPhotoChip('🍨 Brownie', 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=300&q=80', imageUrlCtrl, () => setModalState(() => emoji = '🍨')),
                      _presetPhotoChip('🍹 Mojito', 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=300&q=80', imageUrlCtrl, () => setModalState(() => emoji = '🍹')),
                      _presetPhotoChip('☕ Coffee', 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=300&q=80', imageUrlCtrl, () => setModalState(() => emoji = '☕')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                          ),
                          child: SwitchListTile(
                            dense: true,
                            title: const Text('Available in Kitchen', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                            value: isAvailable,
                            activeThumbColor: const Color(0xFF1B4F72),
                            onChanged: (val) => setModalState(() => isAvailable = val),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                          ),
                          child: SwitchListTile(
                            dense: true,
                            title: Text(isVeg ? 'Pure Veg' : 'Non-Veg', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: isVeg ? const Color(0xFF1E8449) : const Color(0xFFC0392B))),
                            value: isVeg,
                            activeThumbColor: const Color(0xFF27AE60),
                            onChanged: (val) => setModalState(() => isVeg = val),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              _win32DialogButton('Cancel', () => Navigator.pop(ctx)),
              const SizedBox(width: 8),
              _win32DialogButton('Save Changes', () {
                final p = double.tryParse(priceCtrl.text) ?? item.price;
                repo.updateMenuItem(
                  item.id,
                  name: nameCtrl.text.trim(),
                  category: category,
                  price: p,
                  taxRate: taxRate,
                  isAvailable: isAvailable,
                  isVeg: isVeg,
                  imageUrl: imageUrlCtrl.text.trim().isNotEmpty ? imageUrlCtrl.text.trim() : null,
                  emoji: emoji,
                );
                Navigator.pop(ctx);
                setState(() {});
              }, isPrimary: true),
            ],
          );
        },
      ),
    );
  }

  Widget _presetPhotoChip(String label, String url, TextEditingController controller, VoidCallback onSelected) {
    return InkWell(
      onTap: () {
        controller.text = url;
        onSelected();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFEAECEE),
          border: Border.all(color: ClassicErpTheme.borderLight),
        ),
        child: Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _editStaff(StaffModel staff, HotelRepository repo) {
    bool isActive = staff.isActive;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => _win32DialogShell(
          context: ctx,
          title: 'Staff Member — ${staff.fullName}',
          icon: Icons.badge_rounded,
          width: 380,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: ClassicErpTheme.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Department: ${staff.department.name.toUpperCase()}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMuted)),
                    const SizedBox(height: 2),
                    Text('Phone: ${staff.phone}', style: const TextStyle(fontSize: 11, color: ClassicErpTheme.textMain)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                ),
                child: SwitchListTile(
                  dense: true,
                  title: const Text('Active Staff Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  value: isActive,
                  activeThumbColor: const Color(0xFF27AE60),
                  onChanged: (v) => setModalState(() => isActive = v),
                ),
              ),
            ],
          ),
          actions: [
            _win32DialogButton('Cancel', () => Navigator.pop(ctx)),
            const SizedBox(width: 8),
            _win32DialogButton('Save Status', () {
              repo.toggleStaffActive(staff.id);
              Navigator.pop(ctx);
              setState(() {});
            }, isPrimary: true),
          ],
        ),
      ),
    );
  }

  void _showAddRoomTypeDialog(HotelRepository repo) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '8500');
    String bedType = 'King Bed';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => _win32DialogShell(
          context: ctx,
          title: 'Add Room Category & Base Tariff',
          icon: Icons.add_home_work_rounded,
          width: 480,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _win32InputField('Category Name (e.g. Executive Suite) *', nameCtrl, hint: 'Enter room category title'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _win32InputField('Category Code (e.g. EXC-STE) *', codeCtrl, hint: 'Short Code'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _win32InputField('Base Tariff (₹) *', priceCtrl, isNumeric: true, prefixText: '₹ '),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClassicErpDropdown<String>(
                label: 'Bed Configuration',
                isRequired: true,
                value: bedType,
                items: ['King Bed', 'Queen Bed', 'Twin Bed', 'Single Bed', 'Family Bunk'].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (v) {
                  if (v != null) setModalState(() => bedType = v);
                },
              ),
            ],
          ),
          actions: [
            _win32DialogButton('Cancel', () => Navigator.pop(ctx)),
            const SizedBox(width: 8),
            _win32DialogButton('Create Category', () {
              if (nameCtrl.text.isNotEmpty && codeCtrl.text.isNotEmpty) {
                repo.addRoomType(
                  name: nameCtrl.text.trim(),
                  code: codeCtrl.text.trim().toUpperCase(),
                  basePrice: double.tryParse(priceCtrl.text) ?? 5000,
                  bedType: bedType,
                  maxAdults: 2,
                );
                Navigator.pop(ctx);
                setState(() {});
              }
            }, isPrimary: true),
          ],
        ),
      ),
    );
  }

  void _showAddRoomDialog(HotelRepository repo) {
    final roomNoCtrl = TextEditingController();
    final roomTypes = repo.activeBranchRoomTypes;
    RoomTypeModel? selectedType = roomTypes.isNotEmpty ? roomTypes.first : null;
    int floor = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => _win32DialogShell(
          context: ctx,
          title: 'Add New Room Inventory',
          icon: Icons.meeting_room_rounded,
          width: 480,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _win32InputField('Room Number (e.g. 105, 201A) *', roomNoCtrl, hint: 'Enter room number'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClassicErpDropdown<int>(
                      label: 'Floor Level',
                      isRequired: true,
                      value: floor,
                      items: [0, 1, 2, 3, 4, 5, 6].map((f) => DropdownMenuItem(value: f, child: Text(f == 0 ? 'Ground Floor' : 'Floor $f'))).toList(),
                      onChanged: (v) {
                        if (v != null) setModalState(() => floor = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClassicErpDropdown<RoomTypeModel>(
                      label: 'Room Category',
                      isRequired: true,
                      value: selectedType,
                      items: roomTypes.map((t) => DropdownMenuItem(value: t, child: Text('${t.name} (₹${t.basePrice.toStringAsFixed(0)})'))).toList(),
                      onChanged: (v) => setModalState(() => selectedType = v),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            _win32DialogButton('Cancel', () => Navigator.pop(ctx)),
            const SizedBox(width: 8),
            _win32DialogButton('Create Room', () {
              if (roomNoCtrl.text.isNotEmpty && selectedType != null) {
                repo.addRoom(
                  roomNumber: roomNoCtrl.text.trim(),
                  floorNumber: floor,
                  roomTypeId: selectedType!.id,
                  basePrice: selectedType!.basePrice,
                );
                Navigator.pop(ctx);
                setState(() {});
              }
            }, isPrimary: true),
          ],
        ),
      ),
    );
  }

  void _showAddMenuItemDialog(HotelRepository repo) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '350');
    final imageUrlCtrl = TextEditingController();
    final outlets = repo.activeBranchOutlets;
    String? outletId = outlets.isNotEmpty ? outlets.first.id : null;
    String category = 'Main Course';
    double taxRate = 5.0;
    bool isVeg = true;
    String emoji = '🍽️';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final double base = double.tryParse(priceCtrl.text) ?? 350.0;
          final double cgst = (base * (taxRate / 2)) / 100;
          final double sgst = (base * (taxRate / 2)) / 100;
          final double totalWithGst = base + cgst + sgst;

          return _win32DialogShell(
            context: ctx,
            title: 'Add Food & Beverage Menu Item (Photo, Price & GST)',
            icon: Icons.fastfood_rounded,
            width: 550,
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _win32InputField('Item Name *', nameCtrl, hint: 'e.g. Royal Murgh Dum Biryani'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClassicErpDropdown<String>(
                          label: 'Menu Category',
                          isRequired: true,
                          value: category,
                          items: ['Starters', 'Main Course', 'Breads & Rice', 'Desserts', 'Beverages', 'Cocktails']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setModalState(() => category = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _win32InputField(
                          'Base Selling Price (₹) *',
                          priceCtrl,
                          isNumeric: true,
                          prefixText: '₹ ',
                          onChanged: (_) => setModalState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClassicErpDropdown<double>(
                          label: 'GST Tax Slab Rate',
                          isRequired: true,
                          value: taxRate,
                          items: const [
                            DropdownMenuItem(value: 0.0, child: Text('0% — Tax Exempt')),
                            DropdownMenuItem(value: 5.0, child: Text('5% — Restaurant Food GST')),
                            DropdownMenuItem(value: 12.0, child: Text('12% — AC Dining / Banquet')),
                            DropdownMenuItem(value: 18.0, child: Text('18% — Bar & Luxury Dining')),
                          ],
                          onChanged: (v) {
                            if (v != null) setModalState(() => taxRate = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Live Tax Calculation Strip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF5FB),
                      border: Border.all(color: const Color(0xFFAED6F1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Base Rate: ₹${base.toStringAsFixed(2)}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
                            Text('CGST (${(taxRate / 2).toStringAsFixed(1)}%): ₹${cgst.toStringAsFixed(2)}  •  SGST (${(taxRate / 2).toStringAsFixed(1)}%): ₹${sgst.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 10, color: Color(0xFF7D6608))),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Net MRP (GST Included)', style: TextStyle(fontSize: 9.5, color: ClassicErpTheme.textMuted)),
                            Text('₹${totalWithGst.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Photo & Image URL with Live Thumbnail Preview
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F4),
                          border: Border.all(color: ClassicErpTheme.borderDark),
                        ),
                        child: imageUrlCtrl.text.trim().isNotEmpty
                            ? ClipRRect(
                                child: Image.network(
                                  imageUrlCtrl.text.trim(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
                                ),
                              )
                            : Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _win32InputField(
                              'Dish Photo / Image URL',
                              imageUrlCtrl,
                              hint: 'https://images.unsplash.com/...',
                              onChanged: (_) => setModalState(() {}),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Or click a preset food photo to autofill:',
                              style: TextStyle(fontSize: 9.5, color: ClassicErpTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Preset Photo Chips
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _presetPhotoChip('🍛 Biryani', 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=300&q=80', imageUrlCtrl, () {
                        setModalState(() {
                          emoji = '🍛';
                          if (nameCtrl.text.isEmpty) nameCtrl.text = 'Hyderabadi Dum Biryani';
                          category = 'Main Course';
                        });
                      }),
                      _presetPhotoChip('🧀 Paneer', 'https://images.unsplash.com/photo-1567184109890-9a660c14dd59?w=300&q=80', imageUrlCtrl, () {
                        setModalState(() {
                          emoji = '🧀';
                          if (nameCtrl.text.isEmpty) nameCtrl.text = 'Paneer Butter Masala';
                          category = 'Main Course';
                          isVeg = true;
                        });
                      }),
                      _presetPhotoChip('🍗 Chicken', 'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=300&q=80', imageUrlCtrl, () {
                        setModalState(() {
                          emoji = '🍗';
                          if (nameCtrl.text.isEmpty) nameCtrl.text = 'Butter Chicken Masala';
                          category = 'Main Course';
                          isVeg = false;
                        });
                      }),
                      _presetPhotoChip('🍲 Dal Makhani', 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=300&q=80', imageUrlCtrl, () {
                        setModalState(() {
                          emoji = '🍲';
                          if (nameCtrl.text.isEmpty) nameCtrl.text = 'Dal Makhani Bukhara';
                          category = 'Main Course';
                          isVeg = true;
                        });
                      }),
                      _presetPhotoChip('🫓 Naan', 'https://images.unsplash.com/photo-1626074353765-517a681e40be?w=300&q=80', imageUrlCtrl, () {
                        setModalState(() {
                          emoji = '🫓';
                          if (nameCtrl.text.isEmpty) nameCtrl.text = 'Butter Garlic Naan Basket';
                          category = 'Breads & Rice';
                          isVeg = true;
                        });
                      }),
                      _presetPhotoChip('🥞 Dosa', 'https://images.unsplash.com/photo-1668236543090-82eba5ee5976?w=300&q=80', imageUrlCtrl, () {
                        setModalState(() {
                          emoji = '🥞';
                          if (nameCtrl.text.isEmpty) nameCtrl.text = 'Mysore Masala Dosa';
                          category = 'Breakfast';
                          isVeg = true;
                        });
                      }),
                      _presetPhotoChip('🍨 Brownie', 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=300&q=80', imageUrlCtrl, () {
                        setModalState(() {
                          emoji = '🍨';
                          if (nameCtrl.text.isEmpty) nameCtrl.text = 'Sizzling Brownie with Ice Cream';
                          category = 'Desserts';
                          isVeg = true;
                        });
                      }),
                      _presetPhotoChip('🍹 Mojito', 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=300&q=80', imageUrlCtrl, () {
                        setModalState(() {
                          emoji = '🍹';
                          if (nameCtrl.text.isEmpty) nameCtrl.text = 'Virgin Mint Mojito';
                          category = 'Beverages';
                          isVeg = true;
                        });
                      }),
                      _presetPhotoChip('☕ Coffee', 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=300&q=80', imageUrlCtrl, () {
                        setModalState(() {
                          emoji = '☕';
                          if (nameCtrl.text.isEmpty) nameCtrl.text = 'Royal Espresso Coffee';
                          category = 'Beverages';
                          isVeg = true;
                        });
                      }),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                    ),
                    child: SwitchListTile(
                      dense: true,
                      title: Row(
                        children: [
                          Icon(isVeg ? Icons.eco_rounded : Icons.kebab_dining_rounded, size: 16, color: isVeg ? const Color(0xFF27AE60) : const Color(0xFFC0392B)),
                          const SizedBox(width: 6),
                          Text(isVeg ? 'Vegetarian Dish (🟢)' : 'Non-Vegetarian Item (🔴)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      value: isVeg,
                      activeThumbColor: const Color(0xFF27AE60),
                      onChanged: (v) => setModalState(() => isVeg = v),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              _win32DialogButton('Cancel', () => Navigator.pop(ctx)),
              const SizedBox(width: 8),
              _win32DialogButton('Add Menu Item', () {
                if (nameCtrl.text.trim().isNotEmpty && outletId != null) {
                  repo.addMenuItem(
                    outletId: outletId,
                    name: nameCtrl.text.trim(),
                    category: category,
                    price: double.tryParse(priceCtrl.text) ?? 350.0,
                    taxRate: taxRate,
                    isVeg: isVeg,
                    imageUrl: imageUrlCtrl.text.trim().isNotEmpty ? imageUrlCtrl.text.trim() : null,
                  );
                  Navigator.pop(ctx);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Menu item "${nameCtrl.text.trim()}" created successfully.'),
                      backgroundColor: const Color(0xFF1E8449),
                    ),
                  );
                }
              }, isPrimary: true),
            ],
          );
        },
      ),
    );
  }

  void _showRegisterCustomerDialog(HotelRepository repo) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final cityCtrl = TextEditingController(text: repo.activeBranch.city);
    final companyCtrl = TextEditingController();
    final gstinCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final walletCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => _win32DialogShell(
          context: ctx,
          title: 'Register New Customer / Corporate Guest (CRM)',
          icon: Icons.person_add_alt_1_rounded,
          width: 520,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _win32InputField('Guest / Customer Full Name *', nameCtrl, hint: 'e.g. Vikram Singhania'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _win32InputField('Mobile Phone Number *', phoneCtrl, hint: '+91 98200 XXXXX'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _win32InputField('Email Address', emailCtrl, hint: 'guest@example.com'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _win32InputField('Company / Firm Name (B2B)', companyCtrl, hint: 'e.g. Tata Consultancy Services'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _win32InputField('GSTIN (15-Digit Tax ID)', gstinCtrl, hint: '27AAAAA0000A1Z5'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _win32InputField('City / Region', cityCtrl, hint: 'e.g. Mumbai'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _win32InputField('Opening Wallet Balance (₹)', walletCtrl, isNumeric: true, prefixText: '₹ '),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _win32InputField('Billing / Delivery Address', addressCtrl, hint: 'Floor, Tower, Street, Pincode'),
              ],
            ),
          ),
          actions: [
            _win32DialogButton('Cancel', () => Navigator.pop(ctx)),
            const SizedBox(width: 8),
            _win32DialogButton('Register Guest', () {
              if (nameCtrl.text.trim().isNotEmpty && phoneCtrl.text.trim().isNotEmpty) {
                final wallet = double.tryParse(walletCtrl.text) ?? 0.0;
                repo.registerCustomer(
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                  city: cityCtrl.text.trim().isNotEmpty ? cityCtrl.text.trim() : null,
                  companyName: companyCtrl.text.trim().isNotEmpty ? companyCtrl.text.trim() : null,
                  gstin: gstinCtrl.text.trim().isNotEmpty ? gstinCtrl.text.trim() : null,
                  address: addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : null,
                  walletBalance: wallet,
                );
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Guest ${nameCtrl.text.trim()} registered successfully in CRM.'),
                    backgroundColor: const Color(0xFF1E8449),
                  ),
                );
              }
            }, isPrimary: true),
          ],
        ),
      ),
    );
  }

  void _showEditCustomerDialog(CustomerModel customer, HotelRepository repo) {
    final nameCtrl = TextEditingController(text: customer.name);
    final phoneCtrl = TextEditingController(text: customer.phone);
    final emailCtrl = TextEditingController(text: customer.email);
    final cityCtrl = TextEditingController(text: customer.city);
    final companyCtrl = TextEditingController(text: customer.companyName ?? '');
    final gstinCtrl = TextEditingController(text: customer.gstin ?? '');
    final addressCtrl = TextEditingController(text: customer.displayAddress);
    final walletCtrl = TextEditingController(text: customer.walletBalance.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => _win32DialogShell(
          context: ctx,
          title: 'Customer CRM Profile — ${customer.name}',
          icon: Icons.person_rounded,
          width: 540,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top CRM Highlights Card
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2F8),
                    border: Border.all(color: const Color(0xFFAED6F1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cust ID: ${customer.id.toUpperCase()} • ${customer.totalVisits} Total Visits', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
                          const SizedBox(height: 2),
                          Text('Joined: ${DateFormat("dd-MMM-yyyy").format(customer.joinedDate)}', style: const TextStyle(fontSize: 9.5, color: ClassicErpTheme.textMuted)),
                        ],
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_card_rounded, size: 13),
                        label: const Text('+ Credit ₹500', style: TextStyle(fontSize: 10)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E8449),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                        onPressed: () {
                          repo.addCustomerWalletCredits(customer.id, 500);
                          final cur = double.tryParse(walletCtrl.text) ?? customer.walletBalance;
                          walletCtrl.text = (cur + 500).toStringAsFixed(0);
                          setModalState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Added ₹500 advance credit to wallet!'), backgroundColor: Color(0xFF1E8449)),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _win32InputField('Customer / Guest Name *', nameCtrl),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _win32InputField('Mobile Phone *', phoneCtrl)),
                    const SizedBox(width: 8),
                    Expanded(child: _win32InputField('Email Address', emailCtrl)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _win32InputField('Company / Firm (B2B)', companyCtrl)),
                    const SizedBox(width: 8),
                    Expanded(child: _win32InputField('GSTIN (Tax ID)', gstinCtrl)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _win32InputField('City / Region', cityCtrl)),
                    const SizedBox(width: 8),
                    Expanded(child: _win32InputField('Wallet Balance (₹)', walletCtrl, isNumeric: true, prefixText: '₹ ')),
                  ],
                ),
                const SizedBox(height: 8),
                _win32InputField('Billing / Delivery Address', addressCtrl),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                repo.deleteCustomer(customer.id);
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Customer ${customer.name} removed from CRM.'), backgroundColor: const Color(0xFFC0392B)),
                );
              },
              child: const Text('Delete Profile', style: TextStyle(color: Color(0xFFC0392B), fontSize: 11)),
            ),
            const Spacer(),
            _win32DialogButton('Cancel', () => Navigator.pop(ctx)),
            const SizedBox(width: 8),
            _win32DialogButton('Save Changes', () {
              final w = double.tryParse(walletCtrl.text) ?? customer.walletBalance;
              repo.updateCustomerDetails(
                customer.id,
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                city: cityCtrl.text.trim().isNotEmpty ? cityCtrl.text.trim() : null,
                companyName: companyCtrl.text.trim().isNotEmpty ? companyCtrl.text.trim() : null,
                gstin: gstinCtrl.text.trim().isNotEmpty ? gstinCtrl.text.trim() : null,
                address: addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : null,
                walletBalance: w,
              );
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Customer profile for ${nameCtrl.text.trim()} updated.'), backgroundColor: const Color(0xFF1E8449)),
              );
            }, isPrimary: true),
          ],
        ),
      ),
    );
  }

  void _showAddStaffDialog(HotelRepository repo) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    StaffDepartment department = StaffDepartment.frontDesk;
    StaffRole role = StaffRole.frontDeskAgent;
    StaffShift shift = StaffShift.morning;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => _win32DialogShell(
          context: ctx,
          title: 'Register Staff Employee',
          icon: Icons.person_add_alt_1_rounded,
          width: 480,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _win32InputField('Full Name *', nameCtrl, hint: 'Employee Full Name'),
              const SizedBox(height: 8),
              _win32InputField('Mobile Phone Number *', phoneCtrl, hint: '+91 98000 00000'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClassicErpDropdown<StaffDepartment>(
                      label: 'Department',
                      isRequired: true,
                      value: department,
                      items: StaffDepartment.values.map((d) => DropdownMenuItem(value: d, child: Text(d.name.toUpperCase()))).toList(),
                      onChanged: (v) {
                        if (v != null) setModalState(() => department = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClassicErpDropdown<StaffShift>(
                      label: 'Shift',
                      isRequired: true,
                      value: shift,
                      items: StaffShift.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()))).toList(),
                      onChanged: (v) {
                        if (v != null) setModalState(() => shift = v);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            _win32DialogButton('Cancel', () => Navigator.pop(ctx)),
            const SizedBox(width: 8),
            _win32DialogButton('Register Staff', () {
              if (nameCtrl.text.isNotEmpty) {
                repo.addStaff(
                  fullName: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.isNotEmpty ? phoneCtrl.text.trim() : '+91 98000 00000',
                  department: department,
                  role: role,
                  shift: shift,
                );
                Navigator.pop(ctx);
                setState(() {});
              }
            }, isPrimary: true),
          ],
        ),
      ),
    );
  }

  void _showAddUserDialog(HotelRepository repo) {
    final currentUser = repo.currentErpUser;
    final canManageUsers = currentUser.isDeveloper || currentUser.role == AppUserRole.superAdmin;
    if (!canManageUsers) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied: Only Developer and Super Admin can create user accounts.'),
          backgroundColor: Color(0xFFC0392B),
        ),
      );
      return;
    }

    final userCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: 'Admin@123');
    bool obscurePass = true;
    AppUserRole role = AppUserRole.frontDeskAgent;
    final allBranches = repo.branches;
    final selectedBranches = <String>{repo.activeBranch.id};
    final selectedAppAccess = <String>{'windows_erp', 'waiter_pos'};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => _win32DialogShell(
          context: ctx,
          title: 'Add User — Windows ERP & Android Mobile Apps',
          icon: Icons.manage_accounts_rounded,
          width: 530,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _win32InputField('Login Username *', userCtrl, hint: 'e.g. priya.waiter'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _win32InputField('Display Name *', nameCtrl, hint: 'e.g. Priya Singh'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Login Password *', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain)),
                        const SizedBox(height: 3),
                        Container(
                          height: 26,
                          color: Colors.white,
                          child: TextField(
                            controller: passCtrl,
                            obscureText: obscurePass,
                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: ClassicErpTheme.textMain),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.grey.shade400)),
                              suffixIcon: IconButton(
                                icon: Icon(obscurePass ? Icons.visibility_off : Icons.visibility, size: 14, color: ClassicErpTheme.textMuted),
                                onPressed: () => setModalState(() => obscurePass = !obscurePass),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClassicErpDropdown<AppUserRole>(
                      label: 'User Role & Permissions',
                      isRequired: true,
                      value: role,
                      items: AppUserRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.label))).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setModalState(() {
                            role = v;
                            selectedAppAccess.clear();
                            selectedAppAccess.addAll(v.defaultAppAccess);
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text('Allowed Platforms & Mobile Apps *', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: ClassicErpTheme.borderDark),
                ),
                child: Column(
                  children: [
                    _appCheckRow('Windows Desktop ERP Software', 'windows_erp', selectedAppAccess, setModalState),
                    _appCheckRow('Staff Waiter & Captain POS App', 'waiter_pos', selectedAppAccess, setModalState),
                    _appCheckRow('Delivery Boy & Rider Partner App', 'delivery_boy', selectedAppAccess, setModalState),
                    _appCheckRow('Housekeeping & Inspection App', 'housekeeping', selectedAppAccess, setModalState),
                    _appCheckRow('Manager & Owner Live MIS App', 'manager_mis', selectedAppAccess, setModalState),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text('Allocate Accessible Branches *', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ClassicErpTheme.textMain)),
              const SizedBox(height: 3),
              Material(
                color: Colors.white,
                child: Container(
                  height: 75,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    children: allBranches.map((b) => CheckboxListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      title: Text('${b.code} — ${b.name} (${b.city})', style: const TextStyle(fontSize: 10.5, color: ClassicErpTheme.textMain)),
                      value: selectedBranches.contains(b.id),
                      activeColor: const Color(0xFF1B4F72),
                      onChanged: (v) {
                        setModalState(() {
                          if (v == true) {
                            selectedBranches.add(b.id);
                          } else if (selectedBranches.length > 1) {
                            selectedBranches.remove(b.id);
                          }
                        });
                      },
                    )).toList(),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            _win32DialogButton('Cancel', () => Navigator.pop(ctx)),
            const SizedBox(width: 8),
            _win32DialogButton('Create Operator', () {
              if (userCtrl.text.isNotEmpty && nameCtrl.text.isNotEmpty && passCtrl.text.isNotEmpty) {
                repo.addAppUser(
                  username: userCtrl.text.trim(),
                  displayName: nameCtrl.text.trim(),
                  password: passCtrl.text.trim(),
                  role: role,
                  branchAccess: selectedBranches.toList(),
                  appAccess: selectedAppAccess,
                  functionRights: role.permissions,
                );
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Operator ${nameCtrl.text.trim()} created with password and granted app permissions.'),
                    backgroundColor: const Color(0xFF27AE60),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all required fields including password.'), backgroundColor: Colors.red),
                );
              }
            }, isPrimary: true),
          ],
        ),
      ),
    );
  }

  void _showBranchLookupDialog(BuildContext context, HotelRepository repo) {
    showDialog(
      context: context,
      builder: (ctx) => _win32DialogShell(
        context: ctx,
        title: 'Select Active Branch / Location',
        icon: Icons.location_city_rounded,
        width: 440,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose the branch to switch workstation context:', style: TextStyle(fontSize: 11, color: ClassicErpTheme.textMuted)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: ClassicErpTheme.borderDark, width: 1),
              ),
              child: Column(
                children: repo.accessibleBranches.map((b) {
                  final isCurrent = b.id == repo.activeBranch.id;
                  return InkWell(
                    onTap: () {
                      repo.switchBranch(b.id);
                      Navigator.pop(ctx);
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      color: isCurrent ? const Color(0xFFD4E6F1) : null,
                      child: Row(
                        children: [
                          Icon(isCurrent ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              size: 16, color: isCurrent ? const Color(0xFF1B4F72) : ClassicErpTheme.textMuted),
                          const SizedBox(width: 8),
                          Text('📍 ${b.code} — ${b.name}', style: TextStyle(fontSize: 11.5, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, color: ClassicErpTheme.textMain)),
                          const Spacer(),
                          Text(b.city, style: const TextStyle(fontSize: 10.5, color: ClassicErpTheme.textMuted)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        actions: [
          _win32DialogButton('Close', () => Navigator.pop(ctx)),
        ],
      ),
    );
  }
}
