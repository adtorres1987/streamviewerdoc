'use strict';

const express = require('express');

const supabase = require('../config/db');
const resend = require('../config/mailer');
const authenticate = require('../middleware/auth');
const checkRole = require('../middleware/checkRole');
const { generateActivationCode } = require('../utils/generateCode');
const { adminInviteEmail } = require('../utils/email_templates');

const router = express.Router();

const EMAIL_FROM = process.env.EMAIL_FROM || 'noreply@syncpdf.app';

// All superadmin routes require authentication + superadmin role only
router.use(authenticate, checkRole('superadmin'));

// ---------------------------------------------------------------------------
// Helper — send email without blocking the response on failure
// ---------------------------------------------------------------------------
async function sendEmail({ to, subject, html }) {
  try {
    await resend.emails.send({ from: EMAIL_FROM, to, subject, html });
  } catch (err) {
    console.error('[email] Failed to send to', to, err.message);
  }
}

// ---------------------------------------------------------------------------
// GET /superadmin/admins — list all admin users with client count
// ---------------------------------------------------------------------------
router.get('/admins', async (req, res) => {
  try {
    const { data: admins, error } = await supabase
      .from('users')
      .select('id, email, full_name, status, created_at, invited_by')
      .eq('role', 'admin')
      .order('created_at', { ascending: false });

    if (error) {
      console.error('[GET /superadmin/admins] Supabase error:', error);
      return res.status(500).json({ message: 'Error al obtener los admins.' });
    }

    if (!admins || admins.length === 0) {
      return res.json({ success: true, data: [] });
    }

    // Fetch client counts per admin (users with invited_by = admin.id and role = 'client')
    const adminIds = admins.map((a) => a.id);

    const { data: clientRows, error: clientError } = await supabase
      .from('users')
      .select('invited_by')
      .eq('role', 'client')
      .in('invited_by', adminIds);

    if (clientError) {
      console.error('[GET /superadmin/admins] Client count error:', clientError);
      // Non-fatal — return admins without counts
    }

    // Build count map
    const countMap = {};
    for (const row of clientRows || []) {
      if (row.invited_by) {
        countMap[row.invited_by] = (countMap[row.invited_by] ?? 0) + 1;
      }
    }

    const result = admins.map((a) => ({
      id: a.id,
      email: a.email,
      full_name: a.full_name,
      status: a.status,
      created_at: a.created_at,
      invited_by: a.invited_by,
      clients_count: countMap[a.id] ?? 0,
    }));

    return res.json({ success: true, data: result });
  } catch (err) {
    console.error('[GET /superadmin/admins] Unexpected error:', err);
    return res.status(500).json({ message: 'Error interno del servidor.' });
  }
});

// ---------------------------------------------------------------------------
// POST /superadmin/admins/invite — invite a new admin by email
// Body: { email: string }
// ---------------------------------------------------------------------------
router.post('/admins/invite', async (req, res) => {
  const { email } = req.body;

  if (!email || typeof email !== 'string') {
    return res.status(400).json({ message: 'El campo email es requerido.' });
  }

  // Basic email format check
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email.trim())) {
    return res.status(422).json({ message: 'Formato de email inválido.' });
  }

  const normalizedEmail = email.trim().toLowerCase();

  try {
    // Check if email is already registered
    const { data: existing, error: lookupError } = await supabase
      .from('users')
      .select('id')
      .eq('email', normalizedEmail)
      .maybeSingle();

    if (lookupError) {
      console.error('[POST /superadmin/admins/invite] Lookup error:', lookupError);
      return res.status(500).json({ message: 'Error al verificar el email.' });
    }

    if (existing) {
      return res.status(409).json({ message: 'Este email ya está registrado.' });
    }

    // Generate activation code
    const { raw: activationCodeRaw, stored: activationCodeStored } = generateActivationCode();

    // Insert admin user with status 'pending'
    const { data: newAdmin, error: insertError } = await supabase
      .from('users')
      .insert({
        email: normalizedEmail,
        password_hash: '', // Will be set when admin completes registration
        full_name: normalizedEmail, // Placeholder until they complete profile
        role: 'admin',
        status: 'pending',
        activation_code: activationCodeStored,
        invited_by: req.user.id,
      })
      .select('id, email')
      .single();

    if (insertError || !newAdmin) {
      console.error('[POST /superadmin/admins/invite] Insert error:', insertError);
      return res.status(500).json({ message: 'Error al crear la invitación.' });
    }

    // Build invite link (activation code serves as the invite credential)
    const appUrl = process.env.APP_URL || 'https://app.syncpdf.io';
    const inviteLink = `${appUrl}/admin/activate?email=${encodeURIComponent(normalizedEmail)}&code=${activationCodeRaw}`;

    // Send invitation email
    const { subject, html } = adminInviteEmail(normalizedEmail, inviteLink);
    await sendEmail({ to: normalizedEmail, subject, html });

    return res.status(201).json({ message: 'Invitación enviada' });
  } catch (err) {
    console.error('[POST /superadmin/admins/invite] Unexpected error:', err);
    return res.status(500).json({ message: 'Error interno del servidor.' });
  }
});

