---
name: Project Conventions — Flutter SyncPDF
description: Established coding conventions for the SyncPDF Flutter app that must be followed in all future phases
type: project
---

**Freezed sealed unions across files:** Use public variant class names (e.g., `AuthInitial`, `AuthLoading`) not private ones (`_Initial`). Private names can only be used in the same file as the freezed class.

**Why:** Screens in separate files need `is AuthLoading` pattern matching — private variants are inaccessible outside the declaring file.

**AuthState provider name:** The provider is `authNotifierProvider` (from `@riverpod class AuthNotifier`). Derived providers: `currentUserProvider`, `currentSubscriptionProvider`, `authIsLoadingProvider`.

**Router provider name:** `routerProvider` (from `@riverpod GoRouter router(Ref ref)`).

**Screen navigation:** Always use GoRouter `context.go()` for replacing stack (post-login), `context.push()` for stacking (register → activate). Email passed to ActivateScreen via `extra`, not query params.

**Error display:** All screens use `ref.listen(authNotifierProvider, ...)` to show `SnackBar` on `AuthError`. Never show inline error text widgets for transient auth errors.

**How to apply:** Follow in all Phase 7+ screens. Any new freezed sealed class used across files must have public variant names.
