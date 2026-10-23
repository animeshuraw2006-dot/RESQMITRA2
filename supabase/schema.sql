-- Apply this SQL in Supabase SQL Editor before running the app.
-- Anonymous Auth must be enabled in Authentication > Sign In / Providers.

create extension if not exists pgcrypto;

create table if not exists public.incidents (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references auth.users(id) on delete cascade,
  status text not null default 'open' check (status in ('open','accepted','en_route','arrived','completed','cancelled')),
  risk text not null default 'standard' check (risk in ('standard','high')),
  category text not null default 'Other',
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  accepted_by uuid references auth.users(id) on delete set null,
  accepted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists incidents_status_created_at_idx
  on public.incidents (status, created_at desc);

alter table public.incidents enable row level security;

-- Any signed-in app user can see open incidents and their own incidents.
drop policy if exists "read open or own incidents" on public.incidents;
create policy "read open or own incidents" on public.incidents
  for select to authenticated
  using (status = 'open' or created_by = (select auth.uid())
         or accepted_by = (select auth.uid()));

drop policy if exists "create own incidents" on public.incidents;
create policy "create own incidents" on public.incidents
  for insert to authenticated
  with check (created_by = (select auth.uid()) and accepted_by is null and status = 'open');

-- Clients cannot directly update rows. Status transitions go through the
-- narrowly scoped RPCs below, which enforce actor and current-status checks.

create or replace function public.accept_incident(p_incident_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  changed_count integer;
begin
  if (select auth.uid()) is null then return false; end if;
  update public.incidents
     set status = 'accepted',
         accepted_by = (select auth.uid()),
         accepted_at = now(),
         updated_at = now()
   where id = p_incident_id
     and status = 'open'
     and accepted_by is null;
  get diagnostics changed_count = row_count;
  return changed_count = 1;
end;
$$;

create or replace function public.update_incident_status(
  p_incident_id uuid, p_status text
) returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  changed_count integer;
begin
  if (select auth.uid()) is null then return false; end if;
  if p_status = 'cancelled' then
    update public.incidents
       set status = 'cancelled', updated_at = now()
     where id = p_incident_id
       and created_by = (select auth.uid())
       and status = 'open';
  elsif p_status in ('en_route', 'arrived', 'completed') then
    update public.incidents
       set status = p_status, updated_at = now()
     where id = p_incident_id
       and accepted_by = (select auth.uid())
       and status in ('accepted', 'en_route', 'arrived')
       and (p_status <> 'en_route' or status = 'accepted')
       and (p_status <> 'arrived' or status in ('accepted', 'en_route'))
       and (p_status <> 'completed' or status = 'arrived');
  else
    return false;
  end if;
  get diagnostics changed_count = row_count;
  return changed_count = 1;
end;
$$;

revoke all on function public.accept_incident(uuid) from public;
revoke all on function public.update_incident_status(uuid, text) from public;
grant execute on function public.accept_incident(uuid) to authenticated;
grant execute on function public.update_incident_status(uuid, text) to authenticated;

-- Enable realtime for incident stream updates. If this reports an existing
-- publication membership, that is fine; ensure incidents is in supabase_realtime.
alter publication supabase_realtime add table public.incidents;
