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
