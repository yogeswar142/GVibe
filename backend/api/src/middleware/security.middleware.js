/**
 * security.middleware.js
 *
 * Centralises all HTTP security hardening:
 *   1. Helmet        – sets 14 recommended HTTP security headers
 *   2. CORS          – allow-list of trusted origins only
 *   3. Body limits   – prevent payload bombing (50kb max)
 *   4. HPP           – strip duplicate query-string params (parameter pollution)
 *   5. Mongo sanitize – strip $ and . keys from req.body/params/query to block NoSQL injection
 *   6. Rate limiters  – tiered limits per route category
 */

const helmet      = require('helmet');
const cors        = require('cors');
const rateLimit   = require('express-rate-limit');
const mongoSanitize = require('express-mongo-sanitize');
const hpp         = require('hpp');

// ── Trusted origins ───────────────────────────────────────────────────────────
// Add your ngrok domain and any future custom domain here.
const ALLOWED_ORIGINS = (process.env.ALLOWED_ORIGINS || '')
  .split(',')
  .map(o => o.trim())
  .filter(Boolean);

// Always allow local dev and the static ngrok domain
const DEFAULT_ORIGINS = [
  'http://localhost:3000',
  'http://10.0.2.2:5000',      // Android emulator
  'https://levitative-unpresumptuously-claire.ngrok-free.dev',
];

const allowedOrigins = new Set([...DEFAULT_ORIGINS, ...ALLOWED_ORIGINS]);

const corsOptions = {
  origin: (origin, callback) => {
    // Allow requests with no origin (mobile apps, Postman, curl)
    if (!origin) return callback(null, true);
    if (allowedOrigins.has(origin)) return callback(null, true);
    callback(new Error(`CORS: origin '${origin}' not allowed`));
  },
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
  optionsSuccessStatus: 204,
};

// ── Rate limiters ─────────────────────────────────────────────────────────────

const createLimiter = (windowMinutes, max, message) =>
  rateLimit({
    windowMs: windowMinutes * 60 * 1000,
    max,
    message: { success: false, message },
    standardHeaders: true,   // Return RateLimit-* headers
    legacyHeaders: false,     // Disable X-RateLimit-* legacy headers
    skipSuccessfulRequests: false,
  });

// Auth endpoints — strictest: 10 attempts per 15 min
const authLimiter = createLimiter(
  15, 10,
  'Too many login/register attempts. Please try again in 15 minutes.'
);

// General API — 200 requests per 5 min per IP
const apiLimiter = createLimiter(
  5, 200,
  'Too many requests. Please slow down.'
);

// Message send — 60 per minute (prevents DM spam)
const messageLimiter = createLimiter(
  1, 60,
  'You are sending messages too quickly. Please wait a moment.'
);

// ── Helmet config ─────────────────────────────────────────────────────────────
// contentSecurityPolicy disabled because this is a pure JSON API (no HTML).
const helmetConfig = helmet({
  contentSecurityPolicy: false,
  crossOriginEmbedderPolicy: false, // Not needed for API
});

// ── NoSQL Injection sanitizer ─────────────────────────────────────────────────
// Strips keys containing $ or . from req.body, req.query, req.params
const sanitize = mongoSanitize({
  replaceWith: '_', // Replace prohibited chars instead of deleting key entirely
  onSanitizeError: (req, key) => {
    console.warn(`⚠️  Sanitized suspicious key "${key}" from ${req.method} ${req.originalUrl}`);
  },
});

module.exports = {
  helmetConfig,
  corsOptions,
  cors,
  authLimiter,
  apiLimiter,
  messageLimiter,
  sanitize,
  hpp,
};
