-- Admin-only maintenance RPCs for the local experiment admin page.
-- Run this in the Supabase SQL editor before using the reset buttons.

create or replace function public.admin_truncate_task_progress()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  truncate table public.task_progress;
  return jsonb_build_object('status', 'success', 'table', 'task_progress');
end;
$$;

create or replace function public.admin_truncate_experiment_events()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  truncate table public.experiment_events;
  return jsonb_build_object('status', 'success', 'table', 'experiment_events');
end;
$$;

revoke all on function public.admin_truncate_task_progress() from public, anon, authenticated;
revoke all on function public.admin_truncate_experiment_events() from public, anon, authenticated;

grant execute on function public.admin_truncate_task_progress() to service_role;
grant execute on function public.admin_truncate_experiment_events() to service_role;
