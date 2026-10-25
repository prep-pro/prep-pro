-- Prep.pro · POC v2 · marchas livres e orçado x realizado
-- Rode no SQL Editor do Supabase depois dos scripts anteriores. Pode rodar uma vez só.

-- Orçamento total do projeto (em reais)
alter table projects add column if not exists orcamento_total numeric(12,2);

-- Valor orçado de cada item do plano (o valor pago já existe: valor_pago)
alter table project_items add column if not exists valor_orcado numeric(10,2);

-- Informações do projeto por stage: quem faz (4ª marcha) e mão de obra orçada e paga
create table if not exists project_stages (
  id          uuid primary key default gen_random_uuid(),
  project_id  uuid not null references projects(id) on delete cascade,
  stage_id    uuid not null references template_stages(id) on delete cascade,
  quem_faz    text,
  mo_orcado   numeric(10,2),
  mo_pago     numeric(10,2),
  unique (project_id, stage_id)
);
create index if not exists project_stages_project_idx on project_stages (project_id);

alter table project_stages enable row level security;

drop policy if exists "stages do dono" on project_stages;
create policy "stages do dono" on project_stages for all to authenticated
  using (exists (select 1 from projects p where p.id = project_id and p.user_id = auth.uid()))
  with check (exists (select 1 from projects p where p.id = project_id and p.user_id = auth.uid()));
