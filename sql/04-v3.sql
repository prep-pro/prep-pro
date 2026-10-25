-- Prep.pro · POC v3 · lançamentos de gastos (previsto x realizado) e itens próprios no plano
-- Rode no SQL Editor do Supabase depois dos scripts anteriores. Pode rodar mais de uma vez.

-- ---------- Lançamentos de gastos -----------------------------------
do $$ begin
  create type tipo_gasto as enum ('peca', 'mao_de_obra', 'frete', 'servico', 'outro');
exception when duplicate_object then null; end $$;

create table if not exists project_expenses (
  id               uuid primary key default gen_random_uuid(),
  project_id       uuid not null references projects(id) on delete cascade,
  stage_id         uuid references template_stages(id) on delete set null,   -- nulo = geral
  project_item_id  uuid references project_items(id) on delete set null,     -- opcional
  tipo             tipo_gasto not null default 'peca',
  descricao        text not null,
  fornecedor       text,                                                     -- onde / quem
  valor_previsto   numeric(12,2),
  valor_realizado  numeric(12,2),
  data             date not null default current_date,
  criado_em        timestamptz not null default now()
);
create index if not exists project_expenses_project_idx on project_expenses (project_id);

alter table project_expenses enable row level security;
drop policy if exists "gastos do dono" on project_expenses;
create policy "gastos do dono" on project_expenses for all to authenticated
  using (exists (select 1 from projects p where p.id = project_id and p.user_id = auth.uid()))
  with check (exists (select 1 from projects p where p.id = project_id and p.user_id = auth.uid()));

-- ---------- Itens próprios no plano ---------------------------------
alter table project_items alter column template_item_id drop not null;
alter table project_items add column if not exists nome text;
alter table project_items add column if not exists stage_id uuid references template_stages(id) on delete cascade;

-- ---------- Leva os valores lançados na v2 para os lançamentos -------
insert into project_expenses (project_id, stage_id, project_item_id, tipo, descricao, valor_previsto, valor_realizado)
select pi.project_id, ti.stage_id, pi.id, 'peca', ti.nome, pi.valor_orcado, pi.valor_pago
from project_items pi
join template_items ti on ti.id = pi.template_item_id
where (pi.valor_orcado is not null or pi.valor_pago is not null)
  and not exists (select 1 from project_expenses e where e.project_item_id = pi.id);

insert into project_expenses (project_id, stage_id, tipo, descricao, valor_previsto, valor_realizado)
select ps.project_id, ps.stage_id, 'mao_de_obra',
       case when s.e_legalizacao then 'Taxas e despachante' else 'Mão de obra' end,
       ps.mo_orcado, ps.mo_pago
from project_stages ps
join template_stages s on s.id = ps.stage_id
where (ps.mo_orcado is not null or ps.mo_pago is not null)
  and not exists (select 1 from project_expenses e
                  where e.project_id = ps.project_id and e.stage_id = ps.stage_id and e.tipo = 'mao_de_obra'
                    and e.descricao in ('Mão de obra', 'Taxas e despachante'));
