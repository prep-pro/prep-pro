-- Prep.pro · POC v6 · ofertas com links de afiliado, banners de parceiros e área de admin
-- Rode no SQL Editor do Supabase depois dos scripts anteriores. Pode rodar mais de uma vez.

-- Novas lojas para os links de afiliado
alter type loja add value if not exists 'shopee';
alter type loja add value if not exists 'aliexpress';

-- Ofertas: um produto pode valer para um item do plano OU para palavras-chave (itens próprios do usuário)
alter table products alter column template_item_id drop not null;
alter table products add column if not exists palavras text[] not null default '{}';
alter table products add column if not exists criado_em timestamptz not null default now();

-- Administrador (você): cadastra ofertas e banners pelo próprio app
alter table profiles add column if not exists is_admin boolean not null default false;

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select is_admin from profiles where id = auth.uid()), false)
$$;

-- Banners de parceiros (um por tela, sempre marcado como "Parceiro")
create table if not exists banners (
  id           uuid primary key default gen_random_uuid(),
  parceiro     text not null,
  titulo       text not null,
  texto        text,
  imagem_url   text,
  url          text,
  posicao      text not null check (posicao in ('garagem', 'gastos', 'stage')),
  stage_ordem  int,                        -- quando posicao = 'stage' (0 = Stage 0, 4 = Legalização)
  ativo        boolean not null default true,
  criado_em    timestamptz not null default now()
);

create table if not exists banner_clicks (
  id          bigint generated always as identity primary key,
  banner_id   uuid not null references banners(id) on delete cascade,
  user_id     uuid references profiles(id) on delete set null,
  project_id  uuid references projects(id) on delete set null,
  clicado_em  timestamptz not null default now()
);

alter table banners       enable row level security;
alter table banner_clicks enable row level security;

-- Leitura: todos logados veem o que está ativo; o admin vê tudo
drop policy if exists "banners leitura" on banners;
create policy "banners leitura" on banners for select to authenticated using (ativo or public.is_admin());
drop policy if exists "catalogo leitura" on products;
create policy "catalogo leitura" on products for select to authenticated using (ativo or public.is_admin());

-- Escrita só do admin
drop policy if exists "admin produtos"  on products;
drop policy if exists "admin links"     on product_links;
drop policy if exists "admin banners"   on banners;
create policy "admin produtos" on products      for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admin links"    on product_links for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admin banners"  on banners       for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Cliques: o usuário registra; o admin lê
drop policy if exists "registrar clique banner" on banner_clicks;
create policy "registrar clique banner" on banner_clicks for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "admin le cliques banner" on banner_clicks;
create policy "admin le cliques banner" on banner_clicks for select to authenticated using (public.is_admin());
drop policy if exists "admin le cliques links" on link_clicks;
create policy "admin le cliques links" on link_clicks for select to authenticated using (public.is_admin());

-- Você vira admin: o dono do projeto Caminhãozinho
update profiles set is_admin = true
where id = (select user_id from projects where nome ilike 'caminh%' order by criado_em limit 1);

select case when exists (select 1 from profiles where is_admin) then 'Admin definido ✓'
            else 'Nenhum admin: crie o projeto Caminhãozinho no app e rode de novo' end as resultado;
