# Plan de desarrollo — SyncPDF

Plan de ejecución por fases. Cada fase es independientemente testeable antes de avanzar a la siguiente.

---

## Fase 1 — Backend: Infraestructura + Auth

**Objetivo:** servidor corriendo, DB lista, flujo de registro/login funcional.

**Tareas:**
1. `npm init` en `server/`, instalar dependencias: `express`, `@supabase/supabase-js`, `bcrypt`, `jsonwebtoken`, `ws`, `stripe`, `resend`, `express-rate-limit`, `dotenv`
2. Crear las 9 tablas en Supabase (copiar los `CREATE TABLE` de `backend/syncpdf-backend.md`) + insertar `global_settings` iniciales
3. `config/db.js`, `config/mailer.js`
4. `utils/jwt.js`, `utils/generateCode.js`, `utils/email_templates.js`
5. `middleware/auth.js` (verificar JWT)
6. `routes/auth.js` — register, login, activate, forgot/reset password, `/me`
7. `index.js` — levantar Express en `PORT`

**Cómo probar:**
```bash
# Registro
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"user@test.com","password":"123456","full_name":"Test"}'

# Login → guardar el JWT
curl -X POST http://localhost:3000/auth/login \
  -d '{"email":"user@test.com","password":"123456"}'

# Activar cuenta
curl -X POST http://localhost:3000/auth/activate \
  -d '{"email":"user@test.com","code":"123456"}'

# Perfil
curl http://localhost:3000/auth/me -H "Authorization: Bearer <JWT>"
```

**Criterio de éxito:** usuario se registra, activa su cuenta con código, hace login y obtiene su perfil.

---

## Fase 2 — Backend: API REST — Grupos y Salas

**Objetivo:** flujo completo de grupos e invitaciones, y CRUD de salas, sin WebSocket aún.

**Tareas:**
1. `middleware/checkRole.js`, `middleware/checkSubscription.js` (versión básica)
2. `routes/groups.js` — todos los endpoints de grupos e invitaciones
3. `routes/rooms.js` — GET, POST, GET `:id`, PATCH `:id/close`

**Secuencia de prueba:**
```
POST /groups                          → crear grupo
POST /groups/:id/invite               → invitar por email
GET  /groups/invite/:token            → validar token
POST /groups/invite/:token/accept     → aceptar invitación
POST /rooms (con groupId)             → crear sala
GET  /rooms?groupId=...               → listar salas
PATCH /rooms/:id/close                → cerrar sala
```

**Criterio de éxito:** dos usuarios distintos pueden compartir un grupo y ver las salas del mismo.

---

## Fase 3 — Backend: WebSocket + Sincronización en tiempo real

**Objetivo:** host y viewer se conectan, el scroll se sincroniza, el timeout de host funciona.

**Tareas:**
1. `ws/room_manager.js` — estructura `Map<roomId, {...}>` en memoria con las 8 reglas críticas del spec
2. `ws/ws_server.js` — upgrade HTTP → WS, validar JWT en query param (cerrar con código `4001` si inválido), dispatch de mensajes
3. Handlers para todos los mensajes: `CREATE_ROOM`, `JOIN_ROOM`, `SCROLL`, `VIEWER_SCROLL`, `REJOIN_SYNC`, `PING`
4. Debounce de 5s para persistencia de scroll en Supabase
5. Timer de 10 minutos para `SESSION_CLOSED` cuando host se desconecta
6. Levantar WS server en `WS_PORT` desde `index.js`

**Cómo probar** (con `wscat`):
```bash
npm install -g wscat

# Terminal 1 — host
wscat -c "ws://localhost:3001/ws?token=<JWT_HOST>"
> {"type":"JOIN_ROOM","roomId":"<uuid>"}
> {"type":"SCROLL","page":3,"offsetY":0.5}

# Terminal 2 — viewer
wscat -c "ws://localhost:3001/ws?token=<JWT_VIEWER>"
> {"type":"JOIN_ROOM","roomId":"<uuid>"}
# Debe recibir: {"type":"SYNC","page":3,"offsetY":0.5}

# Cerrar Terminal 1 → viewer recibe HOST_DISCONNECTED
# Esperar timeout → viewer recibe SESSION_CLOSED
```

