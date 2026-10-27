// ResQMitra API  –  Express + Neon (PostgreSQL)
// The phone talks ONLY to this server. The database password never leaves it.
import 'dotenv/config';
import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import jwt from 'jsonwebtoken';
import pg from 'pg';
import crypto from 'node:crypto';
import { S3Client, PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';

const { DATABASE_URL, JWT_SECRET, RENFLAIR_API_KEY } = process.env;
// Render injects PORT (usually 10000). A *blank* PORT env var is the empty string '' – the old
// `PORT = 8080` default only covers `undefined`, so it crashed with ERR_SOCKET_BAD_PORT.
// Parse it, and fall back to 8080 for anything missing / blank / not a valid port number.
const PORT = (() => {
  const n = Number.parseInt(String(process.env.PORT ?? '').trim(), 10);
  return Number.isInteger(n) && n > 0 && n < 65536 ? n : 8080;
})();
if (!DATABASE_URL || !JWT_SECRET) {
  console.error('DATABASE_URL and JWT_SECRET must be set');
  process.exit(1);
}

const S3_ENDPOINT = process.env.S3_ENDPOINT || '';
const S3_BUCKET = process.env.S3_BUCKET || 'assets';
const S3_REGION = process.env.S3_REGION || 'auto';
const S3_ACCESS_KEY_ID = process.env.S3_ACCESS_KEY_ID || '';
const S3_SECRET_ACCESS_KEY = process.env.S3_SECRET_ACCESS_KEY || '';
const s3Enabled = Boolean(S3_ENDPOINT && S3_ACCESS_KEY_ID && S3_SECRET_ACCESS_KEY);
const s3 = s3Enabled ? new S3Client({
  endpoint: S3_ENDPOINT,
  region: S3_REGION,
  forcePathStyle: true,
  credentials: { accessKeyId: S3_ACCESS_KEY_ID, secretAccessKey: S3_SECRET_ACCESS_KEY },
}) : null;

const pool = new pg.Pool({
  connectionString: DATABASE_URL,
  max: 8,
  idleTimeoutMillis: 20_000,
  connectionTimeoutMillis: 15_000, // Neon may need a moment to wake up
});
pool.on('error', (e) => console.error('pg pool error', e.message)); // never crash on a dropped idle connection
const q = (text, params) => pool.query(text, params);

const BADGES = new Set([
  '', 'life_saver', 'accident_angel', 'medical_hero', 'fire_fighter', 'flood_warrior', 'rescue_champ',
  'womens_safety_guardian', 'child_care_hero', 'location_legend', 'team_player', 'reliable_responder',
  'community_supporter', 'brave_soul', 'hope_giver', 'special_thanks',
]);
const ROLES = new Set(['seeker', 'rescuer', 'both']);
const KINDS = new Set(['photo', 'id_doc', 'sos_photo', 'sos_audio']);
const MIMES = new Set(['image/jpeg', 'image/png', 'image/webp', 'audio/mp4', 'audio/aac', 'audio/mpeg', 'audio/x-m4a']);
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const str = (v, max = 500) => (typeof v === 'string' ? v.trim().slice(0, max) : '');
const num = (v, d = null) => (typeof v === 'number' && Number.isFinite(v) ? v : d);
const uuidOrNull = (v) => (typeof v === 'string' && UUID.test(v) ? v : null);
const bad = (res, msg, code = 400) => res.status(code).json({ error: msg });

const app = express();
app.set('trust proxy', 1); // behind Render's proxy
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(rateLimit({ windowMs: 60_000, limit: 240, standardHeaders: true, legacyHeaders: false }));
const registerLimit = rateLimit({ windowMs: 60 * 60_000, limit: 20 });
const otpSendLimit = rateLimit({ windowMs: 15 * 60_000, limit: 5, message: { error: 'Too many OTP requests. Please wait and try again.' } });
const otpVerifyLimit = rateLimit({ windowMs: 15 * 60_000, limit: 15, message: { error: 'Too many verification attempts. Please wait and try again.' } });
const uploadLimit = rateLimit({ windowMs: 60_000, limit: 20 });

const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

function auth(req, res, next) {
  const h = req.headers.authorization || '';
  const t = h.startsWith('Bearer ') ? h.slice(7) : '';
  try {
    req.uid = jwt.verify(t, JWT_SECRET).sub;
    next();
  } catch {
    bad(res, 'unauthorized', 401);
  }
}

// profile keys that are local file paths / bulky blobs – never stored in the JSON column
const DROP = new Set(['photo', 'docPhoto', 'doc']);
function cleanProfile(p) {
  const out = {};
  if (!p || typeof p !== 'object') return out;
  for (const [k, v] of Object.entries(p)) {
    if (DROP.has(k) || k.endsWith('Bytes')) continue;
    if (['string', 'number', 'boolean'].includes(typeof v) || Array.isArray(v)) out[k] = v;
  }
  return out;
}

async function saveContacts(client, uid, contacts) {
  await client.query('DELETE FROM contacts WHERE user_id=$1', [uid]);
  const list = Array.isArray(contacts) ? contacts.slice(0, 5) : [];
  for (let i = 0; i < list.length; i++) {
    const c = list[i] || {};
    const phone = str(c.phone, 15);
    if (!phone) continue;
    await client.query(
      'INSERT INTO contacts (user_id, position, name, phone, relation, method) VALUES ($1,$2,$3,$4,$5,$6)',
      [uid, i, str(c.name, 80), phone, str(c.relation, 40), str(c.method, 20) || 'Both'],
    );
  }
}

const sosJson = (r, me) => ({
  id: r.id,
  user_id: r.user_id,
  category: r.category,
  type: r.type,
  name: r.name,
  phone: r.do_not_call && r.user_id !== me ? '' : r.phone,
  lat: r.lat,
  lng: r.lng,
  address: r.address,
  description: r.description,
  tags: r.tags,
  details: r.details,
  high_alert: r.high_alert,
  do_not_call: r.do_not_call,
  photo_file: r.photo_file,
  audio_file: r.audio_file,
  stage: r.stage,
  status: r.status,
  responder_id: r.responder_id,
  responder_name: r.responder_name,
  created_at: r.created_at,
  updated_at: r.updated_at,
  km: r.km ?? null,
});

// ───────────────────────── health ─────────────────────────
// Home page: opening the bare Render URL used to hit the 404 handler. Now it confirms the API is up.
app.get('/', (_req, res) => res.json({
  name: 'ResQMitra API',
  status: 'running',
  tagline: 'Be the first to respond',
  health: '/health',
  database_check: '/health/db',
}));

// Light check (no database) – used by Render's health check so a sleeping Neon DB never marks the service as down.
app.get('/health', (_req, res) => res.json({ ok: true, uptime_s: Math.round(process.uptime()) }));

// Deep check: also tests the Neon connection. Open this one to confirm DATABASE_URL is correct.
app.get('/health/db', wrap(async (_req, res) => {
  await q('SELECT 1');
  res.json({ ok: true, database: 'connected' });
}));

// ───────────────────────── phone OTP (Renflair) ─────────────────────────
function normalizeIndianPhone(value) {
  const digits = String(value ?? '').replace(/\D/g, '');
  // This registration form currently collects Indian 10-digit mobile numbers.
  return digits.length === 10 ? digits : null;
}
function otpDigest(phone, otp) {
  return crypto.createHash('sha256').update(`${phone}:${otp}:${JWT_SECRET}`).digest('hex');
}
app.post('/auth/otp/send', otpSendLimit, wrap(async (req, res) => {
  const phone = normalizeIndianPhone(req.body?.phone);
  if (!phone) return bad(res, 'Enter a valid 10-digit Indian mobile number');
  if (!RENFLAIR_API_KEY) return bad(res, 'SMS OTP service is not configured on the backend', 503);

  const prior = await q('SELECT last_sent_at FROM phone_otp_challenges WHERE phone=$1', [phone]);
  if (prior.rowCount && Date.now() - new Date(prior.rows[0].last_sent_at).getTime() < 60_000) {
    return bad(res, 'Please wait 60 seconds before requesting another OTP', 429);
  }

  const otp = String(crypto.randomInt(100000, 1000000));
  await q(
    `INSERT INTO phone_otp_challenges (phone, otp_hash, expires_at, attempts, last_sent_at)
     VALUES ($1,$2,now() + interval '5 minutes',0,now())
     ON CONFLICT (phone) DO UPDATE SET otp_hash=EXCLUDED.otp_hash,
       expires_at=EXCLUDED.expires_at, attempts=0, last_sent_at=now()`,
    [phone, otpDigest(phone, otp)],
  );

  try {
    const url = new URL('https://sms.renflair.in/V1.php');
    url.searchParams.set('API', RENFLAIR_API_KEY);
    url.searchParams.set('PHONE', phone);
    url.searchParams.set('OTP', otp);
    const providerResponse = await fetch(url, { method: 'GET', signal: AbortSignal.timeout(15000) });
    const providerBody = await providerResponse.text();
    let providerJson = null;
    try { providerJson = JSON.parse(providerBody); } catch {}
    const providerText = typeof providerJson === 'object' && providerJson
      ? JSON.stringify(providerJson).toLowerCase() : providerBody.toLowerCase();
    const providerFailed = !providerResponse.ok ||
      (providerJson && (providerJson.success === false ||
        ['error', 'failed'].includes(String(providerJson.status ?? '').toLowerCase()))) ||
      /invalid api|insufficient balance/i.test(providerText);
    if (providerFailed) {
      await q('DELETE FROM phone_otp_challenges WHERE phone=$1', [phone]);
      console.error('Renflair OTP request failed with HTTP', providerResponse.status);
      return bad(res, 'SMS provider could not send the OTP. Check the Renflair account and API configuration.', 502);
    }
    res.json({ ok: true, message: 'OTP request submitted. Check your SMS messages.' });
  } catch (e) {
    await q('DELETE FROM phone_otp_challenges WHERE phone=$1', [phone]).catch(() => {});
    console.error('Renflair OTP request failed:', e?.name || 'provider error');
    return bad(res, 'Could not contact the SMS provider. Please try again.', 502);
  }
}));

app.post('/auth/otp/verify', otpVerifyLimit, wrap(async (req, res) => {
  const phone = normalizeIndianPhone(req.body?.phone);
  const otp = String(req.body?.otp ?? '').trim();
  if (!phone || !/^\\d{6}$/.test(otp)) return bad(res, 'Enter the 6-digit OTP sent to your phone');
  const r = await q('SELECT otp_hash, expires_at, attempts FROM phone_otp_challenges WHERE phone=$1', [phone]);
  if (!r.rowCount) return bad(res, 'OTP expired or not requested. Request a new OTP.', 400);
  const challenge = r.rows[0];
  if (new Date(challenge.expires_at).getTime() < Date.now()) {
    await q('DELETE FROM phone_otp_challenges WHERE phone=$1', [phone]);
    return bad(res, 'OTP expired. Request a new one.', 400);
  }
  if (challenge.attempts >= 5) {
    await q('DELETE FROM phone_otp_challenges WHERE phone=$1', [phone]);
    return bad(res, 'Too many incorrect attempts. Request a new OTP.', 429);
  }
  const expected = Buffer.from(challenge.otp_hash, 'hex');
  const actual = Buffer.from(otpDigest(phone, otp), 'hex');
  if (expected.length !== actual.length || !crypto.timingSafeEqual(expected, actual)) {
    await q('UPDATE phone_otp_challenges SET attempts=attempts+1 WHERE phone=$1', [phone]);
    return bad(res, 'Incorrect OTP. Please check the code and try again.', 400);
  }
  await q(
    `INSERT INTO verified_phones (phone, verified_at, expires_at)
     VALUES ($1,now(),now() + interval '30 minutes')
     ON CONFLICT (phone) DO UPDATE SET verified_at=now(), expires_at=now() + interval '30 minutes'`,
    [phone],
  );
  await q('DELETE FROM phone_otp_challenges WHERE phone=$1', [phone]);
  res.json({ ok: true, verified: true });
}));

// ───────────────────────── auth / profile ─────────────────────────
app.post('/auth/register', registerLimit, wrap(async (req, res) => {
  const { role, profile, contacts } = req.body || {};
  if (!ROLES.has(role)) return bad(res, 'invalid role');
  const p = cleanProfile(profile);
  const name = str(p.name, 100);
  if (!name) return bad(res, 'name required');
  const phone = normalizeIndianPhone(p.mobile);
  if (!phone || phone !== str(p.mobile, 20).replace(/\D/g, '')) {
    return bad(res, 'A verified 10-digit Indian mobile number is required');
  }
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const verified = await client.query(
      'SELECT phone FROM verified_phones WHERE phone=$1 AND expires_at > now() FOR UPDATE',
      [phone],
    );
    if (!verified.rowCount) {
      await client.query('ROLLBACK');
      return bad(res, 'Verify this phone number by SMS OTP before registering', 403);
    }
    const r = await client.query(
      `INSERT INTO users (role, name, mobile, email, blood_group, profile)
       VALUES ($1,$2,$3,$4,$5,$6) RETURNING id`,
      [role, name, str(p.mobile, 15), str(p.email, 120), str(p.blood, 10), p],
    );
    const id = r.rows[0].id;
    await saveContacts(client, id, contacts);
    await client.query('DELETE FROM verified_phones WHERE phone=$1', [phone]);
    await client.query('COMMIT');
    const token = jwt.sign({ sub: id }, JWT_SECRET, { expiresIn: '365d' });
    res.json({ user_id: id, token });
  } catch (e) {
    await client.query('ROLLBACK').catch(() => {});
    throw e;
  } finally {
    client.release();
  }
}));

