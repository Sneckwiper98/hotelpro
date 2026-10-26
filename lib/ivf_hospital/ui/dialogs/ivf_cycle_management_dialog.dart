import 'package:flutter/material.dart';
import '../../config/ivf_erp_theme.dart';
import '../../data/models/ivf_cycle_model.dart';
import '../../data/models/ivf_patient_model.dart';
import '../../data/repositories/ivf_hospital_repository.dart';
import '../widgets/win32_window_frame.dart';
import 'print_preview_dialog.dart';

/// Specialized IVF & ART Cycle Management Dialog (Stimulation, OPU, Embryology, ET, Outcome)
class IvfCycleManagementDialog extends StatefulWidget {
  final IvfHospitalRepository repo;
  final IvfCycleModel? existingCycle;

  const IvfCycleManagementDialog({super.key, required this.repo, this.existingCycle});

  static Future<void> show(BuildContext context, IvfHospitalRepository repo, {IvfCycleModel? existingCycle}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => IvfCycleManagementDialog(repo: repo, existingCycle: existingCycle),
    );
  }

  @override
  State<IvfCycleManagementDialog> createState() => _IvfCycleManagementDialogState();
}

class _IvfCycleManagementDialogState extends State<IvfCycleManagementDialog> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  String? _selectedPatientUhid;
  String _cycleType = 'ICSI';
  String _protocol = 'Antagonist Protocol';
  final _stimDaysCtrl = TextEditingController(text: '10');
  final _stimMedsCtrl = TextEditingController(text: 'Inj. Gonal-F 225 IU + Menopur 75 IU + Cetrotide 0.25mg');
  final _rightFolliclesCtrl = TextEditingController(text: '19mm, 18mm, 16mm, 15mm');
  final _leftFolliclesCtrl = TextEditingController(text: '20mm, 17mm, 16mm');
  final _endoMmCtrl = TextEditingController(text: '9.4');

  final _totalOocytesCtrl = TextEditingController(text: '14');
  final _m2Ctrl = TextEditingController(text: '11');
  final _m1Ctrl = TextEditingController(text: '2');
  final _gvCtrl = TextEditingController(text: '1');
  String _semenType = 'Fresh Partner';

  final _fert2pnCtrl = TextEditingController(text: '9');
  final _day3Ctrl = TextEditingController(text: '8');
  final _day5BlastCtrl = TextEditingController(text: '5');
  final _blastGradingCtrl = TextEditingController(text: '4AA, 4AB, 3BB');

  String _transferType = 'FET - Frozen Embryo Transfer';
  final _transferredCountCtrl = TextEditingController(text: '1');
  final _frozenCountCtrl = TextEditingController(text: '4');
  final _cryoLocCtrl = TextEditingController(text: 'Cryo Tank 2 • Canister 3 • Straw #8821');
  final _betaHcgCtrl = TextEditingController(text: '485.5');
  String _cycleOutcome = 'Positive (Pregnant)';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);

    if (widget.existingCycle != null) {
      final c = widget.existingCycle!;
      _cycleType = c.cycleType;
      _protocol = c.protocol;
      _stimDaysCtrl.text = '${c.stimulationDays}';
      _stimMedsCtrl.text = c.stimulationMedications;
      _rightFolliclesCtrl.text = c.rightOvaryFollicles;
      _leftFolliclesCtrl.text = c.leftOvaryFollicles;
      _endoMmCtrl.text = '${c.endometrialThicknessMm}';
      _totalOocytesCtrl.text = '${c.totalOocytesRetrieved}';
      _m2Ctrl.text = '${c.m2Oocytes}';
      _m1Ctrl.text = '${c.m1Oocytes}';
      _gvCtrl.text = '${c.gvOocytes}';
      _semenType = c.semenSampleType;
      _fert2pnCtrl.text = '${c.fertilization2pnCount}';
      _day3Ctrl.text = '${c.day3CleavageCount}';
      _day5BlastCtrl.text = '${c.day5BlastocystCount}';
      _blastGradingCtrl.text = c.blastocystGrading;
      _transferType = c.transferType;
      _transferredCountCtrl.text = '${c.embryosTransferredCount}';
      _frozenCountCtrl.text = '${c.embryosFrozenCount}';
      _cryoLocCtrl.text = c.cryoStorageLocation;
      _betaHcgCtrl.text = c.betaHcgValue != null ? '${c.betaHcgValue}' : '';
      _cycleOutcome = c.cycleOutcome;
      _selectedPatientUhid = c.patientUhid;
    } else {
      if (widget.repo.patients.isNotEmpty) {
        _selectedPatientUhid = widget.repo.patients.first.uhid;
      }
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _stimDaysCtrl.dispose();
    _stimMedsCtrl.dispose();
    _rightFolliclesCtrl.dispose();
    _leftFolliclesCtrl.dispose();
    _endoMmCtrl.dispose();
    _totalOocytesCtrl.dispose();
    _m2Ctrl.dispose();
    _m1Ctrl.dispose();
    _gvCtrl.dispose();
    _fert2pnCtrl.dispose();
    _day3Ctrl.dispose();
    _day5BlastCtrl.dispose();
    _blastGradingCtrl.dispose();
    _transferredCountCtrl.dispose();
    _frozenCountCtrl.dispose();
    _cryoLocCtrl.dispose();
    _betaHcgCtrl.dispose();
    super.dispose();
  }

  void _saveCycle() {
    final patient = widget.repo.patients.firstWhere(
      (p) => p.uhid == _selectedPatientUhid,
      orElse: () => widget.repo.patients.isNotEmpty ? widget.repo.patients.first : IvfPatientModel.empty(),
    );

    final cycleId = widget.existingCycle?.cycleId ??
        '${widget.repo.config.ivfCyclePrefix}${(widget.repo.ivfCycles.length + 1).toString().padLeft(3, '0')}';

    final cycle = IvfCycleModel(
      cycleId: cycleId,
      patientUhid: patient.uhid,
      patientName: patient.femaleName,
      cycleType: _cycleType,
      protocol: _protocol,
      startDate: widget.existingCycle?.startDate ?? DateTime.now(),
      stimulationDays: int.tryParse(_stimDaysCtrl.text) ?? 10,
      stimulationMedications: _stimMedsCtrl.text.trim(),
      rightOvaryFollicles: _rightFolliclesCtrl.text.trim(),
      leftOvaryFollicles: _leftFolliclesCtrl.text.trim(),
      endometrialThicknessMm: double.tryParse(_endoMmCtrl.text) ?? 9.0,
      totalOocytesRetrieved: int.tryParse(_totalOocytesCtrl.text) ?? 0,
      m2Oocytes: int.tryParse(_m2Ctrl.text) ?? 0,
      m1Oocytes: int.tryParse(_m1Ctrl.text) ?? 0,
      gvOocytes: int.tryParse(_gvCtrl.text) ?? 0,
      semenSampleType: _semenType,
      fertilization2pnCount: int.tryParse(_fert2pnCtrl.text) ?? 0,
      day3CleavageCount: int.tryParse(_day3Ctrl.text) ?? 0,
      day5BlastocystCount: int.tryParse(_day5BlastCtrl.text) ?? 0,
      blastocystGrading: _blastGradingCtrl.text.trim(),
      transferType: _transferType,
      embryosTransferredCount: int.tryParse(_transferredCountCtrl.text) ?? 0,
      embryosFrozenCount: int.tryParse(_frozenCountCtrl.text) ?? 0,
      cryoStorageLocation: _cryoLocCtrl.text.trim(),
      betaHcgValue: double.tryParse(_betaHcgCtrl.text),
      cycleOutcome: _cycleOutcome,
      attendingDoctor: patient.attendingDoctor,
      attendingEmbryologist: 'Dr. Rajesh Patel (Chief Embryologist)',
    );

    if (widget.existingCycle != null) {
      widget.repo.updateIvfCycle(cycle);
    } else {
      widget.repo.addIvfCycle(cycle);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('IVF Treatment Cycle $cycleId saved successfully!'),
        backgroundColor: IvfErpTheme.medicalEmerald,
      ),
    );
  }

  void _printCycleSummary() {
    final patient = widget.repo.patients.firstWhere(
      (p) => p.uhid == _selectedPatientUhid,
      orElse: () => widget.repo.patients.isNotEmpty ? widget.repo.patients.first : IvfPatientModel.empty(),
    );
    final config = widget.repo.config;
    final cycleId = widget.existingCycle?.cycleId ?? 'NEW-CYCLE';

    PrintPreviewDialog.show(
      context: context,
      config: config,
      documentTitle: 'IVF & EMBRYOLOGY LAB TREATMENT SUMMARY',
      documentSubtitle: 'Ovarian Stimulation, Oocyte Retrieval, Blastocyst Culture & ET Log',
      documentNumber: 'CYC-$cycleId',
      initialPaperFormat: 'A4',
      previewContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              border: Border.all(color: const Color(0xFFCCCCCC)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PATIENT: ${patient.femaleName.toUpperCase()} (${patient.femaleAge}Y / ${patient.femaleBloodGroup})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      Text('UHID: ${patient.uhid}  |  HUSBAND: ${patient.malePartnerName ?? "Husband"}', style: const TextStyle(fontSize: 10)),
                      Text('CYCLE TYPE: $_cycleType  |  PROTOCOL: $_protocol', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8E44AD))),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('OUTCOME: $_cycleOutcome', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF27AE60))),
                    Text('BETA HCG: ${_betaHcgCtrl.text.isNotEmpty ? "${_betaHcgCtrl.text} mIU/mL" : "Pending"}', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                    Text('EMBRYOLOGIST: Dr. Rajesh Patel', style: const TextStyle(fontSize: 9.5)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text('1. STIMULATION & FOLLICULAR RECOVERY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF003366))),
          const Divider(thickness: 1, height: 8),
          Text('Stimulation Duration: ${_stimDaysCtrl.text} Days  |  Medications: ${_stimMedsCtrl.text}', style: const TextStyle(fontSize: 9.5)),
          Text('Right Ovary Follicles: ${_rightFolliclesCtrl.text}  |  Left Ovary Follicles: ${_leftFolliclesCtrl.text}', style: const TextStyle(fontSize: 9.5)),
          Text('Endometrial Thickness: ${_endoMmCtrl.text} mm', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('2. OOCYTE PICKUP (OPU) & SPERM PREPARATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF003366))),
          const Divider(thickness: 1, height: 8),
          Text('Total Oocytes Retrieved: ${_totalOocytesCtrl.text}  |  Mature M-II: ${_m2Ctrl.text}  |  M-I: ${_m1Ctrl.text}  |  GV: ${_gvCtrl.text}', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
          Text('Sperm Source / Quality: $_semenType', style: const TextStyle(fontSize: 9.5)),
          const SizedBox(height: 10),
          const Text('3. EMBRYOLOGY, BLASTOCYST CULTURE & VITRIFICATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF003366))),
          const Divider(thickness: 1, height: 8),
          Text('Fertilization (2PN Confirmed): ${_fert2pnCtrl.text}  |  Day 3 Cleavage Embryos: ${_day3Ctrl.text}', style: const TextStyle(fontSize: 9.5)),
          Text('Day 5 Blastocysts Formed: ${_day5BlastCtrl.text}  |  Grading: ${_blastGradingCtrl.text}', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
          Text('Embryos Transferred: ${_transferredCountCtrl.text} ($_transferType)', style: const TextStyle(fontSize: 9.5)),
          Text('Embryos Vitrified / Frozen: ${_frozenCountCtrl.text}  |  Location: ${_cryoLocCtrl.text}', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72))),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Doctor In-charge:\n${config.activeBranch.doctorInCharge}', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
              const Text('Chief Embryologist:\nDr. Rajesh Patel, M.Sc., Ph.D.', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Win32WindowFrame(
      title: widget.existingCycle != null
          ? 'EDIT IVF TREATMENT CYCLE — ${widget.existingCycle!.cycleId}'
          : 'NEW IVF / ART TREATMENT CYCLE MANAGEMENT',
      subtitle: '${widget.repo.config.hospitalName} • ${widget.repo.config.activeBranch.branchName}',
      icon: Icons.biotech_rounded,
      defaultWidth: 1050,
      defaultHeight: 680,
      child: Column(
        children: [

            // Top Patient Selector Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: const Color(0xFFF4ECF7),
              child: Row(
                children: [
                  const Text('Select Patient / Couple: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: IvfErpTheme.borderDark),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: widget.repo.patients.any((p) => p.uhid == _selectedPatientUhid)
                              ? _selectedPatientUhid
                              : (widget.repo.patients.isNotEmpty ? widget.repo.patients.first.uhid : null),
                          isDense: true,
                          isExpanded: true,
                          style: const TextStyle(fontSize: 11, color: IvfErpTheme.textMain, fontWeight: FontWeight.bold),
                          items: widget.repo.patients.map((p) {
                            return DropdownMenuItem(
                              value: p.uhid,
                              child: Text(
                                '${p.uhid} — ${p.femaleName} (Partner: ${p.malePartnerName ?? "N/A"})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedPatientUhid = v),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _dropdown('Treatment Type', _cycleType, ['ICSI', 'IVF', 'FET', 'IUI', 'Egg Freezing'], (v) {
                    if (v != null) setState(() => _cycleType = v);
                  }, width: 130),
                  const SizedBox(width: 8),
                  _dropdown('Protocol', _protocol, ['Antagonist Protocol', 'Long Agonist Protocol', 'Mild Stimulation', 'Natural Cycle'], (v) {
                    if (v != null) setState(() => _protocol = v);
                  }, width: 160),
                ],
              ),
            ),

            // Stage Tabs
            Container(
              color: IvfErpTheme.menuBarBg,
              child: TabBar(
                controller: _tabCtrl,
                isScrollable: true,
                indicatorColor: IvfErpTheme.ivfPurple,
                indicatorWeight: 3,
                labelColor: IvfErpTheme.ivfPurple,
                unselectedLabelColor: IvfErpTheme.textMuted,
                labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(icon: Icon(Icons.medication_rounded, size: 14), text: '1. Stimulation & USG Tracking'),
                  Tab(icon: Icon(Icons.egg_rounded, size: 14), text: '2. Trigger & OPU (Oocytes)'),
                  Tab(icon: Icon(Icons.science_rounded, size: 14), text: '3. Embryology & Day 5 Blastocysts'),
                  Tab(icon: Icon(Icons.child_care_rounded, size: 14), text: '4. Embryo Transfer & Beta-hCG'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    // Tab 1: Stimulation & Follicular USG
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTag('Ovarian Stimulation & Daily Injections'),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(child: _field('Stimulation Duration (Days)', _stimDaysCtrl)),
                              const SizedBox(width: 8),
                              Expanded(flex: 3, child: _field('Stimulation Drugs & Dosage', _stimMedsCtrl, hint: 'e.g. Rec-FSH 225 IU + Menopur 75 IU + Cetrotide')),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _sectionTag('Follicular Monitoring Ultrasound (USG) Measurements (mm)'),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(child: _field('Right Ovary Follicles (mm)', _rightFolliclesCtrl, hint: 'e.g. 19mm, 18mm, 16mm, 14mm')),
                              const SizedBox(width: 8),
                              Expanded(child: _field('Left Ovary Follicles (mm)', _leftFolliclesCtrl, hint: 'e.g. 20mm, 17mm, 16mm, 15mm')),
                              const SizedBox(width: 8),
                              Expanded(child: _field('Endometrial Thickness (mm)', _endoMmCtrl, hint: 'e.g. 9.4 mm (Triple Line)')),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Tab 2: OPU
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTag('Oocyte Pickup (OPU) Surgical Yield'),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(child: _field('Total Oocytes Retrieved *', _totalOocytesCtrl)),
                              const SizedBox(width: 8),
                              Expanded(child: _field('MII (Mature Oocytes) *', _m2Ctrl)),
                              const SizedBox(width: 8),
                              Expanded(child: _field('MI (Intermediate)', _m1Ctrl)),
                              const SizedBox(width: 8),
                              Expanded(child: _field('GV (Germinal Vesicle)', _gvCtrl)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _sectionTag('Male Semen Preparation for Insemination / ICSI'),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: _dropdown('Semen Sample Source', _semenType, ['Fresh Partner', 'Frozen Partner', 'Donor Sperm (ART Compliant)'], (v) {
                                  if (v != null) setState(() => _semenType = v);
                                }),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Tab 3: Embryology
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTag('Fertilization & Embryo Culture Progression'),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(child: _field('Day 1: 2PN Fertilized Count', _fert2pnCtrl)),
                              const SizedBox(width: 8),
                              Expanded(child: _field('Day 3: Cleavage Stage Count', _day3Ctrl)),
                              const SizedBox(width: 8),
                              Expanded(child: _field('Day 5: Blastocysts Formed', _day5BlastCtrl)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _sectionTag('Gardner Blastocyst Morphological Grading'),
                          const SizedBox(height: 6),
                          _field('Day 5/6 Blastocyst Grades', _blastGradingCtrl, hint: 'e.g. 4AA, 4AB, 3BB, 3BC (Gardner Score)'),
                        ],
                      ),
                    ),

                    // Tab 4: ET & Outcome
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTag('Embryo Transfer (ET) & Cryopreservation'),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: _dropdown('Transfer Type', _transferType, ['Fresh Transfer', 'FET - Frozen Embryo Transfer'], (v) {
                                  if (v != null) setState(() => _transferType = v);
                                }),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: _field('Embryos Transferred Count', _transferredCountCtrl)),
                              const SizedBox(width: 8),
                              Expanded(child: _field('Embryos Cryopreserved (Frozen)', _frozenCountCtrl)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _field('Vitrification Storage Tank & Straw Location', _cryoLocCtrl, hint: 'e.g. Cryo Tank 2 • Canister 3 • Straw #8821'),
                          const SizedBox(height: 12),
                          _sectionTag('Pregnancy Outcome & Serum Beta-hCG (Day 14 Post-ET)'),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(child: _field('Beta-hCG Value (mIU/mL)', _betaHcgCtrl, hint: 'e.g. 485.5 (>25 indicates pregnancy)')),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _dropdown('Cycle Clinical Outcome', _cycleOutcome, [
                                  'Positive (Pregnant)',
                                  'Ongoing / In Progress',
                                  'Stimulation in Progress',
                                  'OPU Done',
                                  'Negative',
                                  'Delivered',
                                ], (v) {
                                  if (v != null) setState(() => _cycleOutcome = v);
                                }),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Actions Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              color: IvfErpTheme.menuBarBg,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.print_rounded, size: 14),
                    label: const Text('Print Embryology & Cycle Summary (A4)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: IvfErpTheme.primaryNavy,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: _printCycleSummary,
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save_rounded, size: 14),
                    label: const Text('Save IVF Cycle Record'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: IvfErpTheme.ivfPurple,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: _saveCycle,
                  ),
                ],
              ),
            ),
          ],
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

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged, {double? width}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Container(
          width: width,
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
