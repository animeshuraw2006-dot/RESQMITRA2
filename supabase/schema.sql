-- Run in Supabase SQL Editor. Review policies with your deployment/security team.
create extension if not exists pgcrypto;

do $$ begin
  create type public.app_role as enum ('citizen','responder','admin');
exception when duplicate_object then null; end $$;
do $$ begin
  create type public.emergency_status as enum ('pending','assigned','accepted','responding','arrived','resolved','cancelled','expired');
exception when duplicate_object then null; end $$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  phone text,
  role public.app_role not null default 'responder',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.responder_profiles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  verified boolean not null default true,
  available boolean not null default true,
  organization text default 'Community Responder',
  verified_at timestamptz default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.emergency_requests (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references auth.users(id),
  client_request_id text not null,
  category text not null check (category in ('general','women','child')),
  emergency_type text not null,
  priority text not null check (priority in ('normal','high_alert')),
  instructions text not null default '',
  do_not_call boolean not null default false,
  blood_group text,
  audio_requested boolean not null default false,
  latitude double precision,
  longitude double precision,
  accuracy_meters double precision,
  status public.emergency_status not null default 'pending',
  accepted_responder_id uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '2 hours',
  unique(requester_id, client_request_id),
  check ((latitude is null and longitude is null) or
         (latitude between -90 and 90 and longitude between -180 and 180))
);
create table if not exists public.responder_assignments (
  id uuid primary key default gen_random_uuid(),
  emergency_id uuid not null references public.emergency_requests(id) on delete cascade,
  responder_id uuid not null references auth.users(id),
  status text not null default 'assigned' check (status in ('assigned','accepted','declined','responding','arrived','resolved','cancelled')),
  category text not null,
  emergency_type text not null,
  priority text not null,
  instructions text not null default '',
  latitude double precision,
  longitude double precision,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(emergency_id, responder_id)
);
create table if not exists public.responder_locations (
  responder_id uuid primary key references auth.users(id) on delete cascade,
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  accuracy_m double precision,
  updated_at timestamptz not null default now()
);

create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  fcm_token text not null unique,
  platform text not null default 'android',
  updated_at timestamptz not null default now()
);

-- Trigger: auto-register EVERY user as Citizen AND Responder
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles(id, display_name, phone, role)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name',''), new.phone, 'responder')
  on conflict (id) do update set role = 'responder';

  insert into public.responder_profiles(user_id, verified, available, organization)
  values (new.id, true, true, 'Community Responder')
  on conflict (user_id) do update set verified = true, available = true;

  return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Upgrade existing accounts
insert into public.responder_profiles(user_id, verified, available, organization)
select id, true, true, 'Community Responder'
from auth.users
on conflict (user_id) do update set verified = true, available = true;

alter table public.profiles enable row level security;
alter table public.responder_profiles enable row level security;
alter table public.emergency_requests enable row level security;
alter table public.responder_assignments enable row level security;
alter table public.device_tokens enable row level security;
alter table public.responder_locations enable row level security;

drop policy if exists "profile read own" on public.profiles;
create policy "profile read own" on public.profiles for select to authenticated using (true);
drop policy if exists "profile update own nonprivileged" on public.profiles;
create policy "profile update own nonprivileged" on public.profiles for update to authenticated using (id = (select auth.uid()));

drop policy if exists "responder profile visible to self" on public.responder_profiles;
create policy "responder profile visible to self" on public.responder_profiles for select to authenticated using (true);
drop policy if exists "responder profile upsert own" on public.responder_profiles;
create policy "responder profile upsert own" on public.responder_profiles for all to authenticated
using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

drop policy if exists "requester read own emergencies" on public.emergency_requests;
create policy "requester read own emergencies" on public.emergency_requests for select to authenticated using (true);

drop policy if exists "assigned responder read assignment" on public.responder_assignments;
create policy "assigned responder read assignment" on public.responder_assignments for select to authenticated using (
  responder_id = (select auth.uid())
);
drop policy if exists "responder update own assignment" on public.responder_assignments;
create policy "responder update own assignment" on public.responder_assignments for update to authenticated using (
  responder_id = (select auth.uid())
) with check (
  responder_id = (select auth.uid())
);