**Criterio de éxito:** las 8 reglas críticas del `room_manager.js` se cumplen.

---

## Fase 4 — Backend: Stripe y Suscripciones

**Objetivo:** alta de suscripción, cancelación y webhooks funcionando en modo test.

**Tareas:**
1. `config/stripe.js`
2. Crear `Stripe Customer` en `POST /auth/register`, guardar `stripe_customer_id` en `subscriptions`
3. `routes/payments.js` — plans, subscribe, cancel, status
4. `webhooks/stripe.js` — handlers para `customer.subscription.updated/deleted`, `invoice.payment_succeeded/failed`
5. Montar webhook en `index.js` con `express.raw()` (antes del `express.json()`)
6. `checkSubscription.js` completo — bloquear `/groups`, `/rooms` si `isActive = false`

**Cómo probar** (con Stripe CLI):
```bash
stripe login
stripe listen --forward-to localhost:3000/webhooks/stripe

# En otra terminal:
stripe trigger invoice.payment_succeeded
stripe trigger customer.subscription.deleted
```

**Criterio de éxito:** suscripción pasa de `trial → active → expired` según webhooks. Usuario con suscripción expirada recibe 403 al crear grupos.

---

## Fase 5 — Backend: Admin y SuperAdmin API

**Objetivo:** endpoints de gestión funcionales.

**Tareas:**
1. `routes/admin.js` — clientes, editar trial, suspender/activar, salas activas
2. `routes/superadmin.js` — admins, invitar admin, settings, métricas
3. Emails de invitación de admin (plantilla en `email_templates.js`)

**Secuencia de prueba:**
```
GET  /admin/clients               → listar todos los clients
PATCH /admin/clients/:id/suspend  → suspender → verificar que no puede hacer login
PATCH /superadmin/settings        → cambiar default_trial_days
GET  /superadmin/metrics          → ver totales
```

**Criterio de éxito:** las tres jerarquías de rol están aisladas y funcionan correctamente.

---

## Fase 6 — Flutter: Fundación + Autenticación

**Objetivo:** app Flutter que se comunica con el backend real, usuario puede hacer login.

**Tareas:**
1. `flutter create app-mobile`, copiar `pubspec.yaml` del spec, `flutter pub get`
2. `flutter pub run build_runner build` (Riverpod codegen)
3. `core/constants.dart`, `core/theme.dart`, `core/exceptions.dart`
4. Todos los modelos (`user.dart`, `subscription.dart`, etc.) + `sync_event.dart` como sealed class
5. `services/auth_service.dart`
6. `providers/auth_provider.dart`
7. Pantallas: `LoginScreen`, `RegisterScreen`, `ActivateScreen`, `ForgotPasswordScreen`
8. `core/router.dart` con GoRouter — guard básico: sin sesión → `/login`
9. `app.dart` + `main.dart`

**Cómo probar:**
- Registrar usuario desde la app → verificar en Supabase que aparece en `users`
- Activar cuenta → login exitoso → llega a `HomeScreen` vacía

**Criterio de éxito:** flujo de autenticación completo. `authProvider` persiste sesión entre reinicios.

---

## Fase 7 — Flutter: Grupos, Salas y Guard de Suscripción

**Objetivo:** usuario puede crear grupos, invitar miembros y ver salas.

