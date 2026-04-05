# SyncPDF — API Reference

Base URL: `http://localhost:3000`

Todos los endpoints protegidos requieren el header:
```
Authorization: Bearer <token>
```

Las respuestas exitosas tienen la forma `{ success: true, data: ... }`.  
Los errores tienen la forma `{ message: "..." }` (o `{ success: false, error: "..." }` en auth).

---

## Auth — `/auth`

### POST `/auth/register`
Registro de nuevo cliente. Envía email de activación.

**Body:**
```json
{
  "email": "usuario@ejemplo.com",
  "password": "minimo8chars",
  "full_name": "Nombre Completo"
}
```

**Respuesta 201:**
```json
{ "success": true, "message": "Cuenta creada. Revisa tu email para activarla." }
```

**Errores:** `409` email ya registrado · `422` validación

---

### POST `/auth/login`
Login. Devuelve JWT.

**Body:**
```json
{ "email": "usuario@ejemplo.com", "password": "tupassword" }
```

**Respuesta 200:**
```json
{
  "success": true,
  "data": {
    "token": "eyJ...",
    "user": { "id": "uuid", "email": "...", "full_name": "...", "role": "client" }
  }
}
```

**Errores:** `401` credenciales inválidas / cuenta pendiente · `403` cuenta suspendida

---

### POST `/auth/activate`
Activa la cuenta con el código de 6 dígitos recibido por email.

**Body:**
```json
{ "email": "usuario@ejemplo.com", "code": "123456" }
```

**Respuesta 200:**
```json
{ "success": true, "message": "Cuenta activada exitosamente." }
```

**Errores:** `400` código inválido o expirado · `409` ya estaba activa

---

### POST `/auth/forgot-password`
Solicita código de reset de contraseña. Siempre responde igual (anti-enumeración).

**Body:**
```json
{ "email": "usuario@ejemplo.com" }
```

**Respuesta 200:**
```json
{ "success": true, "message": "Si el email existe, recibirás un código." }
```

---

### POST `/auth/reset-password`
Resetea la contraseña con el código recibido por email.

**Body:**
```json
{
  "email": "usuario@ejemplo.com",
  "code": "123456",
  "new_password": "nuevapassword"
}
```

**Respuesta 200:**
```json
{ "success": true, "message": "Contraseña actualizada." }
```

**Errores:** `400` código inválido o expirado

---

### GET `/auth/me`
Perfil del usuario autenticado + estado de suscripción.

**Auth:** requerida

**Respuesta 200:**
```json
{
  "success": true,
  "data": {
    "user": { "id": "uuid", "email": "...", "full_name": "...", "role": "client", "status": "active" },
    "subscription": { "status": "trial", "trial_ends_at": "2026-04-18T...", "current_period_end": null }
  }
}
```

---

## Grupos — `/groups`

> Todos los endpoints requieren auth.

### GET `/groups`
Lista los grupos donde el usuario autenticado es miembro.

**Respuesta 200:**
```json
{
  "success": true,
  "data": [
    { "id": "uuid", "name": "Mi Grupo", "owner_id": "uuid", "created_at": "...", "memberRole": "owner", "joinedAt": "..." }
  ]
}
```

---

### POST `/groups`
Crea un grupo. El usuario se convierte en owner. Requiere suscripción activa.

**Body:**
```json
{ "name": "Nombre del grupo" }
```

**Respuesta 201:**
```json
{ "success": true, "data": { "id": "uuid", "name": "...", "owner_id": "...", "created_at": "..." } }
```

**Errores:** `403` suscripción expirada/suspendido

---

### GET `/groups/:id`
Detalle del grupo con lista de miembros. El usuario debe ser miembro.

**Respuesta 200:**
```json
{
  "success": true,
  "data": {
    "id": "uuid", "name": "...", "owner_id": "...", "created_at": "...",
    "members": [
      { "id": "uuid", "fullName": "...", "email": "...", "role": "owner", "joinedAt": "..." }
    ]
  }
}
```

**Errores:** `403` no eres miembro · `404` grupo no encontrado

---

### DELETE `/groups/:id`
Elimina el grupo. Solo el owner puede hacerlo.

