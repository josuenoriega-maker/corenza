-- ============================================================
-- CORENZA — Reset limpio
-- Ejecutar ANTES de schema.sql para limpiar estado anterior.
-- ============================================================

-- Tablas (CASCADE resuelve dependencias entre FK)
DROP TABLE IF EXISTS public.behavior_records       CASCADE;
DROP TABLE IF EXISTS public.payments               CASCADE;
DROP TABLE IF EXISTS public.invoices               CASCADE;
DROP TABLE IF EXISTS public.fee_structures         CASCADE;
DROP TABLE IF EXISTS public.messages               CASCADE;
DROP TABLE IF EXISTS public.announcements          CASCADE;
DROP TABLE IF EXISTS public.daily_notes            CASCADE;
DROP TABLE IF EXISTS public.student_observations   CASCADE;
DROP TABLE IF EXISTS public.appointments           CASCADE;
DROP TABLE IF EXISTS public.attendance             CASCADE;
DROP TABLE IF EXISTS public.grades                 CASCADE;
DROP TABLE IF EXISTS public.teacher_subjects       CASCADE;
DROP TABLE IF EXISTS public.enrollments            CASCADE;
DROP TABLE IF EXISTS public.student_guardians      CASCADE;
DROP TABLE IF EXISTS public.guardians              CASCADE;
DROP TABLE IF EXISTS public.subjects               CASCADE;
DROP TABLE IF EXISTS public.class_sections         CASCADE;
DROP TABLE IF EXISTS public.grade_levels           CASCADE;
DROP TABLE IF EXISTS public.students               CASCADE;
DROP TABLE IF EXISTS public.grading_periods        CASCADE;
DROP TABLE IF EXISTS public.academic_years         CASCADE;
DROP TABLE IF EXISTS public.user_roles             CASCADE;
DROP TABLE IF EXISTS public.profiles               CASCADE;
DROP TABLE IF EXISTS public.subscriptions          CASCADE;
DROP TABLE IF EXISTS public.plans                  CASCADE;
DROP TABLE IF EXISTS public.schools                CASCADE;

-- Tipos personalizados
DROP TYPE IF EXISTS public.app_role CASCADE;

-- Funciones
DROP FUNCTION IF EXISTS public.auth_user_school_id()       CASCADE;
DROP FUNCTION IF EXISTS public.auth_user_role()            CASCADE;
DROP FUNCTION IF EXISTS public.score_to_letter(NUMERIC)    CASCADE;
DROP FUNCTION IF EXISTS public.set_updated_at()            CASCADE;
