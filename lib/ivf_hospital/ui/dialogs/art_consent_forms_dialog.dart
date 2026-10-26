import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/ivf_erp_theme.dart';
import '../../data/repositories/ivf_hospital_repository.dart';
import '../widgets/win32_window_frame.dart';
import 'print_preview_dialog.dart';

/// Indian ART Act 2021 & PCPNDT Statutory Consent Forms & Legal Undertakings
/// Compliant with National Assisted Reproductive Technology & Surrogacy Act 2021
class ArtConsentFormsDialog extends StatefulWidget {
  final IvfHospitalRepository repo;

  const ArtConsentFormsDialog({super.key, required this.repo});

  static Future<void> show(BuildContext context, IvfHospitalRepository repo) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ArtConsentFormsDialog(repo: repo),
    );
  }

  @override
  State<ArtConsentFormsDialog> createState() => _ArtConsentFormsDialogState();
}

class _ArtConsentFormsDialogState extends State<ArtConsentFormsDialog> {
  int _selectedFormIndex = 0;
  String _selectedPatientUhid = '';

  @override
  void initState() {
    super.initState();
    if (widget.repo.patients.isNotEmpty) {
      _selectedPatientUhid = widget.repo.patients.first.uhid;
    }
  }

  final List<String> _formTitles = [
    'Form 1: Informed Consent for IVF / ICSI Procedure (Sec 21 ART Act 2021)',
    'Form 2: Oocyte Pick-Up (OPU) & General Anaesthesia Consent',
    'Form 3: Cryopreservation & Vitrification Undertaking (Embryos / Gametes)',
    'Form 4: Declaration for Pre-implantation Genetic Testing (PGT)',
    'Form 5: Statutory Undertaking of Non-Sex Selection (PCPNDT Act 1994)',
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.repo.patients.isEmpty) {
      return const Win32WindowFrame(
        title: 'STATUTORY CONSENT FORMS & INDIAN ART ACT 2021',
        icon: Icons.gavel_rounded,
        child: Center(child: Text('No patient records found to generate statutory consent form.')),
      );
    }

    final patient = widget.repo.patients.firstWhere(
      (p) => p.uhid == _selectedPatientUhid,
      orElse: () => widget.repo.patients.first,
    );
    final config = widget.repo.config;
    final nowFormatted = DateFormat('dd-MMMM-yyyy').format(DateTime.now());

