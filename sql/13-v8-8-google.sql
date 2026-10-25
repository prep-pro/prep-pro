-- Prep.pro · v8.8 · Login com Google: o nome vem de full_name/name quando a conta é criada pelo Google
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare m jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
begin
  insert into public.profiles (id, nome, celular, cep, cidade, uf, perfil_uso, como_conheceu, aceita_ofertas, termos_em)
  values (new.id, coalesce(nullif(m ->> 'nome', ''), nullif(m ->> 'full_name', ''), nullif(m ->> 'name', '')),
          nullif(m ->> 'celular', ''), nullif(m ->> 'cep', ''), nullif(m ->> 'cidade', ''), nullif(m ->> 'uf', '')::char(2),
          nullif(m ->> 'perfil_uso', ''), nullif(m ->> 'como_conheceu', ''), coalesce((m ->> 'aceita_ofertas')::boolean, false),
          case when (m ->> 'termos')::boolean then now() end);
  return new;
end $$;
