'use strict';

const supabase = require('../config/db');

/**
 * Subscription gate middleware.
 *
 * Reads req.user.id (set by authenticate), queries the subscriptions table,
 * and allows the request to proceed only when the subscription status is
 * 'trial' or 'active' and the user's account is not suspended.
 *
 * Must be used after authenticate (and optionally after checkRole).
 *
 * Returns 403 in the following cases:
 *   - User account status is 'suspended'
 *   - No subscription record found
 *   - Subscription status is 'expired' or 'cancelled'
 */
async function checkSubscription(req, res, next) {
  const userId = req.user.id;

  try {
    // Check user account status first — suspended users are blocked regardless
    // of subscription state
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('status')
      .eq('id', userId)
      .single();

    if (userError || !user) {
      return res.status(403).json({ message: 'Usuario no encontrado.' });
    }

    if (user.status === 'suspended') {
      return res.status(403).json({ message: 'Tu cuenta ha sido suspendida. Contacta al administrador.' });
    }

    // Check subscription status
    const { data: subscription, error: subError } = await supabase
      .from('subscriptions')
      .select('status')
      .eq('user_id', userId)
      .single();

    if (subError || !subscription) {
      return res.status(403).json({ message: 'No se encontró una suscripción activa.' });
    }

    const activeStatuses = ['trial', 'active'];
    if (!activeStatuses.includes(subscription.status)) {
      return res.status(403).json({
        message: 'Tu suscripción ha expirado o fue cancelada. Renueva tu plan para continuar.',
      });
    }

    next();
  } catch (err) {
    console.error('[checkSubscription] Error verifying subscription:', err);
    return res.status(500).json({ message: 'Error al verificar la suscripción.' });
  }
}

module.exports = checkSubscription;
