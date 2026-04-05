'use strict';

const express = require('express');
const bcrypt = require('bcrypt');
const { body, validationResult } = require('express-validator');

const supabase = require('../config/db');
const resend = require('../config/mailer');
const { signToken } = require('../utils/jwt');
const { generateActivationCode, validateActivationCode } = require('../utils/generateCode');
const { activationEmail, resetPasswordEmail } = require('../utils/email_templates');
const authenticate = require('../middleware/auth');

const router = express.Router();

const BCRYPT_SALT_ROUNDS = 12;
const EMAIL_FROM = process.env.EMAIL_FROM || 'noreply@syncpdf.app';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function validationErrors(req, res) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({ success: false, error: errors.array()[0].msg });
  }
  return null;
}

async function sendEmail({ to, subject, html }) {
  try {
    await resend.emails.send({ from: EMAIL_FROM, to, subject, html });
  } catch (err) {
    // Log but do not let email failure block the request
    console.error('[email] Failed to send to', to, err.message);
  }
}

// ---------------------------------------------------------------------------
// POST /auth/register
// ---------------------------------------------------------------------------
router.post(
  '/register',
  [
    body('email').isEmail().withMessage('Email inválido.').normalizeEmail(),
    body('password').isLength({ min: 8 }).withMessage('La contraseña debe tener al menos 8 caracteres.'),
    body('full_name').trim().notEmpty().withMessage('El nombre completo es requerido.'),
  ],
  async (req, res) => {
    const errRes = validationErrors(req, res);
    if (errRes) return;

    const { email, password, full_name } = req.body;

    try {
      // 1. Check email uniqueness
      const { data: existing } = await supabase
        .from('users')
        .select('id')
        .eq('email', email)
        .maybeSingle();

      if (existing) {
        return res.status(409).json({ success: false, error: 'El email ya está registrado.' });
      }

      // 2. Hash password
      const password_hash = await bcrypt.hash(password, BCRYPT_SALT_ROUNDS);

      // 3. Generate activation code
      const { raw: codeRaw, stored: codeStored } = generateActivationCode();

      // 4. Insert user
      const { data: user, error: userError } = await supabase
        .from('users')
        .insert({
          email,
          password_hash,
          full_name,
          role: 'client',
          status: 'pending',
          activation_code: codeStored,
        })
        .select('id')
        .single();

      if (userError) {
        console.error('[register] DB insert user error:', userError);
        return res.status(500).json({ success: false, error: 'Error al crear la cuenta.' });
      }

      // 5. Create trial subscription
      const trialDays = 15;
      const trialEndsAt = new Date(Date.now() + trialDays * 24 * 60 * 60 * 1000).toISOString();

      const { error: subError } = await supabase.from('subscriptions').insert({
        user_id: user.id,
        status: 'trial',
        trial_days: trialDays,
        trial_ends_at: trialEndsAt,
      });

      if (subError) {
        console.error('[register] DB insert subscription error:', subError);
        // Non-fatal: user created; subscription can be reconciled later
      }

      // 6. Send activation email
      const template = activationEmail(full_name, codeRaw);
      await sendEmail({ to: email, ...template });

      return res.status(201).json({
        success: true,
        message: 'Cuenta creada. Revisa tu email para activarla.',
      });
    } catch (err) {
      console.error('[register] Unexpected error:', err);
      return res.status(500).json({ success: false, error: 'Error interno del servidor.' });
    }
  }
);

// ---------------------------------------------------------------------------
// POST /auth/login
// ---------------------------------------------------------------------------
router.post(
  '/login',
  [
    body('email').isEmail().withMessage('Email inválido.').normalizeEmail(),
    body('password').notEmpty().withMessage('La contraseña es requerida.'),
  ],
  async (req, res) => {
    const errRes = validationErrors(req, res);
    if (errRes) return;

    const { email, password } = req.body;

    try {
      const { data: user, error } = await supabase
        .from('users')
        .select('id, email, full_name, role, status, password_hash')
        .eq('email', email)
        .maybeSingle();

      if (error) {
        console.error('[login] DB error:', error);
        return res.status(500).json({ success: false, error: 'Error interno del servidor.' });
      }

      // Use a generic message to avoid user enumeration
      if (!user) {
        return res.status(401).json({ success: false, error: 'Credenciales inválidas.' });
      }

      if (user.status === 'pending') {
        return res.status(401).json({ success: false, error: 'Cuenta pendiente de activación.' });
      }

      if (user.status === 'suspended') {
        return res.status(403).json({ success: false, error: 'Cuenta suspendida. Contacta al soporte.' });
      }

      const passwordMatch = await bcrypt.compare(password, user.password_hash);
      if (!passwordMatch) {
        return res.status(401).json({ success: false, error: 'Credenciales inválidas.' });
      }

      const token = signToken({ id: user.id, email: user.email, role: user.role });

      return res.json({
        success: true,
        data: {
          token,
          user: {
            id: user.id,
            email: user.email,
            full_name: user.full_name,
            role: user.role,
            status: user.status,
          },
        },
      });
    } catch (err) {
      console.error('[login] Unexpected error:', err);
      return res.status(500).json({ success: false, error: 'Error interno del servidor.' });
    }
  }
);

