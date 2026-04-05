# SyncPDF — Backend Architecture

## Stack tecnológico

| Capa | Tecnología |
|---|---|
| API REST | Node.js + Express |
| WebSocket | Node.js + ws |
| Base de datos | Supabase (PostgreSQL) |
| Autenticación | JWT + bcrypt |
| Pagos | Stripe (suscripciones recurrentes) |
| Emails | Resend o SendGrid |
| Hosting sugerido | Railway / Render / Fly.io |

---

## Estructura de archivos

```
server/
├── index.js                        # Entry point — HTTP + WS
├── .env
├── package.json
│
├── config/
│   ├── db.js                       # Cliente Supabase
│   ├── stripe.js                   # Cliente Stripe
│   └── mailer.js                   # Cliente email
│
├── routes/
│   ├── auth.js                     # Registro, login, activación
│   ├── groups.js                   # CRUD grupos + invitaciones
│   ├── rooms.js                    # CRUD salas
│   ├── admin.js                    # Endpoints de admin
│   ├── superadmin.js               # Endpoints de superadmin
│   └── payments.js                 # Stripe intents + portal
│
├── middleware/
│   ├── auth.js                     # Verificar JWT
│   ├── checkRole.js                # Verificar rol (admin, superadmin)
│   └── checkSubscription.js        # Verificar acceso activo
│
├── webhooks/
│   └── stripe.js                   # Eventos de Stripe
│
├── ws/
│   ├── ws_server.js                # Servidor WebSocket
│   └── room_manager.js             # Lógica de salas en memoria
│
└── utils/
    ├── generateCode.js             # Códigos de activación y sala
    ├── jwt.js                      # Sign y verify JWT
    └── email_templates.js          # Templates HTML de emails
```

---

## Base de datos

### users
```sql
CREATE TABLE users (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email            TEXT UNIQUE NOT NULL,
  password_hash    TEXT NOT NULL,
  full_name        TEXT NOT NULL,
  role             TEXT CHECK (role IN ('superadmin','admin','client')) NOT NULL,
  status           TEXT CHECK (status IN ('pending','active','suspended')) DEFAULT 'pending',
  invited_by       UUID REFERENCES users(id),
  activation_code  TEXT,
  activated_at     TIMESTAMP,
  created_at       TIMESTAMP DEFAULT now()
);
```

### subscriptions
```sql
CREATE TABLE subscriptions (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id              UUID REFERENCES users(id) ON DELETE CASCADE,
  status               TEXT CHECK (status IN ('trial','active','expired','cancelled')) DEFAULT 'trial',
  trial_days           INT DEFAULT 15,
  trial_ends_at        TIMESTAMP,
  current_period_end   TIMESTAMP,
  stripe_customer_id   TEXT,
  stripe_sub_id        TEXT,
  cancelled_at         TIMESTAMP
);
```

### groups
```sql
CREATE TABLE groups (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  owner_id    UUID REFERENCES users(id),
  created_at  TIMESTAMP DEFAULT now()
);
```

### group_members
```sql
CREATE TABLE group_members (
  group_id    UUID REFERENCES groups(id) ON DELETE CASCADE,
  user_id     UUID REFERENCES users(id) ON DELETE CASCADE,
  role        TEXT CHECK (role IN ('owner','member')) DEFAULT 'member',
  invited_by  UUID REFERENCES users(id),
  joined_at   TIMESTAMP DEFAULT now(),
  PRIMARY KEY (group_id, user_id)
);
```

### group_invitations
```sql
CREATE TABLE group_invitations (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id       UUID REFERENCES groups(id) ON DELETE CASCADE,
  invited_email  TEXT NOT NULL,
  invited_by     UUID REFERENCES users(id),
  token          TEXT UNIQUE NOT NULL,
  status         TEXT CHECK (status IN ('pending','accepted','expired')) DEFAULT 'pending',
  expires_at     TIMESTAMP NOT NULL
);
```

### rooms
```sql
CREATE TABLE rooms (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id               UUID REFERENCES groups(id) ON DELETE CASCADE,
  name                   TEXT NOT NULL,
  host_id                UUID REFERENCES users(id),
  code                   CHAR(6) UNIQUE NOT NULL,
  status                 TEXT CHECK (status IN ('waiting','active','host_disconnected','closed')) DEFAULT 'waiting',
  file_name              TEXT,
  last_page              INT DEFAULT 1,
  last_offset            DECIMAL DEFAULT 0,
  host_disconnected_at   TIMESTAMP,
  created_at             TIMESTAMP DEFAULT now(),
  closed_at              TIMESTAMP
);
```

### room_participants
```sql
CREATE TABLE room_participants (
  room_id       UUID REFERENCES rooms(id) ON DELETE CASCADE,
  user_id       UUID REFERENCES users(id) ON DELETE CASCADE,
  role          TEXT CHECK (role IN ('host','viewer')) NOT NULL,
  sync_state    TEXT CHECK (sync_state IN ('synced','free','disconnected')) DEFAULT 'synced',
  last_page     INT DEFAULT 1,
  last_offset   DECIMAL DEFAULT 0,
  joined_at     TIMESTAMP DEFAULT now(),
  left_at       TIMESTAMP,
  last_seen_at  TIMESTAMP DEFAULT now(),
  PRIMARY KEY (room_id, user_id)
);
```