**Tareas:**
1. `services/group_service.dart`, `services/room_service.dart`
2. `providers/group_provider.dart`, `providers/room_provider.dart`
3. `services/subscription_service.dart`, `providers/subscription_provider.dart`
4. `HomeScreen` — lista de grupos
5. `GroupScreen` — salas del grupo, botón invitar
6. Guard `checkRoomAccess()` — redirigir a `/paywall` si suscripción inactiva
7. Rutas en GoRouter: `/home`, `/groups/:id`, `/room/:id`, `/paywall`

**Cómo probar:**
- Crear grupo → aparece en `HomeScreen`
- Invitar otro usuario → aceptar invitación → aparece en el grupo
- Simular suscripción expirada en Supabase → al intentar crear sala → redirige a paywall

---

## Fase 8 — Flutter: Visor PDF + Sincronización WebSocket

**Objetivo:** host y viewer sincronizados en tiempo real desde la app.

**Tareas:**
1. `services/sync_service.dart` — WebSocket con reconexión exponential backoff y PING/PONG
2. `providers/sync_provider.dart` — `SyncState` con máquina de estados del viewer
3. `PDFViewerScreen` — cargar PDF con `file_picker`, `SfPdfViewer`, lógica host vs viewer
4. `_suppressNextScroll` flag para evitar eco en viewers
5. `AppLifecycleListener` para reconectar al volver de background
6. `widgets/sync_banner.dart` y `widgets/reconnect_banner.dart` con animaciones slide-up
7. `widgets/room_overlay.dart` — código de sala + contador de participantes
8. Debounce 50ms en scroll del host antes de broadcast

**Cómo probar** (dos dispositivos o simuladores):
```
Dispositivo A (host):  entrar a sala → cargar PDF → scrollear
Dispositivo B (viewer): unirse a sala → verificar que sigue el scroll del host

Desconectar red del host:
  → Viewer recibe HOST_DISCONNECTED → banner "Carlos se desconectó"
  → Viewer puede scrollear libremente

Reconectar red del host:
  → Viewer recibe HOST_RECONNECTED → banner "¿Volver a sincro?"
  → Tocar [Sí] → viewer vuelve a synced
  → Tocar [No] → viewer sigue en free
```

**Criterio de éxito:** las transiciones de la máquina de estados del viewer (synced → free → synced) funcionan correctamente.

---

## Fase 9 — Flutter: Pagos y Suscripción

**Objetivo:** usuario puede suscribirse y cancelar desde la app.

**Tareas:**
1. `services/payment_service.dart`
2. `SubscriptionScreen` — estado actual, días restantes, botón cancelar
3. `PaywallScreen` — listar planes, iniciar pago con `flutter_stripe`
4. `widgets/subscription_badge.dart`

**Cómo probar:**
- Usar tarjeta de prueba Stripe `4242 4242 4242 4242`
- Verificar que `subscriptions.status` cambia a `active` vía webhook
- Cancelar → verificar acceso hasta `current_period_end`

---

## Fase 10 — Flutter: Pantallas Admin y SuperAdmin

**Objetivo:** admins y superadmins tienen su panel operativo en la app.

**Tareas:**
1. `AdminDashboard`, `ClientsScreen`, `ClientDetailScreen`
2. `SuperAdminDashboard`, `AdminsScreen`, `SettingsScreen`, `MetricsScreen`
3. Guards de rol en GoRouter para rutas `/admin` y `/superadmin`

**Criterio de éxito:** un `client` no puede acceder a rutas de admin. Un `admin` no puede acceder a rutas de superadmin.

---

## Fase 11 — Flutter: Deep Links e Invitaciones de Grupo

**Objetivo:** un link `syncpdf://invite?token=xxx` abre la app y lleva al flujo correcto.

**Tareas:**
1. Registrar scheme `syncpdf://` en `AndroidManifest.xml` e `Info.plist`
2. `InviteAcceptScreen` — si no autenticado → `RegisterScreen` con token pre-cargado; si autenticado → confirmación
3. Ruta GoRouter `/invite`
4. Link en el email de invitación del backend

