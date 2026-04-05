'use strict';

// Load environment variables first — before any module that reads process.env
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');

const authRouter = require('./routes/auth');
const groupsRouter = require('./routes/groups');
const roomsRouter = require('./routes/rooms');
const paymentsRouter = require('./routes/payments');
const adminRouter = require('./routes/admin');
const superadminRouter = require('./routes/superadmin');
const stripeWebhookRouter = require('./webhooks/stripe');
const { initWebSocket } = require('./ws/ws_server');

const app = express();
const PORT = process.env.PORT || 3000;

// ---------------------------------------------------------------------------
// Global middleware
// ---------------------------------------------------------------------------

app.use(cors());

// ---------------------------------------------------------------------------
// Stripe webhook — must receive raw body for signature verification.
// Mount BEFORE express.json() so the buffer is not consumed by the JSON parser.
// ---------------------------------------------------------------------------
app.use(
  '/webhooks/stripe',
  express.raw({ type: 'application/json' }),
  (req, _res, next) => {
    req.rawBody = req.body;
    next();
  }
);

app.use(express.json());

// ---------------------------------------------------------------------------
// Rate limiting — /auth/* : 10 requests per minute per IP
// ---------------------------------------------------------------------------
const authLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: 'Demasiadas solicitudes. Intenta de nuevo en un minuto.',
  },
});

app.use('/auth', authLimiter);

// ---------------------------------------------------------------------------
// Routes
// ---------------------------------------------------------------------------

app.use('/auth', authRouter);
app.use('/groups', groupsRouter);
app.use('/rooms', roomsRouter);
app.use('/payments', paymentsRouter);
app.use('/admin', adminRouter);
app.use('/superadmin', superadminRouter);
app.use('/webhooks', stripeWebhookRouter);

// Health check — useful for deployment platforms
app.get('/health', (_req, res) => {
  res.json({ success: true, status: 'ok' });
});

// 404 fallback
app.use((_req, res) => {
  res.status(404).json({ success: false, error: 'Ruta no encontrada.' });
});

// ---------------------------------------------------------------------------
// Start server
// ---------------------------------------------------------------------------

const server = app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

initWebSocket(server);

module.exports = app;
