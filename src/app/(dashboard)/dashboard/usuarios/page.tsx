import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase-server'
import InviteForm from './InviteForm'
import { inviteUser } from './actions'

const ROL_LABELS: Record<string, string> = {
  super_admin:  'Super Admin',
  school_admin: 'Administrador',
  secretary:    'Secretaria',
  teacher:      'Maestro',
  student:      'Alumno',
  guardian:     'Tutor',
}

// Roles que cada invitador puede asignar
const INVITABLE_BY: Record<string, string[]> = {
  super_admin:  ['school_admin', 'secretary', 'teacher', 'student', 'guardian'],
  school_admin: ['secretary', 'teacher', 'student', 'guardian'],
  secretary:    ['teacher', 'student', 'guardian'],
}

export default async function UsuariosPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/login')

  const { data: roleRow } = await supabase
    .from('user_roles')
    .select('role')
    .eq('user_id', user.id)
    .limit(1)
    .maybeSingle()

  const currentRole = roleRow?.role ?? ''

  if (!INVITABLE_BY[currentRole]) redirect('/dashboard')

  const invitableRoles = INVITABLE_BY[currentRole]

  // Lista de usuarios del colegio con sus roles
  const { data: usuarios } = await supabase
    .from('profiles')
    .select('id, first_name, last_name, active, user_roles(role)')
    .order('last_name', { ascending: true })

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-2xl font-bold text-slate-900">Usuarios</h1>
        <p className="mt-1 text-sm text-slate-500">
          Invita y gestiona los usuarios de tu colegio. El registro solo es por invitación.
        </p>
      </div>

      {/* Formulario de invitación */}
      <div className="rounded-2xl bg-white shadow-sm ring-1 ring-slate-200 p-6">
        <h2 className="text-base font-semibold text-slate-800 mb-5">
          Invitar usuario
        </h2>
        <InviteForm roles={invitableRoles} action={inviteUser} />
      </div>

      {/* Tabla de usuarios */}
      <div className="rounded-2xl bg-white shadow-sm ring-1 ring-slate-200 overflow-hidden">
        <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
          <h2 className="text-base font-semibold text-slate-800">
            Usuarios registrados
          </h2>
          <span className="text-sm text-slate-400">
            {usuarios?.length ?? 0} {(usuarios?.length ?? 0) === 1 ? 'usuario' : 'usuarios'}
          </span>
        </div>

        {!usuarios?.length ? (
          <p className="px-6 py-10 text-sm text-slate-400 text-center">
            No hay usuarios aún. Usa el formulario de arriba para invitar al primero.
          </p>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-slate-100">
              <thead className="bg-slate-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wide">
                    Nombre
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wide">
                    Rol
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wide">
                    Estado
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 bg-white">
                {usuarios.map((u) => {
                  const roles = u.user_roles as { role: string }[] | null
                  const roleName = roles?.[0]?.role ?? ''
                  return (
                    <tr key={u.id} className="hover:bg-slate-50 transition-colors">
                      <td className="px-6 py-4 text-sm font-medium text-slate-900 whitespace-nowrap">
                        {u.first_name} {u.last_name}
                      </td>
                      <td className="px-6 py-4 text-sm text-slate-600 whitespace-nowrap">
                        {ROL_LABELS[roleName] ?? (roleName || '—')}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${
                          u.active
                            ? 'bg-green-50 text-green-700'
                            : 'bg-slate-100 text-slate-500'
                        }`}>
                          {u.active ? 'Activo' : 'Inactivo'}
                        </span>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  )
}
