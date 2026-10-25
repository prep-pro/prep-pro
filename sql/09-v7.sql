-- Prep.pro · v7 · Preparadores: cadastro opcional, busca por cidade e destaque pago
create table if not exists preparadores (
  user_id          uuid primary key references profiles(id) on delete cascade,
  ativo            boolean not null default true,          -- aparece nas buscas (a pessoa liga e desliga)
  nome_oficina     text not null,
  cidade           text not null,
  uf               char(2) not null,
  whatsapp         text,
  instagram        text,
  especialidades   text[] not null default '{}',
  descricao        text,
  destaque_ate     timestamptz,                            -- só o admin (ou o pagamento) altera
  quer_destaque_em timestamptz,                            -- tocou em "tenho interesse"
  criado_em        timestamptz not null default now(),
  atualizado_em    timestamptz not null default now()
);
create index if not exists preparadores_local_idx on preparadores (uf, lower(cidade));

create table if not exists preparador_contatos (
  id             bigint generated always as identity primary key,
  preparador_id  uuid not null references preparadores(user_id) on delete cascade,
  user_id        uuid references profiles(id) on delete set null,
  project_id     uuid references projects(id) on delete set null,
  tipo           text not null default 'whatsapp' check (tipo in ('whatsapp', 'instagram', 'escolheu')),
  criado_em      timestamptz not null default now()
);

alter table preparadores        enable row level security;
alter table preparador_contatos enable row level security;

drop policy if exists "preparadores leitura" on preparadores;
create policy "preparadores leitura" on preparadores for select to authenticated using (ativo or user_id = auth.uid() or public.is_admin());
drop policy if exists "preparador cria" on preparadores;
create policy "preparador cria" on preparadores for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "preparador altera" on preparadores;
create policy "preparador altera" on preparadores for update to authenticated using (user_id = auth.uid() or public.is_admin()) with check (user_id = auth.uid() or public.is_admin());
drop policy if exists "preparador apaga" on preparadores;
create policy "preparador apaga" on preparadores for delete to authenticated using (user_id = auth.uid());

drop policy if exists "registrar contato" on preparador_contatos;
create policy "registrar contato" on preparador_contatos for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "preparador ve contatos" on preparador_contatos;
create policy "preparador ve contatos" on preparador_contatos for select to authenticated using (preparador_id = auth.uid() or public.is_admin());

-- O destaque é pago: o próprio preparador não consegue se colocar no topo
create or replace function public.preparador_protege_destaque() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() and coalesce(auth.role(), '') <> 'service_role' then
    if tg_op = 'INSERT' then new.destaque_ate := null;
    else new.destaque_ate := old.destaque_ate; end if;
  end if;
  new.atualizado_em := now();
  return new;
end $$;
drop trigger if exists preparador_destaque on preparadores;
create trigger preparador_destaque before insert or update on preparadores
  for each row execute function public.preparador_protege_destaque();
