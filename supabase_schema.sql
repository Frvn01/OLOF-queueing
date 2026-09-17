-- ==============================================================================
-- OUR LADY OF FATIMA EYE EAR NOSE THROAT CENTER (OLOF) QUEUEING & CLINICAL SYSTEM
-- SUPABASE COMPLETE DATABASE SCHEMA, STORAGE & REALTIME SETUP
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
    is_first_time BOOLEAN DEFAULT true,
    assigned_doctor VARCHAR(128),
    assigned_room VARCHAR(64),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Idempotent column additions for existing databases:
ALTER TABLE public.patients ADD COLUMN IF NOT EXISTS chief_complaint TEXT;
ALTER TABLE public.patients ADD COLUMN IF NOT EXISTS history_of_present_illness TEXT;
ALTER TABLE public.patients ADD COLUMN IF NOT EXISTS past_medical_history TEXT;
ALTER TABLE public.patients ADD COLUMN IF NOT EXISTS is_first_time BOOLEAN DEFAULT true;
ALTER TABLE public.patients ADD COLUMN IF NOT EXISTS assigned_doctor VARCHAR(128);
ALTER TABLE public.patients ADD COLUMN IF NOT EXISTS assigned_room VARCHAR(64);

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
    assigned_doctor VARCHAR(128),
    date_key VARCHAR(16) NOT NULL, -- 'YYYY-MM-DD' for daily reset
    created_at TIMESTAMPTZ DEFAULT NOW(),
    called_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ
);

ALTER TABLE public.queue_entries ADD COLUMN IF NOT EXISTS assigned_room VARCHAR(64);
ALTER TABLE public.queue_entries ADD COLUMN IF NOT EXISTS assigned_doctor VARCHAR(128);

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

-- 4. CLINIC DOCTORS & ROOMS
CREATE TABLE IF NOT EXISTS public.clinic_doctors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(128) NOT NULL,
    department VARCHAR(16) NOT NULL DEFAULT 'ENT', -- 'ENT', 'EYES', 'BOTH'
    room VARCHAR(64),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.clinic_rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(64) NOT NULL,
    department VARCHAR(16) NOT NULL DEFAULT 'BOTH', -- 'ENT', 'EYES', 'BOTH'
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Pre-seed default doctors if empty
INSERT INTO public.clinic_doctors (name, department, room)
VALUES 
    ('Dr. Engr. Ranulfo Ramos', 'ENT', 'Room 1'),
    ('Dr. Ranulfo Ramos Jr.', 'EYES', 'Room 2')
ON CONFLICT DO NOTHING;

-- Pre-seed default rooms if empty
INSERT INTO public.clinic_rooms (name, department)
VALUES 
    ('Room 1', 'BOTH'),
    ('Room 2', 'BOTH'),
    ('Room 3', 'BOTH')
ON CONFLICT DO NOTHING;

-- 5. CLINICAL EXAMINATIONS & DIAGRAMS (NURSE STATION)
CREATE TABLE IF NOT EXISTS public.clinical_examinations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    examination_uuid UUID NOT NULL,
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    queue_entry_id UUID REFERENCES public.queue_entries(id) ON DELETE SET NULL,
    department VARCHAR(16) NOT NULL DEFAULT 'ENT', -- 'ENT' or 'EYES'
    exam_type VARCHAR(32) NOT NULL, -- 'EYES', 'EARS', 'NOSE', 'THROAT', 'HEAD', 'NECK', 'GENERAL'
    view_name VARCHAR(32) NOT NULL DEFAULT '1', -- '1', '2', '3', 'drawing'
    annotations JSONB DEFAULT '[]'::jsonb,
    image_url TEXT,
    clinical_findings TEXT,
    device_info VARCHAR(128),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. INDEXES FOR FAST SEARCH & LOOKUP
CREATE INDEX IF NOT EXISTS idx_patients_no ON public.patients(patient_no);
CREATE INDEX IF NOT EXISTS idx_patients_name ON public.patients(last_name, first_name);
CREATE INDEX IF NOT EXISTS idx_queue_date_dept ON public.queue_entries(date_key, department, status);
CREATE INDEX IF NOT EXISTS idx_queue_patient ON public.queue_entries(patient_id);
CREATE INDEX IF NOT EXISTS idx_visit_patient ON public.visit_records(patient_id);
CREATE INDEX IF NOT EXISTS idx_clinical_exam_uuid ON public.clinical_examinations(examination_uuid);
CREATE INDEX IF NOT EXISTS idx_clinical_exam_patient ON public.clinical_examinations(patient_id);
CREATE INDEX IF NOT EXISTS idx_clinical_exam_type ON public.clinical_examinations(exam_type);

-- 7. ROW LEVEL SECURITY (RLS) POLICIES (Allow App Read/Write)
ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.queue_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.visit_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clinic_doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clinic_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clinical_examinations ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    DROP POLICY IF EXISTS "Allow public read/write on patients" ON public.patients;
    CREATE POLICY "Allow public read/write on patients" ON public.patients FOR ALL USING (true) WITH CHECK (true);

    DROP POLICY IF EXISTS "Allow public read/write on queue_entries" ON public.queue_entries;
    CREATE POLICY "Allow public read/write on queue_entries" ON public.queue_entries FOR ALL USING (true) WITH CHECK (true);

    DROP POLICY IF EXISTS "Allow public read/write on visit_records" ON public.visit_records;
    CREATE POLICY "Allow public read/write on visit_records" ON public.visit_records FOR ALL USING (true) WITH CHECK (true);

    DROP POLICY IF EXISTS "Allow public read/write on clinic_doctors" ON public.clinic_doctors;
    CREATE POLICY "Allow public read/write on clinic_doctors" ON public.clinic_doctors FOR ALL USING (true) WITH CHECK (true);

    DROP POLICY IF EXISTS "Allow public read/write on clinic_rooms" ON public.clinic_rooms;
    CREATE POLICY "Allow public read/write on clinic_rooms" ON public.clinic_rooms FOR ALL USING (true) WITH CHECK (true);

    DROP POLICY IF EXISTS "Allow public read/write on clinical_examinations" ON public.clinical_examinations;
    CREATE POLICY "Allow public read/write on clinical_examinations" ON public.clinical_examinations FOR ALL USING (true) WITH CHECK (true);
END $$;

-- 8. STORAGE BUCKETS SETUP (Photos & Diagram Annotations)
INSERT INTO storage.buckets (id, name, public)
VALUES 
    ('patient-photos', 'patient-photos', true),
    ('clinical-diagrams', 'clinical-diagrams', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DO $$ BEGIN
    DROP POLICY IF EXISTS "Public Access patient-photos" ON storage.objects;
    CREATE POLICY "Public Access patient-photos" ON storage.objects
        FOR ALL USING (bucket_id = 'patient-photos') WITH CHECK (bucket_id = 'patient-photos');

    DROP POLICY IF EXISTS "Public Access clinical-diagrams" ON storage.objects;
    CREATE POLICY "Public Access clinical-diagrams" ON storage.objects
        FOR ALL USING (bucket_id = 'clinical-diagrams') WITH CHECK (bucket_id = 'clinical-diagrams');
END $$;

-- 9. ENABLE REALTIME PUBLICATION FOR LIVE QUEUE, NURSE STATION & DOCTORS
BEGIN;
  DROP PUBLICATION IF EXISTS supabase_realtime;
  CREATE PUBLICATION supabase_realtime FOR TABLE 
    public.patients, 
    public.queue_entries, 
    public.visit_records, 
    public.clinic_doctors, 
    public.clinic_rooms,
    public.clinical_examinations;
COMMIT;
