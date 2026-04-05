---
name: Phase 7 — Groups, Rooms, and Subscription Guard
description: What was implemented in Phase 7, key decisions, and what's next for Phase 8
type: project
---

Phase 7 added groups, rooms, subscription management, paywall, and invite deep-link handling to the Flutter app.

**Why:** Phase 6 left HomeScreen as a placeholder. Phase 7 fulfills the client-facing core flows before Phase 8 (WebSocket + PDF viewer).

**Key decisions and deviations:**

- **JWT key alignment:** `auth_provider.dart` writes the JWT under key `'syncpdf_auth_token'`. All Phase 7 services read from `AppConstants.tokenStorageKey` (which is `'syncpdf_auth_token'`), not a raw `'auth_token'` string. This constant was added to `core/constants.dart` to avoid divergence.

- **API response key casing:** The backend returns camelCase keys in some endpoints (`fullName`, `joinedAt`, `syncState`, `lastPage`, `lastOffset`) even though the DB uses snake_case. `GroupMember` and `RoomParticipant` models use `@JsonKey(name: 'fullName')` etc. to match actual API output. `Plan` uses snake_case `@JsonKey` since the plans endpoint returns snake_case.

- **SubscriptionService normalises keys:** `/payments/status` returns camelCase (`trialEndsAt`, `currentPeriodEnd`, `cancelledAt`) while `Subscription.fromJson` expects snake_case. `SubscriptionService.getStatus()` manually remaps before calling `Subscription.fromJson`.

- **HomeScreen moved:** The real `HomeScreen` now lives at `screens/client/home_screen.dart`. The old placeholder at `screens/home/home_screen.dart` is still present but the router now imports from `client/`. Do NOT delete the old file until Phase 6's `home/` folder is cleaned up.

- **RegisterScreen updated:** Added optional `inviteToken` parameter to `RegisterScreen` — no other logic changed. The token is available in state after registration for future post-activation invite acceptance (not yet wired).

- **`checkRoomAccess` in `core/guards.dart`:** Subscription guard helper for use in screen `onTap`/`onPressed`. Pushes `/paywall` and returns false if subscription is inactive.

- **Router subscription redirect:** The global redirect in `router.dart` now also watches `isSubscriptionActiveProvider`. Client users whose subscription is inactive are redirected to `/paywall` when visiting `/home`, `/groups/*`, or `/room/*`. `/paywall` and `/subscription` are exempt from this guard.

- **PaywallScreen — no Stripe SDK yet:** Phase 7 calls `POST /payments/subscribe` directly. Phase 9 will wrap this with the Stripe payment sheet.

- **`file_picker: ^8.0.0` added to pubspec.yaml.**

**Files created:**
- `lib/models/group_member.dart`, `room_participant.dart`, `plan.dart`
- `lib/services/group_service.dart`, `room_service.dart`, `subscription_service.dart`
- `lib/providers/group_provider.dart`, `room_provider.dart`, `subscription_provider.dart`
- `lib/core/guards.dart`
- `lib/widgets/subscription_badge.dart`
- `lib/screens/client/home_screen.dart` (replaces placeholder)
- `lib/screens/client/group_screen.dart`
- `lib/screens/client/subscription_screen.dart`
- `lib/screens/client/paywall_screen.dart`
- `lib/screens/client/pdf_viewer_screen.dart` (Phase 8 placeholder)
- `lib/screens/invite/invite_accept_screen.dart`

**Files modified:**
- `lib/core/router.dart` — added Phase 7 routes and subscription guard
- `lib/core/constants.dart` — added `tokenStorageKey`
- `lib/screens/register/register_screen.dart` — added optional `inviteToken` param
- `pubspec.yaml` — added `file_picker: ^8.0.0`

**How to apply:** Phase 8 adds WebSocket SyncService, sync_provider, and real PDF viewer in `screens/client/pdf_viewer_screen.dart`. Do NOT re-implement services or providers created here.
