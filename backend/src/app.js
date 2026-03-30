const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/auth.routes');
const userRoutes = require('./routes/user.routes');
const vibeRoutes = require('./routes/vibe.routes');
const discoveryRoutes = require('./routes/discovery.routes');
const messageRoutes = require('./routes/message.routes');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request logging middleware
app.use((req, res, next) => {
  const start = Date.now();
  console.log(`📥 ${req.method} ${req.originalUrl}`);
  if (req.method === 'POST' || req.method === 'PUT') {
    console.log('   Body:', JSON.stringify(req.body, null, 2));
  }
  res.on('finish', () => {
    const duration = Date.now() - start;
    const statusIcon = res.statusCode < 400 ? '✅' : '❌';
    console.log(`${statusIcon} ${req.method} ${req.originalUrl} → ${res.statusCode} (${duration}ms)`);
  });
  next();
});

// Health check
app.get('/', (req, res) => {
  res.json({ message: 'Welcome to GVibe API 🎉' });
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/vibes', vibeRoutes);
app.use('/api/discovery', discoveryRoutes);
app.use('/api/messages', messageRoutes);

// Global error handler
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err.stack);
  res.status(500).json({ success: false, message: 'Internal server error' });
});

module.exports = app;
