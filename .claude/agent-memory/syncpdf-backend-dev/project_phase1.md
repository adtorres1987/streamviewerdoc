---
name: Phase 1–5 Implementation Status
description: What was built in Phases 1–5 (auth, middleware, groups, rooms, payments, Stripe webhooks, admin/superadmin REST API), key non-obvious decisions, and what remains
type: project
---

Phase 1 and Phase 2 are complete.

---

## Phase 1 — Auth infrastructure

Entry point is `server/index.js`. All 6 `/auth` endpoints implemented in `server/routes/auth.js`.

### Key non-obvious decision: activation code expiry

The `users` table schema has no `activation_expires_at` column. Expiry is encoded in the column value itself as a composite string:

```
"<6-digit-code>:<unix-ms-expiry>"
example: "483920:1712012345678"
```

`generateActivationCode()` returns `{ raw, stored }`. `validateActivationCode(stored, inputCode)` returns `{ valid, expired }`. Same convention reused for password reset codes.

### Rate limiting

`/auth/*` is rate-limited to 10 req/min per IP using `express-rate-limit`, applied in `index.js` before mounting the auth router.

### Stripe webhook note (for future phase)

Stripe webhook route MUST be mounted BEFORE `express.json()` to receive raw body. Comment already placed in `index.js` as a reminder.

---

## Phase 2 — Middleware + Groups + Rooms REST API

### Middleware

- `middleware/checkRole.js` — variadic: `checkRole('admin', 'superadmin')`. Reads `req.user.role`, returns 403 if not in the allowed set.
- `middleware/checkSubscription.js` — checks `users.status` (suspended → 403) then `subscriptions.status` (must be `trial` or `active`). Async; uses Supabase service key.

### Groups router (`routes/groups.js` → mounted at `/groups`)

Non-obvious ordering: `/invite/:token` and `/invite/:token/accept` are declared BEFORE `/:id` to prevent Express from matching "invite" as a group ID.

Invitation tokens: `crypto.randomUUID()`, 48h expiry stored as ISO timestamp in `group_invitations.expires_at`. When token is validated or accepted, if expired the row status is updated to `'expired'` in DB immediately.

On group creation failure after the group row exists (member insert fails), the group row is deleted as cleanup.

### Rooms router (`routes/rooms.js` → mounted at `/rooms`)

Room code uniqueness: `generateRoomCode()` is retried up to 5 times on collision before returning 500.

On room creation: inserts into `rooms` then `room_participants` with `role='host'`, `sync_state='synced'`. If participant insert fails, the room row is deleted as cleanup.

`PATCH /rooms/:id/close` checks that caller is the host (`rooms.host_id === req.user.id`), not just a group member.

---

## Implemented routes (Phases 1 + 2)

| Method | Path | Auth | Subscription |
|--------|------|------|--------------|
| POST | /auth/register | public | — |
| POST | /auth/login | public | — |
| POST | /auth/activate | public | — |
| POST | /auth/forgot-password | public | — |
| POST | /auth/reset-password | public | — |
| GET | /auth/me | JWT | — |
| GET | /health | public | — |
| GET | /groups | JWT | — |
| POST | /groups | JWT | required |
| GET | /groups/invite/:token | public | — |
| POST | /groups/invite/:token/accept | JWT | — |
| GET | /groups/:id | JWT | — |
| DELETE | /groups/:id | JWT | — |
| POST | /groups/:id/invite | JWT | — |
| GET | /rooms | JWT | — |
| POST | /rooms | JWT | required |
| GET | /rooms/:id | JWT | — |
| PATCH | /rooms/:id/close | JWT | — |

---

---

## Phase 4 — Stripe configuration, payments API, webhook handler

### config/stripe.js

Simple singleton: `new Stripe(process.env.STRIPE_SECRET_KEY)`. Required by both `routes/payments.js` and `webhooks/stripe.js`.

### routes/payments.js (mounted at /payments)

`checkSubscription` is intentionally NOT applied to any payments route — users must be able to subscribe even with expired/missing subscriptions.

`POST /payments/subscribe` logic: fetches plan by `planId` to get `stripe_price_id`; gets or creates Stripe customer (checks `subscriptions.stripe_customer_id` first); reads `default_trial_days` from `global_settings` table (key/value store, default 15 if missing); creates Stripe subscription; upserts `subscriptions` row (update if exists, insert if not).

`POST /payments/cancel`: calls `stripe.subscriptions.update(id, { cancel_at_period_end: true })`, writes `cancelled_at = now()` to DB.

### webhooks/stripe.js (mounted at /webhooks)

The webhook route receives raw body via middleware set in `index.js` that runs BEFORE `express.json()`. The middleware stores the buffer as `req.rawBody` so `stripe.webhooks.constructEvent` can verify the signature.

`customer.subscription.deleted`: distinguishes voluntary cancel (cancelled_at already set → status `'cancelled'`) from forced expiry (no cancelled_at → status `'expired'`).

`invoice.payment_succeeded`: retrieves the Stripe subscription by ID to get an accurate `current_period_end` (invoice object alone does not carry it reliably).

`invoice.payment_failed`: logs warning only. TODO comment left for future email notification via Resend.

### index.js raw body middleware ordering

```javascript
// BEFORE express.json():
app.use('/webhooks/stripe', express.raw({ type: 'application/json' }), (req, _res, next) => {
  req.rawBody = req.body;
  next();
});
app.use(express.json());
// ...
app.use('/payments', paymentsRouter);
app.use('/webhooks', stripeWebhookRouter);
```

The router is mounted at `/webhooks` and handles `POST /` internally, so the effective path is `POST /webhooks/stripe`.

