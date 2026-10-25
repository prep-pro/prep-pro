-- =====================================================================
-- Prep.pro · Modelo de dados v1
-- Banco: Supabase (Postgres 15+)
-- Como usar: Supabase > SQL Editor > New query > cole tudo > Run
-- =====================================================================

-- ---------- Tipos ----------------------------------------------------
create type objetivo    as enum ('rua', 'arrancada', 'offroad', 'track', 'visual', 'restauro');
create type tipo_carro  as enum ('pickup', 'sedan', 'hatch', 'suv', 'outro');
create type status_diag as enum ('ok', 'verificar', 'nao_sei');
create type status_item as enum ('lista', 'comprado', 'instalado');
create type loja        as enum ('mercado_livre', 'amazon', 'outra');

-- =====================================================================
-- CATÁLOGO · você mantém pelo painel web (usuário só lê)
-- =====================================================================

-- Modelos de carro (bases)
create table car_models (
  id         uuid primary key default gen_random_uuid(),
  marca      text not null,
  modelo     text not null,
  motor      text,
  tipo       tipo_carro not null default 'outro',
  criado_em  timestamptz not null default now()
);

-- Modelos de plano (na v1: só "Força e turbo")
create table templates (
  id         uuid primary key default gen_random_uuid(),
  nome       text not null,
  objetivos  objetivo[] not null,
  ativo      boolean not null default true
);

-- Stages de cada modelo de plano (Stage 0, 1, 2, 3 e Legalização)
create table template_stages (
  id             uuid primary key default gen_random_uuid(),
  template_id    uuid not null references templates(id) on delete cascade,
  ordem          smallint not null,
  nome           text not null,
  quem_faz       text,                         -- categoria de parceiro: 'Mecânico', 'Injeção', ...
  e_legalizacao  boolean not null default false,
  unique (template_id, ordem)
);

-- Itens de cada stage (peças ou passos)
create table template_items (
  id         uuid primary key default gen_random_uuid(),
  stage_id   uuid not null references template_stages(id) on delete cascade,
  ordem      smallint not null,
  nome       text not null,
  descricao  text,
  unique (stage_id, ordem)
);

-- Produtos sugeridos para cada item (car_model_id nulo = serve para todos)
create table products (
  id                uuid primary key default gen_random_uuid(),
  template_item_id  uuid not null references template_items(id) on delete cascade,
  car_model_id      uuid references car_models(id) on delete set null,
  nome              text not null,
  imagem_url        text,
  ativo             boolean not null default true
);

-- Links de afiliado de cada produto
create table product_links (
  id             uuid primary key default gen_random_uuid(),
  product_id     uuid not null references products(id) on delete cascade,
  loja           loja not null,
  url_afiliado   text not null,
  preco_ref      numeric(10,2),
  atualizado_em  timestamptz not null default now()
);

-- Parceiros (Quem faz)
create table partners (
  id         uuid primary key default gen_random_uuid(),
  nome       text not null,
  categoria  text not null,                    -- mesma lista de template_stages.quem_faz
  cidade     text,
  uf         char(2),
  whatsapp   text,
  instagram  text,
  parceiro   boolean not null default false,   -- selo "PARCEIRA"
  ativo      boolean not null default true
);

-- =====================================================================
-- CONTA
-- =====================================================================

create table profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  nome       text,
  celular    text,
  cidade     text,
  uf         char(2),
  criado_em  timestamptz not null default now()
);

-- Cria o perfil automaticamente quando a pessoa se cadastra
create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, nome)
  values (new.id, new.raw_user_meta_data ->> 'nome');
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- =====================================================================
-- PROJETOS · o que o usuário cria e atualiza
-- =====================================================================

-- Um projeto = um sonho (com ou sem carro)
create table projects (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references profiles(id) on delete cascade,
  nome           text not null,                -- ex.: "S10 4.3 V6"
  objetivo       objetivo not null,            -- 1ª marcha
  orcamento      text,                         -- 1ª marcha: faixa escolhida
  prazo          text,                         -- 1ª marcha
  tem_carro      boolean not null default false, -- 2ª marcha
  car_model_id   uuid references car_models(id) on delete set null,
  template_id    uuid references templates(id) on delete set null,
  marcha         smallint not null default 1 check (marcha between 1 and 6), -- 6 = acerto fino
  cor            text,
  criado_em      timestamptz not null default now(),
  atualizado_em  timestamptz not null default now()
);
create index on projects (user_id);