// ---------------------------------------------------------------------------
// PATCH /superadmin/admins/:id/suspend — suspend an admin account
// Cannot suspend a superadmin
// ---------------------------------------------------------------------------
router.patch('/admins/:id/suspend', async (req, res) => {
  const { id } = req.params;

  try {
    const { data: target, error: lookupError } = await supabase
      .from('users')
      .select('id, role, status')
      .eq('id', id)
      .single();

    if (lookupError || !target) {
      return res.status(404).json({ message: 'Usuario no encontrado.' });
    }

    if (target.role !== 'admin') {
      return res.status(403).json({ message: 'Solo se pueden suspender cuentas con rol admin.' });
    }

    if (target.status === 'suspended') {
      return res.status(409).json({ message: 'La cuenta ya está suspendida.' });
    }

    const { data: updated, error: updateError } = await supabase
      .from('users')
      .update({ status: 'suspended' })
      .eq('id', id)
      .select('id, email, full_name, status, created_at, invited_by')
      .single();

    if (updateError || !updated) {
      console.error('[PATCH /superadmin/admins/:id/suspend] Update error:', updateError);
      return res.status(500).json({ message: 'Error al suspender la cuenta.' });
    }

    return res.json({ success: true, data: updated });
  } catch (err) {
    console.error('[PATCH /superadmin/admins/:id/suspend] Unexpected error:', err);
    return res.status(500).json({ message: 'Error interno del servidor.' });
  }
});

// ---------------------------------------------------------------------------
// GET /superadmin/settings — return all global settings as an object
// ---------------------------------------------------------------------------
router.get('/settings', async (req, res) => {
  try {
    const { data: rows, error } = await supabase
      .from('global_settings')
      .select('key, value');

    if (error) {
      console.error('[GET /superadmin/settings] Supabase error:', error);
      return res.status(500).json({ message: 'Error al obtener la configuración.' });
    }

    // Transform array of { key, value } rows into a single object
    const settings = {};
    for (const row of rows || []) {
      settings[row.key] = row.value;
    }

    return res.json({ success: true, data: settings });
  } catch (err) {
    console.error('[GET /superadmin/settings] Unexpected error:', err);
    return res.status(500).json({ message: 'Error interno del servidor.' });
  }
});

// ---------------------------------------------------------------------------
// PATCH /superadmin/settings — upsert one or many global settings
// Body: { key: string, value: string }           — single key/value pair
//    OR { settings: { key: value, ... } }         — multiple keys at once
// ---------------------------------------------------------------------------
router.patch('/settings', async (req, res) => {
  const { key, value, settings } = req.body;

  // Build the list of { key, value } pairs to upsert
  let pairs = [];

  if (settings && typeof settings === 'object' && !Array.isArray(settings)) {
    // Bulk update path
    pairs = Object.entries(settings).map(([k, v]) => ({ key: k, value: String(v) }));
  } else if (key !== undefined && value !== undefined) {
    // Single pair path
    pairs = [{ key: String(key), value: String(value) }];
  } else {
    return res.status(400).json({
      message: 'Se requiere { key, value } o { settings: { key: value, ... } }.',
    });
  }

  if (pairs.length === 0) {
    return res.status(400).json({ message: 'No se proporcionaron configuraciones para actualizar.' });
  }

  const now = new Date().toISOString();
  const upsertRows = pairs.map(({ key: k, value: v }) => ({
    key: k,
    value: v,
    updated_by: req.user.id,
    updated_at: now,
  }));

  try {
    const { error: upsertError } = await supabase
      .from('global_settings')
      .upsert(upsertRows, { onConflict: 'key' });

    if (upsertError) {
      console.error('[PATCH /superadmin/settings] Upsert error:', upsertError);
      return res.status(500).json({ message: 'Error al actualizar la configuración.' });
    }

    // Return the full updated settings object
    const { data: rows, error: fetchError } = await supabase
      .from('global_settings')
      .select('key, value');

    if (fetchError) {
      console.error('[PATCH /superadmin/settings] Fetch after upsert error:', fetchError);
      return res.status(500).json({ message: 'Configuración actualizada, pero no se pudo releer.' });
    }

    const updatedSettings = {};
    for (const row of rows || []) {
      updatedSettings[row.key] = row.value;
    }

    return res.json({ success: true, data: updatedSettings });
  } catch (err) {
    console.error('[PATCH /superadmin/settings] Unexpected error:', err);
    return res.status(500).json({ message: 'Error interno del servidor.' });
  }
});

