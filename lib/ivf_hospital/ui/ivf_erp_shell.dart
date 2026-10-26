import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/ivf_erp_theme.dart';
import '../data/repositories/ivf_hospital_repository.dart';
import '../data/services/supabase_service.dart';
import 'dialogs/hospital_settings_dialog.dart';
import 'dialogs/patient_registration_dialog.dart';
import 'dialogs/ivf_cycle_management_dialog.dart';
import 'dialogs/maternity_delivery_dialog.dart';
import 'dialogs/ivf_billing_invoice_dialog.dart';
import 'dialogs/fertility_analytics_dialog.dart';
import 'dialogs/diagnostics_lab_dialog.dart';
import 'dialogs/pharmacy_inventory_dialog.dart';
import 'dialogs/patient_record_360_dialog.dart';
import 'dialogs/follicular_tracking_dialog.dart';
import 'dialogs/semen_analysis_dialog.dart';
import 'dialogs/cryo_storage_dialog.dart';
import 'dialogs/bed_ward_matrix_dialog.dart';
import 'dialogs/opd_token_queue_dialog.dart';
import 'dialogs/art_consent_forms_dialog.dart';
import 'dialogs/daily_mis_summary_dialog.dart';
import 'widgets/hospital_logo_widget.dart';

/// Classic Win32 High-Density Desktop ERP Shell for IVFPro 360 Enterprise
/// Developed & Technology Partner: iSecure System Pvt. Ltd.
class IvfErpShell extends StatefulWidget {
  const IvfErpShell({super.key});

  @override
  State<IvfErpShell> createState() => _IvfErpShellState();
}

class _IvfErpShellState extends State<IvfErpShell> {
  int _activeViewIndex = 0; // 0: Patients, 1: IVF Cycles, 2: Maternity, 3: Billing
  String _searchQuery = '';
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<IvfHospitalRepository>();
    final config = repo.config;
    final isCloud = SupabaseService.instance.isConnected;

