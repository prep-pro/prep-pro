-- Prep.pro · v8 · Plano PRO, cadastro completo, cupons de parceiros e proteção do perfil

-- Cadastro mais completo
alter table profiles add column if not exists perfil_uso     text check (perfil_uso in ('entusiasta', 'preparador', 'loja', 'outro'));
alter table profiles add column if not exists como_conheceu  text;
alter table profiles add column if not exists aceita_ofertas boolean not null default false;
alter table profiles add column if not exists termos_em      timestamptz;
-- Plano: PRO enquanto pro_ate estiver no futuro (o pagamento ou o admin define)
alter table profiles add column if not exists pro_ate        timestamptz;
alter table profiles add column if not exists quer_pro_em    timestamptz;

create or replace function public.is_pro() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select is_admin or coalesce(pro_ate > now(), false) from profiles where id = auth.uid()), false)
$$;

-- Segurança: ninguém se promove a admin nem se dá PRO sozinho
create or replace function public.perfil_protege() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() and coalesce(auth.role(), '') <> 'service_role' and auth.uid() is not null then
    if tg_op = 'INSERT' then new.is_admin := false; new.pro_ate := null;
    else new.is_admin := old.is_admin; new.pro_ate := old.pro_ate; end if;
  end if;
  return new;
end $$;
drop trigger if exists perfil_protege on profiles;
create trigger perfil_protege before insert or update on profiles for each row execute function public.perfil_protege();

drop policy if exists "admin le perfis" on profiles;
create policy "admin le perfis" on profiles for select to authenticated using (public.is_admin());
drop policy if exists "admin altera perfis" on profiles;
create policy "admin altera perfis" on profiles for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- Novo usuário: guarda os dados do cadastro
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare m jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
begin
  insert into public.profiles (id, nome, celular, cidade, uf, perfil_uso, como_conheceu, aceita_ofertas, termos_em)
  values (new.id, m ->> 'nome', nullif(m ->> 'celular', ''), nullif(m ->> 'cidade', ''), nullif(m ->> 'uf', '')::char(2),
          nullif(m ->> 'perfil_uso', ''), nullif(m ->> 'como_conheceu', ''), coalesce((m ->> 'aceita_ofertas')::boolean, false),
          case when (m ->> 'termos')::boolean then now() end);
  return new;
end $$;

-- Cupons de parceiros (o código fica numa tabela à parte, só para quem pode ver)
create table if not exists cupons (
  id              uuid primary key default gen_random_uuid(),
  parceiro        text not null,
  titulo          text not null,
  desconto        text not null,                 -- ex.: "10% OFF", "Frete grátis"
  url             text,
  descricao       text,
  economia_media  numeric(10,2),                 -- quanto a pessoa economiza, em média, usando
  so_pro          boolean not null default true,
  valido_ate      date,
  ativo           boolean not null default true,
  criado_em       timestamptz not null default now()
);
create table if not exists cupom_codigos (
  cupom_id  uuid primary key references cupons(id) on delete cascade,
  codigo    text not null
);
create table if not exists cupom_usos (
  id         bigint generated always as identity primary key,
  cupom_id   uuid not null references cupons(id) on delete cascade,
  user_id    uuid references profiles(id) on delete set null,
  criado_em  timestamptz not null default now()
);
alter table cupons        enable row level security;
alter table cupom_codigos enable row level security;
alter table cupom_usos    enable row level security;

drop policy if exists "cupons leitura" on cupons;
create policy "cupons leitura" on cupons for select to authenticated using (ativo or public.is_admin());
drop policy if exists "admin cupons" on cupons;
create policy "admin cupons" on cupons for all to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists "codigo para quem pode" on cupom_codigos;
create policy "codigo para quem pode" on cupom_codigos for select to authenticated
  using (exists (select 1 from cupons c where c.id = cupom_id and c.ativo and (not c.so_pro or public.is_pro())) or public.is_admin());
drop policy if exists "admin codigos" on cupom_codigos;
create policy "admin codigos" on cupom_codigos for all to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists "registrar uso cupom" on cupom_usos;
create policy "registrar uso cupom" on cupom_usos for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "admin le usos" on cupom_usos;
create policy "admin le usos" on cupom_usos for select to authenticated using (public.is_admin());
