CREATE TABLE IF NOT EXISTS insurance (
    insurance_id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS hospitals (
    hospital_id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    hospital_type TEXT NOT NULL,
    region TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS providers (
    provider_id TEXT PRIMARY KEY NOT NULL,
    specialty TEXT NOT NULL,
    hospital_id TEXT NOT NULL REFERENCES hospitals(hospital_id),
    state TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS diagnoses (
    diagnosis_code TEXT PRIMARY KEY NOT NULL,
    description TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS procedures (
    procedure_code TEXT PRIMARY KEY NOT NULL,
    description TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS patients (
    patient_id TEXT PRIMARY KEY NOT NULL,
    date_of_birth DATE NOT NULL,
    gender TEXT NOT NULL,
    state TEXT NOT NULL,
    insurance_id TEXT NOT NULL REFERENCES insurance(insurance_id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CHECK (updated_at >= created_at)
);

CREATE TABLE IF NOT EXISTS visits (
    visit_id TEXT PRIMARY KEY NOT NULL,
    patient_id TEXT NOT NULL REFERENCES patients(patient_id),
    provider_id TEXT NOT NULL REFERENCES providers(provider_id),
    hospital_id TEXT NOT NULL REFERENCES hospitals(hospital_id),
    visit_type TEXT NOT NULL,
    event_time TIMESTAMP WITH TIME ZONE NOT NULL,
    diagnosis_code TEXT NOT NULL REFERENCES diagnoses(diagnosis_code)
);

CREATE TABLE IF NOT EXISTS claims (
    claim_id TEXT PRIMARY KEY NOT NULL,
    patient_id TEXT NOT NULL REFERENCES patients(patient_id),
    visit_id TEXT NOT NULL REFERENCES visits(visit_id),
    status TEXT NOT NULL,
    billed NUMERIC(14,2) NOT NULL CHECK (billed >= 0),
    allowed NUMERIC(14,2) NOT NULL CHECK (allowed >= 0),
    paid NUMERIC(14,2) NOT NULL CHECK (paid >= 0),
    rejection_reason TEXT,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CHECK (status IN ('Approved', 'Rejected', 'Pending')),
    CHECK (paid <= allowed AND allowed <= billed)
);

CREATE TABLE IF NOT EXISTS claim_lines (
    claim_line_id TEXT PRIMARY KEY NOT NULL,
    claim_id TEXT NOT NULL REFERENCES claims(claim_id),
    procedure_code TEXT NOT NULL REFERENCES procedures(procedure_code),
    units INTEGER NOT NULL CHECK (units > 0),
    amount NUMERIC(14,2) NOT NULL CHECK (amount >= 0)
);

CREATE TABLE IF NOT EXISTS prescriptions (
    prescription_id TEXT PRIMARY KEY NOT NULL,
    patient_id TEXT NOT NULL REFERENCES patients(patient_id),
    provider_id TEXT NOT NULL REFERENCES providers(provider_id),
    medicine TEXT NOT NULL,
    dosage TEXT NOT NULL,
    date DATE NOT NULL
);

CREATE INDEX IF NOT EXISTS ix_patients_updated_at ON patients(updated_at);

CREATE INDEX IF NOT EXISTS ix_claims_updated_at ON claims(updated_at);

CREATE INDEX IF NOT EXISTS ix_visits_patient_time ON visits(patient_id, event_time);

CREATE INDEX IF NOT EXISTS ix_claim_lines_claim ON claim_lines(claim_id);
