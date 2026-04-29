import { createClient } from '@/lib/supabase-server'

const ROLE_LABELS: Record<string, string> = {
  'super-admin': 'Super Administrador',
  admin:         'Administrador',
  secretaria:    'Secretaria',
  maestro:       'Maestro',
  alumno:        'Alumno',
  tutor:         'Tutor',
  portal:        'Portal',
}

export default async function RoleDashboardPage({
  params,
}: {
  params: Promise<{ role: string }>
}) {
  const { role } = await params
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  const { data: profile } = await supabase
    .from('profiles')
    .select('first_name')
    .eq('id', user!.id)
    .single()

  const label = ROLE_LABELS[role] ?? role

  return (
    <div>
      <h1 className="text-2xl font-bold text-slate-900">
        Bienvenido{profile?.first_name ? `, ${profile.first_name}` : ''}
      </h1>
      <p className="mt-1 text-slate-500 text-sm">
        Panel de {label} — en construcción
      </p>
    </div>
  )
}