drop policy if exists "responder delete own assignment" on public.responder_assignments;
create policy "responder delete own assignment" on public.responder_assignments
for delete to authenticated using (responder_id = (select auth.uid()));

drop policy if exists "requester delete own emergency" on public.emergency_requests;
create policy "requester delete own emergency" on public.emergency_requests
for delete to authenticated using (requester_id = (select auth.uid()));

drop policy if exists "requester update own emergency" on public.emergency_requests;
create policy "requester update own emergency" on public.emergency_requests
for update to authenticated using (requester_id = (select auth.uid()))
with check (requester_id = (select auth.uid()));

drop policy if exists "user manage own device tokens" on public.device_tokens;
create policy "user manage own device tokens" on public.device_tokens for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

create index if not exists emergency_requests_status_created_idx on public.emergency_requests(status, created_at desc);
create index if not exists responder_assignments_responder_status_idx on public.responder_assignments(responder_id, status, created_at desc);

drop policy if exists "responder writes own location" on public.responder_locations;
create policy "responder writes own location" on public.responder_locations for all to authenticated
using (responder_id = (select auth.uid())) with check (responder_id = (select auth.uid()));

drop policy if exists "read responder location" on public.responder_locations;
create policy "read responder location" on public.responder_locations for select to authenticated using (true);

create index if not exists responder_locations_updated_idx on public.responder_locations(updated_at desc);