    return Scaffold(
      backgroundColor: IvfErpTheme.windowBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Top Enterprise Win32 Header & Branding ──────────────
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [IvfErpTheme.headerGradientStart, IvfErpTheme.headerGradientEnd],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                HospitalLogoWidget(logoPathOrUrl: config.logoPathOrUrl, size: 24),
                const SizedBox(width: 8),
                Flexible(
                  flex: 3,
                  child: Text(
                    config.hospitalName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Multi-Branch Switcher Dropdown (Bounded width with ellipsis)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220, minWidth: 120),
                  child: Container(
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      border: Border.all(color: Colors.white38),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: config.branches.any((b) => b.branchId == config.activeBranchId)
                            ? config.activeBranchId
                            : (config.branches.isNotEmpty ? config.branches.first.branchId : null),
                        dropdownColor: IvfErpTheme.primaryNavy,
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
                        isDense: true,
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                        items: config.branches.map((b) => DropdownMenuItem(
                          value: b.branchId,
                          child: Row(
                            children: [
                              const Icon(Icons.apartment_rounded, color: Colors.white70, size: 13),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  '${b.branchName} (${b.branchId})',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10.5, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                        onChanged: (newBranchId) {
                          if (newBranchId != null) {
                            repo.switchBranch(newBranchId);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Quick Settings & Logo Button
                InkWell(
                  onTap: () => HospitalSettingsDialog.show(context, repo),
                  child: Container(
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune_rounded, color: Colors.white, size: 13),
                        SizedBox(width: 4),
                        Text('Settings & Logo', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Technology Partner Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Partner: ',
                        style: TextStyle(color: Colors.white60, fontSize: 9.5),
                      ),
                      Text(
                        config.technologyPartner,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── 2. Classic Win32 Menu Bar ──────────────────────────────
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            color: IvfErpTheme.menuBarBg,
            child: Row(
              children: [
                _menuItem('File', [
                  _subMenuItem('Daily MIS Census & Revenue Summary', Icons.assessment_rounded, () => DailyMisSummaryDialog.show(context, repo)),
                  _subMenuItem('Export Patient Data (CSV/Excel)', Icons.table_view_rounded, () {}),
                  _subMenuItem('Backup Database', Icons.backup_rounded, () {}),
                ]),
                _menuItem('Master Data', [
                  _subMenuItem('Register Couple / Patient', Icons.person_add_rounded, () => PatientRegistrationDialog.show(context, repo)),
                  _subMenuItem('OPD Appointments & Token Queue', Icons.queue_rounded, () => OpdTokenQueueDialog.show(context, repo)),
                  _subMenuItem('Wards & Bed Matrix', Icons.hotel_rounded, () => BedWardMatrixDialog.show(context, repo)),
                ]),
                _menuItem('Infertility & IVF', [
                  _subMenuItem('New IVF / ICSI Cycle', Icons.add_circle_outline, () => IvfCycleManagementDialog.show(context, repo)),
                  _subMenuItem('Follicular USG Tracking Sheet', Icons.monitor_heart_rounded, () => FollicularTrackingDialog.show(context, repo)),
                  _subMenuItem('Embryology Lab & Blastocysts', Icons.science_rounded, () => IvfCycleManagementDialog.show(context, repo)),
                  _subMenuItem('Cryo & LN2 Tank Inventory', Icons.ac_unit_rounded, () => CryoStorageDialog.show(context, repo)),
                  _subMenuItem('ART Act 2021 Legal Consent Forms', Icons.gavel_rounded, () => ArtConsentFormsDialog.show(context, repo)),
                  _subMenuItem('Fertility Analytics Dashboard', Icons.analytics_rounded, () => FertilityAnalyticsDialog.show(context, repo)),
                ]),
                _menuItem('Maternity & Delivery', [
                  _subMenuItem('Antenatal Care (ANC) Register', Icons.pregnant_woman_rounded, () => MaternityDeliveryDialog.show(context, repo)),
                  _subMenuItem('Labour Room & Delivery Episode', Icons.child_friendly_rounded, () => MaternityDeliveryDialog.show(context, repo)),
                ]),
                _menuItem('Diagnostics', [
                  _subMenuItem('Pathology Lab Tests', Icons.biotech_rounded, () => DiagnosticsLabDialog.show(context, repo)),
                  _subMenuItem('WHO Semen Analysis (6th Ed)', Icons.water_drop_rounded, () => SemenAnalysisDialog.show(context, repo)),
                ]),
                _menuItem('Pharmacy', [
                  _subMenuItem('IVF Injections & Drug Stock', Icons.medication_rounded, () => PharmacyInventoryDialog.show(context, repo)),
                ]),
                _menuItem('Billing & Accounts', [
                  _subMenuItem('Hospital Bills & IVF Packages', Icons.receipt_long_rounded, () => IvfBillingInvoiceDialog.show(context, repo)),
                ]),
                _menuItem('Settings', [
                  _subMenuItem('Hospital Whitelabel & Cloud Config', Icons.settings_applications_rounded, () => HospitalSettingsDialog.show(context, repo)),
                ]),
                _menuItem('Help', [
                  _subMenuItem('About IVFPro 360 Enterprise', Icons.info_outline_rounded, () => _showAboutModal(context, config)),
                ]),
              ],
            ),
          ),

          // ── 3. High-Density Win32 Quick-Action Toolbar ──────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: const BoxDecoration(
              color: IvfErpTheme.toolbarBg,
              border: Border(
                top: BorderSide(color: Colors.white, width: 1),
                bottom: BorderSide(color: IvfErpTheme.borderDark, width: 1),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _toolbarButton(
                    icon: Icons.person_add_alt_1_rounded,
                    label: '+ Register Patient',
                    isPrimary: true,
                    onTap: () => PatientRegistrationDialog.show(context, repo),
                  ),
                  const SizedBox(width: 5),
                  _toolbarButton(
                    icon: Icons.assignment_ind_rounded,
                    label: 'Patient 360 File',
                    onTap: () {
                      if (repo.patients.isNotEmpty) {
                        PatientRecord360Dialog.show(context, repo.patients.first, repo);
                      }
                    },
                  ),
                  const SizedBox(width: 5),
                  _toolbarButton(
                    icon: Icons.queue_rounded,
                    label: 'OPD Queue',
                    onTap: () => OpdTokenQueueDialog.show(context, repo),
                  ),
                  const SizedBox(width: 5),
                  _toolbarButton(
                    icon: Icons.biotech_rounded,
                    label: 'IVF Cycles',
                    onTap: () => setState(() => _activeViewIndex = 1),
                  ),
                  const SizedBox(width: 5),
                  _toolbarButton(
                    icon: Icons.monitor_heart_rounded,
                    label: 'Follicular USG',
                    onTap: () => FollicularTrackingDialog.show(context, repo),
                  ),
                  const SizedBox(width: 5),
                  _toolbarButton(
                    icon: Icons.water_drop_rounded,
                    label: 'Semen Lab (WHO)',
                    onTap: () => SemenAnalysisDialog.show(context, repo),
                  ),
                  const SizedBox(width: 5),
                  _toolbarButton(
                    icon: Icons.ac_unit_rounded,
                    label: 'Cryo LN2 Tanks',
                    onTap: () => CryoStorageDialog.show(context, repo),
                  ),
                  const SizedBox(width: 5),
                  _toolbarButton(
                    icon: Icons.gavel_rounded,
                    label: 'ART Consents',
                    onTap: () => ArtConsentFormsDialog.show(context, repo),
                  ),
                  const SizedBox(width: 5),
                  _toolbarButton(
                    icon: Icons.hotel_rounded,
                    label: 'Bed Matrix',
                    onTap: () => BedWardMatrixDialog.show(context, repo),
                  ),
                  const SizedBox(width: 5),
                  _toolbarButton(
                    icon: Icons.pregnant_woman_rounded,
                    label: 'Maternity',
                    onTap: () => setState(() => _activeViewIndex = 2),
                  ),
                  const SizedBox(width: 5),
                  _toolbarButton(
                    icon: Icons.science_rounded,
                    label: 'Pathology Lab',
                    onTap: () => DiagnosticsLabDialog.show(context, repo),
                  ),
                  const SizedBox(width: 5),
                  _toolbarButton(
                    icon: Icons.medication_rounded,
                    label: 'Pharmacy Stock',
                    onTap: () => PharmacyInventoryDialog.show(context, repo),
                  ),
                  const SizedBox(width: 5),
                  _toolbarButton(
                    icon: Icons.receipt_long_rounded,
                    label: 'Billing & Packages',
                    onTap: () => IvfBillingInvoiceDialog.show(context, repo),
                  ),
                  const SizedBox(width: 5),
                  _toolbarButton(
                    icon: Icons.assessment_rounded,
                    label: 'Daily MIS',
                    onTap: () => DailyMisSummaryDialog.show(context, repo),
                  ),
                  const SizedBox(width: 5),
                  _toolbarButton(
                    icon: Icons.analytics_rounded,
                    label: 'Fertility Analytics',
                    onTap: () => FertilityAnalyticsDialog.show(context, repo),
                  ),
                  const SizedBox(width: 5),
                  _toolbarButton(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    onTap: () => HospitalSettingsDialog.show(context, repo),
                  ),
                ],
              ),
            ),
          ),

          // ── 4. Main View Switcher & DataGrid ─────────────────────────
          Container(
            color: const Color(0xFFE5E7E9),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                _viewTab(0, 'Patients & Couples (${repo.patients.length})', Icons.people_alt_rounded),
                const SizedBox(width: 4),
                _viewTab(1, 'IVF Cycles (${repo.ivfCycles.length})', Icons.biotech_rounded),
                const SizedBox(width: 4),
                _viewTab(2, 'Maternity & Deliveries (${repo.maternityCases.length})', Icons.child_friendly_rounded),
                const SizedBox(width: 4),
                _viewTab(3, 'Hospital Invoices (${repo.invoices.length})', Icons.receipt_rounded),
                const Spacer(),
                // Search Input Box
                Container(
                  width: 220,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: IvfErpTheme.borderDark),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: Icon(Icons.search, size: 13, color: Colors.grey),
                      ),
                      Expanded(
                        child: TextField(
                          style: const TextStyle(fontSize: 10.5),
                          decoration: const InputDecoration(
                            hintText: 'Quick Search records...',
                            hintStyle: TextStyle(fontSize: 10, color: Colors.grey),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 6),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Data Grid Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: IvfErpTheme.borderDark, width: 1),
                ),
                child: _buildActiveDataGrid(repo),
              ),
            ),
          ),

          // ── 5. Classic Win32 Status Bar ──────────────────────────────
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              color: IvfErpTheme.menuBarBg,
              border: Border(top: BorderSide(color: IvfErpTheme.borderDark, width: 1)),
            ),
            child: Row(
              children: [
                // Hospital Identity
                const Icon(Icons.business_rounded, size: 13, color: IvfErpTheme.primaryNavy),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    config.hospitalName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('|', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 8),

                // Active Branch
                const Icon(Icons.apartment_rounded, size: 13, color: IvfErpTheme.primaryNavy),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Branch: ${config.activeBranch.branchName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('|', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 8),

                // ART Act Registration Status
                Text(
                  'ART Reg: ${config.artClinicRegNumber}',
                  style: const TextStyle(fontSize: 10, color: IvfErpTheme.textMuted),
                ),
                const SizedBox(width: 8),
                const Text('|', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 8),

                // Cloud Supabase Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: isCloud ? const Color(0xFFD4EFDF) : const Color(0xFFFCF3CF),
                    border: Border.all(color: isCloud ? IvfErpTheme.medicalEmerald : IvfErpTheme.warningAmber),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCloud ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                        size: 11,
                        color: isCloud ? IvfErpTheme.medicalEmerald : const Color(0xFF7D6608),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCloud ? 'Supabase Cloud Connected' : 'Local Offline Standalone Mode',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isCloud ? const Color(0xFF196F3D) : const Color(0xFF7D6608),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Live Clock
                Text(
                  DateFormat('dd-MMM-yyyy | hh:mm:ss a').format(_currentTime),
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),

                // Permanent Partner Branding
                Text(
                  'Powered by ${config.technologyPartner}',
                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDataGrid(IvfHospitalRepository repo) {
    switch (_activeViewIndex) {
      case 1:
        return _buildIvfCyclesGrid(repo);
      case 2:
        return _buildMaternityGrid(repo);
      case 3:
        return _buildBillingGrid(repo);
      case 0:
      default:
        return _buildPatientsGrid(repo);
    }
  }

  // --- Grid 1: Patients & Couples ---
  Widget _buildPatientsGrid(IvfHospitalRepository repo) {
    final list = repo.patients.where((p) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return p.uhid.toLowerCase().contains(q) ||
          p.femaleName.toLowerCase().contains(q) ||
          (p.malePartnerName?.toLowerCase().contains(q) ?? false) ||
          p.phone.contains(q);
    }).toList();

    return Column(
      children: [
        Container(
          height: 28,
          color: IvfErpTheme.gridHeaderBg,
          child: const Row(
            children: [
              SizedBox(width: 35, child: Text('#', textAlign: TextAlign.center, style: IvfErpTheme.gridHeaderStyle)),
              SizedBox(width: 95, child: Text('UHID', style: IvfErpTheme.gridHeaderStyle)),
              Expanded(flex: 2, child: Text('Female Patient Name', style: IvfErpTheme.gridHeaderStyle)),
              SizedBox(width: 50, child: Text('Age', style: IvfErpTheme.gridHeaderStyle)),
              SizedBox(width: 60, child: Text('Blood', style: IvfErpTheme.gridHeaderStyle)),
              Expanded(flex: 2, child: Text('Male Partner / Husband', style: IvfErpTheme.gridHeaderStyle)),
              SizedBox(width: 100, child: Text('Category', style: IvfErpTheme.gridHeaderStyle)),
              SizedBox(width: 130, child: Text('Infertility Type', style: IvfErpTheme.gridHeaderStyle)),
              Expanded(flex: 2, child: Text('Attending Doctor', style: IvfErpTheme.gridHeaderStyle)),
              SizedBox(width: 90, child: Text('Status', textAlign: TextAlign.center, style: IvfErpTheme.gridHeaderStyle)),
              SizedBox(width: 75, child: Text('Patient 360', textAlign: TextAlign.center, style: IvfErpTheme.gridHeaderStyle)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, idx) {
              final p = list[idx];
              return InkWell(
                onDoubleTap: () => PatientRecord360Dialog.show(context, p, repo),
                child: Container(
                  height: 28,
                  color: idx.isEven ? IvfErpTheme.gridRowEven : IvfErpTheme.gridRowOdd,
                  child: Row(
                    children: [
                      SizedBox(width: 35, child: Text('${idx + 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10))),
                      SizedBox(width: 95, child: Text(p.uhid, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy))),
                      Expanded(flex: 2, child: Text(p.femaleName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
                      SizedBox(width: 50, child: Text('${p.femaleAge}y', style: const TextStyle(fontSize: 10))),
                      SizedBox(width: 60, child: Text(p.femaleBloodGroup, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text(p.malePartnerName ?? '—', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10))),
                      SizedBox(width: 100, child: Text(p.clinicalCategory, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: IvfErpTheme.ivfPurple))),
                      SizedBox(width: 130, child: Text(p.infertilityType, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10))),
                      Expanded(flex: 2, child: Text(p.attendingDoctor, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10))),
                      SizedBox(
                        width: 90,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            color: const Color(0xFFD4EFDF),
                            child: Text(p.status, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: IvfErpTheme.medicalEmerald)),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 75,
                        child: Center(
                          child: InkWell(
                            onTap: () => PatientRecord360Dialog.show(context, p, repo),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: IvfErpTheme.primaryNavy,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: const Text('📋 360 File', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
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
      ],
    );
  }

  // --- Grid 2: IVF Cycles ---
  Widget _buildIvfCyclesGrid(IvfHospitalRepository repo) {
    final list = repo.ivfCycles;

    return Column(
      children: [
        Container(
          height: 28,
          color: IvfErpTheme.gridHeaderBg,
          child: const Row(
            children: [
              SizedBox(width: 35, child: Text('#', textAlign: TextAlign.center, style: IvfErpTheme.gridHeaderStyle)),
              SizedBox(width: 110, child: Text('Cycle ID', style: IvfErpTheme.gridHeaderStyle)),
              Expanded(flex: 2, child: Text('Patient Name', style: IvfErpTheme.gridHeaderStyle)),
              SizedBox(width: 80, child: Text('Type', style: IvfErpTheme.gridHeaderStyle)),
              Expanded(flex: 2, child: Text('Stimulation Protocol', style: IvfErpTheme.gridHeaderStyle)),
              SizedBox(width: 85, child: Text('Oocytes MII', textAlign: TextAlign.center, style: IvfErpTheme.gridHeaderStyle)),
              SizedBox(width: 90, child: Text('Day 5 Blast', textAlign: TextAlign.center, style: IvfErpTheme.gridHeaderStyle)),
              SizedBox(width: 100, child: Text('Beta-hCG (mIU)', textAlign: TextAlign.right, style: IvfErpTheme.gridHeaderStyle)),
              SizedBox(width: 130, child: Text('Clinical Outcome', textAlign: TextAlign.center, style: IvfErpTheme.gridHeaderStyle)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, idx) {
              final c = list[idx];
              final isPositive = c.cycleOutcome.contains('Positive');

              return InkWell(
                onDoubleTap: () => IvfCycleManagementDialog.show(context, repo, existingCycle: c),
                child: Container(
                  height: 28,
                  color: idx.isEven ? IvfErpTheme.gridRowEven : IvfErpTheme.gridRowOdd,
                  child: Row(
                    children: [
                      SizedBox(width: 35, child: Text('${idx + 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10))),
                      SizedBox(width: 110, child: Text(c.cycleId, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy))),
                      Expanded(flex: 2, child: Text(c.patientName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
                      SizedBox(width: 80, child: Text(c.cycleType, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: IvfErpTheme.ivfPurple))),
                      Expanded(flex: 2, child: Text(c.protocol, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10))),
                      SizedBox(width: 85, child: Text('${c.m2Oocytes} MII', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
                      SizedBox(width: 90, child: Text('${c.day5BlastocystCount} Blast', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: IvfErpTheme.babyBlue))),
                      SizedBox(width: 100, child: Text(c.betaHcgValue != null ? '${c.betaHcgValue}' : '—', textAlign: TextAlign.right, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: isPositive ? IvfErpTheme.medicalEmerald : Colors.black87))),
                      SizedBox(
                        width: 130,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            color: isPositive ? const Color(0xFFD4EFDF) : const Color(0xFFF4ECF7),
                            child: Text(
                              c.cycleOutcome,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: isPositive ? IvfErpTheme.medicalEmerald : IvfErpTheme.ivfPurple),
                            ),
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
      ],
    );
  }

  // --- Grid 3: Maternity & Deliveries ---
  Widget _buildMaternityGrid(IvfHospitalRepository repo) {
    final list = repo.maternityCases;
    final df = DateFormat('dd-MMM-yyyy');

    return Column(
      children: [
        Container(
          height: 28,
          color: IvfErpTheme.gridHeaderBg,
          child: const Row(
            children: [
              SizedBox(width: 35, child: Text('#', textAlign: TextAlign.center, style: IvfErpTheme.gridHeaderStyle)),
              SizedBox(width: 110, child: Text('Case ID', style: IvfErpTheme.gridHeaderStyle)),
              Expanded(flex: 2, child: Text('Patient Name', style: IvfErpTheme.gridHeaderStyle)),
              SizedBox(width: 95, child: Text('EDD Date', style: IvfErpTheme.gridHeaderStyle)),
              Expanded(flex: 2, child: Text('High Risk Factors', style: IvfErpTheme.gridHeaderStyle)),
              SizedBox(width: 110, child: Text('Delivery Mode', style: IvfErpTheme.gridHeaderStyle)),
              SizedBox(width: 80, child: Text('Baby Gender', style: IvfErpTheme.gridHeaderStyle)),
              SizedBox(width: 90, child: Text('Birth Wt (kg)', textAlign: TextAlign.center, style: IvfErpTheme.gridHeaderStyle)),
              SizedBox(width: 110, child: Text('Status', textAlign: TextAlign.center, style: IvfErpTheme.gridHeaderStyle)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, idx) {
              final m = list[idx];
              return Container(
                height: 28,
                color: idx.isEven ? IvfErpTheme.gridRowEven : IvfErpTheme.gridRowOdd,
                child: Row(
                  children: [
                    SizedBox(width: 35, child: Text('${idx + 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10))),
                    SizedBox(width: 110, child: Text(m.caseId, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy))),
                    Expanded(flex: 2, child: Text(m.patientName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
                    SizedBox(width: 95, child: Text(df.format(m.edd), style: const TextStyle(fontSize: 10))),
                    Expanded(flex: 2, child: Text(m.highRiskCondition, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: IvfErpTheme.alertRuby, fontWeight: FontWeight.w600))),
                    SizedBox(width: 110, child: Text(m.deliveryType, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                    SizedBox(width: 80, child: Text(m.babyGender ?? '—', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: IvfErpTheme.pinkMaternity))),
                    SizedBox(width: 90, child: Text(m.birthWeightKg != null ? '${m.birthWeightKg} kg' : '—', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
                    SizedBox(
                      width: 110,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          color: const Color(0xFFD4EFDF),
                          child: Text(m.caseStatus, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: IvfErpTheme.medicalEmerald)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Grid 4: Invoices ---
  Widget _buildBillingGrid(IvfHospitalRepository repo) {
    final list = repo.invoices;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return Column(
      children: [
        Container(
          height: 28,
          color: IvfErpTheme.gridHeaderBg,
          child: const Row(
            children: [
              SizedBox(width: 35, child: Text('#', textAlign: TextAlign.center, style: IvfErpTheme.gridHeaderStyle)),
              SizedBox(width: 120, child: Text('Invoice No', style: IvfErpTheme.gridHeaderStyle)),
              Expanded(flex: 2, child: Text('Patient Name', style: IvfErpTheme.gridHeaderStyle)),
              Expanded(flex: 3, child: Text('Service Description', style: IvfErpTheme.gridHeaderStyle)),
              SizedBox(width: 110, child: Text('Total (₹)', textAlign: TextAlign.right, style: IvfErpTheme.gridHeaderStyle)),
              SizedBox(width: 110, child: Text('Paid (₹)', textAlign: TextAlign.right, style: IvfErpTheme.gridHeaderStyle)),
              SizedBox(width: 85, child: Text('Status', textAlign: TextAlign.center, style: IvfErpTheme.gridHeaderStyle)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, idx) {
              final inv = list[idx];
              return Container(
                height: 28,
                color: idx.isEven ? IvfErpTheme.gridRowEven : IvfErpTheme.gridRowOdd,
                child: Row(
                  children: [
                    SizedBox(width: 35, child: Text('${idx + 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10))),
                    SizedBox(width: 120, child: Text(inv.invoiceNumber, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy))),
                    Expanded(flex: 2, child: Text(inv.patientName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
                    Expanded(flex: 3, child: Text(inv.serviceDescription, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10))),
                    SizedBox(width: 110, child: Text(currency.format(inv.totalAmount), textAlign: TextAlign.right, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
                    SizedBox(width: 110, child: Text(currency.format(inv.paidAmount), textAlign: TextAlign.right, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: IvfErpTheme.medicalEmerald))),
                    SizedBox(
                      width: 85,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          color: inv.status == 'PAID' ? const Color(0xFFD4EFDF) : const Color(0xFFFADBD8),
                          child: Text(inv.status, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: inv.status == 'PAID' ? IvfErpTheme.medicalEmerald : IvfErpTheme.alertRuby)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Helper Widgets ---

  Widget _viewTab(int index, String label, IconData icon) {
    final isSelected = _activeViewIndex == index;
    return InkWell(
      onTap: () => setState(() => _activeViewIndex = index),
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          border: isSelected ? Border.all(color: IvfErpTheme.borderDark) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: isSelected ? IvfErpTheme.primaryNavy : IvfErpTheme.textMuted),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? IvfErpTheme.primaryNavy : IvfErpTheme.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isPrimary ? IvfErpTheme.primaryNavy : Colors.white,
          border: Border.all(
            color: isPrimary ? const Color(0xFF07273C) : IvfErpTheme.borderDark,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isPrimary ? Colors.white : IvfErpTheme.primaryNavy),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: isPrimary ? Colors.white : IvfErpTheme.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(String title, List<PopupMenuEntry> entries) {
    return PopupMenuButton(
      itemBuilder: (ctx) => entries,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(title, style: IvfErpTheme.menuStyle),
      ),
    );
  }

  PopupMenuItem _subMenuItem(String label, IconData icon, VoidCallback onTap) {
    return PopupMenuItem(
      onTap: onTap,
      height: 30,
      child: Row(
        children: [
          Icon(icon, size: 14, color: IvfErpTheme.primaryNavy),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  void _showAboutModal(BuildContext context, dynamic config) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Row(
          children: [
            Icon(Icons.local_hospital_rounded, color: IvfErpTheme.primaryNavy, size: 20),
            SizedBox(width: 8),
            Text('About IVFPro 360™ Enterprise', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'IVFPro 360 Enterprise Hospital Management System',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy),
            ),
            const SizedBox(height: 4),
            const Text('Specialized for Gynecology, Infertility, IVF/ART, Embryology & Maternity Care.', style: TextStyle(fontSize: 11)),
            const Divider(height: 16),
            const Text('Commercial Enterprise Edition • Version 1.0.0 (Win32)', style: TextStyle(fontSize: 10.5)),
            const SizedBox(height: 6),
            const Row(
              children: [
                Text('Developed & Technology Partner: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                Text('iSecure System Pvt. Ltd.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy)),
              ],
            ),
            const SizedBox(height: 6),
            const Text('Compliant with National Assisted Reproductive Technology (ART) Act 2021 & Surrogacy Act.', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }
}