**Cómo probar:**
```bash
# Android
adb shell am start -a android.intent.action.VIEW \
  -d "syncpdf://invite?token=<token>"

# iOS Simulator
xcrun simctl openurl booted "syncpdf://invite?token=<token>"
```

---

## Fase 12 — Flutter: Notificaciones Push

**Objetivo:** usuarios reciben notificaciones cuando son invitados o cuando una sesión termina.

**Tareas:**
1. Configurar `firebase_messaging` + `flutter_local_notifications`
2. Guardar FCM token en Supabase (agregar columna `fcm_token` a `users`)
3. Backend: enviar push desde room_manager (session cerrada) y webhook Stripe (pago fallido)

---

## Fase WA-1 — Web Admin: Fundación + Login

**Objetivo:** proyecto Next.js configurado, login funcional para admin y superadmin.

**Tareas:**
1. `npx create-next-app@latest web-admin --typescript --tailwind --app`
2. `npx shadcn@latest init` + añadir componentes: `button`, `input`, `label`, `form`, `card`, `badge`, `dialog`, `table`, `tabs`
3. `npm install @tanstack/react-query zustand react-hook-form zod recharts sonner`
4. `src/lib/api.ts` — fetch wrapper con JWT y manejo de 401
5. `src/lib/auth.ts` — Zustand store: `user`, `token`, `login()`, `logout()`
6. `src/types/index.ts` — tipos: `User`, `Subscription`, `Room`, `Plan`, `GlobalSettings`
7. `src/app/login/page.tsx` — form con Zod, validación de rol
8. `src/middleware.ts` — proteger `/admin/*` y `/superadmin/*` con cookie
9. Provider de TanStack Query en `src/app/layout.tsx`

**Cómo probar:**
```
- Login con admin → redirige a /admin
- Login con superadmin → redirige a /superadmin
- Login con client → muestra error "Acceso no permitido"
- Acceder a /admin sin token → redirige a /login
```

**Criterio de éxito:** sesión persiste al recargar. Rutas protegidas redirigen correctamente.

---

## Fase WA-2 — Web Admin: Layout y Admin Dashboard

**Objetivo:** estructura visual completa + primera pantalla con datos reales.

**Tareas:**
1. `src/components/layout/Sidebar.tsx`
2. `src/components/layout/Header.tsx` — nombre de usuario + logout
3. `src/app/admin/layout.tsx` — sidebar + verificación secundaria de rol
4. `src/hooks/useClients.ts` — `useClients()`, `useClientStats()`
5. `src/components/metrics/StatsCards.tsx` — cards: en trial, activos, expirados, salas activas
6. `src/app/admin/page.tsx` — Dashboard

**Criterio de éxito:** dashboard muestra conteos correctos (verificar contra Supabase).

---

## Fase WA-3 — Web Admin: Gestión de Clientes

**Objetivo:** admin puede ver, buscar, suspender y editar el trial de cualquier cliente.

**Tareas:**
1. `src/components/clients/ClientStatusBadge.tsx`
2. `src/components/clients/ClientsTable.tsx` — búsqueda con debounce 300ms, filtro por status
3. `src/components/clients/EditTrialModal.tsx`
4. `src/components/clients/SuspendModal.tsx` — confirmación antes de suspender/activar
5. `src/hooks/useClients.ts` — añadir `useSuspendClient()`, `useActivateClient()`, `useEditTrial()`
6. `src/app/admin/clients/page.tsx`
7. `src/app/admin/clients/[id]/page.tsx` — detalle con grupos y salas

**Cómo probar:**
```
1. Buscar cliente por nombre → filtra en tiempo real
2. Editar trial → verificar en Supabase que subscriptions.trial_ends_at cambió
3. Suspender → badge cambia a "Suspendido" sin recargar página
4. Activar cliente suspendido → vuelve al estado anterior
```

**Criterio de éxito:** todas las acciones muestran toast y la tabla se actualiza sin reload.

---