**Respuesta 200:**
```json
{ "success": true, "data": { "deleted": true } }
```

**Errores:** `403` no eres owner

---

### POST `/groups/:id/invite`
Invita a un cliente por email. El usuario debe ser miembro del grupo.

**Body:**
```json
{ "email": "invitado@ejemplo.com" }
```

**Respuesta 201:**
```json
{
  "success": true,
  "data": { "token": "uuid", "invitedEmail": "...", "expiresAt": "..." }
}
```

**Errores:** `403` no eres miembro · `409` ya existe una invitación pendiente para ese email

---

### GET `/groups/invite/:token`
Valida un token de invitación. **Público** (no requiere auth).

**Respuesta 200:**
```json
{
  "success": true,
  "data": { "groupId": "uuid", "groupName": "...", "invitedEmail": "...", "expiresAt": "..." }
}
```

**Errores:** `404` token no encontrado · `409` ya utilizada · `410` expirada

---

### POST `/groups/invite/:token/accept`
Acepta una invitación. El usuario autenticado se une al grupo.

**Auth:** requerida

**Respuesta 200:**
```json
{ "success": true, "data": { "groupId": "uuid" } }
```

**Errores:** `404` token no encontrado · `409` ya eres miembro / invitación ya utilizada · `410` expirada

---

## Salas — `/rooms`

> Todos los endpoints requieren auth.

### GET `/rooms?groupId=<uuid>`
Lista las salas de un grupo. El usuario debe ser miembro del grupo.

**Query params:** `groupId` (requerido)

**Respuesta 200:**
```json
{
  "success": true,
  "data": [
    { "id": "uuid", "name": "Sala 1", "code": "XK49PQ", "status": "active", "file_name": "doc.pdf", "last_page": 3, "last_offset": 0.5, "created_at": "...", "closed_at": null, "host_id": "uuid" }
  ]
}
```

**Errores:** `400` falta groupId · `403` no eres miembro

---

### POST `/rooms`
Crea una sala en un grupo. El usuario se convierte en host. Requiere suscripción activa.

**Body:**
```json
{ "groupId": "uuid", "name": "Nombre de la sala" }
```

**Respuesta 201:**
```json
{ "success": true, "data": { "id": "uuid", "name": "...", "code": "AB12CD", "status": "waiting", ... } }
```

**Errores:** `403` no eres miembro / suscripción inactiva

---

### GET `/rooms/:id`
Detalle de la sala + participantes. El usuario debe ser miembro del grupo de la sala.

**Respuesta 200:**
```json
{
  "success": true,
  "data": {
    "id": "uuid", "name": "...", "code": "...", "status": "active", "host_id": "uuid",
    "participants": [
      { "id": "uuid", "fullName": "...", "email": "...", "role": "host", "syncState": "synced", "lastPage": 1, "lastOffset": 0.0, "joinedAt": "...", "leftAt": null, "lastSeenAt": "..." }
    ]
  }
}
```

**Errores:** `403` no tienes acceso · `404` sala no encontrada

---

### PATCH `/rooms/:id/close`
Cierra la sala. Solo el host puede hacerlo.

**Respuesta 200:**
```json
{ "success": true, "data": { "id": "uuid", "status": "closed", "closed_at": "...", ... } }
```

**Errores:** `403` no eres el host · `404` sala no encontrada · `409` ya estaba cerrada

---

## Pagos — `/payments`

> Todos los endpoints requieren auth.

### GET `/payments/plans`
Lista los planes disponibles.

**Respuesta 200:**
```json
{
  "success": true,
  "data": [
    { "id": "uuid", "name": "Mensual", "price_usd": 9.99, "duration_days": 30, "stripe_price_id": "price_xxx" }
  ]
}
```

---

### POST `/payments/subscribe`
Crea una suscripción Stripe para el usuario autenticado.

**Body:**
```json
{ "planId": "uuid" }
```

**Respuesta 201:**
```json
{
  "success": true,
  "data": { "subscriptionId": "sub_xxx", "status": "trial", "trialEndsAt": "2026-04-18T..." }
}
```

