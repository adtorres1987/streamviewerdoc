---
name: Phase 9 — Stripe Payments and Subscription Flow
description: All payment/subscription screens, PaymentService, and Stripe init implemented in Phase 9
type: project
---

Phase 9 is complete. The following was implemented:

**New files:**
- `lib/services/payment_service.dart` — thin Stripe-specific service wrapping POST /payments/subscribe and /payments/cancel. Uses same Dio + FlutterSecureStorage pattern as SubscriptionService. No payment sheet (trial-based flow; Stripe charges via webhook at trial end).

**Modified files:**
- `lib/main.dart` — added `Stripe.publishableKey = AppConstants.stripePublishableKey` and `await Stripe.instance.applySettings()` before `runApp`.
- `pubspec.yaml` — added `intl: ^0.19.0` for date formatting.
- `lib/screens/client/paywall_screen.dart` — switched from `SubscriptionService().subscribe()` to `PaymentService().subscribe()`. Added bottom note about Stripe charging at trial end. Uses `context.pop()` (GoRouter) instead of `Navigator.of(context).pop()`.
- `lib/screens/client/subscription_screen.dart` — converted inner state widget to `ConsumerStatefulWidget`. Uses `PaymentService().cancel()`. Dates formatted with `DateFormat('d MMM yyyy', 'es')`. Added days-remaining `LinearProgressIndicator`. Shows `_InfoBanner` "Acceso hasta: {date}" when `cancelledAt` is set instead of cancel button.
- `lib/widgets/subscription_badge.dart` — now distinguishes: trial (amber, "Trial · X días"), active (green, "Activo"), active+cancelledAt (orange, "Cancelando"), cancelled+isCancellingAtPeriodEnd (orange, "Cancelando"), cancelled (grey, "Cancelado"), default (red, "Expirado").
- `lib/screens/client/group_screen.dart` — after `createRoom()` succeeds, immediately navigates to `/room/${room.id}?role=host`.

**Why:** `SubscriptionService` already handles generic payment API calls; `PaymentService` is the Stripe-specific layer that will own the payment sheet in a future phase when a server-side PaymentIntent is added.

**How to apply:** When adding Stripe payment sheet in a future phase, add it inside `PaymentService.subscribe()` after getting a client_secret from the backend. Do not put Stripe SDK calls in screens.

**Key design note:** `stripePublishableKey` in `AppConstants` has no `defaultValue` — it will be empty string in dev if not passed via `--dart-define`. This is intentional to avoid committing test keys.

**Next phase (Phase 10):** Push notifications (firebase_messaging).
