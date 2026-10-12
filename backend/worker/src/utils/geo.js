/**
 * utils/geo.js
 *
 * Shared parsing utilities for click analytics — extracted from
 * the original short_link.controller.js logic so both shortLinks
 * and future handlers share a single source of truth.
 */

/**
 * Parse device category from User-Agent string.
 * @param {string} ua
 * @returns {'android'|'iphone'|'desktop'|'other'}
 */
export function parseDevice(ua = '') {
  if (/android/i.test(ua)) return 'android';
  if (/(iphone|ipad|ipod)/i.test(ua)) return 'iphone';
  if (/windows|macintosh|linux/i.test(ua)) return 'desktop';
  return 'other';
}

/**
 * Parse browser from User-Agent string.
 * @param {string} ua
 * @returns {'edge'|'chrome'|'safari'|'firefox'|'other'}
 */
export function parseBrowser(ua = '') {
  if (/edg/i.test(ua)) return 'edge';
  if (/chrome|crios/i.test(ua) && !/edg/i.test(ua)) return 'chrome';
  if (/safari/i.test(ua) && !/chrome/i.test(ua)) return 'safari';
  if (/firefox|fxios/i.test(ua)) return 'firefox';
  return 'other';
}

/**
 * Normalize referrer URL to a human-readable source name.
 * @param {string} ref
 * @returns {string}
 */
export function parseReferrer(ref = '') {
  if (!ref || ref.trim() === '') return 'Direct';
  try {
    const host = new URL(ref).hostname.toLowerCase();
    if (host.includes('linkedin')) return 'LinkedIn';
    if (host.includes('whatsapp')) return 'WhatsApp';
    if (host.includes('google')) return 'Google';
    if (host.includes('instagram')) return 'Instagram';
    if (host.includes('twitter') || host.includes('t.co') || host.includes('x.com')) return 'X';
    if (host.includes('facebook') || host.includes('fb.com')) return 'Facebook';
    if (host.includes('youtube')) return 'YouTube';
    return host.replace('www.', '');
  } catch (_) {
    return 'Other';
  }
}

/**
 * Compute a privacy-safe visitor hash using SHA-256.
 * Uses Web Crypto API (available in Cloudflare Workers).
 *
 * @param {string} ip
 * @param {string} ua
 * @returns {Promise<string>} 16-char hex prefix of hash
 */
export async function computeVisitorHash(ip, ua) {
  const data = new TextEncoder().encode(`${ip}-${ua}`);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('').substring(0, 16);
}
