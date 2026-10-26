import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/ivf_erp_theme.dart';
import '../../data/models/ivf_patient_model.dart';
import '../../data/repositories/ivf_hospital_repository.dart';

/// Central Patient 360 Comprehensive Medical Record Dialog
/// Complete longitudinal patient record covering Gynecology, Infertility, IVF, Maternity & Billing
class PatientRecord360Dialog extends StatefulWidget {
  final IvfPatientModel patient;
  final IvfHospitalRepository repo;

  const PatientRecord360Dialog({super.key, required this.patient, required this.repo});

  static Future<void> show(BuildContext context, IvfPatientModel patient, IvfHospitalRepository repo) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PatientRecord360Dialog(patient: patient, repo: repo),
    );
  }

  @override
  State<PatientRecord360Dialog> createState() => _PatientRecord360DialogState();
}

class _PatientRecord360DialogState extends State<PatientRecord360Dialog> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  final _df = DateFormat('dd-MMM-yyyy');

  // Consultation New Note Controllers
  final _complaintsCtrl = TextEditingController(text: 'Infertility for 4 years, irregular menses, severe dysmenorrhea.');
  final _bpCtrl = TextEditingController(text: '120/80');
  final _pulseCtrl = TextEditingController(text: '74');
  final _weightCtrl = TextEditingController(text: '58.5');
  final _heightCtrl = TextEditingController(text: '162');
  final _diagnosisCtrl = TextEditingController(text: 'Primary Infertility • Bilateral Tubal Factor Block • PCOS Grade 2');
  final _rxCtrl = TextEditingController(text: '1. Tab Susten 200mg (1-0-1 x 14 Days)\n2. Tab Folvite 5mg (0-1-0 x 30 Days)\n3. Tab Metformin 500mg (1-0-1 with meals)');
  final _adviceCtrl = TextEditingController(text: 'Advised Pelvic USG + Serum AMH + Partner Semen Analysis on Day 2 of next cycle.');

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _complaintsCtrl.dispose();
    _bpCtrl.dispose();
    _pulseCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _diagnosisCtrl.dispose();
    _rxCtrl.dispose();
    _adviceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final dialogWidth = (screen.width * 0.94).clamp(840.0, 1150.0);
    final dialogHeight = (screen.height * 0.92).clamp(540.0, 720.0);
    final p = widget.patient;

    // Filter patient-specific records
    final cycles = widget.repo.ivfCycles.where((c) => c.patientUhid == p.uhid).toList();
    final maternity = widget.repo.maternityCases.where((m) => m.patientUhid == p.uhid).toList();
    final labs = widget.repo.labInvestigations.where((l) => l.patientUhid == p.uhid).toList();
    final bills = widget.repo.invoices.where((b) => b.patientUhid == p.uhid).toList();

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
            // ── 1. Top Win32 Title Bar ──────────────────────────────
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              color: IvfErpTheme.primaryNavy,
              child: Row(
                children: [
                  const Icon(Icons.folder_shared_rounded, size: 15, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Central Patient 360 Medical Record — ${p.uhid} : ${p.femaleName} & ${p.malePartnerName ?? "Husband"}',
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

            // ── 2. Patient Master Summary Header ────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFFEBF5FB),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    color: IvfErpTheme.primaryNavy,
                    child: const Icon(Icons.family_restroom_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              p.femaleName.toUpperCase(),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy),
                            ),
                            const SizedBox(width: 8),
                            Text('(${p.femaleAge}y / ${p.femaleBloodGroup})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 10),
                            const Text('• Husband: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text('${p.malePartnerName ?? "N/A"} (${p.maleAge != null ? "${p.maleAge}y" : ""})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              color: IvfErpTheme.ivfPurple.withValues(alpha: 0.15),
                              child: Text(p.clinicalCategory, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: IvfErpTheme.ivfPurple)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'UHID: ${p.uhid}  |  Phone: ${p.phone}  |  Address: ${p.address}  |  Doctor: ${p.attendingDoctor}',
                          style: const TextStyle(fontSize: 10.5, color: IvfErpTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.print_rounded, size: 13),
                    label: const Text('Print Case File'),
                    style: OutlinedButton.styleFrom(shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Printing complete case file for ${p.uhid}...')),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── 3. Tabs Header ──────────────────────────────────────
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
                tabs: [
                  const Tab(icon: Icon(Icons.medical_services_rounded, size: 14), text: 'OPD Consult & Rx Prescription'),
                  Tab(icon: const Icon(Icons.biotech_rounded, size: 14), text: 'IVF / ART Cycles (${cycles.length})'),
                  Tab(icon: const Icon(Icons.child_friendly_rounded, size: 14), text: 'Maternity & Deliveries (${maternity.length})'),
                  Tab(icon: const Icon(Icons.science_rounded, size: 14), text: 'Pathology & Scans (${labs.length})'),
                  Tab(icon: const Icon(Icons.receipt_long_rounded, size: 14), text: 'Billing & Packages (${bills.length})'),
                ],
              ),
            ),

            // ── 4. Tab Views ────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    // Tab 1: OPD Consultation & Prescription Sheet
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTag('Consultation Examination & Clinical Notes'),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(flex: 3, child: _field('Chief Complaints & Symptoms *', _complaintsCtrl)),
                              const SizedBox(width: 8),
                              Expanded(child: _field('BP (mmHg)', _bpCtrl)),
                              const SizedBox(width: 8),
                              Expanded(child: _field('Pulse (bpm)', _pulseCtrl)),
                              const SizedBox(width: 8),
                              Expanded(child: _field('Weight (kg)', _weightCtrl)),
                              const SizedBox(width: 8),
                              Expanded(child: _field('Height (cm)', _heightCtrl)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _field('Clinical Diagnosis / Specialty Assessment *', _diagnosisCtrl),
                          const SizedBox(height: 10),
                          _sectionTag('Digital Prescription (Rx Drugs & Dosage)'),
                          const SizedBox(height: 6),
                          _field('Prescribed Medicines & Doses', _rxCtrl, maxLines: 4),
                          const SizedBox(height: 10),
                          _sectionTag('Clinical Instructions & Follow-up Plan'),
                          const SizedBox(height: 6),
                          _field('Diet, Lifestyle, Next Scan & Review Date', _adviceCtrl, maxLines: 2),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.save_rounded, size: 14),
                                label: const Text('Save Consultation & Print Rx'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: IvfErpTheme.medicalEmerald,
                                  foregroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Prescription saved & queued for Pharmacy dispensing!'),
                                      backgroundColor: IvfErpTheme.medicalEmerald,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Tab 2: IVF Cycles
                    cycles.isEmpty
                        ? const Center(child: Text('No IVF cycles recorded for this patient.', style: TextStyle(fontSize: 11, color: Colors.grey)))
                        : ListView.builder(
                            itemCount: cycles.length,
                            itemBuilder: (context, i) {
                              final c = cycles[i];
                              return Card(
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(c.cycleId, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy)),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            color: IvfErpTheme.ivfPurple.withValues(alpha: 0.15),
                                            child: Text('${c.cycleType} • ${c.protocol}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: IvfErpTheme.ivfPurple)),
                                          ),
                                          const Spacer(),
                                          Text('Started: ${_df.format(c.startDate)}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            color: c.cycleOutcome.contains('Positive') ? const Color(0xFFD4EFDF) : const Color(0xFFF4ECF7),
                                            child: Text(c.cycleOutcome, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c.cycleOutcome.contains('Positive') ? IvfErpTheme.medicalEmerald : IvfErpTheme.ivfPurple)),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 12),
                                      Text('Stimulation: ${c.stimulationMedications} (${c.stimulationDays} Days)', style: const TextStyle(fontSize: 10.5)),
                                      const SizedBox(height: 3),
                                      Text('Follicles: Right [${c.rightOvaryFollicles}]  |  Left [${c.leftOvaryFollicles}]  |  Endo: ${c.endometrialThicknessMm}mm', style: const TextStyle(fontSize: 10.5)),
                                      const SizedBox(height: 3),
                                      Text('Embryology: OPU ${c.totalOocytesRetrieved} Oocytes (${c.m2Oocytes} MII) → ${c.fertilization2pnCount} 2PN → ${c.day5BlastocystCount} Blastocysts [${c.blastocystGrading}]', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: IvfErpTheme.babyBlue)),
                                      if (c.betaHcgValue != null) ...[
                                        const SizedBox(height: 3),
                                        Text('Pregnancy Confirmation: Serum Beta-hCG = ${c.betaHcgValue} mIU/mL', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: IvfErpTheme.medicalEmerald)),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                    // Tab 3: Maternity Cases
                    maternity.isEmpty
                        ? const Center(child: Text('No maternity or delivery episodes recorded.', style: TextStyle(fontSize: 11, color: Colors.grey)))
                        : ListView.builder(
                            itemCount: maternity.length,
                            itemBuilder: (context, i) {
                              final m = maternity[i];
                              return Card(
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(m.caseId, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy)),
                                          const SizedBox(width: 8),
                                          Text('EDD: ${_df.format(m.edd)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            color: const Color(0xFFD4EFDF),
                                            child: Text(m.caseStatus, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: IvfErpTheme.medicalEmerald)),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 12),
                                      Text('High Risk Alert: ${m.highRiskCondition}', style: const TextStyle(fontSize: 10.5, color: IvfErpTheme.alertRuby, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 3),
                                      Text('Delivery: ${m.deliveryType}  |  Doctor: ${m.attendingObstetrician}', style: const TextStyle(fontSize: 10.5)),
                                      if (m.babyGender != null) ...[
                                        const SizedBox(height: 3),
                                        Text('Baby: ${m.babyGender} (${m.birthWeightKg} kg)  |  APGAR Score: ${m.apgar1Min} (1 min) / ${m.apgar5Min} (5 min)  |  Vaccines: BCG, OPV, Hep-B Given', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: IvfErpTheme.pinkMaternity)),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                    // Tab 4: Labs & Pathology
                    labs.isEmpty
                        ? const Center(child: Text('No laboratory investigation reports found.', style: TextStyle(fontSize: 11, color: Colors.grey)))
                        : ListView.builder(
                            itemCount: labs.length,
                            itemBuilder: (context, i) {
                              final l = labs[i];
                              return Container(
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: IvfErpTheme.borderLight)),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(l.testName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy)),
                                          Text('Normal Range: ${l.normalRange}', style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                    Text('${l.resultValue} ${l.unit}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: IvfErpTheme.medicalEmerald)),
                                  ],
                                ),
                              );
                            },
                          ),

                    // Tab 5: Billing & Invoices
                    bills.isEmpty
                        ? const Center(child: Text('No billing records recorded for this patient.', style: TextStyle(fontSize: 11, color: Colors.grey)))
                        : ListView.builder(
                            itemCount: bills.length,
                            itemBuilder: (context, i) {
                              final b = bills[i];
                              return Container(
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: IvfErpTheme.borderLight)),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${b.invoiceNumber} — ${b.category}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy)),
                                          Text(b.serviceDescription, style: const TextStyle(fontSize: 10, color: IvfErpTheme.textMuted)),
                                        ],
                                      ),
                                    ),
                                    Text('Total: ${_currency.format(b.totalAmount)}  |  Paid: ${_currency.format(b.paidAmount)}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      color: b.status == 'PAID' ? const Color(0xFFD4EFDF) : const Color(0xFFFADBD8),
                                      child: Text(b.status, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: b.status == 'PAID' ? IvfErpTheme.medicalEmerald : IvfErpTheme.alertRuby)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),

            // ── 5. Bottom Status Bar ────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: IvfErpTheme.menuBarBg,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close File'),
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
}
