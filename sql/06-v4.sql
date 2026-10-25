-- Prep.pro · POC v4 · catálogo de carros brasileiros e nova 2ª marcha (ponto de partida)
-- Rode no SQL Editor do Supabase depois dos scripts anteriores. Pode rodar mais de uma vez.
-- Fonte das fichas: fichacompleta.com.br (ano da ficha em ano_ref). Valores de fábrica, servem de referência.

-- ---------- Catálogo: novos campos ---------------------------------
alter table car_models add column if not exists versao         text;
alter table car_models add column if not exists ano_ref        int;
alter table car_models add column if not exists cilindrada_cm3 int;
alter table car_models add column if not exists cilindros      text;
alter table car_models add column if not exists alimentacao    text;
alter table car_models add column if not exists aspiracao      text;
alter table car_models add column if not exists potencia_cv    numeric(6,1);
alter table car_models add column if not exists torque_kgfm    numeric(6,1);
alter table car_models add column if not exists tracao         text;
alter table car_models add column if not exists nota           text;

-- Ajusta as 3 bases que já existiam
update car_models set versao = null, ano_ref = 1998, cilindrada_cm3 = 4299, cilindros = 'V6', alimentacao = 'Injeção monoponto', aspiracao = 'Aspirado',
  potencia_cv = 180, torque_kgfm = 34.7, tracao = 'Traseira', nota = 'Torque de sobra e muita peça do V6 americano.'
where marca = 'Chevrolet' and modelo = 'S10' and motor = '4.3 V6';

update car_models set motor = '1.8 AP', ano_ref = 1994, cilindrada_cm3 = 1781, cilindros = '4 em linha', alimentacao = 'Carburador', aspiracao = 'Aspirado',
  potencia_cv = 96, torque_kgfm = 14.9, tracao = 'Dianteira', nota = 'Motor AP: o mais preparado do Brasil, peça em todo lugar.'
where marca = 'Volkswagen' and modelo = 'Gol' and motor = 'AP';

update car_models set motor = '4.1 6 cil.', versao = 'Comodoro', ano_ref = 1989, cilindrada_cm3 = 4093, cilindros = '6 em linha', alimentacao = 'Carburador', aspiracao = 'Aspirado',
  potencia_cv = 118, torque_kgfm = 28, tracao = 'Traseira', nota = 'O seis-cilindros que virou lenda na arrancada.'
where marca = 'Chevrolet' and modelo = 'Opala' and motor = '4.1 6 cilindros';

