<!-- BEGIN:nextjs-agent-rules -->
# This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` before writing any code. Heed deprecation notices.
<!-- END:nextjs-agent-rules -->

---

# Reglas técnicas no negociables

1. **Multi-tenancy obligatorio.** Toda tabla nueva debe incluir `school_id UUID NOT NULL` y políticas RLS desde el momento de creación. Sin excepciones.

2. **TypeScript estricto.** `strict: true` en `tsconfig.json`. No usar `any` salvo casos justificados con comentario explicando el porqué.

3. **Tailwind puro.** No instalar shadcn, Material UI, Chakra ni ninguna UI library sin pedir permiso explícito al usuario primero.

4. **Dual currency / dual grading.** Cualquier feature de billing debe contemplar USD y GTQ. Cualquier feature de calificaciones debe contemplar A-F/GPA y escala 0-100.

5. **PDF desde el día 1.** Transcripts, report cards, certificates, invoices y recibos deben incluir exportación PDF en el mismo momento en que se implementa la feature.

6. **Sistema 100% virtual.** No implementar asistencia física, tardanzas ni salones físicos. Si se solicita alguno de estos, alertar al usuario antes de proceder.

7. **Migraciones destructivas requieren confirmación.** Antes de ejecutar `DROP`, `TRUNCATE`, o `ALTER ... DROP COLUMN`, mostrar el SQL completo al usuario y esperar aprobación explícita.

8. **Registro solo por invitación.** Nunca habilitar registro público de usuarios. El acceso al sistema es siempre mediante invitación del admin del colegio.

9. **Commits en inglés con Conventional Commits.** Usar prefijos: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`.

10. **Antes de schema changes: plan primero.** Mostrar el SQL completo al usuario, esperar aprobación, y solo después aplicar los cambios en Supabase.
