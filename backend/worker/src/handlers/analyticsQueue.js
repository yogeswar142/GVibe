/**
 * handlers/analyticsQueue.js
 *
 * Cloudflare Queue consumer — receives batches of click events and
 * forwards them to the GVibe API's internal analytics endpoint.
 *
 * Free-plan behaviour:
 *  - Batches of up to 25 messages are delivered every 15 seconds
 *    (configured in wrangler.toml max_batch_size / max_batch_timeout).
 *  - Each message is retried up to 3 times on failure (max_retries).
 *  - Messages expire after 24 hours on the free plan — if the API is
 *    down for more than 24 hours, undelivered messages will be lost.
 *    This is a documented limitation of the free tier.
 *
 * Idempotency:
 *  - Each event includes a `timestamp` field.
 *  - The API endpoint uses MongoDB $inc (atomic counter) and $addToSet
 *    (idempotent unique visitor set) to make repeated deliveries safe.
 */

/**
 * Queue consumer — called by the CF runtime, NOT via HTTP.
 * @param {MessageBatch} batch
 * @param {object} env
 */
export async function handleAnalyticsQueue(batch, env) {
  // Collect all messages into one array for a single batched API call
  const events = batch.messages.map(msg => msg.body);

  try {
    const res = await fetch(
      `${env.API_BASE_URL}/internal/analytics/link-click`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-internal-secret': env.INTERNAL_SECRET,
        },
        body: JSON.stringify({ events }),
        cf: { cacheEverything: false },
      }
    );

    if (!res.ok) {
      const errText = await res.text().catch(() => '');
      console.error(`[analyticsQueue] API returned ${res.status}: ${errText}`);
      // Throw so CF retries the entire batch (each message up to max_retries)
      throw new Error(`API responded with ${res.status}`);
    }

    // Acknowledge all messages — they will NOT be retried
    batch.ackAll();
    console.log(`[analyticsQueue] Delivered ${events.length} events successfully`);
  } catch (err) {
    console.error('[analyticsQueue] Delivery failed, will retry:', err.message);
    // retryAll() tells CF to re-enqueue all messages for retry
    batch.retryAll();
  }
}
