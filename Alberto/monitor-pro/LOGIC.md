# Lógica: Monitor Pro - Sistema de Monitoramento de Notícias

## 1. Objetivo

Sistema de monitoramento de mídia que busca notícias sobre uma pessoa/entidade específica (atualmente configurado para buscar "Gusttavo Lima" e "vereador Roberto Ricardo"), extrai o conteúdo das páginas encontradas, analisa sentimento e relevância, e classifica as menções para gestão de crise de imagem.

## 2. Trigger (O que dispara)

| Tipo | Configuração | Descrição |
|------|--------------|-----------|
| **Manual** | `manualTrigger` | Clique no botão "Test workflow" no n8n |

> **Nota**: Workflow está **INATIVO** (`active: false`) - é um protótipo/POC, não está em produção.

## 3. Algoritmo (Pseudocódigo)

```
INÍCIO monitor_noticias()

    // PASSO 1: Buscar notícias no Google
    resultado_busca = CHAMAR_API(
        url: "https://www.googleapis.com/customsearch/v1",
        params: {
            key: "AIzaSyA7aMXuUunTqVvXCgHwmUdWzSUzHGuimTo",
            cx: "35acabbbfcd444d7a",
            q: "vereador Roberto Ricardo",  // Termo de busca configurável
            cr: "countryBR",                 // Apenas resultados do Brasil
            lr: "lang_pt",                   // Apenas em português
            dateRestrict: "y1",              // Último ano
            num: 10,                         // 10 resultados
            sort: "date"                     // Ordenar por data
        }
    )

    // PASSO 2: Para cada item encontrado (PARALELO - 2 fluxos)
    PARA CADA item EM resultado_busca.items:

        // FLUXO A: Extração HTML (via Jina Reader)
        conteudo_html = CHAMAR_API(
            url: "https://r.jina.ai/{item.link}",
            headers: { Accept: "text/html" }
        )
        dados_formatados_html = formata_conteudo(conteudo_html)

        // FLUXO B: Extração JSON (via Jina Reader)
        conteudo_json = CHAMAR_API(
            url: "https://r.jina.ai/{item.link}",
            headers: {
                Accept: "application/json",
                X-Return-Format: "json"
            }
        )
        dados_formatados_json = formata_conteudo1(conteudo_json)

FIM

// ===============================================
// FUNÇÃO: formata_conteudo (para HTML/Markdown)
// ===============================================
FUNÇÃO formata_conteudo(markdown_content):

    // Extrair metadados do markdown
    titulo = EXTRAIR_LINHA("Title:", markdown_content)
    url = EXTRAIR_LINHA("URL Source:", markdown_content)
    dataPublicacao = EXTRAIR_LINHA("Published Time:", markdown_content)

    // Buscar menção ao cantor monitorado
    cantor = "Gusttavo Lima"  // HARDCODED
    menciona_cantor = BUSCAR(conteudo.toLowerCase(), cantor.toLowerCase())

    SE menciona_cantor:
        // Extrair trecho de contexto (200 chars antes, 300 depois)
        indice = POSICAO(cantor, conteudo)
        trecho_relevante = SUBSTRING(conteudo, indice - 200, indice + 300)
    FIM_SE

    // Limpar formatação markdown
    conteudo_formatado = conteudo
        .REMOVER_LINHAS_MENU()          // Remove [* links]
        .REMOVER_IMAGENS()               // Remove ![Image]
        .REMOVER_MARKDOWN_BOLD()         // Remove **texto**
        .REMOVER_MARKDOWN_ITALICO()      // Remove *texto*
        .PADRONIZAR_BULLETS()            // * → •

    RETORNAR {
        titulo,
        url,
        dataPublicacao,
        mencionaCantor,
        trechoRelevante,
        conteudoCompleto,
        categoria: menciona_cantor ? "RELEVANTE" : "DESCARTADA"
    }
FIM_FUNÇÃO

// ===============================================
// FUNÇÃO: formata_conteudo1 (para JSON - ANÁLISE DE SENTIMENTO)
// ===============================================
FUNÇÃO formata_conteudo1(jina_response):

    SE jina_response.code != 200:
        RETORNAR { erro: "Resposta inválida", categoria: "ERRO" }
    FIM_SE

    // Extrair dados principais
    titulo = jina_response.data.title
    descricao = jina_response.data.description
    url = jina_response.data.url
    dataPublicacao = jina_response.data.publishedTime
    conteudo = jina_response.data.content

    // Verificar menção
    cantor = "Gusttavo Lima"
    menciona_cantor = BUSCAR(conteudo.toLowerCase(), cantor.toLowerCase())

    SE menciona_cantor:
        // Extrair trecho relevante
        trecho_relevante = EXTRAIR_CONTEXTO(conteudo, cantor, 200, 300)

        // ======== ANÁLISE DE SENTIMENTO E CRISE ========

        // Dicionário de palavras NEGATIVAS com peso
        palavras_negativas = {
            "corrupção": { peso: 10, tipo: "ESCÂNDALO_CRIMINAL" },
            "propina": { peso: 10, tipo: "ESCÂNDALO_CRIMINAL" },
            "lavagem": { peso: 10, tipo: "ESCÂNDALO_CRIMINAL" },
            "fraude": { peso: 9, tipo: "ESCÂNDALO_CRIMINAL" },
            "investigação": { peso: 7, tipo: "INVESTIGAÇÃO" },
            "denúncia": { peso: 8, tipo: "DENÚNCIA" },
            "condenação": { peso: 10, tipo: "JURÍDICO" },
            "prisão": { peso: 10, tipo: "JURÍDICO" },
            "assédio": { peso: 9, tipo: "ESCÂNDALO_MORAL" },
            "polêmica": { peso: 5, tipo: "CONTROVÉRSIA" },
            "cancelado": { peso: 8, tipo: "CANCELAMENTO" },
            // ... mais 25+ palavras
        }

        // Dicionário de palavras POSITIVAS com peso
        palavras_positivas = {
            "sucesso": { peso: 8, tipo: "SUCESSO" },
            "recorde": { peso: 9, tipo: "CONQUISTA" },
            "prêmio": { peso: 8, tipo: "RECONHECIMENTO" },
            "doação": { peso: 8, tipo: "AÇÃO_SOCIAL" },
            "lotado": { peso: 7, tipo: "POPULARIDADE" },
            // ... mais 15+ palavras
        }

        // Calcular pontuações
        pontuacao_negativa = 0
        pontuacao_positiva = 0
        indicadores_negativos = []
        indicadores_positivos = []

        PARA CADA palavra, info EM palavras_negativas:
            SE conteudo.inclui(palavra):
                pontuacao_negativa += info.peso
                indicadores_negativos.ADICIONAR({ palavra, tipo, peso })
            FIM_SE
        FIM_PARA

        PARA CADA palavra, info EM palavras_positivas:
            SE conteudo.inclui(palavra):
                pontuacao_positiva += info.peso
                indicadores_positivos.ADICIONAR({ palavra, tipo, peso })
            FIM_SE
        FIM_PARA

        // Classificar sentimento
        SE pontuacao_negativa > pontuacao_positiva:
            SE pontuacao_negativa >= 20:
                sentimento = "MUITO_NEGATIVO"
                nivel_crise = MIN(10, pontuacao_negativa / 3)
                acao_recomendada = "CRISE_URGENTE"
            SENÃO SE pontuacao_negativa >= 10:
                sentimento = "NEGATIVO"
                nivel_crise = MIN(7, pontuacao_negativa / 4)
                acao_recomendada = "PREPARAR_RESPOSTA"
            SENÃO:
                sentimento = "LEVEMENTE_NEGATIVO"
                acao_recomendada = "MONITORAR_EVOLUÇÃO"
            FIM_SE
        SENÃO SE pontuacao_positiva > pontuacao_negativa:
            SE pontuacao_positiva >= 20:
                sentimento = "MUITO_POSITIVO"
                acao_recomendada = "AMPLIFICAR_MENSAGEM"
            SENÃO:
                sentimento = "POSITIVO"
                acao_recomendada = "COMPARTILHAR"
            FIM_SE
        SENÃO:
            sentimento = "NEUTRO"
            acao_recomendada = "MONITORAR"
        FIM_SE

        // Determinar urgência
        SE nivel_crise >= 8:
            urgencia = "CRÍTICA"
        SENÃO SE nivel_crise >= 5:
            urgencia = "ALTA"
        SENÃO SE nivel_crise >= 3:
            urgencia = "MÉDIA"
        SENÃO:
            urgencia = "NORMAL"
        FIM_SE

        // Gerar sugestão de ação
        sugestao_acao = GERAR_SUGESTAO(sentimento)

        // Identificar stakeholders afetados
        stakeholders = []
        SE conteudo.inclui("fã"): stakeholders.ADICIONAR("Fãs")
        SE conteudo.inclui("patrocin"): stakeholders.ADICIONAR("Patrocinadores")
        SE conteudo.inclui("família"): stakeholders.ADICIONAR("Família")
        // ...

    FIM_SE

    RETORNAR {
        // Informações básicas
        titulo, descricao, url, dataPublicacao,
        fonte: metadata.og_site_name || EXTRAIR_DOMINIO(url),
        autor: metadata.author || "Não identificado",

        // Análise de sentimento e crise
        mencionaCantor: menciona_cantor,
        sentimento,
        tipoNoticia,
        nivelCrise,
        urgencia,

        // Indicadores detalhados
        indicadoresNegativos,
        indicadoresPositivos,
        pontuacaoNegativa,
        pontuacaoPositiva,

        // Gestão de crise
        acaoRecomendada,
        sugestaoAcao,
        stakeholdersAfetados,

        // Conteúdo processado
        trechoRelevante,
        conteudoCompleto,

        // Controle de envio
        deveNotificarEquipe: menciona_cantor && (nivel_crise >= 3 || sentimento.inclui("POSITIVO")),
        notificacaoUrgente: urgencia == "CRÍTICA" || urgencia == "ALTA",
        canalNotificacao: urgencia == "CRÍTICA" ? "TODOS_CANAIS_URGENTE" :
                          urgencia == "ALTA" ? "WHATSAPP_TELEGRAM" :
                          "EMAIL_RELATORIO"
    }
FIM_FUNÇÃO
```

