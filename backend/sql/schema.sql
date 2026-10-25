CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS profiles (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 auth_subject TEXT UNIQUE NOT NULL,
 role TEXT NOT NULL DEFAULT 'seeker' CHECK (role IN ('seeker','rescuer','both')),
 full_name TEXT NOT NULL,
 phone TEXT UNIQUE,
 email TEXT UNIQUE,
 date_of_birth DATE,
 address JSONB NOT NULL DEFAULT '{}'::jsonb,
 latitude DOUBLE PRECISION CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),
 longitude DOUBLE PRECISION CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180),
 blood_group TEXT,
 medical_info JSONB NOT NULL DEFAULT '{}'::jsonb,
 profile_photo_key TEXT,
 phone_verified BOOLEAN NOT NULL DEFAULT FALSE,
 email_verified BOOLEAN NOT NULL DEFAULT FALSE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS emergency_contacts (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(), user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
 contact_name TEXT NOT NULL, phone TEXT NOT NULL, relation TEXT,
 preferred_method TEXT NOT NULL DEFAULT 'Both', created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS responder_profiles (
 user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
 skills TEXT[] NOT NULL DEFAULT '{}', qualifications JSONB NOT NULL DEFAULT '[]'::jsonb,
 resources JSONB NOT NULL DEFAULT '[]'::jsonb,
 service_radius_km INTEGER NOT NULL DEFAULT 10 CHECK (service_radius_km BETWEEN 1 AND 500),
 verified BOOLEAN NOT NULL DEFAULT FALSE, available BOOLEAN NOT NULL DEFAULT FALSE,
 identity_document_key TEXT, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS sos_alerts (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(), seeker_id UUID NOT NULL REFERENCES profiles(id),
 category TEXT NOT NULL, emergency_type TEXT NOT NULL, description TEXT NOT NULL DEFAULT '',
 latitude DOUBLE PRECISION NOT NULL CHECK (latitude BETWEEN -90 AND 90),
 longitude DOUBLE PRECISION NOT NULL CHECK (longitude BETWEEN -180 AND 180), address TEXT NOT NULL DEFAULT '',
 high_alert BOOLEAN NOT NULL DEFAULT FALSE, do_not_call BOOLEAN NOT NULL DEFAULT FALSE,
 tags TEXT[] NOT NULL DEFAULT '{}', extra_details JSONB NOT NULL DEFAULT '{}'::jsonb,
 photo_object_key TEXT, audio_object_key TEXT,
 status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','assigned','on_the_way','arrived','resolved','cancelled')),
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), resolved_at TIMESTAMPTZ
);
CREATE TABLE IF NOT EXISTS sos_responses (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(), sos_id UUID NOT NULL REFERENCES sos_alerts(id),
 responder_id UUID NOT NULL REFERENCES profiles(id),
 status TEXT NOT NULL DEFAULT 'accepted' CHECK (status IN ('accepted','on_the_way','arrived','completed','declined','withdrawn')),
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), UNIQUE (sos_id,responder_id)
);
CREATE TABLE IF NOT EXISTS badge_catalog (
 badge_key TEXT PRIMARY KEY, badge_name TEXT NOT NULL, description TEXT NOT NULL,
 image_object_key TEXT, active BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE IF NOT EXISTS badge_awards (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(), sos_id UUID NOT NULL REFERENCES sos_alerts(id),
 from_user_id UUID NOT NULL REFERENCES profiles(id), to_responder_id UUID NOT NULL REFERENCES profiles(id),
 badge_key TEXT NOT NULL REFERENCES badge_catalog(badge_key), message TEXT NOT NULL DEFAULT '', created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 CHECK (from_user_id <> to_responder_id)
);
CREATE TABLE IF NOT EXISTS reviews (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(), sos_id UUID NOT NULL REFERENCES sos_alerts(id),
 from_user_id UUID NOT NULL REFERENCES profiles(id), to_responder_id UUID NOT NULL REFERENCES profiles(id),
 rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5), feedback TEXT NOT NULL DEFAULT '', created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 UNIQUE (sos_id,from_user_id,to_responder_id), CHECK (from_user_id <> to_responder_id)
);
CREATE TABLE IF NOT EXISTS sos_status_history (
 id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, sos_id UUID NOT NULL REFERENCES sos_alerts(id),
 changed_by UUID REFERENCES profiles(id), old_status TEXT, new_status TEXT NOT NULL, changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_sos_open_created ON sos_alerts(status,created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sos_seeker ON sos_alerts(seeker_id,created_at DESC);
CREATE INDEX IF NOT EXISTS idx_responder_available ON responder_profiles(available,verified);
CREATE INDEX IF NOT EXISTS idx_responses_responder ON sos_responses(responder_id,created_at DESC);
CREATE INDEX IF NOT EXISTS idx_awards_responder ON badge_awards(to_responder_id,created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reviews_responder ON reviews(to_responder_id,created_at DESC);
CREATE INDEX IF NOT EXISTS idx_contacts_user ON emergency_contacts(user_id);
