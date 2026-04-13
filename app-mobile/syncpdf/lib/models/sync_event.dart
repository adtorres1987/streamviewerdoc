/// Sealed class hierarchy representing every message type the WebSocket server
/// can push to the client.  Each subclass maps 1-to-1 to a WS `type` value.
///
/// Parsing entry point: [SyncEvent.fromJson]
sealed class SyncEvent {
  const SyncEvent();

  /// Factory that inspects the `type` field and dispatches to the correct
  /// subclass.  Returns [ErrorEvent] for unknown types so callers never get
  /// a null.
  factory SyncEvent.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? '';
    return switch (type) {
      'ROOM_JOINED' => RoomJoinedEvent.fromJson(json),
      'SYNC' => SyncScrollEvent.fromJson(json),
      'PARTICIPANTS' => ParticipantsEvent.fromJson(json),
      'HOST_DISCONNECTED' => HostDisconnectedEvent.fromJson(json),
      'HOST_RECONNECTED' => HostReconnectedEvent.fromJson(json),
      'REJOIN_CONTEXT' => RejoinContextEvent.fromJson(json),
      'SESSION_CLOSED' => RoomClosedEvent.fromJson(json),
      'PDF_READY' => PdfReadyEvent.fromJson(json),
      'ERROR' => ErrorEvent.fromJson(json),
      _ => ErrorEvent(code: 'UNKNOWN_TYPE', message: 'Unknown WS event type: $type'),
    };
  }
}

// ---------------------------------------------------------------------------
// Concrete event types
// ---------------------------------------------------------------------------

/// Server acknowledges a successful JOIN_ROOM.
class RoomJoinedEvent extends SyncEvent {
  const RoomJoinedEvent({
    required this.roomId,
    required this.code,
    this.hostPage = 1,
  });

  final String roomId;
  final String code;

  /// Host's current page at the moment the viewer joined.
  /// Only sent for fresh viewer joins (not host joins, not rejoins).
  final int hostPage;

  factory RoomJoinedEvent.fromJson(Map<String, dynamic> json) => RoomJoinedEvent(
        roomId: json['roomId'] as String,
        code: json['code'] as String,
        hostPage: (json['hostPage'] as num?)?.toInt() ?? 1,
      );
}

/// Host scroll position broadcast — viewers apply this if syncState == synced.
class SyncScrollEvent extends SyncEvent {
  const SyncScrollEvent({required this.page, required this.offsetY});

  final int page;
  final double offsetY;

  factory SyncScrollEvent.fromJson(Map<String, dynamic> json) => SyncScrollEvent(
        page: (json['page'] as num).toInt(),
        offsetY: (json['offsetY'] as num).toDouble(),
      );
}

/// Server-side participant count changed.
class ParticipantsEvent extends SyncEvent {
  const ParticipantsEvent({required this.count});

  final int count;

  factory ParticipantsEvent.fromJson(Map<String, dynamic> json) => ParticipantsEvent(
        count: (json['count'] as num).toInt(),
      );
}

/// Host connection dropped.  Viewer state machine: synced → free.
class HostDisconnectedEvent extends SyncEvent {
  const HostDisconnectedEvent({
    required this.lastPage,
    required this.lastOffsetY,
    required this.reconnectWindowSeconds,
  });

  final int lastPage;
  final double lastOffsetY;

  /// How many seconds the host has to reconnect before SESSION_CLOSED fires.
  final int reconnectWindowSeconds;

  factory HostDisconnectedEvent.fromJson(Map<String, dynamic> json) =>
      HostDisconnectedEvent(
        lastPage: (json['lastPage'] as num).toInt(),
        lastOffsetY: (json['lastOffsetY'] as num).toDouble(),
        reconnectWindowSeconds: (json['reconnectWindowSeconds'] as num).toInt(),
      );
}

/// Host reconnected.  Viewer state machine: free → synced (if viewer accepts).
class HostReconnectedEvent extends SyncEvent {
  const HostReconnectedEvent({
    required this.page,
    required this.offsetY,
    required this.hostName,
  });

  final int page;
  final double offsetY;
  final String hostName;

  factory HostReconnectedEvent.fromJson(Map<String, dynamic> json) =>
      HostReconnectedEvent(
        page: (json['page'] as num).toInt(),
        offsetY: (json['offsetY'] as num).toDouble(),
        hostName: json['hostName'] as String,
      );
}

/// Sent after a viewer reconnects so it can restore context without a DB query
/// from the client side.
class RejoinContextEvent extends SyncEvent {
  const RejoinContextEvent({
    required this.roomStatus,
    required this.yourLastPage,
    required this.yourLastOffset,
    required this.hostPage,
    required this.hostOffset,
    required this.hostConnected,
    required this.hostName,
  });

  final String roomStatus;
  final int yourLastPage;
  final double yourLastOffset;
  final int hostPage;
  final double hostOffset;
  final bool hostConnected;
  final String hostName;

  factory RejoinContextEvent.fromJson(Map<String, dynamic> json) =>
      RejoinContextEvent(
        roomStatus: json['roomStatus'] as String,
        yourLastPage: (json['yourLastPage'] as num).toInt(),
        yourLastOffset: (json['yourLastOffset'] as num).toDouble(),
        hostPage: (json['hostPage'] as num).toInt(),
        hostOffset: (json['hostOffset'] as num).toDouble(),
        hostConnected: json['hostConnected'] as bool,
        hostName: json['hostName'] as String,
      );
}

/// Session permanently ended. Viewer state machine: any → closed.
class RoomClosedEvent extends SyncEvent {
  const RoomClosedEvent({required this.reason});

  final String reason;

  factory RoomClosedEvent.fromJson(Map<String, dynamic> json) =>
      RoomClosedEvent(reason: json['reason'] as String? ?? 'Session ended.');
}

/// Server broadcasts the PDF URL after the host uploads a file.
/// Viewers receive this and download the file to temp storage.
class PdfReadyEvent extends SyncEvent {
  const PdfReadyEvent({required this.pdfUrl, required this.fileName});

  final String pdfUrl;
  final String fileName;

  factory PdfReadyEvent.fromJson(Map<String, dynamic> json) => PdfReadyEvent(
        pdfUrl: json['pdfUrl'] as String,
        fileName: json['fileName'] as String,
      );
}

/// Server-side error (e.g., not a member of the group).
class ErrorEvent extends SyncEvent {
  const ErrorEvent({required this.code, required this.message});

  final String code;
  final String message;

  factory ErrorEvent.fromJson(Map<String, dynamic> json) => ErrorEvent(
        code: json['code'] as String? ?? 'ERROR',
        message: json['message'] as String? ?? 'Unknown error',
      );
}
