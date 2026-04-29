'use client'

import { useActionState } from 'react'
import { setPassword, type SetPasswordState } from './actions'

// Vive fuera de (auth): usuarios recién invitados ya tienen sesión
// y no deben ser redirigidos al dashboard hasta crear su contraseña.
export default function SetPasswordPage() {
  const [state, action, pending] = useActionState<SetPasswordState, FormData>(
    setPassword,
    null
  )

  return (
    <div className="min-h-screen bg-slate-50 flex items-center justify-center p-4">
      <div className="w-full max-w-sm">
        <div className="mb-8 text-center">
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">
            Corenza
          </h1>
          <p className="mt-1 text-sm text-slate-500">
            Bienvenido. Crea tu contraseña para comenzar.
          </p>
        </div>

        <div className="rounded-2xl bg-white shadow-sm ring-1 ring-slate-200 p-8">
          <h2 className="text-lg font-semibold text-slate-800 mb-6">
            Crear contraseña
          </h2>

          <form action={action} className="space-y-4">
            <div>
              <label
                htmlFor="password"
                className="block text-sm font-medium text-slate-700 mb-1.5"
              >
                Nueva contraseña
              </label>
              <input
                id="password"
                name="password"
                type="password"
                autoComplete="new-password"
                required
                minLength={8}
                className="w-full rounded-lg border border-slate-300 px-3.5 py-2.5 text-sm text-slate-900 placeholder:text-slate-400 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20 disabled:opacity-50"
                placeholder="Mínimo 8 caracteres"
                disabled={pending}
              />
            </div>

            <div>
              <label
                htmlFor="confirm"
                className="block text-sm font-medium text-slate-700 mb-1.5"
              >
                Confirmar contraseña
              </label>
              <input
                id="confirm"
                name="confirm"
                type="password"
                autoComplete="new-password"
                required
                className="w-full rounded-lg border border-slate-300 px-3.5 py-2.5 text-sm text-slate-900 placeholder:text-slate-400 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20 disabled:opacity-50"
                placeholder="Repite la contraseña"
                disabled={pending}
              />
            </div>

            {state?.error && (
              <p className="rounded-lg bg-red-50 border border-red-200 px-3.5 py-2.5 text-sm text-red-700">
                {state.error}
              </p>
            )}

            <button
              type="submit"
              disabled={pending}
              className="w-full rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-semibold text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-60 disabled:cursor-not-allowed transition-colors mt-2"
            >
              {pending ? 'Guardando…' : 'Crear contraseña y entrar'}
            </button>
          </form>
        </div>
      </div>
    </div>
  )
}