app.put('/me/profile', auth, wrap(async (req, res) => {
  const { role, profile, contacts, photo_file, doc_file } = req.body || {};
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const cur = await client.query('SELECT * FROM users WHERE id=$1 FOR UPDATE', [req.uid]);
    if (!cur.rowCount) { await client.query('ROLLBACK'); return bad(res, 'user not found', 404); }
    const u = cur.rows[0];
    const p = profile ? cleanProfile(profile) : u.profile;
    const oldPhone = normalizeIndianPhone(u.mobile);
    const nextPhone = normalizeIndianPhone(profile ? p.mobile : u.mobile);
    if (!nextPhone) {
      await client.query('ROLLBACK');
      return bad(res, 'A valid 10-digit Indian mobile number is required');
    }
    if (nextPhone !== oldPhone) {
      const verified = await client.query(
        'SELECT phone FROM verified_phones WHERE phone=$1 AND expires_at > now() FOR UPDATE',
        [nextPhone],
      );
      if (!verified.rowCount) {
        await client.query('ROLLBACK');
        return bad(res, 'Verify the new phone number by SMS OTP before updating your profile', 403);
      }
      await client.query('DELETE FROM verified_phones WHERE phone=$1', [nextPhone]);
    }
    await client.query(
      `UPDATE users SET role=$2, name=$3, mobile=$4, email=$5, blood_group=$6, profile=$7,
              photo_file=COALESCE($8, photo_file), doc_file=COALESCE($9, doc_file), updated_at=now()
       WHERE id=$1`,
      [
        req.uid,
        ROLES.has(role) ? role : u.role,
        str(p.name, 100) || u.name,
        profile ? str(p.mobile, 15) : u.mobile,
        profile ? str(p.email, 120) : u.email,
        profile ? str(p.blood, 10) : u.blood_group,
        p,
        uuidOrNull(photo_file),
        uuidOrNull(doc_file),
      ],
    );
    if (Array.isArray(contacts)) await saveContacts(client, req.uid, contacts);
    await client.query('COMMIT');
    res.json({ ok: true });
  } catch (e) {
    await client.query('ROLLBACK').catch(() => {});
    throw e;
  } finally {
    client.release();
  }
}));

