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
      .select('id, code, host_id, status, group_id')
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

    initRoom(roomId, ws.userId, ws.userName, ws);

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
    // Verify room exists in DB
    const { data: room, error: roomError } = await supabase
      .from('rooms')
      .select('id, code, host_id, status, group_id')
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

    // Check if this is a rejoin (room exists in memory and user was already there)
    const context = getRoomContext(roomId, ws.userId);
    const isRejoin = context !== null;

    const joined = joinRoom(roomId, ws.userId, ws.userName, ws, role);

    if (!joined) {
      // Room not in memory — this can happen if the server restarted
      // or the host hasn't sent CREATE_ROOM yet
      return sendError(ws, 'ROOM_NOT_ACTIVE', 'La sala no está activa en este momento.');
    }

    if (isRejoin && role === 'viewer') {
      sendWs(ws, { type: 'REJOIN_CONTEXT', ...context });
    } else {
      sendWs(ws, { type: 'ROOM_JOINED', roomId, code: room.code });
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
