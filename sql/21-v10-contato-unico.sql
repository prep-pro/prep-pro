-- v10 · o filtro de contato repetido precisa enxergar os contatos anteriores (a RLS esconde do próprio usuário)
create or replace function public.contato_unico() returns trigger language plpgsql security definer set search_path = public as $$
begin
  if exists (select 1 from preparador_contatos c where c.preparador_id = new.preparador_id and c.user_id = new.user_id
             and c.tipo = new.tipo and c.criado_em > now() - interval '24 hours') then
    return null;
  end if;
  return new;
end $$;
revoke all on function public.contato_unico() from public, anon, authenticated;
