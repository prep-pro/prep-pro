-- v10 · Preparação para o lançamento: políticas de RLS mais rápidas e índices nas chaves usadas pelo app
-- 1) Troca auth.uid() por (select auth.uid()) em todas as políticas: o Postgres calcula uma vez por consulta,
--    não uma vez por linha (recomendação do Supabase, aviso auth_rls_initplan).
do $$
declare p record; using_ text; check_ text;
begin
  for p in select * from pg_policies where schemaname = 'public'
           and (qual ~ 'auth\.uid\(\)' or with_check ~ 'auth\.uid\(\)') loop
    using_ := regexp_replace(p.qual, '(?<!select )auth\.uid\(\)', '(select auth.uid())', 'gi');
    check_ := regexp_replace(p.with_check, '(?<!select )auth\.uid\(\)', '(select auth.uid())', 'gi');
    execute format('drop policy %I on %I.%I', p.policyname, p.schemaname, p.tablename);
    execute format('create policy %I on %I.%I as %s for %s to %s %s %s', p.policyname, p.schemaname, p.tablename,
      p.permissive, p.cmd, array_to_string(p.roles, ', '),
      case when using_ is not null then 'using (' || using_ || ')' else '' end,
      case when check_ is not null then 'with check (' || check_ || ')' else '' end);
  end loop;
end $$;

-- 2) Índices nas chaves estrangeiras que o app consulta
create index if not exists project_items_template_item_idx on project_items (template_item_id);
create index if not exists project_items_stage_idx on project_items (stage_id);
create index if not exists project_expenses_stage_idx on project_expenses (stage_id);
create index if not exists project_expenses_item_idx on project_expenses (project_item_id);
create index if not exists project_stages_stage_idx on project_stages (stage_id);
create index if not exists projects_template_idx on projects (template_id);
create index if not exists projects_car_model_idx on projects (car_model_id);
create index if not exists diary_entries_item_idx on diary_entries (project_item_id);
create index if not exists preparador_contatos_user_idx on preparador_contatos (user_id);
create index if not exists products_template_item_idx on products (template_item_id);
create index if not exists product_links_product_idx on product_links (product_id);

-- 3) search_path fixo na função que faltava
alter function public.touch_atualizado_em() set search_path = public;
