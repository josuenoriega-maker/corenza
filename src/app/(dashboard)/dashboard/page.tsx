import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase-server'

const ROLE_ROUTES: Record<string, string> = {
  super_admin:  '/dashboard/super-admin',
  school_admin: '/dashboard/admin',
  secretary:    '/dashboard/secretaria',
  teacher:      '/dashboard/maestro',
  student:      '/dashboard/alumno',
  guardian:     '/dashboard/tutor',
}

export default async function DashboardPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) redirect('/login')

  const { data: roleRow } = await supabase
    .from('user_roles')
    .select('role')
    .eq('user_id', user.id)
    .limit(1)
    .maybeSingle()

  const target = roleRow?.role
    ? (ROLE_ROUTES[roleRow.role] ?? '/dashboard/portal')
    : '/dashboard/portal'

  redirect(target)
}
