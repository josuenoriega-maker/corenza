'use client'

import { useActionState, useEffect, useRef } from 'react'
import type { InviteState } from './actions'

const ROL_LABELS: Record<string, string> = {
  super_admin:  'Super Admin',
  school_admin: 'Administrador',
  secretary:    'Secretaria',
  teacher:      'Maestro',
  student:      'Alumno',
  guardian:     'Tutor',
}

interface Props {
  roles: string[]
  action: (prev: InviteState, data: FormData) => Promise<InviteState>
}

export default function InviteForm({ roles, action }: Props) {
  const [state, formAction, pending] = useActionState<InviteState, FormData>(action, null)
  const formRef = useRef<HTMLFormElement>(null)

  // Limpiar formulario al recibir éxito
  useEffect(() => {
    if (state && 'success' in state) {
      formRef.current?.reset()
    }
  }, [state])

  return (
    <form ref={formRef} action={formAction} className="grid grid-cols-1 sm:grid-cols-2 gap-4">
      <div>
        <label htmlFor="first_name" className="block text-sm font-medium text-slate-700 mb-1.5">
          Nombre
        </label>
        <input
          id="first_name" name="first_name" type="text" required
          disabled={pending}
          placeholder="María"
          className="w-full rounded-lg border border-slate-300 px-3.5 py-2.5 text-sm text-slate-900 placeholder:text-slate-400 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20 disabled:opacity-50"
        />
      </div>

      <div>
        <label htmlFor="last_name" className="block text-sm font-medium text-slate-700 mb-1.5">
          Apellido
        </label>
        <input
          id="last_name" name="last_name" type="text" required
          disabled={pending}
          placeholder="García"
          className="w-full rounded-lg border border-slate-300 px-3.5 py-2.5 text-sm text-slate-900 placeholder:text-slate-400 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20 disabled:opacity-50"
        />
      </div>

      <div>
        <label htmlFor="email" className="block text-sm font-medium text-slate-700 mb-1.5">
          Correo electrónico
        </label>
        <input
          id="email" name="email" type="email" required
          disabled={pending}
          placeholder="usuario@colegio.edu.gt"
          className="w-full rounded-lg border border-slate-300 px-3.5 py-2.5 text-sm text-slate-900 placeholder:text-slate-400 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20 disabled:opacity-50"
        />
      </div>

      <div>
        <label htmlFor="role" className="block text-sm font-medium text-slate-700 mb-1.5">
          Rol
        </label>
        <select
          id="role" name="role" required
          disabled={pending}
          defaultValue=""
          className="w-full rounded-lg border border-slate-300 bg-white px-3.5 py-2.5 text-sm text-slate-900 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20 disabled:opacity-50"
        >
          <option value="" disabled>Selecciona un rol…</option>
          {roles.map(r => (
            <option key={r} value={r}>{ROL_LABELS[r] ?? r}</option>
          ))}
        </select>
      </div>

      {state && 'error' in state && (
        <div className="sm:col-span-2">
          <p className="rounded-lg bg-red-50 border border-red-200 px-3.5 py-2.5 text-sm text-red-700">
            {state.error}
          </p>
        </div>
      )}

      {state && 'success' in state && (
        <div className="sm:col-span-2">
          <p className="rounded-lg bg-green-50 border border-green-200 px-3.5 py-2.5 text-sm text-green-700">
            {state.success}
          </p>
        </div>
      )}

      <div className="sm:col-span-2 flex justify-end pt-1">
        <button
          type="submit"
          disabled={pending}
          className="rounded-lg bg-blue-600 px-5 py-2.5 text-sm font-semibold text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-60 disabled:cursor-not-allowed transition-colors"
        >
          {pending ? 'Enviando…' : 'Enviar invitación'}
        </button>
      </div>
    </form>
  )
}
