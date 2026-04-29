import { redirect } from 'next/navigation'

// Este archivo resuelve en "/" dentro del route group (dashboard).
// app/page.tsx tiene precedencia para "/"; este redirige por si acaso.
export default function DashboardGroupRoot() {
  redirect('/dashboard')
}
