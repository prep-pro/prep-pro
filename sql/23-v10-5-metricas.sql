-- v10.5 · Métricas de acesso sem dados pessoais
-- Cada navegador ganha um código aleatório (visitante) guardado no próprio aparelho. Não guardamos IP, nome ou e-mail
-- de quem só visitou. Cadastros e projetos são contados direto das tabelas oficiais.
create table if not exists public.eventos (
  id bigint generated always as identity primary key,
  criado_em timestamptz not null default now(),
  visitante text not null check (char_length(visitante) between 8 and 40),
  user_id uuid references auth.users(id) on delete set null,
  tipo text not null check (tipo in ('visita', 'publico_visita', 'oferta_clique', 'compartilhar', 'instalar')),
  pagina text check (char_length(pagina) <= 60),
  origem text check (char_length(origem) <= 80),
  slug text check (char_length(slug) <= 20),
  dispositivo text check (dispositivo in ('celular', 'computador')),
  detalhe text check (char_length(detalhe) <= 200)
);
create index if not exists eventos_criado_idx on public.eventos (criado_em desc);
create index if not exists eventos_tipo_idx on public.eventos (tipo, criado_em desc);
create index if not exists eventos_user_idx on public.eventos (user_id);
alter table public.eventos enable row level security;

-- qualquer pessoa registra (inclusive sem login), mas só em nome próprio; só o admin lê
drop policy if exists "registrar evento" on public.eventos;
create policy "registrar evento" on public.eventos for insert to anon, authenticated
  with check (user_id is null or user_id = (select auth.uid()));
drop policy if exists "admin le eventos" on public.eventos;
create policy "admin le eventos" on public.eventos for select to authenticated using ((select public.is_admin()));
grant insert on public.eventos to anon, authenticated;

-- painel: números do período e por dia (fuso de Campo Grande/Cuiabá)
create or replace function public.metricas(p_dias int default 30) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare desde timestamptz := date_trunc('day', now() at time zone 'America/Cuiaba') at time zone 'America/Cuiaba' - make_interval(days => greatest(p_dias, 1) - 1);
begin
  if not public.is_admin() then raise exception 'Só o administrador.'; end if;
  return jsonb_build_object(
    'desde', desde,
    'total', jsonb_build_object(
      'visitantes', (select count(distinct visitante) from eventos where tipo = 'visita' and criado_em >= desde),
      'visitas', (select count(*) from eventos where tipo = 'visita' and criado_em >= desde),
      'cadastros', (select count(*) from auth.users where created_at >= desde),
      'projetos', (select count(*) from projects where criado_em >= desde),
      'gastos', (select count(*) from project_expenses where criado_em >= desde),
      'publico', (select count(*) from eventos where tipo = 'publico_visita' and criado_em >= desde),
      'ofertas', (select count(*) from eventos where tipo = 'oferta_clique' and criado_em >= desde) + (select count(*) from link_clicks where clicado_em >= desde),
      'compartilhar', (select count(*) from eventos where tipo = 'compartilhar' and criado_em >= desde),
      'celular', (select count(distinct visitante) from eventos where tipo = 'visita' and dispositivo = 'celular' and criado_em >= desde),
      'usuarios_total', (select count(*) from auth.users),
      'ativos', (select count(distinct user_id) from eventos where user_id is not null and criado_em >= desde)
    ),
    'dias', (select coalesce(jsonb_agg(jsonb_build_object('dia', d, 'visitantes', v, 'cadastros', c, 'projetos', pj) order by d), '[]'::jsonb) from (
      select g::date d,
        (select count(distinct visitante) from eventos e where e.tipo = 'visita' and (e.criado_em at time zone 'America/Cuiaba')::date = g::date) v,
        (select count(*) from auth.users u where (u.created_at at time zone 'America/Cuiaba')::date = g::date) c,
        (select count(*) from projects p where (p.criado_em at time zone 'America/Cuiaba')::date = g::date) pj
      from generate_series((desde at time zone 'America/Cuiaba')::date, (now() at time zone 'America/Cuiaba')::date, interval '1 day') g) x),
    'origens', (select coalesce(jsonb_agg(jsonb_build_object('origem', o, 'n', n) order by n desc), '[]'::jsonb) from (
      select coalesce(nullif(origem, ''), 'direto / WhatsApp') o, count(distinct visitante) n from eventos
      where tipo in ('visita', 'publico_visita') and criado_em >= desde group by 1 order by 2 desc limit 10) x),
    'como_conheceu', (select coalesce(jsonb_agg(jsonb_build_object('origem', o, 'n', n) order by n desc), '[]'::jsonb) from (
      select coalesce(como_conheceu, 'não informado') o, count(*) n from profiles where criado_em >= desde group by 1) x),
    'links_publicos', (select coalesce(jsonb_agg(jsonb_build_object('projeto', p.nome, 'n', x.n) order by x.n desc), '[]'::jsonb) from (
      select slug, count(*) n from eventos where tipo = 'publico_visita' and criado_em >= desde group by slug order by 2 desc limit 10) x
      left join projects p on p.slug = x.slug),
    'ultimos_cadastros', (select coalesce(jsonb_agg(jsonb_build_object('nome', split_part(coalesce(pf.nome, '?'), ' ', 1), 'cidade', pf.cidade, 'uf', pf.uf, 'como', pf.como_conheceu, 'em', u.created_at) order by u.created_at desc), '[]'::jsonb)
      from (select id, created_at from auth.users order by created_at desc limit 10) u left join profiles pf on pf.id = u.id)
  );
end $$;
revoke all on function public.metricas(int) from public, anon;
grant execute on function public.metricas(int) to authenticated;