## 4. Regras de Negócio

| ID | Regra | Implementação |
|----|-------|---------------|
| **RN01** | Busca restrita ao Brasil | `cr: "countryBR"` no Google Custom Search |
| **RN02** | Apenas conteúdo em português | `lr: "lang_pt"` |
| **RN03** | Buscar notícias do último ano | `dateRestrict: "y1"` |
| **RN04** | Máximo 10 resultados por busca | `num: "10"` |
| **RN05** | Ordenar por data (mais recentes primeiro) | `sort: "date"` |
| **RN06** | Entidade monitorada: "Gusttavo Lima" | Hardcoded nos nós Code |
| **RN07** | Trecho de contexto: 200 chars antes + 300 depois | `substring(index-200, index+300)` |
| **RN08** | Crise urgente: pontuação negativa >= 20 | Classificação automática de nível de crise |
| **RN09** | Notificar equipe se crise >= nível 3 ou notícia positiva | Flag `deveNotificarEquipe` |
| **RN10** | Canal de notificação baseado em urgência | CRÍTICA → todos canais, ALTA → WhatsApp/Telegram |

## 5. Fluxo de Decisão

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         MONITOR PRO - FLUXO                             │
└─────────────────────────────────────────────────────────────────────────┘

        ┌──────────────────────┐
        │ 🖱️ Manual Trigger    │
        │ (Test workflow)      │
        └──────────┬───────────┘
                   │
                   ▼
        ┌──────────────────────┐
        │ 🔍 Google Custom     │
        │ Search API           │
        │ q="vereador Roberto" │
        │ num=10, sort=date    │
        └──────────┬───────────┘
                   │
                   ▼ (10 resultados)
         ┌─────────┴─────────┐
         │    PARALELO       │
         ▼                   ▼
