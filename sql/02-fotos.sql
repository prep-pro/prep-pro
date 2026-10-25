-- Prep.pro · POC · pasta de fotos do diário (rode depois do prep-pro-schema-v1.sql)
-- Cada usuário só envia e vê fotos dentro da própria pasta.

insert into storage.buckets (id, name, public)
values ('diario', 'diario', false)
on conflict (id) do nothing;

create policy "diario: enviar na propria pasta" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'diario' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "diario: ver propria pasta" on storage.objects
  for select to authenticated
  using (bucket_id = 'diario' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "diario: apagar propria pasta" on storage.objects
  for delete to authenticated
  using (bucket_id = 'diario' and (storage.foldername(name))[1] = auth.uid()::text);