-- Trusted transactional dispatch: Assigns ALL available responders except the requester
create or replace function public.dispatch_emergency(
  p_requester_id uuid, p_client_request_id text, p_category text,
  p_emergency_type text, p_priority text, p_instructions text,
  p_do_not_call boolean, p_blood_group text, p_audio_requested boolean,
  p_latitude double precision, p_longitude double precision, p_accuracy_meters double precision
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_emergency public.emergency_requests%rowtype;
  v_count integer := 0;
begin
  insert into public.emergency_requests(
    requester_id, client_request_id, category, emergency_type, priority,
    instructions, do_not_call, blood_group, audio_requested, latitude, longitude,
    accuracy_meters, status
  )
  values(
    p_requester_id, p_client_request_id, p_category, p_emergency_type, p_priority,
    p_instructions, p_do_not_call, p_blood_group, p_audio_requested, p_latitude, p_longitude,
    p_accuracy_meters, 'pending'
  )
  on conflict(requester_id, client_request_id) do update set client_request_id = excluded.client_request_id
  returning * into v_emergency;

  -- Ensure any other user has a responder profile
  insert into public.responder_profiles(user_id, verified, available, organization)
  select u.id, true, true, 'Community Responder'
  from auth.users u
  where u.id <> p_requester_id
  on conflict (user_id) do nothing;

  -- Assign to ALL other users who are available
  insert into public.responder_assignments(
    emergency_id, responder_id, status, category, emergency_type, priority, instructions, latitude, longitude
  )
  select
    v_emergency.id, rp.user_id, 'assigned', v_emergency.category, v_emergency.emergency_type,
    v_emergency.priority, v_emergency.instructions, v_emergency.latitude, v_emergency.longitude
  from public.responder_profiles rp
  where rp.user_id <> p_requester_id
    and rp.available = true
  on conflict(emergency_id, responder_id) do update set status = 'assigned';

  get diagnostics v_count = row_count;
  
  if v_count > 0 then
    update public.emergency_requests set status = 'assigned', updated_at = now() where id = v_emergency.id returning * into v_emergency;
  end if;

  return jsonb_build_object('id', v_emergency.id, 'status', v_emergency.status, 'assigned_count', v_count);
end; $$;

-- Claim emergency function
create or replace function public.claim_emergency(p_emergency_id uuid, p_responder_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_emergency public.emergency_requests%rowtype;
  v_assignment public.responder_assignments%rowtype;
begin
  insert into public.responder_profiles(user_id, verified, available)
  values (p_responder_id, true, true)
  on conflict(user_id) do update set verified = true, available = true;

  update public.emergency_requests
  set status = 'accepted', accepted_responder_id = p_responder_id, updated_at = now()
  where id = p_emergency_id and status in ('assigned', 'pending') and (accepted_responder_id is null or accepted_responder_id = p_responder_id)
  returning * into v_emergency;

  if not found then
    raise exception 'Emergency already claimed or not active';
  end if;

  update public.responder_assignments
  set status = 'accepted', updated_at = now()
  where emergency_id = p_emergency_id and responder_id = p_responder_id
  returning * into v_assignment;

  if not found then
    insert into public.responder_assignments(emergency_id, responder_id, status, category, emergency_type, priority)
    values (v_emergency.id, p_responder_id, 'accepted', v_emergency.category, v_emergency.emergency_type, v_emergency.priority)
    returning * into v_assignment;
  end if;

  update public.responder_assignments
  set status = 'cancelled', updated_at = now()
  where emergency_id = p_emergency_id and responder_id <> p_responder_id and status = 'assigned';

  return jsonb_build_object('id', v_assignment.id, 'emergency_id', v_emergency.id, 'status', 'accepted');
end; $$;

-- Cancel emergency function
create or replace function public.cancel_emergency(p_emergency_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_emergency public.emergency_requests%rowtype;
begin
  update public.emergency_requests
  set status = 'cancelled', updated_at = now()
  where id = p_emergency_id and requester_id = (select auth.uid()) and status in ('pending','assigned','accepted')
  returning * into v_emergency;

  if not found then
    raise exception 'Emergency not found or cannot be cancelled';
  end if;

  update public.responder_assignments
  set status = 'cancelled', updated_at = now()
  where emergency_id = p_emergency_id and status in ('assigned','accepted');

  return jsonb_build_object('id', v_emergency.id, 'status', 'cancelled');
end; $$;

-- Resolve emergency function
drop function if exists public.resolve_emergency(uuid);
create or replace function public.resolve_emergency(p_emergency_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
begin
  update public.emergency_requests
  set status = 'resolved', updated_at = now()
  where id = p_emergency_id;

  update public.responder_assignments
  set status = 'resolved', updated_at = now()
  where emergency_id = p_emergency_id;

  return jsonb_build_object('success', true);
end; $$;

-- Clear all test emergencies function
drop function if exists public.clear_all_test_emergencies();
create or replace function public.clear_all_test_emergencies()
returns jsonb language plpgsql security definer set search_path = '' as $$
begin
  delete from public.emergency_audio_recordings;
  delete from public.responder_assignments;
  delete from public.emergency_requests;
  delete from public.responder_locations;
  return jsonb_build_object('success', true);
end; $$;

-- Grant execution to authenticated users (Direct RPC, zero failure risk)
grant execute on function public.dispatch_emergency(uuid,text,text,text,text,text,boolean,text,boolean,double precision,double precision,double precision) to authenticated;
grant execute on function public.claim_emergency(uuid,uuid) to authenticated;
grant execute on function public.cancel_emergency(uuid) to authenticated;
grant execute on function public.resolve_emergency(uuid) to authenticated, anon;
grant execute on function public.clear_all_test_emergencies() to authenticated, anon;

-- Realtime publication
do $$ begin
  alter publication supabase_realtime add table public.responder_assignments;
exception when duplicate_object then null; when undefined_object then null; end $$;

do $$ begin
  alter publication supabase_realtime add table public.responder_locations;
exception when duplicate_object then null; when undefined_object then null; end $$;

do $$ begin
  alter publication supabase_realtime add table public.emergency_requests;
exception when duplicate_object then null; when undefined_object then null; end $$;

-- Private emergency audio recordings
create table if not exists public.emergency_audio_recordings (
  id uuid primary key default gen_random_uuid(),
  emergency_id uuid not null references public.emergency_requests(id) on delete cascade,
  requester_id uuid not null references auth.users(id) on delete cascade,
  storage_path text not null unique,
  mime_type text not null default 'audio/m4a',
  duration_ms integer,
  created_at timestamptz not null default now()
);
alter table public.emergency_audio_recordings enable row level security;
drop policy if exists "read emergency audio metadata" on public.emergency_audio_recordings;
create policy "read emergency audio metadata"
on public.emergency_audio_recordings for select to authenticated using (true);

drop policy if exists "insert emergency audio metadata" on public.emergency_audio_recordings;
create policy "insert emergency audio metadata"
on public.emergency_audio_recordings for insert to authenticated with check (
  requester_id = (select auth.uid())
);

-- Notify PostgREST to reload schema cache immediately
notify pgrst, 'reload schema';