create function public.touch_atualizado_em() returns trigger
language plpgsql as $$
begin new.atualizado_em := now(); return new; end $$;

create trigger projects_touch before update on projects
  for each row execute function public.touch_atualizado_em();

-- 2ª marcha: diagnóstico do ponto de partida
create table project_diagnostics (
  id          uuid primary key default gen_random_uuid(),
  project_id  uuid not null references projects(id) on delete cascade,
  item        text not null,                   -- 'Compressão dos cilindros', ...
  status      status_diag not null default 'nao_sei',
  unique (project_id, item)
);

-- 3ª e 5ª marchas: cada item do plano no projeto
create table project_items (
  id                uuid primary key default gen_random_uuid(),
  project_id        uuid not null references projects(id) on delete cascade,
  template_item_id  uuid not null references template_items(id) on delete restrict,
  status            status_item not null default 'lista',
  valor_pago        numeric(10,2),
  comprado_em       timestamptz,
  instalado_em      timestamptz,
  unique (project_id, template_item_id)
);
create index on project_items (project_id);

-- Acerto fino: cada ciclo de testes, regulagem e ajustes
create table project_cycles (
  id          uuid primary key default gen_random_uuid(),
  project_id  uuid not null references projects(id) on delete cascade,
  numero      smallint not null default 1,
  testes      boolean not null default false,
  regulagem   boolean not null default false,
  ajustes     boolean not null default false,
  fechado_em  timestamptz,
  unique (project_id, numero)
);

-- Diário do projeto (fotos ficam no Supabase Storage; aqui só os caminhos)
create table diary_entries (
  id               uuid primary key default gen_random_uuid(),
  project_id       uuid not null references projects(id) on delete cascade,
  project_item_id  uuid references project_items(id) on delete set null,
  texto            text,
  fotos            text[] not null default '{}',
  criado_em        timestamptz not null default now()
);
create index on diary_entries (project_id);

-- =====================================================================
-- MÉTRICAS · o que prova a v1 (cliques em afiliado e contatos)
-- =====================================================================

create table link_clicks (
  id               bigint generated always as identity primary key,
  user_id          uuid references profiles(id) on delete set null,
  project_id       uuid references projects(id) on delete set null,
  product_link_id  uuid not null references product_links(id) on delete cascade,
  clicado_em       timestamptz not null default now()
);

create table partner_contacts (
  id          bigint generated always as identity primary key,
  user_id     uuid references profiles(id) on delete set null,
  project_id  uuid references projects(id) on delete set null,
  partner_id  uuid not null references partners(id) on delete cascade,
  criado_em   timestamptz not null default now()
);

-- =====================================================================
-- SEGURANÇA (RLS): cada pessoa só vê e mexe no que é dela
-- O painel web usa a service role, que ignora o RLS.
-- =====================================================================

alter table car_models          enable row level security;
alter table templates           enable row level security;
alter table template_stages     enable row level security;
alter table template_items      enable row level security;
alter table products            enable row level security;
alter table product_links       enable row level security;
alter table partners            enable row level security;
alter table profiles            enable row level security;
alter table projects            enable row level security;
alter table project_diagnostics enable row level security;
alter table project_items       enable row level security;
alter table project_cycles      enable row level security;
alter table diary_entries       enable row level security;
alter table link_clicks         enable row level security;
alter table partner_contacts    enable row level security;

-- Catálogo: leitura para quem está logado
create policy "catalogo leitura" on car_models      for select to authenticated using (true);
create policy "catalogo leitura" on templates       for select to authenticated using (ativo);
create policy "catalogo leitura" on template_stages for select to authenticated using (true);
create policy "catalogo leitura" on template_items  for select to authenticated using (true);
create policy "catalogo leitura" on products        for select to authenticated using (ativo);
create policy "catalogo leitura" on product_links   for select to authenticated using (true);
create policy "catalogo leitura" on partners        for select to authenticated using (ativo);

