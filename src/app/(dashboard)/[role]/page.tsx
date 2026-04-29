import { redirect } from 'next/navigation'

// Catch-all en raíz del grupo — redirige al path correcto bajo /dashboard/
export default async function RootRoleRedirect({
  params,
}: {
  params: Promise<{ role: string }>
}) {
  const { role } = await params
  redirect(`/dashboard/${role}`)
}
