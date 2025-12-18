-- ========================================
-- QUERIES ÚTEIS - Análise de Vendas Perdidas
-- ========================================

-- ========================================
-- 1. ESTATÍSTICAS GERAIS
-- ========================================

-- Total de vendas perdidas
SELECT COUNT(*) as total_vendas_perdidas
FROM vendas_perdidas
WHERE ativo = true;

-- Valor total perdido
SELECT
  COUNT(*) as total_vendas,
  SUM(valor_final) as valor_total_perdido,
  ROUND(AVG(valor_final), 2) as ticket_medio,
  MIN(valor_final) as menor_valor,
  MAX(valor_final) as maior_valor
FROM vendas_perdidas
WHERE ativo = true;

-- Distribuição por mês
SELECT
  TO_CHAR(data_perda, 'YYYY-MM') as mes,
  COUNT(*) as quantidade,
  SUM(valor_final) as valor_total,
  ROUND(AVG(valor_final), 2) as ticket_medio
FROM vendas_perdidas
WHERE ativo = true
GROUP BY TO_CHAR(data_perda, 'YYYY-MM')
ORDER BY mes DESC;

-- ========================================
-- 2. ANÁLISE POR MOTIVO DE PERDA
-- ========================================

-- Top motivos de perda
SELECT
  motivo_perda_nome,
  COUNT(*) as quantidade,
  ROUND((COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER ()) * 100, 2) as percentual,
  SUM(valor_final) as valor_total,
  ROUND(AVG(valor_final), 2) as ticket_medio
FROM vendas_perdidas
WHERE
  ativo = true
  AND motivo_perda_nome IS NOT NULL
GROUP BY motivo_perda_nome
ORDER BY quantidade DESC;

-- Vendas perdidas por "Preço alto"
SELECT
  paciente_nome,
  paciente_celular,
  valor_final,
  data_perda,
  EXTRACT(DAY FROM (NOW() - data_perda)) as dias_desde_perda
FROM vendas_perdidas
WHERE
  motivo_perda_nome ILIKE '%preço%'
  AND ativo = true
  AND status_recuperacao = 'pendente'
ORDER BY valor_final DESC;

-- ========================================
-- 3. ANÁLISE POR PROFISSIONAL
-- ========================================

-- Ranking de profissionais por vendas perdidas
SELECT
  profissional_nome,
  COUNT(*) as total_perdas,
  SUM(valor_final) as valor_total_perdido,
  ROUND(AVG(valor_final), 2) as ticket_medio
FROM vendas_perdidas
WHERE
  ativo = true
  AND profissional_nome IS NOT NULL
GROUP BY profissional_nome
ORDER BY total_perdas DESC;

-- ========================================
-- 4. ANÁLISE POR ESPECIALIDADE
-- ========================================

-- Perdas por especialidade
SELECT
  especialidade_nome,
  COUNT(*) as quantidade,
  SUM(valor_final) as valor_total,
  ROUND(AVG(valor_final), 2) as ticket_medio
FROM vendas_perdidas
WHERE
  ativo = true
  AND especialidade_nome IS NOT NULL
GROUP BY especialidade_nome
ORDER BY valor_total DESC;

-- ========================================
-- 5. ANÁLISE DE RECUPERAÇÃO
-- ========================================

-- Dashboard de recuperação
SELECT
  status_recuperacao,
  COUNT(*) as total,
  ROUND((COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER ()) * 100, 2) as percentual,
  SUM(valor_final) as valor_total,
  ROUND(AVG(valor_final), 2) as ticket_medio
FROM vendas_perdidas
WHERE ativo = true
GROUP BY status_recuperacao
ORDER BY total DESC;

-- Taxa de conversão
SELECT
  ROUND(
    (COUNT(*) FILTER (WHERE status_recuperacao = 'recuperado')::NUMERIC /
    COUNT(*)) * 100,
    2
  ) as taxa_conversao_pct
FROM vendas_perdidas
WHERE ativo = true;

-- Vendas recuperadas
SELECT
  paciente_nome,
  valor_final,
  data_perda,
  data_ultimo_contato,
  total_tentativas_recuperacao,
  observacao_recuperacao
FROM vendas_perdidas
WHERE
  status_recuperacao = 'recuperado'
  AND ativo = true