app.get('/me', auth, wrap(async (req, res) => {
  const u = await q('SELECT id, role, name, mobile, email, blood_group, profile, photo_file, created_at FROM users WHERE id=$1', [req.uid]);
  if (!u.rowCount) return bad(res, 'user not found', 404);
  const c = await q('SELECT name, phone, relation, method FROM contacts WHERE user_id=$1 ORDER BY position', [req.uid]);
  res.json({ user: u.rows[0], contacts: c.rows });
}));

app.put('/me/presence', auth, wrap(async (req, res) => {
  const { online, lat, lng } = req.body || {};
  await q(
    `UPDATE users SET online=$2, last_lat=COALESCE($3,last_lat), last_lng=COALESCE($4,last_lng), last_seen=now() WHERE id=$1`,
    [req.uid, online === true, num(lat), num(lng)],
  );
  res.json({ ok: true });
}));

// Everything the Profile screen shows (badges, reviews, completed responses, counters)
app.get('/me/summary', auth, wrap(async (req, res) => {
  const [badges, reviews, responses, sent, user] = await Promise.all([
    q(`SELECT a.badge_key, a.message, a.created_at, u.name AS from_name
         FROM appreciations a JOIN users u ON u.id=a.from_user
        WHERE a.to_user=$1 AND a.badge_key<>'' ORDER BY a.created_at`, [req.uid]),
    q(`SELECT a.rating, a.feedback, a.message, a.created_at, u.name AS from_name
         FROM appreciations a JOIN users u ON u.id=a.from_user
        WHERE a.to_user=$1 AND (a.rating>0 OR a.feedback<>'' OR a.message<>'') ORDER BY a.created_at`, [req.uid]),
    q(`SELECT type, category, name, address, updated_at FROM sos
        WHERE responder_id=$1 AND stage>=4 ORDER BY updated_at`, [req.uid]),
    q('SELECT count(*)::int AS n FROM sos WHERE user_id=$1', [req.uid]),
    q('SELECT created_at FROM users WHERE id=$1', [req.uid]),
  ]);
  res.json({
    badges: badges.rows,
    reviews: reviews.rows,
    responses: responses.rows,
    sent: sent.rows[0].n,
    since: user.rows[0]?.created_at ?? null,
  });
}));

