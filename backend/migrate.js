// Usage:  npm run migrate      (reads DATABASE_URL from .env or the environment)
import 'dotenv/config';
import fs from 'node:fs';
import pg from 'pg';

const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
await client.connect();
await client.query(fs.readFileSync(new URL('./schema.sql', import.meta.url), 'utf8'));
await client.end();
console.log('✔ schema applied');
