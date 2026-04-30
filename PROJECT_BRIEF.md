# Corenza — Project Brief

> **Cómo usar este archivo:** Si eres Claude Code, lee este documento al inicio de cada sesión para tener contexto completo del proyecto. Aquí está el "por qué" y el "qué"; las reglas técnicas están en `CLAUDE.md`.

---

## 1. ¿Qué es Corenza?

**Corenza** es un SaaS de gestión escolar **multi-tenant** que reemplaza a OpenSIS, dirigido a colegios **100% virtuales** (americanos y guatemaltecos).

- **Tipo de producto:** Software-as-a-Service B2B vertical (educación).
- **Comprador objetivo:** Directores, dueños y administradores de colegios virtuales.
- **Reemplaza a:** OpenSIS, PowerSchool, FACTS, Blackbaud (en su segmento).
- **Diferenciadores clave:**
  - 100% virtual nativo (sin asistencia física, sin tardanzas).
  - Bilingüe inglés/español desde el inicio (no traducción posterior).
  - Soporte dual de calificaciones americano (A/B/C/GPA) y guatemalteco (0-100).
  - Soporte dual de moneda USD y GTQ.
  - Multi-tenant real con aislamiento por `school_id` y RLS en todas las tablas.
  - UI moderna (Next.js 14 + Tailwind), no la interfaz vieja típica del sector.

---

## 2. Stack técnico

| Capa | Tecnología |
|---|---|
| Frontend | Next.js 14 (App Router) + TypeScript |
| Estilos | Tailwind CSS |
| Backend / DB | Supabase (PostgreSQL) |
| Autenticación | Supabase Auth |
| Hosting | Vercel |
| Dominio | corenza.io |

**DNS configurado en Namecheap:**
- A record `@` → `76.76.21.21`
- CNAME `www` → `cname.vercel-dns.com`

---

## 3. Posicionamiento estratégico

**Corenza es producto independiente que vende a múltiples colegios.**

- Es propiedad de la red ISEA (sombrilla institucional).
- Woodbridge Academy (Newport Beach, CA — colegio propio) es uno de los 3 primeros clientes piloto.
- Otros 2 colegios serán los siguientes clientes.
- A largo plazo, debe poder venderse a colegios fuera de la red ISEA.

**Implicación crítica:** La marca de Corenza NO debe verse como "el sistema interno de Woodbridge". Debe pararse sola frente a un colegio que nunca oyó hablar de ISEA. Por eso la identidad visual es deliberadamente distinta de Woodbridge (azul navy + dorado mostaza) e ISEA (rojo terracota + negro).

---

## 4. Identidad de marca

### Nombre
**Corenza** — nombre inventado de inspiración italiana. Juego de palabras:
- **Cor** (latín/italiano: corazón) → calidez humana.
- **Core** (inglés: núcleo, sistema central) → infraestructura técnica.
- **-enza** (sufijo italiano elegante: Fiorenza, Vincenza) → sofisticación.

### Taglines
- **Español:** "El corazón de tu colegio"
- **Inglés:** "The core of your school" *(juego de palabras Core+nza)*
- **Italiano (slogan secundario):** "Educazione con anima"

### Paleta oficial
| Color | HEX | Uso |
|---|---|---|
| Esmeralda profundo | `#0F4438` | Color principal, wordmark, elementos primarios UI |
| Cobre | `#B87333` | Acento metálico, CTAs, highlights |
| Verde claro | `#4A8A78` | Color secundario, estados hover |
| Crema | `#F0F4F0` | Fondo neutro, espacios en blanco |

### Personalidad
Premium italiano cálido · Educativo institucional · Biblioteca toscana moderna · Boutique académica.

**Inspiración visual:** Bottega Veneta, Adelphi/Einaudi (editoriales italianas), hoteles boutique toscanos, papelería de lujo florentina.

### Tipografía
- **Marketing / branding:** Serif italiana cursiva (Cormorant Garamond, Bodoni Moda, Playfair Display).
- **Producto / UI:** Sans serif moderna (Inter, DM Sans, system fonts).

### Decisión sobre el logo
- **Fase 1 (ahora):** Wordmark provisional sin símbolo. Foco en construir la plataforma.
- **Fase 2 (cuando la plataforma funcione):** Logo definitivo con símbolo abstracto/geométrico.
- **Restricción explícita:** El símbolo NO puede ser botánico (hojas, brotes, flores) — hace parecer empresa agrícola, no SaaS educativo.
- **Herramientas para Fase 2:** BrandCrowd, Looka, Canva Pro, o diseñador profesional con brief.