**Errores:** `400` falta planId · `404` plan no encontrado · `422` plan sin precio Stripe

---

### POST `/payments/cancel`
Cancela la suscripción al final del período actual.

**Respuesta 200:**
```json
{ "success": true, "data": { "message": "Suscripción cancelada al final del período" } }
```

**Errores:** `404` suscripción no encontrada · `422` sin stripe_sub_id

---

### GET `/payments/status`
Estado actual de la suscripción del usuario.

**Respuesta 200:**
```json
{
  "success": true,
  "data": {
    "status": "trial",
    "trialEndsAt": "2026-04-18T...",
    "currentPeriodEnd": null,
    "cancelledAt": null,
    "stripeCustomerId": "cus_xxx"
  }
}
```

**Errores:** `404` suscripción no encontrada

---

## Admin — `/admin`

> Requieren auth + rol `admin` o `superadmin`.

### GET `/admin/clients`
Lista todos los clientes con info de suscripción.

**Query params:** `?q=` búsqueda por nombre o email (opcional)

**Respuesta 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid", "email": "...", "full_name": "...", "status": "active",
      "subscription_status": "trial", "trial_ends_at": "...", "current_period_end": null, "created_at": "..."
    }
  ]
}
```

---

### GET `/admin/clients/:id`
Detalle de un cliente: info + suscripción + grupos + salas recientes.

**Respuesta 200:**
```json
{
  "success": true,
  "data": {
    "id": "uuid", "email": "...", "full_name": "...", "status": "active", "created_at": "...",
    "subscription": { "status": "trial", "trial_days": 15, "trial_ends_at": "...", "current_period_end": null, "stripe_customer_id": "cus_xxx", "stripe_sub_id": "sub_xxx", "cancelled_at": null },
    "groups": [ { "id": "uuid", "name": "...", "created_at": "...", "member_role": "owner", "joined_at": "..." } ],
    "recent_rooms": [ { "id": "uuid", "name": "...", "code": "...", "status": "closed", "created_at": "...", "closed_at": "...", "participant_role": "host", "joined_at": "...", "left_at": "..." } ]
  }
}
```

**Errores:** `404` cliente no encontrado

---

### PATCH `/admin/clients/:id/trial`
Edita los días de trial (solo si `status = 'trial'`).

**Body:**
```json
{ "trial_days": 30 }
```

**Respuesta 200:**
```json
{ "success": true, "data": { ... } }
```

**Errores:** `400` falta trial_days · `404` cliente/suscripción no encontrada · `409` no está en trial

---

### PATCH `/admin/clients/:id/suspend`
Suspende la cuenta de un cliente.

**Respuesta 200:**
```json
{ "success": true, "data": { "id": "uuid", "email": "...", "status": "suspended", ... } }
```

**Errores:** `404` cliente no encontrado · `409` ya suspendido

---

### PATCH `/admin/clients/:id/activate`
Reactiva la cuenta de un cliente.

**Respuesta 200:**
```json
{ "success": true, "data": { "id": "uuid", "email": "...", "status": "active", ... } }
```

**Errores:** `404` cliente no encontrado · `409` ya estaba activo

---

### GET `/admin/rooms`
Lista las salas activas (`active` o `host_disconnected`) con conteo de participantes.

**Respuesta 200:**
```json
{
  "success": true,
  "data": [
    { "id": "uuid", "name": "...", "code": "...", "status": "active", "host_id": "uuid", "host_name": "...", "participant_count": 3, "created_at": "..." }
  ]
}
```

---

## SuperAdmin — `/superadmin`

> Requieren auth + rol `superadmin`.

### GET `/superadmin/admins`
Lista todos los admins con conteo de clientes asignados.

**Respuesta 200:**
```json
{
  "success": true,
  "data": [
    { "id": "uuid", "email": "...", "full_name": "...", "status": "active", "created_at": "...", "invited_by": "uuid", "clients_count": 5 }
  ]
}
```

---

### POST `/superadmin/admins/invite`
Invita a un nuevo admin por email.

**Body:**
```json
{ "email": "nuevo-admin@ejemplo.com" }
```

**Respuesta 201:**
```json
{ "message": "Invitación enviada" }
```

**Errores:** `409` email ya registrado · `422` email inválido

---

### PATCH `/superadmin/admins/:id/suspend`
Suspende un admin. No puede suspender superadmins.

**Respuesta 200:**
```json
{ "success": true, "data": { "id": "uuid", "status": "suspended", ... } }
```

**Errores:** `403` el usuario no es admin · `404` no encontrado · `409` ya suspendido

---

### GET `/superadmin/settings`
Obtiene la configuración global como objeto.

**Respuesta 200:**
```json
{
  "success": true,
  "data": { "default_trial_days": "15", "host_reconnect_timeout_minutes": "10" }
}
```

---

### PATCH `/superadmin/settings`
Actualiza uno o varios settings. Acepta dos formatos:

**Body (un setting):**
```json
{ "key": "default_trial_days", "value": "30" }
```

**Body (múltiples settings):**
```json
{ "settings": { "default_trial_days": "30", "host_reconnect_timeout_minutes": "5" } }
```

**Respuesta 200:**
```json
{ "success": true, "data": { "default_trial_days": "30", "host_reconnect_timeout_minutes": "5" } }
```

---

### GET `/superadmin/metrics`
Métricas globales de la plataforma.

**Respuesta 200:**
```json
{
  "success": true,
  "data": {
    "total_users": 185,
    "trial_users": 42,
    "active_users": 128,
    "expired_users": 15,
    "active_rooms": 7,
    "total_admins": 4,
    "mrr": 1279.72
  }
}
```

---

## WebSocket — `ws://localhost:3000/ws`

