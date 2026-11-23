-- v10 · Compartilhar projeto (link público opcional) + endurecimento do cadastro de preparadores

-- ---------- Projeto público ----------
alter table projects add column if not exists publico boolean not null default false;
alter table projects add column if not exists publico_valores boolean not null default false;
alter table projects add column if not exists slug text unique;

-- Gera o código curto do link na primeira vez que o dono tornar público
create or replace function public.projeto_slug() returns trigger language plpgsql as $$
begin
  if new.publico and new.slug is null then
    loop
      new.slug := substr(replace(gen_random_uuid()::text, '-', ''), 1, 10);
      exit when not exists (select 1 from projects where slug = new.slug);
    end loop;
  end if;
  return new;
end $$;
drop trigger if exists projeto_slug on projects;
create trigger projeto_slug before insert or update of publico on projects for each row execute function public.projeto_slug();

-- Leitura pública: só o que o dono liberou. Sem e-mail, celular, cidade, caixinha ou fornecedores.
create or replace function public.projeto_publico(p_slug text) returns jsonb
language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'nome', p.nome,
    'objetivo', p.objetivo,
    'marcha', p.marcha,
    'dono', split_part(coalesce(pf.nome, 'Um entusiasta'), ' ', 1),
    'carro', case when c.id is null then null else concat_ws(' ', c.marca, c.modelo, c.versao, c.motor) end,
    'tipo', c.tipo,
    'ano', p.ficha->>'ano',
    'cv_fabrica', c.potencia_cv,
    'atualizado_em', p.atualizado_em,
    'stages', (select coalesce(jsonb_agg(jsonb_build_object(
        'nome', s.nome, 'legal', s.e_legalizacao,
        'itens', (select coalesce(jsonb_agg(jsonb_build_object('nome', coalesce(pi.nome, ti.nome), 'status', pi.status) order by ti.ordem nulls last), '[]'::jsonb)
                  from project_items pi left join template_items ti on ti.id = pi.template_item_id
                  where pi.project_id = p.id and coalesce(ti.stage_id, pi.stage_id) = s.id)
      ) order by s.ordem), '[]'::jsonb) from template_stages s where s.template_id = p.template_id),
    'dyno', (select coalesce(jsonb_agg(jsonb_build_object('data', d.data, 'cv', d.potencia_cv, 'kgfm', d.torque_kgfm, 'medida', d.medida) order by d.data), '[]'::jsonb)
             from project_dyno d where d.project_id = p.id),
    'investido', case when p.publico_valores then (select coalesce(sum(e.valor_realizado), 0) from project_expenses e where e.project_id = p.id) end,
    'orcamento', case when p.publico_valores then p.orcamento_total end
  )
  from projects p
  left join car_models c on c.id = p.car_model_id
  left join profiles pf on pf.id = p.user_id
  where p.slug = p_slug and p.publico
$$;
revoke all on function public.projeto_publico(text) from public;
grant execute on function public.projeto_publico(text) to anon, authenticated;

-- ---------- Preparadores ----------
alter table preparadores add column if not exists verificado boolean not null default false;
alter table preparadores add column if not exists bloqueado boolean not null default false;

-- tamanho máximo dos campos (evita abuso e quebra de layout)
alter table preparadores drop constraint if exists prep_tamanhos;
alter table preparadores add constraint prep_tamanhos check (
  char_length(nome_oficina) between 2 and 80 and char_length(cidade) <= 80
  and char_length(coalesce(descricao, '')) <= 400 and char_length(coalesce(instagram, '')) <= 80
  and char_length(coalesce(whatsapp, '')) <= 25 and coalesce(array_length(especialidades, 1), 0) <= 12) not valid;

-- só o admin mexe em destaque, verificado e bloqueado
create or replace function public.preparador_protege_destaque() returns trigger language plpgsql as $$
begin
  if not public.is_admin() and coalesce(auth.role(), '') <> 'service_role' then
    if tg_op = 'INSERT' then
      new.destaque_ate := null; new.verificado := false; new.bloqueado := false;
    else
      new.destaque_ate := old.destaque_ate; new.verificado := old.verificado; new.bloqueado := old.bloqueado;
    end if;
  end if;
  new.atualizado_em := now();
  return new;
end $$;

-- bloqueado não aparece para ninguém além do próprio e do admin
drop policy if exists "preparadores leitura" on preparadores;
create policy "preparadores leitura" on preparadores for select to authenticated
  using ((ativo and not bloqueado) or user_id = (select auth.uid()) or (select public.is_admin()));

create index if not exists preparadores_uf_idx on preparadores (uf) where ativo and not bloqueado;

-- contato repetido (mesma pessoa, mesmo preparador, mesmo tipo) em 24 h conta uma vez só
create or replace function public.contato_unico() returns trigger language plpgsql as $$
begin
  if exists (select 1 from preparador_contatos c where c.preparador_id = new.preparador_id and c.user_id = new.user_id
             and c.tipo = new.tipo and c.criado_em > now() - interval '24 hours') then
    return null;
  end if;
  return new;
end $$;
drop trigger if exists contato_unico on preparador_contatos;
create trigger contato_unico before insert on preparador_contatos for each row execute function public.contato_unico();
create index if not exists prep_contatos_dedupe_idx on preparador_contatos (preparador_id, user_id, tipo, criado_em desc);