// ---------------------------------------------------------------------------
// GET /superadmin/metrics — global platform metrics
// ---------------------------------------------------------------------------
router.get('/metrics', async (req, res) => {
  try {
    // Run all count queries in parallel for efficiency
    const [
      totalUsersResult,
      trialUsersResult,
      activeUsersResult,
      expiredUsersResult,
      activeRoomsResult,
      totalAdminsResult,
      mrrResult,
    ] = await Promise.all([
      // total_users: clients
      supabase
        .from('users')
        .select('id', { count: 'exact', head: true })
        .eq('role', 'client'),

      // trial_users: subscriptions with status = 'trial'
      supabase
        .from('subscriptions')
        .select('id', { count: 'exact', head: true })
        .eq('status', 'trial'),

      // active_users: subscriptions with status = 'active'
      supabase
        .from('subscriptions')
        .select('id', { count: 'exact', head: true })
        .eq('status', 'active'),

      // expired_users: subscriptions with status expired or cancelled
      supabase
        .from('subscriptions')
        .select('id', { count: 'exact', head: true })
        .in('status', ['expired', 'cancelled']),

      // active_rooms: rooms with status active or host_disconnected
      supabase
        .from('rooms')
        .select('id', { count: 'exact', head: true })
        .in('status', ['active', 'host_disconnected']),

      // total_admins: users with role = 'admin'
      supabase
        .from('users')
        .select('id', { count: 'exact', head: true })
        .eq('role', 'admin'),

      // MRR: sum of plan prices for active subscriptions that have a stripe_sub_id
      // Join subscriptions → plans via plan_id (not explicit in schema, so we select
      // active subscriptions with stripe_sub_id and join plans through the subscription)
      supabase
        .from('subscriptions')
        .select('plans ( price_usd )')
        .eq('status', 'active')
        .not('stripe_sub_id', 'is', null),
    ]);

    // Check for errors — log but return partial data rather than failing entirely
    const errors = [
      totalUsersResult.error,
      trialUsersResult.error,
      activeUsersResult.error,
      expiredUsersResult.error,
      activeRoomsResult.error,
      totalAdminsResult.error,
      mrrResult.error,
    ].filter(Boolean);

    if (errors.length > 0) {
      console.error('[GET /superadmin/metrics] Query errors:', errors);
    }

    // Compute MRR by summing plan prices from active subscriptions
    let mrr = 0;
    if (!mrrResult.error && mrrResult.data) {
      for (const row of mrrResult.data) {
        const price = row.plans?.price_usd;
        if (price != null) {
          mrr += parseFloat(price);
        }
      }
    }

    return res.json({
      success: true,
      data: {
        total_users: totalUsersResult.count ?? 0,
        trial_users: trialUsersResult.count ?? 0,
        active_users: activeUsersResult.count ?? 0,
        expired_users: expiredUsersResult.count ?? 0,
        active_rooms: activeRoomsResult.count ?? 0,
        total_admins: totalAdminsResult.count ?? 0,
        mrr: parseFloat(mrr.toFixed(2)),
      },
    });
  } catch (err) {
    console.error('[GET /superadmin/metrics] Unexpected error:', err);
    return res.status(500).json({ message: 'Error interno del servidor.' });
  }
});

module.exports = router;
