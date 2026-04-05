# SyncPDF — Web Admin Architecture

Panel web de administración para roles `admin` y `superadmin`. Los clientes usan exclusivamente la app móvil.

---

## Stack tecnológico

| Capa | Tecnología |
|---|---|
| Framework | Next.js 14 (App Router) |
| UI | shadcn/ui + Tailwind CSS |
| Estado servidor | TanStack Query v5 |
| Estado cliente | Zustand |
| Formularios | React Hook Form + Zod |
| Gráficas | Recharts |
| HTTP client | fetch nativo (wrapper con JWT) |

---

## Estructura de archivos

```
web-admin/
├── package.json
├── next.config.js
├── tailwind.config.js
├── components.json              # shadcn config
├── .env.local
│
└── src/
    ├── app/
    │   ├── layout.tsx           # RootLayout — providers globales
    │   ├── login/
    │   │   └── page.tsx
    │   ├── admin/
    │   │   ├── layout.tsx       # Sidebar + guard de rol admin
    │   │   ├── page.tsx         # Dashboard admin
    │   │   └── clients/
    │   │       ├── page.tsx     # Lista de clientes
    │   │       └── [id]/
    │   │           └── page.tsx # Detalle de cliente
    │   └── superadmin/
    │       ├── layout.tsx       # Sidebar + guard de rol superadmin
    │       ├── page.tsx         # Dashboard superadmin
    │       ├── admins/
    │       │   └── page.tsx     # Lista de admins + invitar
    │       ├── settings/
    │       │   └── page.tsx     # Trial days, precios de planes
    │       └── metrics/
    │           └── page.tsx     # Gráficas de crecimiento e ingresos
    │
    ├── components/
    │   ├── ui/                  # Componentes shadcn (Button, Table, Badge, Dialog...)
    │   ├── layout/
    │   │   ├── Sidebar.tsx      # Nav lateral con enlaces por rol
    │   │   └── Header.tsx       # Nombre de usuario + botón logout
    │   ├── clients/
    │   │   ├── ClientsTable.tsx      # Tabla paginada con búsqueda
    │   │   ├── ClientStatusBadge.tsx # Trial / Activo / Expirado / Suspendido
    │   │   ├── EditTrialModal.tsx    # Dialog para editar días de trial
    │   │   └── SuspendModal.tsx      # Confirmación suspender/activar
    │   ├── admins/
    │   │   ├── AdminsTable.tsx
    │   │   └── InviteAdminModal.tsx  # Form email + envío
    │   └── metrics/
    │       ├── StatsCards.tsx        # Cards: MRR, usuarios, churn, salas activas
    │       ├── RevenueChart.tsx      # Recharts — ingresos mensuales
    │       └── UsersGrowthChart.tsx  # Recharts — nuevos usuarios por mes
    │
    ├── lib/
    │   ├── api.ts               # fetch wrapper — añade Authorization header + maneja 401
    │   ├── auth.ts              # Zustand store — user, token, login(), logout()
    │   └── utils.ts             # formatDate, formatCurrency, cn()
    │
    ├── hooks/
    │   ├── useClients.ts        # TanStack Query: useClients(), useClient(id), useSuspendClient(), useEditTrial()
    │   ├── useAdmins.ts         # useAdmins(), useInviteAdmin(), useSuspendAdmin()
    │   ├── useMetrics.ts        # useMetrics()
    │   └── useSettings.ts      # useSettings(), useUpdateSettings()
    │
    ├── middleware.ts            # Next.js middleware — protección de rutas por rol
    │
    └── types/
        └── index.ts             # User, Subscription, Room, Plan, GlobalSettings, Metrics
```

---

## Autenticación

Solo pueden acceder los roles `admin` y `superadmin`. Los `client` reciben 403 si intentan hacer login.

```typescript
// lib/auth.ts — Zustand store
interface AuthStore {
  user:   User | null;
  token:  string | null;
  login:  (email: string, password: string) => Promise<void>;
  logout: () => void;
}

// Al hacer login:
// 1. POST /auth/login
// 2. Verificar que user.role es 'admin' o 'superadmin'
// 3. Guardar token en localStorage + Zustand
// 4. Redirigir según rol: /admin o /superadmin
```

```typescript
// middleware.ts — protección de rutas
export function middleware(request: NextRequest) {
  const token = request.cookies.get('token')?.value;
  const role  = request.cookies.get('role')?.value;

  if (request.nextUrl.pathname.startsWith('/admin')) {
    if (!token || (role !== 'admin' && role !== 'superadmin')) {
      return NextResponse.redirect(new URL('/login', request.url));
    }
  }

  if (request.nextUrl.pathname.startsWith('/superadmin')) {
    if (!token || role !== 'superadmin') {
      return NextResponse.redirect(new URL('/login', request.url));
    }
  }
}

export const config = {
  matcher: ['/admin/:path*', '/superadmin/:path*'],
};
```

**Nota:** guardar el token también en cookie httpOnly además de Zustand, para que `middleware.ts` pueda leerlo sin JS.

---

## API wrapper

