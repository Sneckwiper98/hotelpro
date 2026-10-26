import 'package:flutter/material.dart';
import '../../config/ivf_erp_theme.dart';
import '../../data/models/ivf_patient_model.dart';
import '../../data/repositories/ivf_hospital_repository.dart';
import '../widgets/win32_window_frame.dart';
import 'print_preview_dialog.dart';

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
  String? _selectedPatientUhid;

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
      _selectedPatientUhid = widget.repo.patients.first.uhid;
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
    return Win32WindowFrame(
      title: 'WHO 6TH EDITION SEMEN ANALYSIS & ANDROLOGY LAB',
      subtitle: '${widget.repo.config.hospitalName} • ${widget.repo.config.activeBranch.branchName}',
      icon: Icons.biotech_rounded,
      defaultWidth: 960,
      defaultHeight: 650,
      child: Column(
        children: [

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
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: IvfErpTheme.borderDark)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: widget.repo.patients.any((p) => p.uhid == _selectedPatientUhid)
                              ? _selectedPatientUhid
                              : (widget.repo.patients.isNotEmpty ? widget.repo.patients.first.uhid : null),
                          isDense: true,
                          isExpanded: true,
                          items: widget.repo.patients.map((p) {
                            return DropdownMenuItem(
                              value: p.uhid,
                              child: Text(
                                '${p.uhid} — Husband: ${p.malePartnerName ?? "N/A"} (Wife: ${p.femaleName})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedPatientUhid = v),
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
                    onPressed: _openPrintPreview,
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  void _openPrintPreview() {
    final patient = widget.repo.patients.firstWhere(
      (p) => p.uhid == _selectedPatientUhid,
      orElse: () => widget.repo.patients.isNotEmpty ? widget.repo.patients.first : IvfPatientModel.empty(),
    );
    final patientName = '${patient.femaleName} & ${patient.malePartnerName ?? "Husband"}';
    final uhid = patient.uhid;

    PrintPreviewDialog.show(
      context: context,
      config: widget.repo.config,
      documentTitle: 'ANDROLOGY LABORATORY REPORT — SEMEN ANALYSIS',
      documentSubtitle: 'Standardized according to WHO Laboratory Manual 6th Edition (2021)',
      documentNumber: 'SA-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      initialPaperFormat: 'A4',
      previewContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: const Color(0xFFF9FAFB),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Couple / Patient: $patientName', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      Text('UHID: $uhid • Abstinence: ${_abstinenceCtrl.text} Days', style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Primary Indication: ${patient.infertilityType}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
                      Text('Attending Specialist: ${patient.attendingDoctor}', style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Macroscopic Evaluation Table
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: IvfErpTheme.gridHeaderBg,
            child: const Text('1. MACROSCOPIC PHYSICAL EXAMINATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy)),
          ),
          Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(2), 2: FlexColumnWidth(2), 3: FlexColumnWidth(2)},
            children: [
              TableRow(
                children: [
                  _cell('Appearance', _appearance),
                  _cell('Liquefaction Time', '${_liquefactionCtrl.text} min (< 60 min)'),
                  _cell('Semen Volume', '${_volumeCtrl.text} mL (≥ 1.4 mL)'),
                  _cell('Viscosity', _viscosity),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Microscopic Evaluation Table
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: IvfErpTheme.gridHeaderBg,
            child: const Text('2. MICROSCOPIC SPERM PARAMETERS (WHO 6th Ed Criteria)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy)),
          ),
          Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(2), 2: FlexColumnWidth(3)},
            children: [
              const TableRow(
                decoration: BoxDecoration(color: Color(0xFFEBF5FB)),
                children: [
                  Padding(padding: EdgeInsets.all(5), child: Text('Parameter', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(5), child: Text('Observed Value', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(5), child: Text('WHO 6th Ed Reference Limit', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                ],
              ),
              _paramRow('Sperm Concentration', '${_concCtrl.text} Million / mL', '≥ 16.0 Million / mL'),
              _paramRow('Progressive Motility (PR)', '${_prCtrl.text} %', '≥ 30.0 %'),
              _paramRow('Non-Progressive Motility (NP)', '${_npCtrl.text} %', '—'),
              _paramRow('Total Motility (PR + NP)', '${(double.tryParse(_prCtrl.text) ?? 0) + (double.tryParse(_npCtrl.text) ?? 0)} %', '≥ 42.0 %'),
              _paramRow('Immotile Sperms', '${_immotileCtrl.text} %', '—'),
              _paramRow('Normal Morphology (Kruger Strict)', '${_morphologyCtrl.text} %', '≥ 4.0 % Normal Forms'),
              _paramRow('Vitality (Eosin-Nigrosin)', '${_vitalityCtrl.text} %', '≥ 54.0 % Live'),
              _paramRow('Round Cells / Pus Cells', '${_wbcCtrl.text} / hpf', '< 1.0 Million / mL'),
            ],
          ),
          const SizedBox(height: 10),
          // Diagnostic Impression Box
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEAFAF1),
              border: Border.all(color: IvfErpTheme.medicalEmerald),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('DIAGNOSTIC IMPRESSION: ', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy)),
                    Text(_impression.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: IvfErpTheme.medicalEmerald)),
                  ],
                ),
                const SizedBox(height: 3),
                Text('Clinical Recommendation: $_recommendation', style: const TextStyle(fontSize: 10, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(String title, String val) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 9, color: Colors.grey)),
          Text(val, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  TableRow _paramRow(String param, String val, String ref) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(5), child: Text(param, style: const TextStyle(fontSize: 9.5))),
        Padding(padding: const EdgeInsets.all(5), child: Text(val, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy))),
        Padding(padding: const EdgeInsets.all(5), child: Text(ref, style: const TextStyle(fontSize: 9, color: Colors.black54))),
      ],
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
          height: maxLines == 1 ? 28 : null,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: IvfErpTheme.borderDark),
          ),
          child: TextField(
            controller: ctrl,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 11),
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
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: IvfErpTheme.borderDark),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : (items.isNotEmpty ? items.first : null),
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
