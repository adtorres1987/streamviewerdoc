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
