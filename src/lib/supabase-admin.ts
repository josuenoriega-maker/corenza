import { createClient } from '@supabase/supabase-js'

// Solo usar en Server Actions — nunca importar desde Client Components.
// Requiere SUPABASE_SERVICE_ROLE_KEY en .env.local
export function createAdminClient() {
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY
  if (!serviceKey) {
    throw new Error('SUPABASE_SERVICE_ROLE_KEY no configurada')
  }
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    serviceKey,
    { auth: { autoRefreshToken: false, persistSession: false } }
  )
}
