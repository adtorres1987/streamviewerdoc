'use strict';

const WebSocket = require('ws');
const { verifyToken } = require('../utils/jwt');
const supabase = require('../config/db');
const {
  initRoom,
  joinRoom,
  handleHostScroll,
  handleViewerScroll,
  handleRejoinSync,
  handleDisconnect,
  getRoomContext,
  getRoomPdfInfo,
  _isRoomHost,
} = require('./room_manager');

const HEARTBEAT_INTERVAL_MS = 30 * 1000; // 30 seconds

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function sendWs(socket, payload) {
  if (socket.readyState === WebSocket.OPEN) {
    socket.send(JSON.stringify(payload));
  }
}

function sendError(socket, code, message) {
  sendWs(socket, { type: 'ERROR', code, message });
}

// ---------------------------------------------------------------------------
// Message handlers
// ---------------------------------------------------------------------------

async function handleCreateRoom(ws, payload) {
  const { roomId } = payload;

  if (!roomId) {
    return sendError(ws, 'INVALID_PAYLOAD', 'roomId es requerido.');
  }

  try {
    // Verify room exists in DB and this user is the host
    const { data: room, error } = await supabase
      .from('rooms')
      .select('id, code, host_id, status, group_id, last_page')
      .eq('id', roomId)
      .single();

    if (error || !room) {
      return sendError(ws, 'ROOM_NOT_FOUND', 'La sala no existe.');
    }

    if (room.host_id !== ws.userId) {
      return sendError(ws, 'NOT_HOST', 'Solo el host puede crear la sala.');
    }

    if (room.status === 'closed') {
      return sendError(ws, 'ROOM_CLOSED', 'La sala está cerrada.');
    }

    initRoom(roomId, ws.userId, ws.userName, ws, room.last_page || 1);

    sendWs(ws, { type: 'ROOM_JOINED', roomId, code: room.code });
  } catch (err) {
    console.error('[ws] handleCreateRoom error:', err);
    sendError(ws, 'INTERNAL_ERROR', 'Error interno del servidor.');
  }
}

async function handleJoinRoom(ws, payload) {
  const { roomId } = payload;

  if (!roomId) {
    return sendError(ws, 'INVALID_PAYLOAD', 'roomId es requerido.');
  }

  try {
    // Verify room exists in DB — last_page is the persisted host position
    const { data: room, error: roomError } = await supabase
      .from('rooms')
      .select('id, code, host_id, status, group_id, last_page')
      .eq('id', roomId)
      .single();

    if (roomError || !room) {
      return sendError(ws, 'ROOM_NOT_FOUND', 'La sala no existe.');
    }

    if (room.status === 'closed') {
      return sendError(ws, 'ROOM_CLOSED', 'La sala está cerrada.');
    }

    // Verify user belongs to the room's group
    const { data: membership, error: memberError } = await supabase
      .from('group_members')
      .select('role')
      .eq('group_id', room.group_id)
      .eq('user_id', ws.userId)
      .single();

    if (memberError || !membership) {
      return sendError(ws, 'NOT_GROUP_MEMBER', 'No eres miembro del grupo de esta sala.');
    }

    const role = room.host_id === ws.userId ? 'host' : 'viewer';

    // Ensure participant record exists in DB for viewers
    if (role === 'viewer') {
      const { data: existingParticipant } = await supabase
        .from('room_participants')
        .select('user_id')
        .eq('room_id', roomId)
        .eq('user_id', ws.userId)
        .single();

      if (!existingParticipant) {
        await supabase.from('room_participants').insert({
          room_id: roomId,
          user_id: ws.userId,
          role: 'viewer',
          sync_state: 'synced',
        });
      }
    }

    if (role === 'host') {
      // For the host, always use initRoom regardless of whether the room is
      // already in memory.  initRoom handles both:
      //   - Fresh init (room not in memory): creates room, broadcasts participant count
      //   - Reconnect (room in host_disconnected state): clears close timer,
      //     broadcasts HOST_RECONNECTED to viewers, persists active status
      // This ensures the close timer is ALWAYS cancelled on host reconnect.
      initRoom(roomId, ws.userId, ws.userName, ws, room.last_page || 1);
      sendWs(ws, { type: 'ROOM_JOINED', roomId, code: room.code });
    } else {
      // Viewer join
      const context = getRoomContext(roomId, ws.userId);
      const isRejoin = context !== null;

      const joined = joinRoom(roomId, ws.userId, ws.userName, ws, 'viewer');

      if (!joined) {
        // Room not in memory — host hasn't connected yet.
        return sendError(ws, 'ROOM_NOT_ACTIVE', 'La sala no está activa en este momento.');
      } else if (isRejoin) {
        sendWs(ws, { type: 'REJOIN_CONTEXT', ...context });
      } else {
        // Fresh join — include the host's persisted page from DB so the viewer
        // can be offered to jump there.  In-memory lastPage may be higher if
        // the host scrolled within the debounce window; take the max.
        const memContext = getRoomContext(roomId, ws.userId);
        const dbPage = room.last_page || 1;
        const hostPage = memContext ? Math.max(memContext.hostPage, dbPage) : dbPage;
        sendWs(ws, { type: 'ROOM_JOINED', roomId, code: room.code, hostPage });
      }

      // If the room already has a PDF (host uploaded before this viewer joined),
      // send PDF_READY immediately so the viewer doesn't wait forever.
      const pdfInfo = getRoomPdfInfo(roomId);
      if (pdfInfo) {
        sendWs(ws, { type: 'PDF_READY', pdfUrl: pdfInfo.pdfUrl, fileName: pdfInfo.fileName });
      }
    }
  } catch (err) {
    console.error('[ws] handleJoinRoom error:', err);
    sendError(ws, 'INTERNAL_ERROR', 'Error interno del servidor.');
  }
}

