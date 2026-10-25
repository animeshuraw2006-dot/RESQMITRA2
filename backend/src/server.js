import 'dotenv/config';
import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import jwt from 'jsonwebtoken';
import crypto from 'node:crypto';
import pg from 'pg';
import { z } from 'zod';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

const { Pool } = pg;
if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is required');
if (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 32) throw new Error('JWT_SECRET must be at least 32 characters');
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: true }, max: 10 });
const app = express();
app.disable('x-powered-by'); app.use(helmet()); app.use(cors({ origin: process.env.CORS_ORIGIN === '*' ? true : (process.env.CORS_ORIGIN || '').split(',') }));
app.use(express.json({ limit: '256kb' })); app.use(rateLimit({ windowMs: 60_000, limit: 120, standardHeaders: 'draft-7', legacyHeaders: false }));
const s3 = process.env.S3_ENDPOINT ? new S3Client({ endpoint: process.env.S3_ENDPOINT, region: process.env.S3_REGION || 'auto', forcePathStyle: true, credentials: { accessKeyId: process.env.S3_ACCESS_KEY_ID || '', secretAccessKey: process.env.S3_SECRET_ACCESS_KEY || '' } }) : null;
function auth(req,res,next) {
  const raw = req.headers.authorization || ''; const token = raw.startsWith('Bearer ') ? raw.slice(7) : '';
  if (!token) return res.status(401).json({ error: 'Bearer token required' });
  try { const claims = jwt.verify(token, process.env.JWT_SECRET, { algorithms: ['HS256'], issuer: 'resqmitra-api' }); if (!claims.sub) throw new Error('missing sub'); req.subject = String(claims.sub); next(); }
  catch { return res.status(401).json({ error: 'Invalid or expired access token' }); }
}
const asyncRoute = fn => (req,res,next) => Promise.resolve(fn(req,res,next)).catch(next);
app.get('/health', asyncRoute(async (_req,res) => { await pool.query('SELECT 1'); res.json({ ok: true, service: 'resqmitra-api' }); }));
// Tokens must be issued by a trusted auth service/backend. Never let the mobile client mint its own JWT.
app.get('/profile/me', auth, asyncRoute(async (req,res) => {
 const r = await pool.query('SELECT id,role,full_name,phone,email,profile_photo_key,created_at FROM profiles WHERE auth_subject=$1', [req.subject]);
 if (!r.rowCount) return res.status(404).json({ error: 'Profile not found' }); res.json(r.rows[0]);
}));
const sosSchema = z.object({ category:z.string().min(1).max(80), emergency_type:z.string().min(1).max(80), description:z.string().max(4000).optional().default(''), latitude:z.number().min(-90).max(90), longitude:z.number().min(-180).max(180), address:z.string().max(500).optional().default(''), high_alert:z.boolean().optional().default(false), do_not_call:z.boolean().optional().default(false), tags:z.array(z.string().max(60)).max(30).optional().default([]), extra_details:z.record(z.string(),z.unknown()).optional().default({}) });
app.post('/sos', auth, asyncRoute(async (req,res) => {
 const parsed=sosSchema.safeParse(req.body); if(!parsed.success) return res.status(400).json({error:'Invalid SOS payload',details:parsed.error.issues});
 const client=await pool.connect(); try { await client.query('BEGIN');
 const p=await client.query("SELECT id,role FROM profiles WHERE auth_subject=$1 FOR SHARE",[req.subject]);
 if(!p.rowCount) { await client.query('ROLLBACK'); return res.status(403).json({error:'Create a profile before sending SOS'}); }
 const d=parsed.data; const r=await client.query(`INSERT INTO sos_alerts (seeker_id,category,emergency_type,description,latitude,longitude,address,high_alert,do_not_call,tags,extra_details) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) RETURNING *`,[p.rows[0].id,d.category,d.emergency_type,d.description,d.latitude,d.longitude,d.address,d.high_alert,d.do_not_call,d.tags,d.extra_details]);
 await client.query("INSERT INTO sos_status_history(sos_id,changed_by,new_status) VALUES($1,$2,'open')",[r.rows[0].id,p.rows[0].id]); await client.query('COMMIT'); res.status(201).json(r.rows[0]);
 } catch(e){await client.query('ROLLBACK');throw e;} finally{client.release();}
}));
app.get('/sos/mine', auth, asyncRoute(async(req,res)=>{ const r=await pool.query(`SELECT s.* FROM sos_alerts s JOIN profiles p ON p.id=s.seeker_id WHERE p.auth_subject=$1 ORDER BY s.created_at DESC LIMIT 100`,[req.subject]); res.json({items:r.rows}); }));
app.post('/sos/:id/cancel', auth, asyncRoute(async(req,res)=>{ const c=await pool.connect(); try {await c.query('BEGIN'); const r=await c.query(`UPDATE sos_alerts s SET status='cancelled',updated_at=now() FROM profiles p WHERE s.id=$1 AND s.seeker_id=p.id AND p.auth_subject=$2 AND s.status IN ('open','assigned') RETURNING s.*`,[req.params.id,req.subject]); if(!r.rowCount){await c.query('ROLLBACK');return res.status(404).json({error:'SOS not found or cannot be cancelled'});} await c.query("INSERT INTO sos_status_history(sos_id,changed_by,old_status,new_status) SELECT $1,p.id,'open','cancelled' FROM profiles p WHERE p.auth_subject=$2",[req.params.id,req.subject]); await c.query('COMMIT');res.json(r.rows[0]);}catch(e){await c.query('ROLLBACK');throw e;}finally{c.release();} }));
app.post('/sos/:id/accept', auth, asyncRoute(async(req,res)=>{ const c=await pool.connect(); try {await c.query('BEGIN'); const p=await c.query(`SELECT p.id FROM profiles p JOIN responder_profiles r ON r.user_id=p.id WHERE p.auth_subject=$1 AND r.verified=true AND r.available=true FOR UPDATE OF r`,[req.subject]); if(!p.rowCount){await c.query('ROLLBACK');return res.status(403).json({error:'Verified, available responder required'});} const responder=p.rows[0].id; const s=await c.query("UPDATE sos_alerts SET status='assigned',updated_at=now() WHERE id=$1 AND status='open' RETURNING *",[req.params.id]); if(!s.rowCount){await c.query('ROLLBACK');return res.status(409).json({error:'SOS is no longer open'});} await c.query("INSERT INTO sos_responses(sos_id,responder_id,status) VALUES($1,$2,'accepted')",[req.params.id,responder]); await c.query("INSERT INTO sos_status_history(sos_id,changed_by,old_status,new_status) VALUES($1,$2,'open','assigned')",[req.params.id,responder]); await c.query('COMMIT');res.json(s.rows[0]);}catch(e){await c.query('ROLLBACK'); if(e.code==='23505') return res.status(409).json({error:'Already accepted'}); throw e;}finally{c.release();} }));
const uploadSchema=z.object({file_name:z.string().min(1).max(150).regex(/^[a-zA-Z0-9._-]+$/),content_type:z.enum(['image/jpeg','image/png','audio/m4a','audio/mp4','audio/aac','video/mp4','application/pdf']),sos_id:z.string().uuid().optional(),purpose:z.enum(['profile_photo','identity_document','sos_evidence'])});
app.post('/uploads/presign', auth, asyncRoute(async(req,res)=>{ if(!s3 || !process.env.S3_BUCKET) return res.status(503).json({error:'Object storage is not configured'}); const parsed=uploadSchema.safeParse(req.body); if(!parsed.success)return res.status(400).json({error:'Invalid upload request'}); const d=parsed.data; const p=await pool.query('SELECT id FROM profiles WHERE auth_subject=$1',[req.subject]); if(!p.rowCount)return res.status(403).json({error:'Profile required'}); if(d.purpose==='sos_evidence' && d.sos_id){const own=await pool.query('SELECT 1 FROM sos_alerts WHERE id=$1 AND seeker_id=$2',[d.sos_id,p.rows[0].id]);if(!own.rowCount)return res.status(403).json({error:'SOS access denied'});} const prefix=d.purpose==='profile_photo'?'profiles':d.purpose==='identity_document'?'identity-documents':'sos-evidence'; const key=`${prefix}/${p.rows[0].id}/${crypto.randomUUID()}-${d.file_name}`; const url=await getSignedUrl(s3,new PutObjectCommand({Bucket:process.env.S3_BUCKET,Key:key,ContentType:d.content_type}),{expiresIn:300}); res.json({upload_url:url,object_key:key,expires_in:300}); }));
app.use((err,_req,res,_next)=>{ console.error('API error:',err.message); res.status(500).json({error:'Internal server error'}); });
const port=Number(process.env.PORT||8080); app.listen(port,()=>console.log(`ResQMitra API listening on ${port}`));
