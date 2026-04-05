'use strict';

const express = require('express');
const { randomUUID } = require('crypto');

const supabase = require('../config/db');
const authenticate = require('../middleware/auth');
const checkSubscription = require('../middleware/checkSubscription');

const router = express.Router();

// ---------------------------------------------------------------------------
// GET /groups — list groups where the authenticated user is a member
// ---------------------------------------------------------------------------
router.get('/', authenticate, async (req, res) => {
  const userId = req.user.id;

  try {
    const { data, error } = await supabase
      .from('group_members')
      .select('role, joined_at, groups(id, name, owner_id, created_at)')
      .eq('user_id', userId);

    if (error) {
      console.error('[GET /groups] Supabase error:', error);
      return res.status(500).json({ message: 'Error al obtener los grupos.' });
    }

    const groups = (data || []).map((row) => ({
      ...row.groups,
      memberRole: row.role,
      joinedAt: row.joined_at,
    }));

    return res.json({ success: true, data: groups });
  } catch (err) {
    console.error('[GET /groups] Unexpected error:', err);
    return res.status(500).json({ message: 'Error interno del servidor.' });
  }
});

// ---------------------------------------------------------------------------
// POST /groups — create a group; caller becomes owner
// Requires active subscription
// ---------------------------------------------------------------------------
router.post('/', authenticate, checkSubscription, async (req, res) => {
  const userId = req.user.id;
  const { name } = req.body;

  if (!name || typeof name !== 'string' || name.trim().length === 0) {
    return res.status(400).json({ message: 'El nombre del grupo es requerido.' });
  }

  try {
    // Insert the group
    const { data: group, error: groupError } = await supabase
      .from('groups')
      .insert({ name: name.trim(), owner_id: userId })
      .select()
      .single();

    if (groupError || !group) {
      console.error('[POST /groups] Insert group error:', groupError);
      return res.status(500).json({ message: 'Error al crear el grupo.' });
    }

    // Add creator as owner in group_members
    const { error: memberError } = await supabase.from('group_members').insert({
      group_id: group.id,
      user_id: userId,
      role: 'owner',
      invited_by: null,
    });

    if (memberError) {
      console.error('[POST /groups] Insert group_member error:', memberError);
      // Group was created but membership failed — attempt cleanup
      await supabase.from('groups').delete().eq('id', group.id);
      return res.status(500).json({ message: 'Error al registrar tu membresía en el grupo.' });
    }

    return res.status(201).json({ success: true, data: group });
  } catch (err) {
    console.error('[POST /groups] Unexpected error:', err);
    return res.status(500).json({ message: 'Error interno del servidor.' });
  }
});

// ---------------------------------------------------------------------------
// GET /groups/invite/:token — validate an invitation token (public)
// Must be placed BEFORE /groups/:id to avoid route shadowing
// ---------------------------------------------------------------------------
router.get('/invite/:token', async (req, res) => {
  const { token } = req.params;

  try {
    const { data: invitation, error } = await supabase
      .from('group_invitations')
      .select('id, group_id, invited_email, status, expires_at, groups(id, name)')
      .eq('token', token)
      .single();

    if (error || !invitation) {
      return res.status(404).json({ message: 'Invitación no encontrada.' });
    }

    if (invitation.status !== 'pending') {
      return res.status(409).json({ message: 'Esta invitación ya fue utilizada o expiró.' });
    }

    if (new Date(invitation.expires_at) < new Date()) {
      // Mark as expired in DB for housekeeping
      await supabase
        .from('group_invitations')
        .update({ status: 'expired' })
        .eq('id', invitation.id);

      return res.status(410).json({ message: 'Esta invitación ha expirado.' });
    }

    return res.json({
      success: true,
      data: {
        groupId: invitation.group_id,
        groupName: invitation.groups?.name,
        invitedEmail: invitation.invited_email,
        expiresAt: invitation.expires_at,
      },
    });
  } catch (err) {
    console.error('[GET /groups/invite/:token] Unexpected error:', err);
    return res.status(500).json({ message: 'Error interno del servidor.' });
  }
});

// ---------------------------------------------------------------------------
// POST /groups/invite/:token/accept — accept an invitation (auth required)
// ---------------------------------------------------------------------------
router.post('/invite/:token/accept', authenticate, async (req, res) => {
  const { token } = req.params;
  const userId = req.user.id;

  try {
    const { data: invitation, error } = await supabase
      .from('group_invitations')
      .select('id, group_id, invited_email, status, expires_at')
      .eq('token', token)
      .single();

    if (error || !invitation) {
      return res.status(404).json({ message: 'Invitación no encontrada.' });
    }

    if (invitation.status !== 'pending') {
      return res.status(409).json({ message: 'Esta invitación ya fue utilizada o expiró.' });
    }

    if (new Date(invitation.expires_at) < new Date()) {
      await supabase
        .from('group_invitations')
        .update({ status: 'expired' })
        .eq('id', invitation.id);

      return res.status(410).json({ message: 'Esta invitación ha expirado.' });
    }

    // Check if user is already a member
    const { data: existingMember } = await supabase
      .from('group_members')
      .select('user_id')
      .eq('group_id', invitation.group_id)
      .eq('user_id', userId)
      .single();

    if (existingMember) {
      return res.status(409).json({ message: 'Ya eres miembro de este grupo.' });
    }

    // Add user as member
    const { error: memberError } = await supabase.from('group_members').insert({
      group_id: invitation.group_id,
      user_id: userId,
      role: 'member',
      invited_by: invitation.invited_by,
    });

    if (memberError) {
      console.error('[POST /groups/invite/:token/accept] Insert member error:', memberError);
      return res.status(500).json({ message: 'Error al unirte al grupo.' });
    }

    // Mark invitation as accepted
    await supabase
      .from('group_invitations')
      .update({ status: 'accepted' })
      .eq('id', invitation.id);

    return res.json({ success: true, data: { groupId: invitation.group_id } });
  } catch (err) {
    console.error('[POST /groups/invite/:token/accept] Unexpected error:', err);
    return res.status(500).json({ message: 'Error interno del servidor.' });
  }
});

