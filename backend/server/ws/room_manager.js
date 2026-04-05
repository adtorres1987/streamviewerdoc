'use strict';

const supabase = require('../config/db');

// ---------------------------------------------------------------------------
// In-memory room state
// ---------------------------------------------------------------------------
// Map<roomId, roomState>
//
// roomState: {
//   hostId:             string,
//   hostName:           string,
//   hostSocket:         WebSocket | null,
//   status:             'waiting' | 'active' | 'host_disconnected' | 'closed',
//   lastPage:           number,
//   lastOffset:         number,
//   hostDisconnectedAt: Date | null,
//   closeTimer:         Timeout | null,
//   participants:       Map<userId, participantState>
// }
//
// participantState: {
//   socket:    WebSocket,
//   role:      'host' | 'viewer',
//   syncState: 'synced' | 'free' | 'disconnected',
//   lastPage:  number,
//   lastOffset: number,
//   name:      string,
// }
// ---------------------------------------------------------------------------
const rooms = new Map();

// Per-viewer debounce timers: Map<userId, Timeout>
const viewerScrollTimers = new Map();
// Per-room host debounce timers: Map<roomId, Timeout>
const hostScrollTimers = new Map();

const SCROLL_DEBOUNCE_MS = parseInt(process.env.SCROLL_DEBOUNCE_MS || '5000', 10);
const DEFAULT_RECONNECT_TIMEOUT_MINUTES = 10;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function send(socket, payload) {
  if (socket && socket.readyState === 1 /* OPEN */) {
    socket.send(JSON.stringify(payload));
  }
}

function broadcastParticipantCount(roomId) {
  const room = rooms.get(roomId);
  if (!room) return;

  const count = room.participants.size;
  for (const [, participant] of room.participants) {
    send(participant.socket, { type: 'PARTICIPANTS', count });
  }
}

async function getReconnectTimeoutSeconds() {
  try {
    const { data, error } = await supabase
      .from('global_settings')
      .select('value')
      .eq('key', 'host_reconnect_timeout_minutes')
      .single();

    if (error || !data) return DEFAULT_RECONNECT_TIMEOUT_MINUTES * 60;
    return parseInt(data.value, 10) * 60;
  } catch (err) {
    console.error('[room_manager] Failed to read global_settings:', err);
    return DEFAULT_RECONNECT_TIMEOUT_MINUTES * 60;
  }
}

// ---------------------------------------------------------------------------
// Persistence helpers
// ---------------------------------------------------------------------------

async function persistViewerPosition(roomId, userId, page, offsetY) {
  const { error } = await supabase
    .from('room_participants')
    .update({
      last_page: page,
      last_offset: offsetY,
      last_seen_at: new Date().toISOString(),
    })
    .eq('room_id', roomId)
    .eq('user_id', userId);

  if (error) {
    console.error(`[room_manager] persistViewerPosition error (room=${roomId}, user=${userId}):`, error);
  }
}

async function persistHostPosition(roomId, page, offsetY) {
  const { error } = await supabase
    .from('rooms')
    .update({ last_page: page, last_offset: offsetY })
    .eq('id', roomId);

  if (error) {
    console.error(`[room_manager] persistHostPosition error (room=${roomId}):`, error);
  }
}

async function persistParticipantDisconnect(roomId, userId, page, offsetY) {
  const { error } = await supabase
    .from('room_participants')
    .update({
      last_page: page,
      last_offset: offsetY,
      last_seen_at: new Date().toISOString(),
      left_at: new Date().toISOString(),
    })
    .eq('room_id', roomId)
    .eq('user_id', userId);

  if (error) {
    console.error(`[room_manager] persistParticipantDisconnect error (room=${roomId}, user=${userId}):`, error);
  }
}