// ---------------------------------------------------------------------------
// POST /auth/activate
// ---------------------------------------------------------------------------
router.post(
  '/activate',
  [
    body('email').isEmail().withMessage('Email inválido.').normalizeEmail(),
    body('code')
      .isLength({ min: 6, max: 6 })
      .isNumeric()
      .withMessage('El código debe ser de 6 dígitos numéricos.'),
  ],
  async (req, res) => {
    const errRes = validationErrors(req, res);
    if (errRes) return;

    const { email, code } = req.body;

    try {
      const { data: user, error } = await supabase
        .from('users')
        .select('id, status, activation_code')
        .eq('email', email)
        .maybeSingle();

      if (error) {
        console.error('[activate] DB error:', error);
        return res.status(500).json({ success: false, error: 'Error interno del servidor.' });
      }

      if (!user) {
        return res.status(404).json({ success: false, error: 'Usuario no encontrado.' });
      }

      if (user.status === 'active') {
        return res.status(409).json({ success: false, error: 'La cuenta ya está activa.' });
      }

      const { valid, expired } = validateActivationCode(user.activation_code, code);

      if (expired) {
        return res.status(400).json({ success: false, error: 'El código ha expirado. Solicita uno nuevo.' });
      }

      if (!valid) {
        return res.status(400).json({ success: false, error: 'Código inválido.' });
      }

      const { error: updateError } = await supabase
        .from('users')
        .update({
          status: 'active',
          activated_at: new Date().toISOString(),
          activation_code: null,
        })
        .eq('id', user.id);

      if (updateError) {
        console.error('[activate] DB update error:', updateError);
        return res.status(500).json({ success: false, error: 'Error al activar la cuenta.' });
      }

      return res.json({ success: true, message: 'Cuenta activada exitosamente.' });
    } catch (err) {
      console.error('[activate] Unexpected error:', err);
      return res.status(500).json({ success: false, error: 'Error interno del servidor.' });
    }
  }
);

// ---------------------------------------------------------------------------
// POST /auth/forgot-password
// ---------------------------------------------------------------------------
router.post(
  '/forgot-password',
  [body('email').isEmail().withMessage('Email inválido.').normalizeEmail()],
  async (req, res) => {
    const errRes = validationErrors(req, res);
    if (errRes) return;

    const { email } = req.body;

    // Always return the same message to avoid user enumeration
    const genericResponse = {
      success: true,
      message: 'Si el email existe, recibirás un código.',
    };

    try {
      const { data: user, error } = await supabase
        .from('users')
        .select('id, full_name, status')
        .eq('email', email)
        .maybeSingle();

      if (error) {
        console.error('[forgot-password] DB error:', error);
        // Still return generic response
        return res.json(genericResponse);
      }

      if (!user || user.status === 'suspended') {
        return res.json(genericResponse);
      }

      const { raw: codeRaw, stored: codeStored } = generateActivationCode();

      await supabase
        .from('users')
        .update({ activation_code: codeStored })
        .eq('id', user.id);

      const template = resetPasswordEmail(user.full_name, codeRaw);
      await sendEmail({ to: email, ...template });

      return res.json(genericResponse);
    } catch (err) {
      console.error('[forgot-password] Unexpected error:', err);
      return res.json(genericResponse); // never reveal internals
    }
  }
);

