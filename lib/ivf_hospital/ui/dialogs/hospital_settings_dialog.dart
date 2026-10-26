import 'package:flutter/material.dart';
import '../../config/ivf_erp_theme.dart';
import '../../data/models/hospital_config_model.dart';
import '../../data/repositories/ivf_hospital_repository.dart';
import '../../data/services/supabase_service.dart';
import '../widgets/hospital_logo_widget.dart';
import '../widgets/win32_window_frame.dart';

/// Whitelabel Hospital Settings, Multi-Branch & Logo Configuration Dialog
class HospitalSettingsDialog extends StatefulWidget {
  final IvfHospitalRepository repo;

  const HospitalSettingsDialog({super.key, required this.repo});

  static Future<void> show(BuildContext context, IvfHospitalRepository repo) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => HospitalSettingsDialog(repo: repo),
    );
  }

  @override
  State<HospitalSettingsDialog> createState() => _HospitalSettingsDialogState();
}

class _HospitalSettingsDialogState extends State<HospitalSettingsDialog> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  late TextEditingController _nameCtrl;
  late TextEditingController _taglineCtrl;
  late TextEditingController _logoCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _pinCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emergencyCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _webCtrl;
  late TextEditingController _gstinCtrl;
  late TextEditingController _panCtrl;
  late TextEditingController _artRegCtrl;
  late TextEditingController _clinicalRegCtrl;
  late TextEditingController _currencyCtrl;
  late TextEditingController _invPrefixCtrl;
  late TextEditingController _uhidPrefixCtrl;
  late TextEditingController _cyclePrefixCtrl;

  late TextEditingController _supabaseUrlCtrl;
  late TextEditingController _supabaseKeyCtrl;
  late bool _cloudSyncEnabled;

  late String _activeBranchId;
  late List<HospitalBranchModel> _branches;

  bool _isTestingConnection = false;
  String? _connectionTestResult;
  bool _connectionSuccess = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
    final c = widget.repo.config;

    _nameCtrl = TextEditingController(text: c.hospitalName);
    _taglineCtrl = TextEditingController(text: c.tagline);
    _logoCtrl = TextEditingController(text: c.logoPathOrUrl);
    _addressCtrl = TextEditingController(text: c.address);
    _cityCtrl = TextEditingController(text: c.city);
    _stateCtrl = TextEditingController(text: c.state);
    _pinCtrl = TextEditingController(text: c.pincode);
    _phoneCtrl = TextEditingController(text: c.phone);
    _emergencyCtrl = TextEditingController(text: c.emergencyHelpline);
    _emailCtrl = TextEditingController(text: c.email);
    _webCtrl = TextEditingController(text: c.website);
    _gstinCtrl = TextEditingController(text: c.gstin);
    _panCtrl = TextEditingController(text: c.pan);
    _artRegCtrl = TextEditingController(text: c.artClinicRegNumber);
    _clinicalRegCtrl = TextEditingController(text: c.clinicalEstRegNumber);
    _currencyCtrl = TextEditingController(text: c.currencySymbol);
    _invPrefixCtrl = TextEditingController(text: c.invoicePrefix);
    _uhidPrefixCtrl = TextEditingController(text: c.patientIdPrefix);
    _cyclePrefixCtrl = TextEditingController(text: c.ivfCyclePrefix);

    _supabaseUrlCtrl = TextEditingController(text: c.supabaseUrl);
    _supabaseKeyCtrl = TextEditingController(text: c.supabaseAnonKey);
    _cloudSyncEnabled = c.isCloudSyncEnabled;

    _activeBranchId = c.activeBranchId;
    _branches = List.from(c.branches);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _taglineCtrl.dispose();
    _logoCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pinCtrl.dispose();
    _phoneCtrl.dispose();
    _emergencyCtrl.dispose();
    _emailCtrl.dispose();
    _webCtrl.dispose();
    _gstinCtrl.dispose();
    _panCtrl.dispose();
    _artRegCtrl.dispose();
    _clinicalRegCtrl.dispose();
    _currencyCtrl.dispose();
    _invPrefixCtrl.dispose();
    _uhidPrefixCtrl.dispose();
    _cyclePrefixCtrl.dispose();
    _supabaseUrlCtrl.dispose();
    _supabaseKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _testSupabase() async {
    setState(() {
      _isTestingConnection = true;
      _connectionTestResult = null;
    });

    final success = await SupabaseService.instance.testConnection(
      _supabaseUrlCtrl.text.trim(),
      _supabaseKeyCtrl.text.trim(),
    );

    setState(() {
      _isTestingConnection = false;
      _connectionSuccess = success;
      _connectionTestResult = success
          ? 'Cloud connection verified! Supabase is responsive.'
          : 'Failed to reach Supabase. Check URL and anon key.';
    });
  }

  void _saveSettings() {
    final updated = HospitalConfigModel(
      hospitalName: _nameCtrl.text.trim(),
      tagline: _taglineCtrl.text.trim(),
      technologyPartner: widget.repo.config.technologyPartner,
      logoPathOrUrl: _logoCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      state: _stateCtrl.text.trim(),
      stateCode: widget.repo.config.stateCode,
      pincode: _pinCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      emergencyHelpline: _emergencyCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      website: _webCtrl.text.trim(),
      gstin: _gstinCtrl.text.trim(),
      pan: _panCtrl.text.trim(),
      artClinicRegNumber: _artRegCtrl.text.trim(),
      clinicalEstRegNumber: _clinicalRegCtrl.text.trim(),
      currencySymbol: _currencyCtrl.text.trim(),
      invoicePrefix: _invPrefixCtrl.text.trim(),
      patientIdPrefix: _uhidPrefixCtrl.text.trim(),
      ivfCyclePrefix: _cyclePrefixCtrl.text.trim(),
      supabaseUrl: _supabaseUrlCtrl.text.trim(),
      supabaseAnonKey: _supabaseKeyCtrl.text.trim(),
      isCloudSyncEnabled: _cloudSyncEnabled,
      licenseKey: widget.repo.config.licenseKey,
      licenseStatus: widget.repo.config.licenseStatus,
      activeBranchId: _activeBranchId,
      branches: _branches,
    );

    widget.repo.updateHospitalConfig(updated);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hospital settings, branding logo, and multi-branch configuration saved!'),
        backgroundColor: IvfErpTheme.medicalEmerald,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Win32WindowFrame(
      title: 'HOSPITAL WHITELABEL, LOGO & MULTI-BRANCH CONFIGURATION',
      subtitle: 'Commercial Whitelabeling System • iSecure System Pvt. Ltd.',
      icon: Icons.settings_applications_rounded,
      defaultWidth: 980,
      defaultHeight: 640,
      child: Column(
        children: [
          // Sub-Tab Navigation Bar
          Container(
            color: const Color(0xFFD5D8DC),
            child: TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              labelColor: IvfErpTheme.primaryNavy,
              unselectedLabelColor: Colors.black54,
              indicatorColor: IvfErpTheme.primaryNavy,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(icon: Icon(Icons.business_rounded, size: 14), text: 'Identity & Brand Logo'),
                Tab(icon: Icon(Icons.account_tree_rounded, size: 14), text: 'Hospital Branches'),
                Tab(icon: Icon(Icons.gavel_rounded, size: 14), text: 'Legal & ART Act 2021'),
                Tab(icon: Icon(Icons.tag_rounded, size: 14), text: 'Numbering & Prefixes'),
                Tab(icon: Icon(Icons.cloud_sync_rounded, size: 14), text: 'Supabase Cloud Sync'),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildIdentityAndLogoTab(),
                _buildBranchesTab(),
                _buildLegalTab(),
                _buildPrefixesTab(),
                _buildSupabaseTab(),
              ],
            ),
          ),

          // Bottom Action Bar
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            color: IvfErpTheme.menuBarBg,
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, size: 13, color: IvfErpTheme.medicalEmerald),
                const SizedBox(width: 5),
                const Text(
                  'Changes apply to all generated bills, receipts, reports, prescriptions, and branches.',
                  style: TextStyle(fontSize: 10, color: Colors.black87),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save_rounded, size: 14),
                  label: const Text('Save & Apply Settings', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: IvfErpTheme.primaryNavy,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    side: const BorderSide(color: IvfErpTheme.borderDark),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Tab 1: Identity & Logo ---
  Widget _buildIdentityAndLogoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Configuration Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: IvfErpTheme.borderDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.image_rounded, size: 14, color: IvfErpTheme.primaryNavy),
                    SizedBox(width: 6),
                    Text('Hospital Brand Logo (Used in All Bills, Reports & Previews)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy)),
                  ],
                ),
                const Divider(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Live Preview of Current Logo
                    Column(
                      children: [
                        const Text('Live Logo Preview', style: TextStyle(fontSize: 9.5, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F4F4),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: HospitalLogoWidget(logoPathOrUrl: _logoCtrl.text.trim(), size: 54),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    // Logo Path / Presets
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _field('Logo URL or Local File Path', _logoCtrl, hint: 'e.g., https://.../logo.png or preset:fertility_lotus'),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: ElevatedButton(
                                  onPressed: () => setState(() {}),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: IvfErpTheme.primaryNavy,
                                    foregroundColor: Colors.white,
                                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                  ),
                                  child: const Text('Refresh Preview', style: TextStyle(fontSize: 10)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text('Or Select a Built-in Medical Brand Emblem:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            children: [
                              _presetEmblemButton('Fertility Lotus', 'preset:fertility_lotus'),
                              _presetEmblemButton('Caduceus Gold', 'preset:caduceus'),
                              _presetEmblemButton('Heart Cross Green', 'preset:heart_cross'),
                              _presetEmblemButton('DNA Embryo Purple', 'preset:dna_embryo'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // General Details
          Row(
            children: [
              Expanded(child: _field('Hospital / Center Name', _nameCtrl)),
              const SizedBox(width: 8),
              Expanded(child: _field('Tagline / Subtitle', _taglineCtrl)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(flex: 2, child: _field('Physical Address', _addressCtrl)),
              const SizedBox(width: 8),
              Expanded(child: _field('City', _cityCtrl)),
              const SizedBox(width: 8),
              Expanded(child: _field('State', _stateCtrl)),
              const SizedBox(width: 8),
              Expanded(child: _field('Pincode', _pinCtrl)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _field('Official Phone', _phoneCtrl)),
              const SizedBox(width: 8),
              Expanded(child: _field('24x7 Emergency Helpline', _emergencyCtrl)),
              const SizedBox(width: 8),
              Expanded(child: _field('Email Address', _emailCtrl)),
              const SizedBox(width: 8),
              Expanded(child: _field('Website Portal', _webCtrl)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetEmblemButton(String label, String value) {
    final isSelected = _logoCtrl.text.trim() == value;
    return OutlinedButton.icon(
      onPressed: () {
        setState(() {
          _logoCtrl.text = value;
        });
      },
      icon: HospitalLogoWidget(logoPathOrUrl: value, size: 16),
      label: Text(label, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      style: OutlinedButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        side: BorderSide(color: isSelected ? IvfErpTheme.primaryNavy : Colors.grey.shade400, width: isSelected ? 1.5 : 1),
        backgroundColor: isSelected ? const Color(0xFFD6EAF8) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  // --- Tab 2: Multi-Branch Management ---
  Widget _buildBranchesTab() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_tree_rounded, size: 16, color: IvfErpTheme.primaryNavy),
              const SizedBox(width: 6),
              const Text('Hospital Branches & Centers Directory', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showAddBranchDialog,
                icon: const Icon(Icons.add, size: 14),
                label: const Text('+ Add New Branch', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: IvfErpTheme.primaryNavy,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: IvfErpTheme.borderDark)),
              child: Column(
                children: [
                  Container(
                    height: 28,
                    color: IvfErpTheme.gridHeaderBg,
                    child: const Row(
                      children: [
                        SizedBox(width: 80, child: Text('Branch ID', textAlign: TextAlign.center, style: IvfErpTheme.gridHeaderStyle)),
                        Expanded(flex: 3, child: Text('Branch Name', style: IvfErpTheme.gridHeaderStyle)),
                        Expanded(flex: 3, child: Text('Location & Address', style: IvfErpTheme.gridHeaderStyle)),
                        Expanded(flex: 2, child: Text('In-Charge Doctor', style: IvfErpTheme.gridHeaderStyle)),
                        SizedBox(width: 130, child: Text('ART Reg No', style: IvfErpTheme.gridHeaderStyle)),
                        SizedBox(width: 100, child: Text('Status', textAlign: TextAlign.center, style: IvfErpTheme.gridHeaderStyle)),
                        SizedBox(width: 90, child: Text('Action', textAlign: TextAlign.center, style: IvfErpTheme.gridHeaderStyle)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _branches.length,
                      itemBuilder: (context, idx) {
                        final b = _branches[idx];
                        final isActive = b.branchId == _activeBranchId;

                        return Container(
                          height: 36,
                          color: isActive ? const Color(0xFFD4EFDF) : (idx.isEven ? IvfErpTheme.gridRowEven : IvfErpTheme.gridRowOdd),
                          child: Row(
                            children: [
                              SizedBox(width: 80, child: Text(b.branchId, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy))),
                              Expanded(flex: 3, child: Text(b.branchName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
                              Expanded(flex: 3, child: Text('${b.address}, ${b.city}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10))),
                              Expanded(flex: 2, child: Text(b.inChargeDoctor, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10))),
                              SizedBox(width: 130, child: Text(b.artClinicRegNumber, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, color: IvfErpTheme.medicalEmerald, fontWeight: FontWeight.w600))),
                              SizedBox(
                                width: 100,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    color: isActive ? IvfErpTheme.medicalEmerald : Colors.grey.shade300,
                                    child: Text(
                                      isActive ? 'ACTIVE BRANCH' : (b.isMainBranch ? 'MAIN' : 'SATELLITE'),
                                      style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: isActive ? Colors.white : Colors.black87),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 90,
                                child: Center(
                                  child: isActive
                                      ? const Icon(Icons.check_circle, size: 16, color: IvfErpTheme.medicalEmerald)
                                      : InkWell(
                                          onTap: () {
                                            setState(() => _activeBranchId = b.branchId);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: IvfErpTheme.primaryNavy, borderRadius: BorderRadius.circular(2)),
                                            child: const Text('Set Active', style: TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.bold)),
                                          ),
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBranchDialog() {
    final idCtrl = TextEditingController(text: 'BR-0${_branches.length + 1}');
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final docCtrl = TextEditingController();
    final artCtrl = TextEditingController(text: '${_artRegCtrl.text.trim()}-B${_branches.length + 1}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text('Add Hospital Branch / Center', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field('Branch Code', idCtrl),
              const SizedBox(height: 6),
              _field('Branch Name', nameCtrl, hint: 'e.g. West City Satellite IVF Clinic'),
              const SizedBox(height: 6),
              _field('Address & City', addressCtrl),
              const SizedBox(height: 6),
              _field('In-Charge Doctor', docCtrl, hint: 'Dr. ...'),
              const SizedBox(height: 6),
              _field('Branch ART Reg No', artCtrl),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _branches.add(HospitalBranchModel(
                    branchId: idCtrl.text.trim(),
                    branchName: nameCtrl.text.trim(),
                    address: addressCtrl.text.trim(),
                    city: _cityCtrl.text.trim(),
                    phone: _phoneCtrl.text.trim(),
                    inChargeDoctor: docCtrl.text.trim(),
                    artClinicRegNumber: artCtrl.text.trim(),
                    isMainBranch: false,
                  ));
                });
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: IvfErpTheme.primaryNavy,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: const Text('Add Branch'),
          ),
        ],
      ),
    );
  }

  // --- Tab 3: Legal & Regulatory ---
  Widget _buildLegalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _field('National ART Clinic Registration No (ART Act 2021)', _artRegCtrl)),
              const SizedBox(width: 8),
              Expanded(child: _field('Clinical Establishment Act (CEA) Number', _clinicalRegCtrl)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _field('GSTIN (Tax Registration Number)', _gstinCtrl)),
              const SizedBox(width: 8),
              Expanded(child: _field('Permanent Account Number (PAN)', _panCtrl)),
            ],
          ),
        ],
      ),
    );
  }

  // --- Tab 4: Numbering Prefixes ---
  Widget _buildPrefixesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _field('Currency Symbol', _currencyCtrl)),
              const SizedBox(width: 8),
              Expanded(child: _field('Invoice Prefix', _invPrefixCtrl)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _field('Patient UHID Prefix', _uhidPrefixCtrl)),
              const SizedBox(width: 8),
              Expanded(child: _field('IVF Cycle Prefix', _cyclePrefixCtrl)),
            ],
          ),
        ],
      ),
    );
  }

  // --- Tab 5: Supabase Cloud Sync ---
  Widget _buildSupabaseTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: _cloudSyncEnabled,
                onChanged: (val) => setState(() => _cloudSyncEnabled = val ?? false),
              ),
              const Text('Enable Real-Time Cloud Sync with Supabase (PostgreSQL)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          _field('Supabase Project URL', _supabaseUrlCtrl, hint: 'https://xyz.supabase.co'),
          const SizedBox(height: 8),
          _field('Supabase Anon / Public Key', _supabaseKeyCtrl, hint: 'eyJh...'),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _isTestingConnection ? null : _testSupabase,
                icon: _isTestingConnection
                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.network_check_rounded, size: 14),
                label: Text(_isTestingConnection ? 'Testing...' : 'Test Connection (Ping)', style: const TextStyle(fontSize: 10.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: IvfErpTheme.primaryNavy,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
              ),
              const SizedBox(width: 12),
              if (_connectionTestResult != null)
                Expanded(
                  child: Text(
                    _connectionTestResult!,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: _connectionSuccess ? IvfErpTheme.medicalEmerald : IvfErpTheme.alertRuby,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Container(
          height: 26,
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: IvfErpTheme.borderDark)),
          child: TextField(
            controller: ctrl,
            style: const TextStyle(fontSize: 11),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 10, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            ),
          ),
        ),
      ],
    );
  }
}