---

## Implemented routes (Phases 1–4)

| Method | Path | Auth | Subscription |
|--------|------|------|--------------|
| POST | /auth/register | public | — |
| POST | /auth/login | public | — |
| POST | /auth/activate | public | — |
| POST | /auth/forgot-password | public | — |
| POST | /auth/reset-password | public | — |
| GET | /auth/me | JWT | — |
| GET | /health | public | — |
| GET | /groups | JWT | — |
| POST | /groups | JWT | required |
| GET | /groups/invite/:token | public | — |
| POST | /groups/invite/:token/accept | JWT | — |
| GET | /groups/:id | JWT | — |
| DELETE | /groups/:id | JWT | — |
| POST | /groups/:id/invite | JWT | — |
| GET | /rooms | JWT | — |
| POST | /rooms | JWT | required |
| GET | /rooms/:id | JWT | — |
| PATCH | /rooms/:id/close | JWT | — |
| GET | /payments/plans | JWT | — |
| POST | /payments/subscribe | JWT | skipped |
| POST | /payments/cancel | JWT | skipped |
| GET | /payments/status | JWT | skipped |
| POST | /webhooks/stripe | raw body | — |

---

---

## Phase 5 — Admin and SuperAdmin REST API

### routes/admin.js (mounted at /admin)

All routes apply `authenticate` + `checkRole('admin', 'superadmin')` at the router level (not per-route).

`GET /admin/clients`: selects users with `role='client'`, supports optional `?q=` via Supabase `.or('full_name.ilike.%term%,email.ilike.%term%')`. Flattens the one-to-many `subscriptions` array to `subscriptions[0]` for the response shape.

`GET /admin/clients/:id`: fetches user + subscription, then separately queries `group_members` joined with `groups`, and `room_participants` joined with `rooms` (limit 10, ordered by `joined_at DESC`). The `.eq('role', 'client')` guard on the user lookup ensures IDs from other roles return 404.

`PATCH /admin/clients/:id/trial`: only proceeds if subscription `status = 'trial'`. Recalculates `trial_ends_at = now() + days`. Returns 409 if subscription is not in trial.

`GET /admin/rooms`: fetches rooms `IN ('active', 'host_disconnected')`, joins host via `users(full_name)`. Participant counts are fetched in a second query (`.is('left_at', null)`) and assembled into a map — Supabase aggregate functions are not used here since the count query is straightforward and avoids a raw SQL call.

### routes/superadmin.js (mounted at /superadmin)

All routes apply `authenticate` + `checkRole('superadmin')` at the router level.

`POST /superadmin/admins/invite`: inserts admin with `password_hash: ''` (placeholder — admin sets password on activation). Activation code is the invite credential; invite link is `APP_URL/admin/activate?email=...&code=...`. `APP_URL` defaults to `https://app.syncpdf.io` if not set in env.

`GET /superadmin/metrics` MRR: queries active subscriptions with `stripe_sub_id NOT NULL`, selects `plans(price_usd)` via foreign key join, sums `price_usd` in JS. The `plans` table relationship is assumed to be via a `plan_id` foreign key on `subscriptions` (not explicitly in the schema doc, so the join relies on Supabase PostgREST inferring the FK). If the FK does not exist, this query returns empty — a TODO to note.

`PATCH /superadmin/settings`: accepts either `{ key, value }` (single) or `{ settings: {...} }` (bulk). Uses Supabase `.upsert(..., { onConflict: 'key' })`. Returns the full settings object after the upsert.

---

## Implemented routes (Phases 1–5)

| Method | Path | Auth | Role |
|--------|------|------|------|
| POST | /auth/register | public | — |
| POST | /auth/login | public | — |
| POST | /auth/activate | public | — |
| POST | /auth/forgot-password | public | — |
| POST | /auth/reset-password | public | — |
| GET | /auth/me | JWT | any |
| GET | /health | public | — |
| GET | /groups | JWT | client+ |
| POST | /groups | JWT+sub | client+ |
| GET | /groups/invite/:token | public | — |
| POST | /groups/invite/:token/accept | JWT | client+ |
| GET | /groups/:id | JWT | client+ |
| DELETE | /groups/:id | JWT | client+ |
| POST | /groups/:id/invite | JWT | client+ |
| GET | /rooms | JWT | client+ |
| POST | /rooms | JWT+sub | client+ |
| GET | /rooms/:id | JWT | client+ |
| PATCH | /rooms/:id/close | JWT | client+ |
| GET | /payments/plans | JWT | client+ |
| POST | /payments/subscribe | JWT | client+ |
| POST | /payments/cancel | JWT | client+ |
| GET | /payments/status | JWT | client+ |
| POST | /webhooks/stripe | raw body | — |
| GET | /admin/clients | JWT | admin+ |
| GET | /admin/clients/:id | JWT | admin+ |
| PATCH | /admin/clients/:id/trial | JWT | admin+ |
| PATCH | /admin/clients/:id/suspend | JWT | admin+ |
| PATCH | /admin/clients/:id/activate | JWT | admin+ |
| GET | /admin/rooms | JWT | admin+ |
| GET | /superadmin/admins | JWT | superadmin |
| POST | /superadmin/admins/invite | JWT | superadmin |
| PATCH | /superadmin/admins/:id/suspend | JWT | superadmin |
| GET | /superadmin/settings | JWT | superadmin |
| PATCH | /superadmin/settings | JWT | superadmin |
| GET | /superadmin/metrics | JWT | superadmin |

---

## Not yet implemented (future phases)

- `ws/wsServer.js`, `ws/room_manager.js`, `ws/handlers/`
