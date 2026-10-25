-- Prep.pro · v8.5 · Catálogo maior (picapes, importados e esportivos) e pedidos de carro que não está na lista
-- Potência e torque só onde a ficha é conhecida; os demais ficam em branco até conferirmos.
insert into car_models (marca, modelo, versao, motor, tipo, ano_ref, cilindros, aspiracao, potencia_cv, torque_kgfm, tracao, nota)
select v.* from (values
  ('RAM','1500','Classic Laramie','5.7 V8 Hemi','pickup'::tipo_carro, 2023,'V8','Aspirado',400.0,56.7,'4x4','Dodge Ram 1500: V8 Hemi, muita peça americana.'),
  ('RAM','1500','Rebel','3.0 Hurricane biturbo','pickup', 2025,'6 em linha','Biturbo',null,null,'4x4','Dodge Ram 1500 nova geração, seis-cilindros biturbo.'),
  ('RAM','2500','Laramie','6.7 Cummins turbodiesel','pickup', 2025,'6 em linha','Turbo',436.0,149.0,'4x4','Dodge Ram 2500 com o Cummins 6.7: rei do torque.'),
  ('RAM','3500','Laramie','6.7 Cummins turbodiesel','pickup', 2025,'6 em linha','Turbo',436.0,149.0,'4x4','Dodge Ram 3500, mesmo Cummins da 2500.'),
  ('RAM','Rampage','R/T','2.0 Hurricane4 turbo','pickup', 2024,'4 em linha','Turbo',272.0,40.8,'4x4','Picape média com motor turbo a gasolina.'),
  ('RAM','Rampage','Laramie','2.2 turbodiesel','pickup', 2024,'4 em linha','Turbo',200.0,45.9,'4x4','Picape média diesel.'),
  ('Dodge','Ram 2500','SLT','5.9 Cummins turbodiesel','pickup', 2008,'6 em linha','Turbo',null,null,'4x4','A Dodge Ram antiga com o Cummins 5.9, clássica de preparação diesel.'),
  ('Dodge','Dakota','Sport','3.9 V6','pickup', 1999,'V6','Aspirado',null,null,'Traseira','Picape média nacional dos anos 90.'),
  ('Dodge','Dakota','R/T','5.2 V8','pickup', 2000,'V8','Aspirado',null,null,'Traseira','Dakota com V8 Magnum.'),
  ('Toyota','Hilux','SRX','2.8 turbodiesel','pickup', 2021,'4 em linha','Turbo',204.0,50.9,'4x4','Diesel robusto, aceita bem remap.'),
  ('Toyota','Hilux','SRV','3.0 turbodiesel','pickup', 2010,'4 em linha','Turbo',null,null,'4x4','Geração antiga, motor 1KD muito usado em preparação.'),
  ('Toyota','SW4','SRX','2.8 turbodiesel','suv', 2021,'4 em linha','Turbo',204.0,50.9,'4x4','SUV da Hilux, mesmo motor.'),
  ('Toyota','Corolla','XEi','2.0','sedan', 2020,'4 em linha','Aspirado',null,null,'Dianteira','Sedã confiável, base para preparação leve.'),
  ('Ford','Ranger','Limited','3.0 V6 turbodiesel','pickup', 2024,'V6','Turbo',250.0,61.2,'4x4','Nova Ranger com V6 diesel.'),
  ('Ford','Ranger','XLT','3.2 turbodiesel','pickup', 2019,'5 em linha','Turbo',200.0,47.9,'4x4','Cinco cilindros diesel, muito usado com remap.'),
  ('Ford','Maverick','Lariat','2.0 EcoBoost','pickup', 2022,'4 em linha','Turbo',253.0,38.0,'4x4','Picape com motor turbo a gasolina.'),
  ('Ford','F-1000',null,'3.9 turbodiesel','pickup', 1995,'4 em linha','Turbo',null,null,'Traseira','Clássica nacional, muito usada com motor diesel preparado.'),
  ('Ford','F-250','XLT','4.2 turbodiesel','pickup', 2005,'4 em linha','Turbo',null,null,'Traseira','Picape grande nacional.'),
  ('Ford','Mustang','GT','5.0 V8 Coyote','outro', 2018,'V8','Aspirado',466.0,56.7,'Traseira','O V8 Coyote, base forte para compressor.'),
  ('Ford','Fiesta',null,'1.6','hatch', 2014,'4 em linha','Aspirado',null,null,'Dianteira','Hatch comum, base barata.'),
  ('Ford','Ka',null,'1.0 3 cil.','hatch', 2016,'3 em linha','Aspirado',null,null,'Dianteira','Popular de três cilindros.'),
  ('Chevrolet','S10','LTZ','2.8 turbodiesel','pickup', 2018,'4 em linha','Turbo',200.0,51.0,'4x4','Diesel Duramax, aceita bem remap.'),
  ('Chevrolet','Montana',null,'1.2 turbo','pickup', 2023,'3 em linha','Turbo',133.0,21.4,'Dianteira','Picape compacta turbo.'),
  ('Chevrolet','Silverado','High Country','5.3 V8','pickup', 2023,'V8','Aspirado',null,null,'4x4','Picape grande americana.'),
  ('Chevrolet','Onix',null,'1.0 turbo','hatch', 2020,'3 em linha','Turbo',116.0,16.8,'Dianteira','Turbo de fábrica, aceita remap.'),
  ('Chevrolet','Cruze',null,'1.4 turbo','sedan', 2018,'4 em linha','Turbo',153.0,24.5,'Dianteira','Sedã turbo, bom para remap.'),
  ('Chevrolet','Camaro','SS','6.2 V8','outro', 2017,'V8','Aspirado',461.0,62.9,'Traseira','V8 LT1, esportivo americano.'),
  ('Volkswagen','Amarok','Highline','3.0 V6 turbodiesel','pickup', 2020,'V6','Turbo',258.0,59.1,'4x4','V6 diesel, uma das picapes mais fortes do segmento.'),
  ('Volkswagen','Polo','GTS','1.4 TSI','hatch', 2020,'4 em linha','Turbo',150.0,25.5,'Dianteira','Hatch esportivo turbo.'),
  ('Volkswagen','Golf','GTI','2.0 TSI','hatch', 2017,'4 em linha','Turbo',230.0,35.7,'Dianteira','EA888: dos motores mais preparados do mundo.'),
  ('Volkswagen','Jetta','GLI','2.0 TSI','sedan', 2019,'4 em linha','Turbo',230.0,35.7,'Dianteira','Mesmo EA888 do Golf GTI.'),
  ('Volkswagen','up!','TSI','1.0 TSI','hatch', 2017,'3 em linha','Turbo',105.0,16.8,'Dianteira','Pequeno turbo, febre de remap.'),
  ('Fiat','Toro','Volcano','2.0 turbodiesel','pickup', 2018,'4 em linha','Turbo',170.0,35.7,'4x4','Picape média diesel.'),
  ('Fiat','Toro','Ultra','1.3 turbo','pickup', 2022,'4 em linha','Turbo',185.0,27.5,'Dianteira','Motor T270 turbo flex.'),
  ('Fiat','Strada',null,'1.4','pickup', 2018,'4 em linha','Aspirado',null,null,'Dianteira','Picape compacta mais vendida.'),
  ('Fiat','Pulse','Abarth','1.3 turbo','suv', 2023,'4 em linha','Turbo',185.0,27.5,'Dianteira','SUV compacto esportivo.'),
  ('Fiat','147',null,'1.3','hatch', 1980,'4 em linha','Carburador',null,null,'Dianteira','Clássico nacional.'),
  ('Jeep','Compass','Longitude','2.0 turbodiesel','suv', 2018,'4 em linha','Turbo',170.0,35.7,'4x4','SUV diesel nacional.'),
  ('Jeep','Renegade',null,'1.3 turbo','suv', 2022,'4 em linha','Turbo',185.0,27.5,'Dianteira','Motor T270 turbo flex.'),
  ('Jeep','Wrangler','Rubicon','2.0 turbo','suv', 2022,'4 em linha','Turbo',null,null,'4x4','Off-road raiz.'),
  ('Mitsubishi','L200','Triton','2.4 turbodiesel','pickup', 2020,'4 em linha','Turbo',null,null,'4x4','Picape média diesel.'),
  ('Mitsubishi','Pajero','Full','3.2 turbodiesel','suv', 2015,'4 em linha','Turbo',null,null,'4x4','SUV off-road diesel.'),
  ('Mitsubishi','Lancer','Evolution X','2.0 turbo','sedan', 2010,'4 em linha','Turbo',null,null,'4x4','Ícone dos rallys, motor 4B11 turbo.'),
  ('Nissan','Frontier','Attack','2.3 biturbo diesel','pickup', 2020,'4 em linha','Biturbo',190.0,45.9,'4x4','Picape média diesel biturbo.'),
  ('Honda','Civic','Si','1.5 turbo','sedan', 2018,'4 em linha','Turbo',null,null,'Dianteira','Civic esportivo turbo.'),
  ('Honda','Civic',null,'2.0','sedan', 2014,'4 em linha','Aspirado',null,null,'Dianteira','Base comum, muito usada com turbo.'),
  ('Honda','Fit',null,'1.5','hatch', 2015,'4 em linha','Aspirado',null,null,'Dianteira','Compacto confiável.'),
  ('Hyundai','HB20',null,'1.0 turbo','hatch', 2020,'3 em linha','Turbo',120.0,17.5,'Dianteira','Turbo de fábrica.'),
  ('Hyundai','Creta',null,'1.0 turbo','suv', 2022,'3 em linha','Turbo',120.0,17.5,'Dianteira','SUV compacto turbo.'),
  ('Renault','Sandero','RS','2.0','hatch', 2016,'4 em linha','Aspirado',150.0,20.9,'Dianteira','Hatch esportivo nacional.'),
  ('Peugeot','208','GT','1.0 turbo','hatch', 2024,'3 em linha','Turbo',null,null,'Dianteira','Hatch turbo.'),
  ('Subaru','Impreza','WRX STI','2.5 turbo boxer','sedan', 2014,'4 boxer','Turbo',null,null,'4x4','Boxer turbo e tração integral.')
) as v(marca, modelo, versao, motor, tipo, ano_ref, cilindros, aspiracao, potencia_cv, torque_kgfm, tracao, nota)
where not exists (
  select 1 from car_models c
  where c.marca = v.marca and c.modelo = v.modelo and coalesce(c.versao, '') = coalesce(v.versao, '') and c.motor = v.motor
);

-- Quando o carro não está na lista, guardamos o pedido para incluir depois
create table if not exists car_sugestoes (
  id         bigint generated always as identity primary key,
  texto      text not null,
  user_id    uuid references profiles(id) on delete set null,
  criado_em  timestamptz not null default now()
);
alter table car_sugestoes enable row level security;
drop policy if exists "pedir carro" on car_sugestoes;
create policy "pedir carro" on car_sugestoes for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "admin ve pedidos" on car_sugestoes;
create policy "admin ve pedidos" on car_sugestoes for select to authenticated using (public.is_admin());