---

## 5. Módulos requeridos (alcance funcional)

### School
- School Information
- Marking Periods (Q1-Q4 o semestres)
- Calendars (calendario académico)
- Notices (avisos internos)
- Mental Health Info

### Admissions
- Dashboard de admisiones
- Application Forms (configurables)
- Applicants (status: Applied / Accepted / Enrolled / Archived)
- Email Templates
- Applicant Fields (configurables)
- Process Steps

### Students
- Student Information (perfil completo)
- Group Assign Student Info
- Re-enroll Student
- Student Fields (configurables)
- Enrollment Codes

### Parents
- Parent Information
- Vinculación padre/madre-hijo (puede haber ambos progenitores)

### Staff
- Staff Info
- Teacher Functions (permisos por maestro)
- Staff Fields (configurables)

### Courses
- Course Manager
- Course Catalog
- Course Request
- Student Course Requests

### Scheduling
- Horarios virtuales (sin salones físicos)
- Asignación de maestros a secciones

### Grades
- Administration (configuración)
- Progress Reports
- Report Cards (PDF generables)
- Certificates (PDF)
- Transcripts (PDF — formato americano y guatemalteco)
- Report Card Grade Scale (A/B/C/D/F y 0-100)
- Report Card Comments
- Honor Roll
- Historical Marking Periods
- Standards Based Grades
- Efforts Based Grades
- Graduation Requirements / Degree Audit
- Grading Preferences

### Attendance
- Solo virtual: Conectado / Ausente / Con Excusa
- NO tardanzas (es 100% online)
- Attendance Codes (configurables)
- Reportes de asistencia

### Behavior & Discipline
- Behavior Referrals
- Behavior Fields (configurables)
- Widget en dashboard

### Billing & Fees
- Fee Structures por programa/grado
- Fee Types múltiples por estudiante: Annual Enrollment, K5 Tuition, K6-K12 Tuition, Testing Services, Apostille, Invoice, Subscription
- Invoices (PDF editables)
- Payments
- Recibos (PDF)
- General Ledger / G/L Accounts
- Payment Methods
- Online Payment Acceptance
- Default Currency (USD y GTQ)
- Online Subscriptions
- Dashboard de billing: Total Collection YTD, Collected/Overdue/To-be-collected, Total Collection by Fee Type

### LMS
- Get LMS Data (integración Canvas, Google Classroom)
- LMS Settings

### Communication
- Mensajes padre-maestro
- Announcements
- Email Templates
- Default Communication Settings

### Lesson Plan Library
- Biblioteca de planes de clase por materia

### Reports
- Módulo completo de reportes exportables

### Settings (todo configurable por colegio)
School · Student · Staff · Attendance · Grades · Administration · List of Values · SSO · Billing · Admissions

### Super Admin (solo el dueño de Corenza)
- Ver todos los colegios
- Crear nuevos colegios
- Asignar planes (Trial, Básico, Estándar, Premium)
- Gestionar suscripciones y cobros a colegios

### Características adicionales
- **Daily Notes:** bitácora privada opcional por usuario (no obligatoria).
- **Student Observations:** notas oficiales en expediente del alumno.
- **Appointments:** citas formales padre/alumno con maestro o secretaría.

---

## 6. Reglas de negocio críticas

1. **Sistema 100% virtual** — sin asistencia física ni tardanzas.
2. **Multi-tenant estricto** — cada colegio ve SOLO sus datos. `school_id` en TODAS las tablas.
3. **RLS habilitado** en todas las tablas de Supabase.
4. **Documentos PDF generables:** transcripts, report cards, certificates, invoices, recibos.
5. **Dual currency:** USD y GTQ.
6. **Dual grading:** americano (A/B/C/GPA) y guatemalteco (0-100).
7. **Registro solo por invitación** del admin. Nunca abierto al público.

---

## 7. Equipo de validación honesta

Las decisiones de marca y producto se validan con dos personas de confianza que dan feedback directo y sin filtro:

- **Abner** — amigo cercano, da feedback honesto sobre decisiones creativas y de comunicación.
- **Papá del usuario** — empresario con experiencia, da feedback estratégico de negocio.

