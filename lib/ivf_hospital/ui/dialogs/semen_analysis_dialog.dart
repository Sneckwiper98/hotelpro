import 'package:flutter/material.dart';
import '../../config/ivf_erp_theme.dart';
import '../../data/models/ivf_patient_model.dart';
import '../../data/repositories/ivf_hospital_repository.dart';

/// WHO 6th Edition Semen Analysis & Andrology Laboratory Report Dialog
class SemenAnalysisDialog extends StatefulWidget {
  final IvfHospitalRepository repo;

  const SemenAnalysisDialog({super.key, required this.repo});

  static Future<void> show(BuildContext context, IvfHospitalRepository repo) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => SemenAnalysisDialog(repo: repo),
    );
  }

  @override
  State<SemenAnalysisDialog> createState() => _SemenAnalysisDialogState();
}

class _SemenAnalysisDialogState extends State<SemenAnalysisDialog> {
  IvfPatientModel? _selectedPatient;

  final _abstinenceCtrl = TextEditingController(text: '3');
  final _liquefactionCtrl = TextEditingController(text: '25');
  final _volumeCtrl = TextEditingController(text: '2.8');
  final _concCtrl = TextEditingController(text: '48.0');
  final _prCtrl = TextEditingController(text: '45');
  final _npCtrl = TextEditingController(text: '12');
  final _immotileCtrl = TextEditingController(text: '43');
  final _morphologyCtrl = TextEditingController(text: '6');
  final _vitalityCtrl = TextEditingController(text: '72');
  final _wbcCtrl = TextEditingController(text: '1-2');

  String _appearance = 'Greyish-Opalescent';
  String _viscosity = 'Normal';
  String _impression = 'Normozoospermia';
  String _recommendation = 'Suitable for Natural Conception or Intrauterine Insemination (IUI).';

  @override
  void initState() {
    super.initState();
    if (widget.repo.patients.isNotEmpty) {
      _selectedPatient = widget.repo.patients.first;
    }
  }

  @override
  void dispose() {
    _abstinenceCtrl.dispose();
    _liquefactionCtrl.dispose();
    _volumeCtrl.dispose();
    _concCtrl.dispose();
    _prCtrl.dispose();
    _npCtrl.dispose();
    _immotileCtrl.dispose();
    _morphologyCtrl.dispose();
    _vitalityCtrl.dispose();
    _wbcCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final dialogWidth = (screen.width * 0.90).clamp(780.0, 960.0);
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
          children: [
            // Win32 Title Bar
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              color: IvfErpTheme.primaryNavy,
              child: Row(
                children: [
                  const Icon(Icons.biotech_rounded, size: 15, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'WHO 6th Edition Semen Analysis & Andrology Lab Report — ${widget.repo.config.hospitalName}',
                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
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
              color: const Color(0xFFEBF5FB),
              child: Row(
                children: [
                  const Text('Select Couple / Male Partner: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 26,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: IvfErpTheme.borderDark)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<IvfPatientModel>(
                          value: _selectedPatient,
                          isDense: true,
                          isExpanded: true,
                          items: widget.repo.patients.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Text('${p.uhid} — Husband: ${p.malePartnerName ?? "N/A"} (Wife: ${p.femaleName})'),
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

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTag('1. Macroscopic & Sample Collection Parameters'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: _field('Abstinence Period (Days) [Ref: 2-7]', _abstinenceCtrl)),
                        const SizedBox(width: 8),
                        Expanded(child: _field('Liquefaction Time (min) [Ref: <60]', _liquefactionCtrl)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _dropdown('Appearance', _appearance, ['Greyish-Opalescent', 'Viscous / Thick', 'Watery / Clear', 'Blood Tinged'], (v) {
                            if (v != null) setState(() => _appearance = v);
                          }),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _dropdown('Viscosity', _viscosity, ['Normal', 'Moderate High', 'High'], (v) {
                            if (v != null) setState(() => _viscosity = v);
                          }),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    _sectionTag('2. Microscopic Parameters (WHO 6th Manual Biological References)'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: _field('Ejaculate Volume (mL) [Ref: ≥ 1.4 mL] *', _volumeCtrl)),
                        const SizedBox(width: 8),
                        Expanded(child: _field('Sperm Concentration (M/mL) [Ref: ≥ 16 M/mL] *', _concCtrl)),
                        const SizedBox(width: 8),
                        Expanded(child: _field('Progressive Motility (PR %) [Ref: ≥ 30%] *', _prCtrl)),
                        const SizedBox(width: 8),
                        Expanded(child: _field('Non-Progressive (NP %)', _npCtrl)),
                        const SizedBox(width: 8),
                        Expanded(child: _field('Immotile (%)', _immotileCtrl)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _field('Kruger Strict Morphology (%) [Ref: ≥ 4%] *', _morphologyCtrl)),
                        const SizedBox(width: 8),
                        Expanded(child: _field('Vitality (%) [Ref: ≥ 54%]', _vitalityCtrl)),
                        const SizedBox(width: 8),
                        Expanded(child: _field('Pus Cells / WBC (/HPF) [Ref: < 5]', _wbcCtrl)),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _dropdown('Diagnostic Andrology Impression *', _impression, [
                            'Normozoospermia',
                            'Oligozoospermia (Low Count)',
                            'Asthenozoospermia (Low Motility)',
                            'Teratozoospermia (Poor Morphology)',
                            'Oligoasthenoteratozoospermia (OAT)',
                            'Azoospermia (Nil Sperm)',
                          ], (v) {
                            if (v != null) {
                              setState(() {
                                _impression = v;
                                if (v == 'Oligoasthenoteratozoospermia (OAT)') {
                                  _recommendation = 'Severe male factor. ICSI (Intracytoplasmic Sperm Injection) advised.';
                                } else if (v == 'Normozoospermia') {
                                  _recommendation = 'Normal semen parameters. Natural conception or IUI indicated.';
                                }
                              });
                            }
                          }),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    _sectionTag('3. Clinical Recommendation & Andrologist Notes'),
                    const SizedBox(height: 6),
                    _field('Specialist Treatment Advice', TextEditingController(text: _recommendation), maxLines: 2),
                  ],
                ),
              ),
            ),

            // Bottom Actions Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: IvfErpTheme.menuBarBg,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.print_rounded, size: 14),
                    label: const Text('Save & Print WHO Semen Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: IvfErpTheme.primaryNavy,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Semen Analysis report saved & linked to patient record!'),
                          backgroundColor: IvfErpTheme.medicalEmerald,
                        ),
                      );
                    },
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

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1}) {
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
            style: const TextStyle(fontSize: 10.5),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
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
              style: const TextStyle(fontSize: 10, color: IvfErpTheme.textMain, fontWeight: FontWeight.w600),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
