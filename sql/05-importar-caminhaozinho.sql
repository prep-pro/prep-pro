-- Prep.pro · importa os gastos já feitos no Caminhãozinho (tabela do Tonito, 25/10/2026)
-- Rode depois do prep-pro-v3-migracao.sql. Usa o projeto cujo nome começa com "Caminh".
-- Não duplica: se rodar de novo, os lançamentos já importados são ignorados.

with p as (
  select id, template_id from projects where nome ilike 'caminh%' order by criado_em limit 1
),
st as (
  select s.id, s.ordem from template_stages s join p on s.template_id = p.template_id
),
v (tipo, descricao, fornecedor, valor, ordem, item) as (values
  ('mao_de_obra'::tipo_gasto, 'Dinamômetro',                          'Betinho',          150.00::numeric, null::int, null::text),
  ('peca',        'Roda fônica 60-2',                                 'ML',               166.85,  1, null),
  ('peca',        'Turbina ZR .70 Black',                             'ML',               2295.00, 2, 'Kit turbo e coletor'),
  ('peca',        'Intercooler MH Street 2-1/2',                      'ML',               1206.40, 2, 'Intercooler'),
  ('peca',        '2 sensores de pressão PS10B FuelTech',             'ML',               199.00,  1, null),
  ('peca',        'Kit 6 bicos Bosch 112 lb',                         'ML',               2964.00, 1, 'Bicos de maior vazão'),
  ('peca',        'FT450 + Nano + chicotes',                          'RS Performance',   5591.00, 1, 'Injeção programável'),
  ('peca',        'Kit 6 bobinas Bosch Camaro',                       'RS Performance',   1290.00, 1, null),
  ('frete',       'Frete do coletor Flow Performance',                'Sedex',            152.27,  2, null),
  ('peca',        'Coletor de admissão Flow Performance',             'Flow Performance', 5600.00, 2, null),
  ('peca',        'Distribuidor cego Flow Performance',               'Flow Performance', 700.00,  1, null),
  ('peca',        'Coletor de escape Typhoon T3',                     'USA',              2755.64, 2, 'Kit turbo e coletor'),
  ('frete',       'Frete do coletor de escape',                       'USA',              1683.00, 2, null)
)
insert into project_expenses (project_id, stage_id, project_item_id, tipo, descricao, fornecedor, valor_realizado)
select p.id, st.id, pi.id, v.tipo, v.descricao, v.fornecedor, v.valor
from v
cross join p
left join st on st.ordem = v.ordem
left join template_items ti on ti.stage_id = st.id and ti.nome = v.item
left join project_items pi on pi.project_id = p.id and pi.template_item_id = ti.id
where not exists (
  select 1 from project_expenses e
  where e.project_id = p.id and e.descricao = v.descricao and e.valor_realizado = v.valor
);

-- Itens do plano que já têm gasto ligado passam para "comprado"
update project_items pi
set status = 'comprado', comprado_em = coalesce(pi.comprado_em, now())
where pi.status = 'lista'
  and exists (select 1 from project_expenses e where e.project_item_id = pi.id and e.valor_realizado is not null);

-- Conferência: 13 lançamentos e R$ 24.753,16
-- (mais o que você já tiver lançado na versão 2, se lançou)
select count(*) as lancamentos, sum(valor_realizado) as total_realizado
from project_expenses e
join projects p on p.id = e.project_id
where p.nome ilike 'caminh%';
