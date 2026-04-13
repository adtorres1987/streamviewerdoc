import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';

import '../models/room.dart';
import '../services/room_service.dart';

part 'room_provider.g.dart';

// ---------------------------------------------------------------------------
// Rooms list provider (parameterised by group id)
// ---------------------------------------------------------------------------

@riverpod
Future<List<Room>> rooms(Ref ref, String groupId) =>
    RoomService().getRooms(groupId);

// ---------------------------------------------------------------------------
// Single room provider (parameterised by room id)
// ---------------------------------------------------------------------------

@riverpod
Future<Room> room(Ref ref, String id) => RoomService().getRoom(id);

// ---------------------------------------------------------------------------
// Room actions notifier (create / close)
// ---------------------------------------------------------------------------

@riverpod
class RoomActions extends _$RoomActions {
  @override
  void build() {}

  /// Creates a new room inside [groupId] and invalidates the rooms list.
  Future<Room> createRoom(String groupId, String name) async {
    final room = await RoomService().createRoom(groupId, name);
    // Invalidate the rooms list for this group so it re-fetches.
    ref.invalidate(roomsProvider(groupId));
    return room;
  }

  /// Closes [roomId] and invalidates both the room detail and list providers.
  Future<void> closeRoom(String roomId, {required String groupId}) async {
    await RoomService().closeRoom(roomId);
    ref.invalidate(roomProvider(roomId));
    ref.invalidate(roomsProvider(groupId));
  }

  /// Reopens a closed [roomId] (host only) and refreshes list + detail.
  Future<Room> reopenRoom(String roomId, {required String groupId}) async {
    final room = await RoomService().reopenRoom(roomId);
    ref.invalidate(roomProvider(roomId));
    ref.invalidate(roomsProvider(groupId));
    return room;
  }

  /// Deletes [roomId] (group owner only) and refreshes the rooms list.
  Future<void> deleteRoom(String roomId, {required String groupId}) async {
    await RoomService().deleteRoom(roomId);
    ref.invalidate(roomsProvider(groupId));
  }
}
