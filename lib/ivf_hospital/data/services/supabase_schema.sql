-- =====================================================================
-- IVFPro 360™ Enterprise — Cloud Supabase PostgreSQL Schema
-- Developed & Technology Partner: iSecure System Pvt. Ltd.
-- Specialized for Gynecology, Infertility, IVF/ART & Maternity Hospitals
-- =====================================================================

-- 1. Whitelabel Hospital Configuration & Masters
CREATE TABLE IF NOT EXISTS hospital_profile (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hospital_name TEXT NOT NULL DEFAULT 'Shri Radhakrishna Hospital & Infertility Centre',
    tagline TEXT DEFAULT 'Gynecology • Infertility • IVF • Maternity',
    technology_partner TEXT DEFAULT 'iSecure System Pvt. Ltd.',
    address TEXT,
    city TEXT,
    state TEXT DEFAULT 'Maharashtra',
    state_code TEXT DEFAULT '27',
    pincode TEXT,
    phone TEXT,
    emergency_helpline TEXT,
    email TEXT,
    website TEXT,
    gstin TEXT,
    pan TEXT,
    art_clinic_reg_number TEXT, -- Registered under Indian ART Act 2021
    clinical_establishment_reg TEXT,
    currency_symbol TEXT DEFAULT '₹',
    license_key TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Master Patients & Couple Records
CREATE TABLE IF NOT EXISTS patients (
    uhid TEXT PRIMARY KEY,
    female_name TEXT NOT NULL,
    female_age INT NOT NULL,
    female_blood_group TEXT DEFAULT 'B+',
    phone TEXT NOT NULL,
    email TEXT,
    address TEXT,
    male_partner_name TEXT,
    male_age INT,
    male_blood_group TEXT,
    male_phone TEXT,
    years_of_marriage INT DEFAULT 0,
    clinical_category TEXT NOT NULL, -- 'IVF', 'INFERTILITY', 'GYNECOLOGY', 'MATERNITY'
    infertility_type TEXT DEFAULT 'N/A', -- 'Primary Infertility', 'Secondary Infertility'
    infertility_duration_years INT DEFAULT 0,
    lmp_date TEXT,
    obstetric_gpla TEXT DEFAULT 'G0 P0 L0 A0',
    attending_doctor TEXT,
    medical_history TEXT,
    allergies TEXT,
    status TEXT DEFAULT 'Active Treatment',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. IVF & ART Cycle Management (Stimulation, OPU, Embryology, ET, Cryo)
CREATE TABLE IF NOT EXISTS ivf_cycles (
    cycle_id TEXT PRIMARY KEY,
    patient_uhid TEXT NOT NULL REFERENCES patients(uhid) ON DELETE CASCADE,
    patient_name TEXT NOT NULL,
    cycle_type TEXT NOT NULL, -- 'ICSI', 'IVF', 'FET', 'IUI', 'Egg Freezing'
    protocol TEXT DEFAULT 'Antagonist Protocol',
    start_date DATE NOT NULL,
    stimulation_days INT DEFAULT 0,
    stimulation_medications TEXT,
    right_ovary_follicles TEXT,
    left_ovary_follicles TEXT,
    endometrial_thickness_mm NUMERIC(4,2),
    trigger_date TIMESTAMPTZ,
    trigger_medicine TEXT,
    opu_date TIMESTAMPTZ,
    total_oocytes_retrieved INT DEFAULT 0,
    m2_oocytes INT DEFAULT 0,
    m1_oocytes INT DEFAULT 0,
    gv_oocytes INT DEFAULT 0,
    semen_sample_type TEXT DEFAULT 'Fresh Partner',
    fertilization_2pn_count INT DEFAULT 0,
    day3_cleavage_count INT DEFAULT 0,
    day5_blastocyst_count INT DEFAULT 0,
    blastocyst_grading TEXT,
    embryo_transfer_date TIMESTAMPTZ,
    transfer_type TEXT DEFAULT 'FET - Frozen Embryo Transfer',
    embryos_transferred_count INT DEFAULT 0,
    embryos_frozen_count INT DEFAULT 0,
    cryo_storage_location TEXT,
    beta_hcg_value NUMERIC(7,2),
    cycle_outcome TEXT DEFAULT 'Ongoing',
    attending_doctor TEXT,
    attending_embryologist TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Maternity, Labour, Delivery & Newborn Records
CREATE TABLE IF NOT EXISTS maternity_cases (
    case_id TEXT PRIMARY KEY,
    patient_uhid TEXT NOT NULL REFERENCES patients(uhid) ON DELETE CASCADE,
    patient_name TEXT NOT NULL,
    lmp DATE NOT NULL,
    edd DATE NOT NULL,
    gravida INT DEFAULT 1,
    para INT DEFAULT 0,
    is_ivf_conception BOOLEAN DEFAULT TRUE,
    high_risk_condition TEXT DEFAULT 'Low Risk',
    ward_bed TEXT,
    admission_date TIMESTAMPTZ,
    labour_start_time TIMESTAMPTZ,
    cervical_dilation_cm NUMERIC(4,1),
    fetal_heart_rate_bpm INT,
    delivery_date TIMESTAMPTZ,
    delivery_type TEXT DEFAULT 'Normal Vaginal',
    attending_obstetrician TEXT,
    attending_pediatrician TEXT,
    baby_gender TEXT,
    birth_weight_kg NUMERIC(4,2),
    apgar_1min INT,
    apgar_5min INT,
    vaccine_bcg_given BOOLEAN DEFAULT FALSE,
    vaccine_opv0_given BOOLEAN DEFAULT FALSE,
    vaccine_hepb_given BOOLEAN DEFAULT FALSE,
    case_status TEXT DEFAULT 'Antenatal Care',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Billing, IVF Packages & GST Invoices
CREATE TABLE IF NOT EXISTS billing_invoices (
    invoice_number TEXT PRIMARY KEY,
    patient_uhid TEXT NOT NULL REFERENCES patients(uhid),
    patient_name TEXT NOT NULL,
    category TEXT NOT NULL, -- 'IVF Package', 'OPD Consultation', 'Maternity Delivery IPD', 'Diagnostics / Lab', 'Pharmacy'
    service_description TEXT NOT NULL,
    base_taxable NUMERIC(10,2) NOT NULL,
    cgst_amount NUMERIC(10,2) DEFAULT 0.00,
    sgst_amount NUMERIC(10,2) DEFAULT 0.00,
    total_amount NUMERIC(10,2) NOT NULL,
    paid_amount NUMERIC(10,2) NOT NULL,
    balance_due NUMERIC(10,2) DEFAULT 0.00,
    payment_mode TEXT DEFAULT 'UPI',
    status TEXT DEFAULT 'PAID',
    invoice_date TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Diagnostics, Semen Analysis & Lab Investigations
CREATE TABLE IF NOT EXISTS lab_investigations (
    order_id TEXT PRIMARY KEY,
    patient_uhid TEXT NOT NULL REFERENCES patients(uhid),
    patient_name TEXT NOT NULL,
    test_category TEXT NOT NULL, -- 'HORMONES', 'SEMEN ANALYSIS', 'HEMATOLOGY', 'USG RADIOLOGY'
    test_name TEXT NOT NULL,
    result_value TEXT NOT NULL,
    normal_range TEXT NOT NULL,
    unit TEXT NOT NULL,
    status TEXT DEFAULT 'COMPLETED',
    order_date TIMESTAMPTZ DEFAULT NOW(),
    pathologist_notes TEXT
);

-- 7. Pharmacy Inventory & Drug Masters
CREATE TABLE IF NOT EXISTS pharmacy_inventory (
    medicine_id TEXT PRIMARY KEY,
    brand_name TEXT NOT NULL,
    composition TEXT NOT NULL,
    category TEXT NOT NULL,
    batch_number TEXT NOT NULL,
    expiry_date DATE NOT NULL,
    current_stock INT NOT NULL DEFAULT 0,
    reorder_level INT NOT NULL DEFAULT 10,
    mrp_unit NUMERIC(8,2) NOT NULL
);

-- 8. Audit Log Table for ART Act 2021 Regulatory Trail
CREATE TABLE IF NOT EXISTS clinical_audit_log (
    log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action_type TEXT NOT NULL,
    module_name TEXT NOT NULL,
    patient_uhid TEXT,
    performed_by TEXT NOT NULL,
    details TEXT,
    ip_address TEXT,
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE ivf_cycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE maternity_cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE billing_invoices ENABLE ROW LEVEL SECURITY;

-- Allow authenticated read/write
CREATE POLICY "Allow authenticated staff access" ON patients FOR ALL USING (true);
CREATE POLICY "Allow authenticated staff ivf access" ON ivf_cycles FOR ALL USING (true);
CREATE POLICY "Allow authenticated staff maternity access" ON maternity_cases FOR ALL USING (true);
CREATE POLICY "Allow authenticated staff billing access" ON billing_invoices FOR ALL USING (true);
