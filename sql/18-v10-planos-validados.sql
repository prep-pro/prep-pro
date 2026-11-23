-- v10 · Planos revisados com base em referências técnicas e na Resolução Contran 916/2022
-- 1) "Força e turbo": base com teste de compressão e medição no dinamômetro; ignição e sensores;
--    "Segurar a força" (embreagem/freios) ANTES do turbo; linha de óleo e acerto no dinamômetro;
--    legalização com a regra dos 10% (Anexo V item 4 x Anexo IV item 04).
-- 2) Planos próprios para Track day, Off-road, Visual/stance e Restauração (antes caíam no plano turbo).
-- 3) Cada item ganha uma explicação curta (template_items.descricao), exibida no app.

do $$
declare
  t uuid := '336a5939-de39-45db-b536-e15119ead5f5';
  s0 uuid; s1 uuid; s2 uuid; s3 uuid; sl uuid;
begin
  select id into s0 from template_stages where template_id = t and ordem = 0;
  select id into s1 from template_stages where template_id = t and ordem = 1;
  select id into s2 from template_stages where template_id = t and ordem = 2;  -- era "Turbo"
  select id into s3 from template_stages where template_id = t and ordem = 3;  -- era "Segurar a força"
  select id into sl from template_stages where template_id = t and ordem = 4;

  update templates set objetivos = array['rua','arrancada']::objetivo[] where id = t;

  -- troca a ordem: segurar a força vem antes do turbo
  update template_stages set ordem = 98 where id = s2;
  update template_stages set ordem = 2, nome = 'Stage 2 · Segurar a força' where id = s3;
  update template_stages set ordem = 3, nome = 'Stage 3 · Turbo e acerto' where id = s2;
  update template_stages set nome = 'Stage 1 · Combustível e ignição' where id = s1;

  -- Stage 0
  update template_items set ordem = 90 + ordem where stage_id = s0;
  update template_items set ordem = 1, descricao = 'Óleo, filtros, velas, correias e juntas em dia, sem vazamentos. Motor cansado não deve ganhar potência.' where stage_id = s0 and nome = 'Revisão do motor';
  update template_items set ordem = 3, descricao = 'Radiador, válvula termostática, ventoinha e mangueiras. Mais potência gera mais calor.' where stage_id = s0 and nome = 'Arrefecimento';
  update template_items set ordem = 4, nome = 'Freios e pneus em dia', descricao = 'Pastilhas, discos, fluido e pneus bons antes de qualquer ganho de potência.' where stage_id = s0 and nome = 'Embreagem';
  insert into template_items (stage_id, ordem, nome, descricao) values
    (s0, 2, 'Teste de compressão e estanqueidade', 'Mostra se anéis, válvulas e junta do cabeçote estão bons. É o que diz se o motor aguenta pressão.'),
    (s0, 5, 'Dinamômetro: medição de antes', 'Registre a potência original para comparar no final. Dá para lançar no app, na 2ª marcha.');

  -- Stage 1
  update template_items set ordem = 90 + ordem where stage_id = s1;
  update template_items set ordem = 1, descricao = 'Controla combustível e ponto de ignição com pressão positiva. A injeção original não foi feita para turbo.' where stage_id = s1 and nome = 'Injeção programável';
  update template_items set ordem = 2, descricao = 'Dimensionados para a potência que você quer, com folga. Bico no limite empobrece a mistura.' where stage_id = s1 and nome = 'Bicos de maior vazão';
  update template_items set ordem = 3, nome = 'Bomba e regulador de combustível', descricao = 'Vazão para a potência-alvo e pressão que sobe junto com o turbo (regulador 1:1).' where stage_id = s1 and nome = 'Bomba de combustível';
  update template_items set ordem = 5, nome = 'Sonda banda larga e sensores', descricao = 'Sonda wideband, sensor de pressão (MAP) e de temperatura do ar. Sem leitura da mistura não existe acerto seguro.' where stage_id = s1 and nome = 'Sonda banda larga';
  insert into template_items (stage_id, ordem, nome, descricao) values
    (s1, 4, 'Ignição: bobinas e velas', 'Velas mais frias e ignição forte para não falhar sob pressão.');

  -- Stage 2 · Segurar a força
  update template_items set ordem = 90 + ordem where stage_id = s3;
  update template_items set ordem = 1, descricao = 'Com mais torque a embreagem original patina. Dimensione para a força final.' where stage_id = s3 and nome = 'Embreagem reforçada';
  update template_items set ordem = 2, descricao = 'Mais velocidade pede mais freio: discos, pastilhas e fluido de alta temperatura.' where stage_id = s3 and nome = 'Freios maiores';
  update template_items set ordem = 3, descricao = 'Amortecedores, molas e buchas em ordem. Rebaixou? Altura livre mínima de 100 mm (Res. Contran 916, art. 8º).' where stage_id = s3 and nome = 'Suspensão';

  -- Stage 3 · Turbo e acerto
  update template_items set ordem = 90 + ordem where stage_id = s2;
  update template_items set ordem = 1, descricao = 'Turbina dimensionada para a meta, com wastegate e válvula de alívio.' where stage_id = s2 and nome = 'Kit turbo e coletor';
  update template_items set ordem = 3, descricao = 'Esfria o ar pressurizado: mais potência e menos risco de detonação.' where stage_id = s2 and nome = 'Intercooler';
  update template_items set ordem = 4, descricao = 'Saída livre depois da turbina, sem estrangular o escape.' where stage_id = s2 and nome = 'Downpipe e escape';
  update template_items set ordem = 5, descricao = 'Pressão de turbo, óleo e combustível sempre à vista.' where stage_id = s2 and nome = 'Manômetros';
  insert into template_items (stage_id, ordem, nome, descricao) values
    (s2, 2, 'Linha de óleo do turbo', 'Alimentação com óleo limpo e retorno livre para o cárter. Falta de óleo é o que mais quebra turbina.'),
    (s2, 6, 'Acerto no dinamômetro', 'Mapa feito por profissional, lendo a sonda. Compare com a medição de antes.');

  -- Legalização
  update template_items set descricao = 'Peça antes de modificar (art. 98 do CTB).' where stage_id = sl and nome = 'Autorização prévia no Detran';
  update template_items set descricao = 'Ganho de até 10% de potência: CSV emitido pela ITL. Acima de 10%, a Res. Contran 916/2022 exige homologação com CAT, bem mais difícil. Confirme no Detran do seu estado.' where stage_id = sl and nome = 'Vistoria na ITL e emissão do CSV';
  update template_items set descricao = 'O documento passa a mostrar a modificação e o número do CSV.' where stage_id = sl and nome = 'Novo CRLV com a modificação';

  -- itens novos também entram nos projetos que já usam este plano
  insert into project_items (project_id, template_item_id, status)
  select p.id, ti.id, 'lista'
  from projects p
  join template_stages ts on ts.template_id = p.template_id
  join template_items ti on ti.stage_id = ts.id
  where p.template_id = t
    and not exists (select 1 from project_items pi where pi.project_id = p.id and pi.template_item_id = ti.id);
