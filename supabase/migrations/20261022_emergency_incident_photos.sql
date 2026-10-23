-- RESQ-MITRA incident photo storage. Review existing RLS policies before production.
insert into storage.buckets (id, name, public)
values ('emergency-photos', 'emergency-photos', false)
on conflict (id) do nothing;

create table if not exists public.emergency_incident_photos (
  id uuid primary key default gen_random_uuid(),
  emergency_id uuid not null references public.emergency_requests(id) on delete cascade,
  requester_id uuid not null references auth.users(id) on delete cascade,
  storage_path text not null unique,
  mime_type text not null default 'image/jpeg',
  created_at timestamptz not null default now()
);

alter table public.emergency_incident_photos enable row level security;
drop policy if exists "requesters insert own incident photos" on public.emergency_incident_photos;
create policy "requesters insert own incident photos"
on public.emergency_incident_photos for insert to authenticated
with check (requester_id = auth.uid());
drop policy if exists "requesters read own incident photos" on public.emergency_incident_photos;
create policy "requesters read own incident photos"
on public.emergency_incident_photos for select to authenticated
using (requester_id = auth.uid());

drop policy if exists "users upload own emergency photos" on storage.objects;
create policy "users upload own emergency photos"
on storage.objects for insert to authenticated
with check (bucket_id = 'emergency-photos' and (storage.foldername(name))[2] = auth.uid()::text);

drop policy if exists "users read own emergency photos" on storage.objects;
create policy "users read own emergency photos"
on storage.objects for select to authenticated
using (bucket_id = 'emergency-photos' and (storage.foldername(name))[2] = auth.uid()::text);
