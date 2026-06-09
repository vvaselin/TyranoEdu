-- Anonymous registration flow that assigns experiment role only after registration is complete.
-- Run this in the Supabase SQL editor.

alter table public.profiles alter column role drop not null;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, name)
  values (new.id, '')
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

drop function if exists public.check_participant_id_available(text);

create or replace function public.check_participant_id_available(
  input_participant_id text
)
returns table (
  valid boolean,
  available boolean,
  participant_id text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  normalized_participant_id text;
begin
  normalized_participant_id := upper(btrim(coalesce(input_participant_id, '')));

  if normalized_participant_id !~ '^(?:[0-9]{2}[A-Z]{2}[0-9]{3}[A-Z]|[0-9]{2}[A-Z][0-9]{4}[A-Z])$' then
    return query select false, false, normalized_participant_id;
    return;
  end if;

  return query
    select
      true,
      not exists (
        select 1
          from public.profiles
         where profiles.participant_id = normalized_participant_id
      ),
      normalized_participant_id;
end;
$$;

drop function if exists public.complete_anonymous_registration(text, text);

create or replace function public.complete_anonymous_registration(
  display_name text,
  input_participant_id text
)
returns table (
  participant_id text,
  role text,
  name text
)
language plpgsql
security definer
set search_path = public
as $complete_anonymous_registration$
declare
  current_uid uuid;
  normalized_name text;
  normalized_participant_id text;
  existing_profile public.profiles%rowtype;
  completed_user_count integer;
  assigned_role text;
begin
  current_uid := auth.uid();
  if current_uid is null then
    raise exception 'auth.uid() is required';
  end if;

  normalized_name := btrim(coalesce(display_name, ''));
  normalized_participant_id := upper(btrim(coalesce(input_participant_id, '')));

  if char_length(normalized_name) < 2 or char_length(normalized_name) > 10 or normalized_name ~ '[[:space:]]' then
    raise exception 'display_name must be 2 to 10 non-space characters';
  end if;

  if normalized_participant_id !~ '^(?:[0-9]{2}[A-Z]{2}[0-9]{3}[A-Z]|[0-9]{2}[A-Z][0-9]{4}[A-Z])$' then
    raise exception 'participant_id format is invalid';
  end if;

  perform pg_advisory_xact_lock(2026060901);

  select p.*
    into existing_profile
    from public.profiles p
   where p.id = current_uid
   for update;

  if not found then
    insert into public.profiles (id, name)
    values (current_uid, '')
    returning * into existing_profile;
  end if;

  if existing_profile.participant_id is not null
     and existing_profile.participant_id <> normalized_participant_id then
    raise exception 'this anonymous user is already registered';
  end if;

  if exists (
    select 1
      from public.profiles p
     where p.participant_id = normalized_participant_id
       and p.id <> current_uid
  ) then
    raise exception 'participant_id is already registered';
  end if;

  if existing_profile.participant_id = normalized_participant_id
     and existing_profile.role in ('experimental', 'control') then
    update public.profiles p
       set name = normalized_name,
           participant_id = normalized_participant_id
     where p.id = current_uid;

    return query
      select p.participant_id, p.role, p.name
        from public.profiles p
       where p.id = current_uid;
    return;
  end if;

  select count(*)
    into completed_user_count
    from public.profiles p
   where p.participant_id is not null
     and p.role in ('experimental', 'control');

  assigned_role := case
    when completed_user_count % 2 = 0 then 'experimental'
    else 'control'
  end;

  update public.profiles p
     set name = normalized_name,
         participant_id = normalized_participant_id,
         role = assigned_role
   where p.id = current_uid;

  return query
    select p.participant_id, p.role, p.name
      from public.profiles p
     where p.id = current_uid;
end;
$complete_anonymous_registration$;

revoke all on function public.check_participant_id_available(text) from public;
grant execute on function public.check_participant_id_available(text) to anon, authenticated;

revoke all on function public.complete_anonymous_registration(text, text) from public, anon;
grant execute on function public.complete_anonymous_registration(text, text) to authenticated;

-- Existing incomplete rows should not affect future assignment counts.
update public.profiles
   set role = null
 where participant_id is null;
