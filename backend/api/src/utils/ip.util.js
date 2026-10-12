/**
 * ip.util.js
 * High-performance IP and client device extraction utility.
 * Normalizes IPv4, IPv6, and reverse-proxy forwarded IPs.
 */

/**
 * Extracts and cleans client IP address from an Express HTTP request.
 * @param {import('express').Request} req
 * @returns {string} Clean IPv4/IPv6 address or 'unknown'
 */
exports.getClientIp = (req) => {
  if (!req) return 'unknown';

  let rawIp = '';

  // 1. Check standard reverse-proxy headers (ngrok, Cloudflare, load balancers)
  const forwarded = req.headers['x-forwarded-for'];
  if (typeof forwarded === 'string' && forwarded.length > 0) {
    rawIp = forwarded.split(',')[0].trim();
  } else if (req.headers['x-real-ip']) {
    rawIp = String(req.headers['x-real-ip']).trim();
  } else if (req.headers['cf-connecting-ip']) {
    rawIp = String(req.headers['cf-connecting-ip']).trim();
  } else {
    rawIp = req.ip || req.socket?.remoteAddress || '';
  }

  return cleanIp(rawIp);
};

/**
 * Extracts and cleans client IP address from a Socket.IO connection.
 * @param {import('socket.io').Socket} socket
 * @returns {string} Clean IPv4/IPv6 address or 'unknown'
 */
exports.getSocketIp = (socket) => {
  if (!socket) return 'unknown';

  let rawIp = '';

  const forwarded = socket.handshake?.headers?.['x-forwarded-for'];
  if (typeof forwarded === 'string' && forwarded.length > 0) {
    rawIp = forwarded.split(',')[0].trim();
  } else if (socket.handshake?.headers?.['x-real-ip']) {
    rawIp = String(socket.handshake.headers['x-real-ip']).trim();
  } else {
    rawIp = socket.handshake?.address || '';
  }

  return cleanIp(rawIp);
};

/**
 * Extracts client User-Agent or device header safely.
 * @param {import('express').Request} req
 * @returns {string}
 */
exports.getUserAgent = (req) => {
  if (!req) return 'unknown';
  const ua = req.headers['user-agent'] || req.headers['x-device-info'] || 'GVibe Mobile App';
  return String(ua).slice(0, 255);
};

/**
 * Helper to strip IPv6-mapped IPv4 prefix (::ffff:) and local loopback formats.
 * @param {string} ip
 * @returns {string}
 */
function cleanIp(ip) {
  if (!ip || typeof ip !== 'string') return 'unknown';
  let cleaned = ip.trim();

  // Strip ::ffff: prefix often added by Node.js dual-stack sockets
  if (cleaned.startsWith('::ffff:')) {
    cleaned = cleaned.substring(7);
  }

  // Normalize localhost
  if (cleaned === '::1') {
    cleaned = '127.0.0.1';
  }

  return cleaned || 'unknown';
}
