-- ═══════════════════════════════════════════════════════════════════════════════
-- MIGRACIÓN: 20260430_add_widgets_system_and_billing_roles
-- Propósito: Sistema de widgets para dashboard + roles de billing y staff
-- Tablas nuevas: widgets, school_widgets, user_widget_preferences
-- Roles nuevos: cashier, accounting, staff
-- ═══════════════════════════════════════════════════════════════════════════════


-- ─────────────────────────────────────────────────────────────────────────────
-- 1. EXTENDER ENUM app_role
-- ─────────────────────────────────────────────────────────────────────────────

-- Roles de billing (Feature B — PROJECT_BRIEF §10)
ALTER TYPE app_role ADD VALUE IF NOT EXISTS 'cashier';
ALTER TYPE app_role ADD VALUE IF NOT EXISTS 'accounting';

-- Personal no-docente no-secretarial (coordinadores, psicólogos, IT, etc.)
ALTER TYPE app_role ADD VALUE IF NOT EXISTS 'staff';


-- ─────────────────────────────────────────────────────────────────────────────
-- 2. TABLA: widgets
--    Catálogo global de widgets disponibles en la plataforma.
--    No tiene school_id — es un catálogo compartido entre todos los tenants.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE widgets (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  code            TEXT        UNIQUE NOT NULL,
  name_es         TEXT        NOT NULL,
  name_en         TEXT        NOT NULL,
  description_es  TEXT,
  description_en  TEXT,
  icon            TEXT,
  allowed_roles   TEXT[]      NOT NULL,
  default_size    TEXT        DEFAULT 'medium' CHECK (default_size IN ('small', 'medium', 'large')),
  min_plan        TEXT        DEFAULT 'trial'  CHECK (min_plan  IN ('trial', 'basico', 'estandar', 'premium')),
  is_active       BOOLEAN     DEFAULT true,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE widgets ENABLE ROW LEVEL SECURITY;

-- SELECT abierto a cualquier usuario autenticado (catálogo de solo lectura)
CREATE POLICY "widgets_select_authenticated"
  ON widgets FOR SELECT
  TO authenticated
  USING (is_active = true);


-- ─────────────────────────────────────────────────────────────────────────────
-- 3. TABLA: school_widgets
--    Qué widgets ha activado cada colegio.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE school_widgets (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id   UUID        NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  widget_id   UUID        NOT NULL REFERENCES widgets(id) ON DELETE CASCADE,
  is_enabled  BOOLEAN     DEFAULT true,
  enabled_by  UUID        REFERENCES auth.users(id),
  enabled_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(school_id, widget_id)
);

CREATE INDEX idx_school_widgets_school_id ON school_widgets(school_id);

ALTER TABLE school_widgets ENABLE ROW LEVEL SECURITY;

-- SELECT: usuario pertenece al colegio
CREATE POLICY "school_widgets_select_own_school"
  ON school_widgets FOR SELECT
  TO authenticated
  USING (
    school_id IN (
      SELECT school_id FROM user_roles WHERE user_id = auth.uid()
    )
  );

-- INSERT: solo school_admin o super_admin
CREATE POLICY "school_widgets_insert_admin"
  ON school_widgets FOR INSERT
  TO authenticated
  WITH CHECK (
    school_id IN (
      SELECT school_id FROM user_roles
      WHERE user_id = auth.uid()
        AND role IN ('school_admin', 'super_admin')
    )
  );

-- UPDATE: solo school_admin o super_admin
CREATE POLICY "school_widgets_update_admin"
  ON school_widgets FOR UPDATE
  TO authenticated
  USING (
    school_id IN (
      SELECT school_id FROM user_roles
      WHERE user_id = auth.uid()
        AND role IN ('school_admin', 'super_admin')
    )
  );


-- ─────────────────────────────────────────────────────────────────────────────
-- 4. TABLA: user_widget_preferences
--    Orden y visibilidad personalizada de widgets por usuario.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE user_widget_preferences (
  id            UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID    NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  school_id     UUID    NOT NULL REFERENCES schools(id)    ON DELETE CASCADE,
  widget_id     UUID    NOT NULL REFERENCES widgets(id)    ON DELETE CASCADE,
  display_order INTEGER NOT NULL DEFAULT 0,
  is_visible    BOOLEAN DEFAULT true,
  updated_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, school_id, widget_id)
);

CREATE INDEX idx_user_widget_prefs_user_id   ON user_widget_preferences(user_id);
CREATE INDEX idx_user_widget_prefs_school_id ON user_widget_preferences(school_id);

ALTER TABLE user_widget_preferences ENABLE ROW LEVEL SECURITY;

-- SELECT/INSERT/UPDATE: solo el propio usuario sobre sus propias preferencias
CREATE POLICY "uwp_select_own"
  ON user_widget_preferences FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "uwp_insert_own"
  ON user_widget_preferences FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "uwp_update_own"
  ON user_widget_preferences FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());


-- ─────────────────────────────────────────────────────────────────────────────
-- 5. SEED: widget de bienvenida
--    Visible para todos los roles. Tamaño medium. Disponible desde plan trial.
-- ─────────────────────────────────────────────────────────────────────────────

INSERT INTO widgets (
  code, name_es, name_en,
  description_es, description_en,
  icon, allowed_roles, default_size, min_plan
) VALUES (
  'welcome',
  'Bienvenida',
  'Welcome',
  'Saludo personalizado con nombre del usuario y nombre del colegio.',
  'Personalized greeting with the user''s name and school name.',
  'Hand',
  ARRAY['super_admin', 'school_admin', 'secretary', 'staff', 'teacher',
        'student', 'guardian', 'cashier', 'accounting'],
  'medium',
  'trial'
);
