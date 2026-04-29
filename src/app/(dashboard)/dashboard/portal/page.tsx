export default function PortalPage() {
  return (
    <div className="flex items-center justify-center min-h-[60vh]">
      <div className="rounded-2xl bg-white shadow-sm ring-1 ring-slate-200 p-8 text-center max-w-sm w-full">
        <div className="w-12 h-12 rounded-full bg-amber-50 flex items-center justify-center mx-auto mb-4">
          <svg className="w-6 h-6 text-amber-500" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" />
          </svg>
        </div>
        <h1 className="text-lg font-semibold text-slate-900">Sin rol asignado</h1>
        <p className="mt-2 text-sm text-slate-500">
          Tu cuenta está activa pero aún no tienes un rol asignado. Contacta al
          administrador de tu colegio para que configure tu acceso.
        </p>
      </div>
    </div>
  )
}