end $$;

-- ---------- planos novos ----------
create or replace function pg_temp.novo_plano(p_nome text, p_obj text[], p_stages jsonb) returns void language plpgsql as $$
declare tid uuid; sid uuid; st jsonb; it jsonb; i int := 0; j int;
begin
  insert into templates (nome, ativo, objetivos) values (p_nome, true, p_obj::objetivo[]) returning id into tid;
  for st in select * from jsonb_array_elements(p_stages) loop
    insert into template_stages (template_id, ordem, nome, quem_faz, e_legalizacao)
      values (tid, i, st->>'nome', st->>'quem', coalesce((st->>'legal')::boolean, false)) returning id into sid;
    j := 1;
    for it in select * from jsonb_array_elements(st->'itens') loop
      insert into template_items (stage_id, ordem, nome, descricao) values (sid, j, it->>0, it->>1);
      j := j + 1;
    end loop;
    i := i + 1;
  end loop;
end $$;

select pg_temp.novo_plano('Track day', array['track'], $j$[
 {"nome":"Stage 0 · Base saudável","quem":"Mecânico","itens":[
  ["Revisão do motor","Óleo, filtros, velas e correias em dia. Pista cobra o motor no limite por muitos minutos."],
  ["Arrefecimento","Radiador, ventoinha e válvula termostática perfeitos. Superaquecimento é a falha mais comum em pista."],
  ["Fluido de freio de alta temperatura","Fluido DOT 4 ou superior, trocado. Fluido velho ferve e o pedal some."]]},
 {"nome":"Stage 1 · Freios e pneus","quem":"Preparador","itens":[
  ["Pastilhas de alta performance","Compostos que aguentam temperatura de pista."],
  ["Discos e flexíveis de freio","Discos em bom estado e flexíveis reforçados."],
  ["Pneus esportivos","Pneus de boa aderência, na medida e com calibragem de pista."]]},
 {"nome":"Stage 2 · Suspensão e chassi","quem":"Preparador","itens":[
  ["Amortecedores e molas","Coilover ou kit esportivo. Rebaixou? Altura livre mínima de 100 mm (Res. Contran 916, art. 8º)."],
  ["Barras e buchas","Barras estabilizadoras e buchas firmes reduzem a rolagem."],
  ["Alinhamento de pista","Cambagem e convergência ajustadas para curva."]]},
 {"nome":"Stage 3 · Potência e acerto","quem":"Injeção","itens":[
  ["Admissão e escape","Menos restrição na entrada e na saída de ar."],
  ["Remap ou injeção programável","Mapa ajustado para o uso em pista."],
  ["Acerto no dinamômetro","Ajuste fino com sonda e medição de antes e depois."]]},
 {"nome":"Stage 4 · Segurança","quem":"Eu mesmo","itens":[
  ["Capacete e equipamentos do evento","Siga o regulamento do autódromo ou do organizador."],
  ["Extintor","Fixo e dentro da validade."]]},
 {"nome":"Legalização · Detran + CSV","quem":"Vistoria (ITL)","legal":true,"itens":[
  ["Autorização prévia no Detran","Peça antes de modificar (art. 98 do CTB)."],
  ["Vistoria na ITL e emissão do CSV","Suspensão e potência alteradas exigem CSV. Ganho acima de 10% exige homologação (CAT)."],
  ["Novo CRLV com a modificação","O documento passa a mostrar a modificação."]]}
]$j$::jsonb);