### plans
```sql
CREATE TABLE plans (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name             TEXT NOT NULL,
  price_usd        DECIMAL NOT NULL,
  duration_days    INT NOT NULL,
  stripe_price_id  TEXT NOT NULL
);
```

### global_settings
```sql
CREATE TABLE global_settings (
  key          TEXT PRIMARY KEY,
  value        TEXT NOT NULL,
  updated_by   UUID REFERENCES users(id),
  updated_at   TIMESTAMP DEFAULT now()
);

-- Valores iniciales
INSERT INTO global_settings (key, value) VALUES
  ('default_trial_days', '15'),
  ('host_reconnect_timeout_minutes', '10');
```

---

## API REST

### Auth — `/auth`

| Método | Ruta | Descripción | Rol |
|---|---|---|---|
| POST | `/auth/register` | Registro de cliente | público |
| POST | `/auth/login` | Login | público |
| POST | `/auth/activate` | Activar cuenta con código | público |
| POST | `/auth/forgot-password` | Solicitar reset | público |
| POST | `/auth/reset-password` | Resetear contraseña | público |
| GET | `/auth/me` | Perfil + suscripción | autenticado |

### Grupos — `/groups`

| Método | Ruta | Descripción | Rol |
|---|---|---|---|
| GET | `/groups` | Mis grupos | client |
| POST | `/groups` | Crear grupo | client |
| GET | `/groups/:id` | Detalle del grupo | member |
| DELETE | `/groups/:id` | Eliminar grupo | owner |
| POST | `/groups/:id/invite` | Invitar cliente por email | member |
| GET | `/groups/invite/:token` | Validar token de invitación | público |
| POST | `/groups/invite/:token/accept` | Aceptar invitación | client |

### Salas — `/rooms`

| Método | Ruta | Descripción | Rol |
|---|---|---|---|
| GET | `/rooms?groupId=` | Salas del grupo | member |
| POST | `/rooms` | Crear sala | member |
| GET | `/rooms/:id` | Detalle de sala | member |
| PATCH | `/rooms/:id/close` | Cerrar sala | host |

### Pagos — `/payments`

| Método | Ruta | Descripción | Rol |
|---|---|---|---|
| GET | `/payments/plans` | Listar planes activos | client |
| POST | `/payments/subscribe` | Crear suscripción Stripe | client |
| POST | `/payments/cancel` | Cancelar al fin del período | client |
| GET | `/payments/status` | Estado de suscripción | client |

### Admin — `/admin`

| Método | Ruta | Descripción | Rol |
|---|---|---|---|
| GET | `/admin/clients` | Todos los clientes | admin |
| GET | `/admin/clients/:id` | Detalle de cliente | admin |
| PATCH | `/admin/clients/:id/trial` | Editar días de trial | admin |
| PATCH | `/admin/clients/:id/suspend` | Suspender cuenta | admin |
| PATCH | `/admin/clients/:id/activate` | Reactivar cuenta | admin |
| GET | `/admin/rooms` | Salas activas | admin |

### SuperAdmin — `/superadmin`

| Método | Ruta | Descripción | Rol |
|---|---|---|---|
| GET | `/superadmin/admins` | Listar admins | superadmin |
| POST | `/superadmin/admins/invite` | Invitar admin por email | superadmin |
| PATCH | `/superadmin/admins/:id/suspend` | Suspender admin | superadmin |
| GET | `/superadmin/settings` | Ver configuración global | superadmin |
| PATCH | `/superadmin/settings` | Editar configuración global | superadmin |
| GET | `/superadmin/metrics` | Métricas globales | superadmin |

---

## Protocolo WebSocket

### Conexión
```
wss://your-server.com/ws?token=JWT
```
El servidor valida el JWT al conectar. Si es inválido, cierra la conexión con código 4001.

### Mensajes — Cliente → Servidor

```json
// Crear sala (host)
{ "type": "CREATE_ROOM", "roomId": "uuid", "fileName": "doc.pdf" }

// Unirse a sala
{ "type": "JOIN_ROOM", "roomId": "uuid" }

// Broadcast de scroll (solo host)
{ "type": "SCROLL", "page": 4, "offsetY": 0.73 }

// Scroll libre del viewer (guardado en server)
{ "type": "VIEWER_SCROLL", "page": 3, "offsetY": 0.55 }

// Viewer acepta resync con host
{ "type": "REJOIN_SYNC", "roomId": "uuid" }

// Heartbeat
{ "type": "PING" }
```

### Mensajes — Servidor → Cliente

