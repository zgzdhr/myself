begin;

create table if not exists public.ai_daily_request_usage (
  user_id uuid not null references auth.users(id) on delete cascade,
  usage_day date not null,
  request_count integer not null default 0 check (request_count >= 0),
  updated_at timestamptz not null default now(),
  primary key (user_id, usage_day)
);

alter table public.ai_daily_request_usage enable row level security;
revoke all on public.ai_daily_request_usage from anon, authenticated;

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

revoke all on function public.consume_ai_daily_request_quota() from public;
grant execute on function public.consume_ai_daily_request_quota() to authenticated;

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
grant execute on function public.delete_my_account() to authenticated;

create or replace function public.assert_ai_parse_result_source_owned()
returns trigger
language plpgsql
security invoker
set search_path = ''
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
set search_path = ''
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
set search_path = ''
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
set search_path = ''
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
set search_path = ''
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
set search_path = ''
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

drop trigger if exists ai_parse_results_require_owned_source
  on public.ai_parse_results;
create trigger ai_parse_results_require_owned_source
before insert or update of user_id, raw_input_id on public.ai_parse_results
for each row execute function public.assert_ai_parse_result_source_owned();

drop trigger if exists extracted_items_require_owned_sources
  on public.extracted_items;
create trigger extracted_items_require_owned_sources
before insert or update of user_id, raw_input_id, ai_parse_result_id
on public.extracted_items
for each row execute function public.assert_extracted_item_sources_owned();

drop trigger if exists tasks_require_owned_sources on public.tasks;
create trigger tasks_require_owned_sources
before insert or update of user_id, source_raw_input_id, source_extracted_item_id
on public.tasks
for each row execute function public.assert_memory_record_sources_owned();

drop trigger if exists short_term_states_require_owned_sources
  on public.short_term_states;
create trigger short_term_states_require_owned_sources
before insert or update of user_id, source_raw_input_id, source_extracted_item_id
on public.short_term_states
for each row execute function public.assert_memory_record_sources_owned();

drop trigger if exists life_events_require_owned_sources on public.life_events;
create trigger life_events_require_owned_sources
before insert or update of user_id, source_raw_input_id, source_extracted_item_id
on public.life_events
for each row execute function public.assert_memory_record_sources_owned();

drop trigger if exists profile_items_require_owned_sources on public.profile_items;
create trigger profile_items_require_owned_sources
before insert or update of user_id, source_raw_input_id, source_extracted_item_id
on public.profile_items
for each row execute function public.assert_memory_record_sources_owned();

drop trigger if exists summary_sources_require_owned_summary
  on public.summary_sources;
create trigger summary_sources_require_owned_summary
before insert or update of user_id, summary_id on public.summary_sources
for each row execute function public.assert_summary_source_owned();

drop trigger if exists schedule_blocks_require_owned_sources
  on public.schedule_blocks;
create trigger schedule_blocks_require_owned_sources
before insert or update of user_id, plan_id, task_id on public.schedule_blocks
for each row execute function public.assert_schedule_block_sources_owned();

drop trigger if exists schedule_block_sources_require_owned_block
  on public.schedule_block_sources;
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

grant delete on table
  public.profiles,
  public.raw_inputs,
  public.ai_parse_results,
  public.extracted_items,
  public.tasks,
  public.short_term_states,
  public.life_events,
  public.profile_items,
  public.summaries,
  public.summary_sources,
  public.schedule_plans,
  public.schedule_blocks,
  public.schedule_block_sources
to authenticated;

revoke all on table
  public.profiles,
  public.raw_inputs,
  public.ai_parse_results,
  public.extracted_items,
  public.tasks,
  public.short_term_states,
  public.life_events,
  public.profile_items,
  public.summaries,
  public.summary_sources,
  public.schedule_plans,
  public.schedule_blocks,
  public.schedule_block_sources
from anon;

-- Supabase may install this SECURITY DEFINER event-trigger helper in public.
-- The event trigger itself does not require API roles to execute the function.
do $$
begin
  if to_regprocedure('public.rls_auto_enable()') is not null then
    execute 'revoke execute on function public.rls_auto_enable() from public, anon, authenticated';
  end if;
end;
$$;

notify pgrst, 'reload schema';

commit;
