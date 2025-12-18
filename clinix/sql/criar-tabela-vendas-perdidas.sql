-- ========================================
-- TABELA: vendas_perdidas
-- ========================================
-- Armazena todos os dados de vendas perdidas
-- extraídos do sistema Clinix
-- Total: 62 campos organizados em 15 categorias

CREATE TABLE IF NOT EXISTS vendas_perdidas (
  -- ========================================
  -- 1. IDENTIFICADORES (3 campos)
  -- ========================================
  id BIGSERIAL PRIMARY KEY,
  orcamento_id INTEGER NOT NULL UNIQUE,
  painel_orcamento_id INTEGER,

  -- ========================================
  -- 2. PACIENTE (8 campos)
  -- ========================================
  paciente_id INTEGER NOT NULL,
  paciente_nome VARCHAR(255) NOT NULL,
  paciente_celular VARCHAR(20),
  paciente_email VARCHAR(255),
  paciente_cpf VARCHAR(14),
  paciente_data_nascimento DATE,
  paciente_cidade VARCHAR(100),
  paciente_estado VARCHAR(2),

  -- ========================================
  -- 3. PROFISSIONAL (4 campos)
  -- ========================================
  profissional_id INTEGER,
  profissional_nome VARCHAR(255),
  profissional_email VARCHAR(255),
  profissional_celular VARCHAR(20),

  -- ========================================
  -- 4. CLÍNICA (3 campos)
  -- ========================================
  clinica_id INTEGER,
  clinica_nome VARCHAR(255),
  conta_id INTEGER,

  -- ========================================
  -- 5. ESPECIALIDADE (2 campos)
  -- ========================================
  especialidade_id INTEGER,
  especialidade_nome VARCHAR(255),

  -- ========================================
  -- 6. VALORES (4 campos)
  -- ========================================
  valor_total DECIMAL(10, 2) NOT NULL,
  valor_desconto_total DECIMAL(10, 2) DEFAULT 0,
  valor_acrescimo_total DECIMAL(10, 2) DEFAULT 0,
  valor_final DECIMAL(10, 2) NOT NULL,

  -- ========================================
  -- 7. STATUS E MOTIVO (4 campos)
  -- ========================================
  status_card INTEGER NOT NULL,
  status_descricao VARCHAR(50),
  motivo_perda_id INTEGER,
  motivo_perda_nome VARCHAR(255),

  -- ========================================
  -- 8. DATAS (5 campos)
  -- ========================================
  data_orcamento TIMESTAMP NOT NULL,
  data_aprovacao TIMESTAMP,
  data_perda TIMESTAMP,
  data_movimentacao_negociacao TIMESTAMP,
  data_retorno TIMESTAMP,

  -- ========================================
  -- 9. PROCEDIMENTOS JSONB (3 campos)
  -- ========================================
  procedimentos JSONB,
  total_procedimentos INTEGER DEFAULT 0,
  procedimentos_resumo TEXT,

  -- ========================================
  -- 10. OBSERVAÇÕES JSONB (3 campos)
  -- ========================================
  observacoes JSONB,
  ultima_observacao TEXT,
  total_observacoes INTEGER DEFAULT 0,

  -- ========================================
  -- 11. PAGAMENTO (5 campos)
  -- ========================================
  forma_pagamento VARCHAR(100),
  metodo_pagamento_id INTEGER,
  numero_parcelas INTEGER,
  valor_parcela DECIMAL(10, 2),
  data_vencimento_primeira_parcela DATE,

  -- ========================================
  -- 12. RECORRÊNCIA (3 campos)
  -- ========================================
  is_recorrencia BOOLEAN DEFAULT FALSE,
  orcamento_inicial INTEGER,
  tipo_recorrencia INTEGER,

  -- ========================================
  -- 13. RECUPERAÇÃO (8 campos)
  -- ========================================
  is_contato_realizado BOOLEAN DEFAULT FALSE,
  data_ultimo_contato TIMESTAMP,
  tipo_ultimo_contato VARCHAR(50),
  total_tentativas_recuperacao INTEGER DEFAULT 0,
  status_recuperacao VARCHAR(50),
  proxima_acao TIMESTAMP,
  responsavel_recuperacao VARCHAR(255),
  observacao_recuperacao TEXT,

  -- ========================================
  -- 14. DADOS COMPLETOS (1 campo)
  -- ========================================
  dados_completos_json JSONB,

  -- ========================================
  -- 15. CONTROLE (3 campos)
  -- ========================================
  sincronizado_em TIMESTAMP DEFAULT NOW(),
  atualizado_em TIMESTAMP DEFAULT NOW(),
  ativo BOOLEAN DEFAULT TRUE
);

