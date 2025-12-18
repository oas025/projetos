# CopilotKit - EstéticaPro AI Integration

## Visão Geral do Projeto

Este projeto contém a integração do CopilotKit com o sistema EstéticaPro, um software para clínicas de estética. O assistente de IA está localizado na página de Análise Mensal (`/dados/analisemensal`) e oferece insights inteligentes sobre o negócio.

## Arquitetura

### Arquivos Principais

```
esteticapro/
├── components/ai/
│   ├── InsightsCentral.tsx      # Componente principal com todas as actions
│   └── DynamicVisualizer.tsx    # Renderiza visualizações dinâmicas
├── hooks/
│   ├── useAIContext.ts          # Hook base para contexto da IA
│   └── useExpandedAIContext.ts  # Funções expandidas (Waves 1-4)
├── types/
│   └── database.ts              # Tipos TypeScript
└── app/api/copilotkit/
    └── route.ts                 # API route do CopilotKit
```

### Runtime CopilotKit
- **URL Local**: `/api/copilotkit` (Next.js API Route)
- **Versão**: CopilotKit v1.4.8
- **LLM**: Google Gemini (via GOOGLE_API_KEY)

## Actions Implementadas (32 total)

### Wave 1 - Análises Avançadas (10 actions)
1. `calcularROI` - ROI de campanhas de marketing
2. `analisarFunilCompleto` - Funil de vendas com taxas de conversão
3. `resumoExecutivo` - Dashboard executivo com KPIs
4. `calcularFaturamento` - Faturamento com ticket médio
5. `calcularTaxaAprovacao` - Taxa de aprovação de orçamentos
6. `analisarPerformanceProcedimentos` - Ranking de procedimentos
7. `buscarAgendadosHoje` - Agendamentos do dia
8. `buscarAgendadosSemana` - Agendamentos da semana
9. `analisarEfetividadeFollowup` - Efetividade do follow-up
10. `buscarHistoricoCampanhas` - Histórico de campanhas

### Wave 2 - Gestão e Operações (4 actions)
11. `consultarConfigFollowup` - Configuração follow-up automático
12. `consultarConfigLembrete` - Configuração de lembretes
13. `buscarImagens` - Imagens antes/depois
14. `listarProfissionais` - Profissionais da clínica

### Wave 3 - Análises Temporais (2 actions)
15. `compararPeriodos` - Comparativo com período anterior
16. `analisarTendencias` - Evolução ao longo do tempo

### Wave 4 - Cruzamento de Tabelas (5 actions)
17. `cruzarLeadsOrcamentos` - Correlação leads→orçamentos→vendas
18. `identificarGargalos` - Gargalos no funil com recomendações
19. `analisarConversaoProcedimento` - Conversão por procedimento
20. `analisarLeadsReativados` - Leads reativados via follow-up
21. `analisarJornadaCliente` - Timeline completa do cliente

### Actions Base (11 actions)
22-32. `buscarEMostrarLeads`, `buscarLeadsFollowup`, `analisarDistribuicaoLeads`, `buscarEMostrarOrcamentos`, `buscarOrcamentosBD`, `analisarPerformanceVendas`, `buscarEMostrarAgendamentos`, `buscarFinalizacoes`, `consultarClinixInfo`, `resumoGeral`, `mostrarVisualizacao`, `registrarLimitacao`

## Banco de Dados (Supabase)

### Tabelas Principais Utilizadas
- `leads` - CRM de leads/pacientes
- `orcamentos_clinix` - Orçamentos sincronizados do Clinix
- `finalizacoes` - Atendimentos finalizados
- `historico_followup` - Histórico de follow-ups
- `historico_disparos` - Campanhas de marketing
- `briefings` - Configurações da clínica (JSON)
- `configuracoes_ia` - Configurações da IA
- `imagens_antes_depois` - Galeria de resultados
- `copilot_limitacoes` - Limitações registradas pela IA

### Segurança
Todas as queries são filtradas por `user_id` para garantir isolamento de dados entre clínicas.

## Sistema de Registro de Limitações

Quando a IA não consegue atender uma solicitação do usuário, ela registra automaticamente na tabela `copilot_limitacoes` através da action `registrarLimitacao`. Isso permite:

1. Identificar gaps nas funcionalidades
2. Priorizar desenvolvimento de novas features
3. Entender as necessidades reais dos usuários

### Estrutura da Tabela `copilot_limitacoes`
```sql
- id (uuid)
- user_id (uuid)
- user_email (text)
- clinica_id (uuid)
- clinica_nome (text)
- solicitacao_original (text) -- O que o usuário pediu
- categoria (text) -- action_inexistente, dados_insuficientes, etc.
- motivo_detalhado (text)
- plano_acao (text) -- Sugestão da IA de como resolver
- actions_consideradas (jsonb)
- dados_necessarios (jsonb)
- sistemas_relacionados (jsonb)
- prioridade_sugerida (text)
- impacto_negocio (text)
- complexidade_estimada (text)
- tempo_estimado_horas (integer)
- status (text) -- pendente, em_analise, implementado, descartado
- modulo_origem (text)
- created_at (timestamp)
```

---

# COMANDOS ESPECIAIS

## /limitacoes - Processar Limitações Pendentes

Para ativar este comando, digite no chat: `/limitacoes`

### O que este comando faz:

