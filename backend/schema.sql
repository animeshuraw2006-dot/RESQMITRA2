CREATE TABLE IF NOT EXISTS users (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  role        text NOT NULL CHECK (role IN ('seeker','rescuer','both')),
  name        text NOT NULL,
  mobile      text,
  email       text,
  blood_group text,
  profile     jsonb NOT NULL DEFAULT '{}'::jsonb,
  photo_file  uuid,
  doc_file    uuid,
  online      boolean NOT NULL DEFAULT false,
  last_lat    double precision,
  last_lng    double precision,
  last_seen   timestamptz,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS users_mobile_idx ON users (mobile);
CREATE TABLE IF NOT EXISTS contacts (
  id        bigserial PRIMARY KEY,
  user_id   uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  position  int  NOT NULL DEFAULT 0,
  name      text NOT NULL DEFAULT '',
  phone     text NOT NULL,
  relation  text,
  method    text DEFAULT 'Both'
);
CREATE INDEX IF NOT EXISTS contacts_user_idx ON contacts (user_id);
CREATE TABLE IF NOT EXISTS files (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id   uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  kind       text NOT NULL CHECK (kind IN ('photo','id_doc','sos_photo','sos_audio')),
  mime       text NOT NULL,
  size       int  NOT NULL,
  data       bytea NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS files_owner_idx ON files (owner_id);
CREATE TABLE IF NOT EXISTS sos (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_ref     text NOT NULL,
  user_id        uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category       text NOT NULL,
  type           text NOT NULL,
  name           text NOT NULL,
  phone          text NOT NULL DEFAULT '',
  lat            double precision NOT NULL DEFAULT 0,
  lng            double precision NOT NULL DEFAULT 0,
  address        text NOT NULL DEFAULT '',
  description    text NOT NULL DEFAULT '',
  tags           text[] NOT NULL DEFAULT '{}',
  details        jsonb NOT NULL DEFAULT '{}'::jsonb,
  high_alert     boolean NOT NULL DEFAULT false,
  do_not_call    boolean NOT NULL DEFAULT false,
  photo_file     uuid,
  audio_file     uuid,
  stage          int  NOT NULL DEFAULT 0 CHECK (stage BETWEEN 0 AND 4),
  status         text NOT NULL DEFAULT 'active' CHECK (status IN ('active','cancelled','resolved','expired')),
  responder_id   uuid REFERENCES users(id) ON DELETE SET NULL,
  responder_name text,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, client_ref)
);
CREATE INDEX IF NOT EXISTS sos_status_idx    ON sos (status, created_at DESC);
CREATE INDEX IF NOT EXISTS sos_responder_idx ON sos (responder_id);
CREATE TABLE IF NOT EXISTS sos_events (
  id         bigserial PRIMARY KEY,
  sos_id     uuid NOT NULL REFERENCES sos(id) ON DELETE CASCADE,
  actor_id   uuid REFERENCES users(id) ON DELETE SET NULL,
  stage      int  NOT NULL,
  note       text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS sos_events_sos_idx ON sos_events (sos_id);
CREATE TABLE IF NOT EXISTS appreciations (
  id         bigserial PRIMARY KEY,
  sos_id     uuid NOT NULL REFERENCES sos(id) ON DELETE CASCADE,
  from_user  uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  to_user    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  badge_key  text NOT NULL DEFAULT '',
  message    text NOT NULL DEFAULT '',
  feedback   text NOT NULL DEFAULT '',
  rating     int  NOT NULL DEFAULT 0 CHECK (rating BETWEEN 0 AND 5),
  delivered  boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (sos_id, from_user)
);
CREATE INDEX IF NOT EXISTS appr_to_idx ON appreciations (to_user, delivered);