```json
// Sala creada / unión confirmada
{ "type": "ROOM_JOINED", "roomId": "uuid", "code": "XK49PQ" }

// Sync de scroll a viewers
{ "type": "SYNC", "page": 4, "offsetY": 0.73 }

// Actualización de participantes
{ "type": "PARTICIPANTS", "count": 3 }

// Host se desconectó
{
  "type": "HOST_DISCONNECTED",
  "lastPage": 4,
  "lastOffsetY": 0.73,
  "reconnectWindowSeconds": 600
}

// Host reconectó
{
  "type": "HOST_RECONNECTED",
  "page": 4,
  "offsetY": 0.73,
  "hostName": "Carlos"
}

// Viewer reconecta — contexto completo
{
  "type": "REJOIN_CONTEXT",
  "roomStatus": "active",
  "yourLastPage": 3,
  "yourLastOffset": 0.61,
  "hostPage": 5,
  "hostOffset": 0.22,
  "hostConnected": true,
  "hostName": "Carlos"
}

// Sala cerrada por timeout
{ "type": "SESSION_CLOSED", "reason": "host_timeout" }

// Error
{ "type": "ERROR", "code": "ROOM_NOT_FOUND", "message": "La sala no existe" }

// Heartbeat
{ "type": "PONG" }
```

---

## Lógica WebSocket — room_manager.js

### Estructura en memoria
```javascript
rooms = Map<roomId, {
  hostId:              string,
  hostName:            string,
  hostSocket:          WebSocket | null,
  status:              'waiting' | 'active' | 'host_disconnected' | 'closed',
  lastPage:            number,
  lastOffset:          number,
  hostDisconnectedAt:  Date | null,
  closeTimer:          Timeout | null,
  participants:        Map<userId, {
    socket:     WebSocket,
    role:       'host' | 'viewer',
    syncState:  'synced' | 'free' | 'disconnected',
    lastPage:   number,
    lastOffset: number,
  }>
}>
```

### Reglas críticas

```
1. Solo el host puede hacer broadcast de SCROLL
2. SCROLL se envía únicamente a viewers con syncState = 'synced'
3. Al HOST_DISCONNECTED → todos los viewers pasan a syncState = 'free'
4. Al HOST_RECONNECTED → ninguno cambia de estado automáticamente
5. Solo cambia a 'synced' si el viewer envía REJOIN_SYNC explícitamente
6. VIEWER_SCROLL se persiste en DB con debounce de 5 segundos
7. Al desconectarse cualquier participante → persistir posición inmediatamente
8. Timer de cierre: 10 minutos sin host → SESSION_CLOSED a todos
```

### Persistencia — cuándo escribir a Supabase

| Evento | Qué se persiste |
|---|---|
| Viewer scroll (cada 5s debounce) | `room_participants.last_page / last_offset` |
| Cualquier participante se desconecta | Su posición inmediatamente |
| Host hace scroll | `rooms.last_page / last_offset` (cada 5s debounce) |
| Host se desconecta | `rooms.host_disconnected_at`, posición del host |
| Sala se cierra | `rooms.closed_at`, posición final de todos |

---

## Flujo de suscripción con Stripe

### Alta
```
1. POST /auth/register → crear user + crear Stripe Customer
2. POST /payments/subscribe → crear Stripe Subscription con trial_period_days
3. Stripe no cobra durante el trial
4. Día N (fin de trial) → Stripe intenta cobrar
5. Webhook payment_intent.succeeded → status = 'active'
6. Webhook invoice.payment_failed → reintentos automáticos de Stripe
7. Webhook customer.subscription.deleted → status = 'expired'
```

### Cancelación
```
1. POST /payments/cancel
2. Server → stripe.subscriptions.update({ cancel_at_period_end: true })
3. Guardar subscriptions.cancelled_at = now
4. Cliente mantiene acceso hasta current_period_end
5. Webhook customer.subscription.deleted → status = 'cancelled'
```

### Webhooks que escuchar
```
customer.subscription.updated    → actualizar current_period_end
customer.subscription.deleted    → status = expired / cancelled
invoice.payment_succeeded        → status = active
invoice.payment_failed           → notificar al usuario
```

---

## Variables de entorno

```env
# Server
PORT=3000
WS_PORT=3001
JWT_SECRET=your_jwt_secret
JWT_EXPIRES_IN=7d

# Supabase
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_KEY=your_service_key

# Stripe
STRIPE_SECRET_KEY=sk_live_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx

# Email
RESEND_API_KEY=re_xxx
EMAIL_FROM=noreply@syncpdf.app

# Config
HOST_RECONNECT_TIMEOUT_MIN=10
SCROLL_DEBOUNCE_MS=5000
```

---

## Seguridad

- JWT en header `Authorization: Bearer <token>`
- Passwords con bcrypt (salt rounds: 12)
- Códigos de activación: 6 dígitos, expiran en 24h
- Tokens de invitación a grupos: UUID v4, expiran en 48h
- Stripe Webhook: verificar firma con `stripe.webhooks.constructEvent`
- Rate limiting en `/auth/*`: máximo 10 requests/minuto por IP
- Solo el host puede hacer SCROLL broadcast — validado en server, no solo en cliente
- Viewers no pueden unirse a salas de grupos a los que no pertenecen
