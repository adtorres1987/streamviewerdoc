---
name: Phase 6 — Flutter Foundation and Auth
description: What was implemented in Phase 6, structural decisions, and what's next for Phase 7
type: project
---

Phase 6 implemented the Flutter app foundation at `app-mobile/syncpdf/` including all auth screens, providers, models, routing, and service layer.

**Why:** Bootstrap phase — no Flutter code existed before this. Spec lives at `app-mobile/syncpdf-flutter.md`.

**Key decisions and deviations:**
- `flutter create` could not be run (Flutter not installed on dev machine) — project scaffold was written manually. The project will need `flutter pub get` and `flutter pub run build_runner build --delete-conflicting-outputs` once Flutter is available.
- Freezed variant classes were given **public names** (`AuthInitial`, `AuthLoading`, `AuthAuthenticated`, `AuthUnauthenticated`, `AuthError`) instead of private (`_Initial`, etc.) so screens in other files can use `is AuthLoading` pattern matching. This is a project-wide convention to follow for any future freezed sealed unions used across files.
- `AuthNotifier` extends `_$AuthNotifier` (riverpod_annotation code-gen), NOT `AsyncNotifier<AuthState>`. State is `AuthState` (sync union), not `AsyncValue<AuthState>`.
- `currentUserProvider` and `currentSubscriptionProvider` are derived `@riverpod` functions watching `authNotifierProvider`.
- Router is a `@riverpod GoRouter` that re-evaluates redirect on every auth state change.
- Activation screen receives `email` via GoRouter `extra` (not query params).
- `HomeScreen` is a placeholder — groups/rooms come in Phase 7.

**Files created:**
- `lib/main.dart`, `lib/app.dart`
- `lib/core/constants.dart`, `theme.dart`, `exceptions.dart`, `router.dart`
- `lib/models/user.dart`, `subscription.dart`, `group.dart`, `room.dart`, `sync_event.dart`
- `lib/services/auth_service.dart`
- `lib/providers/auth_provider.dart`
- `lib/screens/login/login_screen.dart`, `register/register_screen.dart`, `activate/activate_screen.dart`, `forgot_password/forgot_password_screen.dart`, `home/home_screen.dart`
- `pubspec.yaml`, `analysis_options.yaml`, `build.yaml`

**How to apply:** Phase 7 adds groups/rooms screens and providers. Phase 8 adds WebSocket (SyncService + sync_provider). Do NOT re-implement auth screens or change the AuthState sealed union shape.