// ───────────────────────── file storage ─────────────────────────
app.post('/files', auth, uploadLimit, express.raw({ type: () => true, limit: '8mb' }), wrap(async (req, res) => {
  const kind = str(req.query.kind, 20);
  const mime = str((req.headers['content-type'] || '').split(';')[0], 40).toLowerCase();
  if (!KINDS.has(kind)) return bad(res, 'invalid kind');
  if (!MIMES.has(mime)) return bad(res, 'unsupported file type');
  if (!Buffer.isBuffer(req.body) || req.body.length === 0) return bad(res, 'empty file');
  // Prefer Neon-compatible S3 object storage when configured; retain the database fallback
  // so existing deployments keep working until their S3 credentials are added.
  const fileId = crypto.randomUUID();
  let storageKey = null;
  if (s3Enabled) {
    storageKey = `users/${req.uid}/${kind}/${fileId}`;
    await s3.send(new PutObjectCommand({ Bucket: S3_BUCKET, Key: storageKey, Body: req.body, ContentType: mime }));
  }
  const r = await q(
    'INSERT INTO files (id, owner_id, kind, mime, size, data, storage_key) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING id',
    [fileId, req.uid, kind, mime, req.body.length, s3Enabled ? Buffer.alloc(0) : req.body, storageKey],
  );
  res.json({ file_id: r.rows[0].id, storage: s3Enabled ? 'object' : 'database' });
}));

