-- Phase 5A Supabase schema draft.
-- Run in the Supabase SQL Editor after creating the project.
-- This file intentionally uses user_id + RLS for every user-owned table.

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.raw_inputs (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  text text not null,
  source text not null default 'user',
  created_at timestamptz not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.ai_parse_results (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  raw_input_id text not null references public.raw_inputs(id) on delete cascade,
  raw_json jsonb not null,
  validation_state text not null,
  error_message text,
  retry_count integer not null default 0,
  created_at timestamptz not null
);

create table if not exists public.extracted_items (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  raw_input_id text not null references public.raw_inputs(id) on delete cascade,
  ai_parse_result_id text not null references public.ai_parse_results(id) on delete cascade,
  type text not null,
  title text,
  content text,
  source_text text not null,
  tags jsonb not null default '[]'::jsonb,
  confidence numeric not null,
  need_user_confirm boolean not null,
  status text not null,
  expires_at timestamptz,
  created_at timestamptz not null,
  updated_at timestamptz not null
);

create table if not exists public.tasks (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  source_raw_input_id text not null references public.raw_inputs(id) on delete restrict,
  source_extracted_item_id text not null references public.extracted_items(id) on delete restrict,
  title text not null,
  description text,
  due_time_text text,
  due_time timestamptz,
  priority text not null default 'medium',
  status text not null,
  task_status text not null default 'active',
  created_at timestamptz not null,
  updated_at timestamptz not null
);

create table if not exists public.short_term_states (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  source_raw_input_id text not null references public.raw_inputs(id) on delete restrict,
  source_extracted_item_id text not null references public.extracted_items(id) on delete restrict,
  content text not null,
  tags jsonb not null default '[]'::jsonb,
  valid_until timestamptz not null,
  status text not null,
  created_at timestamptz not null,
  updated_at timestamptz not null
);

create table if not exists public.life_events (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  source_raw_input_id text not null references public.raw_inputs(id) on delete restrict,
  source_extracted_item_id text not null references public.extracted_items(id) on delete restrict,
  content text not null,
  tags jsonb not null default '[]'::jsonb,
  status text not null,
  created_at timestamptz not null,
  updated_at timestamptz not null
);

create table if not exists public.profile_items (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  source_raw_input_id text not null references public.raw_inputs(id) on delete restrict,
  source_extracted_item_id text not null references public.extracted_items(id) on delete restrict,
  content text not null,
  category text,
  tags jsonb not null default '[]'::jsonb,
  confidence numeric not null,
  status text not null,
  created_at timestamptz not null,
  updated_at timestamptz not null
);

create table if not exists public.summaries (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  summary_type text not null,
  title text not null,
  content text not null,
  encouragement text,
  improvement_notes text,
  task_guidance text,
  open_items jsonb not null default '[]'::jsonb,
  time_range_start timestamptz,
  time_range_end timestamptz,
  status text not null,
  generated_by text not null,
  model_name text,
  prompt_version text,
  confidence numeric,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  user_edited_at timestamptz,
  deleted_at timestamptz
);

create table if not exists public.summary_sources (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  summary_id text not null references public.summaries(id) on delete cascade,
  source_table text not null,
  source_record_id text not null,
  source_status_at_generation text,
  created_at timestamptz not null default now()
);

create table if not exists public.schedule_plans (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  plan_date timestamptz not null,
  title text not null,
  overview text not null,
  suggestions jsonb not null default '[]'::jsonb,
  unscheduled_task_ids jsonb not null default '[]'::jsonb,
  status text not null,
  generated_by text not null,
  model_name text,
  prompt_version text,
  confidence numeric,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  confirmed_at timestamptz,
  user_edited_at timestamptz,
  deleted_at timestamptz
);

create table if not exists public.schedule_blocks (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  plan_id text not null references public.schedule_plans(id) on delete cascade,
  title text not null,
  block_type text not null,
  start_time timestamptz not null,
  end_time timestamptz not null,
  task_id text references public.tasks(id) on delete set null,
  note text,
  reason text not null,
  sort_order integer not null,
  status text not null,
  confidence numeric,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  constraint schedule_blocks_time_order check (start_time < end_time)
);

create table if not exists public.schedule_block_sources (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  block_id text not null references public.schedule_blocks(id) on delete cascade,
  source_table text not null,
  source_record_id text not null,
  created_at timestamptz not null default now()
);

-- The API consumes this through the narrowly scoped RPC below. There are no
-- direct client table privileges, so a user cannot reset or edit their own
-- counter through the Data API. `usage_day` is deliberately UTC based.
create table if not exists public.ai_daily_request_usage (
  user_id uuid not null references auth.users(id) on delete cascade,
  usage_day date not null,
  request_count integer not null default 0 check (request_count >= 0),
  updated_at timestamptz not null default now(),
  primary key (user_id, usage_day)
);

alter table public.ai_daily_request_usage enable row level security;

create or replace function public.consume_ai_daily_request_quota()
returns table (allowed boolean, remaining integer, reset_at timestamptz)
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  quota_limit constant integer := 30;
  current_day date := (timezone('UTC', now()))::date;
  request_total integer;
begin
  if caller_id is null then
    raise exception using
      errcode = '28000',
      message = 'A signed-in user is required to consume AI quota';
  end if;

  insert into public.ai_daily_request_usage (
    user_id, usage_day, request_count, updated_at
  ) values (
    caller_id, current_day, 1, now()
  )
  on conflict (user_id, usage_day) do update
    set request_count = public.ai_daily_request_usage.request_count + 1,
        updated_at = now()
    where public.ai_daily_request_usage.request_count < quota_limit
  returning request_count into request_total;

  if found then
    return query select
      true,
      quota_limit - request_total,
      ((current_day + 1)::timestamp at time zone 'UTC');
    return;
  end if;

  return query select
    false,
    0,
    ((current_day + 1)::timestamp at time zone 'UTC');
end;
$$;

revoke all on public.ai_daily_request_usage from anon, authenticated;
revoke all on function public.consume_ai_daily_request_quota() from public;
grant execute on function public.consume_ai_daily_request_quota() to authenticated;

-- Account deletion is intentionally self-service and accepts no user id from
-- the caller. The authenticated JWT is the only source of identity, so this
-- SECURITY DEFINER function cannot be used to delete another account.
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
begin
  if caller_id is null then
    raise exception using
      errcode = '28000',
      message = 'A signed-in user is required to delete an account';
  end if;

  delete from public.schedule_block_sources where user_id = caller_id;
  delete from public.schedule_blocks where user_id = caller_id;
  delete from public.schedule_plans where user_id = caller_id;
  delete from public.summary_sources where user_id = caller_id;
  delete from public.summaries where user_id = caller_id;
  delete from public.profile_items where user_id = caller_id;
  delete from public.life_events where user_id = caller_id;
  delete from public.short_term_states where user_id = caller_id;
  delete from public.tasks where user_id = caller_id;
  delete from public.extracted_items where user_id = caller_id;
  delete from public.ai_parse_results where user_id = caller_id;
  delete from public.raw_inputs where user_id = caller_id;
  delete from public.profiles where user_id = caller_id;
  delete from public.ai_daily_request_usage where user_id = caller_id;
  delete from auth.users where id = caller_id;
  if not found then
    raise exception using
      errcode = 'P0002',
      message = 'The signed-in account no longer exists';
  end if;
end;
$$;

revoke all on function public.delete_my_account() from public;
revoke all on function public.delete_my_account() from anon;
grant execute on function public.delete_my_account() to authenticated;

-- RLS protects direct row access, but foreign keys alone do not ensure that a
-- child row references records owned by the same auth user. These trigger
-- checks reject cross-account references before they can create an integrity or
-- deletion problem. They deliberately run as the calling role (the default
-- SECURITY INVOKER behavior), not as a privileged service function.
create or replace function public.assert_ai_parse_result_source_owned()
returns trigger
language plpgsql
security invoker
as $$
begin
  if not exists (
    select 1 from public.raw_inputs raw_input
    where raw_input.id = new.raw_input_id
      and raw_input.user_id = new.user_id
  ) then
    raise exception using
      errcode = '23514',
      message = 'ai_parse_results.raw_input_id must belong to the same user';
  end if;
  return new;
end;
$$;

create or replace function public.assert_extracted_item_sources_owned()
returns trigger
language plpgsql
security invoker
as $$
begin
  if not exists (
    select 1 from public.ai_parse_results parse_result
    where parse_result.id = new.ai_parse_result_id
      and parse_result.user_id = new.user_id
      and parse_result.raw_input_id = new.raw_input_id
  ) then
    raise exception using
      errcode = '23514',
      message = 'extracted_items sources must belong to the same user and input';
  end if;
  return new;
end;
$$;

create or replace function public.assert_memory_record_sources_owned()
returns trigger
language plpgsql
security invoker
as $$
begin
  if not exists (
    select 1 from public.extracted_items extracted_item
    where extracted_item.id = new.source_extracted_item_id
      and extracted_item.user_id = new.user_id
      and extracted_item.raw_input_id = new.source_raw_input_id
  ) then
    raise exception using
      errcode = '23514',
      message = 'memory record sources must belong to the same user and input';
  end if;
  return new;
end;
$$;

create or replace function public.assert_summary_source_owned()
returns trigger
language plpgsql
security invoker
as $$
begin
  if not exists (
    select 1 from public.summaries summary
    where summary.id = new.summary_id
      and summary.user_id = new.user_id
  ) then
    raise exception using
      errcode = '23514',
      message = 'summary_sources.summary_id must belong to the same user';
  end if;
  return new;
end;
$$;

create or replace function public.assert_schedule_block_sources_owned()
returns trigger
language plpgsql
security invoker
as $$
begin
  if not exists (
    select 1 from public.schedule_plans plan
    where plan.id = new.plan_id
      and plan.user_id = new.user_id
  ) then
    raise exception using
      errcode = '23514',
      message = 'schedule_blocks.plan_id must belong to the same user';
  end if;

  if new.task_id is not null and not exists (
    select 1 from public.tasks task
    where task.id = new.task_id
      and task.user_id = new.user_id
  ) then
    raise exception using
      errcode = '23514',
      message = 'schedule_blocks.task_id must belong to the same user';
  end if;
  return new;
end;
$$;

create or replace function public.assert_schedule_block_source_owned()
returns trigger
language plpgsql
security invoker
as $$
begin
  if not exists (
    select 1 from public.schedule_blocks block
    where block.id = new.block_id
      and block.user_id = new.user_id
  ) then
    raise exception using
      errcode = '23514',
      message = 'schedule_block_sources.block_id must belong to the same user';
  end if;
  return new;
end;
$$;

create trigger ai_parse_results_require_owned_source
before insert or update of user_id, raw_input_id on public.ai_parse_results
for each row execute function public.assert_ai_parse_result_source_owned();

create trigger extracted_items_require_owned_sources
before insert or update of user_id, raw_input_id, ai_parse_result_id
on public.extracted_items
for each row execute function public.assert_extracted_item_sources_owned();

create trigger tasks_require_owned_sources
before insert or update of user_id, source_raw_input_id, source_extracted_item_id
on public.tasks
for each row execute function public.assert_memory_record_sources_owned();

create trigger short_term_states_require_owned_sources
before insert or update of user_id, source_raw_input_id, source_extracted_item_id
on public.short_term_states
for each row execute function public.assert_memory_record_sources_owned();

create trigger life_events_require_owned_sources
before insert or update of user_id, source_raw_input_id, source_extracted_item_id
on public.life_events
for each row execute function public.assert_memory_record_sources_owned();

create trigger profile_items_require_owned_sources
before insert or update of user_id, source_raw_input_id, source_extracted_item_id
on public.profile_items
for each row execute function public.assert_memory_record_sources_owned();

create trigger summary_sources_require_owned_summary
before insert or update of user_id, summary_id on public.summary_sources
for each row execute function public.assert_summary_source_owned();

create trigger schedule_blocks_require_owned_sources
before insert or update of user_id, plan_id, task_id on public.schedule_blocks
for each row execute function public.assert_schedule_block_sources_owned();

create trigger schedule_block_sources_require_owned_block
before insert or update of user_id, block_id on public.schedule_block_sources
for each row execute function public.assert_schedule_block_source_owned();

revoke all on function public.assert_ai_parse_result_source_owned() from public;
revoke all on function public.assert_extracted_item_sources_owned() from public;
revoke all on function public.assert_memory_record_sources_owned() from public;
revoke all on function public.assert_summary_source_owned() from public;
revoke all on function public.assert_schedule_block_sources_owned() from public;
revoke all on function public.assert_schedule_block_source_owned() from public;
grant execute on function public.assert_ai_parse_result_source_owned() to authenticated;
grant execute on function public.assert_extracted_item_sources_owned() to authenticated;
grant execute on function public.assert_memory_record_sources_owned() to authenticated;
grant execute on function public.assert_summary_source_owned() to authenticated;
grant execute on function public.assert_schedule_block_sources_owned() to authenticated;
grant execute on function public.assert_schedule_block_source_owned() to authenticated;

create index if not exists raw_inputs_user_created_idx
  on public.raw_inputs(user_id, created_at desc);
create index if not exists tasks_user_due_idx
  on public.tasks(user_id, due_time);
create index if not exists tasks_user_status_idx
  on public.tasks(user_id, status, task_status);
create index if not exists states_user_valid_idx
  on public.short_term_states(user_id, valid_until);
create index if not exists summaries_user_type_range_idx
  on public.summaries(user_id, summary_type, time_range_start, time_range_end);
create index if not exists schedule_plans_user_date_idx
  on public.schedule_plans(user_id, plan_date);
create index if not exists schedule_blocks_plan_time_idx
  on public.schedule_blocks(plan_id, start_time);

alter table public.profiles enable row level security;
alter table public.raw_inputs enable row level security;
alter table public.ai_parse_results enable row level security;
alter table public.extracted_items enable row level security;
alter table public.tasks enable row level security;
alter table public.short_term_states enable row level security;
alter table public.life_events enable row level security;
alter table public.profile_items enable row level security;
alter table public.summaries enable row level security;
alter table public.summary_sources enable row level security;
alter table public.schedule_plans enable row level security;
alter table public.schedule_blocks enable row level security;
alter table public.schedule_block_sources enable row level security;

create policy "profiles owner access"
  on public.profiles
  for all
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "raw_inputs owner access"
  on public.raw_inputs
  for all
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "ai_parse_results owner access"
  on public.ai_parse_results
  for all
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "extracted_items owner access"
  on public.extracted_items
  for all
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "tasks owner access"
  on public.tasks
  for all
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "short_term_states owner access"
  on public.short_term_states
  for all
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "life_events owner access"
  on public.life_events
  for all
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "profile_items owner access"
  on public.profile_items
  for all
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "summaries owner access"
  on public.summaries
  for all
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "summary_sources owner access"
  on public.summary_sources
  for all
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "schedule_plans owner access"
  on public.schedule_plans
  for all
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "schedule_blocks owner access"
  on public.schedule_blocks
  for all
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "schedule_block_sources owner access"
  on public.schedule_block_sources
  for all
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- Data API privileges. RLS decides which rows a user may access, but the
-- authenticated role still needs table privileges when automatic table exposure
-- is disabled in Supabase project settings.
grant select, insert, update, delete on public.profiles to authenticated;
grant select, insert, update, delete on public.raw_inputs to authenticated;
grant select, insert, update, delete on public.ai_parse_results to authenticated;
grant select, insert, update, delete on public.extracted_items to authenticated;
grant select, insert, update, delete on public.tasks to authenticated;
grant select, insert, update, delete on public.short_term_states to authenticated;
grant select, insert, update, delete on public.life_events to authenticated;
grant select, insert, update, delete on public.profile_items to authenticated;
grant select, insert, update, delete on public.summaries to authenticated;
grant select, insert, update, delete on public.summary_sources to authenticated;
grant select, insert, update, delete on public.schedule_plans to authenticated;
grant select, insert, update, delete on public.schedule_blocks to authenticated;
grant select, insert, update, delete on public.schedule_block_sources to authenticated;

revoke all on public.profiles from anon;
revoke all on public.raw_inputs from anon;
revoke all on public.ai_parse_results from anon;
revoke all on public.extracted_items from anon;
revoke all on public.tasks from anon;
revoke all on public.short_term_states from anon;
revoke all on public.life_events from anon;
revoke all on public.profile_items from anon;
revoke all on public.summaries from anon;
revoke all on public.summary_sources from anon;
revoke all on public.schedule_plans from anon;
revoke all on public.schedule_blocks from anon;
revoke all on public.schedule_block_sources from anon;
