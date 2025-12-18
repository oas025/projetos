# Integrações: Monitor Pro

## Resumo das Integrações

| Sistema | Tipo | Autenticação | Rate Limit | Custo |
|---------|------|--------------|------------|-------|
| Google Custom Search | REST API | API Key | 100/dia (free) | $5/1000 queries |
| Jina Reader | REST API | Nenhuma | Fair use | Gratuito |

---

## 1. Google Custom Search API

### Visão Geral

| Atributo | Valor |
|----------|-------|
| **Base URL** | `https://www.googleapis.com/customsearch/v1` |
| **Protocolo** | REST |
| **Formato** | JSON |
| **Documentação** | [Google Custom Search JSON API](https://developers.google.com/custom-search/v1/overview) |

### Autenticação

| Parâmetro | Valor | Tipo |
|-----------|-------|------|
| `key` | `AIzaSyA7aMXuUunTqVvXCgHwmUdWzSUzHGuimTo` | API Key |
| `cx` | `35acabbbfcd444d7a` | Custom Search Engine ID |

> **ATENÇÃO**: API Key exposta no workflow. Mover para variáveis de ambiente.

### Endpoint Utilizado

#### GET /customsearch/v1

**Descrição**: Busca notícias em sites e portais indexados pelo Google.

**Parâmetros Query**:
| Parâmetro | Valor | Descrição |
|-----------|-------|-----------|
| `key` | (required) | API Key do projeto Google Cloud |
| `cx` | (required) | ID do Custom Search Engine |
| `q` | `"vereador Roberto Ricardo"` | Termo de busca |
| `cr` | `"countryBR"` | Restringir ao Brasil |
| `lr` | `"lang_pt"` | Apenas resultados em português |
| `dateRestrict` | `"y1"` | Últimos 12 meses |
| `num` | `"10"` | Número de resultados (max 10) |
| `sort` | `"date"` | Ordenar por data |

**cURL de Exemplo**:
```bash
curl -X GET "https://www.googleapis.com/customsearch/v1?key=AIzaSyA7aMXuUunTqVvXCgHwmUdWzSUzHGuimTo&cx=35acabbbfcd444d7a&q=vereador%20Roberto%20Ricardo&cr=countryBR&lr=lang_pt&dateRestrict=y1&num=10&sort=date"
```

**Response de Sucesso** (200):
```json
{
  "kind": "customsearch#search",
  "url": {
    "type": "application/json",
    "template": "https://www.googleapis.com/customsearch/v1?..."
  },
  "queries": {
    "request": [{
      "title": "Google Custom Search - vereador Roberto Ricardo",
      "totalResults": "28100",
      "searchTerms": "vereador Roberto Ricardo",
      "count": 10,
      "startIndex": 1,
      "language": "lang_pt",
      "cr": "countryBR",
      "dateRestrict": "y1"
    }],
    "nextPage": [{
      "startIndex": 11
    }]
  },
  "searchInformation": {
    "searchTime": 0.273988,
    "totalResults": "28100"
  },
  "items": [
    {
      "kind": "customsearch#result",
      "title": "Título da notícia",
      "link": "https://exemplo.com/noticia",
      "displayLink": "exemplo.com",
      "snippet": "Resumo da notícia...",
      "pagemap": {
        "metatags": [{
          "og:title": "Título OG",
          "og:description": "Descrição OG"
        }]
      }
    }
  ]
}
```

**Erros Possíveis**:
| Código | Significado | Causa |
|--------|-------------|-------|
| 400 | Bad Request | Parâmetros inválidos |
| 403 | Forbidden | API Key inválida ou quota excedida |
| 429 | Too Many Requests | Rate limit excedido |
| 500 | Internal Error | Erro no servidor Google |

### Rate Limits e Custos

| Plano | Limite Diário | Custo |
|-------|---------------|-------|
| Gratuito | 100 queries/dia | $0 |
| Pago | 10.000 queries/dia | $5 por 1000 queries |

**Cálculo de Quota**:
- 1 execução = 1 query
- 100 execuções/dia = limite gratuito
- ~4 execuções/hora (se 24/7)

---

## 2. Jina Reader API

### Visão Geral

| Atributo | Valor |
|----------|-------|
| **Base URL** | `https://r.jina.ai` |
| **Protocolo** | REST |
| **Formato** | HTML/Markdown ou JSON |
| **Documentação** | [Jina Reader](https://jina.ai/reader/) |

### Autenticação

Nenhuma autenticação necessária (API pública).

### Endpoints Utilizados

#### GET /r.jina.ai/{url}

**Descrição**: Extrai e converte conteúdo de uma URL para formato legível.

##### Modo HTML/Markdown (Default)

**Headers**: Nenhum especial (default)

**cURL de Exemplo**:
```bash
curl -X GET "https://r.jina.ai/https://exemplo.com/noticia"
```

**Response**: Texto em formato Markdown
```
Title: Título da Página

URL Source: https://exemplo.com/noticia

Published Time: 2025-12-10T15:30:00Z

Markdown Content:
===============

# Título Principal

Conteúdo da página convertido para Markdown...

## Subtítulo

Mais conteúdo...
```

##### Modo JSON

**Headers**:
```
Accept: application/json
X-Return-Format: json
```

**cURL de Exemplo**:
```bash
curl -X GET "https://r.jina.ai/https://exemplo.com/noticia" \
  -H "Accept: application/json" \
  -H "X-Return-Format: json"
```

**Response de Sucesso** (200):
```json
{
  "code": 200,
  "data": {
    "title": "Título da Página",
    "description": "Meta description da página",
    "url": "https://exemplo.com/noticia",
    "publishedTime": "2025-12-10T15:30:00Z",
    "content": "Conteúdo completo em texto plano...",
    "metadata": {
      "og_site_name": "Nome do Site",
      "og_image": "https://exemplo.com/imagem.jpg",
      "author": "Nome do Autor",
      "keywords": "palavra1, palavra2"
    }
  }
}
```

**Erros Possíveis**:
| Código | Significado | Causa |
|--------|-------------|-------|
| 400 | Bad Request | URL inválida |
| 403 | Forbidden | Site bloqueou acesso |
| 408 | Timeout | Site demorou a responder |
| 500 | Internal Error | Erro no Jina Reader |

### Limitações Conhecidas

| Limitação | Descrição |
|-----------|-----------|
| Sites dinâmicos | JavaScript pesado pode não ser renderizado |
| Paywalls | Conteúdo protegido não é acessível |
| Rate limiting | Uso excessivo pode ser bloqueado |
| robots.txt | Alguns sites podem bloquear crawlers |

---

## Configuração no n8n

### Node: HTTP Request (Google Search)

```json
{
  "parameters": {
    "url": "https://www.googleapis.com/customsearch/v1",
    "sendQuery": true,
    "queryParameters": {
      "parameters": [
        { "name": "key", "value": "AIzaSyA7aMXuUunTqVvXCgHwmUdWzSUzHGuimTo" },
        { "name": "cx", "value": "35acabbbfcd444d7a" },
        { "name": "q", "value": "vereador Roberto Ricardo" },
        { "name": "cr", "value": "countryBR" },
        { "name": "lr", "value": "lang_pt" },
        { "name": "dateRestrict", "value": "y1" },
        { "name": "num", "value": "10" },
        { "name": "sort", "value": "date" }
      ]
    }
  },
  "type": "n8n-nodes-base.httpRequest",
  "typeVersion": 4.2
}
```

### Node: HTTP Request (Jina - HTML)

```json
{
  "parameters": {
    "url": "=https://r.jina.ai/{{ $item(\"0\").$node[\"Monitora Noticias em sites e portais\"].json[\"items\"][\"2\"][\"link\"] }}",
    "options": {}
  },
  "type": "n8n-nodes-base.httpRequest",
  "typeVersion": 4.2
}
```

### Node: HTTP Request (Jina - JSON)

```json
{
  "parameters": {
    "url": "=https://r.jina.ai/{{ $item(\"0\").$node[\"Monitora Noticias em sites e portais\"].json[\"items\"][\"2\"][\"link\"] }}",
    "sendHeaders": true,
    "headerParameters": {
      "parameters": [
        { "name": "Accept", "value": "application/json" },
        { "name": "X-Return-Format", "value": "json" }
      ]
    }
  },
  "type": "n8n-nodes-base.httpRequest",
  "typeVersion": 4.2
}
```

---

## Recomendações de Segurança

### 1. Mover API Keys para Variáveis de Ambiente

**Atual** (inseguro):
```json
{ "name": "key", "value": "AIzaSyA7aMXuUunTqVvXCgHwmUdWzSUzHGuimTo" }
```

**Recomendado**:
```json
{ "name": "key", "value": "={{ $env.GOOGLE_API_KEY }}" }
```

**No servidor n8n**:
```bash
export GOOGLE_API_KEY="AIzaSyA7aMXuUunTqVvXCgHwmUdWzSUzHGuimTo"
export GOOGLE_CX="35acabbbfcd444d7a"
```

### 2. Implementar Rate Limiting

```javascript
// No início do workflow
const RATE_LIMIT = {
  maxPerMinute: 10,
  maxPerDay: 100
};

// Verificar quota antes de executar
```

### 3. Adicionar Retry Logic

```javascript
// Configurar no HTTP Request
{
  "options": {
    "retry": {
      "maxRetries": 3,
      "retryInterval": 1000,
      "retryOnStatus": [429, 500, 502, 503]
    }
  }
}
```

---

## Integrações Futuras Sugeridas

| Sistema | Uso | Prioridade |
|---------|-----|------------|
| **Supabase/PostgreSQL** | Persistência de notícias e histórico | 🔴 Alta |
| **WhatsApp/Evolution** | Alertas de crise | 🔴 Alta |
| **Telegram Bot** | Notificações em tempo real | 🟡 Média |
| **SendGrid/Email** | Relatórios diários | 🟡 Média |
| **Google Sheets** | Dashboard simples | ℹ️ Baixa |
| **Slack** | Alertas para equipe | ℹ️ Baixa |

---

## Diagrama de Integração

```
┌─────────────────────────────────────────────────────────────────────┐
│                        MONITOR PRO                                  │
│                                                                     │
│  ┌──────────┐                                                       │
│  │ n8n      │                                                       │
│  │ Workflow │                                                       │
│  └────┬─────┘                                                       │
│       │                                                             │
│       │ 1. GET /customsearch/v1                                     │
│       ▼                                                             │
│  ┌────────────────────────────────┐                                │
│  │  GOOGLE CUSTOM SEARCH          │                                │
│  │  ─────────────────────────     │                                │
│  │  • API Key Authentication      │                                │
│  │  • 100 queries/day (free)      │                                │
│  │  • Returns 10 URLs             │                                │
│  └────────────────────────────────┘                                │
│       │                                                             │
│       │ 2. GET r.jina.ai/{url}                                     │
│       ▼                                                             │
│  ┌────────────────────────────────┐                                │
│  │  JINA READER                   │                                │
│  │  ─────────────────────────     │                                │
│  │  • No Authentication           │                                │
│  │  • Free tier                   │                                │
│  │  • HTML or JSON response       │                                │
│  └────────────────────────────────┘                                │
│       │                                                             │
│       │ 3. Processed data                                          │
│       ▼                                                             │
│  ┌────────────────────────────────┐                                │
│  │  OUTPUT                        │                                │
│  │  ─────────────────────────     │                                │
│  │  • Sentiment analysis          │                                │
│  │  • Crisis level (0-10)         │                                │
│  │  • Recommended action          │                                │
│  │  • (NOT PERSISTED)             │                                │
│  └────────────────────────────────┘                                │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘

EXTERNAL SERVICES:
──────────────────
                    ┌─────────────────┐
                    │  Google Cloud   │
                    │  Custom Search  │
                    │  API            │
                    └─────────────────┘
                           ↕
                    ┌─────────────────┐
                    │  Jina AI        │
                    │  Reader Service │
                    └─────────────────┘
```
