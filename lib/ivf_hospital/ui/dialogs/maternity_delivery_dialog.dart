import 'package:flutter/material.dart';
import '../../config/ivf_erp_theme.dart';
import '../../data/models/maternity_case_model.dart';
import '../../data/models/ivf_patient_model.dart';
import '../../data/repositories/ivf_hospital_repository.dart';

/// Maternity, Labour, Delivery & Newborn Management Dialog
class MaternityDeliveryDialog extends StatefulWidget {
  final IvfHospitalRepository repo;

  const MaternityDeliveryDialog({super.key, required this.repo});

  static Future<void> show(BuildContext context, IvfHospitalRepository repo) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MaternityDeliveryDialog(repo: repo),
    );
  }

  @override
  State<MaternityDeliveryDialog> createState() => _MaternityDeliveryDialogState();
}

class _MaternityDeliveryDialogState extends State<MaternityDeliveryDialog> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  IvfPatientModel? _selectedPatient;

  final _gravidaCtrl = TextEditingController(text: '2');
  final _paraCtrl = TextEditingController(text: '1');
  String _highRisk = 'Previous LSCS + IVF Conception';
  String _wardBed = 'Maternity Deluxe Room - Bed 201';

  final _cervicalCtrl = TextEditingController(text: '10.0');
  final _fhrCtrl = TextEditingController(text: '142');
  String _deliveryType = 'Elective LSCS';
  final String _doctor = 'Dr. Sunita Deshmukh (MD, DGO, Obstetrician)';
  final String _pediatrician = 'Dr. Anand Verma (MD, Pediatrics / Neonatologist)';

  String _babyGender = 'Female';
  final _birthWeightCtrl = TextEditingController(text: '3.15');
  final _apgar1Ctrl = TextEditingController(text: '8');
  final _apgar5Ctrl = TextEditingController(text: '9');
  bool _bcg = true;
  bool _opv0 = true;
  bool _hepb = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    if (widget.repo.patients.isNotEmpty) {
      _selectedPatient = widget.repo.patients.firstWhere(
        (p) => p.clinicalCategory == 'MATERNITY',
        orElse: () => widget.repo.patients.first,
      );
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _gravidaCtrl.dispose();
    _paraCtrl.dispose();
    _cervicalCtrl.dispose();
    _fhrCtrl.dispose();
    _birthWeightCtrl.dispose();
    _apgar1Ctrl.dispose();
    _apgar5Ctrl.dispose();
    super.dispose();
  }

  void _saveMaternityCase() {
    if (_selectedPatient == null) return;

    final caseId = 'MAT-2026-${(widget.repo.maternityCases.length + 81).toString().padLeft(3, '0')}';
    final lmp = DateTime.now().subtract(const Duration(days: 275));
    final edd = DateTime.now().add(const Duration(days: 5));

    final mCase = MaternityCaseModel(
      caseId: caseId,
      patientUhid: _selectedPatient!.uhid,
      patientName: _selectedPatient!.femaleName,
      lmp: lmp,
      edd: edd,
      gravida: int.tryParse(_gravidaCtrl.text) ?? 1,
      para: int.tryParse(_paraCtrl.text) ?? 0,
      isIvfConception: true,
      highRiskCondition: _highRisk,
      wardBed: _wardBed,
      admissionDate: DateTime.now().subtract(const Duration(days: 2)),
      cervicalDilationCm: double.tryParse(_cervicalCtrl.text),
      fetalHeartRateBpm: int.tryParse(_fhrCtrl.text),
      deliveryDate: DateTime.now().subtract(const Duration(hours: 18)),
      deliveryType: _deliveryType,
      attendingObstetrician: _doctor,
      attendingPediatrician: _pediatrician,
      babyGender: _babyGender,
      birthWeightKg: double.tryParse(_birthWeightCtrl.text),
      apgar1Min: int.tryParse(_apgar1Ctrl.text),
      apgar5Min: int.tryParse(_apgar5Ctrl.text),
      vaccineBcgGiven: _bcg,
      vaccineOpv0Given: _opv0,
      vaccineHepBGiven: _hepb,
      caseStatus: 'Delivered & Postnatal',
    );

    widget.repo.addMaternityCase(mCase);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Maternity & Delivery Case $caseId registered successfully!'),
        backgroundColor: IvfErpTheme.medicalEmerald,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final dialogWidth = (screen.width * 0.90).clamp(760.0, 920.0);
    final dialogHeight = (screen.height * 0.88).clamp(520.0, 660.0);

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
          children: [
            // Title Bar
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              color: IvfErpTheme.pinkMaternity,
              child: Row(
                children: [
                  const Icon(Icons.pregnant_woman_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Maternity, Labour Room & Newborn Care — IVFPro Win32 ERP',
                    style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 15, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Patient Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: const Color(0xFFFCE4EC),
              child: Row(
                children: [
                  const Text('Maternity Patient: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 26,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: IvfErpTheme.borderDark),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<IvfPatientModel>(
                          value: _selectedPatient,
                          isDense: true,
                          isExpanded: true,
                          style: const TextStyle(fontSize: 11, color: IvfErpTheme.textMain, fontWeight: FontWeight.bold),
                          items: widget.repo.patients.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Text('${p.uhid} — ${p.femaleName} (Age: ${p.femaleAge}, ${p.femaleBloodGroup})'),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedPatient = v),
                        ),
                      ),
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
                indicatorColor: IvfErpTheme.pinkMaternity,
                indicatorWeight: 3,
                labelColor: IvfErpTheme.pinkMaternity,
                unselectedLabelColor: IvfErpTheme.textMuted,
                labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(icon: Icon(Icons.calendar_today_rounded, size: 14), text: '1. Antenatal Care & Risk Profile'),
                  Tab(icon: Icon(Icons.airline_seat_flat_rounded, size: 14), text: '2. Labour Room & Delivery Episode'),
                  Tab(icon: Icon(Icons.child_friendly_rounded, size: 14), text: '3. Newborn Registration & APGAR'),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    // Tab 1: ANC
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTag('Antenatal History & Risk Classification'),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(child: _field('Gravida (G)', _gravidaCtrl)),
                              const SizedBox(width: 8),
                              Expanded(child: _field('Para (P)', _paraCtrl)),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: _dropdown('High Risk Classification', _highRisk, [
                                  'Low Risk',
                                  'Previous LSCS + IVF Conception',
                                  'Gestational Diabetes (GDM)',
                                  'Preeclampsia Risk',
                                  'Twin Gestation',
                                ], (v) {
                                  if (v != null) setState(() => _highRisk = v);
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _dropdown('Allocated Ward / Bed Room', _wardBed, [
                                  'Maternity Deluxe Room - Bed 201',
                                  'Maternity Deluxe Room - Bed 202',
                                  'General Maternity Ward - Bed 101',
                                  'Labour & Delivery Suite - LDR Bed 1',
                                ], (v) {
                                  if (v != null) setState(() => _wardBed = v);
                                }),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Tab 2: Labour & Delivery
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTag('Labour Room Monitoring (Partograph Parameters)'),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(child: _field('Cervical Dilation (cm)', _cervicalCtrl, hint: 'e.g. 10.0 cm')),
                              const SizedBox(width: 8),
                              Expanded(child: _field('Fetal Heart Rate (bpm)', _fhrCtrl, hint: 'e.g. 140 - 150 bpm')),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: _dropdown('Delivery Mode / Procedure *', _deliveryType, [
                                  'Normal Vaginal Delivery',
                                  'Elective LSCS',
                                  'Emergency LSCS',
                                  'Instrumental Vacuum Assisted',
                                ], (v) {
                                  if (v != null) setState(() => _deliveryType = v);
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _sectionTag('Attending Clinical Team'),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(child: _field('Attending Obstetrician', TextEditingController(text: _doctor))),
                              const SizedBox(width: 8),
                              Expanded(child: _field('Attending Pediatrician / Neonatologist', TextEditingController(text: _pediatrician))),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Tab 3: Newborn
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTag('Newborn Baby Birth Record (Linked to Mother)'),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: _dropdown('Baby Gender', _babyGender, ['Female', 'Male', 'Twins'], (v) {
                                  if (v != null) setState(() => _babyGender = v);
                                }),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: _field('Birth Weight (kg) *', _birthWeightCtrl, hint: 'e.g. 3.15')),
                              const SizedBox(width: 8),
                              Expanded(child: _field('APGAR (1 Min)', _apgar1Ctrl, hint: '8')),
                              const SizedBox(width: 8),
                              Expanded(child: _field('APGAR (5 Min)', _apgar5Ctrl, hint: '9')),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _sectionTag('Immediate Birth Vaccinations (Zero Dose Record)'),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('BCG Vaccine Given', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            value: _bcg,
                            onChanged: (v) => setState(() => _bcg = v ?? true),
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Oral Polio Vaccine (OPV-0) Given', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            value: _opv0,
                            onChanged: (v) => setState(() => _opv0 = v ?? true),
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Hepatitis B (Birth Dose) Given', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            value: _hepb,
                            onChanged: (v) => setState(() => _hepb = v ?? true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              color: IvfErpTheme.menuBarBg,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_rounded, size: 14),
                    label: const Text('Save Maternity & Delivery Record'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: IvfErpTheme.pinkMaternity,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: _saveMaternityCase,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTag(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      color: IvfErpTheme.gridHeaderBg,
      child: Text(
        title,
        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy),
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
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: IvfErpTheme.borderDark),
          ),
          child: TextField(
            controller: ctrl,
            style: const TextStyle(fontSize: 11),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 10, color: Colors.grey),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: IvfErpTheme.borderDark),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              isExpanded: true,
              style: const TextStyle(fontSize: 10.5, color: IvfErpTheme.textMain, fontWeight: FontWeight.w600),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