┌────────────────┐   ┌────────────────┐
│ 📄 Jina Reader │   │ 📊 Jina Reader │
│ HTML/Markdown  │   │ JSON Format    │
│ r.jina.ai/URL  │   │ r.jina.ai/URL  │
└───────┬────────┘   └───────┬────────┘
        │                    │
        ▼                    ▼
┌────────────────┐   ┌────────────────────┐
│ formata        │   │ formata conteudo1  │
│ conteudo       │   │ (Análise           │
│ (Extração      │   │ Sentimento +       │
│ básica)        │   │ Gestão Crise)      │
└───────┬────────┘   └───────┬────────────┘
        │                    │
        ▼                    ▼
   ┌─────────┐          ┌─────────────────────────┐
   │ SAÍDA   │          │ SAÍDA COM ANÁLISE       │
   │ BÁSICA  │          │ ─────────────────────── │
   │         │          │ • sentimento            │
   │ titulo  │          │ • nivelCrise (0-10)     │
   │ url     │          │ • urgencia              │
   │ menciona│          │ • acaoRecomendada       │
   │ trecho  │          │ • sugestaoAcao          │
   │ categoria│         │ • stakeholdersAfetados  │
   └─────────┘          │ • canalNotificacao      │
                        └─────────────────────────┘


        ┌─────────────────────────────────────────┐
        │     MATRIZ DE CLASSIFICAÇÃO             │
        ├─────────────────┬───────────────────────┤
        │ PONTUAÇÃO NEG.  │ CLASSIFICAÇÃO         │
        ├─────────────────┼───────────────────────┤
        │ >= 20           │ MUITO_NEGATIVO        │
        │                 │ Crise: 7-10           │
        │                 │ Ação: CRISE_URGENTE   │
        ├─────────────────┼───────────────────────┤
        │ 10-19           │ NEGATIVO              │
        │                 │ Crise: 3-7            │
        │                 │ Ação: PREPARAR_RESP.  │
        ├─────────────────┼───────────────────────┤
        │ 1-9             │ LEVEMENTE_NEGATIVO    │
        │                 │ Crise: 1-4            │
        │                 │ Ação: MONITORAR_EVOL. │
        ├─────────────────┼───────────────────────┤
        │ PONTUAÇÃO POS.  │ CLASSIFICAÇÃO         │
        ├─────────────────┼───────────────────────┤
        │ >= 20           │ MUITO_POSITIVO        │
        │                 │ Ação: AMPLIFICAR      │
        ├─────────────────┼───────────────────────┤
        │ 10-19           │ POSITIVO              │
        │                 │ Ação: COMPARTILHAR    │
        ├─────────────────┼───────────────────────┤
        │ 1-9             │ LEVEMENTE_POSITIVO    │
        │                 │ Ação: ACOMPANHAR      │
        ├─────────────────┼───────────────────────┤
        │ 0               │ NEUTRO                │
        │                 │ Ação: MONITORAR       │
        └─────────────────┴───────────────────────┘
