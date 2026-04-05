'use strict';

const express = require('express');

const supabase = require('../config/db');
const authenticate = require('../middleware/auth');
const checkSubscription = require('../middleware/checkSubscription');
const { generateRoomCode } = require('../utils/generateCode');

const router = express.Router();

// ---------------------------------------------------------------------------
// Helper — verify that userId is a member of the given groupId.
// Returns the membership row or null.
// ---------------------------------------------------------------------------
async function getGroupMembership(groupId, userId) {
  const { data, error } = await supabase
    .from('group_members')
    .select('role')
    .eq('group_id', groupId)
    .eq('user_id', userId)
    .single();

  if (error || !data) return null;
  return data;
}

// ---------------------------------------------------------------------------
// GET /rooms?groupId= — list rooms for a group (caller must be a member)
// ---------------------------------------------------------------------------
router.get('/', authenticate, async (req, res) => {
  const userId = req.user.id;
  const { groupId } = req.query;

  if (!groupId) {
    return res.status(400).json({ message: 'El parámetro groupId es requerido.' });
  }

  try {
    const membership = await getGroupMembership(groupId, userId);
    if (!membership) {
      return res.status(403).json({ message: 'No eres miembro de este grupo.' });
    }

    const { data: rooms, error } = await supabase
      .from('rooms')
      .select('id, group_id, name, code, status, file_name, last_page, last_offset, created_at, closed_at, host_id')
      .eq('group_id', groupId)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('[GET /rooms] Supabase error:', error);
      return res.status(500).json({ message: 'Error al obtener las salas.' });
    }

    return res.json({ success: true, data: rooms || [] });
  } catch (err) {
    console.error('[GET /rooms] Unexpected error:', err);
    return res.status(500).json({ message: 'Error interno del servidor.' });
  }
});

// ---------------------------------------------------------------------------
// POST /rooms — create a room in a group; caller becomes host
// Requires active subscription
// ---------------------------------------------------------------------------
router.post('/', authenticate, checkSubscription, async (req, res) => {
  const userId = req.user.id;
  const { groupId, name } = req.body;

  if (!groupId || typeof groupId !== 'string') {
    return res.status(400).json({ message: 'El campo groupId es requerido.' });
  }

  if (!name || typeof name !== 'string' || name.trim().length === 0) {
    return res.status(400).json({ message: 'El nombre de la sala es requerido.' });
  }

  try {
    // Caller must be a group member
    const membership = await getGroupMembership(groupId, userId);
    if (!membership) {
      return res.status(403).json({ message: 'No eres miembro de este grupo.' });
    }

    // Generate a unique 6-char room code (retry on collision)
    let code;
    let attempts = 0;
    while (attempts < 5) {
      const candidate = generateRoomCode();
      const { data: existing } = await supabase
        .from('rooms')
        .select('id')
        .eq('code', candidate)
        .single();

      if (!existing) {
        code = candidate;
        break;
      }
      attempts++;
    }

    if (!code) {
      console.error('[POST /rooms] Could not generate a unique room code after 5 attempts');
      return res.status(500).json({ message: 'No se pudo generar un código de sala único.' });
    }

    // Insert room
    const { data: room, error: roomError } = await supabase
      .from('rooms')
      .insert({
        group_id: groupId,
        name: name.trim(),
        host_id: userId,
        code,
        status: 'waiting',
      })
      .select()
      .single();

    if (roomError || !room) {
      console.error('[POST /rooms] Insert room error:', roomError);
      return res.status(500).json({ message: 'Error al crear la sala.' });
    }

    // Insert host as participant
    const { error: participantError } = await supabase.from('room_participants').insert({
      room_id: room.id,
      user_id: userId,
      role: 'host',
      sync_state: 'synced',
    });

    if (participantError) {
      console.error('[POST /rooms] Insert room_participant error:', participantError);
      // Room created but participant failed — attempt cleanup
      await supabase.from('rooms').delete().eq('id', room.id);
      return res.status(500).json({ message: 'Error al registrar al host en la sala.' });
    }

    return res.status(201).json({ success: true, data: room });
  } catch (err) {
    console.error('[POST /rooms] Unexpected error:', err);
    return res.status(500).json({ message: 'Error interno del servidor.' });
  }
});

// ---------------------------------------------------------------------------
// GET /rooms/:id — room detail + participants (caller must be a group member)
// ---------------------------------------------------------------------------
router.get('/:id', authenticate, async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  try {
    // Fetch room first
    const { data: room, error: roomError } = await supabase
      .from('rooms')
      .select('id, group_id, name, code, status, file_name, last_page, last_offset, host_id, created_at, closed_at, host_disconnected_at')
      .eq('id', id)
      .single();

    if (roomError || !room) {
      return res.status(404).json({ message: 'Sala no encontrada.' });
    }

    // Verify caller belongs to the room's group
    const membership = await getGroupMembership(room.group_id, userId);
    if (!membership) {
      return res.status(403).json({ message: 'No tienes acceso a esta sala.' });
    }

    // Fetch participants
    const { data: participants, error: partError } = await supabase
      .from('room_participants')
      .select('role, sync_state, last_page, last_offset, joined_at, left_at, last_seen_at, users(id, full_name, email)')
      .eq('room_id', id);

    if (partError) {
      console.error('[GET /rooms/:id] Fetch participants error:', partError);
      return res.status(500).json({ message: 'Error al obtener los participantes.' });
    }

    return res.json({
      success: true,
      data: {
        ...room,
        participants: (participants || []).map((p) => ({
          id: p.users?.id,
          fullName: p.users?.full_name,
          email: p.users?.email,
          role: p.role,
          syncState: p.sync_state,
          lastPage: p.last_page,
          lastOffset: p.last_offset,
          joinedAt: p.joined_at,
          leftAt: p.left_at,
          lastSeenAt: p.last_seen_at,
        })),
      },
    });
  } catch (err) {
    console.error('[GET /rooms/:id] Unexpected error:', err);
    return res.status(500).json({ message: 'Error interno del servidor.' });
  }
});

// ---------------------------------------------------------------------------
// PATCH /rooms/:id/close — close a room (caller must be the host)
// ---------------------------------------------------------------------------
router.patch('/:id/close', authenticate, async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  try {
    const { data: room, error: roomError } = await supabase
      .from('rooms')
      .select('id, group_id, host_id, status')
      .eq('id', id)
      .single();

    if (roomError || !room) {
      return res.status(404).json({ message: 'Sala no encontrada.' });
    }

    if (room.host_id !== userId) {
      return res.status(403).json({ message: 'Solo el host puede cerrar la sala.' });
    }

    if (room.status === 'closed') {
      return res.status(409).json({ message: 'La sala ya está cerrada.' });
    }

    const { data: updated, error: updateError } = await supabase
      .from('rooms')
      .update({ status: 'closed', closed_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single();

    if (updateError || !updated) {
      console.error('[PATCH /rooms/:id/close] Update error:', updateError);
      return res.status(500).json({ message: 'Error al cerrar la sala.' });
    }

    return res.json({ success: true, data: updated });
  } catch (err) {
    console.error('[PATCH /rooms/:id/close] Unexpected error:', err);
    return res.status(500).json({ message: 'Error interno del servidor.' });
  }
});

module.exports = router;
