/**
 * src/index.js — GVibe Cloudflare Worker entry point
 *
 * Routes:
 *  GET /s/:code        → Short-link redirect (KV + Queue analytics)
 *  GET /live/:code     → Live-location landing page (no-cache, no coords)
 *
 * This file also exports the queue() handler which the CF runtime calls
 * when messages arrive on the gvibe-link-analytics queue.
 *
 * Routing is path-based so adding a custom domain later requires only
 * updating wrangler.toml [[routes]] — no code changes needed.
 */

import { handleShortLink } from './handlers/shortLinks.js';
import { handleLiveLocation } from './handlers/liveLocation.js';
import { handleAnalyticsQueue } from './handlers/analyticsQueue.js';

export default {
  /**
   * HTTP request handler
   * @param {Request} request
   * @param {object} env
   * @param {ExecutionContext} ctx
   */
  async fetch(request, env, ctx) {
    const { pathname } = new URL(request.url);

    if (pathname.startsWith('/s/')) {
      return handleShortLink(request, env, ctx);
    }

    if (pathname.startsWith('/live/')) {
      return handleLiveLocation(request, env);
    }

    return new Response('Not Found', { status: 404 });
  },

  /**
   * Queue consumer — invoked by CF runtime when analytics batch is ready.
   * NOT an HTTP handler.
   * @param {MessageBatch} batch
   * @param {object} env
   */
  async queue(batch, env) {
    return handleAnalyticsQueue(batch, env);
  },
};
