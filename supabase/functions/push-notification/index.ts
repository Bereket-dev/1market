// supabase/functions/push-notification/index.ts
//
// Triggered by a Postgres webhook on INSERT into app_notifications.
// Looks up the recipient's FCM token and sends a Firebase push via
// the FCM HTTP v1 API using a service-account JWT.
//
// Required secrets (set via `supabase secrets set`):
//   FIREBASE_PROJECT_ID      — e.g. "koolan-abc12"
//   FIREBASE_CLIENT_EMAIL    — service account email from firebase-adminsdk JSON
//   FIREBASE_PRIVATE_KEY     — the private_key value (with \n as literal newlines)

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { create, getNumericDate } from 'https://deno.land/x/djwt@v2.8/mod.ts';

// ── Environment ───────────────────────────────────────────────────────────────

const SUPABASE_URL       = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const PROJECT_ID         = Deno.env.get('FIREBASE_PROJECT_ID')!;
const CLIENT_EMAIL       = Deno.env.get('FIREBASE_CLIENT_EMAIL')!;
// Stored with literal \n — replace them so the PEM is valid.
const PRIVATE_KEY        = Deno.env.get('FIREBASE_PRIVATE_KEY')!.replace(/\\n/g, '\n');

const FCM_ENDPOINT = `https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`;

// ── JWT helper (Google OAuth2 access token) ───────────────────────────────────

async function getAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  // Import the PEM private key.
  const keyData = PRIVATE_KEY
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '');

  const binaryKey = Uint8Array.from(atob(keyData), c => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    binaryKey,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const jwt = await create(
    { alg: 'RS256', typ: 'JWT' },
    {
      iss: CLIENT_EMAIL,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      exp: getNumericDate(3600),
      iat: getNumericDate(0),
    },
    cryptoKey,
  );

  const resp = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  const json = await resp.json();
  if (!resp.ok) throw new Error(`OAuth token error: ${JSON.stringify(json)}`);
  return json.access_token as string;
}

// ── FCM send ──────────────────────────────────────────────────────────────────

async function sendPush(
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
  accessToken: string,
  imageUrl?: string,
): Promise<void> {
  const payload = {
    message: {
      token,
      notification: {
        title,
        body,
        // Attach image when provided — shown as a large picture in the
        // notification shade on Android and as a thumbnail on iOS.
        ...(imageUrl ? { image: imageUrl } : {}),
      },
      data,
      android: {
        priority: 'high',
        notification: {
          channel_id: 'koolan_channel',
          sound: 'default',
          default_vibrate_timings: true,
          // Android also needs the image here for the expanded notification.
          ...(imageUrl ? { image: imageUrl } : {}),
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            // Required so iOS downloads and attaches the rich image.
            ...(imageUrl ? { 'mutable-content': 1 } : {}),
          },
        },
        // iOS rich notification image via FCM HTTP v1.
        ...(imageUrl
          ? { fcm_options: { image: imageUrl } }
          : {}),
      },
    },
  };

  const resp = await fetch(FCM_ENDPOINT, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });

  if (!resp.ok) {
    const err = await resp.text();
    // Token not registered — this is expected when a user reinstalls.
    // Log and continue rather than throwing.
    if (err.includes('UNREGISTERED') || err.includes('INVALID_ARGUMENT')) {
      console.warn(`[push] Stale token for message, skipping: ${err}`);
      return;
    }
    throw new Error(`FCM send failed: ${err}`);
  }
  console.log(`[push] Sent successfully`);
}

// ── Handler ───────────────────────────────────────────────────────────────────

serve(async (req) => {
  try {
    // Supabase sends the row as { type, table, record, old_record }.
    const { record } = await req.json() as {
      record: {
        id: string;
        user_id: string;
        title: string;
        body: string;
        payload: Record<string, unknown>;
      };
    };

    if (!record?.user_id) {
      return new Response('no user_id', { status: 400 });
    }

    // Look up the recipient's FCM token.
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    const { data: profile, error } = await supabase
      .from('profiles')
      .select('fcm_token')
      .eq('id', record.user_id)
      .maybeSingle();

    if (error) throw error;
    if (!profile?.fcm_token) {
      console.log(`[push] No FCM token for user ${record.user_id} — skipping`);
      return new Response('no token', { status: 200 });
    }

    // Stringify all payload values (FCM data must be string→string).
    const data: Record<string, string> = {};
    for (const [k, v] of Object.entries(record.payload ?? {})) {
      data[k] = String(v);
    }
    data['notification_id'] = record.id;

    // Extract image URL from payload for rich push display.
    const imageUrl = (record.payload?.imageUrl as string | undefined) || undefined;

    const accessToken = await getAccessToken();
    await sendPush(
      profile.fcm_token,
      record.title,
      record.body,
      data,
      accessToken,
      imageUrl,
    );

    return new Response('ok', { status: 200 });
  } catch (e) {
    console.error('[push] Error:', e);
    return new Response(String(e), { status: 500 });
  }
});
