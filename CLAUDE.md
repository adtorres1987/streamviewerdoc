# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**SyncPDF** — a collaborative PDF viewer that synchronizes real-time navigation between a host and multiple viewers. The architecture is fully documented but not yet implemented. Full specs live in:
- `backend/syncpdf-backend.md` — backend architecture, DB schema, API routes, WebSocket protocol
- `app-mobile/syncpdf-flutter.md` — Flutter app architecture, providers, models, navigation
- `web-admin/syncpdf-webadmin.md` — web admin panel architecture (Next.js)

## Repository Structure

```
partiapp/
├── backend/          # Will contain: server/ (Node.js + Express + WebSocket)
├── app-mobile/       # Will contain: Flutter project
├── web-admin/        # Will contain: Next.js admin panel (admin + superadmin only)
├── backend/syncpdf-backend.md
├── app-mobile/syncpdf-flutter.md
└── web-admin/syncpdf-webadmin.md
```

## Who uses what
- **Clients** → mobile app only
- **Admins** → web admin panel (`/admin/*`) + mobile app (como client si aplica)
- **Superadmin** → web admin panel (`/superadmin/*` + `/admin/*`)

## Backend (Node.js)

**Stack:** Express REST API + `ws` WebSocket server + Supabase (PostgreSQL) + Stripe + bcrypt/JWT

**Commands** (once `server/` exists):
```bash
cd server
npm install
npm start          # or node index.js
```

**Required `.env`:**
```
PORT=3000
WS_PORT=3001
JWT_SECRET=...
JWT_EXPIRES_IN=7d
SUPABASE_URL=...
SUPABASE_SERVICE_KEY=...
STRIPE_SECRET_KEY=...
STRIPE_WEBHOOK_SECRET=...
RESEND_API_KEY=...
EMAIL_FROM=noreply@syncpdf.app
HOST_RECONNECT_TIMEOUT_MIN=10
SCROLL_DEBOUNCE_MS=5000
```

**File layout:** `server/index.js` → `config/` → `routes/` → `middleware/` → `ws/` → `webhooks/` → `utils/`

**Middleware chain:** `auth.js` (JWT) → `checkRole.js` → `checkSubscription.js`

## Mobile (Flutter)

**Stack:** Flutter/Dart + Riverpod + GoRouter + syncfusion_flutter_pdfviewer + web_socket_channel + supabase_flutter + flutter_stripe

**Commands:**
```bash
cd app-mobile
flutter pub get
flutter pub run build_runner build    # generate Riverpod providers
flutter run
flutter build apk / flutter build ios
```

**Environment constants** injected via `--dart-define`:
```
API_URL, WS_URL, STRIPE_PUBLISHABLE_KEY, SUPABASE_URL, SUPABASE_ANON_KEY
```

**File layout:** `lib/main.dart` → `app.dart` → `core/` | `models/` | `services/` | `providers/` | `screens/` | `widgets/`

## Web Admin (Next.js)

**Stack:** Next.js 14 (App Router) + Tailwind CSS + shadcn/ui + TanStack Query v5 + Zustand + Recharts

**Commands:**
```bash
cd web-admin
npm install
npm run dev      # http://localhost:3001
npm run build
npm run lint
```

**Required `.env.local`:**
```
NEXT_PUBLIC_API_URL=http://localhost:3000
```

**File layout:** `src/app/` (pages + layouts) → `src/components/` → `src/hooks/` (TanStack Query) → `src/lib/api.ts` (fetch wrapper) → `src/lib/auth.ts` (Zustand)

**Auth:** JWT stored in Zustand + httpOnly cookie. `middleware.ts` protects routes before render. Layouts do a secondary role check. Only `admin` and `superadmin` can log in.

**Data flow:** all fetching is client-side (TanStack Query) — no SSR for protected data. Mutations invalidate queries for optimistic UI refresh.

## Key Architecture Decisions

### Role hierarchy
`superadmin > admin > client` — enforced server-side via `checkRole` middleware and GoRouter redirect guards.

### WebSocket protocol
- Connection: `wss://host/ws?token=JWT` — server closes with code `4001` on invalid JWT
- Only the **host** can send `SCROLL` broadcasts — enforced server-side, not client-side
- Viewers only receive scroll events when their `syncState = 'synced'`
- PING/PONG heartbeat every 30s

### Viewer sync state machine
```
synced → free          on HOST_DISCONNECTED
synced → disconnected  on network loss
free   → synced        on REJOIN_SYNC (viewer explicit opt-in)
disconnected → free    on reconnect (restores last personal position)
any    → closed        on SESSION_CLOSED
```

### Room state machine
`waiting → active → host_disconnected → closed`  
Host has a 10-minute reconnect window (`host_reconnect_timeout_minutes` global setting). Timer starts on host disconnect; fires `SESSION_CLOSED` to all viewers on expiry.

### Persistence strategy (Supabase writes)
- Viewer scroll: debounced 5s → `room_participants.last_page / last_offset`
- Host scroll: debounced 5s → `rooms.last_page / last_offset`
- Any participant disconnects: immediate write
- Host disconnects: write `rooms.host_disconnected_at` + final position

### Auto-reconnect (mobile)
Exponential backoff: 1s → 2s → 4s → 8s → 16s → 30s max. On reconnect, auto-rejoin using the stored `roomId`. Re-trigger reconnect on foreground via `AppLifecycleListener`.

### Subscription flow
`trial (15 days) → Stripe charges on trial end → webhooks update status`  
Webhook events: `customer.subscription.updated/deleted`, `invoice.payment_succeeded/failed`  
Cancel sets `cancel_at_period_end: true` — access continues until `current_period_end`.

### PDF performance
- `SfPdfViewer` renders lazy — never load full PDF into memory
- Restore position with `initialScrollOffset` to avoid visible scroll jump
- Host: 50ms debounce on scroll listener before broadcasting
- `_suppressNextScroll` flag in `PDFViewerScreen` prevents echo when viewer receives `SYNC` and programmatically scrolls

### Deep linking (group invitations)
Scheme: `syncpdf://invite?token=xxxxx`  
Token is UUID v4, expires 48h. Unauthenticated users go to `RegisterScreen` with token pre-loaded; authenticated users see confirmation dialog.

## Database Schema Summary

9 tables: `users`, `subscriptions`, `groups`, `group_members`, `group_invitations`, `rooms`, `room_participants`, `plans`, `global_settings`

Critical constraints:
- `users.role` ∈ `{superadmin, admin, client}`
- `users.status` ∈ `{pending, active, suspended}`
- `subscriptions.status` ∈ `{trial, active, expired, cancelled}`
- `rooms.status` ∈ `{waiting, active, host_disconnected, closed}`
- `room_participants.sync_state` ∈ `{synced, free, disconnected}`

WebSocket room state lives **in memory** (`room_manager.js` Map), not in DB. DB is for persistence/recovery only.

## Security Rules
- bcrypt 12 salt rounds for passwords
- Activation codes: 6 digits, 24h expiry
- Group invitation tokens: UUID v4, 48h expiry
- Rate limiting on `/auth/*`: 10 req/min per IP
- Stripe webhooks verified with `stripe.webhooks.constructEvent`
- Viewers cannot join rooms in groups they don't belong to (server-validated)