### Conexión
```
ws://localhost:3000/ws?token=<JWT>
```
Si el token es inválido, el servidor cierra con código `4001`.

### Mensajes — Cliente → Servidor

| type | Payload | Descripción |
|---|---|---|
| `CREATE_ROOM` | `{ roomId, fileName }` | Host activa una sala existente |
| `JOIN_ROOM` | `{ roomId }` | Viewer se une a una sala |
| `SCROLL` | `{ page, offsetY }` | Solo host — broadcast a viewers synced |
| `VIEWER_SCROLL` | `{ page, offsetY }` | Viewer registra su posición libre |
| `REJOIN_SYNC` | `{ roomId }` | Viewer vuelve a sincronizar con host |
| `PING` | — | Heartbeat |

### Mensajes — Servidor → Cliente

| type | Payload | Descripción |
|---|---|---|
| `ROOM_JOINED` | `{ roomId, code }` | Confirmación de unión |
| `SYNC` | `{ page, offsetY }` | Posición del host a viewers synced |
| `PARTICIPANTS` | `{ count }` | Actualización de participantes |
| `HOST_DISCONNECTED` | `{ lastPage, lastOffsetY, reconnectWindowSeconds }` | Host se desconectó |
| `HOST_RECONNECTED` | `{ page, offsetY, hostName }` | Host reconectó |
| `REJOIN_CONTEXT` | `{ roomStatus, yourLastPage, yourLastOffset, hostPage, hostOffset, hostConnected, hostName }` | Contexto al reconectar |
| `SESSION_CLOSED` | `{ reason: "host_timeout" }` | Sala cerrada por timeout |
| `ERROR` | `{ code, message }` | Error |
| `PONG` | — | Respuesta a PING |

### Códigos de error WebSocket

| code | Significado |
|---|---|
| `ROOM_NOT_FOUND` | La sala no existe |
| `NOT_AUTHORIZED` | Sin permiso para esta operación |
| `INVALID_MESSAGE` | Mensaje mal formado |

---

## Webhooks Stripe — `POST /webhooks/stripe`

Endpoint interno para recibir eventos de Stripe. Verifica firma con `STRIPE_WEBHOOK_SECRET`.

| Evento | Acción |
|---|---|
| `customer.subscription.updated` | Actualiza `current_period_end` |
| `customer.subscription.deleted` | Status → `cancelled` (si había `cancelled_at`) o `expired` |
| `invoice.payment_succeeded` | Status → `active`, actualiza `current_period_end` |
| `invoice.payment_failed` | Log (notificación por email pendiente) |
