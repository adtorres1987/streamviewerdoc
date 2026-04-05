'use strict';

const express = require('express');

const supabase = require('../config/db');
const authenticate = require('../middleware/auth');
const checkRole = require('../middleware/checkRole');

const router = express.Router();

// All admin routes require authentication + admin/superadmin role
router.use(authenticate, checkRole('admin', 'superadmin'));

// ---------------------------------------------------------------------------
// GET /admin/clients — list all clients with subscription info
// Optional ?q= search on full_name or email (case-insensitive)
// ---------------------------------------------------------------------------
router.get('/clients', async (req, res) => {
  const { q } = req.query;

  try {
    let query = supabase
      .from('users')
      .select(`
        id,
        email,
        full_name,
        status,
        created_at,
        subscriptions (
          status,
          trial_ends_at,
          current_period_end
        )
      `)
      .eq('role', 'client')
      .order('created_at', { ascending: false });

    if (q && q.trim().length > 0) {
      const term = q.trim();
      query = query.or(`full_name.ilike.%${term}%,email.ilike.%${term}%`);
    }

    const { data: users, error } = await query;

    if (error) {
      console.error('[GET /admin/clients] Supabase error:', error);
      return res.status(500).json({ message: 'Error al obtener los clientes.' });
    }

    const clients = (users || []).map((u) => {
      const sub = u.subscriptions?.[0] ?? null;
      return {
        id: u.id,
        email: u.email,
        full_name: u.full_name,
        status: u.status,
        subscription_status: sub?.status ?? null,
        trial_ends_at: sub?.trial_ends_at ?? null,
        current_period_end: sub?.current_period_end ?? null,
        created_at: u.created_at,
      };
    });

    return res.json({ success: true, data: clients });
  } catch (err) {
    console.error('[GET /admin/clients] Unexpected error:', err);
    return res.status(500).json({ message: 'Error interno del servidor.' });
  }
});

// ---------------------------------------------------------------------------
// GET /admin/clients/:id — client detail: user + subscription + groups + recent rooms
// ---------------------------------------------------------------------------
router.get('/clients/:id', async (req, res) => {
  const { id } = req.params;

  try {
    // Fetch user info + subscription
    const { data: user, error: userError } = await supabase
      .from('users')
      .select(`
        id,
        email,
        full_name,
        status,
        created_at,
        subscriptions (
          status,
          trial_days,
          trial_ends_at,
          current_period_end,
          stripe_customer_id,
          stripe_sub_id,
          cancelled_at
        )
      `)
      .eq('id', id)
      .eq('role', 'client')
      .single();

    if (userError || !user) {
      return res.status(404).json({ message: 'Cliente no encontrado.' });
    }

    // Fetch groups the client belongs to
    const { data: groupMemberships, error: groupError } = await supabase
      .from('group_members')
      .select(`
        role,
        joined_at,
        groups (
          id,
          name,
          created_at
        )
      `)
      .eq('user_id', id);

    if (groupError) {
      console.error('[GET /admin/clients/:id] Groups error:', groupError);
    }

    // Fetch recent rooms (last 10 rooms the client participated in)
    const { data: roomParticipations, error: roomsError } = await supabase
      .from('room_participants')
      .select(`
        role,
        sync_state,
        joined_at,
        left_at,
        rooms (
          id,
          name,
          code,
          status,
          created_at,
          closed_at
        )
      `)
      .eq('user_id', id)
      .order('joined_at', { ascending: false })
      .limit(10);

    if (roomsError) {
      console.error('[GET /admin/clients/:id] Rooms error:', roomsError);
    }

    const sub = user.subscriptions?.[0] ?? null;

    return res.json({
      success: true,
      data: {
        id: user.id,
        email: user.email,
        full_name: user.full_name,
        status: user.status,
        created_at: user.created_at,
        subscription: sub
          ? {
              status: sub.status,
              trial_days: sub.trial_days,
              trial_ends_at: sub.trial_ends_at,
              current_period_end: sub.current_period_end,
              stripe_customer_id: sub.stripe_customer_id,
              stripe_sub_id: sub.stripe_sub_id,
              cancelled_at: sub.cancelled_at,
            }
          : null,
        groups: (groupMemberships || []).map((gm) => ({
          id: gm.groups?.id,
          name: gm.groups?.name,
          created_at: gm.groups?.created_at,
          member_role: gm.role,
          joined_at: gm.joined_at,
        })),
        recent_rooms: (roomParticipations || []).map((rp) => ({
          id: rp.rooms?.id,
          name: rp.rooms?.name,
          code: rp.rooms?.code,
          status: rp.rooms?.status,
          created_at: rp.rooms?.created_at,
          closed_at: rp.rooms?.closed_at,
          participant_role: rp.role,
          joined_at: rp.joined_at,
          left_at: rp.left_at,
        })),
      },
    });
  } catch (err) {
    console.error('[GET /admin/clients/:id] Unexpected error:', err);
    return res.status(500).json({ message: 'Error interno del servidor.' });
  }
});

