# 📑 Índice da Documentação - Projeto Clinix

## 🎯 Início Rápido

- **[README.md](README.md)** - Documentação completa do projeto
- **[QUICKSTART.md](QUICKSTART.md)** - Guia rápido de implementação (5 minutos)
- **🆕 [api-documentation/clinix-api-endpoints.md](api-documentation/clinix-api-endpoints.md)** - API completa (44 endpoints) para integração EsteticaPro

---

## 📂 Estrutura de Arquivos

```
C:\Users\mathe\Documents\Projetos\clinix\
│
├── README.md                          # Documentação principal
├── QUICKSTART.md                      # Guia rápido
├── INDEX.md                           # Este arquivo
├── SUMMARY.md                         # Resumo do projeto
│
├── api-documentation/                 # 🆕 Documentação completa da API
│   ├── clinix-api-endpoints.md        # 44 endpoints documentados
│   └── METODOLOGIA-ENGENHARIA-REVERSA.md  # Como os endpoints foram descobertos
│
├── nodes/                             # Códigos dos nodes n8n
│   └── preparar-dados-supabase.js     # Node de formatação de dados
│
├── sql/                               # Scripts SQL
│   ├── criar-tabela-vendas-perdidas.sql   # Criação da tabela
│   └── queries-uteis.sql              # Queries de análise
│
└── examples/                          # Exemplos e referências
    ├── payloads-api.md                # Exemplos de requests/responses
    └── curl-criar-agendamento.txt     # cURL para criar agendamentos
```

---

## 📖 Guias por Objetivo

### 🎯 Quero Começar do Zero

1. Leia: [QUICKSTART.md](QUICKSTART.md)
2. Execute: `sql/criar-tabela-vendas-perdidas.sql`
3. Configure: Credenciais no n8n
4. Teste: Workflow de extração

### 🔍 Quero Entender a API