-- Perfil: só o próprio
create policy "perfil proprio" on profiles for all to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- Projetos: só os próprios
create policy "projetos proprios" on projects for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Tabelas filhas: só se o projeto for do usuário
create policy "diagnostico do dono" on project_diagnostics for all to authenticated
  using (exists (select 1 from projects p where p.id = project_id and p.user_id = auth.uid()))
  with check (exists (select 1 from projects p where p.id = project_id and p.user_id = auth.uid()));

create policy "itens do dono" on project_items for all to authenticated
  using (exists (select 1 from projects p where p.id = project_id and p.user_id = auth.uid()))
  with check (exists (select 1 from projects p where p.id = project_id and p.user_id = auth.uid()));

create policy "ciclos do dono" on project_cycles for all to authenticated
  using (exists (select 1 from projects p where p.id = project_id and p.user_id = auth.uid()))
  with check (exists (select 1 from projects p where p.id = project_id and p.user_id = auth.uid()));

create policy "diario do dono" on diary_entries for all to authenticated
  using (exists (select 1 from projects p where p.id = project_id and p.user_id = auth.uid()))
  with check (exists (select 1 from projects p where p.id = project_id and p.user_id = auth.uid()));

-- Métricas: o usuário só registra; quem lê é o painel
create policy "registrar clique" on link_clicks for insert to authenticated
  with check (user_id = auth.uid());
create policy "registrar contato" on partner_contacts for insert to authenticated
  with check (user_id = auth.uid());

-- =====================================================================
-- DADOS INICIAIS: bases e o plano "Força e turbo"
-- =====================================================================

insert into car_models (marca, modelo, motor, tipo) values
  ('Chevrolet',  'S10',   '4.3 V6',          'pickup'),
  ('Volkswagen', 'Gol',   'AP',              'hatch'),
  ('Chevrolet',  'Opala', '4.1 6 cilindros', 'sedan');

do $$
declare t uuid; s uuid;
begin
  insert into templates (nome, objetivos)
  values ('Força e turbo', '{rua,arrancada,track}') returning id into t;

  insert into template_stages (template_id, ordem, nome, quem_faz)
  values (t, 0, 'Stage 0 · Base saudável', 'Mecânico') returning id into s;
  insert into template_items (stage_id, ordem, nome) values
    (s, 1, 'Revisão do motor'), (s, 2, 'Arrefecimento'), (s, 3, 'Embreagem');

  insert into template_stages (template_id, ordem, nome, quem_faz)
  values (t, 1, 'Stage 1 · Injeção e controle', 'Injeção') returning id into s;
  insert into template_items (stage_id, ordem, nome) values
    (s, 1, 'Injeção programável'), (s, 2, 'Bicos de maior vazão'),
    (s, 3, 'Bomba de combustível'), (s, 4, 'Sonda banda larga');

  insert into template_stages (template_id, ordem, nome, quem_faz)
  values (t, 2, 'Stage 2 · Turbo', 'Preparador') returning id into s;
  insert into template_items (stage_id, ordem, nome) values
    (s, 1, 'Kit turbo e coletor'), (s, 2, 'Intercooler'),
    (s, 3, 'Downpipe e escape'), (s, 4, 'Manômetros');

  insert into template_stages (template_id, ordem, nome, quem_faz)
  values (t, 3, 'Stage 3 · Segurar a força', 'Preparador') returning id into s;
  insert into template_items (stage_id, ordem, nome) values
    (s, 1, 'Freios maiores'), (s, 2, 'Suspensão'), (s, 3, 'Embreagem reforçada');

  insert into template_stages (template_id, ordem, nome, quem_faz, e_legalizacao)
  values (t, 4, 'Legalização · Detran + CSV', 'Vistoria (ITL)', true) returning id into s;
  insert into template_items (stage_id, ordem, nome) values
    (s, 1, 'Autorização prévia no Detran'),
    (s, 2, 'Vistoria na ITL e emissão do CSV'),
    (s, 3, 'Novo CRLV com a modificação');
end $$;
