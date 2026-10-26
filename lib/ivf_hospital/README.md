# IVFPro 360™ Enterprise Hospital Management System
### Specialized Digital Healthcare Platform for Gynecology, Infertility, IVF/ART & Maternity Hospitals
**Developed & Technology Partner:** **iSecure System Pvt. Ltd.**  
**Client Project Foundation:** Shri Radhakrishna Hospital & Infertility Centre Specs  
**Architecture:** Classic Win32 High-Density Desktop ERP + Supabase PostgreSQL Cloud Backend

---

## 🌟 1. Product Overview
**IVFPro 360™ Enterprise** is an advanced, production-ready hospital management platform built specifically for reproductive healthcare. Unlike generic hospital software, it connects the complete **12-Step Patient Journey**:

$$\text{Women's Health} \longrightarrow \text{Gynecology} \longrightarrow \text{Infertility Investigation} \longrightarrow \text{IVF / ICSI Stimulation} \longrightarrow \text{OPU Yield} \longrightarrow \text{Embryology Lab (Blastocysts)} \longrightarrow \text{Embryo Transfer} \longrightarrow \text{Pregnancy Confirmation (Beta-hCG)} \longrightarrow \text{Antenatal Care (ANC)} \longrightarrow \text{Labour Room} \longrightarrow \text{Delivery (Normal/LSCS)} \longrightarrow \text{Mother \& Newborn Care}$$

---

## 💼 2. Whitelabel & Commercial Sale Ready
This software is designed to be **sold to any IVF hospital, clinic, or maternity centre**. You can rebrand and customize it in real-time from the **Settings Dialog** without writing any code:
- **Hospital Name & Tagline:** Change to any buyer's hospital name in 1 click.
- **National ART Clinic Registration Number:** Fully compliant with the **Assisted Reproductive Technology (Regulation) Act, 2021** and Surrogacy Act.
- **Clinical Establishment Act Registration Number & State Code.**
- **GSTIN & PAN Details:** Configurable tax identification for billing.
- **Sequencing Prefixes:** Custom UHID (`SRH-P-`), IVF Cycle (`IVF-2026-`), and Invoice (`SRH-INV-`) prefixes.
- **Permanent Technology Partner Branding:** *Developed & Technology Partner: iSecure System Pvt. Ltd.*

---

## ☁️ 3. Supabase Cloud PostgreSQL Setup
The software comes with an offline-first architecture. It runs in high-speed local mode out-of-the-box and can connect to a live Supabase backend:

1. Create a project at [supabase.com](https://supabase.com).
2. Go to the **SQL Editor** in your Supabase dashboard.
3. Open [`supabase_schema.sql`](file:///c:/Users/dell/Desktop/IvfHospital/supabase_schema.sql) and click **Run**.
4. In **IVFPro Enterprise**, open **Settings $\rightarrow$ Supabase Cloud Backend**.
5. Paste your **Supabase URL** and **Anon Key**, click **Test Supabase Connection**, and save.
6. The status bar will immediately display `🟢 Supabase Cloud Connected`!

---

## 🏥 4. Key Clinical Modules Implemented

### 1. Patient & Couple Registration
- Combined couple registration (Female Patient + Male Partner).
- Infertility type classification (Primary vs Secondary Infertility) and duration.
- Obstetric history score (G_P_L_A_).

### 2. Specialized IVF / ART Cycle Management
- **Protocol Selection:** Antagonist, Long Agonist, Mild Stimulation, Natural Cycle.
- **Stimulation Tracker:** Daily gonadotropin injections (Rec-FSH, HMG, GnRH Antagonist) and doses (IU).
- **Follicular Ultrasound Monitoring (USG):** Right & Left ovary follicle sizes (mm) and Endometrial Thickness (mm, Triple line).
- **OPU / Egg Retrieval Yield:** Total oocytes retrieved, MII mature, MI intermediate, GV germinal vesicle.
- **Embryology Laboratory:** Day 1 2PN fertilization count, Day 3 cleavage count, Day 5 blastocyst count with **Gardner morphological grading (e.g. 4AA, 4AB, 3BB)**.
- **Cryopreservation:** Straw barcode, Canister number, and Liquid Nitrogen tank storage logging.
- **Embryo Transfer & Outcome:** Fresh vs FET, transferred count, Day 14 Beta-hCG levels (mIU/mL), clinical pregnancy confirmation.

### 3. Maternity, Labour & Delivery Management
- Antenatal care tracking, LMP, Calculated EDD (Naegele's rule).
- High-risk pregnancy alerts (Previous LSCS, IVF Conception, GDM, Preeclampsia).
- Labour room partograph parameters: Cervical dilation (cm) & Fetal Heart Rate (bpm).
- Delivery management: Normal Vaginal Delivery, Elective LSCS, Emergency LSCS.
- Newborn birth record linked to mother: Baby gender, birth weight (kg), APGAR score at 1 min and 5 min, zero-dose birth vaccines (BCG, OPV-0, Hepatitis B).

### 4. Diagnostics, Pathology & Semen Analysis
- Semen analysis according to **WHO 6th Edition criteria** (Volume, Concentration M/mL, Total Motility %, Normal Morphology %).
- Hormonal investigations: Serum AMH, Estradiol (E2), Progesterone (P4), Beta-hCG, FSH, LH, TSH.

### 5. Hospital Pharmacy & Drug Inventory
- Stock register of IVF injections (Gonal-F, Menopur, Cetrotide, Ovitrelle) and luteal support (Susten).
- Batch numbers, expiry date tracking, and reorder alerts.

### 6. Billing, IVF Packages & Daily Collection
- All-inclusive IVF cycle package billing with installment tracking.
- OPD consultation bills and IPD delivery packages.
- Advance deposits, cash/UPI/card settlement, and daily cash collection registers.

---

## 🚀 5. How to Run & Build

### Running Locally:
```bash
# In c:\Users\dell\Desktop\IvfHospital:
flutter run -d windows
```

### Building Windows Desktop Release (.exe):
```bash
flutter build windows --release
```

### Building Android Mobile App (.apk):
```bash
flutter build apk --release
```