ORDER BY data_ultimo_contato DESC;

-- ========================================
-- 6. CANDIDATOS PARA RECUPERAÇÃO
-- ========================================

-- Vendas perdidas elegíveis para recuperação
-- Critérios:
-- - Perda entre 30 e 90 dias
-- - Valor > R$ 500
-- - Celular válido
-- - Sem tentativa anterior
SELECT
  orcamento_id,
  paciente_nome,
  paciente_celular,
  valor_final,
  data_perda,
  EXTRACT(DAY FROM (NOW() - data_perda)) as dias_desde_perda,
  motivo_perda_nome,
  procedimentos_resumo
FROM vendas_perdidas
WHERE
  ativo = true
  AND status_recuperacao = 'pendente'
  AND paciente_celular IS NOT NULL
  AND valor_final >= 500
  AND data_perda BETWEEN (NOW() - INTERVAL '90 days') AND (NOW() - INTERVAL '30 days')
  AND total_tentativas_recuperacao = 0
ORDER BY valor_final DESC
LIMIT 20;

-- ========================================
-- 7. ANÁLISE DE PROCEDIMENTOS
-- ========================================

-- Procedimentos mais perdidos
SELECT
  proc->>'nome' as procedimento,
  COUNT(*) as vezes_perdido,
  ROUND(AVG((proc->>'valor_final')::NUMERIC), 2) as valor_medio
FROM
  vendas_perdidas,
  jsonb_array_elements(procedimentos) as proc
WHERE ativo = true
GROUP BY proc->>'nome'
ORDER BY vezes_perdido DESC
LIMIT 20;

-- Vendas com mais de 3 procedimentos
SELECT
  orcamento_id,
  paciente_nome,
  total_procedimentos,
  valor_final,
  procedimentos_resumo
FROM vendas_perdidas
WHERE
  ativo = true
  AND total_procedimentos > 3
ORDER BY total_procedimentos DESC;

-- ========================================
-- 8. ANÁLISE GEOGRÁFICA
-- ========================================

-- Perdas por estado
SELECT
  paciente_estado,
  COUNT(*) as quantidade,
  SUM(valor_final) as valor_total,
  ROUND(AVG(valor_final), 2) as ticket_medio
FROM vendas_perdidas
WHERE
  ativo = true
  AND paciente_estado IS NOT NULL
GROUP BY paciente_estado
ORDER BY quantidade DESC;

-- Perdas por cidade
SELECT
  paciente_cidade,
  paciente_estado,
  COUNT(*) as quantidade,
  SUM(valor_final) as valor_total
FROM vendas_perdidas
WHERE
  ativo = true
  AND paciente_cidade IS NOT NULL
GROUP BY paciente_cidade, paciente_estado
ORDER BY quantidade DESC
LIMIT 20;

-- ========================================
-- 9. ANÁLISE TEMPORAL
-- ========================================

-- Tempo médio entre orçamento e perda
SELECT
  ROUND(AVG(EXTRACT(EPOCH FROM (data_perda - data_orcamento)) / 86400), 2) as dias_medio
FROM vendas_perdidas
WHERE
  ativo = true
  AND data_perda IS NOT NULL
  AND data_orcamento IS NOT NULL;

-- Perdas por dia da semana
SELECT
  TO_CHAR(data_perda, 'Day') as dia_semana,
  COUNT(*) as quantidade,
  SUM(valor_final) as valor_total
FROM vendas_perdidas
WHERE ativo = true
GROUP BY TO_CHAR(data_perda, 'Day'), EXTRACT(DOW FROM data_perda)
ORDER BY EXTRACT(DOW FROM data_perda);

-- Perdas por horário
SELECT
  EXTRACT(HOUR FROM data_perda) as hora,
  COUNT(*) as quantidade
FROM vendas_perdidas
WHERE ativo = true
GROUP BY EXTRACT(HOUR FROM data_perda)
ORDER BY hora;

-- ========================================
-- 10. ANÁLISE DE PAGAMENTO
-- ========================================

-- Forma de pagamento mais comum
SELECT
  forma_pagamento,
  COUNT(*) as quantidade,
  ROUND(AVG(valor_final), 2) as ticket_medio
FROM vendas_perdidas
WHERE
  ativo = true
  AND forma_pagamento IS NOT NULL
