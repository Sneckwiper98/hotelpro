import 'package:flutter/material.dart';
import '../../config/ivf_erp_theme.dart';
import '../../data/models/ivf_patient_model.dart';
import '../../data/repositories/ivf_hospital_repository.dart';

/// New Patient & Couple Registration Dialog
class PatientRegistrationDialog extends StatefulWidget {
  final IvfHospitalRepository repo;

  const PatientRegistrationDialog({super.key, required this.repo});

  static Future<void> show(BuildContext context, IvfHospitalRepository repo) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PatientRegistrationDialog(repo: repo),
    );
  }

  @override
  State<PatientRegistrationDialog> createState() => _PatientRegistrationDialogState();
}

class _PatientRegistrationDialogState extends State<PatientRegistrationDialog> {
  final _femaleNameCtrl = TextEditingController();
  final _femaleAgeCtrl = TextEditingController(text: '28');
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  final _maleNameCtrl = TextEditingController();
  final _maleAgeCtrl = TextEditingController(text: '31');
  final _malePhoneCtrl = TextEditingController();

  final _yearsOfMarriageCtrl = TextEditingController(text: '4');
  final _durationCtrl = TextEditingController(text: '3');
  final _gplaCtrl = TextEditingController(text: 'G0 P0 L0 A0');
  final _historyCtrl = TextEditingController();

  String _femaleBlood = 'B+';
  String _maleBlood = 'O+';
  String _category = 'IVF';
  String _infertilityType = 'Primary Infertility';
  String _doctor = 'Dr. Ananya Sharma (MS, OB-GYN, IVF Specialist)';

  @override
  void dispose() {
    _femaleNameCtrl.dispose();
    _femaleAgeCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _maleNameCtrl.dispose();
    _maleAgeCtrl.dispose();
    _malePhoneCtrl.dispose();
    _yearsOfMarriageCtrl.dispose();
    _durationCtrl.dispose();
    _gplaCtrl.dispose();
    _historyCtrl.dispose();
    super.dispose();
  }

  void _savePatient() {
    if (_femaleNameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Female Patient Name and Contact Phone.')),
      );
      return;
    }

    final nextNum = widget.repo.patients.length + 1001;
    final uhid = '${widget.repo.config.patientIdPrefix}$nextNum';

    final patient = IvfPatientModel(
      uhid: uhid,
      femaleName: _femaleNameCtrl.text.trim(),
      femaleAge: int.tryParse(_femaleAgeCtrl.text) ?? 28,
      femaleBloodGroup: _femaleBlood,
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      malePartnerName: _maleNameCtrl.text.trim().isEmpty ? null : _maleNameCtrl.text.trim(),
      maleAge: int.tryParse(_maleAgeCtrl.text),
      maleBloodGroup: _maleBlood,
      malePhone: _malePhoneCtrl.text.trim().isEmpty ? null : _malePhoneCtrl.text.trim(),
      yearsOfMarriage: int.tryParse(_yearsOfMarriageCtrl.text) ?? 0,
      clinicalCategory: _category,
      infertilityType: _infertilityType,
      infertilityDurationYears: int.tryParse(_durationCtrl.text) ?? 0,
      obstetricGpla: _gplaCtrl.text.trim(),
      attendingDoctor: _doctor,
      medicalHistory: _historyCtrl.text.trim().isEmpty ? null : _historyCtrl.text.trim(),
      status: 'Active Treatment',
    );

    widget.repo.addPatient(patient);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Patient registered successfully! UHID: $uhid'),
        backgroundColor: IvfErpTheme.medicalEmerald,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final dialogWidth = (screen.width * 0.90).clamp(700.0, 880.0);
    final dialogHeight = (screen.height * 0.88).clamp(500.0, 640.0);

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
              color: IvfErpTheme.primaryNavy,
              child: Row(
                children: [
                  const Icon(Icons.person_add_alt_1_rounded, size: 15, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'New Patient & Couple Registration — IVFPro Win32 ERP',
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

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Female Patient
                    _sectionTag('1. Female Patient Information'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(flex: 3, child: _field('Female Full Name *', _femaleNameCtrl)),
                        const SizedBox(width: 8),
                        Expanded(child: _field('Age (Yrs) *', _femaleAgeCtrl)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _dropdown('Blood Group', _femaleBlood, ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'], (v) {
                            if (v != null) setState(() => _femaleBlood = v);
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _field('Mobile Phone *', _phoneCtrl)),
                        const SizedBox(width: 8),
                        Expanded(child: _field('Email ID', _emailCtrl)),
                        const SizedBox(width: 8),
                        Expanded(flex: 2, child: _field('Residential Address', _addressCtrl)),
                      ],
                    ),

                    const SizedBox(height: 12),
                    // Section 2: Male Partner
                    _sectionTag('2. Male Partner / Husband Information (Couple Profile)'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(flex: 3, child: _field('Male Partner Full Name', _maleNameCtrl)),
                        const SizedBox(width: 8),
                        Expanded(child: _field('Age (Yrs)', _maleAgeCtrl)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _dropdown('Blood Group', _maleBlood, ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'], (v) {
                            if (v != null) setState(() => _maleBlood = v);
                          }),
                        ),
                        const SizedBox(width: 8),
                        Expanded(flex: 2, child: _field('Partner Mobile Phone', _malePhoneCtrl)),
                      ],
                    ),

                    const SizedBox(height: 12),
                    // Section 3: Clinical Specialization & Infertility History
                    _sectionTag('3. Clinical Specialty, Infertility History & Doctor Assignment'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _dropdown('Clinical Category *', _category, ['IVF', 'INFERTILITY', 'GYNECOLOGY', 'MATERNITY'], (v) {
                            if (v != null) setState(() => _category = v);
                          }),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _dropdown('Infertility Type', _infertilityType, ['Primary Infertility', 'Secondary Infertility', 'N/A'], (v) {
                            if (v != null) setState(() => _infertilityType = v);
                          }),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: _field('Years of Marriage', _yearsOfMarriageCtrl)),
                        const SizedBox(width: 8),
                        Expanded(child: _field('Infertility Duration (Yrs)', _durationCtrl)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _field('Obstetric Score (GPLA)', _gplaCtrl, hint: 'e.g. G1 P0 L0 A1')),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _dropdown('Attending Consultant Doctor *', _doctor, [
                            'Dr. Ananya Sharma (MS, OB-GYN, IVF Specialist)',
                            'Dr. Sunita Deshmukh (MD, DGO, Obstetrician)',
                            'Dr. Rajesh Patel (Chief Embryologist)',
                          ], (v) {
                            if (v != null) setState(() => _doctor = v);
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _field('Clinical Observations / Medical History', _historyCtrl, maxLines: 2, hint: 'e.g. Tubal block, PCOS, Semen abnormalities, Previous treatments'),
                  ],
                ),
              ),
            ),

            // Bottom Actions
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
                    icon: const Icon(Icons.person_add_rounded, size: 14),
                    label: const Text('Register Patient & Create UHID'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: IvfErpTheme.primaryNavy,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: _savePatient,
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

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Container(
          height: maxLines == 1 ? 26 : null,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: IvfErpTheme.borderDark),
          ),
          child: TextField(
            controller: ctrl,
            maxLines: maxLines,
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
