// supabase/functions/cloudinary-sign/index.ts
//
// Returns a Cloudinary upload signature for an authenticated user.
// The API secret never leaves the server — students cannot extract it from the APK.
//
// Required secrets:
//   CLOUDINARY_CLOUD_NAME  — public cloud name (also fine as dart-define on client)
//   CLOUDINARY_API_KEY     — API key returned to the client with the signature
//   CLOUDINARY_API_SECRET  — used only here to compute the SHA-1 signature
//
// Request body (JSON):
//   { "paramsToSign": { "public_id": "...", "timestamp": "..." , ... } }
//
// Response:
//   { "signature": "...", "apiKey": "...", "timestamp": "...", "cloudName": "..." }

import { createClient } from 'npm:@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!;
const CLOUD_NAME = Deno.env.get('CLOUDINARY_CLOUD_NAME') ?? '';
const API_KEY = Deno.env.get('CLOUDINARY_API_KEY') ?? '';
const API_SECRET = Deno.env.get('CLOUDINARY_API_SECRET') ?? '';

const ALLOWED_SIGN_KEYS = new Set([
  'public_id',
  'timestamp',
  'overwrite',
  'invalidate',
  'folder',
]);

async function sha1Hex(message: string): Promise<string> {
  const data = new TextEncoder().encode(message);
  const digest = await crypto.subtle.digest('SHA-1', data);
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

function corsHeaders(origin: string | null): HeadersInit {
  return {
    'Access-Control-Allow-Origin': origin ?? '*',
    'Access-Control-Allow-Headers':
      'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  };
}

Deno.serve(async (req) => {
  const origin = req.headers.get('Origin');
  const headers = corsHeaders(origin);

  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers });
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'method_not_allowed' }), {
      status: 405,
      headers: { ...headers, 'Content-Type': 'application/json' },
    });
  }

  if (!CLOUD_NAME || !API_KEY || !API_SECRET) {
    return new Response(JSON.stringify({ error: 'not_configured' }), {
      status: 503,
      headers: { ...headers, 'Content-Type': 'application/json' },
    });
  }

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'unauthorized' }), {
      status: 401,
      headers: { ...headers, 'Content-Type': 'application/json' },
    });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    return new Response(JSON.stringify({ error: 'unauthorized' }), {
      status: 401,
      headers: { ...headers, 'Content-Type': 'application/json' },
    });
  }

  let body: { paramsToSign?: Record<string, unknown> };
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: 'invalid_json' }), {
      status: 400,
      headers: { ...headers, 'Content-Type': 'application/json' },
    });
  }

  const raw = body.paramsToSign ?? {};
  const params: Record<string, string> = {};
  for (const [key, value] of Object.entries(raw)) {
    if (!ALLOWED_SIGN_KEYS.has(key)) continue;
    if (value === undefined || value === null) continue;
    params[key] = String(value);
  }

  if (!params.public_id || !params.timestamp) {
    return new Response(JSON.stringify({ error: 'missing_params' }), {
      status: 400,
      headers: { ...headers, 'Content-Type': 'application/json' },
    });
  }

  // Public IDs must stay under onemarket/ and include the caller's user id.
  const publicId = params.public_id;
  if (!publicId.startsWith('onemarket/') || !publicId.includes(user.id)) {
    return new Response(JSON.stringify({ error: 'forbidden_public_id' }), {
      status: 403,
      headers: { ...headers, 'Content-Type': 'application/json' },
    });
  }

  const sorted = Object.keys(params)
    .sort()
    .map((k) => `${k}=${params[k]}`)
    .join('&');
  const signature = await sha1Hex(`${sorted}${API_SECRET}`);

  return new Response(
    JSON.stringify({
      signature,
      apiKey: API_KEY,
      timestamp: params.timestamp,
      cloudName: CLOUD_NAME,
    }),
    {
      status: 200,
      headers: { ...headers, 'Content-Type': 'application/json' },
    },
  );
});
