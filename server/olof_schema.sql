-- ============================================================================
-- OLOF Clinic Local Storage API Schema
-- Local SQLite database running on Server Room PC (192.168.100.17:8080)
-- ============================================================================

-- 1. Local Files Metadata Table (Big Binary Assets)
CREATE TABLE IF NOT EXISTS local_files (
    id TEXT PRIMARY KEY,
    filename TEXT NOT NULL,
    category TEXT NOT NULL CHECK(category IN ('photos', 'drawings', 'attachments', 'backups')),
    patient_id TEXT,
    original_name TEXT,
    content_type TEXT NOT NULL,
    size_bytes INTEGER NOT NULL,
    relative_path TEXT NOT NULL,
    file_url TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_files_patient ON local_files(patient_id);
CREATE INDEX IF NOT EXISTS idx_files_category ON local_files(category);

-- 2. Clinical Drawings & Organ Annotations Table
CREATE TABLE IF NOT EXISTS clinical_drawings (
    id TEXT PRIMARY KEY,
    patient_id TEXT NOT NULL,
    doctor_id TEXT,
    doctor_name TEXT,
    organ TEXT NOT NULL CHECK(organ IN ('EAR', 'NOSE', 'THROAT', 'EYES', 'OTHER')),
    file_id TEXT REFERENCES local_files(id),
    file_url TEXT NOT NULL,
    findings TEXT,
    symptoms TEXT,
    causes TEXT,
    annotations_json TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_drawings_patient ON clinical_drawings(patient_id);
CREATE INDEX IF NOT EXISTS idx_drawings_organ ON clinical_drawings(organ);

-- 3. Local Queue Cache (Optional local LAN broadcast & offline fallback)
CREATE TABLE IF NOT EXISTS local_queue_cache (
    id TEXT PRIMARY KEY,
    queue_number TEXT NOT NULL,
    patient_name TEXT NOT NULL,
    patient_id TEXT,
    department TEXT NOT NULL,
    status TEXT NOT NULL,
    assigned_doctor TEXT,
    assigned_room TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
