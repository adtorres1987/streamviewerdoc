'use strict';

const express = require('express');

const supabase = require('../config/db');
const stripe = require('../config/stripe');
const authenticate = require('../middleware/auth');
const checkRole = require('../middleware/checkRole');

const router = express.Router();

// All payments routes require authentication.
// checkSubscription is intentionally skipped here — users must be able to
// subscribe even when their subscription is expired or not yet active.

// ---------------------------------------------------------------------------
// GET /payments/plans — list all available plans
// ---------------------------------------------------------------------------
router.get('/plans', authenticate, checkRole('client', 'admin', 'superadmin'), async (req, res) => {
  try {
    const { data: plans, error } = await supabase
      .from('plans')
      .select('*')
      .order('created_at', { ascending: true });

    if (error) {
      console.error('[GET /payments/plans] Supabase error:', error);
      return res.status(500).json({ message: 'Error al obtener los planes.' });
    }

    return res.status(200).json({ success: true, data: plans });
  } catch (err) {
    console.error('[GET /payments/plans] Unexpected error:', err);
    return res.status(500).json({ message: 'Error interno del servidor.' });
  }
});

// ---------------------------------------------------------------------------
// POST /payments/subscribe — create a Stripe subscription for current user
// ---------------------------------------------------------------------------
router.post('/subscribe', authenticate, checkRole('client', 'admin', 'superadmin'), async (req, res) => {
  const { planId } = req.body;

  if (!planId) {
    return res.status(400).json({ message: 'planId es requerido.' });
  }

  try {
    // 1. Look up plan to get stripe_price_id
    const { data: plan, error: planError } = await supabase
      .from('plans')
      .select('id, stripe_price_id, name')
      .eq('id', planId)
      .single();

    if (planError || !plan) {
      return res.status(404).json({ message: 'Plan no encontrado.' });
    }

    if (!plan.stripe_price_id) {
      return res.status(422).json({ message: 'El plan no tiene un precio de Stripe configurado.' });
    }

    // 2. Get user info for Stripe customer
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id, email, full_name')
      .eq('id', req.user.id)
      .single();

    if (userError || !user) {
      return res.status(404).json({ message: 'Usuario no encontrado.' });
    }

    // 3. Get or create Stripe customer
    const { data: subscription, error: subError } = await supabase
      .from('subscriptions')
      .select('id, stripe_customer_id, stripe_sub_id')
      .eq('user_id', req.user.id)
      .single();

    if (subError && subError.code !== 'PGRST116') {
      // PGRST116 = no rows returned — that is fine
      console.error('[POST /payments/subscribe] Supabase subscription fetch error:', subError);
      return res.status(500).json({ message: 'Error al verificar la suscripción.' });
    }

    let stripeCustomerId = subscription?.stripe_customer_id || null;

    if (!stripeCustomerId) {
      const customer = await stripe.customers.create({
        email: user.email,
        name: user.full_name,
      });
      stripeCustomerId = customer.id;
    }

    // 4. Read trial_days from global_settings
    const { data: settings } = await supabase
      .from('global_settings')
      .select('value')
      .eq('key', 'default_trial_days')
      .single();

    const trialDays = settings?.value ? parseInt(settings.value, 10) : 15;

    // 5. Create Stripe subscription
    const stripeSubscription = await stripe.subscriptions.create({
      customer: stripeCustomerId,
      items: [{ price: plan.stripe_price_id }],
      trial_period_days: trialDays,
    });

    const trialEndsAt = new Date(Date.now() + trialDays * 24 * 60 * 60 * 1000).toISOString();

    // 6. Upsert subscriptions row
    const upsertData = {
      user_id: req.user.id,
      stripe_customer_id: stripeCustomerId,
      stripe_sub_id: stripeSubscription.id,
      status: 'trial',
      trial_ends_at: trialEndsAt,
    };

    let upsertError;
    if (subscription?.id) {
      // Update existing row
      ({ error: upsertError } = await supabase
        .from('subscriptions')
        .update(upsertData)
        .eq('id', subscription.id));
    } else {
      // Insert new row
      ({ error: upsertError } = await supabase
        .from('subscriptions')
        .insert(upsertData));
    }

    if (upsertError) {
      console.error('[POST /payments/subscribe] Supabase upsert error:', upsertError);
      return res.status(500).json({ message: 'Error al guardar la suscripción.' });
    }

    return res.status(201).json({
      success: true,
      data: {
        subscriptionId: stripeSubscription.id,
        status: 'trial',
        trialEndsAt,
      },
    });
  } catch (err) {
    console.error('[POST /payments/subscribe] Unexpected error:', err);
    return res.status(500).json({ message: 'Error interno del servidor.' });
  }
});

// ---------------------------------------------------------------------------
// POST /payments/cancel — cancel subscription at period end
// ---------------------------------------------------------------------------
router.post('/cancel', authenticate, checkRole('client', 'admin', 'superadmin'), async (req, res) => {
  try {
    const { data: subscription, error: subError } = await supabase
      .from('subscriptions')
      .select('id, stripe_sub_id')
      .eq('user_id', req.user.id)
      .single();

    if (subError || !subscription) {
      return res.status(404).json({ message: 'Suscripción no encontrada.' });
    }

    if (!subscription.stripe_sub_id) {
      return res.status(422).json({ message: 'La suscripción no tiene un ID de Stripe asociado.' });
    }

    // Cancel at period end — access continues until current_period_end
    await stripe.subscriptions.update(subscription.stripe_sub_id, {
      cancel_at_period_end: true,
    });

    const cancelledAt = new Date().toISOString();

    const { error: updateError } = await supabase
      .from('subscriptions')
      .update({ cancelled_at: cancelledAt })
      .eq('id', subscription.id);

    if (updateError) {
      console.error('[POST /payments/cancel] Supabase update error:', updateError);
      return res.status(500).json({ message: 'Error al actualizar la suscripción.' });
    }

    return res.status(200).json({
      success: true,
      data: { message: 'Suscripción cancelada al final del período' },
    });
  } catch (err) {
    console.error('[POST /payments/cancel] Unexpected error:', err);
    return res.status(500).json({ message: 'Error interno del servidor.' });
  }
});

// ---------------------------------------------------------------------------
// GET /payments/status — current subscription status for the authenticated user
// ---------------------------------------------------------------------------
router.get('/status', authenticate, checkRole('client', 'admin', 'superadmin'), async (req, res) => {
  try {
    const { data: subscription, error } = await supabase
      .from('subscriptions')
      .select('status, trial_ends_at, current_period_end, cancelled_at, stripe_customer_id')
      .eq('user_id', req.user.id)
      .single();

    if (error || !subscription) {
      return res.status(404).json({ message: 'Suscripción no encontrada.' });
    }

    return res.status(200).json({
      success: true,
      data: {
        status: subscription.status,
        trialEndsAt: subscription.trial_ends_at,
        currentPeriodEnd: subscription.current_period_end,
        cancelledAt: subscription.cancelled_at,
        stripeCustomerId: subscription.stripe_customer_id,
      },
    });
  } catch (err) {
    console.error('[GET /payments/status] Unexpected error:', err);
    return res.status(500).json({ message: 'Error interno del servidor.' });
  }
});

module.exports = router;