async function persistHostDisconnect(roomId, page, offsetY) {
  const { error } = await supabase
    .from('rooms')
    .update({
      host_disconnected_at: new Date().toISOString(),
      last_page: page,
      last_offset: offsetY,
    })
    .eq('id', roomId);

  if (error) {
    console.error(`[room_manager] persistHostDisconnect error (room=${roomId}):`, error);
  }
}

async function persistRoomClosed(roomId) {
  const { error } = await supabase
    .from('rooms')
    .update({ status: 'closed', closed_at: new Date().toISOString() })
    .eq('id', roomId);

  if (error) {
    console.error(`[room_manager] persistRoomClosed error (room=${roomId}):`, error);
  }
}

// ---------------------------------------------------------------------------
// Debounced scroll persistence
// ---------------------------------------------------------------------------

function scheduleViewerScrollPersist(roomId, userId, page, offsetY) {
  const key = `${roomId}:${userId}`;

  if (viewerScrollTimers.has(key)) {
    clearTimeout(viewerScrollTimers.get(key));
  }

  const timer = setTimeout(() => {
    viewerScrollTimers.delete(key);
    persistViewerPosition(roomId, userId, page, offsetY);
  }, SCROLL_DEBOUNCE_MS);

  viewerScrollTimers.set(key, timer);
}

function scheduleHostScrollPersist(roomId, page, offsetY) {
  if (hostScrollTimers.has(roomId)) {
    clearTimeout(hostScrollTimers.get(roomId));
  }

  const timer = setTimeout(() => {
    hostScrollTimers.delete(roomId);
    persistHostPosition(roomId, page, offsetY);
  }, SCROLL_DEBOUNCE_MS);

  hostScrollTimers.set(roomId, timer);
}

function cancelPendingScrollTimers(roomId, userId) {
  const key = `${roomId}:${userId}`;
  if (viewerScrollTimers.has(key)) {
    clearTimeout(viewerScrollTimers.get(key));
    viewerScrollTimers.delete(key);
  }
}

function cancelPendingHostScrollTimer(roomId) {
  if (hostScrollTimers.has(roomId)) {
    clearTimeout(hostScrollTimers.get(roomId));
    hostScrollTimers.delete(roomId);
  }
}

// ---------------------------------------------------------------------------
// findRoomForSocket — reverse-lookup: given a socket, find roomId + userId
// ---------------------------------------------------------------------------