Ambos contradijeron al usuario en momentos clave (ej. el papá detectó que el logo con hojas parecía empresa agrícola). Sus opiniones tienen peso real en las decisiones.

---

## 8. Estado actual del proyecto

- ✅ Dominio `corenza.io` desplegado en Vercel con DNS configurado.
- ✅ Brief de marca consolidado (este documento).
- ✅ Decisión: logo definitivo en Fase 2.
- 🟡 Schema de Supabase: existe schema base aplicado, pero faltan módulos por mapear y crear.
- ⬜ Módulos del producto: pendientes de desarrollo según prioridad.

---

## 9. Próximos pasos sugeridos

1. **Auditoría del schema actual** vs los módulos listados en sección 5. Identificar qué tablas existen y qué faltan.
2. **Generar SQL para tablas faltantes** (sin ejecutar — primero plan, luego ejecución).
3. **Priorizar módulos** según valor para los 3 colegios piloto. Sugerencia inicial: Students → Admissions → Grades → Attendance → Billing.
4. **Implementar módulo por módulo** con tests, RLS y multi-tenancy desde el inicio.
5. **Wordmark provisional** en el sitio mientras se construye la plataforma.

---

*Última actualización: Abril 2026*

---

## 10. Features diferenciadores prioritarios

Estas 5 features fueron identificadas como diferenciadores críticos vs OpenSIS y SIS americanos genéricos. Reflejan necesidades reales del mercado guatemalteco/latinoamericano y de seguridad institucional.

### Feature A — Cobros offline (Billing)

Permitir registrar pagos por métodos no-Stripe: efectivo, depósito bancario, transferencia, cheque.

**Campos requeridos:** método de pago, número de boleta o transferencia, banco emisor, fecha, monto, comprobante adjunto (imagen/PDF).

Generar recibo PDF oficial independiente del método de pago.

**Razón:** muchos clientes están en países sin Stripe o son familias de escasos recursos sin banca digital.

---

### Feature B — Roles granulares de billing

Crear nuevos roles además de los existentes:

- **`cashier`** (caja/cobros): registra pagos manualmente, genera recibos. NO modifica tarifas ni configuraciones.
- **`accounting`** (contabilidad): verifica y concilia pagos, genera reportes financieros, puede aprobar o rechazar pagos pendientes.

**Estados de pago:** `pending_verification` (registrado por cashier) → `verified` (aprobado por accounting) → `rejected`.

Solo perfiles autorizados pueden registrar pagos manuales offline. Auditoría completa de quién registró/aprobó cada pago.

---

### Feature C — Campos críticos vs no-críticos

Sistema de niveles de edición para evitar fraude pero permitir corregir errores humanos:

- **Campos críticos** (DPI, fecha de nacimiento, ID oficial): solo editables por `school_admin` con justificación obligatoria registrada.
- **Campos no-críticos** (nombre con typo, dirección, teléfono): editables por roles autorizados sin restricción especial.

Tabla `field_change_audit_log` con: `school_id`, `user_id`, `entity_type`, `entity_id`, `field_name`, `old_value`, `new_value`, `reason`, `changed_at`.

---

### Feature D — RBAC flexible multi-rol

Cada usuario puede tener múltiples roles simultáneos asignados. Ejemplo: la secretaria con info@woodbridge.gt puede ser `cashier` Y `accounting` al mismo tiempo. Roles asignables y revocables en cualquier momento por `super_admin` o `school_admin`.

Tabla `user_roles` many-to-many con: `user_id`, `role_id`, `school_id`, `granted_by`, `granted_at`, `expires_at` (NULL = permanente), `is_active`, `reason`, `revoked_at`.

---

### Feature E — Permisos temporales y auditoría de accesos

- **Permisos temporales:** roles con `expires_at` para acceso automático limitado (ej. ayudante en temporada de matrícula). Pasada la fecha, el sistema marca `is_active = false` automáticamente.
- **Suspender sin borrar:** flag `is_active` para revocar acceso sin eliminar la cuenta del usuario ni perder su historial.
- **Audit log de accesos:** tabla `access_audit_log` con `user_id`, `action`, `entity_type`, `entity_id`, `ip_address`, `created_at`. Registra logins, vistas a información sensible (pagos, expedientes), modificaciones, etc.

Diseñado pensando en seguridad institucional, trazabilidad ante auditorías, y flexibilidad operativa real (gente que ayuda temporal, secretarias con múltiples funciones, etc.).