select pg_temp.novo_plano('Off-road', array['offroad'], $j$[
 {"nome":"Stage 0 · Base saudável","quem":"Mecânico","itens":[
  ["Revisão do motor","Óleo, filtros e correias em dia; trilha exige muito em baixa rotação."],
  ["Arrefecimento","Radiador limpo e ventoinha forte para subidas lentas."],
  ["Freios","Freios em ordem antes de colocar pneus maiores e mais pesados."]]},
 {"nome":"Stage 1 · Pneus e rodas","quem":"Borracharia","itens":[
  ["Pneus AT ou MT","Escolha pelo tipo de trilha: AT para uso misto, MT para lama."],
  ["Rodas","Medida e offset corretos para não raspar."]]},
 {"nome":"Stage 2 · Suspensão e lift","quem":"Preparador","itens":[
  ["Kit de suspensão ou lift","Ganho de altura com geometria corrigida. Alteração de altura exige CSV."],
  ["Amortecedores","Curso maior e carga para trilha."],
  ["Alinhamento","Obrigatório depois do lift."]]},
 {"nome":"Stage 3 · Tração e proteção","quem":"Preparador","itens":[
  ["Bloqueio de diferencial","Tração nas duas rodas do eixo quando uma perde aderência."],
  ["Protetor de cárter","Protege motor e câmbio das pedras."],
  ["Snorkel","Ar captado no alto para travessias. Respeite a altura de vau do carro."],
  ["Guincho e pontos de reboque","Pontos de reboque reforçados e cinta. Guincho para trilhas pesadas."]]},
 {"nome":"Legalização · Detran + CSV","quem":"Vistoria (ITL)","legal":true,"itens":[
  ["Autorização prévia no Detran","Peça antes de modificar (art. 98 do CTB)."],
  ["Vistoria na ITL e emissão do CSV","Lift e pneus fora da medida original exigem CSV."],
  ["Novo CRLV com a modificação","O documento passa a mostrar a modificação."]]}
]$j$::jsonb);

