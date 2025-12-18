# 🚀 Guia Rápido - Clinix Automation

## ⚡ Início Rápido em 5 Minutos

### 1️⃣ Configurar Supabase

```bash
# Criar projeto no Supabase
# https://app.supabase.com

# Executar SQL
psql -h seu-projeto.supabase.co -U postgres -d postgres -f sql/criar-tabela-vendas-perdidas.sql
```

### 2️⃣ Configurar n8n

```bash
# Importar workflow
n8n import:workflow clinix-extracao-vendas-perdidas.json

# Configurar credenciais
# - Clinix Login: henrique.silva@nst.com.br
# - Clinix Senha: Teste@123
# - Supabase URL: https://seu-projeto.supabase.co
# - Supabase Key: sua-chave-anon
```

### 3️⃣ Executar Workflow

```bash
# Teste manual
n8n execute --id workflow-id

# Agendar execução diária (8h)
Cron: 0 8 * * *
```

---

## 📋 Checklist de Implementação

### Setup Inicial

- [ ] Criar conta Supabase
- [ ] Criar tabela `vendas_perdidas`
- [ ] Instalar n8n
- [ ] Configurar credenciais Clinix
- [ ] Configurar credenciais Supabase

### Workflow 1: Extração

- [ ] Node 1: Gera Token de Acesso
- [ ] Node 2: Obtém Variáveis de Requisição
- [ ] Node 3: Busca Orçamentos
- [ ] Node 4: Filtra Somente PERDIDOS
- [ ] Node 5: Buscar Detalhes Orçamento
- [ ] Node 6: Preparar Dados Supabase
- [ ] Node 7: Inserir no Supabase

### Workflow 2: Recuperação

- [ ] Node 1: Buscar Candidatos (Supabase)
- [ ] Node 2: Preparar Agendamento
- [ ] Node 3: Criar Consulta (POST)
- [ ] Node 4: Validar Resposta
- [ ] Node 5: Atualizar Status

### Validação

- [ ] Testar autenticação
- [ ] Testar extração de 1 venda
- [ ] Verificar dados no Supabase
- [ ] Testar criação de agendamento
- [ ] Verificar logs de erro

---

## 🎯 Fluxos Principais

### Fluxo 1: Extração Diária

```
Trigger: Cron (8h todos os dias)
   ↓
Login → Buscar Orçamentos → Filtrar Perdidos
   ↓
Buscar Detalhes (para cada) → Preparar Dados
   ↓
Inserir no Supabase → Notificar (email/slack)
```

### Fluxo 2: Recuperação Automática

```
Trigger: Manual ou Webhook
   ↓
Buscar Candidatos (Supabase) → Filtrar Elegíveis
   ↓
Preparar Agendamento → Criar Consulta (API)
   ↓
Atualizar Status → Notificar Responsável
```

---

## 🔧 Configurações Importantes

### Variáveis de Ambiente

```bash
# n8n
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=sua-senha-forte

# Clinix
CLINIX_LOGIN=seu-email@example.com
CLINIX_PASSWORD=sua-senha
CLINIX_CONTA_ID=62

# Supabase
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_KEY=sua-chave-anon-key
```

### Credenciais n8n

```json
{
  "name": "Clinix API",
  "type": "httpBasicAuth",
  "data": {
    "user": "henrique.silva@nst.com.br",
    "password": "Teste@123"
  }
}
```

```json
{
  "name": "Supabase",
  "type": "supabaseApi",
  "data": {
    "host": "https://seu-projeto.supabase.co",
    "serviceRole": "sua-service-role-key"
  }
}
```

---

## 📊 Monitoramento

### Queries de Verificação

```sql
-- Total de registros hoje
SELECT COUNT(*) FROM vendas_perdidas
WHERE DATE(sincronizado_em) = CURRENT_DATE;

-- Últimas 10 vendas
SELECT orcamento_id, paciente_nome, valor_final, sincronizado_em
FROM vendas_perdidas
ORDER BY sincronizado_em DESC
LIMIT 10;

-- Erros de sincronização (verificar logs)
SELECT COUNT(*) FROM vendas_perdidas
WHERE dados_completos_json IS NULL;
```

