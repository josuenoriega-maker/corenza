'use server'

import { createClient } from '@/lib/supabase-server'
import { createAdminClient } from '@/lib/supabase-admin'
import { headers } from 'next/headers'
import { revalidatePath } from 'next/cache'

export type InviteState = { error: string } | { success: string } | null

// Qué roles puede invitar cada rol
const INVITABLE_BY: Record<string, string[]> = {
  super_admin:  ['school_admin', 'secretary', 'teacher', 'student', 'guardian'],
  school_admin: ['secretary', 'teacher', 'student', 'guardian'],
  secretary:    ['teacher', 'student', 'guardian'],
}

export async function inviteUser(
  _prev: InviteState,
  formData: FormData,
): Promise<InviteState> {
  const firstName = (formData.get('first_name') as string)?.trim()
  const lastName  = (formData.get('last_name')  as string)?.trim()
  const email     = (formData.get('email')       as string)?.trim().toLowerCase()
  const role      = formData.get('role') as string

  if (!firstName || !lastName || !email || !role) {
    return { error: 'Completa todos los campos.' }
  }

  // Context del usuario que invita
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return { error: 'Sesión expirada.' }

  const { data: inviterProfile } = await supabase
    .from('profiles')
    .select('school_id')
    .eq('id', user.id)
    .single()

  const { data: inviterRoleRow } = await supabase
    .from('user_roles')
    .select('role')
    .eq('user_id', user.id)
    .limit(1)
    .maybeSingle()

  const inviterRole = inviterRoleRow?.role ?? ''
  const schoolId    = inviterProfile?.school_id

  if (!schoolId)                                   return { error: 'No se pudo determinar el colegio.' }
  if (!(INVITABLE_BY[inviterRole] ?? []).includes(role)) return { error: 'No tienes permiso para asignar ese rol.' }

  // URL de redirección (funciona en localhost y en Vercel)
  const headersList = await headers()
  const host  = headersList.get('host') ?? 'localhost:3000'
  const proto = host.includes('localhost') ? 'http' : 'https'
  const redirectTo = `${proto}://${host}/auth/callback?next=/set-password`

  const admin = createAdminClient()

  // 1. Enviar invitación — crea el auth.user
  const { data: inviteData, error: inviteError } =
    await admin.auth.admin.inviteUserByEmail(email, {
      redirectTo,
      data: { first_name: firstName, last_name: lastName },
    })

  if (inviteError) {
    const msg = inviteError.message ?? ''
    if (msg.toLowerCase().includes('already')) {
      return { error: 'Ya existe una cuenta con ese correo.' }
    }
    return { error: `Error al enviar invitación: ${msg}` }
  }

  const newUserId = inviteData.user.id

  // 2. Crear perfil
  const { error: profileErr } = await admin
    .from('profiles')
    .insert({ id: newUserId, school_id: schoolId, first_name: firstName, last_name: lastName })

  if (profileErr) {
    await admin.auth.admin.deleteUser(newUserId)
    return { error: 'Error al crear el perfil. Intenta de nuevo.' }
  }

  // 3. Asignar rol
  const { error: roleErr } = await admin
    .from('user_roles')
    .insert({ user_id: newUserId, school_id: schoolId, role })

  if (roleErr) {
    await admin.auth.admin.deleteUser(newUserId)
    return { error: 'Error al asignar el rol. Intenta de nuevo.' }
  }

  // 4. Registros complementarios según rol
  if (role === 'student') {
    const year = new Date().getFullYear()
    const code = `STU-${year}-${newUserId.replace(/-/g, '').slice(0, 8).toUpperCase()}`
    await admin.from('students').insert({
      school_id: schoolId, profile_id: newUserId, student_code: code,
    })
  }

  if (role === 'guardian') {
    await admin.from('guardians').insert({ school_id: schoolId, profile_id: newUserId })
  }

  if (['teacher', 'secretary', 'school_admin'].includes(role)) {
    await admin.from('staff_profiles').insert({ school_id: schoolId, profile_id: newUserId })
  }

  revalidatePath('/dashboard/usuarios')
  return { success: `Invitación enviada a ${email}. Recibirá un correo para activar su cuenta.` }
}