select pg_temp.novo_plano('Visual e stance', array['visual'], $j$[
 {"nome":"Stage 0 · Base saudável","quem":"Mecânico","itens":[
  ["Revisão geral","Mecânica em dia antes de investir no visual."],
  ["Freios e pneus em dia","Segurança primeiro."]]},
 {"nome":"Stage 1 · Rodas e pneus","quem":"Borracharia","itens":[
  ["Rodas","Aro, tala e offset que cabem sem raspar."],
  ["Pneus na medida certa","Diâmetro total próximo do original para não alterar velocímetro."]]},
 {"nome":"Stage 2 · Suspensão","quem":"Preparador","itens":[
  ["Rosca, fixa ou a ar","Altura livre mínima de 100 mm do solo (Res. Contran 916, art. 8º)."],
  ["Alinhamento","Obrigatório depois de mexer na altura."]]},
 {"nome":"Stage 3 · Estética","quem":"Estética automotiva","itens":[
  ["Envelopamento ou pintura","Mudou a cor? Precisa de autorização e alteração no documento."],
  ["Iluminação","Só lâmpadas e faróis homologados. Xenon ou LED fora do padrão gera multa."],
  ["Interior","Bancos, volante e acabamento."]]},
 {"nome":"Legalização · Detran + CSV","quem":"Vistoria (ITL)","legal":true,"itens":[
  ["Autorização prévia no Detran","Peça antes de modificar (art. 98 do CTB)."],
  ["Vistoria na ITL e emissão do CSV","Suspensão alterada exige CSV e a altura livre anotada no documento."],
  ["Novo CRLV com a modificação","O documento passa a mostrar a modificação."]]}
]$j$::jsonb);

select pg_temp.novo_plano('Restauração', array['restauro'], $j$[
 {"nome":"Stage 0 · Diagnóstico","quem":"Mecânico","itens":[
  ["Documentação em dia","Débitos, chassi e motor conferidos antes de investir."],
  ["Avaliação de lataria e ferrugem","Define o tamanho real do trabalho de funilaria."],
  ["Avaliação mecânica","Motor, câmbio, freios e suspensão: o que recuperar e o que trocar."]]},
 {"nome":"Stage 1 · Mecânica","quem":"Mecânico","itens":[
  ["Motor","Retífica ou revisão completa, com peças originais quando possível."],
  ["Câmbio e embreagem","Revisão completa."],
  ["Freios e suspensão","Segurança em primeiro lugar."]]},
 {"nome":"Stage 2 · Funilaria e pintura","quem":"Funilaria e pintura","itens":[
  ["Funilaria","Tratamento de ferrugem e recuperação de chapas."],
  ["Pintura","Na cor original para manter a originalidade."]]},
 {"nome":"Stage 3 · Acabamento","quem":"Tapeceiro / elétrica","itens":[
  ["Interior e estofamento","Padrão de fábrica."],
  ["Elétrica","Chicote revisado: prevenir curto em carro antigo."],
  ["Cromados e borrachas","Frisos, emblemas e vedações."]]},
 {"nome":"Coleção · Placa preta","quem":"Clube credenciado","legal":true,"itens":[
  ["Certificado de veículo de coleção (CVCOL)","Carro com 30 anos ou mais e nota mínima de originalidade 80, avaliado por clube credenciado na Senatran (Res. Contran 957/2022)."],
  ["Troca para placa preta no Detran","Com o CVCOL, o Detran altera o documento para a categoria coleção."]]}
]$j$::jsonb);
