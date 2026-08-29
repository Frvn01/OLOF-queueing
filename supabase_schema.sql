-- ==============================================================================
-- OUR LADY OF FATIMA EYE EAR NOSE THROAT CENTER (OLOF) QUEUEING SYSTEM
-- SUPABASE DATABASE SCHEMA & REALTIME SETUP
-- ==============================================================================

-- 1. PATIENTS TABLE
CREATE TABLE IF NOT EXISTS public.patients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_no VARCHAR(64) UNIQUE NOT NULL,
    first_name VARCHAR(128) NOT NULL,
    last_name VARCHAR(128) NOT NULL,
    middle_name VARCHAR(128),
    birthday TIMESTAMPTZ NOT NULL,
    sex VARCHAR(16) NOT NULL,
    civil_status VARCHAR(32) NOT NULL,
    address TEXT NOT NULL,
    contact_number VARCHAR(64) NOT NULL,
    occupation VARCHAR(128),
    referred_by VARCHAR(128),
    photo_url TEXT,
    chief_complaint TEXT,
    history_of_present_illness TEXT,
    past_medical_history TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. QUEUE ENTRIES TABLE
CREATE TABLE IF NOT EXISTS public.queue_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    patient_name VARCHAR(256) NOT NULL,
    patient_photo TEXT,
    department VARCHAR(16) NOT NULL, -- 'ENT' or 'EYES'
    queue_number VARCHAR(32) NOT NULL, -- 'ENT-001', 'EYE-001'
    purpose VARCHAR(128) NOT NULL,
    status VARCHAR(32) DEFAULT 'waiting', -- 'waiting', 'serving', 'completed', 'skipped', 'on_hold'
    assigned_room VARCHAR(64),
    date_key VARCHAR(16) NOT NULL, -- 'YYYY-MM-DD' for daily reset
    created_at TIMESTAMPTZ DEFAULT NOW(),
    called_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ
);

-- 3. VISIT RECORDS (Patient History)
CREATE TABLE IF NOT EXISTS public.visit_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    department VARCHAR(16) NOT NULL,
    purpose VARCHAR(128) NOT NULL,
    chief_complaint TEXT,
    diagnosis TEXT,
    notes TEXT,
    assigned_room VARCHAR(64),
    queue_number VARCHAR(32) NOT NULL,
    visit_date TIMESTAMPTZ DEFAULT NOW()
);

-- 4. INDEXES FOR HIGH PERFORMANCE QUERYING
CREATE INDEX IF NOT EXISTS idx_patients_no ON public.patients(patient_no);
CREATE INDEX IF NOT EXISTS idx_patients_name ON public.patients(last_name, first_name);
CREATE INDEX IF NOT EXISTS idx_queue_date_dept ON public.queue_entries(date_key, department, status);
CREATE INDEX IF NOT EXISTS idx_visit_patient ON public.visit_records(patient_id);

-- 5. ENABLE ROW LEVEL SECURITY (RLS) & ALLOW ANONYMOUS ACCESS FOR KIOSK
ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.queue_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.visit_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read/write on patients" 
    ON public.patients FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Allow public read/write on queue_entries" 
    ON public.queue_entries FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Allow public read/write on visit_records" 
    ON public.visit_records FOR ALL USING (true) WITH CHECK (true);

-- 6. ENABLE REALTIME PUBLICATION FOR LIVE QUEUE SYNC
BEGIN;
  -- Drop publication if existing or add tables
  DROP PUBLICATION IF EXISTS supabase_realtime;
  CREATE PUBLICATION supabase_realtime FOR TABLE public.patients, public.queue_entries, public.visit_records;
COMMIT;