function handleScrollMessage(ws, payload) {
  const { roomId, page, offsetY } = payload;

  if (!roomId || page === undefined || offsetY === undefined) {
    return sendError(ws, 'INVALID_PAYLOAD', 'roomId, page y offsetY son requeridos.');
  }

  // Server-side enforcement: only the host can broadcast SCROLL.
  // Verified against in-memory room state — never trust the client's claim.
  if (!_isRoomHost(roomId, ws.userId)) {
    return sendError(ws, 'NOT_HOST', 'Solo el host puede hacer broadcast de scroll.');
  }

  handleHostScroll(roomId, page, offsetY);
}

function handleViewerScrollMessage(ws, payload) {
  const { roomId, page, offsetY } = payload;

  if (!roomId || page === undefined || offsetY === undefined) {
    return sendError(ws, 'INVALID_PAYLOAD', 'roomId, page y offsetY son requeridos.');
  }

  handleViewerScroll(roomId, ws.userId, page, offsetY);
}

function handleRejoinSyncMessage(ws, payload) {
  const { roomId } = payload;

  if (!roomId) {
    return sendError(ws, 'INVALID_PAYLOAD', 'roomId es requerido.');
  }

  handleRejoinSync(roomId, ws.userId);
}

// ---------------------------------------------------------------------------
// Route incoming messages
// ---------------------------------------------------------------------------

async function routeMessage(ws, rawData) {
  let payload;

  try {
    payload = JSON.parse(rawData);
  } catch {
    return sendError(ws, 'INVALID_JSON', 'El mensaje no es JSON válido.');
  }

  const { type } = payload;

  switch (type) {
    case 'CREATE_ROOM':
      await handleCreateRoom(ws, payload);
      break;
    case 'JOIN_ROOM':
      await handleJoinRoom(ws, payload);
      break;
    case 'SCROLL':
      handleScrollMessage(ws, payload);
      break;
    case 'VIEWER_SCROLL':
      handleViewerScrollMessage(ws, payload);
      break;
    case 'REJOIN_SYNC':
      handleRejoinSyncMessage(ws, payload);
      break;
    case 'PING':
      sendWs(ws, { type: 'PONG' });
      break;
    default:
      sendError(ws, 'UNKNOWN_TYPE', `Tipo de mensaje desconocido: ${type}`);
  }
}

// ---------------------------------------------------------------------------
// WebSocket server initialization
// ---------------------------------------------------------------------------

function initWebSocket(server) {
  const wss = new WebSocket.Server({ server });

  // Heartbeat — every 30 seconds, ping all clients and terminate dead connections
  const heartbeatTimer = setInterval(() => {
    for (const ws of wss.clients) {
      if (ws.isAlive === false) {
        ws.terminate();
        return;
      }
      ws.isAlive = false;
      ws.ping();
    }
  }, HEARTBEAT_INTERVAL_MS);

  wss.on('close', () => {
    clearInterval(heartbeatTimer);
  });

  wss.on('connection', (ws, req) => {
    // Parse JWT from query string: /ws?token=<JWT>
    const url = new URL(req.url, `http://${req.headers.host}`);
    const token = url.searchParams.get('token');

    if (!token) {
      ws.close(4001, 'Token de autenticación requerido.');
      return;
    }

    let decoded;
    try {
      decoded = verifyToken(token);
    } catch {
      ws.close(4001, 'Token inválido o expirado.');
      return;
    }

    // Attach user identity to socket
    ws.userId = decoded.id;
    ws.userName = decoded.full_name || decoded.email || 'Usuario';
    ws.isAlive = true;

    // Respond to server-initiated pings
    ws.on('pong', () => {
      ws.isAlive = true;
    });

    ws.on('message', (data) => {
      routeMessage(ws, data.toString());
    });

    ws.on('close', () => {
      handleDisconnect(ws.userId, ws);
    });

    ws.on('error', (err) => {
      console.error(`[ws] Socket error (user=${ws.userId}):`, err);
    });
  });

  console.log('[ws] WebSocket server attached to HTTP server');
  return wss;
}

module.exports = { initWebSocket };