// ---------------------------------------------------------------------------
// PATCH /admin/clients/:id/trial — update trial days (only when status = 'trial')
// Body: { trial_days: number }
// ---------------------------------------------------------------------------
router.patch('/clients/:id/trial', async (req, res) => {
  const { id } = req.params;
  const { trial_days } = req.body;

  if (trial_days === undefined || trial_days === null) {
    return res.status(400).json({ message: 'El campo trial_days es requerido.' });
  }

  const days = Number(trial_days);
  if (!Number.isInteger(days) || days < 1) {
    return res.status(422).json({ message: 'trial_days debe ser un entero positivo.' });
  }

  try {
    // Verify the user is a client
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id')
      .eq('id', id)
      .eq('role', 'client')
      .single();

    if (userError || !user) {
      return res.status(404).json({ message: 'Cliente no encontrado.' });
    }

    // Fetch the subscription and ensure it is in 'trial' status
    const { data: sub, error: subError } = await supabase
      .from('subscriptions')
      .select('id, status')
      .eq('user_id', id)
      .single();

    if (subError || !sub) {
      return res.status(404).json({ message: 'Suscripción no encontrada.' });
    }

    if (sub.status !== 'trial') {
      return res.status(409).json({ message: 'Solo se puede editar el trial mientras la suscripción esté en estado trial.' });
    }

    // Recalculate trial_ends_at from now
    const trialEndsAt = new Date(Date.now() + days * 24 * 60 * 60 * 1000).toISOString();

    const { data: updated, error: updateError } = await supabase
      .from('subscriptions')
      .update({ trial_days: days, trial_ends_at: trialEndsAt })
      .eq('id', sub.id)
      .select()
      .single();

    if (updateError || !updated) {
      console.error('[PATCH /admin/clients/:id/trial] Update error:', updateError);
      return res.status(500).json({ message: 'Error al actualizar el trial.' });
    }

    return res.json({ success: true, data: updated });
  } catch (err) {
    console.error('[PATCH /admin/clients/:id/trial] Unexpected error:', err);
    return res.status(500).json({ message: 'Error interno del servidor.' });
  }
});

// ---------------------------------------------------------------------------
// PATCH /admin/clients/:id/suspend — set users.status = 'suspended'
// ---------------------------------------------------------------------------
router.patch('/clients/:id/suspend', async (req, res) => {
  const { id } = req.params;

  try {
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id, status')
      .eq('id', id)
      .eq('role', 'client')
      .single();

    if (userError || !user) {
      return res.status(404).json({ message: 'Cliente no encontrado.' });
    }

    if (user.status === 'suspended') {
      return res.status(409).json({ message: 'La cuenta ya está suspendida.' });
    }

    const { data: updated, error: updateError } = await supabase
      .from('users')
      .update({ status: 'suspended' })
      .eq('id', id)
      .select('id, email, full_name, status, created_at')
      .single();

    if (updateError || !updated) {
      console.error('[PATCH /admin/clients/:id/suspend] Update error:', updateError);
      return res.status(500).json({ message: 'Error al suspender la cuenta.' });
    }

    return res.json({ success: true, data: updated });
  } catch (err) {
    console.error('[PATCH /admin/clients/:id/suspend] Unexpected error:', err);
    return res.status(500).json({ message: 'Error interno del servidor.' });
  }
});

// ---------------------------------------------------------------------------
// PATCH /admin/clients/:id/activate — set users.status = 'active'
// ---------------------------------------------------------------------------
router.patch('/clients/:id/activate', async (req, res) => {
  const { id } = req.params;

  try {
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id, status')
      .eq('id', id)
      .eq('role', 'client')
      .single();

    if (userError || !user) {
      return res.status(404).json({ message: 'Cliente no encontrado.' });
    }

    if (user.status === 'active') {
      return res.status(409).json({ message: 'La cuenta ya está activa.' });
    }

    const { data: updated, error: updateError } = await supabase
      .from('users')
      .update({ status: 'active' })
      .eq('id', id)
      .select('id, email, full_name, status, created_at')
      .single();

    if (updateError || !updated) {
      console.error('[PATCH /admin/clients/:id/activate] Update error:', updateError);
      return res.status(500).json({ message: 'Error al activar la cuenta.' });
    }

    return res.json({ success: true, data: updated });
  } catch (err) {
    console.error('[PATCH /admin/clients/:id/activate] Unexpected error:', err);
    return res.status(500).json({ message: 'Error interno del servidor.' });
  }
});

// ---------------------------------------------------------------------------
// GET /admin/rooms — list active/host_disconnected rooms with participant count
// ---------------------------------------------------------------------------
router.get('/rooms', async (req, res) => {
  try {
    // Fetch rooms with status active or host_disconnected, join host user info
    const { data: rooms, error: roomsError } = await supabase
      .from('rooms')
      .select(`
        id,
        name,
        code,
        status,
        created_at,
        host_id,
        users (
          full_name
        )
      `)
      .in('status', ['active', 'host_disconnected'])
      .order('created_at', { ascending: false });

    if (roomsError) {
      console.error('[GET /admin/rooms] Supabase error:', roomsError);
      return res.status(500).json({ message: 'Error al obtener las salas.' });
    }

    if (!rooms || rooms.length === 0) {
      return res.json({ success: true, data: [] });
    }

    // Fetch participant counts for these rooms (left_at IS NULL = currently in room)
    const roomIds = rooms.map((r) => r.id);

    const { data: participantRows, error: partError } = await supabase
      .from('room_participants')
      .select('room_id')
      .in('room_id', roomIds)
      .is('left_at', null);

    if (partError) {
      console.error('[GET /admin/rooms] Participant count error:', partError);
      // Non-fatal — return rooms without counts
    }

    // Build participant count map
    const countMap = {};
    for (const row of participantRows || []) {
      countMap[row.room_id] = (countMap[row.room_id] ?? 0) + 1;
    }

    const result = rooms.map((r) => ({
      id: r.id,
      name: r.name,
      code: r.code,
      status: r.status,
      host_id: r.host_id,
      host_name: r.users?.full_name ?? null,
      participant_count: countMap[r.id] ?? 0,
      created_at: r.created_at,
    }));

    return res.json({ success: true, data: result });
  } catch (err) {
    console.error('[GET /admin/rooms] Unexpected error:', err);
    return res.status(500).json({ message: 'Error interno del servidor.' });
  }
});

module.exports = router;