// ---------------------------------------------------------------------------
// GET /groups/:id — group detail + members (caller must be a member)
// ---------------------------------------------------------------------------
router.get('/:id', authenticate, async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  try {
    // Verify caller is a member
    const { data: membership, error: memberError } = await supabase
      .from('group_members')
      .select('role')
      .eq('group_id', id)
      .eq('user_id', userId)
      .single();

    if (memberError || !membership) {
      return res.status(403).json({ message: 'No eres miembro de este grupo.' });
    }

    // Fetch group with members
    const { data: group, error: groupError } = await supabase
      .from('groups')
      .select('id, name, owner_id, created_at')
      .eq('id', id)
      .single();

    if (groupError || !group) {
      return res.status(404).json({ message: 'Grupo no encontrado.' });
    }

    const { data: members, error: membersError } = await supabase
      .from('group_members')
      .select('role, joined_at, users!group_members_user_id_fkey(id, full_name, email)')
      .eq('group_id', id);

    if (membersError) {
      console.error('[GET /groups/:id] Fetch members error:', membersError);
      return res.status(500).json({ message: 'Error al obtener los miembros del grupo.' });
    }

    return res.json({
      success: true,
      data: {
        ...group,
        members: (members || []).map((m) => ({
          id: m.users?.id,
          fullName: m.users?.full_name,
          email: m.users?.email,
          role: m.role,
          joinedAt: m.joined_at,
        })),
      },
    });
  } catch (err) {
    console.error('[GET /groups/:id] Unexpected error:', err);
    return res.status(500).json({ message: 'Error interno del servidor.' });
  }
});

// ---------------------------------------------------------------------------
// DELETE /groups/:id — delete group (caller must be owner)
// ---------------------------------------------------------------------------
router.delete('/:id', authenticate, async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  try {
    // Verify caller is the owner
    const { data: membership, error: memberError } = await supabase
      .from('group_members')
      .select('role')
      .eq('group_id', id)
      .eq('user_id', userId)
      .single();

    if (memberError || !membership) {
      return res.status(403).json({ message: 'No eres miembro de este grupo.' });
    }

    if (membership.role !== 'owner') {
      return res.status(403).json({ message: 'Solo el propietario puede eliminar el grupo.' });
    }

    const { error: deleteError } = await supabase.from('groups').delete().eq('id', id);

    if (deleteError) {
      console.error('[DELETE /groups/:id] Delete error:', deleteError);
      return res.status(500).json({ message: 'Error al eliminar el grupo.' });
    }

    return res.json({ success: true, data: { deleted: true } });
  } catch (err) {
    console.error('[DELETE /groups/:id] Unexpected error:', err);
    return res.status(500).json({ message: 'Error interno del servidor.' });
  }
});

// ---------------------------------------------------------------------------
// POST /groups/:id/invite — invite a client by email (caller must be a member)
// ---------------------------------------------------------------------------
router.post('/:id/invite', authenticate, async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;
  const { email } = req.body;

  if (!email || typeof email !== 'string' || !email.includes('@')) {
    return res.status(400).json({ message: 'Se requiere un email válido.' });
  }

  const normalizedEmail = email.trim().toLowerCase();

  try {
    // Verify caller is a member of the group
    const { data: membership, error: memberError } = await supabase
      .from('group_members')
      .select('role')
      .eq('group_id', id)
      .eq('user_id', userId)
      .single();

    if (memberError || !membership) {
      return res.status(403).json({ message: 'No eres miembro de este grupo.' });
    }

    // Check if a pending invitation for this email already exists
    const { data: existing } = await supabase
      .from('group_invitations')
      .select('id, status')
      .eq('group_id', id)
      .eq('invited_email', normalizedEmail)
      .eq('status', 'pending')
      .single();

    if (existing) {
      return res.status(409).json({ message: 'Ya existe una invitación pendiente para ese email.' });
    }

    const token = randomUUID();
    const expiresAt = new Date(Date.now() + 48 * 60 * 60 * 1000).toISOString(); // 48h

    const { data: invitation, error: insertError } = await supabase
      .from('group_invitations')
      .insert({
        group_id: id,
        invited_email: normalizedEmail,
        invited_by: userId,
        token,
        status: 'pending',
        expires_at: expiresAt,
      })
      .select()
      .single();

    if (insertError || !invitation) {
      console.error('[POST /groups/:id/invite] Insert invitation error:', insertError);
      return res.status(500).json({ message: 'Error al crear la invitación.' });
    }

    return res.status(201).json({
      success: true,
      data: {
        token: invitation.token,
        invitedEmail: invitation.invited_email,
        expiresAt: invitation.expires_at,
      },
    });
  } catch (err) {
    console.error('[POST /groups/:id/invite] Unexpected error:', err);
    return res.status(500).json({ message: 'Error interno del servidor.' });
  }
});

module.exports = router;