// ---------------------------------------------------------------------------
// POST /auth/reset-password
// ---------------------------------------------------------------------------
router.post(
  '/reset-password',
  [
    body('email').isEmail().withMessage('Email inválido.').normalizeEmail(),
    body('code')
      .isLength({ min: 6, max: 6 })
      .isNumeric()
      .withMessage('El código debe ser de 6 dígitos numéricos.'),
    body('new_password')
      .isLength({ min: 8 })
      .withMessage('La nueva contraseña debe tener al menos 8 caracteres.'),
  ],
  async (req, res) => {
    const errRes = validationErrors(req, res);
    if (errRes) return;

    const { email, code, new_password } = req.body;

    try {
      const { data: user, error } = await supabase
        .from('users')
        .select('id, activation_code')
        .eq('email', email)
        .maybeSingle();

      if (error) {
        console.error('[reset-password] DB error:', error);
        return res.status(500).json({ success: false, error: 'Error interno del servidor.' });
      }

      if (!user) {
        return res.status(404).json({ success: false, error: 'Usuario no encontrado.' });
      }

      const { valid, expired } = validateActivationCode(user.activation_code, code);

      if (expired) {
        return res.status(400).json({ success: false, error: 'El código ha expirado. Solicita uno nuevo.' });
      }

      if (!valid) {
        return res.status(400).json({ success: false, error: 'Código inválido.' });
      }

      const password_hash = await bcrypt.hash(new_password, BCRYPT_SALT_ROUNDS);

      const { error: updateError } = await supabase
        .from('users')
        .update({ password_hash, activation_code: null })
        .eq('id', user.id);

      if (updateError) {
        console.error('[reset-password] DB update error:', updateError);
        return res.status(500).json({ success: false, error: 'Error al actualizar la contraseña.' });
      }

      return res.json({ success: true, message: 'Contraseña actualizada.' });
    } catch (err) {
      console.error('[reset-password] Unexpected error:', err);
      return res.status(500).json({ success: false, error: 'Error interno del servidor.' });
    }
  }
);

// ---------------------------------------------------------------------------
// POST /auth/complete-registration
// ---------------------------------------------------------------------------
router.post(
  '/complete-registration',
  [
    body('email').isEmail().withMessage('Email inválido.').normalizeEmail(),
    body('code')
      .isLength({ min: 6, max: 6 })
      .isNumeric()
      .withMessage('El código debe ser de 6 dígitos numéricos.'),
    body('full_name').trim().notEmpty().withMessage('El nombre completo es requerido.'),
    body('password')
      .isLength({ min: 8 })
      .withMessage('La contraseña debe tener al menos 8 caracteres.'),
  ],
  async (req, res) => {
    const errRes = validationErrors(req, res);
    if (errRes) return;

    const { email, code, full_name, password } = req.body;

    try {
      const { data: user, error } = await supabase
        .from('users')
        .select('id, status, activation_code, role')
        .eq('email', email)
        .maybeSingle();

      if (error) {
        console.error('[complete-registration] DB error:', error);
        return res.status(500).json({ success: false, error: 'Error interno del servidor.' });
      }

      if (!user) {
        return res.status(404).json({ success: false, error: 'Usuario no encontrado.' });
      }

      if (user.status !== 'pending') {
        return res.status(409).json({ success: false, error: 'La cuenta ya fue activada.' });
      }

      const { valid, expired } = validateActivationCode(user.activation_code, code);

      if (expired) {
        return res.status(400).json({ success: false, error: 'El código ha expirado.' });
      }

      if (!valid) {
        return res.status(400).json({ success: false, error: 'Código inválido.' });
      }

      const password_hash = await bcrypt.hash(password, BCRYPT_SALT_ROUNDS);

      const { error: updateError } = await supabase
        .from('users')
        .update({
          password_hash,
          full_name,
          status: 'active',
          activated_at: new Date().toISOString(),
          activation_code: null,
        })
        .eq('id', user.id);

      if (updateError) {
        console.error('[complete-registration] DB update error:', updateError);
        return res.status(500).json({ success: false, error: 'Error al activar la cuenta.' });
      }

      return res.json({ success: true, message: 'Cuenta activada exitosamente.' });
    } catch (err) {
      console.error('[complete-registration] Unexpected error:', err);
      return res.status(500).json({ success: false, error: 'Error interno del servidor.' });
    }
  }
);

// ---------------------------------------------------------------------------
// GET /auth/me  (requires JWT)
// ---------------------------------------------------------------------------
router.get('/me', authenticate, async (req, res) => {
  try {
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id, email, full_name, role, status')
      .eq('id', req.user.id)
      .maybeSingle();

    if (userError) {
      console.error('[me] DB user error:', userError);
      return res.status(500).json({ success: false, error: 'Error interno del servidor.' });
    }

    if (!user) {
      return res.status(404).json({ success: false, error: 'Usuario no encontrado.' });
    }

    const { data: subscription, error: subError } = await supabase
      .from('subscriptions')
      .select('status, trial_ends_at, current_period_end')
      .eq('user_id', req.user.id)
      .maybeSingle();

    if (subError) {
      console.error('[me] DB subscription error:', subError);
      // Non-fatal: return user without subscription info
    }

    return res.json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          full_name: user.full_name,
          role: user.role,
          status: user.status,
        },
        subscription: subscription
          ? {
              status: subscription.status,
              trial_ends_at: subscription.trial_ends_at,
              current_period_end: subscription.current_period_end,
            }
          : null,
      },
    });
  } catch (err) {
    console.error('[me] Unexpected error:', err);
    return res.status(500).json({ success: false, error: 'Error interno del servidor.' });
  }
});

module.exports = router;