1. **🆕 Documentação Completa**: [api-documentation/clinix-api-endpoints.md](api-documentation/clinix-api-endpoints.md) - 44 endpoints
2. **🆕 Metodologia**: [api-documentation/METODOLOGIA-ENGENHARIA-REVERSA.md](api-documentation/METODOLOGIA-ENGENHARIA-REVERSA.md) - Como descobrir mais endpoints
3. Leia: [README.md - Endpoints Descobertos](README.md#endpoints-descobertos)
4. Veja exemplos: [examples/payloads-api.md](examples/payloads-api.md)
5. Teste: cURL nos exemplos

### 🤖 Quero Integrar IA para Agendamento (EsteticaPro)

1. **Documentação da API**: [api-documentation/clinix-api-endpoints.md](api-documentation/clinix-api-endpoints.md)
2. Veja: Seção "Contexto e Objetivo" - Fluxo completo
3. Veja: Seção "Referência Rápida" - Endpoints essenciais
4. Fluxo: Sync inicial → IA agenda → Clinix reflete

### 💾 Quero Configurar o Banco

1. Execute: [sql/criar-tabela-vendas-perdidas.sql](sql/criar-tabela-vendas-perdidas.sql)
2. Valide: Queries em [sql/queries-uteis.sql](sql/queries-uteis.sql)
3. Otimize: Índices já incluídos no script

### 🔄 Quero Criar Workflows

1. Estude: [README.md - Workflows n8n](README.md#workflows-n8n)
2. Use código: [nodes/preparar-dados-supabase.js](nodes/preparar-dados-supabase.js)
3. Teste: Com dados de exemplo

### 📊 Quero Analisar Dados

1. Use: [sql/queries-uteis.sql](sql/queries-uteis.sql)
2. Crie dashboards: Com Metabase ou Superset
3. Monitore: KPIs semanais

### 🚀 Quero Automatizar Recuperação

1. Veja: [examples/curl-criar-agendamento.txt](examples/curl-criar-agendamento.txt)
2. Configure: Node HTTP Request no n8n
3. Valide: Resposta da API

---

## 📚 Documentação Detalhada

### README.md - Seções

1. **Visão Geral** - Introdução ao projeto
2. **Objetivos do Projeto** - O que queremos alcançar
3. **Arquitetura do Sistema** - Como tudo se conecta
4. **Autenticação** - Sistema JWT e tokens
5. **Endpoints Descobertos** - APIs mapeadas
6. **Estrutura de Dados** - Tabela de 62 campos
7. **Workflows n8n** - Fluxos completos
8. **Casos de Uso** - Exemplos práticos
9. **Troubleshooting** - Soluções de problemas

### SQL Scripts

#### criar-tabela-vendas-perdidas.sql
- Criação da tabela principal
- 62 campos organizados em 15 categorias
- Índices para performance
- Views úteis
- Triggers automáticos

#### queries-uteis.sql
- Estatísticas gerais
- Análise por motivo de perda
- Análise por profissional
- Análise de recuperação
- Candidatos para recuperação
- Análise de procedimentos
- Análise geográfica
- Análise temporal
- Relatórios consolidados

### Examples

#### payloads-api.md
- Exemplos de autenticação
- Exemplos de busca de orçamentos
- Exemplos de detalhes completos
- Exemplos de criação de agendamentos
- Estruturas JSONB
- Headers padrão
- Códigos de status

#### curl-criar-agendamento.txt
- cURL completo
- Configuração no n8n
- Descrição de cada campo
- Valores dinâmicos
- Exemplos de respostas

### Nodes

#### preparar-dados-supabase.js
- Código completo do node
- 62 campos mapeados
- Formatação JSONB
- Validações
- Comentários explicativos

---

## 🔗 Links Rápidos

### Documentação Externa

- [n8n Documentation](https://docs.n8n.io/)
- [Supabase Documentation](https://supabase.com/docs)
- [PostgreSQL JSONB](https://www.postgresql.org/docs/current/datatype-json.html)
- [JWT.io](https://jwt.io/) - Decodificador de tokens

### Ferramentas

- [Clinix Gestão](https://gestao.clinix.app.br)
- [Supabase Dashboard](https://app.supabase.com)
- [n8n Cloud](https://n8n.io)

---

## 📋 Checklists Rápidos

### ✅ Setup Completo

- [ ] Criar projeto Supabase
- [ ] Executar `criar-tabela-vendas-perdidas.sql`
- [ ] Instalar n8n
- [ ] Configurar credenciais Clinix
- [ ] Configurar credenciais Supabase
- [ ] Importar workflow de extração
- [ ] Testar workflow
- [ ] Agendar execução diária
- [ ] Configurar alertas

### ✅ Validação de Dados

- [ ] Verificar autenticação
- [ ] Testar extração de 1 venda
- [ ] Validar dados no Supabase
- [ ] Conferir JSONB de procedimentos
- [ ] Conferir JSONB de observações
- [ ] Validar datas
- [ ] Validar valores financeiros

### ✅ Recuperação Automática

- [ ] Configurar workflow de recuperação
- [ ] Definir critérios de elegibilidade
- [ ] Testar criação de agendamento
- [ ] Configurar notificações
- [ ] Implementar follow-up
- [ ] Monitorar taxa de conversão

---

## 🎓 Tutoriais Passo a Passo

### Tutorial 1: Primeira Extração

1. **Preparar Ambiente**
   ```bash
   # Criar pasta do projeto
   mkdir clinix-automation
   cd clinix-automation
   ```

2. **Configurar Supabase**
   ```sql
   -- Executar no SQL Editor
   -- Copiar de: sql/criar-tabela-vendas-perdidas.sql
   ```

3. **Configurar n8n**
   - Criar workflow
   - Adicionar nodes
   - Configurar credenciais

4. **Testar**
   - Executar manualmente
   - Verificar logs
   - Validar dados

### Tutorial 2: Criar Agendamento

1. **Preparar Dados**
   ```javascript
   // Ver: nodes/preparar-agendamento.js
   ```

2. **Configurar Node HTTP**
   ```
   # Ver: examples/curl-criar-agendamento.txt
   ```

3. **Validar Resposta**
   ```javascript
   // Verificar success: true
   ```

4. **Atualizar Status**
   ```sql
   UPDATE vendas_perdidas
   SET status_recuperacao = 'agendado'
   WHERE orcamento_id = ?;
   ```

### Tutorial 3: Dashboard de Análise

1. **Conectar Metabase**
   - URL: Supabase connection string
   - Usuário: postgres
   - Senha: sua senha

2. **Criar Visualizações**
   - Total de vendas perdidas
   - Gráfico de valores
   - Top motivos de perda
   - Taxa de recuperação

3. **Agendar Relatórios**
   - Diário: Novas vendas
   - Semanal: Estatísticas
   - Mensal: Relatório executivo

---

## 🆘 Troubleshooting Rápido

### Erro: Token Expirado
→ Ver: [README.md - Troubleshooting](README.md#troubleshooting)

### Erro: Dados Duplicados
→ Ver: [sql/criar-tabela-vendas-perdidas.sql](sql/criar-tabela-vendas-perdidas.sql) (UPSERT)

### Erro: Horário Ocupado
→ Ver: [examples/payloads-api.md](examples/payloads-api.md) (Resposta de erro)

### Workflow Lento
→ Ver: [QUICKSTART.md - Troubleshooting](QUICKSTART.md#troubleshooting)

---

## 📞 Suporte

### Documentação
- README completo: [README.md](README.md)
- Início rápido: [QUICKSTART.md](QUICKSTART.md)

### Código
- Nodes: [nodes/](nodes/)
- SQL: [sql/](sql/)
- Exemplos: [examples/](examples/)

### Comunidade
- Issues: GitHub
- Discussões: Forum
- Chat: Slack/Discord

---

## 🔄 Atualizações

### Versão 1.0.0 (Janeiro 2025)
- ✅ Documentação completa
- ✅ Scripts SQL
- ✅ Códigos dos nodes
- ✅ Exemplos de API
- ✅ Guia rápido

### Próximas Versões
- [ ] Workflow de WhatsApp
- [ ] Dashboard Metabase
- [ ] Integração CRM
- [ ] Automação de emails

---

**Última Atualização:** Janeiro 2025
**Versão:** 1.0.0
**Status:** ✅ Documentação Completa
