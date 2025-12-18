# Data Flow: Monitor Pro

## Visão Geral do Fluxo de Dados

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   TRIGGER   │────▶│   GOOGLE SEARCH  │────▶│   JINA READER   │
│   Manual    │     │   10 resultados  │     │   (paralelo)    │
└─────────────┘     └──────────────────┘     └────────┬────────┘
                                                      │
                                             ┌────────┴────────┐
                                             │                 │
                                             ▼                 ▼
                                    ┌─────────────┐   ┌─────────────────┐
                                    │ HTML/MD     │   │ JSON            │
                                    │ formata     │   │ formata         │
                                    │ conteudo    │   │ conteudo1       │
                                    └─────────────┘   └─────────────────┘
                                             │                 │
                                             ▼                 ▼
                                    ┌─────────────┐   ┌─────────────────┐
                                    │ Extração    │   │ Análise de      │
                                    │ Básica      │   │ Sentimento +    │
                                    │             │   │ Gestão de Crise │
                                    └─────────────┘   └─────────────────┘
```

---

## Transformações por Nó

### 1. `Monitora Noticias em sites e portais` (HTTP Request)

**Tipo**: HTTP Request → Google Custom Search API

**Entrada**: Nenhuma (parâmetros fixos)

**Saída**:
```typescript
interface GoogleSearchResponse {
  kind: "customsearch#search";
  url: {
    type: string;
    template: string;
  };
  queries: {
    request: QueryInfo[];
    nextPage: QueryInfo[];
  };
  searchInformation: {
    searchTime: number;
    formattedSearchTime: string;
    totalResults: string;
    formattedTotalResults: string;
  };
  items: SearchResult[];
}

interface SearchResult {
  kind: "customsearch#result";
  title: string;
  htmlTitle: string;
  link: string;           // URL do resultado
  displayLink: string;
  snippet: string;        // Resumo do conteúdo
  htmlSnippet: string;
  formattedUrl: string;
  pagemap?: {
    cse_thumbnail?: Array<{ src: string; width: string; height: string }>;
    metatags?: Array<Record<string, string>>;
    cse_image?: Array<{ src: string }>;
  };
}
```

**Mapeamento**:
| Campo Origem | Campo Destino | Transformação |
|--------------|---------------|---------------|
| Response | `items` | Array de resultados |
| `items[].link` | URL para Jina | Usado no próximo nó |

---

### 2. `Extrai conteudo dos Sites - html` (HTTP Request)

**Tipo**: HTTP Request → Jina Reader (formato Markdown)

**Entrada**: URL do resultado Google (via expressão n8n)
```javascript
"https://r.jina.ai/{{ $item(\"0\").$node[\"Monitora Noticias em sites e portais\"].json[\"items\"][\"2\"][\"link\"] }}"
```

**Saída**: String contendo Markdown estruturado
```
Title: Título da Página

URL Source: https://exemplo.com/noticia

Published Time: 2025-12-10T15:30:00Z

Markdown Content:
===============