-- Novas bases
insert into car_models (marca, modelo, versao, motor, tipo, ano_ref, cilindrada_cm3, cilindros, alimentacao, aspiracao, potencia_cv, torque_kgfm, tracao, nota)
select v.* from (values
  ('Chevrolet','S10',      null,       '2.2',            'pickup'::tipo_carro, 2000, 2198, '4 em linha', 'Injeção multiponto', 'Aspirado', 113.0, 19.2, 'Traseira',  'Base barata para quem quer picape leve.'),
  ('Chevrolet','S10',      null,       '2.8 Turbo diesel','pickup',            2002, 2796, '4 em linha', 'Injeção direta',     'Turbo',    132.0, 34.0, 'Traseira',  'Diesel com turbo de fábrica, aceita bem remap.'),
  ('Chevrolet','Opala',    null,       '2.5 4 cil.',     'sedan',              1975, 2471, '4 em linha', 'Carburador',         'Aspirado', 90.0,  18.0, 'Traseira',  'Tração traseira e espaço para trocar de motor.'),
  ('Chevrolet','Opala',    'SS',       '4.1 250-S',      'sedan',              1976, 4093, '6 em linha', 'Carburador',         'Aspirado', 171.0, 32.5, 'Traseira',  'O 250-S de fábrica: o Opala mais forte.'),
  ('Chevrolet','Chevette', null,       '1.6',            'sedan',              1983, 1599, '4 em linha', 'Carburador',         'Aspirado', 72.0,  12.4, 'Traseira',  'Leve e de tração traseira: clássico do drift raiz.'),
  ('Chevrolet','Corsa',    'Wind',     '1.0',            'hatch',              1994, 999,  '4 em linha', 'Injeção monoponto',  'Aspirado', 50.0,  7.8,  'Dianteira', 'Leve e barato; muito usado com turbo.'),
  ('Chevrolet','Corsa',    'GSi',      '1.6 16V',        'hatch',              1995, 1598, '4 em linha', 'Injeção multiponto', 'Aspirado', 108.0, 14.8, 'Dianteira', 'Esportivo de fábrica, raro e valorizado.'),
  ('Chevrolet','Kadett',   'GSi',      '2.0',            'hatch',              1995, 1998, '4 em linha', 'Injeção multiponto', 'Aspirado', 121.0, 17.6, 'Dianteira', 'Motor 2.0 Família II, forte para turbo.'),
  ('Chevrolet','Monza',    'Classic',  '2.0',            'sedan',              1992, 1998, '4 em linha', 'Injeção multiponto', 'Aspirado', 121.0, 17.8, 'Dianteira', 'Mesmo 2.0 do Kadett, barato de achar.'),
  ('Chevrolet','Vectra',   'GSi',      '2.0 16V',        'sedan',              1995, 1998, '4 em linha', 'Injeção multiponto', 'Aspirado', 150.0, 20.0, 'Dianteira', '16 válvulas de fábrica, ótimo de giro.'),
  ('Chevrolet','Omega',    'CD',       '4.1',            'sedan',              1995, 4093, '6 em linha', 'Injeção multiponto', 'Aspirado', 168.0, 29.1, 'Traseira',  'Seis cilindros com injeção e tração traseira.'),
  ('Chevrolet','Celta',    null,       '1.0',            'hatch',              2001, 999,  '4 em linha', 'Injeção multiponto', 'Aspirado', 60.0,  8.3,  'Dianteira', 'Popular leve; muito comum em projeto turbo 1.0.'),
  ('Volkswagen','Gol',     null,       '1.8 AP injeção', 'hatch',              2001, 1781, '4 em linha', 'Injeção multiponto', 'Aspirado', 99.0,  15.5, 'Dianteira', 'AP já com injeção: facilita a injeção programável.'),
  ('Volkswagen','Gol',     'GTi',      '2.0 AP',         'hatch',              1993, 1984, '4 em linha', 'Injeção multiponto', 'Aspirado', 112.0, 17.5, 'Dianteira', 'O primeiro injetado do Brasil, ícone dos anos 90.'),
  ('Volkswagen','Gol',     'Turbo',    '1.0 16V',        'hatch',              2002, 999,  '4 em linha', 'Injeção multiponto', 'Turbo',    112.0, 15.8, 'Dianteira', 'Turbo de fábrica no motor 1.0 16V.'),
  ('Volkswagen','Voyage',  null,       '1.8 AP',         'sedan',              1993, 1781, '4 em linha', 'Carburador',         'Aspirado', 95.0,  15.6, 'Dianteira', 'Sedã do Gol, mesma mecânica AP.'),
  ('Volkswagen','Saveiro', null,       '1.8 AP',         'pickup',             2001, 1781, '4 em linha', 'Injeção multiponto', 'Aspirado', 99.0,  15.5, 'Dianteira', 'Picape leve com motor AP.'),
  ('Volkswagen','Santana', null,       '2.0 AP',         'sedan',              1995, 1984, '4 em linha', 'Injeção multiponto', 'Aspirado', 112.0, 17.6, 'Dianteira', 'AP 2.0 em carro maior e mais barato que o GTi.'),
  ('Volkswagen','Fusca',   null,       '1600',           'sedan',              1996, 1584, '4 boxer',    'Carburador',         'Aspirado', 58.7,  11.9, 'Traseira',  'Motor a ar boxer: cultura própria de preparação.'),
  ('Volkswagen','Golf',    'GTI',      '1.8 Turbo 20V',  'hatch',              2003, 1781, '4 em linha', 'Injeção multiponto', 'Turbo',    180.0, 24.0, 'Dianteira', 'Turbo de fábrica que aceita muito remap.'),
  ('Fiat','Uno',           'Mille',    '1.0',            'hatch',              1990, 994,  '4 em linha', 'Carburador',         'Aspirado', 48.5,  7.4,  'Dianteira', 'Leve, barato e com muita peça.'),
  ('Fiat','Uno',           'Turbo',    '1.4 i.e.',       'hatch',              1994, 1372, '4 em linha', 'Injeção multiponto', 'Turbo',    118.0, 17.5, 'Dianteira', 'O primeiro turbo de série nacional: cultuado.'),
  ('Fiat','Palio',         'Fire',     '1.0',            'hatch',              2005, 999,  '4 em linha', 'Injeção multiponto', 'Aspirado', 66.0,  9.2,  'Dianteira', 'Popular comum, base barata para começar.'),
  ('Fiat','Tempra',        'Turbo',    '2.0 i.e.',       'sedan',              1996, 1995, '4 em linha', 'Injeção multiponto', 'Turbo',    165.0, 26.5, 'Dianteira', 'Sedã turbo de fábrica dos anos 90.'),
  ('Fiat','Marea',         'Turbo',    '2.0 20V',        'sedan',              2000, 1997, '5 em linha', 'Injeção multiponto', 'Turbo',    182.0, 27.0, 'Dianteira', 'Cinco cilindros turbo: famoso pelo ronco.'),
  ('Ford','Maverick',      'GT',       '4.9 V8 302',     'sedan',              1976, 4942, 'V8',         'Carburador',         'Aspirado', 197.0, 39.5, 'Traseira',  'O V8 nacional dos anos 70.'),
  ('Ford','Escort',        'XR3',      '2.0 AP',         'hatch',              1993, 1984, '4 em linha', 'Injeção multiponto', 'Aspirado', 116.0, 17.7, 'Dianteira', 'Usava o motor AP da VW (época Autolatina).'),
  ('Ford','Escort',        'XR3',      '1.8 AP',         'hatch',              1991, 1781, '4 em linha', 'Carburador',         'Aspirado', 99.0,  16.0, 'Dianteira', 'XR3 com AP 1.8 a carburador.')
) as v(marca, modelo, versao, motor, tipo, ano_ref, cilindrada_cm3, cilindros, alimentacao, aspiracao, potencia_cv, torque_kgfm, tracao, nota)
where not exists (
  select 1 from car_models c
  where c.marca = v.marca and c.modelo = v.modelo and coalesce(c.versao, '') = coalesce(v.versao, '') and c.motor = v.motor
);

-- ---------- Nova 2ª marcha: ficha, o que já tenho, itens automáticos ----------
alter table projects      add column if not exists ficha    jsonb not null default '{}'::jsonb;  -- ano, km, cor, câmbio, potência hoje
alter table project_items add column if not exists ja_tenho text check (ja_tenho in ('guardado', 'no_carro'));
alter table project_items add column if not exists origem   text;  -- 'diag:<item>' quando criado pela checagem da base
