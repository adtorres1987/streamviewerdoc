import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';

import '../models/group.dart';
import '../services/group_service.dart';

part 'group_provider.g.dart';

// ---------------------------------------------------------------------------
// Groups list provider
// ---------------------------------------------------------------------------

@riverpod
class Groups extends _$Groups {
  @override
  Future<List<Group>> build() => GroupService().getGroups();

  /// Re-fetches the groups list from the server.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Creates a new group and refreshes the list.
  Future<Group> createGroup(String name) async {
    final group = await GroupService().createGroup(name);
    ref.invalidateSelf();
    return group;
  }
}

// ---------------------------------------------------------------------------
// Single group provider (parameterised by group id)
// ---------------------------------------------------------------------------

@riverpod
Future<Group> group(Ref ref, String id) => GroupService().getGroup(id);

// ---------------------------------------------------------------------------
// Pending invitations provider
// ---------------------------------------------------------------------------

@riverpod
class PendingInvitations extends _$PendingInvitations {
  @override
  Future<List<PendingInvitation>> build() =>
      GroupService().getPendingInvitations();

  /// Accepts an invitation and refreshes groups + this list.
  Future<void> accept(String token) async {
    await GroupService().acceptInvite(token);
    ref.invalidate(groupsProvider);
    ref.invalidateSelf();
  }

  /// Declines an invitation optimistically (no backend call).
  void decline(String id) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.where((inv) => inv.id != id).toList());
  }
}