Conteúdo da página convertido em Markdown...
```

---

### 3. `Extrai conteudo dos Sites - json` (HTTP Request)

**Tipo**: HTTP Request → Jina Reader (formato JSON)

**Entrada**: URL do resultado Google
```javascript
"https://r.jina.ai/{{ $item(\"0\").$node[\"Monitora Noticias em sites e portais\"].json[\"items\"][\"2\"][\"link\"] }}"
```

**Headers**:
```json
{
  "Accept": "application/json",
  "X-Return-Format": "json"
}
```

**Saída**:
```typescript
interface JinaResponse {
  code: number;  // 200 = sucesso
  data: {
    title: string;
    description: string;
    url: string;
    publishedTime: string;
    content: string;  // Texto completo da página
    metadata?: {
      og_site_name?: string;
      author?: string;
      // ... outros metadados OG
    };
  };
}
```

---

### 4. `formata conteudo` (Code Node)

**Tipo**: JavaScript Code → Processamento de Markdown

**Entrada**: `$input.item.json.data` (Markdown da Jina)

**Transformações**:

| Operação | Código | Descrição |
|----------|--------|-----------|
| Extrair título | `lines.find(l => l.startsWith('Title:'))` | Busca linha com prefixo |
| Extrair URL | `lines.find(l => l.startsWith('URL Source:'))` | Busca linha com prefixo |
| Extrair data | `lines.find(l => l.startsWith('Published Time:'))` | Busca linha com prefixo |
| Buscar menção | `content.toLowerCase().includes(cantor.toLowerCase())` | Case-insensitive |
| Extrair contexto | `substring(index-200, index+300)` | 500 chars de contexto |
| Limpar markdown | Múltiplos `.replace()` | Remove formatação |

**Filtros aplicados ao conteúdo**:
```javascript
// Remove linhas indesejadas
!line.startsWith('*   [')           // Links de menu
!line.startsWith('[Image')          // Referências de imagem
!line.includes('###')               // Headers markdown
!line.includes('[![')               // Links com imagem
line.trim().length > 0              // Linhas vazias
```

**Limpeza de formatação**:
```javascript
.replace(/\[([^\]]+)\]\([^)]+\)/g, '$1')  // [texto](link) → texto
.replace(/\*\*([^*]+)\*\*/g, '$1')        // **bold** → bold
.replace(/\*([^*]+)\*/g, '$1')            // *italic* → italic
.replace(/^#+\s/, '')                      // # Header → Header
.replace(/^-+$/, '')                       // --- → (remove)
.replace(/^\s*[-*]\s/, '• ')              // - item → • item
```

**Saída**:
```typescript
interface FormataConteudoOutput {
  titulo: string;
  url: string;
  dataPublicacao: string;
  mencionaCantor: boolean;
  trechoRelevante: string;     // 500 chars de contexto
  conteudoCompleto: string;    // Texto limpo
  categoria: "RELEVANTE" | "DESCARTADA";
}
```

---

### 5. `formata conteudo1` (Code Node) - PRINCIPAL

**Tipo**: JavaScript Code → Análise de Sentimento e Gestão de Crise

**Entrada**: `$input.item.json` (Response JSON da Jina)

**Transformações Complexas**:

#### 5.1 Validação Inicial
```javascript
if (!jinaResponse.data || jinaResponse.code !== 200) {
  return { json: { erro: "Resposta inválida da Jina", categoria: "ERRO" } };
}
```

#### 5.2 Extração de Metadados
| Campo Origem | Campo Destino | Fallback |
|--------------|---------------|----------|
| `data.title` | `titulo` | `''` |
| `data.description` | `descricao` | `''` |
| `data.url` | `url` | `''` |
| `data.publishedTime` | `dataPublicacao` | `''` |
| `data.metadata?.og_site_name` | `fonte` | Domínio extraído da URL |
| `data.metadata?.author` | `autor` | `'Não identificado'` |

#### 5.3 Análise de Sentimento
```javascript
// Palavras negativas com pesos (40+ palavras)
const palavrasNegativas = {
  "corrupção": { peso: 10, tipo: "ESCÂNDALO_CRIMINAL" },
  "lavagem": { peso: 10, tipo: "ESCÂNDALO_CRIMINAL" },
  "investigação": { peso: 7, tipo: "INVESTIGAÇÃO" },
  // ...
};

// Palavras positivas com pesos (20+ palavras)
const palavrasPositivas = {
  "sucesso": { peso: 8, tipo: "SUCESSO" },
  "prêmio": { peso: 8, tipo: "RECONHECIMENTO" },
  // ...
};

// Cálculo de pontuação
for (const [palavra, info] of Object.entries(palavrasNegativas)) {
  if (conteudoLower.includes(palavra)) {
    pontuacaoNegativa += info.peso;
    indicadoresNegativos.push({ palavra, tipo: info.tipo, peso: info.peso });
  }
}
```

#### 5.4 Classificação de Sentimento
| Condição | Sentimento | Nível Crise | Ação |
|----------|------------|-------------|------|
| `negativa >= 20` | MUITO_NEGATIVO | 7-10 | CRISE_URGENTE |
| `negativa >= 10` | NEGATIVO | 3-7 | PREPARAR_RESPOSTA |
| `negativa > 0` | LEVEMENTE_NEGATIVO | 1-4 | MONITORAR_EVOLUÇÃO |
| `positiva >= 20` | MUITO_POSITIVO | 0 | AMPLIFICAR_MENSAGEM |
| `positiva >= 10` | POSITIVO | 0 | COMPARTILHAR |
| `positiva > 0` | LEVEMENTE_POSITIVO | 0 | ACOMPANHAR |
| `igual` | NEUTRO | 0 | MONITORAR |

#### 5.5 Determinação de Urgência
```javascript
let urgencia = "NORMAL";
if (nivelCrise >= 8) urgencia = "CRÍTICA";
else if (nivelCrise >= 5) urgencia = "ALTA";
else if (nivelCrise >= 3) urgencia = "MÉDIA";
```

#### 5.6 Identificação de Stakeholders
```javascript
if (conteudoLower.includes("fã") || conteudoLower.includes("público"))
  stakeholdersAfetados.push("Fãs");
if (conteudoLower.includes("patrocin") || conteudoLower.includes("marca"))
  stakeholdersAfetados.push("Patrocinadores");
if (conteudoLower.includes("família"))
  stakeholdersAfetados.push("Família");
// ...
```

#### 5.7 Decisão de Canal de Notificação
```javascript
canalNotificacao: urgencia === "CRÍTICA" ? "TODOS_CANAIS_URGENTE" :
                  urgencia === "ALTA" ? "WHATSAPP_TELEGRAM" :
                  "EMAIL_RELATORIO"
```

**Saída Completa**:
```typescript
interface FormataConteudo1Output {
  // Informações básicas
  titulo: string;
  descricao: string;
  url: string;
  dataPublicacao: string;
  fonte: string;
  autor: string;

  // Análise de sentimento e crise
  mencionaCantor: boolean;
  sentimento: SentimentoType;
  tipoNoticia: TipoNoticiaType;
  nivelCrise: number;        // 0-10
  urgencia: UrgenciaType;

  // Indicadores detalhados
  indicadoresNegativos: Indicador[];
  indicadoresPositivos: Indicador[];
  pontuacaoNegativa: number;
  pontuacaoPositiva: number;

  // Gestão de crise
  acaoRecomendada: AcaoType;
  sugestaoAcao: string;
  stakeholdersAfetados: string[];

  // Conteúdo processado
  trechoRelevante: string;
  conteudoCompleto: string;

  // Controle de envio
  deveNotificarEquipe: boolean;
  notificacaoUrgente: boolean;
  canalNotificacao: CanalType;
}

type SentimentoType =
  | "MUITO_NEGATIVO" | "NEGATIVO" | "LEVEMENTE_NEGATIVO"
  | "NEUTRO"
  | "LEVEMENTE_POSITIVO" | "POSITIVO" | "MUITO_POSITIVO";

type TipoNoticiaType =
  | "ESCÂNDALO" | "PROBLEMA" | "CONTROVÉRSIA"
  | "INFORMATIVA"
  | "MENÇÃO_POSITIVA" | "BOA_NOTÍCIA" | "GRANDE_CONQUISTA";

type UrgenciaType = "NORMAL" | "MÉDIA" | "ALTA" | "CRÍTICA";

type AcaoType =
  | "CRISE_URGENTE" | "PREPARAR_RESPOSTA" | "MONITORAR_EVOLUÇÃO"
  | "MONITORAR"
  | "ACOMPANHAR" | "COMPARTILHAR" | "AMPLIFICAR_MENSAGEM";

type CanalType = "EMAIL_RELATORIO" | "WHATSAPP_TELEGRAM" | "TODOS_CANAIS_URGENTE";

interface Indicador {
  palavra: string;
  tipo: string;
  peso: number;
}
```

---

### 6. `formata conteudo2 // Codigo antigo` (Code Node - DESCONECTADO)

**Status**: ❌ Não conectado no fluxo (código legado)

**Funcionalidade**: Versão simplificada do `formata conteudo1` sem análise de sentimento profunda.

Categorização básica:
- SHOW → "show", "apresentação", "festival"
- LANÇAMENTO → "música nova", "single", "álbum"
- POLÊMICA → "polêmica", "controversia", "crítica"
- POLÍTICA → "milhão", "gastos", "prefeitura"
- MENÇÃO → default

---

## Schemas de Dados

### Schema de Entrada (nenhum)
```json
null
```
> Workflow é disparado manualmente sem input.

### Schema de Saída - Fluxo HTML
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "titulo": { "type": "string" },
    "url": { "type": "string", "format": "uri" },
    "dataPublicacao": { "type": "string", "format": "date-time" },
    "mencionaCantor": { "type": "boolean" },
    "trechoRelevante": { "type": "string", "maxLength": 500 },
    "conteudoCompleto": { "type": "string" },
    "categoria": { "enum": ["RELEVANTE", "DESCARTADA"] }
  },
  "required": ["titulo", "url", "mencionaCantor", "categoria"]
}
```

### Schema de Saída - Fluxo JSON (Principal)
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "titulo": { "type": "string" },
    "descricao": { "type": "string" },
    "url": { "type": "string", "format": "uri" },
    "dataPublicacao": { "type": "string" },
    "fonte": { "type": "string" },
    "autor": { "type": "string" },

    "mencionaCantor": { "type": "boolean" },
    "sentimento": {
      "enum": ["MUITO_NEGATIVO", "NEGATIVO", "LEVEMENTE_NEGATIVO",
               "NEUTRO",
               "LEVEMENTE_POSITIVO", "POSITIVO", "MUITO_POSITIVO"]
    },
    "tipoNoticia": { "type": "string" },
    "nivelCrise": { "type": "integer", "minimum": 0, "maximum": 10 },
    "urgencia": { "enum": ["NORMAL", "MÉDIA", "ALTA", "CRÍTICA"] },

    "indicadoresNegativos": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "palavra": { "type": "string" },
          "tipo": { "type": "string" },
          "peso": { "type": "integer" }
        }
      }
    },
    "indicadoresPositivos": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "palavra": { "type": "string" },
          "tipo": { "type": "string" },
          "peso": { "type": "integer" }
        }
      }
    },
    "pontuacaoNegativa": { "type": "integer", "minimum": 0 },
    "pontuacaoPositiva": { "type": "integer", "minimum": 0 },

    "acaoRecomendada": { "type": "string" },
    "sugestaoAcao": { "type": "string" },
    "stakeholdersAfetados": {
      "type": "array",
      "items": { "type": "string" }
    },

    "trechoRelevante": { "type": "string" },
    "conteudoCompleto": { "type": "string" },

    "deveNotificarEquipe": { "type": "boolean" },
    "notificacaoUrgente": { "type": "boolean" },
    "canalNotificacao": {
      "enum": ["EMAIL_RELATORIO", "WHATSAPP_TELEGRAM", "TODOS_CANAIS_URGENTE"]
    }
  },
  "required": ["titulo", "url", "mencionaCantor", "sentimento", "nivelCrise"]
}
```