1. **Busca limitações pendentes** na tabela `copilot_limitacoes`
2. **Analisa cada uma** e entende o que precisa ser feito
3. **Monta plano de ação detalhado** para cada limitação
4. **Apresenta para aprovação** do desenvolvedor
5. **Executa uma a uma** após autorização

### Instruções para Claude Code:

Quando o usuário digitar `/limitacoes`, execute os seguintes passos:

```
PASSO 1 - BUSCAR LIMITAÇÕES
============================
Conectar no Supabase do projeto esteticapro e executar:

SELECT * FROM copilot_limitacoes
WHERE status = 'pendente'
ORDER BY
  CASE prioridade_sugerida
    WHEN 'critica' THEN 1
    WHEN 'alta' THEN 2
    WHEN 'media' THEN 3
    WHEN 'baixa' THEN 4
  END,
  created_at ASC;

PASSO 2 - ANALISAR CADA LIMITAÇÃO
==================================
Para cada limitação encontrada:
1. Ler a solicitacao_original
2. Entender a categoria (action_inexistente, dados_insuficientes, etc.)
3. Analisar o plano_acao sugerido pela IA
4. Verificar os arquivos relacionados no projeto

PASSO 3 - CRIAR PLANO DE AÇÃO
==============================
Para cada limitação, criar um plano detalhado contendo:
- Resumo da solicitação
- Arquivos que precisam ser modificados
- Funções/actions que precisam ser criadas
- Estimativa de complexidade
- Dependências (outras tabelas, APIs, etc.)

PASSO 4 - APRESENTAR PARA APROVAÇÃO
====================================
Mostrar o plano em formato de lista:

## Limitações Pendentes (X encontradas)

### 1. [Título baseado na solicitação]
- **Solicitação**: [solicitacao_original]
- **Categoria**: [categoria]
- **Prioridade**: [prioridade_sugerida]
- **Plano de Ação**:
  1. [Passo 1]
  2. [Passo 2]
  ...
- **Arquivos a modificar**: [lista]
- **Estimativa**: [tempo]

Aprovar implementação? (sim/não/pular)

PASSO 5 - EXECUTAR APÓS APROVAÇÃO
==================================
Quando o usuário aprovar:
1. Implementar as mudanças necessárias
2. Testar o build
3. Atualizar o status na tabela para 'implementado'
4. Passar para a próxima limitação

Se o usuário disser "não" ou "pular":
- Manter status como 'pendente' e passar para a próxima
```

### REGRA IMPORTANTE: Perguntar Antes de Explorar

**ANTES de implementar qualquer coisa**, se houver dúvida sobre:
- Qual tabela contém a informação
- Nome de campos específicos
- Estrutura dos dados
- Relacionamento entre tabelas

**PERGUNTE AO USUÁRIO PRIMEIRO!**

O usuário conhece bem o sistema e pode indicar diretamente onde está a informação, economizando tempo. Só explore o banco de dados se o usuário não souber.

### Exemplo de Uso:

```
Usuário: /limitacoes

Claude: Buscando limitações pendentes no Supabase...

Encontrei 3 limitações pendentes:

## 1. Calcular margem de lucro por procedimento
- **Solicitação**: "Qual a margem de lucro de cada procedimento?"
- **Categoria**: action_inexistente
- **Prioridade**: alta
- **Plano de Ação**:
  1. Criar função `calcularMargemLucro` em useExpandedAIContext.ts
  2. Adicionar action `analisarMargemLucro` em InsightsCentral.tsx
  3. Requer: dados de custo por procedimento
- **Arquivos**: useExpandedAIContext.ts, InsightsCentral.tsx
- **Estimativa**: 2-4 horas

Deseja que eu implemente esta funcionalidade? (sim/não/pular)

Usuário: sim

Claude: Para implementar, preciso saber onde está o custo dos procedimentos.
Você sabe em qual tabela/campo está essa informação?
Ou devo explorar o banco de dados?

Usuário: Está na tabela briefings, no campo briefing->Procedimentos, cada procedimento tem um campo "custo"

Claude: Perfeito! Vou usar essa estrutura.
Implementando... [executa as mudanças]
Build OK! Funcionalidade implementada.
Atualizando status para 'implementado'...

Próxima limitação:
## 2. [próxima]...
```

---

## Notas Importantes

### Conexão Supabase
- URL: `NEXT_PUBLIC_SUPABASE_URL` no .env.local
- Key: `NEXT_PUBLIC_SUPABASE_ANON_KEY` no .env.local

### Padrões de Código
- Todas as funções de dados em `useExpandedAIContext.ts`
- Todas as actions CopilotKit em `InsightsCentral.tsx`
- Sempre filtrar por `user_id` nas queries
- Usar `formatarValor()` para valores monetários
- Usar `setVisualContent()` para mostrar visualizações

### Tipos de Visualização Disponíveis
- `cards_metricas` - KPIs e métricas
- `grafico_pizza` - Distribuições
- `grafico_linha` - Evolução temporal
- `grafico_barras` - Rankings
- `tabela` - Dados tabulares
- `lista_leads` - Lista de leads
- `agendamentos` - Lista de agendamentos
- `comparativo` - Comparação de períodos

### Segurança
- Nunca expor dados de outros usuários
- Sempre usar `user_id` do contexto de autenticação
- Validar parâmetros antes de queries
