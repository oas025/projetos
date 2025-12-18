# Documentação: Engenharia Reversa - Sistema Clinix

## 📋 Sumário

- [Visão Geral](#visão-geral)
- [Objetivos do Projeto](#objetivos-do-projeto)
- [Arquitetura do Sistema](#arquitetura-do-sistema)
- [Autenticação](#autenticação)
- [Endpoints Descobertos](#endpoints-descobertos)
- [Estrutura de Dados](#estrutura-de-dados)
- [Workflows n8n](#workflows-n8n)
- [Casos de Uso](#casos-de-uso)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Visão Geral

Este projeto documenta o processo de **engenharia reversa** do sistema **Clinix** (https://gestao.clinix.app.br) para automatizar a extração e manipulação de dados através da ferramenta **n8n**.

**Sistema Alvo:** Clinix - Sistema de Gestão para Clínicas Odontológicas
**Método:** Captura de requisições HTTP/AJAX via DevTools (F12)
**Ferramenta de Automação:** n8n (workflow automation)
**Storage:** Supabase (PostgreSQL)

---

## 🎯 Objetivos do Projeto

### Objetivos Principais

1. **Extrair Vendas Perdidas**: Capturar orçamentos com `statusCard = 4` (PERDIDO)
2. **Centralizar Dados**: Armazenar em banco Supabase para análise posterior
3. **Automatizar Recuperação**: Criar agendamentos automáticos para tentativa de recuperação
4. **Rastrear Tentativas**: Registrar todas as ações de recuperação

### Benefícios

- ✅ Visão consolidada de vendas perdidas
- ✅ Automação de follow-up com clientes
- ✅ Aumento de taxa de conversão
- ✅ Redução de trabalho manual

---

## 🏗️ Arquitetura do Sistema

### Componentes

```
┌─────────────────────────────────────────────────────┐
│           Sistema Clinix (Azure)                    │
│  https://gestao.clinix.app.br                       │
└─────────────────────────────────────────────────────┘
                    ↓ API REST
┌─────────────────────────────────────────────────────┐
│           n8n Workflow Automation                   │
│  - Autenticação                                     │
│  - Extração de dados (GET)                          │
│  - Criação de agendamentos (POST)                   │
└─────────────────────────────────────────────────────┘
                    ↓ Storage
┌─────────────────────────────────────────────────────┐
│           Supabase (PostgreSQL)                     │
│  Tabela: vendas_perdidas                            │
│  - 62 campos de dados                               │
│  - JSONB para dados complexos                       │
└─────────────────────────────────────────────────────┘
```

### Serviços Azure Identificados

| Serviço | Domínio | Função |
|---------|---------|--------|
| Autenticação | `clinix-autenticacao.azurewebsites.net` | Login e JWT tokens |
| Financeiro | `clinix-financeiro.azurewebsites.net` | Orçamentos e pagamentos |
| Cadastro | `clinix-cadastro.azurewebsites.net` | Agendamentos e consultas |

---

## 🔐 Autenticação

### Sistema de Token JWT

**Endpoint:** `POST https://clinix-autenticacao.azurewebsites.net/api/v1/entrar`

**Payload:**
```json
{
  "login": "usuario@email.com",
  "password": "senha123"
}
```

**Resposta:**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJQUzI1NiIs...",
    "user": {
      "idUsuario": 72,
      "idConta": 62,
      "nomeUsuario": "Nome do Usuário",
      "email": "usuario@email.com"
    }
  }
}
```

### Características do Token

- **Tipo:** Bearer Token (JWT)
- **Algoritmo:** PS256 (RSA-PSS with SHA-256)
- **Validade:** ~12 horas (43.200 segundos)
- **Uso:** Header `Authorization: Bearer {token}`

### Campos do Token Decodificado

```json
{
  "sub": "72",
  "email": "usuario@email.com",
  "nbf": 1762957773,
  "iat": 1762957773,
  "exp": 1763000973,
  "iss": "https://clinix-autenticacao.azurewebsites.net",
  "aud": [
    "https://clinix-cadastro.azurewebsites.net",
    "https://clinix-financeiro.azurewebsites.net",
    "https://clinix-api.azurewebsites.net"
  ],
  "role": ["VisualizarAgenda", "IncluirAgendamento", ...]
}
```

---

## 🌐 Endpoints Descobertos

### 1. Autenticação

#### Login
```http
POST /api/v1/entrar
Host: clinix-autenticacao.azurewebsites.net
Content-Type: application/json

{
  "login": "email@example.com",
  "password": "senha"
}
```

---

### 2. Orçamentos/Vendas

#### Buscar Orçamentos (Painel)
```http
GET /api/v1/painelorcamento
Host: clinix-financeiro.azurewebsites.net
Authorization: Bearer {token}

Query Parameters:
- contaId: 62
- clinicaId: 0 (0 = todas)
- inicio: 2024-01-01T00:00:00
- final: 2025-12-31T23:59:59
- tipoRecorrencia: 0
```

**Resposta:**
```json
{
  "success": true,
  "data": [
    {
      "id": 123456,
      "orcamentoId": 253235,
      "statusCard": 4,
      "nome": "Nome do Orçamento",
      "pacienteId": 46711,
      "nomePaciente": "João Silva",
      "celular": "11987654321",
      "profissionalId": 166,
      "profissionalNome": "Dr. Carlos",
      "valor": 1500.00,
      "dataOrcamento": "2025-01-15T10:30:00",
      "dataPerda": "2025-01-20T16:45:00",
      "motivoPerdaId": 3,
      "nomeMotivoPerda": "Preço alto",
      "nomeClinica": "Clínica Central",
      "especialidadeId": 13
    }
  ]
}
```

**Status Card:**
- `1` = EM_ABERTO
- `2` = EM_NEGOCIACAO
- `3` = APROVADO
- `4` = **PERDIDO** ← Alvo da extração

---

#### Buscar Detalhes do Orçamento
```http
GET /api/v1/negociacaoorcamento/orcamento
Host: clinix-financeiro.azurewebsites.net
Authorization: Bearer {token}

Query Parameters:
- orcamentoId: 253235
- contaId: 62
```

**Resposta (Estrutura Completa):**
```json
{
  "success": true,
  "data": {
    "procedimentos": [
      {
        "s": {
          "orcamentoId": 253235,
          "procedimentoId": 10299,
          "descricaoProcedimento": "Profilaxia|85400319",
          "valor": 164.15,
          "valorDesconto": 64.15,
          "valorFinal": 100.00,
          "status": 1,
          "aprovado": true,
          "procedimento": {
            "tuss": 85400319,
            "nome": "Profilaxia"
          },
          "profissional": {
            "nome": "Dr. Carlos"
          },
          "plano": {
            "nome": "Plano Particular"
          }
        },
        "dadosRegiao": [...],
        "dentesSelecionados": [21, 41, 31, 11]
      }
    ],
    "negociacao": {
      "orcamentoId": 253235,
      "valorTotal": 1390.00,
      "valorTotalDesconto": 85.66,
      "valorTotalAcrescimo": 0.00,
      "orcamento": {
        "pacienteId": 46711,
        "statusOrcamentoId": 4,
        "clinicaId": 57,
        "contaId": 62,
        "paciente": {
          "id": 46711,
          "nome": "João Silva",
          "celular": "11987654321",
          "email": "joao@email.com",
          "cpf": "12345678900",
          "dataNascimento": "1985-03-15",
          "cidade": "São Paulo",
          "estado": "SP"
        }
      }
    },
    "negociacaoPagamento": [
      {
        "metodoPagamentoId": 38,
        "qtdParcelas": 1,
        "valorParcela": 1390.00,
        "dataVencimentoParcela": "2025-04-16",
        "metodoPagamento": {
          "formaPagamento": "DINHEIRO"
        }
      }
    ]
  }
}
```

---

### 3. Agendamentos/Consultas

#### Criar Consulta/Agendamento
```http
POST /api/v1/Consulta/gravaconsulta
Host: clinix-cadastro.azurewebsites.net
Authorization: Bearer {token}
Content-Type: application/json

{
  "clinicaID": 57,
  "profissionalId": 1674,
  "cadeiraId": 62,
  "especialidadeId": 13,
  "pacienteId": 46711,
  "celularPaciente": "16994660219",
  "planoId": 77,
  "dataInicio": "2025-11-13T12:00:00.000Z",
  "hora_inicio": "09:00",
  "tempoConsulta": 10,
  "tipoAtendimentoPersonalizadoId": 807,
  "statusConsulta": 1,
  "retorno": false,
  "tipoRetorno": "1",
  "periodoRetorno": "1",
  "observacao": "",
  "origemRelacionamentoId": null,
  "origemRelacionamentoOutros": null,
  "dataFinal": "2025-11-13T12:10:00.000Z",
  "tituloConsulta": "João Silva",
  "contaId": 62,
  "painelLeadsId": null,
  "pacienteSimples": false,
  "usuario": "Nome do Usuário",
  "pacienteElegivel": null
}
```

**Resposta Sucesso:**
```json
{
  "success": true,
  "data": {
    "id": 12345,
    "consultaId": 12345,
    "message": "Consulta criada com sucesso"
  }
}
```

**Resposta Erro:**
```json
{
  "success": false,
  "message": "Horário já ocupado",
  "errors": [...]
}
```

---

## 📊 Estrutura de Dados

### Tabela Supabase: `vendas_perdidas`

**Total:** 62 campos organizados em 15 categorias

#### SQL de Criação

```sql
CREATE TABLE IF NOT EXISTS vendas_perdidas (
  -- 1. Identificadores (3 campos)
  id BIGSERIAL PRIMARY KEY,
  orcamento_id INTEGER NOT NULL UNIQUE,
  painel_orcamento_id INTEGER,

  -- 2. Paciente (8 campos)
  paciente_id INTEGER NOT NULL,
  paciente_nome VARCHAR(255) NOT NULL,
  paciente_celular VARCHAR(20),
  paciente_email VARCHAR(255),
  paciente_cpf VARCHAR(14),
  paciente_data_nascimento DATE,
  paciente_cidade VARCHAR(100),
  paciente_estado VARCHAR(2),

  -- 3. Profissional (4 campos)
  profissional_id INTEGER,
  profissional_nome VARCHAR(255),
  profissional_email VARCHAR(255),
  profissional_celular VARCHAR(20),

  -- 4. Clínica (3 campos)
  clinica_id INTEGER,
  clinica_nome VARCHAR(255),
  conta_id INTEGER,

  -- 5. Especialidade (2 campos)
  especialidade_id INTEGER,
  especialidade_nome VARCHAR(255),

  -- 6. Valores (4 campos)
  valor_total DECIMAL(10, 2) NOT NULL,
  valor_desconto_total DECIMAL(10, 2) DEFAULT 0,
  valor_acrescimo_total DECIMAL(10, 2) DEFAULT 0,
  valor_final DECIMAL(10, 2) NOT NULL,

  -- 7. Status e Motivo (4 campos)
  status_card INTEGER NOT NULL,
  status_descricao VARCHAR(50),
  motivo_perda_id INTEGER,
  motivo_perda_nome VARCHAR(255),

  -- 8. Datas (5 campos)
  data_orcamento TIMESTAMP NOT NULL,
  data_aprovacao TIMESTAMP,
  data_perda TIMESTAMP,
  data_movimentacao_negociacao TIMESTAMP,
  data_retorno TIMESTAMP,

  -- 9. Procedimentos JSONB (3 campos)
  procedimentos JSONB,
  total_procedimentos INTEGER DEFAULT 0,
  procedimentos_resumo TEXT,

  -- 10. Observações JSONB (3 campos)
  observacoes JSONB,
  ultima_observacao TEXT,
  total_observacoes INTEGER DEFAULT 0,

  -- 11. Pagamento (5 campos)
  forma_pagamento VARCHAR(100),
  metodo_pagamento_id INTEGER,
  numero_parcelas INTEGER,
  valor_parcela DECIMAL(10, 2),
  data_vencimento_primeira_parcela DATE,

  -- 12. Recorrência (3 campos)
  is_recorrencia BOOLEAN DEFAULT FALSE,
  orcamento_inicial INTEGER,
  tipo_recorrencia INTEGER,

  -- 13. Recuperação (8 campos)
  is_contato_realizado BOOLEAN DEFAULT FALSE,
  data_ultimo_contato TIMESTAMP,
  tipo_ultimo_contato VARCHAR(50),
  total_tentativas_recuperacao INTEGER DEFAULT 0,
  status_recuperacao VARCHAR(50),
  proxima_acao TIMESTAMP,
  responsavel_recuperacao VARCHAR(255),
  observacao_recuperacao TEXT,

  -- 14. Dados Completos (1 campo)
  dados_completos_json JSONB,

  -- 15. Controle (3 campos)
  sincronizado_em TIMESTAMP DEFAULT NOW(),
  atualizado_em TIMESTAMP DEFAULT NOW(),
  ativo BOOLEAN DEFAULT TRUE
);

-- Índices para performance
CREATE INDEX idx_vendas_perdidas_orcamento ON vendas_perdidas(orcamento_id);
CREATE INDEX idx_vendas_perdidas_paciente ON vendas_perdidas(paciente_id);
CREATE INDEX idx_vendas_perdidas_status_recuperacao ON vendas_perdidas(status_recuperacao);
CREATE INDEX idx_vendas_perdidas_data_perda ON vendas_perdidas(data_perda);
```

---

## 🔄 Workflows n8n

### Workflow 1: Extração de Vendas Perdidas

**Descrição:** Busca todas as vendas perdidas e salva no Supabase

**Fluxo:**
```
1. Gera Token de Acesso
   ↓
2. Obtém Variáveis de Requisição
   ↓
3. Busca Orçamentos
   ↓
4. Filtra Somente PERDIDOS (statusCard = 4)
   ↓
5. Buscar Detalhes Orçamento (para cada)
   ↓
6. Preparar Dados Supabase
   ↓
7. Inserir no Supabase
```

#### Node 1: Gera Token de Acesso

**Tipo:** HTTP Request
**Método:** POST
**URL:** `https://clinix-autenticacao.azurewebsites.net/api/v1/entrar`

**Headers:**
- `Accept: application/json`
- `Origin: https://gestao.clinix.app.br`

**Body Parameters:**
- `login`: henrique.silva@nst.com.br
- `password`: Teste@123

---

#### Node 2: Obtém Variáveis de Requisição

**Tipo:** Code (JavaScript)

```javascript
const response = $input.item.json;

if (!response.success || !response.data || !response.data.token) {
  throw new Error('Falha na autenticação: Token não encontrado');
}

const token = response.data.token;
const idUsuario = response.data.user.idUsuario;
const idConta = response.data.user.idConta;
const nomeUsuario = response.data.user.nomeUsuario;

return {
  json: {
    token: token,
    bearerToken: `Bearer ${token}`,
    idUsuario: idUsuario,
    idConta: idConta,
    nomeUsuario: nomeUsuario,
    authenticated: true
  }
};
```

---

#### Node 3: Busca Orçamentos

**Tipo:** HTTP Request
**Método:** GET
**URL:** `https://clinix-financeiro.azurewebsites.net/api/v1/painelorcamento`

**Query Parameters:**
- `contaId`: `={{ $json.idConta }}`
- `clinicaId`: 0
- `inicio`: `={{ $now.minus({ months: 12 }).toISO() }}`
- `final`: `={{ $now.toISO() }}`
- `tipoRecorrencia`: 0

**Headers:**
- `Authorization`: `={{ $json.bearerToken }}`
- `Accept: application/json`
- `Content-Type: application/json`

---

#### Node 4: Filtra Somente PERDIDOS

**Tipo:** Code (JavaScript)

```javascript
const response = $input.item.json;

if (!response.success || !response.data) {
  return [];
}

// Filtrar apenas vendas perdidas (statusCard = 4)
const vendasPerdidas = response.data.filter(item => item.statusCard === 4);

// Retornar array formatado
return vendasPerdidas.map(venda => ({ json: venda }));
```

---

#### Node 5: Buscar Detalhes Orçamento

**Tipo:** HTTP Request
**Método:** GET
**URL:** `https://clinix-financeiro.azurewebsites.net/api/v1/negociacaoorcamento/orcamento`

**Query Parameters:**
- `orcamentoId`: `={{ $json.orcamentoId }}`
- `contaId`: `={{ $item(0).$node["obtem variaveis de requsição"].json["idConta"] }}`

**Headers:**
- `Authorization`: `={{ $item(0).$node["obtem variaveis de requsição"].json["bearerToken"] }}`
- `Accept: application/json`

---

#### Node 6: Preparar Dados Supabase

**Tipo:** Code (JavaScript)

Ver arquivo completo: `nodes/preparar-dados-supabase.js`

**Resumo:** Combina dados de `vendaPerdida` + `detalhes` e formata para os 62 campos da tabela.

---

#### Node 7: Inserir no Supabase

**Tipo:** Supabase
**Operação:** Insert
**Tabela:** vendas_perdidas
**Data:** `={{ $json }}`

---

### Workflow 2: Criar Agendamentos de Recuperação

**Descrição:** Cria agendamentos automáticos para vendas perdidas

**Fluxo:**
```
1. Buscar Vendas Perdidas (Supabase)
   ↓
2. Filtrar Candidatos (sem contato, > 30 dias)
   ↓
3. Preparar Agendamento
   ↓
4. Criar Consulta (POST)
   ↓
5. Validar Resposta
   ↓
6. Atualizar Status Recuperação (Supabase)
```

---

## 🎯 Casos de Uso

### Caso 1: Extração Diária de Vendas Perdidas

**Objetivo:** Manter base atualizada de vendas perdidas

**Configuração:**
- **Trigger:** Cron (todos os dias às 8h)
- **Workflow:** Extração de Vendas Perdidas
- **Filtro:** Últimos 30 dias
- **Ação:** Upsert no Supabase (atualiza se já existe)

---

### Caso 2: Recuperação Automática

**Objetivo:** Agendar retorno para vendas perdidas

**Critérios:**
- Perda há mais de 30 dias
- Sem tentativa de recuperação anterior
- Celular válido
- Valor > R$ 500

**Ação:**
- Criar agendamento 7 dias no futuro
- Registrar tentativa
- Atualizar status para "agendamento_criado"

---

### Caso 3: Relatório de Recuperação

**Objetivo:** Análise de taxa de conversão

**Queries SQL:**

```sql
-- Total de vendas perdidas
SELECT COUNT(*) FROM vendas_perdidas WHERE ativo = true;

-- Taxa de recuperação
SELECT
  status_recuperacao,
  COUNT(*) as total,
  ROUND(AVG(valor_final), 2) as ticket_medio
FROM vendas_perdidas
GROUP BY status_recuperacao;

-- Top motivos de perda
SELECT
  motivo_perda_nome,
  COUNT(*) as quantidade,
  SUM(valor_final) as valor_total
FROM vendas_perdidas
GROUP BY motivo_perda_nome
ORDER BY quantidade DESC
LIMIT 10;
```

---

## 🛠️ Troubleshooting

### Problema: Token Expirado

**Erro:** `401 Unauthorized`

**Solução:**
```javascript
// Adicionar verificação de expiração
const tokenExp = JSON.parse(atob(token.split('.')[1])).exp;
const agora = Math.floor(Date.now() / 1000);

if (tokenExp < agora) {
  // Re-autenticar
  throw new Error('Token expirado - executar login novamente');
}
```

---

### Problema: Horário Ocupado

**Erro:** `"Horário já ocupado"`

**Solução:**
```javascript
// Tentar próximo horário disponível
const proximoHorario = new Date(dataOriginal);
proximoHorario.setHours(proximoHorario.getHours() + 1);
```

---

### Problema: Dados Duplicados

**Erro:** `duplicate key value violates unique constraint`

**Solução:**
```sql
-- Usar UPSERT (ON CONFLICT)
INSERT INTO vendas_perdidas (orcamento_id, ...)
VALUES (...)
ON CONFLICT (orcamento_id)
DO UPDATE SET
  atualizado_em = NOW(),
  ...;
```

---

## 📚 Referências

### Documentos do Projeto

- `README.md` - Este documento
- `nodes/` - Códigos dos nodes n8n
- `sql/` - Scripts SQL
- `examples/` - Exemplos de payloads

### Links Úteis

- [n8n Documentation](https://docs.n8n.io/)
- [Supabase Documentation](https://supabase.com/docs)
- [JWT.io](https://jwt.io/) - Decodificador de tokens

---

## 📝 Changelog

### v1.0.0 - 2025-01-12
- ✅ Autenticação JWT implementada
- ✅ Extração de vendas perdidas
- ✅ Armazenamento em Supabase
- ✅ Criação de agendamentos
- ✅ Documentação completa

---

**Autor:** Projeto de Engenharia Reversa
**Data:** Janeiro 2025
**Status:** Em Produção ✅