    return Win32WindowFrame(
      title: 'STATUTORY CONSENT FORMS & INDIAN ART ACT 2021',
      subtitle: '${config.hospitalName} • ${config.activeBranch.branchName}',
      icon: Icons.gavel_rounded,
      defaultWidth: 1000,
      defaultHeight: 650,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

            // Patient Selector & Quick Controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: const Color(0xFFEAECEE),
              child: Row(
                children: [
                  const Text('Select Patient Couple: ', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                  Container(
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: IvfErpTheme.borderDark)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: widget.repo.patients.any((p) => p.uhid == _selectedPatientUhid)
                            ? _selectedPatientUhid
                            : (widget.repo.patients.isNotEmpty ? widget.repo.patients.first.uhid : null),
                        isDense: true,
                        style: const TextStyle(fontSize: 10.5, color: Colors.black87),
                        items: widget.repo.patients.map((p) {
                          return DropdownMenuItem(
                            value: p.uhid,
                            child: Text('${p.uhid} - ${p.femaleName} & ${p.malePartnerName ?? "Partner"}'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPatientUhid = val);
                        },
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    color: const Color(0xFFD4EFDF),
                    child: Text(
                      'ART Registration No: ${config.artClinicRegNumber}',
                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: IvfErpTheme.medicalEmerald),
                    ),
                  ),
                ],
              ),
            ),

            // Main Two-Panel Layout
            Expanded(
              child: Row(
                children: [
                  // Left: Form Selection List
                  Container(
                    width: 280,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(right: BorderSide(color: IvfErpTheme.borderDark)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          color: IvfErpTheme.gridHeaderBg,
                          child: const Text('Mandatory Legal Forms (ART Act 2021)', style: IvfErpTheme.gridHeaderStyle),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _formTitles.length,
                            itemBuilder: (context, idx) {
                              final isSelected = _selectedFormIndex == idx;
                              return InkWell(
                                onTap: () => setState(() => _selectedFormIndex = idx),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  color: isSelected ? const Color(0xFFD6EAF8) : (idx.isEven ? Colors.white : const Color(0xFFFBFBFB)),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected ? Icons.check_circle_rounded : Icons.description_outlined,
                                        size: 14,
                                        color: isSelected ? IvfErpTheme.primaryNavy : Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _formTitles[idx],
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected ? IvfErpTheme.primaryNavy : Colors.black87,
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
                    ),
                  ),

                  // Right: Form Preview / Print Sheet
                  Expanded(
                    child: Container(
                      color: const Color(0xFFF2F4F4),
                      padding: const EdgeInsets.all(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade400),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Hospital Letterhead
                              Center(
                                child: Column(
                                  children: [
                                    Text(
                                      config.hospitalName.toUpperCase(),
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      config.tagline,
                                      style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey),
                                    ),
                                    Text(
                                      '${config.address} | Phone: ${config.phone}',
                                      style: const TextStyle(fontSize: 9.5, color: Colors.black87),
                                    ),
                                    Text(
                                      'National ART Clinic Reg No: ${config.artClinicRegNumber} | GSTIN: ${config.gstin}',
                                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: IvfErpTheme.medicalEmerald),
                                    ),
                                    const SizedBox(height: 6),
                                    const Divider(thickness: 1.5, color: IvfErpTheme.primaryNavy),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Form Header
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                color: const Color(0xFFEBF5FB),
                                child: Text(
                                  _formTitles[_selectedFormIndex].toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Patient Demographics Table
                              Table(
                                border: TableBorder.all(color: Colors.grey.shade300),
                                columnWidths: const {
                                  0: FlexColumnWidth(1.5),
                                  1: FlexColumnWidth(2.5),
                                  2: FlexColumnWidth(1.5),
                                  3: FlexColumnWidth(2.5),
                                },
                                children: [
                                  TableRow(
                                    decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
                                    children: [
                                      _tableCell('Female Partner (Wife):', isBold: true),
                                      _tableCell('${patient.femaleName} (${patient.femaleAge}y / ${patient.femaleBloodGroup})'),
                                      _tableCell('Male Partner (Husband):', isBold: true),
                                      _tableCell('${patient.malePartnerName ?? "N/A"} (${patient.maleAge ?? 0}y)'),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      _tableCell('UHID Registration:', isBold: true),
                                      _tableCell(patient.uhid),
                                      _tableCell('Attending IVF Specialist:', isBold: true),
                                      _tableCell(patient.attendingDoctor),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      _tableCell('Clinical Indication:', isBold: true),
                                      _tableCell(patient.infertilityType),
                                      _tableCell('Execution Date:', isBold: true),
                                      _tableCell(nowFormatted),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Dynamic Form Legal Content
                              _buildFormBodyContent(_selectedFormIndex, patient, config),

                              const SizedBox(height: 24),

                              // Signatures Matrix
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _signatureBox('Signature of Female Patient\n(${patient.femaleName})'),
                                  _signatureBox('Signature of Male Partner\n(${patient.malePartnerName ?? "Husband"})'),
                                  _signatureBox('Signature of IVF Specialist\n(${patient.attendingDoctor})'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              color: IvfErpTheme.menuBarBg,
              child: Row(
                children: [
                  const Text(
                    'Mandatory for all ART Cycles under National Assisted Reproductive Technology & Surrogacy Act 2021.',
                    style: TextStyle(fontSize: 10, color: Colors.black87),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _openConsentPrintPreview(patient, config),
                    icon: const Icon(Icons.print_rounded, size: 14),
                    label: const Text('Print Statutory Form', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: IvfErpTheme.primaryNavy,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      side: const BorderSide(color: IvfErpTheme.borderDark),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Close', style: TextStyle(fontSize: 10.5)),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  void _openConsentPrintPreview(dynamic patient, dynamic config) {
    final formTitle = _formTitles[_selectedFormIndex];
    PrintPreviewDialog.show(
      context: context,
      config: widget.repo.config,
      documentTitle: 'INDIAN ART REGULATION ACT 2021 STATUTORY UNDERTAKING',
      documentSubtitle: formTitle,
      documentNumber: 'ART-FORM-${_selectedFormIndex + 1}-${patient.uhid}',
      initialPaperFormat: 'A4',
      previewContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                      Text('Female Patient: ${patient.femaleName} (${patient.femaleAge}y / ${patient.femaleBloodGroup})', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                      Text('Male Partner: ${patient.malePartnerName ?? "N/A"} (${patient.maleAge ?? 0}y)', style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('UHID: ${patient.uhid}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                      Text('Specialist: ${patient.attendingDoctor}', style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(6),
            color: const Color(0xFFEBF5FB),
            child: Text(
              formTitle.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: IvfErpTheme.primaryNavy),
            ),
          ),
          const SizedBox(height: 12),
          _buildFormBodyContent(_selectedFormIndex, patient, config),
        ],
      ),
    );
  }

  Widget _tableCell(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Text(
        text,
        style: TextStyle(fontSize: 9.5, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
      ),
    );
  }

  Widget _signatureBox(String label) {
    return Column(
      children: [
        Container(
          width: 170,
          height: 45,
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
          child: const Center(
            child: Text('[ Signed / Digitally Verified ]', style: TextStyle(fontSize: 8.5, color: Colors.grey, fontStyle: FontStyle.italic)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildFormBodyContent(int formIndex, dynamic patient, dynamic config) {
    switch (formIndex) {
      case 0: // Form 1: IVF / ICSI
        return const Text(
          '1. We, the undersigned couple, hereby freely authorize and give informed consent to undergo In Vitro Fertilization (IVF) / Intra-Cytoplasmic Sperm Injection (ICSI).\n\n'
          '2. The treating fertility specialist has explained to us the detailed medical protocol including Controlled Ovarian Stimulation, Follicular Monitoring, Trigger timing, Oocyte Retrieval under anaesthesia, Sperm Preparation, Laboratory Insemination/ICSI, Embryo Culture, and Ultrasound-Guided Embryo Transfer.\n\n'
          '3. We have been informed that while advanced clinical and embryological standards are maintained, a successful clinical pregnancy cannot be guaranteed. Possible risks including Ovarian Hyperstimulation Syndrome (OHSS), multiple gestation, and ectopic pregnancy have been fully explained.\n\n'
          '4. We confirm compliance with Section 21 and Section 22 of the Indian Assisted Reproductive Technology (Regulation) Act, 2021 regarding couple eligibility and insurance coverage.',
          style: TextStyle(fontSize: 10, height: 1.5, color: Colors.black87),
        );
      case 1: // Form 2: OPU & Anaesthesia
        return const Text(
          '1. I hereby authorize the surgical team and anaesthetist to perform Transvaginal Ultrasound-Guided Oocyte Pick-Up (OPU) under IV Sedation / General Anaesthesia.\n\n'
          '2. The procedure involves inserting a fine needle through the vaginal wall into the ovarian follicles under continuous ultrasound visualization to aspirate follicular fluid and retrieve oocytes.\n\n'
          '3. Risks including minor vaginal bleeding, pelvic cramping, anaesthetic reactions, or accidental injury to adjacent pelvic organs have been explained, and necessary fasting guidelines (NPO 8 hours) have been observed.',
          style: TextStyle(fontSize: 10, height: 1.5, color: Colors.black87),
        );
      case 2: // Form 3: Cryopreservation
        return const Text(
          '1. We hereby authorize the cryopreservation and ultra-rapid vitrification of surplus viable embryos / gametes for long-term storage in Liquid Nitrogen (-196°C).\n\n'
          '2. STORAGE DURATION: As per the ART Regulation Act 2021, embryos may be cryopreserved for a maximum permitted legal duration, subject to annual maintenance fees.\n\n'
          '3. DISPOSAL PROTOCOL: In the event of non-renewal of storage charges after due registered notice, or mutual written request by the couple, or demise of both partners, the clinic is authorized to thaw and discard or donate surplus samples strictly in compliance with National ART Registry guidelines.',
          style: TextStyle(fontSize: 10, height: 1.5, color: Colors.black87),
        );
      case 3: // Form 4: PGT
        return const Text(
          '1. We request and consent to Trophectoderm Biopsy on Day 5/6 Blastocysts for Pre-implantation Genetic Testing for Aneuploidies (PGT-A) or Monogenic Disorders (PGT-M).\n\n'
          '2. We understand that PGT evaluates chromosomal euploidy to optimize embryo selection and reduce miscarriage risks.\n\n'
          '3. STATUTORY NOTICE: PGT is performed strictly for detecting genetic and chromosomal defects. Pre-implantation sex determination or gender disclosure is strictly PROHIBITED under Indian Law.',
          style: TextStyle(fontSize: 10, height: 1.5, color: Colors.black87),
        );
      case 4: // Form 5: PCPNDT Non-Sex Selection
      default:
        return Container(
          padding: const EdgeInsets.all(10),
          color: const Color(0xFFFDEDEC),
          child: const Text(
            'STATUTORY DECLARATION UNDER PRE-CONCEPTION AND PRE-NATAL DIAGNOSTIC TECHNIQUES (PROHIBITION OF SEX SELECTION) ACT, 1994 (PCPNDT ACT):\n\n'
            'We, the patient couple and treating medical practitioner, solemnly affirm and declare that during the course of any diagnostic ultrasound, follicular monitoring, antenatal scan, or ART procedure:\n\n'
            '• The sex of the fetus/embryo was NEITHER determined NOR disclosed to anyone directly or indirectly.\n'
            '• Sex selection is a cognizable and non-bailable offense punishable with imprisonment and cancellation of medical registration under the PCPNDT Act.',
            style: TextStyle(fontSize: 10, height: 1.5, fontWeight: FontWeight.bold, color: IvfErpTheme.alertRuby),
          ),
        );
    }
  }
}