```typescript
// lib/api.ts
const BASE_URL = process.env.NEXT_PUBLIC_API_URL;

async function apiFetch<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = useAuthStore.getState().token;

  const res = await fetch(`${BASE_URL}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  });

  if (res.status === 401) {
    useAuthStore.getState().logout();
    window.location.href = '/login';
  }

  if (!res.ok) {
    const error = await res.json();
    throw new Error(error.message ?? 'Error de servidor');
  }

  return res.json();
}

export const api = {
  get:    <T>(path: string) => apiFetch<T>(path),
  post:   <T>(path: string, body: unknown) => apiFetch<T>(path, { method: 'POST', body: JSON.stringify(body) }),
  patch:  <T>(path: string, body: unknown) => apiFetch<T>(path, { method: 'PATCH', body: JSON.stringify(body) }),
  delete: <T>(path: string) => apiFetch<T>(path, { method: 'DELETE' }),
};
```

---

## Hooks TanStack Query

```typescript
// hooks/useClients.ts
export function useClients(search?: string) {
  return useQuery({
    queryKey: ['clients', search],
    queryFn: () => api.get<User[]>(`/admin/clients${search ? `?q=${search}` : ''}`),
  });
}

export function useSuspendClient() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => api.patch(`/admin/clients/${id}/suspend`, {}),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['clients'] }),
  });
}

export function useEditTrial() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, days }: { id: string; days: number }) =>
      api.patch(`/admin/clients/${id}/trial`, { trial_days: days }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['clients'] }),
  });
}
```

---

## Pantallas

### Login — `/login`
- Form email + password
- Validación con Zod
- Muestra error si rol no es admin/superadmin
- Redirect automático si ya hay sesión

### Admin Dashboard — `/admin`

```
┌─────────────────────────────────────────┐
│ 📊 Resumen                              │
│                                         │
│ ┌──────────┐ ┌──────────┐ ┌──────────┐ │
│ │ Trial    │ │ Activos  │ │ Expirados│ │
│ │   42     │ │   128    │ │    15    │ │
│ └──────────┘ └──────────┘ └──────────┘ │
│                                         │
│ ┌──────────────────────────────────────┐│
│ │ Salas activas ahora: 7               ││
│ └──────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

### Clients list — `/admin/clients`
- Tabla con columnas: Nombre, Email, Estado (badge), Días trial restantes, Fecha registro
- Búsqueda por nombre/email (debounce 300ms)
- Filtro por status: todos / trial / activo / expirado / suspendido
- Acciones inline: Ver detalle, Suspender/Activar

### Client detail — `/admin/clients/[id]`
- Info del usuario (nombre, email, estado, fecha registro)
- Card de suscripción: status, días restantes, Stripe customer ID
- Acciones:
  - Editar días de trial → `EditTrialModal`
  - Suspender / Activar cuenta → `SuspendModal` con confirmación
- Tabla de grupos del cliente (nombre, miembros, fecha)
- Tabla de salas recientes

### SuperAdmin Dashboard — `/superadmin`

```
┌───────────────────────────────────────────────┐
│ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌───────┐│
│ │ MRR     │ │ Usuarios│ │ Churn   │ │Admins ││
│ │ $2,450  │ │   185   │ │  3.2%   │ │   4   ││
│ └─────────┘ └─────────┘ └─────────┘ └───────┘│
└───────────────────────────────────────────────┘
```

### Admins — `/superadmin/admins`
- Tabla: Nombre, Email, Estado, Fecha invitación, Clientes asignados
- Botón "Invitar admin" → `InviteAdminModal` (email)
- Acción: Suspender admin con modal de confirmación

### Settings — `/superadmin/settings`
- Form con React Hook Form + Zod
- Campo: `default_trial_days` (número, mínimo 1)
- Tabla de planes Stripe: nombre, precio, duración — editable inline
- Botón Guardar → `PATCH /superadmin/settings`

### Metrics — `/superadmin/metrics`
- `RevenueChart`: línea de ingresos por mes (últimos 12 meses)
- `UsersGrowthChart`: barras de nuevos usuarios por mes
- Cards de churn y retención

---

## Variables de entorno

```env
# .env.local
NEXT_PUBLIC_API_URL=http://localhost:3000
```

---

## Comandos

```bash
cd web-admin
npm install
npm run dev          # desarrollo en http://localhost:3001
npm run build        # build de producción
npm run lint         # ESLint
```

---

## Configuración inicial shadcn

```bash
npx shadcn@latest init
npx shadcn@latest add button table badge dialog input label form card tabs
```

---

## Decisiones de arquitectura

- **No se usa SSR para datos protegidos** — todo el fetching es client-side con TanStack Query. El middleware de Next.js solo verifica la cookie para redirigir; los datos se cargan desde el cliente con JWT.
- **Layouts anidados como guards** — `app/admin/layout.tsx` y `app/superadmin/layout.tsx` hacen una verificación secundaria del rol (además del middleware) antes de renderizar el sidebar.
- **Invalidación optimista** — las mutaciones (suspender, editar trial) invalidan el query correspondiente para refrescar la tabla sin recargar la página.
- **Toast de feedback** — todas las mutaciones muestran un toast de éxito o error usando el componente `Sonner` de shadcn.
