begin;

create index if not exists ai_parse_results_user_idx
  on public.ai_parse_results(user_id);
create index if not exists ai_parse_results_raw_input_idx
  on public.ai_parse_results(raw_input_id);
create index if not exists extracted_items_user_idx
  on public.extracted_items(user_id);
create index if not exists extracted_items_raw_input_idx
  on public.extracted_items(raw_input_id);
create index if not exists extracted_items_parse_result_idx
  on public.extracted_items(ai_parse_result_id);
create index if not exists tasks_source_raw_input_idx
  on public.tasks(source_raw_input_id);
create index if not exists tasks_source_extracted_item_idx
  on public.tasks(source_extracted_item_id);
create index if not exists states_source_raw_input_idx
  on public.short_term_states(source_raw_input_id);
create index if not exists states_source_extracted_item_idx
  on public.short_term_states(source_extracted_item_id);
create index if not exists life_events_user_idx
  on public.life_events(user_id);
create index if not exists life_events_source_raw_input_idx
  on public.life_events(source_raw_input_id);
create index if not exists life_events_source_extracted_item_idx
  on public.life_events(source_extracted_item_id);
create index if not exists profile_items_user_idx
  on public.profile_items(user_id);
create index if not exists profile_items_source_raw_input_idx
  on public.profile_items(source_raw_input_id);
create index if not exists profile_items_source_extracted_item_idx
  on public.profile_items(source_extracted_item_id);
create index if not exists summary_sources_user_idx
  on public.summary_sources(user_id);
create index if not exists summary_sources_summary_idx
  on public.summary_sources(summary_id);
create index if not exists schedule_blocks_user_idx
  on public.schedule_blocks(user_id);
create index if not exists schedule_blocks_task_idx
  on public.schedule_blocks(task_id);
create index if not exists schedule_block_sources_user_idx
  on public.schedule_block_sources(user_id);
create index if not exists schedule_block_sources_block_idx
  on public.schedule_block_sources(block_id);

commit;