## Fase WA-4 — Web Admin: SuperAdmin — Admins y Settings

**Objetivo:** superadmin puede gestionar admins y configurar el sistema.

**Tareas:**
1. `src/app/superadmin/layout.tsx` — guard de rol `superadmin`
2. `src/hooks/useAdmins.ts` — `useAdmins()`, `useInviteAdmin()`, `useSuspendAdmin()`
3. `src/components/admins/AdminsTable.tsx`
4. `src/components/admins/InviteAdminModal.tsx`
5. `src/app/superadmin/admins/page.tsx`
6. `src/hooks/useSettings.ts` — `useSettings()`, `useUpdateSettings()`
7. `src/app/superadmin/settings/page.tsx` — form `default_trial_days` + planes
8. `src/app/superadmin/page.tsx` — dashboard con stats globales

**Cómo probar:**
```
- Invitar admin → llega email + aparece en tabla
- Suspender admin → ese admin ya no puede hacer login
- Editar default_trial_days → verificar en Supabase global_settings
- Acceder a /superadmin con rol admin → redirige a /admin
```

---

## Fase WA-5 — Web Admin: Métricas con Gráficas

**Objetivo:** dashboard de métricas visuales para superadmin.

**Tareas:**
1. `src/hooks/useMetrics.ts` → `GET /superadmin/metrics`
2. `src/components/metrics/RevenueChart.tsx` — Recharts `LineChart` — ingresos por mes
3. `src/components/metrics/UsersGrowthChart.tsx` — Recharts `BarChart` — nuevos usuarios por mes
4. Cards: MRR, churn rate
5. `src/app/superadmin/metrics/page.tsx`

**Nota:** verificar que `GET /superadmin/metrics` devuelve datos agregados por mes antes de implementar las gráficas.

---

## Fase 13 — Deploy y Hardening

**Objetivo:** todo en producción con las keys reales.

**Backend:**
- Variables de entorno seguras en Railway/Render
- Stripe: migrar a live keys, activar webhooks en el dashboard
- Rate limiting activo en producción

**Flutter:**
- Configurar `--dart-define` por entorno (dev/prod)
- Íconos de app y splash screen
- Build firmado para App Store y Google Play

**Web Admin:**
- Deploy en Vercel (ajustar `NEXT_PUBLIC_API_URL` a producción)
- Dominio propio (ej: admin.syncpdf.app)

**Supabase:**
- Revisar Row Level Security (RLS) — el backend usa `service_key` por lo que RLS no aplica a las llamadas del server, pero sí si en algún punto se accede desde el cliente directamente

---

## Resumen visual

```
── BACKEND ──────────────────────────────────────────
 Fase 1   Auth + DB
 Fase 2   Grupos + Salas REST
 Fase 3   WebSocket + room_manager  ← núcleo del producto
 Fase 4   Stripe + webhooks
 Fase 5   Admin + SuperAdmin API

── MOBILE (Flutter) ─────────────────────────────────
 Fase 6   Auth + navegación
 Fase 7   Grupos + salas + guards
 Fase 8   PDF viewer + sync         ← núcleo del producto
 Fase 9   Pagos
 Fase 10  Admin + SuperAdmin UI (móvil)
 Fase 11  Deep links
 Fase 12  Push notifications

── WEB ADMIN (Next.js) ──────────────────────────────
 Fase WA-1  Fundación + Login
 Fase WA-2  Layout + Admin Dashboard
 Fase WA-3  Gestión de clientes
 Fase WA-4  SuperAdmin: admins + settings
 Fase WA-5  Métricas con gráficas

── TODOS ─────────────────────────────────────────────
 Fase 13  Deploy + hardening
```

**Orden recomendado:**
1. Fases 1–5 primero (backend completo)
2. Fases 6–12 y WA-1 a WA-5 en paralelo (mobile y web admin pueden desarrollarse a la vez)
3. Fase 13 al final