GROUP BY forma_pagamento
ORDER BY quantidade DESC;

-- Vendas parceladas vs à vista
SELECT
  CASE
    WHEN numero_parcelas <= 1 THEN 'À Vista'
    WHEN numero_parcelas BETWEEN 2 AND 6 THEN '2-6x'
    WHEN numero_parcelas BETWEEN 7 AND 12 THEN '7-12x'
    ELSE '12+x'
  END as tipo_parcelamento,
  COUNT(*) as quantidade,
  ROUND(AVG(valor_final), 2) as ticket_medio
FROM vendas_perdidas
WHERE ativo = true
GROUP BY
  CASE
    WHEN numero_parcelas <= 1 THEN 'À Vista'
    WHEN numero_parcelas BETWEEN 2 AND 6 THEN '2-6x'
    WHEN numero_parcelas BETWEEN 7 AND 12 THEN '7-12x'
    ELSE '12+x'
  END
ORDER BY quantidade DESC;

-- ========================================
-- 11. ALERTAS E AÇÕES
-- ========================================

-- Vendas de alto valor sem tentativa (ALERTA)
SELECT
  orcamento_id,
  paciente_nome,
  paciente_celular,
  valor_final,
  data_perda,
  motivo_perda_nome
FROM vendas_perdidas
WHERE
  ativo = true
  AND status_recuperacao = 'pendente'
  AND valor_final >= 2000
  AND total_tentativas_recuperacao = 0
  AND data_perda > (NOW() - INTERVAL '60 days')
ORDER BY valor_final DESC;

-- Agendamentos próximos (próxima ação)
SELECT
  orcamento_id,
  paciente_nome,
  paciente_celular,
  proxima_acao,
  valor_final,
  responsavel_recuperacao
FROM vendas_perdidas
WHERE
  ativo = true
  AND status_recuperacao = 'agendado'
  AND proxima_acao BETWEEN NOW() AND (NOW() + INTERVAL '7 days')
ORDER BY proxima_acao;

-- ========================================
-- 12. RELATÓRIOS CONSOLIDADOS
-- ========================================

-- Relatório executivo mensal
SELECT
  TO_CHAR(data_perda, 'YYYY-MM') as mes,
  COUNT(*) as total_perdas,
  SUM(valor_final) as valor_perdido,
  ROUND(AVG(valor_final), 2) as ticket_medio,
  COUNT(*) FILTER (WHERE status_recuperacao = 'recuperado') as recuperadas,
  ROUND(
    (COUNT(*) FILTER (WHERE status_recuperacao = 'recuperado')::NUMERIC / COUNT(*)) * 100,
    2
  ) as taxa_recuperacao_pct
FROM vendas_perdidas
WHERE ativo = true
GROUP BY TO_CHAR(data_perda, 'YYYY-MM')
ORDER BY mes DESC
LIMIT 12;

-- ========================================
-- 13. LIMPEZA E MANUTENÇÃO
-- ========================================

-- Identificar registros duplicados (se houver)
SELECT
  orcamento_id,
  COUNT(*) as duplicatas
FROM vendas_perdidas
GROUP BY orcamento_id
HAVING COUNT(*) > 1;

-- Verificar integridade dos dados
SELECT
  COUNT(*) FILTER (WHERE paciente_id IS NULL) as sem_paciente,
  COUNT(*) FILTER (WHERE valor_final IS NULL OR valor_final = 0) as sem_valor,
  COUNT(*) FILTER (WHERE data_perda IS NULL) as sem_data_perda,
  COUNT(*) FILTER (WHERE status_card != 4) as status_incorreto
FROM vendas_perdidas
WHERE ativo = true;

-- ========================================
-- 14. EXPORTS PARA ANÁLISE EXTERNA
-- ========================================

-- CSV: Todas vendas perdidas (últimos 90 dias)
COPY (
  SELECT
    orcamento_id,
    paciente_nome,
    paciente_celular,
    valor_final,
    data_perda,
    motivo_perda_nome,
    status_recuperacao,
    profissional_nome,
    especialidade_nome
  FROM vendas_perdidas
  WHERE
    ativo = true
    AND data_perda > (NOW() - INTERVAL '90 days')
  ORDER BY data_perda DESC
) TO '/tmp/vendas_perdidas_90d.csv' WITH CSV HEADER;
