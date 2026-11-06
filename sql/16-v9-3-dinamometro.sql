-- Prep.pro · v9.3 · Medições no dinamômetro (comparar antes e depois)
create table if not exists project_dyno (
  id            uuid primary key default gen_random_uuid(),
  project_id    uuid not null references projects(id) on delete cascade,
  data          date not null default current_date,
  potencia_cv   numeric(7,1),
  torque_kgfm   numeric(6,1),
  rpm_potencia  int,
  rpm_torque    int,
  medida        text not null default 'roda' check (medida in ('roda', 'motor')),
  local         text,
  combustivel   text,
  obs           text,
  foto          text,
  criado_em     timestamptz not null default now()
);
create index if not exists project_dyno_project_idx on project_dyno (project_id);
alter table project_dyno enable row level security;
drop policy if exists "dyno do dono" on project_dyno;
create policy "dyno do dono" on project_dyno for all to authenticated
  using (exists (select 1 from projects p where p.id = project_id and p.user_id = auth.uid()))
  with check (exists (select 1 from projects p where p.id = project_id and p.user_id = auth.uid()));
