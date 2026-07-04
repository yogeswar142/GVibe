const express = require('express');

const {
  helmetConfig,
  corsOptions,
  cors,
  authLimiter,
  apiLimiter,
  messageLimiter,
  sanitize,
  hpp,
} = require('./middleware/security.middleware');

const authRoutes      = require('./routes/auth.routes');
const userRoutes      = require('./routes/user.routes');
const postRoutes      = require('./routes/post.routes');
const vibeRoutes      = require('./routes/vibe.routes');
const discoveryRoutes = require('./routes/discovery.routes');
const messageRoutes   = require('./routes/message.routes');
const lostItemRoutes  = require('./routes/lost_item.routes');

const app = express();

// Trust reverse proxy (Ngrok, Cloudflare, etc.) to allow express-rate-limit to work accurately
app.set('trust proxy', 1);

// ── 1. Security headers (Helmet) ──────────────────────────────────────────────
app.use(helmetConfig);

// ── 2. CORS ───────────────────────────────────────────────────────────────────
app.use(cors(corsOptions));
app.options('*', cors(corsOptions)); // Pre-flight for all routes

// ── 3. Body parsing with size limits (prevent payload bombing) ────────────────
app.use(express.json({ limit: '50kb' }));
app.use(express.urlencoded({ extended: true, limit: '50kb' }));

// ── 4. NoSQL injection sanitizer ──────────────────────────────────────────────
app.use(sanitize);

// ── 5. HTTP Parameter Pollution guard ─────────────────────────────────────────
app.use(hpp());

// ── 6. Request logging (sanitised — no body dump to avoid leaking passwords) ──
app.use((req, res, next) => {
  const start = Date.now();
  const reqId = Math.random().toString(36).slice(2, 9);
  req.reqId = reqId;
  console.log(`📥 [${reqId}] ${req.method} ${req.originalUrl}`);
  res.on('finish', () => {
    const ms = Date.now() - start;
    const icon = res.statusCode < 400 ? '✅' : '❌';
    const userStr = req.user ? ` [User: ${req.user.name} (${req.user._id})]` : '';
    console.log(`${icon} [${reqId}] ${req.method} ${req.originalUrl} → ${res.statusCode} (${ms}ms)${userStr}`);
  });
  next();
});

// ── 7. General API rate limiter ────────────────────────────────────────────────
app.use('/api', apiLimiter);

// ── Health check (before auth limiter so monitoring tools aren't blocked) ─────
app.get('/', (req, res) => res.json({ message: 'Welcome to GVibe API 🎉' }));
app.get('/api', (req, res) => res.json({ success: true, message: 'Welcome to GVibe API 🎉' }));

// ── 8. Routes ─────────────────────────────────────────────────────────────────
// Auth — strict rate limit (brute-force protection)
app.use('/api/auth', authLimiter, authRoutes);

app.use('/api/users',     userRoutes);
app.use('/api/posts',     postRoutes);
app.use('/api/vibes',     vibeRoutes);
app.use('/api/discovery', discoveryRoutes);

// Messages — per-send limit applied inside route file
app.use('/api/messages',  messageRoutes);

// Lost & Found
app.use('/api/lost-items', lostItemRoutes);

// ── 9. 404 handler ────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ success: false, message: 'Route not found' });
});

// ── 10. Global error handler ──────────────────────────────────────────────────
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  // CORS errors — send 403, not 500
  if (err.message?.startsWith('CORS:')) {
    return res.status(403).json({ success: false, message: err.message });
  }
  const reqId = req.reqId ?? '?';
  console.error(`❌ [${reqId}] Unhandled error:`, err.stack);
  res.status(500).json({ success: false, message: 'Internal server error' });
});

module.exports = app;
