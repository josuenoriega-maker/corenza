-- ============================================================
-- CORENZA — Schema Multi-Tenant para Supabase
-- Plataforma educativa 100% virtual: Woodbridge.gt / ISEA.gt
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- 1. COLEGIOS (Tenant raíz)
-- ============================================================

CREATE TABLE schools (
  id         UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  name       TEXT        NOT NULL,
  slug       TEXT        UNIQUE NOT NULL,          -- woodbridge, isea
  logo_url   TEXT,
  country    TEXT        NOT NULL DEFAULT 'GT',
  city       TEXT,
  address    TEXT,
  phone      TEXT,
  email      TEXT,
  website    TEXT,
  timezone   TEXT        NOT NULL DEFAULT 'America/Guatemala',
  locale     TEXT        NOT NULL DEFAULT 'es',
  active     BOOLEAN     NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 2. PLANES Y SUSCRIPCIONES (Comercialización)
-- ============================================================

CREATE TABLE plans (
  id            UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  name          TEXT        NOT NULL,              -- Trial, Básico, Estándar, Premium
  max_students  INTEGER,                           -- NULL = ilimitado
  max_teachers  INTEGER,
  features      JSONB       NOT NULL DEFAULT '{}',
  price_monthly NUMERIC(10,2),
  price_yearly  NUMERIC(10,2),
  currency      TEXT        NOT NULL DEFAULT 'USD',
  active        BOOLEAN     NOT NULL DEFAULT true,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE subscriptions (
  id                     UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id              UUID        NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  plan_id                UUID        NOT NULL REFERENCES plans(id),
  status                 TEXT        NOT NULL DEFAULT 'active'
    CHECK (status IN ('trial', 'active', 'past_due', 'cancelled')),
  trial_ends_at          TIMESTAMPTZ,
  current_period_start   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  current_period_end     TIMESTAMPTZ NOT NULL,
  stripe_subscription_id TEXT        UNIQUE,
  stripe_customer_id     TEXT,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 3. USUARIOS Y PERFILES
-- ============================================================

CREATE TABLE profiles (
  id         UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  school_id  UUID        NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  first_name TEXT        NOT NULL,
  last_name  TEXT        NOT NULL,
  avatar_url TEXT,
  phone      TEXT,
  dpi        TEXT,                                 -- Documento Personal de Identificación (GT)
  birth_date DATE,
  gender     TEXT        CHECK (gender IN ('M', 'F', 'other')),
  address    TEXT,
  active     BOOLEAN     NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TYPE app_role AS ENUM (
  'super_admin',   -- Admin de plataforma (Corenza)
  'school_admin',  -- Director/Admin del colegio
  'secretary',     -- Secretaria del colegio
  'teacher',       -- Maestro
  'student',       -- Alumno
  'guardian'       -- Padre/Tutor
);

CREATE TABLE user_roles (
  id         UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID        NOT NULL REFERENCES profiles(id)  ON DELETE CASCADE,
  school_id  UUID        NOT NULL REFERENCES schools(id)   ON DELETE CASCADE,
  role       app_role    NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, school_id, role)
);

-- ============================================================
-- 4. ESTRUCTURA ACADÉMICA
-- ============================================================

CREATE TABLE academic_years (
  id         UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id  UUID        NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name       TEXT        NOT NULL,                 -- "2025", "2025-2026"
  start_date DATE        NOT NULL,
  end_date   DATE        NOT NULL,
  is_current BOOLEAN     NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE grading_periods (
  id               UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id        UUID        NOT NULL REFERENCES schools(id)        ON DELETE CASCADE,
  academic_year_id UUID        NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
  name             TEXT        NOT NULL,           -- "Bimestre 1", "Trimestre 2"
  sequence         INTEGER     NOT NULL,
  start_date       DATE        NOT NULL,
  end_date         DATE        NOT NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE grade_levels (
  id         UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id  UUID        NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name       TEXT        NOT NULL,                 -- "Primero Primaria", "Cuarto Bachillerato"
  sequence   INTEGER     NOT NULL,
  level_type TEXT        NOT NULL DEFAULT 'primary'
    CHECK (level_type IN ('preschool', 'primary', 'middle', 'high', 'university')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE class_sections (
  id                  UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id           UUID        NOT NULL REFERENCES schools(id)        ON DELETE CASCADE,
  grade_level_id      UUID        NOT NULL REFERENCES grade_levels(id)   ON DELETE CASCADE,
  academic_year_id    UUID        NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
  name                TEXT        NOT NULL,        -- "A", "B", "C"
  max_students        INTEGER     NOT NULL DEFAULT 35,
  homeroom_teacher_id UUID        REFERENCES profiles(id),
  virtual_room_url    TEXT,                        -- enlace permanente de la sección (Meet/Zoom/Teams)
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 5. MATERIAS Y ASIGNACIÓN MAESTRO-MATERIA
-- ============================================================

CREATE TABLE subjects (
  id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id   UUID        NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name        TEXT        NOT NULL,                -- "Matemáticas", "Comunicación y Lenguaje"
  code        TEXT,                                -- "MAT", "CYL"
  description TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Qué maestro imparte qué materia en qué sección y año
CREATE TABLE teacher_subjects (
  id               UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id        UUID        NOT NULL REFERENCES schools(id)         ON DELETE CASCADE,
  teacher_id       UUID        NOT NULL REFERENCES profiles(id),
  subject_id       UUID        NOT NULL REFERENCES subjects(id)        ON DELETE CASCADE,
  section_id       UUID        NOT NULL REFERENCES class_sections(id)  ON DELETE CASCADE,
  academic_year_id UUID        NOT NULL REFERENCES academic_years(id)  ON DELETE CASCADE,
  weekly_hours     INTEGER,
  virtual_room_url TEXT,                           -- enlace de clase si difiere del de sección
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (teacher_id, subject_id, section_id, academic_year_id)
);

-- ============================================================
-- 6. ALUMNOS
-- ============================================================

CREATE TABLE students (
  id              UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id       UUID         NOT NULL REFERENCES schools(id)  ON DELETE CASCADE,
  profile_id      UUID         UNIQUE REFERENCES profiles(id)   ON DELETE SET NULL,
  student_code    TEXT         NOT NULL,           -- Código interno del colegio
  enrollment_date DATE,
  status          TEXT         NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'inactive', 'graduated', 'transferred', 'withdrawn')),
  scholarship_pct NUMERIC(5,2) DEFAULT 0,
  notes           TEXT,
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  UNIQUE (school_id, student_code)
);

CREATE TABLE enrollments (
  id               UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id        UUID        NOT NULL REFERENCES schools(id)         ON DELETE CASCADE,
  student_id       UUID        NOT NULL REFERENCES students(id)        ON DELETE CASCADE,
  section_id       UUID        NOT NULL REFERENCES class_sections(id)  ON DELETE CASCADE,
  academic_year_id UUID        NOT NULL REFERENCES academic_years(id)  ON DELETE CASCADE,
  status           TEXT        NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'transferred', 'withdrawn')),
  enrolled_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, academic_year_id)
);

-- ============================================================
-- 7. TUTORES / PADRES DE FAMILIA
-- ============================================================

CREATE TABLE guardians (
  id         UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id  UUID        NOT NULL REFERENCES schools(id)  ON DELETE CASCADE,
  profile_id UUID        UNIQUE REFERENCES profiles(id)   ON DELETE SET NULL,
  occupation TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE student_guardians (
  id                UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id        UUID        NOT NULL REFERENCES students(id)  ON DELETE CASCADE,
  guardian_id       UUID        NOT NULL REFERENCES guardians(id) ON DELETE CASCADE,
  relationship      TEXT        NOT NULL,          -- "Padre", "Madre", "Abuelo", "Tutor"
  is_primary        BOOLEAN     NOT NULL DEFAULT false,
  emergency_contact BOOLEAN     NOT NULL DEFAULT false,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, guardian_id)
);

-- ============================================================
-- 8. CALIFICACIONES
--    Sistema dual: 0-100 (Guatemala) + letra GPA (americano)
-- ============================================================

CREATE TABLE grades (
  id                 UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id          UUID         NOT NULL REFERENCES schools(id)           ON DELETE CASCADE,
  student_id         UUID         NOT NULL REFERENCES students(id)          ON DELETE CASCADE,
  teacher_subject_id UUID         NOT NULL REFERENCES teacher_subjects(id)  ON DELETE CASCADE,
  grading_period_id  UUID         NOT NULL REFERENCES grading_periods(id)   ON DELETE CASCADE,
  score              NUMERIC(5,2) CHECK (score BETWEEN 0 AND 100),          -- escala 0-100 GT
  letter_grade       TEXT         CHECK (letter_grade IN ('A','A-','B+','B','B-','C+','C','C-','D+','D','F')),
  grade_type         TEXT         NOT NULL DEFAULT 'period'
    CHECK (grade_type IN ('period', 'exam', 'assignment', 'final')),
  notes              TEXT,
  recorded_by        UUID         REFERENCES profiles(id),
  recorded_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, teacher_subject_id, grading_period_id, grade_type)
);

-- Convierte nota 0-100 a letra GPA (escala estándar americana)
CREATE OR REPLACE FUNCTION score_to_letter(p_score NUMERIC)
RETURNS TEXT AS $$
  SELECT CASE
    WHEN p_score >= 93 THEN 'A'
    WHEN p_score >= 90 THEN 'A-'
    WHEN p_score >= 87 THEN 'B+'
    WHEN p_score >= 83 THEN 'B'
    WHEN p_score >= 80 THEN 'B-'
    WHEN p_score >= 77 THEN 'C+'
    WHEN p_score >= 73 THEN 'C'
    WHEN p_score >= 70 THEN 'C-'
    WHEN p_score >= 67 THEN 'D+'
    WHEN p_score >= 60 THEN 'D'
    ELSE 'F'
  END
$$ LANGUAGE sql IMMUTABLE;

-- ============================================================
-- 9. ASISTENCIA (100% virtual)
--    Estados: connected | absent | excused
--    Sin tardanzas ni campos de asistencia física
-- ============================================================

CREATE TABLE attendance (
  id                 UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id          UUID        NOT NULL REFERENCES schools(id)          ON DELETE CASCADE,
  student_id         UUID        NOT NULL REFERENCES students(id)         ON DELETE CASCADE,
  teacher_subject_id UUID        REFERENCES teacher_subjects(id)          ON DELETE CASCADE,
  section_id         UUID        REFERENCES class_sections(id)            ON DELETE CASCADE,
  date               DATE        NOT NULL,
  status             TEXT        NOT NULL
    CHECK (status IN ('connected', 'absent', 'excused')),
  notes              TEXT,
  recorded_by        UUID        REFERENCES profiles(id),
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, teacher_subject_id, date)
);

-- ============================================================
-- 10. CITAS (con observaciones post-cita)
-- ============================================================

CREATE TABLE appointments (
  id           UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id    UUID        NOT NULL REFERENCES schools(id)  ON DELETE CASCADE,
  student_id   UUID        NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  requested_by UUID        NOT NULL REFERENCES profiles(id), -- padre o maestro que solicita
  assigned_to  UUID        REFERENCES profiles(id),           -- maestro/admin que atiende
  scheduled_at TIMESTAMPTZ,
  status       TEXT        NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled')),
  meeting_type TEXT        CHECK (meeting_type IN ('academic', 'behavioral', 'administrative', 'other')),
  virtual_link TEXT,                                          -- enlace Zoom/Meet para la cita
  reason       TEXT,                                          -- motivo de la solicitud
  observations TEXT,                                          -- notas post-cita (maestro/admin)
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 11. OBSERVACIONES DE ALUMNOS (oficiales, visibilidad controlada)
--     Creadas por maestros o secretaria. Visibles para admin,
--     maestros que enseñan al alumno y tutores del alumno.
-- ============================================================

CREATE TABLE student_observations (
  id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id   UUID        NOT NULL REFERENCES schools(id)  ON DELETE CASCADE,
  student_id  UUID        NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  created_by  UUID        NOT NULL REFERENCES profiles(id),
  category    TEXT        CHECK (category IN ('academic', 'behavioral', 'family', 'medical', 'other')),
  body        TEXT        NOT NULL,
  observed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 12. NOTAS PERSONALES (bitácora privada por usuario)
--     Solo las ve el dueño. Disponible para cualquier rol.
-- ============================================================

CREATE TABLE daily_notes (
  id         UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id  UUID        NOT NULL REFERENCES schools(id)  ON DELETE CASCADE,
  user_id    UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title      TEXT,
  body       TEXT        NOT NULL,
  note_date  DATE        NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 13. COMUNICACIONES
-- ============================================================

CREATE TABLE announcements (
  id           UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id    UUID        NOT NULL REFERENCES schools(id)      ON DELETE CASCADE,
  author_id    UUID        NOT NULL REFERENCES profiles(id),
  title        TEXT        NOT NULL,
  body         TEXT        NOT NULL,
  audience     TEXT        NOT NULL DEFAULT 'all'
    CHECK (audience IN ('all', 'teachers', 'students', 'guardians', 'section')),
  section_id   UUID        REFERENCES class_sections(id),
  pinned       BOOLEAN     NOT NULL DEFAULT false,
  published_at TIMESTAMPTZ,
  expires_at   TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE messages (
  id           UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id    UUID        NOT NULL REFERENCES schools(id)  ON DELETE CASCADE,
  sender_id    UUID        NOT NULL REFERENCES profiles(id),
  recipient_id UUID        NOT NULL REFERENCES profiles(id),
  subject      TEXT,
  body         TEXT        NOT NULL,
  read_at      TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 14. FINANZAS
-- ============================================================

CREATE TABLE fee_structures (
  id          UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id   UUID         NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name        TEXT         NOT NULL,               -- "Colegiatura", "Inscripción", "Actividades"
  description TEXT,
  amount      NUMERIC(10,2) NOT NULL,
  currency    TEXT         NOT NULL DEFAULT 'GTQ',
  frequency   TEXT         NOT NULL DEFAULT 'monthly'
    CHECK (frequency IN ('once', 'monthly', 'quarterly', 'yearly')),
  active      BOOLEAN      NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE invoices (
  id               UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id        UUID         NOT NULL REFERENCES schools(id)        ON DELETE CASCADE,
  student_id       UUID         NOT NULL REFERENCES students(id)       ON DELETE CASCADE,
  fee_structure_id UUID         NOT NULL REFERENCES fee_structures(id),
  academic_year_id UUID         NOT NULL REFERENCES academic_years(id),
  invoice_number   TEXT,                           -- correlativo oficial
  amount           NUMERIC(10,2) NOT NULL,
  due_date         DATE         NOT NULL,
  status           TEXT         NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'paid', 'overdue', 'waived')),
  created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE payments (
  id               UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id        UUID         NOT NULL REFERENCES schools(id)  ON DELETE CASCADE,
  invoice_id       UUID         NOT NULL REFERENCES invoices(id),
  student_id       UUID         NOT NULL REFERENCES students(id),
  amount           NUMERIC(10,2) NOT NULL,
  currency         TEXT         NOT NULL DEFAULT 'GTQ',
  payment_method   TEXT         CHECK (payment_method IN ('cash', 'transfer', 'card', 'cheque', 'online')),
  reference_number TEXT,
  paid_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  received_by      UUID         REFERENCES profiles(id),
  notes            TEXT,
  created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 15. CONDUCTA
-- ============================================================

CREATE TABLE behavior_records (
  id           UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id    UUID        NOT NULL REFERENCES schools(id)  ON DELETE CASCADE,
  student_id   UUID        NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  reported_by  UUID        NOT NULL REFERENCES profiles(id),
  type         TEXT        NOT NULL CHECK (type IN ('positive', 'negative', 'neutral')),
  category     TEXT,                               -- "Disciplina", "Rendimiento", "Reconocimiento"
  description  TEXT        NOT NULL,
  action_taken TEXT,
  occurred_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 16. ÍNDICES
-- ============================================================

CREATE INDEX idx_profiles_school           ON profiles(school_id);
CREATE INDEX idx_user_roles_user           ON user_roles(user_id);
CREATE INDEX idx_user_roles_school         ON user_roles(school_id);
CREATE INDEX idx_students_school           ON students(school_id);
CREATE INDEX idx_enrollments_student       ON enrollments(student_id);
CREATE INDEX idx_enrollments_year          ON enrollments(academic_year_id);
CREATE INDEX idx_class_sections_grade      ON class_sections(grade_level_id);
CREATE INDEX idx_class_sections_year       ON class_sections(academic_year_id);
CREATE INDEX idx_teacher_subjects_teacher  ON teacher_subjects(teacher_id);
CREATE INDEX idx_teacher_subjects_section  ON teacher_subjects(section_id);
CREATE INDEX idx_grades_student            ON grades(student_id);
CREATE INDEX idx_grades_teacher_subject    ON grades(teacher_subject_id);
CREATE INDEX idx_attendance_student        ON attendance(student_id);
CREATE INDEX idx_attendance_date           ON attendance(date);
CREATE INDEX idx_appointments_student      ON appointments(student_id);
CREATE INDEX idx_appointments_assigned_to  ON appointments(assigned_to);
CREATE INDEX idx_student_obs_student       ON student_observations(student_id);
CREATE INDEX idx_student_obs_created_by    ON student_observations(created_by);
CREATE INDEX idx_daily_notes_user          ON daily_notes(user_id);
CREATE INDEX idx_daily_notes_school_date   ON daily_notes(school_id, note_date);
CREATE INDEX idx_invoices_student          ON invoices(student_id);
CREATE INDEX idx_invoices_status           ON invoices(status);
CREATE INDEX idx_payments_invoice          ON payments(invoice_id);
CREATE INDEX idx_payments_student          ON payments(student_id);
CREATE INDEX idx_announcements_school      ON announcements(school_id);
CREATE INDEX idx_messages_recipient        ON messages(recipient_id);

-- ============================================================
-- 17. ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE schools             ENABLE ROW LEVEL SECURITY;
ALTER TABLE plans               ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions       ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles            ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles          ENABLE ROW LEVEL SECURITY;
ALTER TABLE academic_years      ENABLE ROW LEVEL SECURITY;
ALTER TABLE grading_periods     ENABLE ROW LEVEL SECURITY;
ALTER TABLE grade_levels        ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_sections      ENABLE ROW LEVEL SECURITY;
ALTER TABLE subjects            ENABLE ROW LEVEL SECURITY;
ALTER TABLE teacher_subjects    ENABLE ROW LEVEL SECURITY;
ALTER TABLE students            ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments         ENABLE ROW LEVEL SECURITY;
ALTER TABLE guardians           ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_guardians   ENABLE ROW LEVEL SECURITY;
ALTER TABLE grades              ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance          ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments        ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_observations ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_notes         ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements       ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages            ENABLE ROW LEVEL SECURITY;
ALTER TABLE fee_structures      ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices            ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments            ENABLE ROW LEVEL SECURITY;
ALTER TABLE behavior_records    ENABLE ROW LEVEL SECURITY;

-- ── Funciones auxiliares ─────────────────────────────────────

-- plpgsql impide que el planificador inlinee la función en el contexto
-- de evaluación de RLS, evitando recursión infinita en profiles.
-- SECURITY DEFINER + propietario postgres (superuser) = bypass RLS interno.
CREATE OR REPLACE FUNCTION auth_user_school_id()
RETURNS UUID AS $$
DECLARE
  v_school_id UUID;
BEGIN
  SELECT school_id INTO v_school_id
  FROM public.profiles
  WHERE id = auth.uid();
  RETURN v_school_id;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION auth_user_role()
RETURNS app_role AS $$
DECLARE
  v_role app_role;
BEGIN
  SELECT role INTO v_role
  FROM public.user_roles
  WHERE user_id   = auth.uid()
    AND school_id = auth_user_school_id()
  ORDER BY
    CASE role
      WHEN 'super_admin'  THEN 1
      WHEN 'school_admin' THEN 2
      WHEN 'secretary'    THEN 3
      WHEN 'teacher'      THEN 4
      WHEN 'student'      THEN 5
      WHEN 'guardian'     THEN 6
    END
  LIMIT 1;
  RETURN v_role;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- ── Aislamiento por escuela (tablas sin lógica de rol extra) ─

CREATE POLICY "school_isolation" ON profiles
  FOR ALL USING (school_id = auth_user_school_id());

CREATE POLICY "school_isolation" ON user_roles
  FOR ALL USING (school_id = auth_user_school_id());

CREATE POLICY "school_isolation" ON academic_years
  FOR ALL USING (school_id = auth_user_school_id());

CREATE POLICY "school_isolation" ON grading_periods
  FOR ALL USING (school_id = auth_user_school_id());

CREATE POLICY "school_isolation" ON grade_levels
  FOR ALL USING (school_id = auth_user_school_id());

CREATE POLICY "school_isolation" ON class_sections
  FOR ALL USING (school_id = auth_user_school_id());

CREATE POLICY "school_isolation" ON subjects
  FOR ALL USING (school_id = auth_user_school_id());

CREATE POLICY "school_isolation" ON teacher_subjects
  FOR ALL USING (school_id = auth_user_school_id());

CREATE POLICY "school_isolation" ON students
  FOR ALL USING (school_id = auth_user_school_id());

CREATE POLICY "school_isolation" ON enrollments
  FOR ALL USING (school_id = auth_user_school_id());

CREATE POLICY "school_isolation" ON guardians
  FOR ALL USING (school_id = auth_user_school_id());

CREATE POLICY "school_isolation" ON student_guardians
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM students s
      WHERE s.id = student_guardians.student_id
        AND s.school_id = auth_user_school_id()
    )
  );

CREATE POLICY "school_isolation" ON grades
  FOR ALL USING (school_id = auth_user_school_id());

CREATE POLICY "school_isolation" ON attendance
  FOR ALL USING (school_id = auth_user_school_id());

CREATE POLICY "school_isolation" ON announcements
  FOR ALL USING (school_id = auth_user_school_id());

CREATE POLICY "school_isolation" ON behavior_records
  FOR ALL USING (school_id = auth_user_school_id());

CREATE POLICY "school_isolation" ON fee_structures
  FOR ALL USING (school_id = auth_user_school_id());

CREATE POLICY "school_isolation" ON invoices
  FOR ALL USING (school_id = auth_user_school_id());

CREATE POLICY "school_isolation" ON payments
  FOR ALL USING (school_id = auth_user_school_id());

-- Suscripciones: lectura para cualquier miembro del colegio;
-- escritura solo para super_admin
CREATE POLICY "subscriptions_read" ON subscriptions
  FOR SELECT USING (school_id = auth_user_school_id());

CREATE POLICY "subscriptions_super_admin" ON subscriptions
  FOR ALL USING (auth_user_role() = 'super_admin')
  WITH CHECK (auth_user_role() = 'super_admin');

-- Plans: lectura pública (no requiere autenticación)
CREATE POLICY "plans_public_read" ON plans
  FOR SELECT USING (true);

-- ── Citas ────────────────────────────────────────────────────

-- Admin / secretaria: acceso completo
CREATE POLICY "appt_admin_all" ON appointments
  FOR ALL
  USING (
    school_id = auth_user_school_id()
    AND auth_user_role() IN ('super_admin', 'school_admin', 'secretary')
  )
  WITH CHECK (
    school_id = auth_user_school_id()
    AND auth_user_role() IN ('super_admin', 'school_admin', 'secretary')
  );

-- Maestros: ven las que les asignaron o ellos solicitaron
CREATE POLICY "appt_teacher_select" ON appointments
  FOR SELECT
  USING (
    school_id = auth_user_school_id()
    AND auth_user_role() = 'teacher'
    AND (assigned_to = auth.uid() OR requested_by = auth.uid())
  );

-- Maestros: pueden solicitar citas
CREATE POLICY "appt_teacher_insert" ON appointments
  FOR INSERT
  WITH CHECK (
    school_id    = auth_user_school_id()
    AND auth_user_role() = 'teacher'
    AND requested_by = auth.uid()
  );

-- Maestros: pueden registrar observaciones en citas que atienden
CREATE POLICY "appt_teacher_update" ON appointments
  FOR UPDATE
  USING (
    school_id   = auth_user_school_id()
    AND auth_user_role() = 'teacher'
    AND assigned_to = auth.uid()
  )
  WITH CHECK (school_id = auth_user_school_id());

-- Tutores: ven citas de sus alumnos
CREATE POLICY "appt_guardian_select" ON appointments
  FOR SELECT
  USING (
    school_id = auth_user_school_id()
    AND auth_user_role() = 'guardian'
    AND EXISTS (
      SELECT 1 FROM student_guardians sg
      JOIN guardians g ON g.id = sg.guardian_id
      WHERE sg.student_id = appointments.student_id
        AND g.profile_id  = auth.uid()
    )
  );

-- Tutores: pueden solicitar citas para sus alumnos
CREATE POLICY "appt_guardian_insert" ON appointments
  FOR INSERT
  WITH CHECK (
    school_id    = auth_user_school_id()
    AND auth_user_role() = 'guardian'
    AND requested_by = auth.uid()
    AND EXISTS (
      SELECT 1 FROM student_guardians sg
      JOIN guardians g ON g.id = sg.guardian_id
      WHERE sg.student_id = appointments.student_id
        AND g.profile_id  = auth.uid()
    )
  );

-- ── Observaciones de alumnos ─────────────────────────────────

-- Admin / secretaria: acceso completo
CREATE POLICY "obs_admin_all" ON student_observations
  FOR ALL
  USING (
    school_id = auth_user_school_id()
    AND auth_user_role() IN ('super_admin', 'school_admin', 'secretary')
  )
  WITH CHECK (
    school_id = auth_user_school_id()
    AND auth_user_role() IN ('super_admin', 'school_admin', 'secretary')
  );

-- Maestros: ven las propias o las de alumnos a quienes enseñan
CREATE POLICY "obs_teacher_select" ON student_observations
  FOR SELECT
  USING (
    school_id = auth_user_school_id()
    AND auth_user_role() = 'teacher'
    AND (
      created_by = auth.uid()
      OR EXISTS (
        SELECT 1
        FROM enrollments e
        JOIN teacher_subjects ts ON ts.section_id   = e.section_id
                                AND ts.school_id    = e.school_id
        WHERE e.student_id  = student_observations.student_id
          AND ts.teacher_id = auth.uid()
          AND e.school_id   = auth_user_school_id()
          AND e.status      = 'active'
      )
    )
  );

-- Maestros: insertar (solo se pueden asignar como autor)
CREATE POLICY "obs_teacher_insert" ON student_observations
  FOR INSERT
  WITH CHECK (
    school_id  = auth_user_school_id()
    AND auth_user_role() = 'teacher'
    AND created_by = auth.uid()
  );

-- Maestros: editar solo sus propias observaciones
CREATE POLICY "obs_teacher_update" ON student_observations
  FOR UPDATE
  USING (
    school_id  = auth_user_school_id()
    AND auth_user_role() = 'teacher'
    AND created_by = auth.uid()
  )
  WITH CHECK (
    school_id  = auth_user_school_id()
    AND created_by = auth.uid()
  );

-- Tutores: solo lectura de sus alumnos
CREATE POLICY "obs_guardian_select" ON student_observations
  FOR SELECT
  USING (
    school_id = auth_user_school_id()
    AND auth_user_role() = 'guardian'
    AND EXISTS (
      SELECT 1 FROM student_guardians sg
      JOIN guardians g ON g.id = sg.guardian_id
      WHERE sg.student_id = student_observations.student_id
        AND g.profile_id  = auth.uid()
    )
  );

-- ── Notas personales ─────────────────────────────────────────

-- Solo el propietario: acceso completo
CREATE POLICY "daily_notes_owner_all" ON daily_notes
  FOR ALL
  USING  (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ── Mensajes ─────────────────────────────────────────────────

-- Solo emisor y receptor ven sus mensajes
CREATE POLICY "messages_participant" ON messages
  FOR ALL
  USING (
    school_id = auth_user_school_id()
    AND (sender_id = auth.uid() OR recipient_id = auth.uid())
  );

-- ============================================================
-- 18. TRIGGERS updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_schools_updated_at
  BEFORE UPDATE ON schools FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_subscriptions_updated_at
  BEFORE UPDATE ON subscriptions FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_students_updated_at
  BEFORE UPDATE ON students FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_grades_updated_at
  BEFORE UPDATE ON grades FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_announcements_updated_at
  BEFORE UPDATE ON announcements FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_appointments_updated_at
  BEFORE UPDATE ON appointments FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_student_observations_updated_at
  BEFORE UPDATE ON student_observations FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_daily_notes_updated_at
  BEFORE UPDATE ON daily_notes FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_invoices_updated_at
  BEFORE UPDATE ON invoices FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- 19. DATOS INICIALES
-- ============================================================

INSERT INTO plans (name, max_students, max_teachers, price_monthly, price_yearly, features) VALUES
  ('Trial',    50,   10,  0,    0,    '{"modules": ["students", "grades", "attendance"]}'),
  ('Básico',   200,  30,  49,   490,  '{"modules": ["students", "grades", "attendance", "communications"]}'),
  ('Estándar', 800,  80,  99,   990,  '{"modules": ["students", "grades", "attendance", "communications", "finance"]}'),
  ('Premium',  NULL, NULL, 199, 1990, '{"modules": ["all"]}');
