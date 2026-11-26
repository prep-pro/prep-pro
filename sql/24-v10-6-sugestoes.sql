-- v10.6 · Sugestões, erros e elogios enviados pelo app (aplicado no Supabase como v10_6_sugestoes)
create table if not exists public.sugestoes (
  id bigint generated always as identity primary key,
  criado_em timestamptz not null default now(),
  user_id uuid references auth.users(id) on delete set null,
  tipo text not null check (tipo in ('melhoria', 'erro', 'elogio', 'outro')),
  mensagem text not null check (char_length(mensagem) between 3 and 2000),
  tela text check (char_length(tela) <= 40),
  versao text check (char_length(versao) <= 12),
  aparelho text check (char_length(aparelho) <= 160),
  pode_contatar boolean not null default false,
  status text not null default 'nova' check (status in ('nova', 'lida', 'resolvida')),
  resposta text check (char_length(resposta) <= 1000)
);
create index if not exists sugestoes_criado_idx on public.sugestoes (criado_em desc);
create index if not exists sugestoes_user_idx on public.sugestoes (user_id);
alter table public.sugestoes enable row level security;
create policy "enviar sugestao" on public.sugestoes for insert to anon, authenticated
  with check ((user_id is null or user_id = (select auth.uid())) and status = 'nova' and resposta is null);
create policy "ver as proprias sugestoes" on public.sugestoes for select to authenticated
  using (user_id = (select auth.uid()) or (select public.is_admin()));
create policy "admin trata sugestoes" on public.sugestoes for update to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
grant insert on public.sugestoes to anon, authenticated;
grant select, update on public.sugestoes to authenticated;
