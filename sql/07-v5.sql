-- Prep.pro · POC v5 · Caixinha do projeto (guardado, aporte mensal e projeção)
-- Rode no SQL Editor do Supabase depois dos scripts anteriores. Pode rodar mais de uma vez.

-- Quanto a pessoa tem guardado (a partir de quando) e quanto consegue guardar por mês
alter table projects add column if not exists caixa_inicial numeric(12,2);
alter table projects add column if not exists caixa_desde   timestamptz;
alter table projects add column if not exists aporte_mensal numeric(12,2);

-- Movimentos da caixinha: valor positivo = guardou, negativo = tirou
create table if not exists project_caixa (
  id          uuid primary key default gen_random_uuid(),
  project_id  uuid not null references projects(id) on delete cascade,
  valor       numeric(12,2) not null,
  descricao   text,
  data        date not null default current_date,
  criado_em   timestamptz not null default now()
);
create index if not exists project_caixa_project_idx on project_caixa (project_id);

alter table project_caixa enable row level security;
drop policy if exists "caixa do dono" on project_caixa;
create policy "caixa do dono" on project_caixa for all to authenticated
  using (exists (select 1 from projects p where p.id = project_id and p.user_id = auth.uid()))
  with check (exists (select 1 from projects p where p.id = project_id and p.user_id = auth.uid()));
