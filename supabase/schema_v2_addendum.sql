-- ============================================================
-- CORENZA — Schema Addendum v2
-- Tablas faltantes para igualar y superar OpenSIS
-- Sistema 100% virtual, multi-tenant, USD + GTQ
--
-- INSTRUCCIONES:
--   1. Aplicar DESPUÉS de schema.sql (ya está en Supabase)
--   2. Sección P contiene ALTER TABLE sobre tablas existentes
--   3. Todas las nuevas tablas incluyen RLS al final
-- ============================================================

-- ============================================================
-- A. SCHOOL — Calendarios, Notices, Salud Mental
-- ============================================================

CREATE TABLE school_calendars (
  id               UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id        UUID        NOT NULL REFERENCES schools(id)        ON DELETE CASCADE,
  academic_year_id UUID        REFERENCES academic_years(id)          ON DELETE CASCADE,
  name             TEXT        NOT NULL,
  description      TEXT,
  is_default       BOOLEAN     NOT NULL DEFAULT false,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE calendar_events (
  id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id   UUID        NOT NULL REFERENCES schools(id)          ON DELETE CASCADE,
  calendar_id UUID        NOT NULL REFERENCES school_calendars(id) ON DELETE CASCADE,
  title       TEXT        NOT NULL,
  description TEXT,
  event_type  TEXT        NOT NULL DEFAULT 'event'
    CHECK (event_type IN ('holiday', 'no_school', 'event', 'exam', 'deadline', 'other')),
  start_date  DATE        NOT NULL,
  end_date    DATE        NOT NULL,
  all_day     BOOLEAN     NOT NULL DEFAULT true,
  audience    TEXT        NOT NULL DEFAULT 'all'
    CHECK (audience IN ('all', 'teachers', 'students', 'guardians')),
  created_by  UUID        REFERENCES profiles(id),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT valid_date_range CHECK (end_date >= start_date)
);

-- Avisos internos operativos (diferente de announcements: solo staff)
CREATE TABLE notices (
  id         UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id  UUID        NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  author_id  UUID        NOT NULL REFERENCES profiles(id),
  title      TEXT        NOT NULL,
  body       TEXT        NOT NULL,
  priority   TEXT        NOT NULL DEFAULT 'normal'
    CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  audience   TEXT        NOT NULL DEFAULT 'staff'
    CHECK (audience IN ('all', 'staff', 'teachers', 'admins')),
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE mental_health_resources (
  id            UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id     UUID        NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  title         TEXT        NOT NULL,
  description   TEXT,
  resource_type TEXT        NOT NULL DEFAULT 'link'
    CHECK (resource_type IN ('link', 'document', 'contact', 'hotline', 'other')),
  url           TEXT,
  phone         TEXT,
  audience      TEXT        NOT NULL DEFAULT 'all'
    CHECK (audience IN ('all', 'students', 'guardians', 'staff')),
  active        BOOLEAN     NOT NULL DEFAULT true,
  created_by    UUID        REFERENCES profiles(id),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- B. ADMISSIONS — Módulo completo
-- ============================================================

CREATE TABLE admission_process_steps (
  id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id   UUID        NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name        TEXT        NOT NULL,
  sequence    INTEGER     NOT NULL,
  description TEXT,
  is_required BOOLEAN     NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (school_id, sequence)
);

-- Campos configurables del formulario de solicitud
CREATE TABLE applicant_field_definitions (
  id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id   UUID        NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  field_name  TEXT        NOT NULL,
  field_label TEXT        NOT NULL,
  field_type  TEXT        NOT NULL DEFAULT 'text'
    CHECK (field_type IN ('text', 'textarea', 'number', 'date', 'select', 'checkbox', 'radio', 'file')),
  options     JSONB,
  is_required BOOLEAN     NOT NULL DEFAULT false,
  sequence    INTEGER     NOT NULL DEFAULT 0,
  active      BOOLEAN     NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE applicants (
  id                      UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id               UUID        NOT NULL REFERENCES schools(id)       ON DELETE CASCADE,
  academic_year_id        UUID        REFERENCES academic_years(id),
  grade_level_id          UUID        REFERENCES grade_levels(id),
  first_name              TEXT        NOT NULL,
  last_name               TEXT        NOT NULL,
  birth_date              DATE,
  gender                  TEXT        CHECK (gender IN ('M', 'F', 'other')),
  guardian_name           TEXT,
  guardian_email          TEXT,
  guardian_phone          TEXT,
  guardian_relationship   TEXT,
  status                  TEXT        NOT NULL DEFAULT 'applied'
    CHECK (status IN ('applied', 'under_review', 'interview_scheduled', 'accepted', 'rejected', 'enrolled', 'archived', 'waitlisted')),
  current_step_id         UUID        REFERENCES admission_process_steps(id),
  applied_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  decision_at             TIMESTAMPTZ,
  decision_by             UUID        REFERENCES profiles(id),
  decision_notes          TEXT,
  converted_to_student_id UUID        REFERENCES students(id),
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE applicant_field_values (
  id           UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  applicant_id UUID        NOT NULL REFERENCES applicants(id)                  ON DELETE CASCADE,
  field_def_id UUID        NOT NULL REFERENCES applicant_field_definitions(id) ON DELETE CASCADE,
  value_text   TEXT,
  value_date   DATE,
  value_number NUMERIC,
  value_bool   BOOLEAN,
  value_json   JSONB,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (applicant_id, field_def_id)
);

CREATE TABLE applicant_step_history (
  id           UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  applicant_id UUID        NOT NULL REFERENCES applicants(id)              ON DELETE CASCADE,
  step_id      UUID        NOT NULL REFERENCES admission_process_steps(id),
  completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_by UUID        REFERENCES profiles(id),
  notes        TEXT
);

-- Plantillas de email (admisiones + comunicaciones)
CREATE TABLE email_templates (
  id         UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id  UUID        NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name       TEXT        NOT NULL,
  subject    TEXT        NOT NULL,
  body_html  TEXT        NOT NULL,
  body_text  TEXT,
  category   TEXT        NOT NULL DEFAULT 'general'
    CHECK (category IN ('admissions', 'enrollment', 'grades', 'attendance', 'billing', 'general', 'welcome')),
  variables  JSONB,                   -- [{key: "student_name", description: "Nombre del alumno"}]
  is_default BOOLEAN     NOT NULL DEFAULT false,
  active     BOOLEAN     NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- C. STUDENTS — Campos configurables y códigos de matrícula
-- ============================================================

CREATE TABLE student_field_definitions (
  id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id   UUID        NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  field_name  TEXT        NOT NULL,
  field_label TEXT        NOT NULL,
  field_type  TEXT        NOT NULL DEFAULT 'text'
    CHECK (field_type IN ('text', 'textarea', 'number', 'date', 'select', 'checkbox', 'radio')),
  options     JSONB,
  section     TEXT        NOT NULL DEFAULT 'general'
    CHECK (section IN ('general', 'medical', 'family', 'academic', 'other')),
  is_required BOOLEAN     NOT NULL DEFAULT false,
  sequence    INTEGER     NOT NULL DEFAULT 0,
  visible_to  TEXT[]      NOT NULL DEFAULT ARRAY['school_admin','secretary'],
  active      BOOLEAN     NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE student_field_values (
  id           UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id   UUID        NOT NULL REFERENCES students(id)                  ON DELETE CASCADE,
  field_def_id UUID        NOT NULL REFERENCES student_field_definitions(id) ON DELETE CASCADE,
  school_id    UUID        NOT NULL REFERENCES schools(id)                   ON DELETE CASCADE,
  value_text   TEXT,
  value_date   DATE,
  value_number NUMERIC,
  value_bool   BOOLEAN,
  value_json   JSONB,
  updated_by   UUID        REFERENCES profiles(id),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, field_def_id)
);

-- Códigos para que un alumno se registre (solo por invitación)
CREATE TABLE enrollment_codes (
  id               UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id        UUID        NOT NULL REFERENCES schools(id)  ON DELETE CASCADE,
  code             TEXT        NOT NULL UNIQUE,
  student_id       UUID        REFERENCES students(id),
  grade_level_id   UUID        REFERENCES grade_levels(id),
  academic_year_id UUID        REFERENCES academic_years(id),
  used_at          TIMESTAMPTZ,
  used_by          UUID        REFERENCES profiles(id),
  expires_at       TIMESTAMPTZ,
  created_by       UUID        REFERENCES profiles(id),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- D. STAFF — Perfil extendido y campos configurables
-- ============================================================

CREATE TABLE staff_profiles (
  id                      UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id               UUID        NOT NULL REFERENCES schools(id)   ON DELETE CASCADE,
  profile_id              UUID        UNIQUE NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  employee_id             TEXT,
  department              TEXT,
  position                TEXT,
  hire_date               DATE,
  contract_type           TEXT        CHECK (contract_type IN ('full_time', 'part_time', 'contractor')),
  salary_type             TEXT        CHECK (salary_type IN ('monthly', 'hourly', 'per_class')),
  emergency_contact_name  TEXT,
  emergency_contact_phone TEXT,
  specializations         TEXT[],
  certifications          TEXT[],
  notes                   TEXT,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE staff_field_definitions (
  id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id   UUID        NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  field_name  TEXT        NOT NULL,
  field_label TEXT        NOT NULL,
  field_type  TEXT        NOT NULL DEFAULT 'text'
    CHECK (field_type IN ('text', 'textarea', 'number', 'date', 'select', 'checkbox')),
  options     JSONB,
  is_required BOOLEAN     NOT NULL DEFAULT false,
  sequence    INTEGER     NOT NULL DEFAULT 0,
  active      BOOLEAN     NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE staff_field_values (
  id           UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  staff_id     UUID        NOT NULL REFERENCES staff_profiles(id)         ON DELETE CASCADE,
  field_def_id UUID        NOT NULL REFERENCES staff_field_definitions(id) ON DELETE CASCADE,
  school_id    UUID        NOT NULL REFERENCES schools(id)                 ON DELETE CASCADE,
  value_text   TEXT,
  value_date   DATE,
  value_number NUMERIC,
  value_bool   BOOLEAN,
  value_json   JSONB,
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (staff_id, field_def_id)
);

-- ============================================================
-- E. COURSES — Catálogo y solicitudes
-- ============================================================

CREATE TABLE courses (
  id             UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id      UUID         NOT NULL REFERENCES schools(id)  ON DELETE CASCADE,
  subject_id     UUID         REFERENCES subjects(id),
  code           TEXT         NOT NULL,
  name           TEXT         NOT NULL,
  description    TEXT,
  credits        NUMERIC(4,2) NOT NULL DEFAULT 1,
  grade_level_id UUID         REFERENCES grade_levels(id),
  is_elective    BOOLEAN      NOT NULL DEFAULT false,
  is_required    BOOLEAN      NOT NULL DEFAULT true,
  prerequisites  UUID[],                    -- course IDs requeridos
  max_students   INTEGER,
  active         BOOLEAN      NOT NULL DEFAULT true,
  created_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  UNIQUE (school_id, code)
);

CREATE TABLE course_requests (
  id               UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id        UUID        NOT NULL REFERENCES schools(id)        ON DELETE CASCADE,
  student_id       UUID        NOT NULL REFERENCES students(id)       ON DELETE CASCADE,
  course_id        UUID        NOT NULL REFERENCES courses(id)        ON DELETE CASCADE,
  academic_year_id UUID        NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
  requested_by     UUID        NOT NULL REFERENCES profiles(id),
  status           TEXT        NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'denied', 'waitlisted')),
  reviewed_by      UUID        REFERENCES profiles(id),
  review_notes     TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, course_id, academic_year_id)
);

-- ============================================================
-- F. SCHEDULING — Horarios virtuales
-- ============================================================

CREATE TABLE schedule_blocks (
  id                 UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id          UUID        NOT NULL REFERENCES schools(id)          ON DELETE CASCADE,
  teacher_subject_id UUID        NOT NULL REFERENCES teacher_subjects(id) ON DELETE CASCADE,
  academic_year_id   UUID        NOT NULL REFERENCES academic_years(id)   ON DELETE CASCADE,
  day_of_week        INTEGER     NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  start_time         TIME        NOT NULL,
  end_time           TIME        NOT NULL,
  timezone           TEXT        NOT NULL DEFAULT 'America/Guatemala',
  virtual_room_url   TEXT,
  active             BOOLEAN     NOT NULL DEFAULT true,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT valid_time_range CHECK (end_time > start_time)
);

-- ============================================================
-- G. GRADES — Escalas, report cards, honor roll, certificados,
--             transcripts, standards, graduación
-- ============================================================

CREATE TABLE grade_scales (
  id         UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id  UUID        NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name       TEXT        NOT NULL,
  scale_type TEXT        NOT NULL DEFAULT 'percentage'
    CHECK (scale_type IN ('percentage', 'letter', 'gpa', 'standards', 'custom')),
  is_default BOOLEAN     NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE grade_scale_entries (
  id             UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  grade_scale_id UUID         NOT NULL REFERENCES grade_scales(id) ON DELETE CASCADE,
  label          TEXT         NOT NULL,
  min_score      NUMERIC(5,2),
  max_score      NUMERIC(5,2),
  letter_grade   TEXT,
  gpa_value      NUMERIC(3,2),
  description    TEXT,
  sequence       INTEGER      NOT NULL DEFAULT 0
);

CREATE TABLE grading_preferences (
  id                     UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id              UUID         NOT NULL UNIQUE REFERENCES schools(id) ON DELETE CASCADE,
  default_scale_id       UUID         REFERENCES grade_scales(id),
  grading_system         TEXT         NOT NULL DEFAULT 'dual'
    CHECK (grading_system IN ('american', 'guatemalan', 'dual')),
  passing_score          NUMERIC(5,2) NOT NULL DEFAULT 60,
  calculate_gpa          BOOLEAN      NOT NULL DEFAULT true,
  gpa_scale              NUMERIC(3,2) NOT NULL DEFAULT 4.0,
  show_letter_grades     BOOLEAN      NOT NULL DEFAULT true,
  show_percentage        BOOLEAN      NOT NULL DEFAULT true,
  allow_teacher_override BOOLEAN      NOT NULL DEFAULT false,
  grade_entry_deadline   INTEGER,
  created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE standards (
  id             UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id      UUID        NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  subject_id     UUID        REFERENCES subjects(id),
  grade_level_id UUID        REFERENCES grade_levels(id),
  code           TEXT        NOT NULL,
  description    TEXT        NOT NULL,
  category       TEXT,
  active         BOOLEAN     NOT NULL DEFAULT true,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (school_id, code)
);

CREATE TABLE standard_grades (
  id                UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id         UUID        NOT NULL REFERENCES schools(id)        ON DELETE CASCADE,
  student_id        UUID        NOT NULL REFERENCES students(id)       ON DELETE CASCADE,
  standard_id       UUID        NOT NULL REFERENCES standards(id)      ON DELETE CASCADE,
  grading_period_id UUID        NOT NULL REFERENCES grading_periods(id),
  score             TEXT        NOT NULL,
  notes             TEXT,
  recorded_by       UUID        REFERENCES profiles(id),
  recorded_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, standard_id, grading_period_id)
);

CREATE TABLE report_card_configs (
  id               UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id        UUID        NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  academic_year_id UUID        REFERENCES academic_years(id),
  name             TEXT        NOT NULL,
  header_html      TEXT,
  footer_html      TEXT,
  show_attendance  BOOLEAN     NOT NULL DEFAULT true,
  show_behavior    BOOLEAN     NOT NULL DEFAULT false,
  show_comments    BOOLEAN     NOT NULL DEFAULT true,
  show_gpa         BOOLEAN     NOT NULL DEFAULT true,
  show_honor_roll  BOOLEAN     NOT NULL DEFAULT true,
  grade_scale_id   UUID        REFERENCES grade_scales(id),
  is_default       BOOLEAN     NOT NULL DEFAULT false,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE report_card_comments (
  id                 UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id          UUID        NOT NULL REFERENCES schools(id)         ON DELETE CASCADE,
  student_id         UUID        NOT NULL REFERENCES students(id)        ON DELETE CASCADE,
  teacher_subject_id UUID        NOT NULL REFERENCES teacher_subjects(id),
  grading_period_id  UUID        NOT NULL REFERENCES grading_periods(id),
  comment            TEXT        NOT NULL,
  effort_grade       TEXT        CHECK (effort_grade IN ('E', 'S', 'N', 'U')),
  created_by         UUID        NOT NULL REFERENCES profiles(id),
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, teacher_subject_id, grading_period_id)
);

CREATE TABLE honor_roll_configs (
  id                UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id         UUID         NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name              TEXT         NOT NULL,
  min_gpa           NUMERIC(3,2) NOT NULL,
  min_score         NUMERIC(5,2),
  no_failing_grades BOOLEAN      NOT NULL DEFAULT true,
  no_behavior_issues BOOLEAN     NOT NULL DEFAULT false,
  sequence          INTEGER      NOT NULL DEFAULT 0,
  created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE honor_roll_records (
  id                UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id         UUID         NOT NULL REFERENCES schools(id)            ON DELETE CASCADE,
  student_id        UUID         NOT NULL REFERENCES students(id)           ON DELETE CASCADE,
  honor_roll_id     UUID         NOT NULL REFERENCES honor_roll_configs(id),
  grading_period_id UUID         NOT NULL REFERENCES grading_periods(id),
  gpa               NUMERIC(3,2),
  avg_score         NUMERIC(5,2),
  created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, honor_roll_id, grading_period_id)
);

CREATE TABLE certificate_templates (
  id              UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id       UUID        NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name            TEXT        NOT NULL,
  template_type   TEXT        NOT NULL DEFAULT 'promotion'
    CHECK (template_type IN ('promotion', 'graduation', 'honor_roll', 'participation', 'custom')),
  body_html       TEXT        NOT NULL,
  variables       JSONB,
  active          BOOLEAN     NOT NULL DEFAULT true,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE certificates_issued (
  id                 UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id          UUID        NOT NULL REFERENCES schools(id)              ON DELETE CASCADE,
  student_id         UUID        NOT NULL REFERENCES students(id)             ON DELETE CASCADE,
  template_id        UUID        NOT NULL REFERENCES certificate_templates(id),
  academic_year_id   UUID        REFERENCES academic_years(id),
  issue_date         DATE        NOT NULL DEFAULT CURRENT_DATE,
  certificate_number TEXT,
  pdf_url            TEXT,
  issued_by          UUID        REFERENCES profiles(id),
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE transcript_configs (
  id                UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id         UUID        NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name              TEXT        NOT NULL,
  format            TEXT        NOT NULL DEFAULT 'american'
    CHECK (format IN ('american', 'guatemalan', 'custom')),
  header_html       TEXT,
  footer_html       TEXT,
  show_gpa          BOOLEAN     NOT NULL DEFAULT true,
  show_credits      BOOLEAN     NOT NULL DEFAULT true,
  show_grad_req     BOOLEAN     NOT NULL DEFAULT false,
  official_seal_url TEXT,
  signature_name    TEXT,
  signature_title   TEXT,
  is_default        BOOLEAN     NOT NULL DEFAULT false,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE graduation_requirements (
  id               UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id        UUID         NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name             TEXT         NOT NULL,
  requirement_type TEXT         NOT NULL DEFAULT 'credits'
    CHECK (requirement_type IN ('credits', 'courses', 'gpa', 'exam', 'service_hours', 'other')),
  credits_required NUMERIC(5,2),
  min_gpa          NUMERIC(3,2),
  course_ids       UUID[],
  description      TEXT,
  sequence         INTEGER      NOT NULL DEFAULT 0,
  active           BOOLEAN      NOT NULL DEFAULT true,
  created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE student_graduation_progress (
  id             UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id      UUID         NOT NULL REFERENCES schools(id)                  ON DELETE CASCADE,
  student_id     UUID         NOT NULL REFERENCES students(id)                 ON DELETE CASCADE,
  requirement_id UUID         NOT NULL REFERENCES graduation_requirements(id)  ON DELETE CASCADE,
  credits_earned NUMERIC(5,2) NOT NULL DEFAULT 0,
  is_completed   BOOLEAN      NOT NULL DEFAULT false,
  completed_at   TIMESTAMPTZ,
  notes          TEXT,
  updated_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, requirement_id)
);

-- ============================================================
-- H. ATTENDANCE — Códigos configurables
-- ============================================================

CREATE TABLE attendance_codes (
  id             UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id      UUID        NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  code           TEXT        NOT NULL,
  label          TEXT        NOT NULL,
  type           TEXT        NOT NULL
    CHECK (type IN ('present', 'absent', 'excused', 'other')),
  color          TEXT,
  affects_record BOOLEAN     NOT NULL DEFAULT true,
  active         BOOLEAN     NOT NULL DEFAULT true,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (school_id, code)
);

-- ============================================================
-- I. BEHAVIOR — Campos configurables
-- ============================================================

CREATE TABLE behavior_field_definitions (
  id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id   UUID        NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  field_name  TEXT        NOT NULL,
  field_label TEXT        NOT NULL,
  field_type  TEXT        NOT NULL DEFAULT 'text'
    CHECK (field_type IN ('text', 'textarea', 'select', 'checkbox')),
  options     JSONB,
  is_required BOOLEAN     NOT NULL DEFAULT false,
  sequence    INTEGER     NOT NULL DEFAULT 0,
  active      BOOLEAN     NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE behavior_field_values (
  id                 UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  behavior_record_id UUID        NOT NULL REFERENCES behavior_records(id)         ON DELETE CASCADE,
  field_def_id       UUID        NOT NULL REFERENCES behavior_field_definitions(id) ON DELETE CASCADE,
  value_text         TEXT,
  value_bool         BOOLEAN,
  value_json         JSONB,
  UNIQUE (behavior_record_id, field_def_id)
);

-- ============================================================
-- J. BILLING — Módulo completo
-- ============================================================

CREATE TABLE fee_types (
  id             UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id      UUID         NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name           TEXT         NOT NULL,
  code           TEXT         NOT NULL,
  description    TEXT,
  default_amount NUMERIC(10,2),
  currency       TEXT         NOT NULL DEFAULT 'USD',
  is_recurring   BOOLEAN      NOT NULL DEFAULT false,
  active         BOOLEAN      NOT NULL DEFAULT true,
  created_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  UNIQUE (school_id, code)
);

CREATE TABLE gl_accounts (
  id             UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id      UUID        NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  account_number TEXT        NOT NULL,
  name           TEXT        NOT NULL,
  account_type   TEXT        NOT NULL
    CHECK (account_type IN ('revenue', 'expense', 'asset', 'liability', 'equity')),
  description    TEXT,
  active         BOOLEAN     NOT NULL DEFAULT true,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (school_id, account_number)
);

CREATE TABLE payment_methods (
  id           UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id    UUID        NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name         TEXT        NOT NULL,
  type         TEXT        NOT NULL
    CHECK (type IN ('cash', 'bank_transfer', 'card', 'cheque', 'online', 'other')),
  instructions TEXT,
  active       BOOLEAN     NOT NULL DEFAULT true,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE billing_settings (
  id                      UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id               UUID         NOT NULL UNIQUE REFERENCES schools(id) ON DELETE CASCADE,
  default_currency        TEXT         NOT NULL DEFAULT 'USD',
  secondary_currency      TEXT         DEFAULT 'GTQ',
  exchange_rate           NUMERIC(10,4),
  tax_enabled             BOOLEAN      NOT NULL DEFAULT false,
  tax_rate                NUMERIC(5,2),
  tax_name                TEXT         DEFAULT 'IVA',
  invoice_prefix          TEXT         DEFAULT 'INV',
  invoice_next_number     INTEGER      NOT NULL DEFAULT 1,
  receipt_prefix          TEXT         DEFAULT 'REC',
  receipt_next_number     INTEGER      NOT NULL DEFAULT 1,
  invoice_footer          TEXT,
  late_fee_enabled        BOOLEAN      NOT NULL DEFAULT false,
  late_fee_amount         NUMERIC(10,2),
  late_fee_type           TEXT         CHECK (late_fee_type IN ('fixed', 'percentage')),
  payment_due_days        INTEGER      NOT NULL DEFAULT 30,
  stripe_account_id       TEXT,
  online_payments_enabled BOOLEAN      NOT NULL DEFAULT false,
  created_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- Líneas de detalle por factura (múltiples cargos simultáneos)
CREATE TABLE invoice_line_items (
  id            UUID          PRIMARY KEY DEFAULT uuid_generate_v4(),
  invoice_id    UUID          NOT NULL REFERENCES invoices(id)  ON DELETE CASCADE,
  fee_type_id   UUID          REFERENCES fee_types(id),
  description   TEXT          NOT NULL,
  quantity      NUMERIC(8,2)  NOT NULL DEFAULT 1,
  unit_price    NUMERIC(10,2) NOT NULL,
  discount_pct  NUMERIC(5,2)  NOT NULL DEFAULT 0,
  total         NUMERIC(10,2) GENERATED ALWAYS AS
    (quantity * unit_price * (1 - discount_pct / 100)) STORED,
  gl_account_id UUID          REFERENCES gl_accounts(id),
  sequence      INTEGER       NOT NULL DEFAULT 0
);

CREATE TABLE receipts (
  id             UUID          PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id      UUID          NOT NULL REFERENCES schools(id)  ON DELETE CASCADE,
  payment_id     UUID          NOT NULL REFERENCES payments(id),
  student_id     UUID          NOT NULL REFERENCES students(id),
  receipt_number TEXT          NOT NULL,
  amount         NUMERIC(10,2) NOT NULL,
  currency       TEXT          NOT NULL DEFAULT 'USD',
  issued_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  issued_by      UUID          REFERENCES profiles(id),
  notes          TEXT,
  pdf_url        TEXT,
  created_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  UNIQUE (school_id, receipt_number)
);

-- ============================================================
-- K. LMS — Integración con plataformas externas
-- ============================================================

CREATE TABLE lms_integrations (
  id                UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id         UUID        NOT NULL UNIQUE REFERENCES schools(id) ON DELETE CASCADE,
  provider          TEXT        NOT NULL DEFAULT 'none'
    CHECK (provider IN ('none', 'canvas', 'google_classroom', 'moodle', 'schoology', 'other')),
  api_url           TEXT,
  api_key_encrypted TEXT,
  client_id         TEXT,
  sync_grades       BOOLEAN     NOT NULL DEFAULT false,
  sync_attendance   BOOLEAN     NOT NULL DEFAULT false,
  sync_assignments  BOOLEAN     NOT NULL DEFAULT false,
  last_synced_at    TIMESTAMPTZ,
  sync_status       TEXT        DEFAULT 'idle'
    CHECK (sync_status IN ('idle', 'syncing', 'error', 'success')),
  sync_error_msg    TEXT,
  active            BOOLEAN     NOT NULL DEFAULT false,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE lms_sync_logs (
  id             UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id      UUID        NOT NULL REFERENCES schools(id)        ON DELETE CASCADE,
  lms_id         UUID        NOT NULL REFERENCES lms_integrations(id) ON DELETE CASCADE,
  sync_type      TEXT        NOT NULL
    CHECK (sync_type IN ('grades', 'attendance', 'assignments', 'courses', 'full')),
  status         TEXT        NOT NULL
    CHECK (status IN ('started', 'success', 'partial', 'failed')),
  records_synced INTEGER     DEFAULT 0,
  records_failed INTEGER     DEFAULT 0,
  error_details  JSONB,
  started_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at   TIMESTAMPTZ
);

-- ============================================================
-- L. COMMUNICATION — Configuración
-- ============================================================

CREATE TABLE communication_settings (
  id                            UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id                     UUID        NOT NULL UNIQUE REFERENCES schools(id) ON DELETE CASCADE,
  email_from_name               TEXT,
  email_from_address            TEXT,
  email_reply_to                TEXT,
  smtp_host                     TEXT,
  smtp_port                     INTEGER,
  smtp_user                     TEXT,
  smtp_password_encrypted       TEXT,
  notify_grades                 BOOLEAN     NOT NULL DEFAULT true,
  notify_attendance             BOOLEAN     NOT NULL DEFAULT true,
  notify_behavior               BOOLEAN     NOT NULL DEFAULT true,
  notify_billing                BOOLEAN     NOT NULL DEFAULT true,
  notify_announcements          BOOLEAN     NOT NULL DEFAULT true,
  guardian_can_message_teachers BOOLEAN     NOT NULL DEFAULT true,
  teacher_can_message_guardians BOOLEAN     NOT NULL DEFAULT true,
  created_at                    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- M. LESSON PLAN LIBRARY
-- ============================================================

CREATE TABLE lesson_plans (
  id               UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id        UUID        NOT NULL REFERENCES schools(id)  ON DELETE CASCADE,
  teacher_id       UUID        NOT NULL REFERENCES profiles(id),
  subject_id       UUID        REFERENCES subjects(id),
  grade_level_id   UUID        REFERENCES grade_levels(id),
  title            TEXT        NOT NULL,
  objectives       TEXT,
  duration_minutes INTEGER,
  body             TEXT        NOT NULL,
  standards        UUID[],
  is_shared        BOOLEAN     NOT NULL DEFAULT false,
  status           TEXT        NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'published', 'archived')),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE lesson_plan_resources (
  id             UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  lesson_plan_id UUID        NOT NULL REFERENCES lesson_plans(id) ON DELETE CASCADE,
  name           TEXT        NOT NULL,
  resource_type  TEXT        NOT NULL DEFAULT 'link'
    CHECK (resource_type IN ('link', 'document', 'video', 'image', 'other')),
  url            TEXT,
  file_url       TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- N. SETTINGS — Configuraciones generales del sistema
-- ============================================================

CREATE TABLE school_preferences (
  id                       UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id                UUID        NOT NULL UNIQUE REFERENCES schools(id) ON DELETE CASCADE,
  date_format              TEXT        NOT NULL DEFAULT 'MM/DD/YYYY'
    CHECK (date_format IN ('MM/DD/YYYY', 'DD/MM/YYYY', 'YYYY-MM-DD')),
  time_format              TEXT        NOT NULL DEFAULT '12h'
    CHECK (time_format IN ('12h', '24h')),
  default_language         TEXT        NOT NULL DEFAULT 'es'
    CHECK (default_language IN ('es', 'en')),
  week_starts_on           INTEGER     NOT NULL DEFAULT 1
    CHECK (week_starts_on IN (0, 1)),
  school_year_start_month  INTEGER     NOT NULL DEFAULT 1
    CHECK (school_year_start_month BETWEEN 1 AND 12),
  student_id_prefix        TEXT        DEFAULT '',
  max_absence_pct_fail     INTEGER     DEFAULT 10,
  show_student_photo       BOOLEAN     NOT NULL DEFAULT true,
  allow_parent_portal      BOOLEAN     NOT NULL DEFAULT true,
  allow_student_portal     BOOLEAN     NOT NULL DEFAULT true,
  maintenance_mode         BOOLEAN     NOT NULL DEFAULT false,
  created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Listas de valores configurables (raza, etnia, idioma, nivel, etc.)
-- school_id NULL = valores globales del sistema
CREATE TABLE list_of_values (
  id         UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id  UUID        REFERENCES schools(id) ON DELETE CASCADE,
  category   TEXT        NOT NULL,
  value      TEXT        NOT NULL,
  label_es   TEXT        NOT NULL,
  label_en   TEXT,
  sequence   INTEGER     NOT NULL DEFAULT 0,
  active     BOOLEAN     NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (school_id, category, value)
);

CREATE TABLE sso_settings (
  id                      UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id               UUID        NOT NULL UNIQUE REFERENCES schools(id) ON DELETE CASCADE,
  provider                TEXT        NOT NULL DEFAULT 'none'
    CHECK (provider IN ('none', 'google', 'microsoft', 'saml', 'oidc')),
  client_id               TEXT,
  client_secret_encrypted TEXT,
  tenant_id               TEXT,
  domain                  TEXT,
  metadata_url            TEXT,
  is_required             BOOLEAN     NOT NULL DEFAULT false,
  active                  BOOLEAN     NOT NULL DEFAULT false,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Perfiles de permiso granular (más allá del rol básico)
CREATE TABLE permission_profiles (
  id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id   UUID        NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name        TEXT        NOT NULL,
  base_role   app_role    NOT NULL,
  description TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE permission_entries (
  id                    UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  permission_profile_id UUID        NOT NULL REFERENCES permission_profiles(id) ON DELETE CASCADE,
  module                TEXT        NOT NULL,
  action                TEXT        NOT NULL
    CHECK (action IN ('view', 'create', 'edit', 'delete', 'export', 'approve')),
  granted               BOOLEAN     NOT NULL DEFAULT true,
  UNIQUE (permission_profile_id, module, action)
);

CREATE TABLE dashlet_settings (
  id         UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id  UUID        NOT NULL REFERENCES schools(id)  ON DELETE CASCADE,
  user_id    UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  dashlet    TEXT        NOT NULL,
  position   INTEGER     NOT NULL DEFAULT 0,
  visible    BOOLEAN     NOT NULL DEFAULT true,
  config     JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, dashlet)
);

-- ============================================================
-- O. DATOS INICIALES — list_of_values globales
-- ============================================================

INSERT INTO list_of_values (school_id, category, value, label_es, label_en, sequence) VALUES
  -- Race
  (NULL, 'race', 'american_indian',       'Indígena Americano/Nativo de Alaska', 'American Indian/Alaska Native', 1),
  (NULL, 'race', 'asian',                 'Asiático',                            'Asian',                         2),
  (NULL, 'race', 'black',                 'Negro/Afroamericano',                 'Black/African American',         3),
  (NULL, 'race', 'hispanic',              'Hispano/Latino',                      'Hispanic/Latino',                4),
  (NULL, 'race', 'native_hawaiian',       'Nativo de Hawaii/Islas del Pacífico', 'Native Hawaiian/Pacific Islander',5),
  (NULL, 'race', 'white',                 'Blanco',                              'White',                         6),
  (NULL, 'race', 'two_or_more',           'Dos o más razas',                     'Two or More Races',             7),
  (NULL, 'race', 'prefer_not_to_say',     'Prefiero no indicar',                 'Prefer Not to Say',             8),
  -- Ethnicity
  (NULL, 'ethnicity', 'hispanic_latino',  'Hispano/Latino',                      'Hispanic/Latino',                1),
  (NULL, 'ethnicity', 'not_hispanic',     'No Hispano/Latino',                   'Not Hispanic/Latino',            2),
  (NULL, 'ethnicity', 'prefer_not_to_say','Prefiero no indicar',                 'Prefer Not to Say',             3),
  -- Language
  (NULL, 'language', 'es',   'Español',    'Spanish',    1),
  (NULL, 'language', 'en',   'Inglés',     'English',    2),
  (NULL, 'language', 'mam',  'Mam',        'Mam',        3),
  (NULL, 'language', 'kiche','K''iche''',  'K''iche''',  4),
  (NULL, 'language', 'other','Otro',       'Other',      5),
  -- School Level
  (NULL, 'school_level', 'preschool',  'Preprimaria',  'Preschool',    1),
  (NULL, 'school_level', 'primary',    'Primaria',     'Elementary',   2),
  (NULL, 'school_level', 'middle',     'Básico',       'Middle School',3),
  (NULL, 'school_level', 'high',       'Diversificado','High School',  4),
  -- School Classification
  (NULL, 'school_classification', 'public',      'Pública',    'Public',     1),
  (NULL, 'school_classification', 'private',     'Privada',    'Private',    2),
  (NULL, 'school_classification', 'charter',     'Charter',    'Charter',    3),
  (NULL, 'school_classification', 'homeschool',  'Homeschool', 'Homeschool', 4),
  (NULL, 'school_classification', 'virtual',     'Virtual',    'Virtual',    5);

-- ============================================================
-- P. MODIFICACIONES A TABLAS EXISTENTES
-- ============================================================

-- invoices: campos para multi-currency, totales, PDF, notas
ALTER TABLE invoices
  ADD COLUMN IF NOT EXISTS fee_type_id     UUID          REFERENCES fee_types(id),
  ADD COLUMN IF NOT EXISTS currency        TEXT          NOT NULL DEFAULT 'USD',
  ADD COLUMN IF NOT EXISTS subtotal        NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS discount_amount NUMERIC(10,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS tax_amount      NUMERIC(10,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_amount    NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS notes           TEXT,
  ADD COLUMN IF NOT EXISTS issued_by       UUID          REFERENCES profiles(id),
  ADD COLUMN IF NOT EXISTS pdf_url         TEXT;

-- payments: vincular a payment_method configurable y GL account
ALTER TABLE payments
  ADD COLUMN IF NOT EXISTS payment_method_id UUID REFERENCES payment_methods(id),
  ADD COLUMN IF NOT EXISTS gl_account_id     UUID REFERENCES gl_accounts(id);

-- behavior_records: campos de referral completo
ALTER TABLE behavior_records
  ADD COLUMN IF NOT EXISTS status            TEXT DEFAULT 'open'
    CHECK (status IN ('open', 'under_review', 'resolved', 'closed')),
  ADD COLUMN IF NOT EXISTS severity          TEXT
    CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  ADD COLUMN IF NOT EXISTS parent_notified   BOOLEAN     DEFAULT false,
  ADD COLUMN IF NOT EXISTS parent_notified_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS resolution        TEXT,
  ADD COLUMN IF NOT EXISTS updated_at        TIMESTAMPTZ DEFAULT NOW();

-- grades: effort grade (esfuerzo separado de nota académica)
ALTER TABLE grades
  ADD COLUMN IF NOT EXISTS effort_grade TEXT
    CHECK (effort_grade IN ('E', 'S', 'N', 'U'));

-- students: campos demográficos completos
ALTER TABLE students
  ADD COLUMN IF NOT EXISTS program     TEXT,
  ADD COLUMN IF NOT EXISTS nationality TEXT,
  ADD COLUMN IF NOT EXISTS language    TEXT,
  ADD COLUMN IF NOT EXISTS race        TEXT,
  ADD COLUMN IF NOT EXISTS ethnicity   TEXT,
  ADD COLUMN IF NOT EXISTS special_ed  BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS iep_flag    BOOLEAN DEFAULT false;

-- user_roles: vincular a perfil de permisos granular
ALTER TABLE user_roles
  ADD COLUMN IF NOT EXISTS permission_profile_id UUID REFERENCES permission_profiles(id);

-- ============================================================
-- Q. ÍNDICES para nuevas tablas
-- ============================================================

CREATE INDEX idx_school_calendars_school     ON school_calendars(school_id);
CREATE INDEX idx_calendar_events_calendar    ON calendar_events(calendar_id);
CREATE INDEX idx_calendar_events_dates       ON calendar_events(start_date, end_date);
CREATE INDEX idx_notices_school              ON notices(school_id);
CREATE INDEX idx_applicants_school           ON applicants(school_id);
CREATE INDEX idx_applicants_status           ON applicants(status);
CREATE INDEX idx_applicant_fv_applicant      ON applicant_field_values(applicant_id);
CREATE INDEX idx_student_fv_student          ON student_field_values(student_id);
CREATE INDEX idx_staff_profiles_profile      ON staff_profiles(profile_id);
CREATE INDEX idx_staff_profiles_school       ON staff_profiles(school_id);
CREATE INDEX idx_courses_school              ON courses(school_id);
CREATE INDEX idx_course_requests_student     ON course_requests(student_id);
CREATE INDEX idx_schedule_blocks_ts          ON schedule_blocks(teacher_subject_id);
CREATE INDEX idx_schedule_blocks_year        ON schedule_blocks(academic_year_id);
CREATE INDEX idx_standard_grades_student     ON standard_grades(student_id);
CREATE INDEX idx_standard_grades_standard    ON standard_grades(standard_id);
CREATE INDEX idx_report_card_comments_student ON report_card_comments(student_id);
CREATE INDEX idx_honor_roll_records_student  ON honor_roll_records(student_id);
CREATE INDEX idx_certificates_issued_student ON certificates_issued(student_id);
CREATE INDEX idx_grad_progress_student       ON student_graduation_progress(student_id);
CREATE INDEX idx_invoice_lines_invoice       ON invoice_line_items(invoice_id);
CREATE INDEX idx_receipts_payment            ON receipts(payment_id);
CREATE INDEX idx_receipts_student            ON receipts(student_id);
CREATE INDEX idx_lms_sync_logs_school        ON lms_sync_logs(school_id);
CREATE INDEX idx_lesson_plans_teacher        ON lesson_plans(teacher_id);
CREATE INDEX idx_lesson_plans_subject        ON lesson_plans(subject_id);
CREATE INDEX idx_list_of_values_category     ON list_of_values(category);
CREATE INDEX idx_permission_entries_profile  ON permission_entries(permission_profile_id);
CREATE INDEX idx_dashlet_settings_user       ON dashlet_settings(user_id);

-- ============================================================
-- R. ROW LEVEL SECURITY — Nuevas tablas
--    Política base: aislamiento por school_id
-- ============================================================

ALTER TABLE school_calendars            ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendar_events             ENABLE ROW LEVEL SECURITY;
ALTER TABLE notices                     ENABLE ROW LEVEL SECURITY;
ALTER TABLE mental_health_resources     ENABLE ROW LEVEL SECURITY;
ALTER TABLE admission_process_steps     ENABLE ROW LEVEL SECURITY;
ALTER TABLE applicant_field_definitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE applicants                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE applicant_field_values      ENABLE ROW LEVEL SECURITY;
ALTER TABLE applicant_step_history      ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_templates             ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_field_definitions   ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_field_values        ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrollment_codes            ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_profiles              ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_field_definitions     ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_field_values          ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses                     ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_requests             ENABLE ROW LEVEL SECURITY;
ALTER TABLE schedule_blocks             ENABLE ROW LEVEL SECURITY;
ALTER TABLE grade_scales                ENABLE ROW LEVEL SECURITY;
ALTER TABLE grade_scale_entries         ENABLE ROW LEVEL SECURITY;
ALTER TABLE grading_preferences         ENABLE ROW LEVEL SECURITY;
ALTER TABLE standards                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE standard_grades             ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_card_configs         ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_card_comments        ENABLE ROW LEVEL SECURITY;
ALTER TABLE honor_roll_configs          ENABLE ROW LEVEL SECURITY;
ALTER TABLE honor_roll_records          ENABLE ROW LEVEL SECURITY;
ALTER TABLE certificate_templates       ENABLE ROW LEVEL SECURITY;
ALTER TABLE certificates_issued         ENABLE ROW LEVEL SECURITY;
ALTER TABLE transcript_configs          ENABLE ROW LEVEL SECURITY;
ALTER TABLE graduation_requirements     ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_graduation_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_codes            ENABLE ROW LEVEL SECURITY;
ALTER TABLE behavior_field_definitions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE behavior_field_values       ENABLE ROW LEVEL SECURITY;
ALTER TABLE fee_types                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE gl_accounts                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_methods             ENABLE ROW LEVEL SECURITY;
ALTER TABLE billing_settings            ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_line_items          ENABLE ROW LEVEL SECURITY;
ALTER TABLE receipts                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE lms_integrations            ENABLE ROW LEVEL SECURITY;
ALTER TABLE lms_sync_logs               ENABLE ROW LEVEL SECURITY;
ALTER TABLE communication_settings      ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_plans                ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_plan_resources       ENABLE ROW LEVEL SECURITY;
ALTER TABLE school_preferences          ENABLE ROW LEVEL SECURITY;
ALTER TABLE list_of_values              ENABLE ROW LEVEL SECURITY;
ALTER TABLE sso_settings                ENABLE ROW LEVEL SECURITY;
ALTER TABLE permission_profiles         ENABLE ROW LEVEL SECURITY;
ALTER TABLE permission_entries          ENABLE ROW LEVEL SECURITY;
ALTER TABLE dashlet_settings            ENABLE ROW LEVEL SECURITY;

-- Política base: todos los miembros del colegio ven su colegio
CREATE POLICY "school_isolation" ON school_calendars            FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON calendar_events             FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON notices                     FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON mental_health_resources     FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON admission_process_steps     FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON applicant_field_definitions FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON applicants                  FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON email_templates             FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON student_field_definitions   FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON student_field_values        FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON enrollment_codes            FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON staff_profiles              FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON staff_field_definitions     FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON staff_field_values          FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON courses                     FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON course_requests             FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON schedule_blocks             FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON grade_scales                FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON grading_preferences         FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON standards                   FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON standard_grades             FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON report_card_configs         FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON report_card_comments        FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON honor_roll_configs          FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON honor_roll_records          FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON certificate_templates       FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON certificates_issued         FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON transcript_configs          FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON graduation_requirements     FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON student_graduation_progress FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON attendance_codes            FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON behavior_field_definitions  FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON fee_types                   FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON gl_accounts                 FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON payment_methods             FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON billing_settings            FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON receipts                    FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON lms_integrations            FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON lms_sync_logs               FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON communication_settings      FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON lesson_plans                FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON school_preferences          FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON sso_settings                FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON permission_profiles         FOR ALL USING (school_id = auth_user_school_id());
CREATE POLICY "school_isolation" ON permission_entries          FOR ALL
  USING (EXISTS (
    SELECT 1 FROM permission_profiles pp
    WHERE pp.id = permission_entries.permission_profile_id
      AND pp.school_id = auth_user_school_id()
  ));

-- applicant_field_values: via applicant → school
CREATE POLICY "school_isolation" ON applicant_field_values FOR ALL
  USING (EXISTS (
    SELECT 1 FROM applicants a
    WHERE a.id = applicant_field_values.applicant_id
      AND a.school_id = auth_user_school_id()
  ));

-- applicant_step_history: via applicant → school
CREATE POLICY "school_isolation" ON applicant_step_history FOR ALL
  USING (EXISTS (
    SELECT 1 FROM applicants a
    WHERE a.id = applicant_step_history.applicant_id
      AND a.school_id = auth_user_school_id()
  ));

-- grade_scale_entries: via grade_scale → school
CREATE POLICY "school_isolation" ON grade_scale_entries FOR ALL
  USING (EXISTS (
    SELECT 1 FROM grade_scales gs
    WHERE gs.id = grade_scale_entries.grade_scale_id
      AND gs.school_id = auth_user_school_id()
  ));

-- behavior_field_values: via behavior_record → school
CREATE POLICY "school_isolation" ON behavior_field_values FOR ALL
  USING (EXISTS (
    SELECT 1 FROM behavior_records br
    WHERE br.id = behavior_field_values.behavior_record_id
      AND br.school_id = auth_user_school_id()
  ));

-- invoice_line_items: via invoice → school
CREATE POLICY "school_isolation" ON invoice_line_items FOR ALL
  USING (EXISTS (
    SELECT 1 FROM invoices i
    WHERE i.id = invoice_line_items.invoice_id
      AND i.school_id = auth_user_school_id()
  ));

-- lesson_plan_resources: via lesson_plan → school
CREATE POLICY "school_isolation" ON lesson_plan_resources FOR ALL
  USING (EXISTS (
    SELECT 1 FROM lesson_plans lp
    WHERE lp.id = lesson_plan_resources.lesson_plan_id
      AND lp.school_id = auth_user_school_id()
  ));

-- dashlet_settings: solo el propietario
CREATE POLICY "dashlet_owner_all" ON dashlet_settings
  FOR ALL USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- list_of_values: lectura pública (sistema) + aislamiento de escuela
CREATE POLICY "lov_read" ON list_of_values
  FOR SELECT USING (school_id IS NULL OR school_id = auth_user_school_id());
CREATE POLICY "lov_school_write" ON list_of_values
  FOR ALL USING (school_id = auth_user_school_id())
  WITH CHECK (school_id = auth_user_school_id());

-- ============================================================
-- S. TRIGGERS updated_at — Nuevas tablas que lo necesitan
-- ============================================================

CREATE TRIGGER trg_school_calendars_updated_at
  BEFORE UPDATE ON school_calendars FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_notices_updated_at
  BEFORE UPDATE ON notices FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_mental_health_resources_updated_at
  BEFORE UPDATE ON mental_health_resources FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_applicants_updated_at
  BEFORE UPDATE ON applicants FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_email_templates_updated_at
  BEFORE UPDATE ON email_templates FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_staff_profiles_updated_at
  BEFORE UPDATE ON staff_profiles FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_courses_updated_at
  BEFORE UPDATE ON courses FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_course_requests_updated_at
  BEFORE UPDATE ON course_requests FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_grading_preferences_updated_at
  BEFORE UPDATE ON grading_preferences FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_report_card_configs_updated_at
  BEFORE UPDATE ON report_card_configs FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_report_card_comments_updated_at
  BEFORE UPDATE ON report_card_comments FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_certificate_templates_updated_at
  BEFORE UPDATE ON certificate_templates FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_transcript_configs_updated_at
  BEFORE UPDATE ON transcript_configs FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_billing_settings_updated_at
  BEFORE UPDATE ON billing_settings FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_lms_integrations_updated_at
  BEFORE UPDATE ON lms_integrations FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_communication_settings_updated_at
  BEFORE UPDATE ON communication_settings FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_lesson_plans_updated_at
  BEFORE UPDATE ON lesson_plans FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_school_preferences_updated_at
  BEFORE UPDATE ON school_preferences FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_sso_settings_updated_at
  BEFORE UPDATE ON sso_settings FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_permission_profiles_updated_at
  BEFORE UPDATE ON permission_profiles FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_dashlet_settings_updated_at
  BEFORE UPDATE ON dashlet_settings FOR EACH ROW EXECUTE FUNCTION set_updated_at();