### Logs do n8n

```bash
# Ver logs em tempo real
docker logs -f n8n

# Filtrar erros
docker logs n8n 2>&1 | grep ERROR

# Exportar logs
docker logs n8n > n8n-logs.txt 2>&1
```

---

## ⚠️ Troubleshooting

### Problema: Token Expirado

**Sintoma:** Erro 401 Unauthorized

**Solução:**
```javascript
// Adicionar refresh automático no workflow
if (error.statusCode === 401) {
  // Re-executar node de autenticação
  return { rerun: true };
}
```

### Problema: Dados Duplicados

**Sintoma:** Erro de constraint unique

**Solução:**
```sql
-- Usar UPSERT
INSERT INTO vendas_perdidas (...)
VALUES (...)
ON CONFLICT (orcamento_id)
DO UPDATE SET
  atualizado_em = NOW(),
  ...;
```

### Problema: Workflow Lento

**Sintoma:** Timeout após 2 minutos

**Solução:**
- Aumentar timeout do n8n
- Processar em batches menores
- Usar paralelização

```javascript
// Processar em batches de 10
const batch = items.slice(0, 10);
```

---

## 📈 Métricas de Sucesso

### KPIs Semanais

```sql
-- Taxa de extração
SELECT
  COUNT(*) as total_extraido,
  COUNT(*) FILTER (WHERE sincronizado_em > NOW() - INTERVAL '7 days') as extraido_semana
FROM vendas_perdidas;

-- Taxa de recuperação
SELECT
  COUNT(*) FILTER (WHERE status_recuperacao = 'recuperado') as recuperados,
  COUNT(*) as total,
  ROUND(
    (COUNT(*) FILTER (WHERE status_recuperacao = 'recuperado')::NUMERIC / COUNT(*)) * 100,
    2
  ) as taxa_pct
FROM vendas_perdidas;
```

### Dashboard Supabase

Criar dashboard com:
- Total de vendas perdidas
- Valor total perdido
- Top 5 motivos de perda
- Taxa de recuperação mensal
- Próximas ações agendadas

---

## 🔄 Rotina de Manutenção

### Diária

- [ ] Verificar execução do workflow
- [ ] Conferir logs de erro
- [ ] Validar dados do dia anterior

### Semanal

- [ ] Revisar taxa de recuperação
- [ ] Atualizar queries de análise
- [ ] Limpar registros antigos (>1 ano)

### Mensal

- [ ] Relatório executivo
- [ ] Otimizar índices do banco
- [ ] Backup completo

```sql
-- Backup mensal
pg_dump -h seu-projeto.supabase.co -U postgres -d postgres -t vendas_perdidas > backup_vendas_$(date +%Y%m).sql
```

---

## 📚 Recursos

### Documentação

- `README.md` - Documentação completa
- `QUICKSTART.md` - Este guia
- `nodes/` - Códigos dos nodes
- `sql/` - Scripts SQL
- `examples/` - Exemplos de payloads

### Links Úteis

- [n8n Docs](https://docs.n8n.io/)
- [Supabase Docs](https://supabase.com/docs)
- [Clinix](https://gestao.clinix.app.br)

### Suporte

- Email: suporte@exemplo.com
- Slack: #clinix-automation
- GitHub Issues: github.com/seu-repo/issues

---

## ✅ Próximos Passos

1. **Automatizar Recuperação**
   - Criar workflow de follow-up
   - Integrar com WhatsApp/Email
   - Agendar callbacks

2. **Dashboard Analytics**
   - Conectar Supabase → Metabase
   - Criar relatórios visuais
   - Alertas automáticos

3. **Expansão**
   - Extrair outros dados (agendamentos, pagamentos)
   - Integrar com CRM
   - Automação completa de vendas

---

**Versão:** 1.0.0
**Última Atualização:** Janeiro 2025
**Status:** ✅ Pronto para Produção
