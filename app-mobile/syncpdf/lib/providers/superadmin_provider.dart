import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';

import '../models/admin_user.dart';
import '../models/global_settings.dart';
import '../models/metrics.dart';
import '../providers/auth_provider.dart';
import '../services/superadmin_service.dart';

part 'superadmin_provider.g.dart';

// ---------------------------------------------------------------------------
// Helper — extracts the token from auth state; throws if not authenticated.
// ---------------------------------------------------------------------------

String _requireToken(Ref ref) {
  final authState = ref.read(authNotifierProvider);
  return switch (authState) {
    AuthAuthenticated(:final token) => token,
    _ => throw StateError('Not authenticated'),
  };
}

// ---------------------------------------------------------------------------
// Admins list provider
// ---------------------------------------------------------------------------

@riverpod
class Admins extends _$Admins {
  @override
  Future<List<AdminUser>> build() async {
    final token = _requireToken(ref);
    final raw = await SuperAdminService(token).getAdmins();
    return raw.map(AdminUser.fromJson).toList();
  }

  /// Re-fetches the admins list from the server.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Invites a new admin and refreshes the list.
  Future<void> inviteAdmin(String email, String fullName) async {
    final token = _requireToken(ref);
    await SuperAdminService(token).inviteAdmin(email, fullName);
    ref.invalidateSelf();
  }

  /// Suspends an admin and refreshes the list.
  Future<void> suspendAdmin(String id) async {
    final token = _requireToken(ref);
    await SuperAdminService(token).suspendAdmin(id);
    ref.invalidateSelf();
  }

  /// Activates a suspended admin and refreshes the list.
  Future<void> activateAdmin(String id) async {
    final token = _requireToken(ref);
    await SuperAdminService(token).activateAdmin(id);
    ref.invalidateSelf();
  }
}

// ---------------------------------------------------------------------------
// Settings provider
// ---------------------------------------------------------------------------

@riverpod
class Settings extends _$Settings {
  @override
  Future<GlobalSettings> build() async {
    final token = _requireToken(ref);
    final raw = await SuperAdminService(token).getSettings();
    return GlobalSettings.fromJson(raw);
  }

  /// Re-fetches settings from the server.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Persists updated settings and refreshes local state.
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    final token = _requireToken(ref);
    await SuperAdminService(token).updateSettings(settings);
    ref.invalidateSelf();
  }
}

// ---------------------------------------------------------------------------
// Metrics provider
// ---------------------------------------------------------------------------

@riverpod
Future<Metrics> metrics(Ref ref) async {
  final token = _requireToken(ref);
  final raw = await SuperAdminService(token).getMetrics();
  return Metrics.fromJson(raw);
}
