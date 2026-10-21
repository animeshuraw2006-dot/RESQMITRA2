-- RESQ-MITRA: create a responder profile for every existing account.
-- Security: profiles are intentionally NOT verified or available by default.
insert into public.responder_profiles (user_id, verified, available)
select p.id, false, false from public.profiles p
on conflict (user_id) do nothing;

-- Update the auth trigger so all future accounts also get a responder profile.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles(id, display_name, phone, role)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name',''), new.phone, 'citizen')
  on conflict (id) do nothing;
  insert into public.responder_profiles(user_id, verified, available)
  values (new.id, false, false)
  on conflict (user_id) do nothing;
  return new;
end; $$;
