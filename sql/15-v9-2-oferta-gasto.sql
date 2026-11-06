-- Prep.pro · v9.2 · Gasto ligado à oferta usada (o usuário diz "comprei por esta oferta")
alter table project_expenses add column if not exists product_link_id uuid references product_links(id) on delete set null;
create index if not exists project_expenses_link_idx on project_expenses (product_link_id);

-- Admin vê quantas compras cada link de oferta gerou (sem ver os gastos dos usuários)
create or replace function public.compras_por_oferta()
returns table (product_link_id uuid, compras bigint, valor numeric)
language sql stable security definer set search_path = public as $$
  select e.product_link_id, count(*), sum(coalesce(e.valor_realizado, e.valor_previsto, 0))
  from project_expenses e
  where e.product_link_id is not null and public.is_admin()
  group by e.product_link_id
$$;
revoke all on function public.compras_por_oferta() from public, anon;
grant execute on function public.compras_por_oferta() to authenticated;

-- Limpa o preço que veio grudado no nome de uma oferta e guarda como preço de referência
update product_links l set preco_ref = 324.99
from products p where p.id = l.product_id and p.nome like 'Régua Suporte De Bobinas%' and l.preco_ref is null;
update products set nome = regexp_replace(nome, '\s*[-–|]\s*R\$\s*[\d.,]+\s*$', '') where nome ~ 'R\$\s*[\d.,]+\s*$';
