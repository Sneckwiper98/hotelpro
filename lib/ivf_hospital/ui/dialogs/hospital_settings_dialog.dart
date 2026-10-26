import 'package:flutter/material.dart';
import '../../config/ivf_erp_theme.dart';
import '../../data/models/hospital_config_model.dart';
import '../../data/repositories/ivf_hospital_repository.dart';
import '../../data/services/supabase_service.dart';

/// Whitelabel Hospital Settings & Supabase Cloud Configuration Dialog
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

  bool _isTestingConnection = false;
  String? _connectionTestResult;
  bool _connectionSuccess = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    final c = widget.repo.config;

    _nameCtrl = TextEditingController(text: c.hospitalName);
    _taglineCtrl = TextEditingController(text: c.tagline);
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
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _taglineCtrl.dispose();
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
          ? 'SUCCESS: Connected securely to Supabase Cloud PostgreSQL database!'
          : 'FAILED: Unable to connect to Supabase. Check URL, Anon Key or internet connection.';
    });
  }

  void _saveSettings() {
    final updated = HospitalConfigModel(
      hospitalName: _nameCtrl.text.trim(),
      tagline: _taglineCtrl.text.trim(),
      technologyPartner: 'iSecure System Pvt. Ltd.',
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
      licenseStatus: 'ACTIVE',
    );

    widget.repo.updateHospitalConfig(updated);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hospital Configuration & Whitelabel Settings successfully updated!'),
        backgroundColor: IvfErpTheme.medicalEmerald,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final dialogWidth = (screen.width * 0.92).clamp(750.0, 950.0);
    final dialogHeight = (screen.height * 0.90).clamp(520.0, 680.0);

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        decoration: BoxDecoration(
          color: IvfErpTheme.dialogBg,
          border: Border.all(color: IvfErpTheme.borderDark, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Win32 Title Bar
            Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [IvfErpTheme.headerGradientStart, IvfErpTheme.headerGradientEnd],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.settings_applications_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Hospital Whitelabel & Cloud Database Settings — IVFPro Enterprise',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 18,
                      height: 18,
                      color: IvfErpTheme.alertRuby,
                      alignment: Alignment.center,
                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // Tabs Header
            Container(
              color: IvfErpTheme.menuBarBg,
              child: TabBar(
                controller: _tabCtrl,
                isScrollable: true,
                indicatorColor: IvfErpTheme.primaryNavy,
                indicatorWeight: 3,
                labelColor: IvfErpTheme.primaryNavy,
                unselectedLabelColor: IvfErpTheme.textMuted,
                labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(icon: Icon(Icons.business_rounded, size: 15), text: 'Hospital Identity & Legal Reg'),
                  Tab(icon: Icon(Icons.cloud_sync_rounded, size: 15), text: 'Supabase Cloud Backend'),
                  Tab(icon: Icon(Icons.format_list_numbered_rounded, size: 15), text: 'Prefixes, Billing & License'),
                ],
              ),
            ),

            // Tab Views Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    // Tab 1: Hospital Identity & Legal
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Hospital Whitelabel Profile'),
                          const SizedBox(height: 8),
                          _buildTextField('Hospital Name (Trading Name) *', _nameCtrl, hint: 'e.g. Shri Radhakrishna Hospital & Infertility Centre'),
                          const SizedBox(height: 8),
                          _buildTextField('Tagline / Medical Specialization', _taglineCtrl, hint: 'e.g. Gynecology • Infertility • IVF • Maternity'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(flex: 2, child: _buildTextField('Hospital Address *', _addressCtrl)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildTextField('City *', _cityCtrl)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildTextField('State *', _stateCtrl)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildTextField('Pincode', _pinCtrl)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _buildTextField('Primary Phone *', _phoneCtrl)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildTextField('24x7 Emergency Helpline', _emergencyCtrl)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildTextField('Official Email', _emailCtrl)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildTextField('Website', _webCtrl)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildSectionHeader('Legal & ART Act 2021 Regulatory Registration'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  'National ART Clinic Reg Number (Under ART Act 2021) *',
                                  _artRegCtrl,
                                  hint: 'e.g. ART/MH/NAG/2024/0089',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTextField(
                                  'Clinical Establishment Act Reg No *',
                                  _clinicalRegCtrl,
                                  hint: 'e.g. CEA/MH/2022/4119',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _buildTextField('GSTIN (Tax Identification) *', _gstinCtrl)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildTextField('Permanent Account Number (PAN)', _panCtrl)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Tab 2: Supabase Cloud Backend
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Supabase Cloud Database Settings'),
                          const SizedBox(height: 6),
                          const Text(
                            'Enter the hospital Supabase Project URL & Public Anon Key to enable multi-workstation real-time synchronization, mobile app API connectivity, and automated cloud backups.',
                            style: TextStyle(fontSize: 11, color: IvfErpTheme.textMuted),
                          ),
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Enable Supabase Cloud Synchronization & Realtime DB', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            subtitle: const Text('When disabled, software functions in standalone high-speed local mode.', style: TextStyle(fontSize: 10.5)),
                            value: _cloudSyncEnabled,
                            onChanged: (val) => setState(() => _cloudSyncEnabled = val ?? false),
                          ),
                          const SizedBox(height: 8),
                          _buildTextField(
                            'Supabase Project URL (e.g. https://xyz.supabase.co) *',
                            _supabaseUrlCtrl,
                            hint: 'https://your-hospital-id.supabase.co',
                          ),
                          const SizedBox(height: 10),
                          _buildTextField(
                            'Supabase Public Anon / API Key *',
                            _supabaseKeyCtrl,
                            hint: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                icon: _isTestingConnection
                                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.bolt_rounded, size: 15),
                                label: const Text('Test Supabase Connection'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: IvfErpTheme.primaryNavy,
                                  foregroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                ),
                                onPressed: _isTestingConnection ? null : _testSupabase,
                              ),
                            ],
                          ),
                          if (_connectionTestResult != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _connectionSuccess ? const Color(0xFFD4EFDF) : const Color(0xFFFADBD8),
                                border: Border.all(
                                  color: _connectionSuccess ? IvfErpTheme.medicalEmerald : IvfErpTheme.alertRuby,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _connectionSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                                    color: _connectionSuccess ? IvfErpTheme.medicalEmerald : IvfErpTheme.alertRuby,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _connectionTestResult!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _connectionSuccess ? const Color(0xFF196F3D) : const Color(0xFF922B21),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Tab 3: Prefixes, Billing & License
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Automated Sequence Numbering Prefixes'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _buildTextField('Patient UHID Prefix', _uhidPrefixCtrl, hint: 'e.g. SRH-P-')),
                              const SizedBox(width: 8),
                              Expanded(child: _buildTextField('IVF Cycle ID Prefix', _cyclePrefixCtrl, hint: 'e.g. IVF-2026-')),
                              const SizedBox(width: 8),
                              Expanded(child: _buildTextField('Invoice Number Prefix', _invPrefixCtrl, hint: 'e.g. SRH-INV-')),
                              const SizedBox(width: 8),
                              Expanded(child: _buildTextField('Currency Symbol', _currencyCtrl, hint: '₹')),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildSectionHeader('Commercial Software Licensing & Technology Partner'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: IvfErpTheme.borderDark),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.verified_user_rounded, color: IvfErpTheme.medicalEmerald, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'License Status: ${widget.repo.config.licenseStatus}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: IvfErpTheme.medicalEmerald),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Software License Key: ${widget.repo.config.licenseKey}',
                                  style: const TextStyle(fontSize: 10.5, fontFamily: 'monospace', color: IvfErpTheme.textMuted),
                                ),
                                const Divider(height: 14),
                                const Row(
                                  children: [
                                    Text('Developed & Technology Partner: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    Text('iSecure System Pvt. Ltd.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Commercial Enterprise Multi-Hospital Edition • 100% Whitelabel Ready for Resale to any IVF Hospital.',
                                  style: TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Buttons Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: IvfErpTheme.menuBarBg,
                border: Border(top: BorderSide(color: IvfErpTheme.borderDark, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save_rounded, size: 14),
                    label: const Text('Save Configuration'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: IvfErpTheme.medicalEmerald,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: _saveSettings,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: IvfErpTheme.gridHeaderBg,
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {String? hint, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: IvfErpTheme.textMain)),
        const SizedBox(height: 3),
        Container(
          height: maxLines == 1 ? 28 : null,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: IvfErpTheme.borderDark, width: 1),
          ),
          child: TextField(
            controller: ctrl,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 11, color: IvfErpTheme.textMain),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 10.5, color: Colors.grey),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            ),
          ),
        ),
      ],
    );
  }
}