app.get('/files/:id', auth, wrap(async (req, res) => {
  if (!UUID.test(req.params.id)) return bad(res, 'not found', 404);
  const r = await q('SELECT owner_id, kind, mime, data, storage_key FROM files WHERE id=$1', [req.params.id]);
  if (!r.rowCount) return bad(res, 'not found', 404);
  const f = r.rows[0];
  if (f.kind === 'id_doc' && f.owner_id !== req.uid) return bad(res, 'forbidden', 403); // ID documents: owner only
  if (f.kind === 'sos_photo' || f.kind === 'sos_audio') {
    const access = await q(
      `SELECT 1 FROM sos
        WHERE (photo_file=$1 OR audio_file=$1)
          AND (user_id=$2 OR (responder_id=$2 AND stage >= 1))
        LIMIT 1`,
      [req.params.id, req.uid],
    );
    if (!access.rowCount) return bad(res, 'forbidden', 403);
  }
  res.set('Content-Type', f.mime);
  res.set('Cache-Control', 'private, max-age=86400');
  if (f.storage_key && s3Enabled) {
    const obj = await s3.send(new GetObjectCommand({ Bucket: S3_BUCKET, Key: f.storage_key }));
    if (!obj.Body) return bad(res, 'stored file unavailable', 502);
    for await (const chunk of obj.Body) res.write(chunk);
    return res.end();
  }
  res.send(f.data);
}));

