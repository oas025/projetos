# Side Effects: Monitor Pro

## Resumo de Operações

| Categoria | Quantidade | Reversível |
|-----------|------------|------------|
| 🆕 CREATE | 0 | - |
| ✏️ UPDATE | 0 | - |
| 🗑️ DELETE | 0 | - |
| 📤 SEND | 0 | - |
| ⚡ CALL | 3 | N/A |

> **Importante**: Este workflow é **READ-ONLY** - não persiste dados, não envia mensagens, apenas processa e analisa informações em memória.

---

## ⚡ CALL - Chamadas de API

### 1. Google Custom Search API

| Atributo | Valor |
|----------|-------|
| **Nó** | `Monitora Noticias em sites e portais` |
| **Endpoint** | `https://www.googleapis.com/customsearch/v1` |
| **Método** | GET |
| **Frequência** | 1x por execução |
| **Custo** | ~$0.005 USD por query (100 queries/dia gratuitas) |
| **Rate Limit** | 100 queries/dia (plano gratuito) |

**Parâmetros enviados:**
```json
{
  "key": "AIzaSyA7aMXuUunTqVvXCgHwmUdWzSUzHGuimTo",
  "cx": "35acabbbfcd444d7a",
  "q": "vereador Roberto Ricardo",
  "cr": "countryBR",
  "lr": "lang_pt",
  "dateRestrict": "y1",
  "num": "10",
  "sort": "date"
}
```

**Dados retornados:**
- Lista de até 10 URLs de notícias
- Título, snippet, link de cada resultado
- Metadados de paginação

---

### 2. Jina Reader API (HTML Format)

| Atributo | Valor |
|----------|-------|
| **Nó** | `Extrai conteudo dos Sites - html` |
| **Endpoint** | `https://r.jina.ai/{URL}` |
| **Método** | GET |
| **Frequência** | 1x por URL encontrada (até 10/execução) |
| **Custo** | Gratuito |
| **Rate Limit** | Não especificado |

**Headers:**
```
Accept: text/html (default)
```

**Dados retornados:**
- Conteúdo da página em formato Markdown
- Título, URL, data de publicação extraídos do HTML

---

### 3. Jina Reader API (JSON Format)

| Atributo | Valor |
|----------|-------|
| **Nó** | `Extrai conteudo dos Sites - json` |
| **Endpoint** | `https://r.jina.ai/{URL}` |
| **Método** | GET |
| **Frequência** | 1x por URL encontrada (até 10/execução) |
| **Custo** | Gratuito |
| **Rate Limit** | Não especificado |

**Headers:**
```
Accept: application/json
X-Return-Format: json
```

**Dados retornados:**
```json
{
  "code": 200,
  "data": {
    "title": "Título da página",
    "description": "Meta description",
    "url": "URL original",
    "publishedTime": "2025-12-10T15:30:00Z",
    "content": "Conteúdo completo em texto",
    "metadata": {
      "og_site_name": "Nome do site",
      "author": "Autor"
    }
  }
}
```

---

## Estimativa de Custos

### Por Execução Manual
| API | Chamadas | Custo Unitário | Total |
|-----|----------|----------------|-------|
| Google Custom Search | 1 | $0.005 | $0.005 |
| Jina Reader | 20 (10 HTML + 10 JSON) | $0.00 | $0.00 |
| **TOTAL** | 21 | - | **~$0.005** |

### Projeção Mensal (se automatizado)

| Frequência | Execuções/Mês | Custo Google | Custo Total |
|------------|---------------|--------------|-------------|
| 1x/hora | 720 | $3.60 | $3.60 |
| 4x/dia | 120 | $0.60 | $0.60 |
| 1x/dia | 30 | $0.15 | $0.15 |

> **Nota**: Plano gratuito do Google Custom Search inclui 100 queries/dia. Acima disso, cada 1000 queries custa $5.

---

## O Que Este Workflow NÃO Faz

| Operação | Status | Consequência |
|----------|--------|--------------|
| Salvar em banco de dados | ❌ Não implementado | Dados perdidos após execução |
| Enviar notificações | ❌ Não implementado | Equipe não é alertada |
| Deduplicar notícias | ❌ Não implementado | Mesma notícia pode ser analisada várias vezes |
| Histórico de crises | ❌ Não implementado | Sem análise temporal |
| Rate limiting | ❌ Não implementado | Pode exceder quotas |

---

## Dados Sensíveis Expostos

| Dado | Localização | Risco | Recomendação |
|------|-------------|-------|--------------|
| API Key Google | `Monitora Noticias em sites e portais` → `key` | 🔴 ALTO | Mover para variável de ambiente |
| Custom Search Engine ID | `Monitora Noticias em sites e portais` → `cx` | 🟡 MÉDIO | Mover para variável de ambiente |

---

## Impacto em Sistemas Externos

### Google Custom Search
- **Consumo de quota**: 1 query por execução
- **Limite diário**: 100 queries gratuitas
- **Billing**: Ativado automaticamente se exceder quota

### Jina Reader
- **Fair Use**: Uso intensivo pode resultar em rate limiting
- **Sem autenticação**: Qualquer pessoa pode usar a API
- **Dependência**: Se Jina sair do ar, workflow falha

### Sites Alvo (via Jina)
- **Crawling**: Jina faz crawl dos sites em nome do workflow
- **robots.txt**: Jina pode respeitar ou não regras de crawling
- **Bloqueio**: Sites podem bloquear o bot do Jina

---

## Rollback/Recovery

> **Não aplicável** - Este workflow não modifica dados persistentes.

Se necessário "desfazer" uma execução:
1. Não há necessidade - nenhum dado foi salvo
2. Se integrado com notificações no futuro, mensagens enviadas são irreversíveis

---

## Queries de Monitoramento

```sql
-- N/A: Workflow não persiste dados

-- Se integrado com Supabase no futuro:

-- Ver notícias analisadas
SELECT * FROM noticias_monitoradas
ORDER BY data_analise DESC
LIMIT 100;

-- Ver crises detectadas
SELECT * FROM noticias_monitoradas
WHERE nivel_crise >= 5
ORDER BY nivel_crise DESC;

-- Ver notícias positivas
SELECT * FROM noticias_monitoradas
WHERE sentimento LIKE '%POSITIVO%'
ORDER BY pontuacao_positiva DESC;
```
