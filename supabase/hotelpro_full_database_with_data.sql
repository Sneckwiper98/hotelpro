-- =====================================================================
-- HOTELPRO ENTERPRISE HOTEL & RESTAURANT ERP - COMPLETE DATABASE SETUP
-- Target: Supabase (PostgreSQL 15+)
-- Contains:
--   1. Full Schema (25 Tables covering Windows ERP & 5 Mobile Apps)
--   2. Permissive Row Level Security (RLS) Policies (Flutter & Desktop compatible)
--   3. Supabase Realtime Synchronization Configuration
--   4. Comprehensive Seed Data (Hotels, Rooms, Menu, Guests, Orders, Staff, etc.)
-- =====================================================================

-- 0. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================================
-- 1. TABLE DEFINITIONS (DDL)
-- =====================================================================

-- 1. Organizations (Hotel Chains / Parent Enterprise)
CREATE TABLE IF NOT EXISTS organizations (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    chain_tier TEXT DEFAULT '5_star_luxury',
    logo_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Branches / Hotel Properties
CREATE TABLE IF NOT EXISTS branches (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    organization_id TEXT REFERENCES organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    code TEXT NOT NULL UNIQUE,
    star_rating INT DEFAULT 5,
    address TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    country TEXT DEFAULT 'India',
    phone TEXT NOT NULL,
    email TEXT NOT NULL,
    currency TEXT DEFAULT 'INR',
    tax_identifier TEXT, -- GSTIN
    check_in_time TEXT DEFAULT '14:00',
    check_out_time TEXT DEFAULT '11:00',
    amenities JSONB DEFAULT '["Valet Parking", "24/7 Concierge", "Infinity Pool", "Fine Dining", "Royal Spa"]'::jsonb,
    total_rooms INT DEFAULT 42,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Hotel Business Profile & License Configuration
CREATE TABLE IF NOT EXISTS hotel_business_config (
    id TEXT PRIMARY KEY DEFAULT 'config-primary',
    business_name TEXT NOT NULL,
    tagline TEXT,
    address TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT NOT NULL,
    gstin TEXT,
    currency TEXT DEFAULT 'INR',
    license_key TEXT,
    license_type TEXT DEFAULT 'Enterprise 5-Star Multi-Property',
    expiry_date TEXT DEFAULT '2028-12-31',
    contact_person TEXT,
    enable_rooms BOOLEAN DEFAULT TRUE,
    enable_pos BOOLEAN DEFAULT TRUE,
    enable_housekeeping BOOLEAN DEFAULT TRUE,
    enable_crs BOOLEAN DEFAULT TRUE,
    enable_banquet BOOLEAN DEFAULT TRUE,
    enable_customer_app BOOLEAN DEFAULT TRUE,
    room_gst NUMERIC(5, 2) DEFAULT 12.0,
    food_gst NUMERIC(5, 2) DEFAULT 5.0,
    logo_url TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Staff Members Master
CREATE TABLE IF NOT EXISTS staff_members (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    branch_id TEXT REFERENCES branches(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    phone TEXT NOT NULL,
    department TEXT NOT NULL, -- frontDesk, housekeeping, fnb, kitchen, accounts, management
    role TEXT NOT NULL, -- manager, captain, waiter, chef, hkSupervisor, hkStaff, frontDeskAgent
    shift TEXT DEFAULT 'morning',
    joined_date DATE DEFAULT CURRENT_DATE,
    salary NUMERIC(10, 2) DEFAULT 25000.0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Application Users (ERP & Mobile App Login Accounts)
CREATE TABLE IF NOT EXISTS app_users (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    staff_id TEXT REFERENCES staff_members(id) ON DELETE SET NULL,
    username TEXT NOT NULL UNIQUE,
    password_hash TEXT, -- Obfuscated/Encrypted PIN or password
    display_name TEXT NOT NULL,
    role TEXT NOT NULL, -- developer, superAdmin, generalManager, frontDeskSupervisor, hkSupervisor, fbCaptain, waiter, deliveryBoy
    branch_access JSONB DEFAULT '["branch-mum-01"]'::jsonb,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Floors Master
CREATE TABLE IF NOT EXISTS floors (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    branch_id TEXT REFERENCES branches(id) ON DELETE CASCADE,
    floor_number INT NOT NULL,
    label TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Room Types (Deluxe, Presidential, Executive, Villa)
CREATE TABLE IF NOT EXISTS room_types (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    branch_id TEXT REFERENCES branches(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    code TEXT NOT NULL,
    description TEXT,
    base_price NUMERIC(12, 2) NOT NULL,
    max_adults INT DEFAULT 2,
    max_children INT DEFAULT 1,
    bed_type TEXT DEFAULT 'King Size Plush Bed',
    amenities JSONB DEFAULT '["High-Speed WiFi", "Mini Bar", "Espresso Machine", "Bathtub", "Smart TV"]'::jsonb,
    image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (branch_id, code)
);

-- 8. Rooms Inventory (Live Status Tracking)
CREATE TABLE IF NOT EXISTS rooms (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    branch_id TEXT REFERENCES branches(id) ON DELETE CASCADE,
    room_type_id TEXT REFERENCES room_types(id) ON DELETE RESTRICT,
    room_number TEXT NOT NULL,
    floor_number INT NOT NULL,
    status TEXT DEFAULT 'available_clean', -- available_clean, clean_inspected, occupied, dirty_vacant, cleaning_in_progress, out_of_order, reserved
    room_type_name TEXT,
    base_price NUMERIC(12, 2) DEFAULT 0.0,
    current_guest_name TEXT,
    current_reservation_id TEXT,
    current_guest_vip TEXT,
    keycard_rfid TEXT,
    notes TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (branch_id, room_number)
);

-- 9. Guests & VIP Profiles
CREATE TABLE IF NOT EXISTS guests (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    organization_id TEXT REFERENCES organizations(id) ON DELETE CASCADE,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT,
    phone TEXT NOT NULL,
    vip_tier TEXT DEFAULT 'regular', -- regular, silver, gold, platinum, royal_club
    id_type TEXT DEFAULT 'Aadhaar Card', -- Passport, Aadhaar Card, Driving License, Voter ID
    id_number TEXT,
    dietary_preferences TEXT,
    special_requests TEXT,
    total_stays INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. Reservations / Bookings
CREATE TABLE IF NOT EXISTS reservations (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    booking_reference TEXT NOT NULL UNIQUE,
    branch_id TEXT REFERENCES branches(id) ON DELETE CASCADE,
    guest_id TEXT REFERENCES guests(id) ON DELETE RESTRICT,
    room_id TEXT REFERENCES rooms(id) ON DELETE SET NULL,
    room_type_id TEXT REFERENCES room_types(id) ON DELETE RESTRICT,
    guest_name TEXT,
    guest_phone TEXT,
    room_number TEXT,
    check_in_date DATE NOT NULL,
    check_out_date DATE NOT NULL,
    booking_status TEXT DEFAULT 'confirmed', -- confirmed, checked_in, checked_out, cancelled, no_show
    booking_source TEXT DEFAULT 'direct_walk_in', -- direct_walk_in, website, ota_booking_com, ota_mmt, corporate
    rate_per_night NUMERIC(12, 2) NOT NULL,
    advance_paid NUMERIC(12, 2) DEFAULT 0.0,
    special_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. Guest Stay Folios (Billing Master)
CREATE TABLE IF NOT EXISTS folios (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    reservation_id TEXT REFERENCES reservations(id) ON DELETE CASCADE,
    folio_number TEXT NOT NULL UNIQUE,
    room_number TEXT,
    guest_name TEXT,
    status TEXT DEFAULT 'open', -- open, settled, cancelled
    total_charges NUMERIC(12, 2) DEFAULT 0.0,
    total_paid NUMERIC(12, 2) DEFAULT 0.0,
    balance_due NUMERIC(12, 2) DEFAULT 0.0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 12. Folio Transactions (Itemized Room & Restaurant Charges)
CREATE TABLE IF NOT EXISTS folio_transactions (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    folio_id TEXT REFERENCES folios(id) ON DELETE CASCADE,
    category TEXT NOT NULL, -- room_charge, tax, restaurant, bar, spa, laundry, minibar, payment, discount
    description TEXT NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    tax_amount NUMERIC(12, 2) DEFAULT 0.0,
    is_credit BOOLEAN DEFAULT FALSE,
    payment_method TEXT,
    reference_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 13. POS Outlets (Restaurants, Rooftop Bars, Room Service)
CREATE TABLE IF NOT EXISTS pos_outlets (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    branch_id TEXT REFERENCES branches(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL, -- fine_dining, bar, room_service, cafe, poolside
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 14. POS Menu Items Master
CREATE TABLE IF NOT EXISTS pos_menu_items (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    outlet_id TEXT REFERENCES pos_outlets(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    category TEXT NOT NULL, -- Royal Biryani, Starters, Main Course, Tandoor & Breads, Beverages, Desserts
    price NUMERIC(10, 2) NOT NULL,
    is_veg BOOLEAN DEFAULT TRUE,
    emoji TEXT,
    description TEXT,
    image_url TEXT,
    tax_rate NUMERIC(5, 2) DEFAULT 5.0,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 15. POS Orders (Live Table KOTs from Waiter App & ERP)
CREATE TABLE IF NOT EXISTS pos_orders (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    outlet_id TEXT REFERENCES pos_outlets(id) ON DELETE CASCADE,
    order_number TEXT NOT NULL,
    table_number TEXT NOT NULL,
    waiter_name TEXT,
    guest_name TEXT,
    guest_phone TEXT,
    guest_dob TEXT,
    guest_address TEXT,
    status TEXT DEFAULT 'kot_printed', -- kot_printed, in_kitchen, served, settled, cancelled
    items JSONB NOT NULL DEFAULT '[]'::jsonb,
    subtotal NUMERIC(10, 2) DEFAULT 0.0,
    tax NUMERIC(10, 2) DEFAULT 0.0,
    total NUMERIC(10, 2) DEFAULT 0.0,
    notes TEXT,
    charged_to_folio_id TEXT REFERENCES folios(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 16. POS Bills History & Tax Invoices
CREATE TABLE IF NOT EXISTS pos_bills (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    bill_number TEXT NOT NULL UNIQUE,
    billing_type TEXT NOT NULL, -- tableDining, roomFolio, directTakeaway, banquetEvent
    branch_id TEXT REFERENCES branches(id) ON DELETE CASCADE,
    outlet_id TEXT REFERENCES pos_outlets(id) ON DELETE SET NULL,
    outlet_name TEXT NOT NULL,
    table_number TEXT,
    room_number TEXT,
    guest_name TEXT,
    waiter_name TEXT,
    covers INT DEFAULT 2,
    items JSONB NOT NULL DEFAULT '[]'::jsonb,
    subtotal NUMERIC(10, 2) NOT NULL,
    tax_amount NUMERIC(10, 2) DEFAULT 0.0,
    discount_amount NUMERIC(10, 2) DEFAULT 0.0,
    total_amount NUMERIC(10, 2) NOT NULL,
    payment_method TEXT DEFAULT 'Cash',
    payment_status TEXT DEFAULT 'paid',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 17. Housekeeping Tasks (Mobile App & Inspection Matrix)
CREATE TABLE IF NOT EXISTS housekeeping_tasks (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    branch_id TEXT REFERENCES branches(id) ON DELETE CASCADE,
    room_id TEXT REFERENCES rooms(id) ON DELETE CASCADE,
    room_number TEXT NOT NULL,
    floor_number INT NOT NULL,
    task_type TEXT NOT NULL, -- Checkout Deep Clean, Daily Stayover Clean, Turndown Service, Room Inspection, Minibar Restock
    priority TEXT DEFAULT 'normal', -- urgent_rush, high, normal, low
    status TEXT DEFAULT 'pending', -- pending, in_progress, completed, inspected_approved
    assigned_staff_name TEXT,
    inspection_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- 18. Delivery Riders & Fleet Master
CREATE TABLE IF NOT EXISTS delivery_riders (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    name TEXT NOT NULL,
    phone TEXT NOT NULL UNIQUE,
    vehicle_no TEXT NOT NULL,
    rating NUMERIC(3, 2) DEFAULT 4.8,
    deliveries_completed INT DEFAULT 0,
    is_available BOOLEAN DEFAULT TRUE,
    photo_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 19. Customer Dining Profiles (Customer Mobile App)
CREATE TABLE IF NOT EXISTS customers (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    name TEXT NOT NULL,
    phone TEXT NOT NULL UNIQUE,
    email TEXT,
    addresses JSONB DEFAULT '[]'::jsonb,
    wallet_balance NUMERIC(10, 2) DEFAULT 0.0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 20. Customer Online Food Orders (Customer App & Aggregators)
CREATE TABLE IF NOT EXISTS customer_orders (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    branch_id TEXT REFERENCES branches(id) ON DELETE CASCADE,
    branch_name TEXT,
    customer_id TEXT,
    customer_name TEXT NOT NULL,
    customer_phone TEXT NOT NULL,
    delivery_address JSONB NOT NULL,
    items JSONB NOT NULL DEFAULT '[]'::jsonb,
    item_total NUMERIC(10, 2) NOT NULL,
    gst_amount NUMERIC(10, 2) DEFAULT 0.0,
    delivery_fee NUMERIC(10, 2) DEFAULT 0.0,
    packaging_charge NUMERIC(10, 2) DEFAULT 0.0,
    discount_amount NUMERIC(10, 2) DEFAULT 0.0,
    coupon_code TEXT,
    grand_total NUMERIC(10, 2) NOT NULL,
    payment_method TEXT DEFAULT 'cashOnDelivery',
    payment_status TEXT DEFAULT 'success',
    transaction_id TEXT,
    order_status TEXT DEFAULT 'placed', -- placed, confirmed, preparing, outForDelivery, delivered, cancelled
    rider_name TEXT,
    rider_phone TEXT,
    rider_vehicle_no TEXT,
    channel TEXT DEFAULT 'Direct Mobile App', -- Direct Mobile App, Zomato, Swiggy, ONDC, Magicpin, UrbanPiper
    aggregator_order_id TEXT,
    commission_amount NUMERIC(10, 2) DEFAULT 0.0,
    otp TEXT,
    special_instructions TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 21. Restaurant Aggregator Channels
CREATE TABLE IF NOT EXISTS aggregator_channels (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    name TEXT NOT NULL, -- Zomato, Swiggy, ONDC, Magicpin, UrbanPiper
    is_connected BOOLEAN DEFAULT TRUE,
    commission_percent NUMERIC(5, 2) DEFAULT 18.0,
    auto_accept BOOLEAN DEFAULT TRUE,
    default_prep_minutes INT DEFAULT 20,
    api_key TEXT,
    merchant_id TEXT,
    webhook_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 22. Inventory & Stock Items
CREATE TABLE IF NOT EXISTS stock_items (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    branch_id TEXT REFERENCES branches(id) ON DELETE CASCADE,
    item_code TEXT NOT NULL,
    name TEXT NOT NULL,
    category TEXT NOT NULL, -- Kitchen & Provisions, Housekeeping & Linen, Bar & Beverages
    unit TEXT NOT NULL, -- Kg, Ltr, Box, Can, Bottle, Set
    current_stock NUMERIC(10, 2) DEFAULT 0.0,
    reorder_level NUMERIC(10, 2) DEFAULT 10.0,
    unit_price NUMERIC(10, 2) NOT NULL,
    storage_location TEXT,
    last_restocked_at TIMESTAMPTZ DEFAULT NOW()
);

-- 23. Purchases Register (ERP Accounts)
CREATE TABLE IF NOT EXISTS purchases (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    branch_id TEXT REFERENCES branches(id) ON DELETE CASCADE,
    invoice_number TEXT NOT NULL,
    vendor_name TEXT NOT NULL,
    vendor_gstin TEXT,
    vendor_phone TEXT,
    purchase_date DATE DEFAULT CURRENT_DATE,
    department TEXT NOT NULL,
    payment_status TEXT DEFAULT 'Paid',
    payment_mode TEXT DEFAULT 'Bank Transfer / NEFT',
    notes TEXT,
    items JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 24. Expenses Register (ERP Accounts)
CREATE TABLE IF NOT EXISTS expenses (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    branch_id TEXT REFERENCES branches(id) ON DELETE CASCADE,
    voucher_no TEXT NOT NULL,
    date DATE DEFAULT CURRENT_DATE,
    category TEXT NOT NULL,
    paid_to TEXT NOT NULL,
    description TEXT NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    tax_amount NUMERIC(12, 2) DEFAULT 0.0,
    payment_mode TEXT DEFAULT 'Cash',
    reference_no TEXT,
    status TEXT DEFAULT 'Paid',
    recorded_by TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 25. Banquet & Conference Halls
CREATE TABLE IF NOT EXISTS banquet_halls (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    branch_id TEXT REFERENCES branches(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    capacity INT NOT NULL,
    base_rental NUMERIC(12, 2) NOT NULL,
    features TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================================
-- 2. ROW-LEVEL SECURITY (RLS) POLICIES
-- =====================================================================
DO $$
DECLARE
    tbl TEXT;
    tables TEXT[] := ARRAY[
        'organizations', 'branches', 'hotel_business_config', 'staff_members',
        'app_users', 'floors', 'room_types', 'rooms', 'guests', 'reservations',
        'folios', 'folio_transactions', 'pos_outlets', 'pos_menu_items',
        'pos_orders', 'pos_bills', 'housekeeping_tasks', 'delivery_riders',
        'customers', 'customer_orders', 'aggregator_channels', 'stock_items',
        'purchases', 'expenses', 'banquet_halls'
    ];
BEGIN
    FOREACH tbl IN ARRAY tables LOOP
        EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY;', tbl);
        EXECUTE format('DROP POLICY IF EXISTS "Public access policy" ON %I;', tbl);
        EXECUTE format('CREATE POLICY "Public access policy" ON %I FOR ALL USING (true) WITH CHECK (true);', tbl);
    END LOOP;
END $$;

-- =====================================================================
-- 3. SUPABASE REALTIME SUBSCRIPTIONS
-- =====================================================================
DO $$
BEGIN
    -- Recreate realtime publication for primary live synchronization tables
    ALTER PUBLICATION supabase_realtime ADD TABLE rooms;
    ALTER PUBLICATION supabase_realtime ADD TABLE pos_orders;
    ALTER PUBLICATION supabase_realtime ADD TABLE pos_bills;
    ALTER PUBLICATION supabase_realtime ADD TABLE housekeeping_tasks;
    ALTER PUBLICATION supabase_realtime ADD TABLE reservations;
    ALTER PUBLICATION supabase_realtime ADD TABLE customer_orders;
EXCEPTION
    WHEN OTHERS THEN
        NULL; -- Ignore if already added
END $$;

-- =====================================================================
-- 4. COMPREHENSIVE SEED DATA
-- =====================================================================

-- 1. Organizations
INSERT INTO organizations (id, name, slug, chain_tier, logo_url) VALUES
('org-taj-imperial', 'The Grand Imperial Hospitality Group', 'grand-imperial', '5_star_luxury', 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=200')
ON CONFLICT (id) DO NOTHING;

-- 2. Branches
INSERT INTO branches (id, organization_id, name, code, star_rating, address, city, state, country, phone, email, currency, tax_identifier, check_in_time, check_out_time, total_rooms) VALUES
('branch-mum-01', 'org-taj-imperial', 'The Grand Imperial Palace', 'GIP-MUM', 5, 'Nariman Point, Marine Drive', 'Mumbai', 'Maharashtra', 'India', '+91 22 6789 0001', 'concierge.mum@grandimperial.com', 'INR', '27AABCU9603R1ZM', '14:00', '12:00', 42),
('branch-goa-02', 'org-taj-imperial', 'Azure Bay Beach Resort & Spa', 'ABR-GOA', 5, 'Sinquerim Beach Road', 'Candolim', 'Goa', 'India', '+91 832 249 5555', 'reservations.goa@azurebay.com', 'INR', '30AABCU9603R1ZX', '15:00', '11:00', 28),
('branch-pun-03', 'org-taj-imperial', 'The Monarch Elite Business Hotel', 'MEH-PUN', 3, 'Cyber City Expressway, Kalyani Nagar', 'Pune', 'Maharashtra', 'India', '+91 20 4012 3344', 'frontdesk.pun@monarchhotel.com', 'INR', '27AABCU9603R1ZP', '12:00', '11:00', 24)
ON CONFLICT (id) DO NOTHING;

-- 3. Business Config
INSERT INTO hotel_business_config (id, business_name, tagline, address, city, state, phone, email, gstin, currency, license_key, contact_person, enable_rooms, enable_pos, enable_housekeeping, enable_crs, enable_banquet, enable_customer_app, room_gst, food_gst) VALUES
('config-primary', 'The Grand Imperial Palace', 'Luxury Hospitality & Royal Dining Experience', 'Nariman Point, Marine Drive', 'Mumbai', 'Maharashtra', '+91 22 6789 0001', 'concierge.mum@grandimperial.com', '27AABCU9603R1ZM', 'INR', 'HP-ENT-2026-9901-PRO', 'General Manager Rajesh Mehta', TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, 12.0, 5.0)
ON CONFLICT (id) DO NOTHING;

-- 4. Staff Members
INSERT INTO staff_members (id, branch_id, full_name, phone, department, role, shift, salary, is_active) VALUES
('staff-001', 'branch-mum-01', 'Ramesh Patil', '+91 98201 11001', 'frontDesk', 'frontDeskAgent', 'morning', 32000.0, TRUE),
('staff-002', 'branch-mum-01', 'Sunita Sharma', '+91 98201 11002', 'housekeeping', 'hkSupervisor', 'morning', 28000.0, TRUE),
('staff-003', 'branch-mum-01', 'Ravi Kumar', '+91 98201 11003', 'housekeeping', 'hkStaff', 'morning', 22000.0, TRUE),
('staff-004', 'branch-mum-01', 'Amit Desai', '+91 98201 11004', 'fnb', 'captain', 'evening', 35000.0, TRUE),
('staff-005', 'branch-mum-01', 'Priya Singh', '+91 98201 11005', 'fnb', 'waiter', 'evening', 24000.0, TRUE),
('staff-006', 'branch-mum-01', 'Chef Sanjeev Kapoor', '+91 98201 11006', 'kitchen', 'chef', 'general', 65000.0, TRUE),
('staff-007', 'branch-mum-01', 'Deepak Nair', '+91 98201 11007', 'management', 'manager', 'general', 75000.0, TRUE),
('staff-008', 'branch-goa-02', 'Maria Fernandes', '+91 98201 11008', 'frontDesk', 'frontDeskAgent', 'general', 30000.0, TRUE)
ON CONFLICT (id) DO NOTHING;

-- 5. App Users
INSERT INTO app_users (id, staff_id, username, password_hash, display_name, role, branch_access, is_active) VALUES
('usr-dev', NULL, 'isecure', 'isecure@123', 'iSecure Systems Developer', 'developer', '["branch-mum-01", "branch-goa-02", "branch-pun-03"]'::jsonb, TRUE),
('usr-001', NULL, 'admin', 'admin@123', 'Super Administrator', 'superAdmin', '["branch-mum-01", "branch-goa-02", "branch-pun-03"]'::jsonb, TRUE),
('usr-002', 'staff-007', 'gm.mumbai', 'gm@123', 'Rajesh Mehta (GM Mumbai)', 'generalManager', '["branch-mum-01"]'::jsonb, TRUE),
('usr-003', 'staff-001', 'rpatil.fd', 'hotel@123', 'Ramesh Patil (Front Desk)', 'frontDeskSupervisor', '["branch-mum-01"]'::jsonb, TRUE),
('usr-004', 'staff-002', 'ssharma.hk', 'hotel@123', 'Sunita Sharma (Housekeeping)', 'hkSupervisor', '["branch-mum-01"]'::jsonb, TRUE),
('usr-005', 'staff-004', 'adesai.fb', 'hotel@123', 'Amit Desai (Captain POS)', 'fbCaptain', '["branch-mum-01"]'::jsonb, TRUE),
('usr-006', 'staff-008', 'mfernandes.fd', 'hotel@123', 'Maria Fernandes (Goa FD)', 'frontDeskAgent', '["branch-goa-02"]'::jsonb, TRUE)
ON CONFLICT (id) DO NOTHING;

-- 6. Floors
INSERT INTO floors (id, branch_id, floor_number, label) VALUES
('fl-mum-g', 'branch-mum-01', 0, 'Ground Floor (Lobby & Banquets)'),
('fl-mum-1', 'branch-mum-01', 1, 'Floor 1 - Grand Deluxe Ocean'),
('fl-mum-2', 'branch-mum-01', 2, 'Floor 2 - Imperial Club Suites'),
('fl-mum-3', 'branch-mum-01', 3, 'Floor 3 - Maharaja Penthouse')
ON CONFLICT (id) DO NOTHING;

-- 7. Room Types
INSERT INTO room_types (id, branch_id, name, code, description, base_price, max_adults, max_children, bed_type) VALUES
('rt-mum-dlx', 'branch-mum-01', 'Grand Deluxe Ocean View', 'DLX-OCN', 'Panoramic view of Arabian Sea with Italian marble bathroom and Nespresso machine.', 14500.0, 2, 1, 'King Size Feather Bed'),
('rt-mum-clb', 'branch-mum-01', 'Imperial Club Suite', 'CLB-STE', 'Exclusive club lounge access with complimentary high tea and 24/7 dedicated butler service.', 28000.0, 3, 1, 'California King Bed'),
('rt-mum-prs', 'branch-mum-01', 'Maharaja Presidential Penthouse', 'PRS-PNT', 'Top-floor royal suite with private infinity plunge pool, private elevator and personal chef.', 85000.0, 4, 2, 'Royal Suite Double King'),
('rt-goa-ctg', 'branch-goa-02', 'Beachfront Heritage Cottage', 'BCH-CTG', 'Direct white sand beach access with outdoor rain shower and hammock patio.', 18500.0, 2, 1, 'Teakwood Canopy King'),
('rt-pun-std', 'branch-pun-03', 'Smart Business Room', 'BIZ-STD', 'Ergonomic workstation with high-speed fiber internet and express laundry service.', 4200.0, 2, 0, 'Queen Comfort Bed')
ON CONFLICT (id) DO NOTHING;

-- 8. Rooms
INSERT INTO rooms (id, branch_id, room_type_id, room_number, floor_number, status, room_type_name, base_price, current_guest_name, current_reservation_id, current_guest_vip, keycard_rfid, notes) VALUES
('rm-101', 'branch-mum-01', 'rt-mum-dlx', '101', 1, 'occupied', 'Grand Deluxe Ocean View', 14500.0, 'Mr. Vikram Singhania', 'RES-MUM-1001', 'royal_club', 'RFID-9901-A', 'VIP Guest. Bottle of Moët Chandon sent to room.'),
('rm-102', 'branch-mum-01', 'rt-mum-dlx', '102', 1, 'clean_inspected', 'Grand Deluxe Ocean View', 14500.0, NULL, NULL, NULL, 'RFID-9902-B', 'Fresh flowers and fruit basket placed.'),
('rm-103', 'branch-mum-01', 'rt-mum-dlx', '103', 1, 'dirty_vacant', 'Grand Deluxe Ocean View', 14500.0, NULL, NULL, NULL, NULL, 'Guest checked out at 11:30 AM. Deep cleaning required.'),
('rm-104', 'branch-mum-01', 'rt-mum-dlx', '104', 1, 'cleaning_in_progress', 'Grand Deluxe Ocean View', 14500.0, NULL, NULL, NULL, NULL, 'Housekeeper Ravi cleaning linens and minibar.'),
('rm-105', 'branch-mum-01', 'rt-mum-dlx', '105', 1, 'available_clean', 'Grand Deluxe Ocean View', 14500.0, NULL, NULL, NULL, 'RFID-9905-A', NULL),
('rm-106', 'branch-mum-01', 'rt-mum-dlx', '106', 1, 'reserved', 'Grand Deluxe Ocean View', 14500.0, 'Dr. Priya Nair', 'RES-MUM-1005', 'silver', NULL, 'Due in at 4:00 PM.'),
('rm-201', 'branch-mum-01', 'rt-mum-clb', '201', 2, 'occupied', 'Imperial Club Suite', 28000.0, 'Lady Catherine Spencer', 'RES-MUM-1002', 'platinum', 'RFID-9921-A', 'Diplomatic guest. Strict privacy requested.'),
('rm-202', 'branch-mum-01', 'rt-mum-clb', '202', 2, 'clean_inspected', 'Imperial Club Suite', 28000.0, NULL, NULL, NULL, 'RFID-9922-A', NULL),
('rm-203', 'branch-mum-01', 'rt-mum-clb', '203', 2, 'occupied', 'Imperial Club Suite', 28000.0, 'Mr. Rajesh Agarwal', 'RES-MUM-1003', 'gold', 'RFID-9923-A', 'Anniversary celebration.'),
('rm-204', 'branch-mum-01', 'rt-mum-clb', '204', 2, 'out_of_order', 'Imperial Club Suite', 28000.0, NULL, NULL, NULL, NULL, 'AC compressor replacement in progress by engineering.'),
('rm-301', 'branch-mum-01', 'rt-mum-prs', 'PH-01', 3, 'occupied', 'Maharaja Presidential Penthouse', 85000.0, 'His Highness Sheikh Al-Mansoor', 'RES-MUM-1004', 'royal_club', 'RFID-ROYAL-01', 'Private security team on floor. All-inclusive luxury butler folio.')
ON CONFLICT (id) DO NOTHING;

-- 9. Guests
INSERT INTO guests (id, organization_id, first_name, last_name, email, phone, vip_tier, id_type, id_number, dietary_preferences, special_requests, total_stays) VALUES
('gst-01', 'org-taj-imperial', 'Vikram', 'Singhania', 'vikram.s@singhaniagroup.com', '+91 98200 11223', 'royal_club', 'Passport', 'Z8941029', 'Jain Vegetarian / Organic Herbal Teas', 'Temperature 20°C, Sea-facing, Extra silk pillows', 24),
('gst-02', 'org-taj-imperial', 'Catherine', 'Spencer', 'catherine.spencer@ukfco.gov.uk', '+44 7700 900123', 'platinum', 'Diplomatic Passport', 'GB-DIP-09182', 'Gluten-Free, Sparkling Water only', 'Quiet room, Daily The Times UK newspaper', 8),
('gst-03', 'org-taj-imperial', 'Rajesh', 'Agarwal', 'rajesh.agarwal@agarwalfin.in', '+91 99112 33445', 'gold', 'Aadhaar Card', 'XXXX-XXXX-9841', 'North Indian Vegetarian', 'Anniversary cake and red roses at 8 PM', 5),
('gst-04', 'org-taj-imperial', 'Sheikh', 'Al-Mansoor', 'office@almansoorroyal.ae', '+971 50 123 4567', 'royal_club', 'Royal Passport', 'UAE-R-778899', 'Halal Royal Arabic & Gourmet Continental', '24/7 Dedicated Arabic-speaking Butler', 12)
ON CONFLICT (id) DO NOTHING;

-- 10. Reservations
INSERT INTO reservations (id, booking_reference, branch_id, guest_id, room_id, room_type_id, guest_name, guest_phone, room_number, check_in_date, check_out_date, booking_status, booking_source, rate_per_night, advance_paid) VALUES
('RES-MUM-1001', 'RES-2026-9021', 'branch-mum-01', 'gst-01', 'rm-101', 'rt-mum-dlx', 'Mr. Vikram Singhania', '+91 98200 11223', '101', CURRENT_DATE - INTERVAL '1 day', CURRENT_DATE + INTERVAL '2 days', 'checked_in', 'direct_walk_in', 14500.0, 20000.0),
('RES-MUM-1002', 'RES-2026-9022', 'branch-mum-01', 'gst-02', 'rm-201', 'rt-mum-clb', 'Lady Catherine Spencer', '+44 7700 900123', '201', CURRENT_DATE - INTERVAL '2 days', CURRENT_DATE + INTERVAL '3 days', 'checked_in', 'corporate', 28000.0, 50000.0),
('RES-MUM-1003', 'RES-2026-9023', 'branch-mum-01', 'gst-03', 'rm-203', 'rt-mum-clb', 'Mr. Rajesh Agarwal', '+91 99112 33445', '203', CURRENT_DATE, CURRENT_DATE + INTERVAL '2 days', 'checked_in', 'website', 28000.0, 28000.0),
('RES-MUM-1004', 'RES-2026-9024', 'branch-mum-01', 'gst-04', 'rm-301', 'rt-mum-prs', 'His Highness Sheikh Al-Mansoor', '+971 50 123 4567', 'PH-01', CURRENT_DATE - INTERVAL '1 day', CURRENT_DATE + INTERVAL '6 days', 'checked_in', 'direct_walk_in', 85000.0, 200000.0)
ON CONFLICT (id) DO NOTHING;

-- 11. Folios
INSERT INTO folios (id, reservation_id, folio_number, room_number, guest_name, status, total_charges, total_paid, balance_due) VALUES
('fol-1001', 'RES-MUM-1001', 'FOL-MUM-4011', '101', 'Mr. Vikram Singhania', 'open', 17825.0, 20000.0, 0.0),
('fol-1002', 'RES-MUM-1002', 'FOL-MUM-4012', '201', 'Lady Catherine Spencer', 'open', 40980.0, 50000.0, 0.0)
ON CONFLICT (id) DO NOTHING;

-- 12. Folio Transactions
INSERT INTO folio_transactions (id, folio_id, category, description, amount, tax_amount, is_credit, payment_method) VALUES
('ft-1', 'fol-1001', 'room_charge', 'Grand Deluxe Ocean View (Night 1)', 14500.0, 1740.0, FALSE, NULL),
('ft-2', 'fol-1001', 'restaurant', 'The Royal Bistro - Dinner & Saffron Biryani', 1500.0, 75.0, FALSE, NULL),
('ft-3', 'fol-1001', 'payment', 'Advance Deposit via HDFC Credit Card', 20000.0, 0.0, TRUE, 'credit_card')
ON CONFLICT (id) DO NOTHING;

-- 13. POS Outlets
INSERT INTO pos_outlets (id, branch_id, name, type, is_active) VALUES
('outlet-mum-01', 'branch-mum-01', 'The Royal Bistro', 'fine_dining', TRUE),
('outlet-mum-02', 'branch-mum-01', 'Skyline 360 Rooftop Bar', 'bar', TRUE),
('outlet-mum-03', 'branch-mum-01', '24/7 In-Room Dining', 'room_service', TRUE)
ON CONFLICT (id) DO NOTHING;

-- 14. Menu Items
INSERT INTO pos_menu_items (id, outlet_id, name, category, price, is_veg, emoji, description, image_url, tax_rate) VALUES
('menu-biryani-1', 'outlet-mum-01', 'Dum Murgh Hyderabadi Biryani', 'Royal Biryani', 480.0, FALSE, '🍗', 'Slow-cooked chicken pieces marinated in Nizami spices layered with aged basmati rice & saffron.', 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=500', 5.0),
('menu-biryani-2', 'outlet-mum-01', 'Royal Mutton Awadhi Dum Biryani', 'Royal Biryani', 650.0, FALSE, '🥩', 'Tender lamb shanks cooked on charcoal dum with royal ittar and fragrant basmati rice.', 'https://images.unsplash.com/photo-1633945274405-b6c8069047b0?w=500', 5.0),
('menu-biryani-3', 'outlet-mum-01', 'Shahi Paneer Tikka Dum Biryani', 'Royal Biryani', 420.0, TRUE, '🧀', 'Char-grilled malai paneer infused in tandoori marinade, baked in clay pot with dry fruits.', 'https://images.unsplash.com/photo-1645177628172-a94c1f96e6db?w=500', 5.0),
('menu-biryani-4', 'outlet-mum-01', 'Subz-E-Nawabi Tarkari Biryani', 'Royal Biryani', 380.0, TRUE, '🥗', 'Assorted farm-fresh vegetables and mushrooms simmered with mint and browned onions.', 'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=500', 5.0),
('menu-starter-1', 'outlet-mum-01', 'Tandoori Paneer Tikka Angara', 'Starters', 360.0, TRUE, '🔥', 'Cottage cheese steaks marinated in Kashmiri red chili, roasted crisp in charcoal tandoor.', 'https://images.unsplash.com/photo-1599488615731-7e5c2823ff28?w=500', 5.0),
('menu-starter-2', 'outlet-mum-01', 'Murgh Malai Tikka Supreme', 'Starters', 460.0, FALSE, '🍢', 'Succulent boneless chicken tenders steeped in thick dairy cream, cashew paste and cardamom.', 'https://images.unsplash.com/photo-1599488615731-7e5c2823ff28?w=500', 5.0),
('menu-starter-3', 'outlet-mum-01', 'Crispy Corn Salt & Pepper', 'Starters', 320.0, TRUE, '🌽', 'Golden sweet corn wok-tossed with spring onions, bell peppers and cracked peppercorns.', 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500', 5.0),
('menu-main-1', 'outlet-mum-01', 'Delhi 6 Style Butter Chicken', 'Main Course', 520.0, FALSE, '🍗', 'Clay oven roasted tandoori chicken shredded into velvety, sweet-tangy makhani gravy.', 'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=500', 5.0),
('menu-main-2', 'outlet-mum-01', 'Dal Makhani Bukhara Style', 'Main Course', 380.0, TRUE, '🥘', 'Black lentils slow cooked overnight on charcoal embers with churned butter and cream.', 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=500', 5.0),
('menu-bread-1', 'outlet-mum-01', 'Garlic Butter Naan', 'Tandoor & Breads', 90.0, TRUE, '🫓', 'Refined flour leavened flatbread studded with fresh minced garlic and pure butter.', 'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=500', 5.0),
('menu-dessert-1', 'outlet-mum-01', 'Shahi Kesari Rasmalai (2 Pcs)', 'Desserts', 220.0, TRUE, '🍮', 'Soft cottage cheese patties immersed in saffron and pistachio infused thickened rabri.', 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=500', 5.0)
ON CONFLICT (id) DO NOTHING;

-- 15. POS Orders (Live Table KOTs)
INSERT INTO pos_orders (id, outlet_id, order_number, table_number, waiter_name, guest_name, status, subtotal, tax, total, items) VALUES
('pos-ord-101', 'outlet-mum-01', 'KOT-1048', 'Table 4', 'Priya Singh', 'Amitabh Bachchan', 'served', 1260.0, 63.0, 1323.0,
'[{"menuItemId":"menu-biryani-1","name":"Dum Murgh Hyderabadi Biryani","price":480.0,"quantity":2},{"menuItemId":"menu-starter-3","name":"Crispy Corn Salt & Pepper","price":320.0,"quantity":1}]'::jsonb),
('pos-ord-102', 'outlet-mum-01', 'KOT-1049', 'Table 7', 'Amit Desai', 'Sunil Gavaskar', 'in_kitchen', 980.0, 49.0, 1029.0,
'[{"menuItemId":"menu-main-1","name":"Delhi 6 Style Butter Chicken","price":520.0,"quantity":1},{"menuItemId":"menu-main-2","name":"Dal Makhani Bukhara Style","price":380.0,"quantity":1},{"menuItemId":"menu-bread-1","name":"Garlic Butter Naan","price":90.0,"quantity":2}]'::jsonb)
ON CONFLICT (id) DO NOTHING;

-- 16. POS Bills (Settled History)
INSERT INTO pos_bills (id, bill_number, billing_type, branch_id, outlet_id, outlet_name, table_number, waiter_name, subtotal, tax_amount, total_amount, payment_method, payment_status, items) VALUES
('pos-bill-001', 'BILL-TAB-1042', 'tableDining', 'branch-mum-01', 'outlet-mum-01', 'The Royal Bistro', 'Table 4', 'Priya Singh', 2800.0, 140.0, 2940.0, 'UPI / QR Code', 'paid',
'[{"name":"Dum Murgh Hyderabadi Biryani","quantity":2,"price":480.0},{"name":"Tandoori Paneer Tikka Angara","quantity":2,"price":360.0}]'::jsonb)
ON CONFLICT (id) DO NOTHING;

-- 17. Housekeeping Tasks
INSERT INTO housekeeping_tasks (id, branch_id, room_id, room_number, floor_number, task_type, priority, status, assigned_staff_name, inspection_notes) VALUES
('hk-1', 'branch-mum-01', 'rm-103', '103', 1, 'Checkout Deep Clean', 'urgent_rush', 'pending', 'Ravi Kumar', 'Guest checked out. Change all linens and sanitize bathroom.'),
('hk-2', 'branch-mum-01', 'rm-104', '104', 1, 'Daily Stayover Clean', 'normal', 'in_progress', 'Sunita Sharma', 'Cleaning in progress.'),
('hk-3', 'branch-mum-01', 'rm-102', '102', 1, 'Room Inspection', 'high', 'inspected_approved', 'Sunita Sharma', 'Room clean and inspected. Ready for arrival.')
ON CONFLICT (id) DO NOTHING;

-- 18. Delivery Riders
INSERT INTO delivery_riders (id, name, phone, vehicle_no, rating, deliveries_completed, is_available, photo_url) VALUES
('rider-01', 'Ramesh Patel', '+91 98201 54321', 'MH 02 CZ 4421 [Honda Activa 6G]', 4.9, 1420, TRUE, 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150'),
('rider-02', 'Vikram Jadhav', '+91 98200 11223', 'MH 02 DQ 8821 [Bajaj Pulsar 150]', 4.8, 980, TRUE, 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150'),
('rider-03', 'Amit Gaikwad', '+91 98199 44332', 'MH 04 AX 5512 [TVS Jupiter]', 4.9, 1150, TRUE, 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=150'),
('rider-04', 'Sunil Sawant', '+91 98333 77881', 'MH 02 EM 9930 [Hero Splendor+]', 4.7, 640, TRUE, 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150')
ON CONFLICT (id) DO NOTHING;

-- 19. Customers
INSERT INTO customers (id, name, phone, email, wallet_balance, addresses) VALUES
('cust-8821', 'Amit Sharma', '+91 98765 43210', 'amit.sharma@example.com', 250.0,
'[{"id":"addr-1","label":"Home","fullAddress":"Flat 604, Orchid Heights, Chakala, Andheri East, Mumbai","landmark":"Near Chakala Metro","pincode":"400069","distanceKmFromHotel":2.8}]'::jsonb),
('cust-9205', 'Priya Verma', '+91 98192 33441', 'priya.verma@example.com', 100.0,
'[{"id":"addr-pv-1","label":"Home","fullAddress":"Flat 402, Neelkanth Heights, Andheri West, Mumbai","landmark":"Opposite Citi Mall","pincode":"400053","distanceKmFromHotel":2.8}]'::jsonb)
ON CONFLICT (id) DO NOTHING;

-- 20. Customer Online Orders
INSERT INTO customer_orders (id, branch_id, branch_name, customer_id, customer_name, customer_phone, delivery_address, item_total, gst_amount, delivery_fee, packaging_charge, discount_amount, coupon_code, grand_total, payment_method, payment_status, transaction_id, order_status, rider_name, rider_phone, rider_vehicle_no, channel, items) VALUES
('ORD-HP-8421', 'branch-mum-01', 'The Grand Imperial Palace', 'cust-8821', 'Amit Sharma', '+91 98765 43210',
'{"fullAddress":"Flat 604, Orchid Heights, Chakala, Andheri East, Mumbai","label":"Home"}'::jsonb,
1810.0, 90.5, 0.0, 25.0, 181.0, 'HOTELPRO10', 1744.5, 'upiGpay', 'success', 'UPI-TXN-99882201', 'delivered', 'Vikram Jadhav', '+91 98200 11223', 'MH 02 DQ 8821', 'Direct Mobile App',
'[{"name":"Hyderabadi Dum Biryani","price":680.0,"quantity":2},{"name":"Paneer Tikka Angara","price":450.0,"quantity":1}]'::jsonb),
('ORD-HP-9205', 'branch-mum-01', 'The Grand Imperial Palace', 'cust-9205', 'Priya Verma', '+91 98192 33441',
'{"fullAddress":"Flat 402, Neelkanth Heights, Andheri West, Mumbai","label":"Home"}'::jsonb,
1340.0, 67.0, 30.0, 25.0, 0.0, NULL, 1462.0, 'cashOnDelivery', 'pending', 'TXN-COD-9205', 'placed', NULL, NULL, NULL, 'Direct Mobile App',
'[{"name":"Royal Murgh Dum Biryani","price":580.0,"quantity":2},{"name":"Butter Naan Basket","price":180.0,"quantity":1}]'::jsonb),
('ZOM-883192', 'branch-mum-01', 'The Grand Imperial Palace', 'cust-zomato', 'Kunal Shah', '+91 98000 11223',
'{"fullAddress":"Bandra Kurla Complex, BKC Tower 2, Mumbai"}'::jsonb,
1180.0, 59.0, 40.0, 20.0, 100.0, 'ZOMATO50', 1199.0, 'creditDebitCard', 'success', 'TXN-ZOM-8831', 'preparing', 'Zomato Rider (Mukesh)', '+91 98333 44556', 'MH 03 BY 2210', 'Zomato',
'[{"name":"Delhi 6 Style Butter Chicken","price":520.0,"quantity":1},{"name":"Dum Murgh Hyderabadi Biryani","price":480.0,"quantity":1},{"name":"Garlic Butter Naan","price":90.0,"quantity":2}]'::jsonb)
ON CONFLICT (id) DO NOTHING;

-- 21. Aggregator Channels
INSERT INTO aggregator_channels (id, name, is_connected, commission_percent, auto_accept, default_prep_minutes, webhook_url) VALUES
('agg-zomato', 'Zomato', TRUE, 18.0, TRUE, 20, 'http://127.0.0.1:8088/api/aggregator/webhook'),
('agg-swiggy', 'Swiggy', TRUE, 20.0, TRUE, 25, 'http://127.0.0.1:8088/api/webhook/swiggy'),
('agg-ondc', 'ONDC Network', TRUE, 8.0, TRUE, 20, 'http://127.0.0.1:8088/api/webhook/ondc'),
('agg-magicpin', 'Magicpin', TRUE, 12.0, TRUE, 15, 'http://127.0.0.1:8088/api/webhook/magicpin'),
('agg-urbanpiper', 'UrbanPiper Middleware', TRUE, 15.0, TRUE, 20, 'http://127.0.0.1:8088/api/webhook/urbanpiper')
ON CONFLICT (id) DO NOTHING;

-- 22. Stock Items
INSERT INTO stock_items (id, branch_id, item_code, name, category, unit, current_stock, reorder_level, unit_price, storage_location) VALUES
('stk-mum-01', 'branch-mum-01', 'STK-DA-101', 'Fresh Farm Milk (A2 Cow)', 'Kitchen & Provisions', 'Ltr', 180.0, 50.0, 65.0, 'Main Cold Room'),
('stk-mum-02', 'branch-mum-01', 'STK-DA-102', 'Amul Salted Table Butter (500g)', 'Kitchen & Provisions', 'Box', 45.0, 20.0, 280.0, 'Dairy Refrigerator'),
('stk-mum-03', 'branch-mum-01', 'STK-GR-201', 'Organic Aged Basmati Rice (Daawat)', 'Kitchen & Provisions', 'Kg', 120.0, 40.0, 140.0, 'Dry Grocery Store'),
('stk-mum-04', 'branch-mum-01', 'STK-DA-103', 'Fresh Malai Paneer (Cottage Cheese)', 'Kitchen & Provisions', 'Kg', 35.0, 15.0, 380.0, 'Main Cold Room'),
('stk-mum-05', 'branch-mum-01', 'STK-LN-301', '400 TC Egyptian White King Bedsheet Set', 'Housekeeping & Linen', 'Set', 40.0, 15.0, 1650.0, 'Linen Room Floor 1'),
('stk-mum-06', 'branch-mum-01', 'STK-LN-302', 'Luxury 600 GSM Cotton Bath Towels', 'Housekeeping & Linen', 'Piece', 80.0, 30.0, 450.0, 'Linen Room Floor 1'),
('stk-mum-07', 'branch-mum-01', 'STK-BV-401', 'Glenfiddich 12 Year Single Malt Whisky', 'Bar & Beverages', 'Bottle', 12.0, 5.0, 4200.0, 'Main Bar Vault')
ON CONFLICT (id) DO NOTHING;

-- 23. Purchases Register
INSERT INTO purchases (id, branch_id, invoice_number, vendor_name, vendor_gstin, vendor_phone, purchase_date, department, payment_status, payment_mode, notes, items) VALUES
('PUR-MUM-1001', 'branch-mum-01', 'INV-AP-8921', 'Apex Food & Dairy Suppliers Ltd.', '27AABCA1234F1Z5', '+91 98201 55432', CURRENT_DATE - INTERVAL '3 days', 'Kitchen & Provisions', 'Paid', 'Bank Transfer / NEFT', 'Monthly bulk dairy and provisions delivery.',
'[{"name":"Fresh Farm Milk (A2 Cow)","quantity":200,"unit":"Ltr","unitPrice":65.0,"taxPercent":5.0},{"name":"Amul Salted Butter","quantity":60,"unit":"Box","unitPrice":280.0,"taxPercent":12.0}]'::jsonb),
('PUR-MUM-1002', 'branch-mum-01', 'INV-LS-4029', 'LinenCraft Hospitality Textiles', '27AAACL9922M1ZW', '+91 98205 77112', CURRENT_DATE - INTERVAL '6 days', 'Housekeeping & Linen', 'Paid', 'Bank Transfer / NEFT', 'Egyptian cotton bedsheets replacement.',
'[{"name":"400 TC White King Bedsheet Set","quantity":30,"unit":"Set","unitPrice":1650.0,"taxPercent":12.0}]'::jsonb)
ON CONFLICT (id) DO NOTHING;

-- 24. Expenses Register
INSERT INTO expenses (id, branch_id, voucher_no, date, category, paid_to, description, amount, tax_amount, payment_mode, status, recorded_by) VALUES
('EXP-MUM-5001', 'branch-mum-01', 'VCH-MUM-084', CURRENT_DATE - INTERVAL '1 day', 'Fuel & Generator (DG Set)', 'Indian Oil Corporation Petrol Pump', '500 Liters high-speed diesel for hotel standby backup generators.', 46500.0, 0.0, 'Company Debit Card', 'Paid', 'Chief Engineer Sharma'),
('EXP-MUM-5002', 'branch-mum-01', 'VCH-MUM-085', CURRENT_DATE - INTERVAL '2 days', 'Software & Internet', 'Tata Teleservices Ltd.', 'High-speed leased line internet for guest WiFi and ERP.', 18500.0, 3330.0, 'Bank Transfer / NEFT', 'Paid', 'IT Administrator')
ON CONFLICT (id) DO NOTHING;

-- 25. Banquet Halls
INSERT INTO banquet_halls (id, branch_id, name, capacity, base_rental, features) VALUES
('hall-mum-01', 'branch-mum-01', 'Kohinoor Grand Banquet Hall', 500, 65000.0, 'Central AC • Stage & Audio Visuals • Chandeliers • Dedicated Buffet Area'),
('hall-mum-02', 'branch-mum-01', 'Regal Ballroom & Conference Suite', 250, 42000.0, 'Modular Partition • Projector & Surround Sound • Podium & Pre-Function Lobby'),
('hall-mum-03', 'branch-mum-01', 'Crystal Executive Boardroom', 50, 18000.0, 'Video Conference Display • High-Speed Leased Line • Executive Leather Chairs'),
('hall-mum-04', 'branch-mum-01', 'Skyline Rooftop Lawn & Poolside', 350, 55000.0, 'Open Air Ocean View • Live BBQ Counters • Mood Lighting • DJ Console Space')
ON CONFLICT (id) DO NOTHING;

-- =====================================================================
-- SUCCESS NOTIFICATION
-- =====================================================================
SELECT 'HotelPro Enterprise Database Schema and Seed Data Successfully Applied!' AS status;
