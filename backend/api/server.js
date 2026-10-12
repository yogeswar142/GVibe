const dotenv = require('dotenv');
dotenv.config();

// ── Startup env validation ─────────────────────────────────────────────────
const REQUIRED_ENV = ['MONGO_URI', 'JWT_SECRET'];
for (const key of REQUIRED_ENV) {
  if (!process.env[key]) {
    console.error(`❌ Missing required env variable: ${key}`);
    process.exit(1);
  }
}
if (
  process.env.NODE_ENV === 'production' &&
  process.env.JWT_SECRET === 'gvibe_super_secret_key_change_me_in_production'
) {
  console.error('❌ FATAL: JWT_SECRET is the default dev value. Set a strong secret before deploying to production.');
  process.exit(1);
}

const http = require('http');
const app = require('./src/app');
const connectDB = require('./src/config/db');
const { initSocket } = require('./src/services/socket.service');

const PORT = process.env.PORT || 5000;

const startServer = async () => {
  try {
    await connectDB();

    // Wrap Express with http.Server so Socket.io can attach
    const httpServer = http.createServer(app);
    initSocket(httpServer);

    httpServer.listen(PORT, () => {
      console.log(`🚀 GVibe server running on port ${PORT}`);
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error.message);
    process.exit(1);
  }
};

startServer();
