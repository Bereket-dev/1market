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

import { createClient } from 'npm:@supabase/supabase-js@2';
import { SignJWT, importPKCS8 } from 'npm:jose@5';

// ── Environment ───────────────────────────────────────────────────────────────

const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
const PUSH_WEBHOOK_SECRET = Deno.env.get("PUSH_WEBHOOK_SECRET");
const PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID');
const CLIENT_EMAIL = Deno.env.get('FIREBASE_CLIENT_EMAIL');
// Stored with literal \n — replace them so the PEM is valid.
const PRIVATE_KEY = Deno.env.get('FIREBASE_PRIVATE_KEY')?.replace(/\\n/g, '\n');

const requireEnv = (name: string, value: string | undefined): string => {
  if (!value?.trim()) throw new Error('Missing required function secret: ' + name);
  return value;
};

const FCM_ENDPOINT = `https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`;

// ── JWT helper (Google OAuth2 access token) ───────────────────────────────────

async function getAccessToken(): Promise<string> {
  const privateKey = await importPKCS8(requireEnv('FIREBASE_PRIVATE_KEY', PRIVATE_KEY), 'RS256');

  const jwt = await new SignJWT({
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
  })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuer(requireEnv('FIREBASE_CLIENT_EMAIL', CLIENT_EMAIL))
    .setAudience('https://oauth2.googleapis.com/token')
    .setIssuedAt()
    .setExpirationTime('1h')
    .sign(privateKey);

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

type SendResult = 'sent' | 'stale_token';

async function sendPush(
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
  accessToken: string,
  imageUrl?: string,
  notificationType?: string,
): Promise<SendResult> {
  const channelId =
    notificationType === 'new_message'
      ? 'onemarket_messages_channel_v2'
      : 'onemarket_channel_v2';

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
          channel_id: channelId,
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
      return 'stale_token';
    }
    throw new Error(`FCM send failed: ${err}`);
  }
  console.log(`[push] Sent successfully`);
  return 'sent';
}

// ── Handler ───────────────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  const expectedAuth = "Bearer " + (PUSH_WEBHOOK_SECRET ?? "");
  if (req.headers.get("authorization") !== expectedAuth || !PUSH_WEBHOOK_SECRET) {
    return new Response("Unauthorized", { status: 401 });
  }

  try {
    // Supabase sends the row as { type, table, record, old_record }.
    const { record } = await req.json() as {
      record: {
        id: string;
        user_id: string;
        type: string;
        title: string;
        body: string;
        payload: Record<string, unknown>;
      };
    };

    if (!record?.user_id) {
      return new Response('no user_id', { status: 400 });
    }

    // Look up the recipient's FCM token.
    const supabase = createClient(
      requireEnv('SUPABASE_URL', SUPABASE_URL),
      requireEnv('SUPABASE_SERVICE_ROLE_KEY', SUPABASE_SERVICE_KEY),
    );
    const { data: profile, error } = await supabase
      .from('profiles')
      .select('fcm_token, notif_push_enabled, notif_messages_enabled')
      .eq('id', record.user_id)
      .maybeSingle();

    if (error) throw error;
    if (!profile?.fcm_token) {
      console.log(`[push] No FCM token for user ${record.user_id} — skipping`);
      return new Response('no token', { status: 200 });
    }

    if (profile.notif_push_enabled === false) {
      console.log(`[push] Push disabled for user ${record.user_id} — skipping`);
      return new Response('push disabled', { status: 200 });
    }

    if (
      record.type === 'new_message' &&
      profile.notif_messages_enabled === false
    ) {
      console.log(`[push] Message push disabled for user ${record.user_id} — skipping`);
      return new Response('messages disabled', { status: 200 });
    }

    // Stringify all payload values (FCM data must be string→string).
    const data: Record<string, string> = {};
    for (const [k, v] of Object.entries(record.payload ?? {})) {
      data[k] = String(v);
    }
    data['notification_id'] = record.id;
    data['type'] = record.type;

    // Extract image URL from payload for rich push display.
    // Treat empty string as missing (nearby trigger stores '' when no photo).
    const rawImage = record.payload?.imageUrl;
    const imageUrl =
      typeof rawImage === 'string' && rawImage.trim() !== ''
        ? rawImage
        : undefined;

    requireEnv('FIREBASE_PROJECT_ID', PROJECT_ID);
    const accessToken = await getAccessToken();
    const result = await sendPush(
      profile.fcm_token,
      record.title,
      record.body,
      data,
      accessToken,
      imageUrl,
      record.type,
    );

    // Drop dead tokens so the next device login can claim a fresh one and
    // nearby/message pushes stop targeting UNREGISTERED devices.
    if (result === 'stale_token') {
      const { error: clearErr } = await supabase
        .from('profiles')
        .update({ fcm_token: null })
        .eq('id', record.user_id)
        .eq('fcm_token', profile.fcm_token);
      if (clearErr) {
        console.warn(`[push] Failed to clear stale token: ${clearErr.message}`);
      } else {
        console.log(`[push] Cleared stale FCM token for user ${record.user_id}`);
      }
      return new Response('stale_token', { status: 200 });
    }

    return new Response('ok', { status: 200 });
  } catch (e) {
    console.error('[push] Error:', e);
    return new Response(String(e), { status: 500 });
  }
});
