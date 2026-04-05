'use strict';

const express = require('express');

const supabase = require('../config/db');
const stripe = require('../config/stripe');

const router = express.Router();

// ---------------------------------------------------------------------------
// POST /webhooks/stripe — receive and process Stripe webhook events
//
// IMPORTANT: This route depends on req.rawBody being set by the raw body
// middleware configured in index.js BEFORE express.json(). The signature
// verification will fail if the body has been parsed as JSON.
// ---------------------------------------------------------------------------
router.post('/', async (req, res) => {
  const sig = req.headers['stripe-signature'];

  if (!sig) {
    console.warn('[Stripe webhook] Missing stripe-signature header');
    return res.status(400).json({ message: 'Falta la firma de Stripe.' });
  }

  let event;
  try {
    event = stripe.webhooks.constructEvent(
      req.rawBody,
      sig,
      process.env.STRIPE_WEBHOOK_SECRET
    );
  } catch (err) {
    console.error('[Stripe webhook] Signature verification failed:', err.message);
    return res.status(400).json({ message: `Webhook error: ${err.message}` });
  }

  const dataObject = event.data.object;

  // Look up the subscription row by stripe_customer_id so we know which user
  // to update. Most Stripe subscription/invoice objects carry a `customer` field.
  const stripeCustomerId = dataObject.customer;

  try {
    switch (event.type) {
      // -----------------------------------------------------------------------
      // customer.subscription.updated
      // Update current_period_end from the Stripe subscription object.
      // -----------------------------------------------------------------------
      case 'customer.subscription.updated': {
        const currentPeriodEnd = dataObject.current_period_end
          ? new Date(dataObject.current_period_end * 1000).toISOString()
          : null;

        const { error } = await supabase
          .from('subscriptions')
          .update({ current_period_end: currentPeriodEnd })
          .eq('stripe_customer_id', stripeCustomerId);

        if (error) {
          console.error('[Stripe webhook] customer.subscription.updated DB error:', error);
        }
        break;
      }

      // -----------------------------------------------------------------------
      // customer.subscription.deleted
      // If the user had already cancelled voluntarily → status = 'cancelled'
      // Otherwise (payment failure, admin action) → status = 'expired'
      // -----------------------------------------------------------------------
      case 'customer.subscription.deleted': {
        // Fetch current row to check whether cancelled_at is already set
        const { data: sub, error: fetchError } = await supabase
          .from('subscriptions')
          .select('id, cancelled_at')
          .eq('stripe_customer_id', stripeCustomerId)
          .single();

        if (fetchError || !sub) {
          console.error('[Stripe webhook] customer.subscription.deleted — subscription not found for customer:', stripeCustomerId);
          break;
        }

        const newStatus = sub.cancelled_at ? 'cancelled' : 'expired';

        const { error: updateError } = await supabase
          .from('subscriptions')
          .update({ status: newStatus })
          .eq('id', sub.id);

        if (updateError) {
          console.error('[Stripe webhook] customer.subscription.deleted DB error:', updateError);
        }
        break;
      }

      // -----------------------------------------------------------------------
      // invoice.payment_succeeded
      // Subscription is now active; refresh current_period_end.
      // -----------------------------------------------------------------------
      case 'invoice.payment_succeeded': {
        // The invoice object may carry subscription_details.metadata or lines
        // with period info. The safest source for current_period_end is the
        // subscription object referenced by the invoice.
        const subscriptionId = dataObject.subscription;
        let currentPeriodEnd = null;

        if (subscriptionId) {
          try {
            const stripeSub = await stripe.subscriptions.retrieve(subscriptionId);
            currentPeriodEnd = stripeSub.current_period_end
              ? new Date(stripeSub.current_period_end * 1000).toISOString()
              : null;
          } catch (stripeErr) {
            console.error('[Stripe webhook] invoice.payment_succeeded — failed to retrieve subscription:', stripeErr.message);
          }
        }

        const updatePayload = { status: 'active' };
        if (currentPeriodEnd) updatePayload.current_period_end = currentPeriodEnd;

        const { error } = await supabase
          .from('subscriptions')
          .update(updatePayload)
          .eq('stripe_customer_id', stripeCustomerId);

        if (error) {
          console.error('[Stripe webhook] invoice.payment_succeeded DB error:', error);
        }
        break;
      }

      // -----------------------------------------------------------------------
      // invoice.payment_failed
      // TODO: send payment failure notification email to the user via Resend
      // -----------------------------------------------------------------------
      case 'invoice.payment_failed': {
        console.warn('[Stripe webhook] invoice.payment_failed for customer:', stripeCustomerId);
        // TODO: trigger email notification to user about failed payment
        break;
      }

      default:
        // Unhandled event type — acknowledge receipt without error
        console.log(`[Stripe webhook] Unhandled event type: ${event.type}`);
    }
  } catch (err) {
    console.error(`[Stripe webhook] Error processing event ${event.type}:`, err);
    return res.status(500).json({ message: 'Error procesando el evento.' });
  }

  // Stripe requires a 2xx response to acknowledge receipt
  return res.status(200).json({ received: true });
});

module.exports = router;