---

## Variáveis e Constantes Hardcoded

| Variável | Valor | Localização | Impacto |
|----------|-------|-------------|---------|
| `cantor` | `"Gusttavo Lima"` | formata conteudo, formata conteudo1 | Entidade monitorada fixa |
| `key` | `"AIzaSyA7..."` | HTTP Request | API Key exposta |
| `cx` | `"35acabbbfcd444d7a"` | HTTP Request | Search Engine ID exposto |
| `q` | `"vereador Roberto Ricardo"` | HTTP Request | Termo de busca fixo |
| `dateRestrict` | `"y1"` | HTTP Request | Apenas último ano |
| `num` | `"10"` | HTTP Request | Máximo 10 resultados |

---

## Fluxo de Erros

```
┌────────────────────────────────────────────────────────────┐
│                    TRATAMENTO DE ERROS                     │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Google Search falha                                       │
│       │                                                    │
│       └──▶ Workflow para silenciosamente                   │
│            (sem tratamento explícito)                      │
│                                                            │
│  Jina Reader retorna code !== 200                          │
│       │                                                    │
│       └──▶ formata conteudo1 retorna:                      │
│            { erro: "Resposta inválida", categoria: "ERRO" }│
│                                                            │
│  URL inacessível                                           │
│       │                                                    │
│       └──▶ Jina retorna erro                               │
│            (propagado ao próximo nó)                       │
│                                                            │
└────────────────────────────────────────────────────────────┘
```