// ───────────────────────── SOS ─────────────────────────
app.post('/sos', auth, wrap(async (req, res) => {
  const b = req.body || {};
  const clientRef = str(b.client_ref, 60);
  if (!clientRef || !str(b.type, 100) || !str(b.category, 40)) return bad(res, 'invalid sos');
  const u = await q('SELECT name, mobile FROM users WHERE id=$1', [req.uid]);
  if (!u.rowCount) return bad(res, 'user not found', 404);
  const details = {};
  if (b.details && typeof b.details === 'object') {
    for (const [k, v] of Object.entries(b.details).slice(0, 30)) details[str(k, 60)] = str(String(v), 300);
  }
  const tags = Array.isArray(b.tags) ? b.tags.slice(0, 20).map((t) => str(String(t), 40)) : [];
  const r = await q(
    `INSERT INTO sos (client_ref, user_id, category, type, name, phone, lat, lng, address, description,
                      tags, details, high_alert, do_not_call)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)
     ON CONFLICT (user_id, client_ref) DO UPDATE SET updated_at = now()
     RETURNING id, stage, status`,
    [
      clientRef, req.uid, str(b.category, 40), str(b.type, 100), u.rows[0].name, u.rows[0].mobile || '',
      num(b.lat, 0), num(b.lng, 0), str(b.address, 300), str(b.description, 1000),
      tags, details, b.high_alert === true, b.do_not_call === true,
    ],
  );
  await q('INSERT INTO sos_events (sos_id, actor_id, stage, note) VALUES ($1,$2,0,$3)', [r.rows[0].id, req.uid, 'SOS created']).catch(() => {});
  res.json({ id: r.rows[0].id, stage: r.rows[0].stage, status: r.rows[0].status });
}));

// attach photo / voice note after the SOS was created (so the alert itself is never delayed)
app.patch('/sos/:id/files', auth, wrap(async (req, res) => {
  if (!UUID.test(req.params.id)) return bad(res, 'not found', 404);
  const r = await q(
    `UPDATE sos SET photo_file=COALESCE($3,photo_file), audio_file=COALESCE($4,audio_file), updated_at=now()
      WHERE id=$1 AND user_id=$2 RETURNING id`,
    [req.params.id, req.uid, uuidOrNull(req.body?.photo_file), uuidOrNull(req.body?.audio_file)],
  );
  if (!r.rowCount) return bad(res, 'not found', 404);
  res.json({ ok: true });
}));

// Active alerts around a responder (the app polls this every ~5 s while the responder is ONLINE)
app.get('/sos/nearby', auth, wrap(async (req, res) => {
  const lat = Number(req.query.lat);
  const lng = Number(req.query.lng);
  const has = Number.isFinite(lat) && Number.isFinite(lng) && !(lat === 0 && lng === 0);
  const radius = Math.min(Math.max(Number(req.query.radius_km) || 50, 1), 500);
  if (has) {
    await q('UPDATE users SET online=true, last_lat=$2, last_lng=$3, last_seen=now() WHERE id=$1', [req.uid, lat, lng]);
  }
  const r = await q(
    `SELECT * FROM (
       SELECT s.*,
              CASE WHEN $2::float8 IS NULL OR s.lat = 0 THEN NULL
                   ELSE 6371 * acos(LEAST(1, GREATEST(-1,
                        cos(radians($1::float8)) * cos(radians(s.lat)) * cos(radians(s.lng) - radians($2::float8)) +
                        sin(radians($1::float8)) * sin(radians(s.lat))))) END AS km
         FROM sos s
        WHERE s.user_id <> $3
          AND s.created_at > now() - interval '3 hours'
          AND (s.status = 'active' OR s.updated_at > now() - interval '10 minutes')
     ) t
     WHERE km IS NULL OR km <= $4
     ORDER BY created_at DESC LIMIT 20`,
    [has ? lat : null, has ? lng : null, req.uid, radius],
  );
  res.json({ items: r.rows.map((x) => sosJson(x, req.uid)) });
}));

app.get('/sos/:id', auth, wrap(async (req, res) => {
  if (!UUID.test(req.params.id)) return bad(res, 'not found', 404);
  const r = await q('SELECT * FROM sos WHERE id=$1', [req.params.id]);
  if (!r.rowCount) return bad(res, 'not found', 404);
  res.json(sosJson(r.rows[0], req.uid));
}));

