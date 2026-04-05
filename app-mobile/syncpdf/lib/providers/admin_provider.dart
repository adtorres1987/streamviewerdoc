import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';

import '../models/client_detail.dart';
import '../providers/auth_provider.dart';
import '../services/admin_service.dart';

part 'admin_provider.g.dart';

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
// Clients list provider (supports optional search query)
// ---------------------------------------------------------------------------

@riverpod
class Clients extends _$Clients {
  @override
  Future<List<Map<String, dynamic>>> build({String? q}) async {
    final token = _requireToken(ref);
    return AdminService(token).getClients(q: q);
  }

  /// Re-fetches the clients list from the server.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

// ---------------------------------------------------------------------------
// Single client detail provider (parameterised by client id)
// ---------------------------------------------------------------------------

@riverpod
Future<ClientDetail> clientDetail(Ref ref, String id) async {
  final token = _requireToken(ref);
  final raw = await AdminService(token).getClientDetail(id);
  return ClientDetail.fromJson(raw);
}