function findRoomForSocket(socket) {
  for (const [roomId, room] of rooms) {
    for (const [userId, participant] of room.participants) {
      if (participant.socket === socket) {
        return { roomId, userId, room, participant };
      }
    }
  }
  return null;
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/**
 * initRoom — called when a host sends CREATE_ROOM.
 * The room record must already exist in DB (created via REST API).
 */
function initRoom(roomId, hostId, hostName, hostSocket) {
  // If room already exists in memory (e.g. host reconnect), update socket
  if (rooms.has(roomId)) {
    const room = rooms.get(roomId);
    // Treat as host reconnect
    room.hostSocket = hostSocket;
    room.status = 'active';
    room.hostDisconnectedAt = null;

    if (room.closeTimer) {
      clearTimeout(room.closeTimer);
      room.closeTimer = null;
    }

    // Update host participant socket
    if (room.participants.has(hostId)) {
      room.participants.get(hostId).socket = hostSocket;
      room.participants.get(hostId).syncState = 'synced';
    } else {
      room.participants.set(hostId, {
        socket: hostSocket,
        role: 'host',
        syncState: 'synced',
        lastPage: room.lastPage,
        lastOffset: room.lastOffset,
        name: hostName,
      });
    }

    // Broadcast HOST_RECONNECTED to all viewers
    for (const [uid, participant] of room.participants) {
      if (uid !== hostId && participant.role === 'viewer') {
        send(participant.socket, {
          type: 'HOST_RECONNECTED',
          page: room.lastPage,
          offsetY: room.lastOffset,
          hostName,
        });
      }
    }

    broadcastParticipantCount(roomId);

    // Confirm room joined to host
    send(hostSocket, {
      type: 'ROOM_JOINED',
      roomId,
      code: null, // host already has the code
    });

    return;
  }

  // Fresh room initialization
  const participants = new Map();
  participants.set(hostId, {
    socket: hostSocket,
    role: 'host',
    syncState: 'synced',
    lastPage: 1,
    lastOffset: 0,
    name: hostName,
  });

  rooms.set(roomId, {
    hostId,
    hostName,
    hostSocket,
    status: 'active',
    lastPage: 1,
    lastOffset: 0,
    hostDisconnectedAt: null,
    closeTimer: null,
    participants,
  });

  broadcastParticipantCount(roomId);
}

/**
 * joinRoom — called when a viewer (or returning host) sends JOIN_ROOM.
 * Returns false if the room is not found in memory.
 */
function joinRoom(roomId, userId, userName, socket, role) {
  const room = rooms.get(roomId);
  if (!room) return false;

  const isRejoining = room.participants.has(userId);
  const existing = isRejoining ? room.participants.get(userId) : null;

  if (isRejoining && existing) {
    // Reconnecting participant: restore socket, set syncState to 'free'
    existing.socket = socket;
    existing.syncState = 'free';
  } else {
    // New participant
    room.participants.set(userId, {
      socket,
      role,
      syncState: role === 'host' ? 'synced' : 'synced', // new viewers start synced per spec
      lastPage: 1,
      lastOffset: 0,
      name: userName,
    });
  }

  broadcastParticipantCount(roomId);
  return true;
}

/**
 * handleHostScroll — processes a SCROLL message from the host.
 * Broadcasts SYNC to viewers with syncState === 'synced'.
 * Debounces DB write.
 */
function handleHostScroll(roomId, page, offsetY) {
  const room = rooms.get(roomId);
  if (!room) return;

  // Update in-memory state
  room.lastPage = page;
  room.lastOffset = offsetY;

  // Update host participant state
  if (room.participants.has(room.hostId)) {
    const hostPart = room.participants.get(room.hostId);
    hostPart.lastPage = page;
    hostPart.lastOffset = offsetY;
  }

  // Broadcast SYNC to synced viewers only
  for (const [userId, participant] of room.participants) {
    if (userId !== room.hostId && participant.role === 'viewer' && participant.syncState === 'synced') {
      send(participant.socket, { type: 'SYNC', page, offsetY });
    }
  }

  // Debounced persist
  scheduleHostScrollPersist(roomId, page, offsetY);
}

/**
 * handleViewerScroll — processes a VIEWER_SCROLL message.
 * Updates in-memory state and debounces DB write.
 */
function handleViewerScroll(roomId, userId, page, offsetY) {
  const room = rooms.get(roomId);
  if (!room) return;

  const participant = room.participants.get(userId);
  if (!participant || participant.role !== 'viewer') return;

  participant.lastPage = page;
  participant.lastOffset = offsetY;

  scheduleViewerScrollPersist(roomId, userId, page, offsetY);
}

/**
 * handleRejoinSync — viewer explicitly opts back into host sync.
 * Sets syncState = 'synced' and sends current host position.
 */
function handleRejoinSync(roomId, userId) {
  const room = rooms.get(roomId);
  if (!room) return;

  const participant = room.participants.get(userId);
  if (!participant || participant.role !== 'viewer') return;

  participant.syncState = 'synced';

  // Send current host position to the viewer
  send(participant.socket, {
    type: 'SYNC',
    page: room.lastPage,
    offsetY: room.lastOffset,
  });
}

/**
 * handleDisconnect — called when any WebSocket connection closes.
 * Finds which room the socket belongs to, persists position, cleans up.
 * If host: starts the close timer and broadcasts HOST_DISCONNECTED.
 */
async function handleDisconnect(userId, socket) {
  const found = findRoomForSocket(socket);
  if (!found) return; // Socket wasn't in any room

  const { roomId, room, participant } = found;

  if (participant.role === 'host') {
    // Cancel pending debounced host scroll persist
    cancelPendingHostScrollTimer(roomId);

    // Immediate persist: host position + host_disconnected_at
    room.hostSocket = null;
    room.status = 'host_disconnected';
    room.hostDisconnectedAt = new Date();

    // Persist immediately (fire and forget — do not block)
    persistHostDisconnect(roomId, participant.lastPage, participant.lastOffset);
    persistParticipantDisconnect(roomId, userId, participant.lastPage, participant.lastOffset);

    // Broadcast HOST_DISCONNECTED to all connected viewers
    // and set all viewer syncStates to 'free'
    const reconnectWindowSeconds = await getReconnectTimeoutSeconds();

    for (const [uid, p] of room.participants) {
      if (uid !== userId && p.role === 'viewer') {
        p.syncState = 'free';
        send(p.socket, {
          type: 'HOST_DISCONNECTED',
          lastPage: participant.lastPage,
          lastOffsetY: participant.lastOffset,
          reconnectWindowSeconds,
        });
      }
    }

    // Remove host from in-memory participants
    room.participants.delete(userId);
    broadcastParticipantCount(roomId);

    // Start close timer
    const timerMs = reconnectWindowSeconds * 1000;
    room.closeTimer = setTimeout(async () => {
      const currentRoom = rooms.get(roomId);
      if (!currentRoom) return;

      currentRoom.status = 'closed';

      // Broadcast SESSION_CLOSED to all remaining viewers
      for (const [, p] of currentRoom.participants) {
        send(p.socket, { type: 'SESSION_CLOSED', reason: 'host_timeout' });
      }

      // Persist room closure
      await persistRoomClosed(roomId);

      // Clean up in-memory state
      rooms.delete(roomId);
    }, timerMs);
  } else {
    // Viewer disconnect
    cancelPendingScrollTimers(roomId, userId);

    // Immediate persist
    persistParticipantDisconnect(roomId, userId, participant.lastPage, participant.lastOffset);

    // Remove from in-memory state
    room.participants.delete(userId);
    broadcastParticipantCount(roomId);
  }
}

/**
 * getRoomContext — returns REJOIN_CONTEXT data for a reconnecting viewer.
 */
function getRoomContext(roomId, userId) {
  const room = rooms.get(roomId);
  if (!room) return null;

  const participant = room.participants.get(userId);
  const hostConnected = room.hostSocket !== null && room.hostSocket.readyState === 1;

  return {
    roomStatus: room.status,
    yourLastPage: participant ? participant.lastPage : 1,
    yourLastOffset: participant ? participant.lastOffset : 0,
    hostPage: room.lastPage,
    hostOffset: room.lastOffset,
    hostConnected,
    hostName: room.hostName,
  };
}

/**
 * getActiveRooms — returns array of room summaries for admin API.
 */
function getActiveRooms() {
  const result = [];
  for (const [roomId, room] of rooms) {
    result.push({
      roomId,
      status: room.status,
      hostId: room.hostId,
      hostName: room.hostName,
      participantCount: room.participants.size,
      lastPage: room.lastPage,
      lastOffset: room.lastOffset,
      hostDisconnectedAt: room.hostDisconnectedAt,
    });
  }
  return result;
}

/**
 * _isRoomHost — returns true if userId is the current host of roomId.
 * Used by ws_server.js to enforce server-side SCROLL authorization.
 */
function _isRoomHost(roomId, userId) {
  const room = rooms.get(roomId);
  if (!room) return false;
  return room.hostId === userId;
}

module.exports = {
  initRoom,
  joinRoom,
  handleHostScroll,
  handleViewerScroll,
  handleRejoinSync,
  handleDisconnect,
  getRoomContext,
  getActiveRooms,
  _isRoomHost,
};