-- ========================================
-- ÍNDICES PARA PERFORMANCE
-- ========================================

-- Busca por orçamento específico
CREATE INDEX idx_vendas_perdidas_orcamento
ON vendas_perdidas(orcamento_id);

-- Busca por paciente
CREATE INDEX idx_vendas_perdidas_paciente
ON vendas_perdidas(paciente_id);

-- Filtro por status de recuperação
CREATE INDEX idx_vendas_perdidas_status_recuperacao
ON vendas_perdidas(status_recuperacao);

-- Ordenação por data de perda
CREATE INDEX idx_vendas_perdidas_data_perda
ON vendas_perdidas(data_perda DESC);

-- Filtro por clínica
CREATE INDEX idx_vendas_perdidas_clinica
ON vendas_perdidas(clinica_id);

-- Filtro por profissional
CREATE INDEX idx_vendas_perdidas_profissional
ON vendas_perdidas(profissional_id);

-- Busca por valor
CREATE INDEX idx_vendas_perdidas_valor
ON vendas_perdidas(valor_final DESC);

-- Índice JSONB para procedimentos
CREATE INDEX idx_vendas_perdidas_procedimentos
ON vendas_perdidas USING GIN(procedimentos);

-- ========================================
-- COMENTÁRIOS NA TABELA
-- ========================================

COMMENT ON TABLE vendas_perdidas IS 'Armazena vendas perdidas extraídas do sistema Clinix';

COMMENT ON COLUMN vendas_perdidas.orcamento_id IS 'ID único do orçamento no Clinix';
COMMENT ON COLUMN vendas_perdidas.status_card IS '1=EM_ABERTO, 2=EM_NEGOCIACAO, 3=APROVADO, 4=PERDIDO';
COMMENT ON COLUMN vendas_perdidas.procedimentos IS 'Array JSON com todos os procedimentos do orçamento';
COMMENT ON COLUMN vendas_perdidas.status_recuperacao IS 'pendente|agendado|em_contato|recuperado|desistido';
COMMENT ON COLUMN vendas_perdidas.dados_completos_json IS 'Backup completo das respostas da API Clinix';

-- ========================================
-- VIEWS ÚTEIS
-- ========================================

-- View: Vendas perdidas pendentes de recuperação
CREATE OR REPLACE VIEW vw_vendas_perdidas_pendentes AS
SELECT
  id,
  orcamento_id,
  paciente_nome,
  paciente_celular,
  valor_final,
  data_perda,
  motivo_perda_nome,
  EXTRACT(DAY FROM (NOW() - data_perda)) as dias_desde_perda
FROM vendas_perdidas
WHERE
  status_recuperacao = 'pendente'
  AND ativo = true
  AND paciente_celular IS NOT NULL
  AND data_perda > NOW() - INTERVAL '90 days'
ORDER BY valor_final DESC;

-- View: Estatísticas de recuperação
CREATE OR REPLACE VIEW vw_stats_recuperacao AS
SELECT
  status_recuperacao,
  COUNT(*) as total,
  ROUND(AVG(valor_final), 2) as ticket_medio,
  SUM(valor_final) as valor_total,
  ROUND(COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER () * 100, 2) as percentual
FROM vendas_perdidas
WHERE ativo = true
GROUP BY status_recuperacao;

-- View: Top motivos de perda
CREATE OR REPLACE VIEW vw_top_motivos_perda AS
SELECT
  motivo_perda_nome,
  COUNT(*) as quantidade,
  SUM(valor_final) as valor_total,
  ROUND(AVG(valor_final), 2) as ticket_medio,
  ROUND(COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER () * 100, 2) as percentual
FROM vendas_perdidas
WHERE
  ativo = true
  AND motivo_perda_nome IS NOT NULL
GROUP BY motivo_perda_nome
ORDER BY quantidade DESC;

-- ========================================
-- TRIGGERS
-- ========================================

-- Trigger: Atualizar timestamp automaticamente
CREATE OR REPLACE FUNCTION atualizar_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.atualizado_em = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_atualizar_timestamp
BEFORE UPDATE ON vendas_perdidas
FOR EACH ROW
EXECUTE FUNCTION atualizar_timestamp();

-- ========================================
-- GRANTS (ajustar conforme necessário)
-- ========================================

-- GRANT SELECT, INSERT, UPDATE ON vendas_perdidas TO seu_usuario;
-- GRANT USAGE, SELECT ON SEQUENCE vendas_perdidas_id_seq TO seu_usuario;