```

## 6. Integrações

| Sistema | Endpoint | Método | Autenticação |
|---------|----------|--------|--------------|
| **Google Custom Search** | `googleapis.com/customsearch/v1` | GET | API Key |
| **Jina Reader** | `r.jina.ai/{url}` | GET | Nenhuma (público) |

## 7. Side Effects

| Ícone | Tipo | Descrição |
|-------|------|-----------|
| ⚡ | CALL | Google Custom Search API (~$0.005/query) |
| ⚡ | CALL | Jina Reader API x2 por URL (gratuito) |

> **Nota**: Este workflow **NÃO** persiste dados em banco de dados. É apenas um processador de análise.

## 8. Erros Possíveis

| Erro | Causa | Tratamento |
|------|-------|------------|
| `jina_response.code !== 200` | URL bloqueada ou timeout | Retorna `{ erro, categoria: "ERRO" }` |
| Quota excedida Google | Limite diário de 100 queries | Nenhum - falha silenciosa |
| URL não acessível | Site bloqueou bot | Jina retorna erro |

## 9. Exemplo Completo

### Input (Trigger Manual)
```json
// Nenhum input - busca pré-configurada
```

### Output (formata conteudo1)
```json
{
  "titulo": "Gusttavo Lima é investigado por lavagem de dinheiro",
  "descricao": "Cantor sertanejo é alvo de operação policial...",
  "url": "https://exemplo.com.br/noticia/123",
  "dataPublicacao": "2025-12-10T15:30:00Z",
  "fonte": "Portal Exemplo",
  "autor": "Redação",

  "mencionaCantor": true,
  "sentimento": "MUITO_NEGATIVO",
  "tipoNoticia": "ESCÂNDALO",
  "nivelCrise": 8,
  "urgencia": "CRÍTICA",

  "indicadoresNegativos": [
    { "palavra": "investigado", "tipo": "INVESTIGAÇÃO", "peso": 7 },
    { "palavra": "lavagem", "tipo": "ESCÂNDALO_CRIMINAL", "peso": 10 },
    { "palavra": "operação", "tipo": "INVESTIGAÇÃO", "peso": 7 },
    { "palavra": "policial", "tipo": "INVESTIGAÇÃO", "peso": 7 }
  ],
  "indicadoresPositivos": [],
  "pontuacaoNegativa": 31,
  "pontuacaoPositiva": 0,

  "acaoRecomendada": "CRISE_URGENTE",
  "sugestaoAcao": "ATENÇÃO MÁXIMA: Acionar equipe de crise imediatamente. Preparar nota de esclarecimento. Monitorar repercussão nas próximas horas. Considerar ação jurídica se houver difamação.",
  "stakeholdersAfetados": ["Fãs", "Patrocinadores"],

  "trechoRelevante": "...O cantor Gusttavo Lima é investigado pela Polícia Federal em operação que apura lavagem de dinheiro...",

  "deveNotificarEquipe": true,
  "notificacaoUrgente": true,
  "canalNotificacao": "TODOS_CANAIS_URGENTE"
}
```

## 10. Checklist de Implementação

- [ ] Configurar variáveis de ambiente para API Keys
- [ ] Definir termo de busca dinâmico (não hardcoded)
- [ ] Implementar persistência em banco de dados
- [ ] Adicionar Schedule Trigger para execução automática
- [ ] Implementar envio de notificações (WhatsApp, Telegram, Email)
- [ ] Criar dashboard de monitoramento
- [ ] Implementar deduplicação de notícias
- [ ] Adicionar histórico de crises

## 11. Gaps Identificados

| Severidade | Gap | Impacto | Sugestão |
|------------|-----|---------|----------|
| 🔴 **CRÍTICO** | Termo de busca hardcoded | Não escalável | Parametrizar via config/BD |
| 🔴 **CRÍTICO** | API Key exposta no workflow | Segurança | Usar variáveis de ambiente |
| 🔴 **CRÍTICO** | Entidade monitorada hardcoded ("Gusttavo Lima") | Não escalável | Tornar configurável |
| 🟡 **ALTO** | Sem persistência de dados | Perda de histórico | Adicionar Supabase/PostgreSQL |
| 🟡 **ALTO** | Sem Schedule Trigger | Apenas manual | Adicionar cron (ex: a cada 1h) |
| 🟡 **ALTO** | Sem notificações | Equipe não é alertada | Integrar WhatsApp/Telegram |
| 🟡 **MÉDIO** | formata conteudo2 desconectado | Código legado | Remover ou conectar |
| 🟡 **MÉDIO** | Fluxos paralelos não consolidados | Dados duplicados | Merge ou escolher um |
| ℹ️ **BAIXO** | Workflow inativo | É um POC | Ativar quando pronto |
| ℹ️ **BAIXO** | Sem rate limiting | Pode exceder quota | Adicionar delays |

---

## Dicionário de Palavras (Sentimento)

### Palavras Negativas (40+)
```javascript
// Escândalos criminais (peso 9-10)
corrupção, propina, lavagem, sonegação, fraude, condenação, prisão

// Investigação (peso 6-8)
investigação, operação, polícia, denúncia, acusação, processo

// Escândalos morais (peso 5-9)
assédio, agressão, violência, traição, divórcio, briga, polêmica

// Políticos (peso 6-9)
rachadinha, nepotismo, superfaturamento, desvio, má gestão

// Cancelamento (peso 7-8)
cancelado, boicote, perde patrocínio, rompe contrato

// Acidentes (peso 5-8)
acidente, morte, ferido, hospital
```

### Palavras Positivas (20+)
```javascript
// Sucesso profissional (peso 8-9)
sucesso, recorde, número 1, premiado, prêmio, homenagem

// Ações sociais (peso 6-8)
doação, doou, caridade, solidário, beneficente

// Popularidade (peso 7-8)
lotado, ingressos esgotados, ovação, aclamado

// Vida pessoal (peso 5-6)
casamento, nascimento, celebração
```