// responder progress: 1 assigned · 2 on the way · 3 arrived · 4 assistance provided
app.patch('/sos/:id/stage', auth, wrap(async (req, res) => {
  if (!UUID.test(req.params.id)) return bad(res, 'not found', 404);
  const stage = Number(req.body?.stage);
  if (!Number.isInteger(stage) || stage < 1 || stage > 4) return bad(res, 'invalid stage');
  const u = await q('SELECT name, role FROM users WHERE id=$1', [req.uid]);
  if (!u.rowCount || u.rows[0].role === 'seeker') return bad(res, 'only responders can update a rescue', 403);
  const cur = await q('SELECT user_id, stage, status, responder_id, responder_name FROM sos WHERE id=$1', [req.params.id]);
  if (!cur.rowCount) return bad(res, 'not found', 404);
  const s = cur.rows[0];
  if (s.user_id === req.uid) return bad(res, 'cannot respond to your own SOS', 403);
  if (s.status === 'cancelled') return bad(res, 'sos was cancelled', 409);
  if (s.responder_id && s.responder_id !== req.uid) {
    return res.status(409).json({ error: 'already_assigned', responder_name: s.responder_name });
  }
  const status = stage >= 4 ? 'resolved' : 'active';
  await q(
    `UPDATE sos SET stage=GREATEST(stage,$2), status=$3, responder_id=$4, responder_name=$5, updated_at=now() WHERE id=$1`,
    [req.params.id, stage, status, req.uid, u.rows[0].name],
  );
  await q('INSERT INTO sos_events (sos_id, actor_id, stage) VALUES ($1,$2,$3)', [req.params.id, req.uid, stage]).catch(() => {});
  res.json({ ok: true, stage, responder_name: u.rows[0].name });
}));

app.post('/sos/:id/cancel', auth, wrap(async (req, res) => {
  if (!UUID.test(req.params.id)) return bad(res, 'not found', 404);
  const r = await q(
    `UPDATE sos SET status='cancelled', updated_at=now() WHERE id=$1 AND user_id=$2 AND status='active' RETURNING id`,
    [req.params.id, req.uid],
  );
  if (r.rowCount) {
    await q('INSERT INTO sos_events (sos_id, actor_id, stage, note) VALUES ($1,$2,0,$3)', [req.params.id, req.uid, 'cancelled – user is safe']).catch(() => {});
  }
  res.json({ ok: true });
}));

// ───────────────────────── appreciation ─────────────────────────
app.post('/appreciations', auth, wrap(async (req, res) => {
  const b = req.body || {};
  const sosId = uuidOrNull(b.sos_id);
  const badge = str(b.badge_key, 40);
  const rating = Math.round(num(b.rating, 0));
  if (!sosId) return bad(res, 'invalid sos');
  if (!BADGES.has(badge)) return bad(res, 'invalid badge');
  if (rating < 0 || rating > 5) return bad(res, 'invalid rating');
  const s = await q('SELECT responder_id FROM sos WHERE id=$1 AND user_id=$2', [sosId, req.uid]);
  if (!s.rowCount) return bad(res, 'sos not found', 404);
  if (!s.rows[0].responder_id) return bad(res, 'no_responder', 409);
  await q(
    `INSERT INTO appreciations (sos_id, from_user, to_user, badge_key, message, feedback, rating)
     VALUES ($1,$2,$3,$4,$5,$6,$7) ON CONFLICT (sos_id, from_user) DO NOTHING`,
    [sosId, req.uid, s.rows[0].responder_id, badge, str(b.message, 300), str(b.feedback, 300), rating],
  );
  res.json({ ok: true });
}));

// responder phone collects new appreciation (each item is delivered exactly once)
app.get('/me/appreciations', auth, wrap(async (req, res) => {
  const r = await q(
    `UPDATE appreciations a SET delivered=true FROM users u
      WHERE a.to_user=$1 AND a.delivered=false AND u.id=a.from_user
  RETURNING a.id, a.sos_id, a.badge_key, a.message, a.feedback, a.rating, a.created_at, u.name AS from_name`,
    [req.uid],
  );
  res.json({ items: r.rows });
}));

// ───────────────────────── housekeeping ─────────────────────────
setInterval(() => {
  q(`UPDATE sos SET status='expired', updated_at=now() WHERE status='active' AND created_at < now() - interval '6 hours'`).catch(() => {});
}, 10 * 60_000).unref();

app.use((_req, res) => bad(res, 'not found', 404));
// eslint-disable-next-line no-unused-vars
app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({ error: 'server error' });
});

// 0.0.0.0 is required on Render so the platform's port scanner can reach the server.
app.listen(PORT, '0.0.0.0', () => console.log(`ResQMitra API listening on :${PORT}`));
