# Implementação: Monitor Pro

## Estrutura do Projeto

```
monitor-pro/
├── src/
│   ├── types/
│   │   └── index.ts              # Interfaces TypeScript
│   ├── config/
│   │   └── constants.ts          # Configurações e dicionários
│   ├── services/
│   │   ├── google-search.ts      # Google Custom Search API
│   │   └── jina-reader.ts        # Jina Reader API
│   ├── analyzers/
│   │   └── sentiment.ts          # Análise de sentimento
│   ├── processors/
│   │   └── news.processor.ts     # Processador de notícias
│   └── index.ts                  # Entry point
├── tests/
│   └── sentiment.test.ts         # Testes de sentimento
├── package.json
├── tsconfig.json
└── .env.example
```

---

## Tipos TypeScript

### `src/types/index.ts`

```typescript
// ==========================================
// TIPOS DE ENTRADA
// ==========================================

export interface GoogleSearchResult {
  kind: 'customsearch#result';
  title: string;
  htmlTitle: string;
  link: string;
  displayLink: string;
  snippet: string;
  htmlSnippet: string;
  formattedUrl: string;
  pagemap?: {
    metatags?: Array<Record<string, string>>;
    cse_thumbnail?: Array<{ src: string; width: string; height: string }>;
    cse_image?: Array<{ src: string }>;
  };
}

export interface GoogleSearchResponse {
  kind: 'customsearch#search';
  queries: {
    request: Array<{
      totalResults: string;
      searchTerms: string;
      count: number;
    }>;
    nextPage?: Array<{
      startIndex: number;
    }>;
  };
  searchInformation: {
    searchTime: number;
    totalResults: string;
  };
  items: GoogleSearchResult[];
}

export interface JinaResponse {
  code: number;
  data: {
    title: string;
    description: string;
    url: string;
    publishedTime: string;
    content: string;
    metadata?: {
      og_site_name?: string;
      author?: string;
      keywords?: string;
    };
  };
}

// ==========================================
// TIPOS DE ANÁLISE
// ==========================================

export type Sentimento =
  | 'MUITO_NEGATIVO'
  | 'NEGATIVO'
  | 'LEVEMENTE_NEGATIVO'
  | 'NEUTRO'
  | 'LEVEMENTE_POSITIVO'
  | 'POSITIVO'
  | 'MUITO_POSITIVO';

export type TipoNoticia =
  | 'ESCÂNDALO'
  | 'PROBLEMA'
  | 'CONTROVÉRSIA'
  | 'INFORMATIVA'
  | 'MENÇÃO_POSITIVA'
  | 'BOA_NOTÍCIA'
  | 'GRANDE_CONQUISTA';

export type Urgencia = 'NORMAL' | 'MÉDIA' | 'ALTA' | 'CRÍTICA';

export type AcaoRecomendada =
  | 'CRISE_URGENTE'
  | 'PREPARAR_RESPOSTA'
  | 'MONITORAR_EVOLUÇÃO'
  | 'MONITORAR'
  | 'ACOMPANHAR'
  | 'COMPARTILHAR'
  | 'AMPLIFICAR_MENSAGEM';

export type CanalNotificacao =
  | 'EMAIL_RELATORIO'
  | 'WHATSAPP_TELEGRAM'
  | 'TODOS_CANAIS_URGENTE';

export interface Indicador {
  palavra: string;
  tipo: string;
  peso: number;
}

// ==========================================
// TIPOS DE SAÍDA
// ==========================================

export interface AnaliseNoticia {
  // Informações básicas
  titulo: string;
  descricao: string;
  url: string;
  dataPublicacao: string;
  fonte: string;
  autor: string;

  // Análise de sentimento
  mencionaEntidade: boolean;
  sentimento: Sentimento;
  tipoNoticia: TipoNoticia;
  nivelCrise: number;
  urgencia: Urgencia;

  // Indicadores
  indicadoresNegativos: Indicador[];
  indicadoresPositivos: Indicador[];
  pontuacaoNegativa: number;
  pontuacaoPositiva: number;

  // Gestão de crise
  acaoRecomendada: AcaoRecomendada;
  sugestaoAcao: string;
  stakeholdersAfetados: string[];

  // Conteúdo
  trechoRelevante: string;
  conteudoCompleto: string;

  // Controle de envio
  deveNotificarEquipe: boolean;
  notificacaoUrgente: boolean;
  canalNotificacao: CanalNotificacao;
}

export interface ConfigMonitoramento {
  entidadeMonitorada: string;
  termoBusca: string;
  pais: string;
  idioma: string;
  periodoRestricao: string;
  maxResultados: number;
}
```

---

## Configurações e Dicionários

### `src/config/constants.ts`

```typescript
import { ConfigMonitoramento } from '../types';

// ==========================================
// CONFIGURAÇÃO (mover para .env em produção)
// ==========================================

export const CONFIG: ConfigMonitoramento = {
  entidadeMonitorada: process.env.ENTIDADE_MONITORADA || 'Gusttavo Lima',
  termoBusca: process.env.TERMO_BUSCA || 'vereador Roberto Ricardo',
  pais: 'countryBR',
  idioma: 'lang_pt',
  periodoRestricao: 'y1', // Último ano
  maxResultados: 10,
};

export const API_CONFIG = {
  google: {
    baseUrl: 'https://www.googleapis.com/customsearch/v1',
    apiKey: process.env.GOOGLE_API_KEY || '',
    cx: process.env.GOOGLE_CX || '',
  },
  jina: {
    baseUrl: 'https://r.jina.ai',
  },
};

// ==========================================
// DICIONÁRIO DE PALAVRAS NEGATIVAS
// ==========================================

export interface PalavraConfig {
  peso: number;
  tipo: string;
}

export const PALAVRAS_NEGATIVAS: Record<string, PalavraConfig> = {
  // Escândalos criminais (peso 9-10)
  'corrupção': { peso: 10, tipo: 'ESCÂNDALO_CRIMINAL' },
  'propina': { peso: 10, tipo: 'ESCÂNDALO_CRIMINAL' },
  'lavagem': { peso: 10, tipo: 'ESCÂNDALO_CRIMINAL' },
  'sonegação': { peso: 9, tipo: 'ESCÂNDALO_CRIMINAL' },
  'fraude': { peso: 9, tipo: 'ESCÂNDALO_CRIMINAL' },
  'condenação': { peso: 10, tipo: 'JURÍDICO' },
  'prisão': { peso: 10, tipo: 'JURÍDICO' },

  // Investigação (peso 6-8)
  'investigação': { peso: 7, tipo: 'INVESTIGAÇÃO' },
  'operação': { peso: 7, tipo: 'INVESTIGAÇÃO' },
  'polícia': { peso: 7, tipo: 'INVESTIGAÇÃO' },
  'denúncia': { peso: 8, tipo: 'DENÚNCIA' },
  'acusação': { peso: 8, tipo: 'DENÚNCIA' },
  'processo': { peso: 6, tipo: 'JURÍDICO' },

  // Escândalos morais (peso 5-9)
  'assédio': { peso: 9, tipo: 'ESCÂNDALO_MORAL' },
  'agressão': { peso: 9, tipo: 'ESCÂNDALO_MORAL' },
  'violência': { peso: 9, tipo: 'ESCÂNDALO_MORAL' },
  'traição': { peso: 5, tipo: 'ESCÂNDALO_PESSOAL' },
  'divórcio': { peso: 4, tipo: 'ESCÂNDALO_PESSOAL' },
  'briga': { peso: 6, tipo: 'CONFLITO' },
  'polêmica': { peso: 5, tipo: 'CONTROVÉRSIA' },
  'controverso': { peso: 5, tipo: 'CONTROVÉRSIA' },

  // Políticos (peso 6-9)
  'rachadinha': { peso: 9, tipo: 'ESCÂNDALO_POLÍTICO' },
  'nepotismo': { peso: 8, tipo: 'ESCÂNDALO_POLÍTICO' },
  'superfaturamento': { peso: 9, tipo: 'ESCÂNDALO_POLÍTICO' },
  'desvio': { peso: 9, tipo: 'ESCÂNDALO_POLÍTICO' },
  'gastos excessivos': { peso: 6, tipo: 'MÁ_GESTÃO' },
  'má gestão': { peso: 7, tipo: 'MÁ_GESTÃO' },

  // Críticas e ataques (peso 4-6)
  'crítica': { peso: 4, tipo: 'CRÍTICA' },
  'criticou': { peso: 4, tipo: 'CRÍTICA' },
  'atacou': { peso: 5, tipo: 'ATAQUE' },
  'acusou': { peso: 6, tipo: 'ACUSAÇÃO' },
  'desmentiu': { peso: 5, tipo: 'DEFESA' },
  'negou': { peso: 5, tipo: 'DEFESA' },

  // Cancelamento (peso 7-8)
  'cancelado': { peso: 8, tipo: 'CANCELAMENTO' },
  'boicote': { peso: 7, tipo: 'CANCELAMENTO' },
  'perde patrocínio': { peso: 7, tipo: 'PERDA_COMERCIAL' },
  'rompe contrato': { peso: 6, tipo: 'PERDA_COMERCIAL' },

  // Acidentes (peso 5-8)
  'acidente': { peso: 7, tipo: 'ACIDENTE' },
  'morte': { peso: 8, tipo: 'TRAGÉDIA' },
  'ferido': { peso: 6, tipo: 'ACIDENTE' },
  'hospital': { peso: 5, tipo: 'SAÚDE' },
};

// ==========================================
// DICIONÁRIO DE PALAVRAS POSITIVAS
// ==========================================

export const PALAVRAS_POSITIVAS: Record<string, PalavraConfig> = {
  // Sucesso profissional (peso 8-9)
  'sucesso': { peso: 8, tipo: 'SUCESSO' },
  'recorde': { peso: 9, tipo: 'CONQUISTA' },
  'número 1': { peso: 9, tipo: 'CONQUISTA' },
  'premiado': { peso: 8, tipo: 'RECONHECIMENTO' },
  'prêmio': { peso: 8, tipo: 'RECONHECIMENTO' },
  'homenagem': { peso: 7, tipo: 'RECONHECIMENTO' },
  'reconhecimento': { peso: 7, tipo: 'RECONHECIMENTO' },

  // Ações sociais (peso 6-8)
  'doação': { peso: 8, tipo: 'AÇÃO_SOCIAL' },
  'doou': { peso: 8, tipo: 'AÇÃO_SOCIAL' },
  'caridade': { peso: 8, tipo: 'AÇÃO_SOCIAL' },
  'solidário': { peso: 7, tipo: 'AÇÃO_SOCIAL' },
  'ajuda': { peso: 6, tipo: 'AÇÃO_SOCIAL' },
  'beneficente': { peso: 7, tipo: 'AÇÃO_SOCIAL' },

  // Parcerias (peso 6-7)
  'parceria': { peso: 6, tipo: 'NEGÓCIO' },
  'contrato': { peso: 6, tipo: 'NEGÓCIO' },
  'investimento': { peso: 7, tipo: 'NEGÓCIO' },
  'patrocínio': { peso: 6, tipo: 'NEGÓCIO' },

  // Popularidade (peso 7-8)
  'lotado': { peso: 7, tipo: 'POPULARIDADE' },
  'ingressos esgotados': { peso: 8, tipo: 'POPULARIDADE' },
  'ovação': { peso: 7, tipo: 'POPULARIDADE' },
  'aclamado': { peso: 7, tipo: 'POPULARIDADE' },

  // Vida pessoal (peso 5-6)
  'casamento': { peso: 5, tipo: 'VIDA_PESSOAL' },
  'nascimento': { peso: 6, tipo: 'VIDA_PESSOAL' },
  'celebração': { peso: 5, tipo: 'VIDA_PESSOAL' },
};

// ==========================================
// SUGESTÕES DE AÇÃO
// ==========================================

export const SUGESTOES_ACAO: Record<string, string> = {
  MUITO_NEGATIVO:
    'ATENÇÃO MÁXIMA: Acionar equipe de crise imediatamente. Preparar nota de esclarecimento. Monitorar repercussão nas próximas horas. Considerar ação jurídica se houver difamação.',
  NEGATIVO:
    'Preparar resposta oficial se necessário. Avaliar necessidade de esclarecimento público. Monitorar evolução da narrativa.',
  LEVEMENTE_NEGATIVO:
    'Continuar monitoramento. Preparar argumentos de defesa caso evolua negativamente.',
  NEUTRO: 'Continuar monitoramento regular.',
  LEVEMENTE_POSITIVO: 'Acompanhar. Considerar engajamento se apropriado.',
  POSITIVO:
    'Compartilhar em canais oficiais. Engajar com a publicação se apropriado.',
  MUITO_POSITIVO:
    'Oportunidade de marketing: Amplificar mensagem nas redes sociais. Considerar release para imprensa. Agradecer publicamente se apropriado.',
};
```

---

## Serviços

### `src/services/google-search.ts`

```typescript
import { GoogleSearchResponse, GoogleSearchResult } from '../types';
import { API_CONFIG, CONFIG } from '../config/constants';

export class GoogleSearchService {
  private apiKey: string;
  private cx: string;
  private baseUrl: string;

  constructor() {
    this.apiKey = API_CONFIG.google.apiKey;
    this.cx = API_CONFIG.google.cx;
    this.baseUrl = API_CONFIG.google.baseUrl;

    if (!this.apiKey || !this.cx) {
      throw new Error(
        'GOOGLE_API_KEY e GOOGLE_CX são obrigatórios. Configure em .env'
      );
    }
  }

  async buscarNoticias(
    termoBusca?: string
  ): Promise<GoogleSearchResult[]> {
    const params = new URLSearchParams({
      key: this.apiKey,
      cx: this.cx,
      q: termoBusca || CONFIG.termoBusca,
      cr: CONFIG.pais,
      lr: CONFIG.idioma,
      dateRestrict: CONFIG.periodoRestricao,
      num: CONFIG.maxResultados.toString(),
      sort: 'date',
    });

    const url = `${this.baseUrl}?${params.toString()}`;

    try {
      const response = await fetch(url);

      if (!response.ok) {
        throw new Error(
          `Google Search API error: ${response.status} ${response.statusText}`
        );
      }

      const data: GoogleSearchResponse = await response.json();

      console.log(
        `[GoogleSearch] Encontrados ${data.searchInformation.totalResults} resultados`
      );

      return data.items || [];
    } catch (error) {
      console.error('[GoogleSearch] Erro na busca:', error);
      throw error;
    }
  }
}
```

### `src/services/jina-reader.ts`

```typescript
import { JinaResponse } from '../types';
import { API_CONFIG } from '../config/constants';

export class JinaReaderService {
  private baseUrl: string;

  constructor() {
    this.baseUrl = API_CONFIG.jina.baseUrl;
  }

  async extrairConteudo(url: string): Promise<JinaResponse> {
    const jinaUrl = `${this.baseUrl}/${url}`;

    try {
      const response = await fetch(jinaUrl, {
        headers: {
          Accept: 'application/json',
          'X-Return-Format': 'json',
        },
      });

      if (!response.ok) {
        throw new Error(
          `Jina Reader error: ${response.status} ${response.statusText}`
        );
      }

      const data: JinaResponse = await response.json();

      if (data.code !== 200) {
        throw new Error(`Jina Reader retornou código ${data.code}`);
      }

      console.log(`[JinaReader] Extraído conteúdo de: ${url}`);

      return data;
    } catch (error) {
      console.error(`[JinaReader] Erro ao extrair ${url}:`, error);
      throw error;
    }
  }

  async extrairConteudoMarkdown(url: string): Promise<string> {
    const jinaUrl = `${this.baseUrl}/${url}`;

    try {
      const response = await fetch(jinaUrl);

      if (!response.ok) {
        throw new Error(
          `Jina Reader error: ${response.status} ${response.statusText}`
        );
      }

      return await response.text();
    } catch (error) {
      console.error(`[JinaReader] Erro ao extrair markdown ${url}:`, error);
      throw error;
    }
  }
}
```

---

## Analisador de Sentimento

### `src/analyzers/sentiment.ts`

```typescript
import {
  Sentimento,
  TipoNoticia,
  Urgencia,
  AcaoRecomendada,
  CanalNotificacao,
  Indicador,
} from '../types';
import {
  CONFIG,
  PALAVRAS_NEGATIVAS,
  PALAVRAS_POSITIVAS,
  SUGESTOES_ACAO,
} from '../config/constants';

export interface ResultadoAnalise {
  mencionaEntidade: boolean;
  sentimento: Sentimento;
  tipoNoticia: TipoNoticia;
  nivelCrise: number;
  urgencia: Urgencia;
  indicadoresNegativos: Indicador[];
  indicadoresPositivos: Indicador[];
  pontuacaoNegativa: number;
  pontuacaoPositiva: number;
  acaoRecomendada: AcaoRecomendada;
  sugestaoAcao: string;
  stakeholdersAfetados: string[];
  trechoRelevante: string;
  deveNotificarEquipe: boolean;
  notificacaoUrgente: boolean;
  canalNotificacao: CanalNotificacao;
}

export class SentimentAnalyzer {
  private entidadeMonitorada: string;

  constructor(entidade?: string) {
    this.entidadeMonitorada = entidade || CONFIG.entidadeMonitorada;
  }

  analisar(conteudo: string): ResultadoAnalise {
    const conteudoLower = conteudo.toLowerCase();
    const entidadeLower = this.entidadeMonitorada.toLowerCase();

    // Verificar menção
    const mencionaEntidade = conteudoLower.includes(entidadeLower);

    if (!mencionaEntidade) {
      return this.criarResultadoSemMencao();
    }

    // Extrair trecho relevante
    const trechoRelevante = this.extrairTrecho(conteudo, entidadeLower);

    // Calcular pontuações
    const { indicadoresNegativos, pontuacaoNegativa } = this.calcularNegativos(
      conteudoLower
    );
    const { indicadoresPositivos, pontuacaoPositiva } = this.calcularPositivos(
      conteudoLower
    );

    // Classificar sentimento
    const { sentimento, tipoNoticia, nivelCrise, acaoRecomendada } =
      this.classificarSentimento(pontuacaoNegativa, pontuacaoPositiva);

    // Determinar urgência
    const urgencia = this.determinarUrgencia(nivelCrise);

    // Identificar stakeholders
    const stakeholdersAfetados = this.identificarStakeholders(conteudoLower);

    // Determinar canal de notificação
    const canalNotificacao = this.determinarCanal(urgencia);

    return {
      mencionaEntidade: true,
      sentimento,
      tipoNoticia,
      nivelCrise,
      urgencia,
      indicadoresNegativos,
      indicadoresPositivos,
      pontuacaoNegativa,
      pontuacaoPositiva,
      acaoRecomendada,
      sugestaoAcao: SUGESTOES_ACAO[sentimento],
      stakeholdersAfetados,
      trechoRelevante,
      deveNotificarEquipe:
        nivelCrise >= 3 || sentimento.includes('POSITIVO'),
      notificacaoUrgente: urgencia === 'CRÍTICA' || urgencia === 'ALTA',
      canalNotificacao,
    };
  }

  private criarResultadoSemMencao(): ResultadoAnalise {
    return {
      mencionaEntidade: false,
      sentimento: 'NEUTRO',
      tipoNoticia: 'INFORMATIVA',
      nivelCrise: 0,
      urgencia: 'NORMAL',
      indicadoresNegativos: [],
      indicadoresPositivos: [],
      pontuacaoNegativa: 0,
      pontuacaoPositiva: 0,
      acaoRecomendada: 'MONITORAR',
      sugestaoAcao: 'Notícia não menciona a entidade monitorada.',
      stakeholdersAfetados: [],
      trechoRelevante: '',
      deveNotificarEquipe: false,
      notificacaoUrgente: false,
      canalNotificacao: 'EMAIL_RELATORIO',
    };
  }

  private extrairTrecho(conteudo: string, entidade: string): string {
    const index = conteudo.toLowerCase().indexOf(entidade);
    if (index === -1) return '';

    const start = Math.max(0, index - 200);
    const end = Math.min(conteudo.length, index + 300);
    return conteudo.substring(start, end).trim();
  }

  private calcularNegativos(conteudo: string): {
    indicadoresNegativos: Indicador[];
    pontuacaoNegativa: number;
  } {
    const indicadores: Indicador[] = [];
    let pontuacao = 0;

    for (const [palavra, config] of Object.entries(PALAVRAS_NEGATIVAS)) {
      if (conteudo.includes(palavra)) {
        pontuacao += config.peso;
        indicadores.push({
          palavra,
          tipo: config.tipo,
          peso: config.peso,
        });
      }
    }

    return { indicadoresNegativos: indicadores, pontuacaoNegativa: pontuacao };
  }

  private calcularPositivos(conteudo: string): {
    indicadoresPositivos: Indicador[];
    pontuacaoPositiva: number;
  } {
    const indicadores: Indicador[] = [];
    let pontuacao = 0;

    for (const [palavra, config] of Object.entries(PALAVRAS_POSITIVAS)) {
      if (conteudo.includes(palavra)) {
        pontuacao += config.peso;
        indicadores.push({
          palavra,
          tipo: config.tipo,
          peso: config.peso,
        });
      }
    }

    return { indicadoresPositivos: indicadores, pontuacaoPositiva: pontuacao };
  }

  private classificarSentimento(
    negativa: number,
    positiva: number
  ): {
    sentimento: Sentimento;
    tipoNoticia: TipoNoticia;
    nivelCrise: number;
    acaoRecomendada: AcaoRecomendada;
  } {
    if (negativa > positiva) {
      if (negativa >= 20) {
        return {
          sentimento: 'MUITO_NEGATIVO',
          tipoNoticia: 'ESCÂNDALO',
          nivelCrise: Math.min(10, Math.floor(negativa / 3)),
          acaoRecomendada: 'CRISE_URGENTE',
        };
      } else if (negativa >= 10) {
        return {
          sentimento: 'NEGATIVO',
          tipoNoticia: 'PROBLEMA',
          nivelCrise: Math.min(7, Math.floor(negativa / 4)),
          acaoRecomendada: 'PREPARAR_RESPOSTA',
        };
      } else {
        return {
          sentimento: 'LEVEMENTE_NEGATIVO',
          tipoNoticia: 'CONTROVÉRSIA',
          nivelCrise: Math.min(4, Math.floor(negativa / 5)),
          acaoRecomendada: 'MONITORAR_EVOLUÇÃO',
        };
      }
    } else if (positiva > negativa) {
      if (positiva >= 20) {
        return {
          sentimento: 'MUITO_POSITIVO',
          tipoNoticia: 'GRANDE_CONQUISTA',
          nivelCrise: 0,
          acaoRecomendada: 'AMPLIFICAR_MENSAGEM',
        };
      } else if (positiva >= 10) {
        return {
          sentimento: 'POSITIVO',
          tipoNoticia: 'BOA_NOTÍCIA',
          nivelCrise: 0,
          acaoRecomendada: 'COMPARTILHAR',
        };
      } else {
        return {
          sentimento: 'LEVEMENTE_POSITIVO',
          tipoNoticia: 'MENÇÃO_POSITIVA',
          nivelCrise: 0,
          acaoRecomendada: 'ACOMPANHAR',
        };
      }
    }

    return {
      sentimento: 'NEUTRO',
      tipoNoticia: 'INFORMATIVA',
      nivelCrise: 0,
      acaoRecomendada: 'MONITORAR',
    };
  }

  private determinarUrgencia(nivelCrise: number): Urgencia {
    if (nivelCrise >= 8) return 'CRÍTICA';
    if (nivelCrise >= 5) return 'ALTA';
    if (nivelCrise >= 3) return 'MÉDIA';
    return 'NORMAL';
  }

  private identificarStakeholders(conteudo: string): string[] {
    const stakeholders: string[] = [];

    if (conteudo.includes('fã') || conteudo.includes('público')) {
      stakeholders.push('Fãs');
    }
    if (conteudo.includes('patrocin') || conteudo.includes('marca')) {
      stakeholders.push('Patrocinadores');
    }
    if (conteudo.includes('contrato') || conteudo.includes('empresário')) {
      stakeholders.push('Parceiros Comerciais');
    }
    if (
      conteudo.includes('família') ||
      conteudo.includes('esposa') ||
      conteudo.includes('filho')
    ) {
      stakeholders.push('Família');
    }
    if (conteudo.includes('prefeitura') || conteudo.includes('governo')) {
      stakeholders.push('Órgãos Públicos');
    }

    return stakeholders;
  }

  private determinarCanal(urgencia: Urgencia): CanalNotificacao {
    switch (urgencia) {
      case 'CRÍTICA':
        return 'TODOS_CANAIS_URGENTE';
      case 'ALTA':
        return 'WHATSAPP_TELEGRAM';
      default:
        return 'EMAIL_RELATORIO';
    }
  }
}
```

---

## Processador Principal

### `src/processors/news.processor.ts`

```typescript
import { GoogleSearchService } from '../services/google-search';
import { JinaReaderService } from '../services/jina-reader';
import { SentimentAnalyzer } from '../analyzers/sentiment';
import { AnaliseNoticia, GoogleSearchResult, JinaResponse } from '../types';

export class NewsProcessor {
  private googleSearch: GoogleSearchService;
  private jinaReader: JinaReaderService;
  private sentimentAnalyzer: SentimentAnalyzer;

  constructor(entidadeMonitorada?: string) {
    this.googleSearch = new GoogleSearchService();
    this.jinaReader = new JinaReaderService();
    this.sentimentAnalyzer = new SentimentAnalyzer(entidadeMonitorada);
  }

  async processar(termoBusca?: string): Promise<AnaliseNoticia[]> {
    console.log('[NewsProcessor] Iniciando processamento...');

    // 1. Buscar notícias no Google
    const resultados = await this.googleSearch.buscarNoticias(termoBusca);
    console.log(`[NewsProcessor] ${resultados.length} notícias encontradas`);

    // 2. Processar cada notícia
    const analises: AnaliseNoticia[] = [];

    for (const resultado of resultados) {
      try {
        const analise = await this.processarNoticia(resultado);
        analises.push(analise);
      } catch (error) {
        console.error(
          `[NewsProcessor] Erro ao processar ${resultado.link}:`,
          error
        );
      }
    }

    // 3. Ordenar por nível de crise (mais urgentes primeiro)
    analises.sort((a, b) => b.nivelCrise - a.nivelCrise);

    console.log(`[NewsProcessor] ${analises.length} notícias processadas`);

    return analises;
  }

  private async processarNoticia(
    resultado: GoogleSearchResult
  ): Promise<AnaliseNoticia> {
    // Extrair conteúdo via Jina Reader
    const jinaResponse = await this.jinaReader.extrairConteudo(resultado.link);

    // Analisar sentimento
    const analise = this.sentimentAnalyzer.analisar(
      jinaResponse.data.content || ''
    );

    // Montar resultado completo
    return {
      titulo: jinaResponse.data.title || resultado.title,
      descricao: jinaResponse.data.description || resultado.snippet,
      url: jinaResponse.data.url || resultado.link,
      dataPublicacao: jinaResponse.data.publishedTime || '',
      fonte:
        jinaResponse.data.metadata?.og_site_name || resultado.displayLink,
      autor: jinaResponse.data.metadata?.author || 'Não identificado',
      conteudoCompleto: this.limparConteudo(jinaResponse.data.content || ''),
      ...analise,
    };
  }

  private limparConteudo(conteudo: string): string {
    return conteudo
      .split('\n')
      .filter((line) => {
        const lineClean = line.trim();
        return (
          lineClean.length > 0 &&
          !lineClean.startsWith('*   [') &&
          !lineClean.startsWith('[![') &&
          !lineClean.startsWith('[Image') &&
          !lineClean.includes('](https://') &&
          !lineClean.startsWith('[](') &&
          !lineClean.match(/^\[.*\]\(.*\)$/) &&
          !lineClean.match(/^={3,}$/) &&
          !lineClean.match(/^-{3,}$/)
        );
      })
      .map((line) =>
        line
          .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1')
          .replace(/\*\*([^*]+)\*\*/g, '$1')
          .replace(/\*([^*]+)\*/g, '$1')
          .replace(/^#+\s/, '')
          .replace(/!\[.*?\]\(.*?\)/g, '')
          .replace(/^[\*\-]\s+/, '• ')
          .trim()
      )
      .filter((line) => line.length > 0)
      .join('\n\n');
  }
}
```

---

## Entry Point

### `src/index.ts`

```typescript
import { NewsProcessor } from './processors/news.processor';
import { AnaliseNoticia } from './types';

async function main() {
  console.log('='.repeat(60));
  console.log('MONITOR PRO - Sistema de Monitoramento de Mídia');
  console.log('='.repeat(60));

  const processor = new NewsProcessor();

  try {
    const resultados = await processor.processar();

    // Filtrar apenas notícias relevantes
    const relevantes = resultados.filter((r) => r.mencionaEntidade);

    console.log('\n' + '='.repeat(60));
    console.log(`RESUMO: ${relevantes.length} notícias relevantes`);
    console.log('='.repeat(60));

    for (const noticia of relevantes) {
      console.log(`\n📰 ${noticia.titulo}`);
      console.log(`   🔗 ${noticia.url}`);
      console.log(
        `   📊 Sentimento: ${noticia.sentimento} | Crise: ${noticia.nivelCrise}/10`
      );
      console.log(`   ⚠️ Urgência: ${noticia.urgencia}`);
      console.log(`   🎯 Ação: ${noticia.acaoRecomendada}`);

      if (noticia.indicadoresNegativos.length > 0) {
        console.log(
          `   🔴 Negativos: ${noticia.indicadoresNegativos.map((i) => i.palavra).join(', ')}`
        );
      }
      if (noticia.indicadoresPositivos.length > 0) {
        console.log(
          `   🟢 Positivos: ${noticia.indicadoresPositivos.map((i) => i.palavra).join(', ')}`
        );
      }
    }

    // Alertas de crise
    const crises = relevantes.filter((r) => r.nivelCrise >= 5);
    if (crises.length > 0) {
      console.log('\n' + '🚨'.repeat(30));
      console.log('ALERTAS DE CRISE:');
      crises.forEach((c) => {
        console.log(`  ⚠️ ${c.titulo} (Nível ${c.nivelCrise})`);
        console.log(`     ${c.sugestaoAcao}`);
      });
      console.log('🚨'.repeat(30));
    }
  } catch (error) {
    console.error('Erro no processamento:', error);
    process.exit(1);
  }
}

main();
```

---

## Configuração do Projeto

### `package.json`

```json
{
  "name": "monitor-pro",
  "version": "1.0.0",
  "description": "Sistema de monitoramento de mídia e gestão de crise",
  "main": "dist/index.js",
  "scripts": {
    "build": "tsc",
    "start": "node dist/index.js",
    "dev": "ts-node src/index.ts",
    "test": "jest"
  },
  "dependencies": {},
  "devDependencies": {
    "@types/node": "^20.10.0",
    "typescript": "^5.3.0",
    "ts-node": "^10.9.0",
    "jest": "^29.7.0",
    "@types/jest": "^29.5.0"
  }
}
```

### `tsconfig.json`

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

### `.env.example`

```env
# Google Custom Search API
GOOGLE_API_KEY=your_api_key_here
GOOGLE_CX=your_search_engine_id_here

# Monitoramento
ENTIDADE_MONITORADA=Gusttavo Lima
TERMO_BUSCA=vereador Roberto Ricardo
```

---

## Testes

### `tests/sentiment.test.ts`

```typescript
import { SentimentAnalyzer } from '../src/analyzers/sentiment';

describe('SentimentAnalyzer', () => {
  let analyzer: SentimentAnalyzer;

  beforeEach(() => {
    analyzer = new SentimentAnalyzer('Gusttavo Lima');
  });

  test('deve detectar sentimento muito negativo', () => {
    const conteudo =
      'Gusttavo Lima é investigado por lavagem de dinheiro e corrupção';
    const resultado = analyzer.analisar(conteudo);

    expect(resultado.mencionaEntidade).toBe(true);
    expect(resultado.sentimento).toBe('MUITO_NEGATIVO');
    expect(resultado.nivelCrise).toBeGreaterThanOrEqual(7);
    expect(resultado.acaoRecomendada).toBe('CRISE_URGENTE');
  });

  test('deve detectar sentimento positivo', () => {
    const conteudo =
      'Gusttavo Lima faz doação milionária e recebe prêmio de sucesso';
    const resultado = analyzer.analisar(conteudo);

    expect(resultado.mencionaEntidade).toBe(true);
    expect(resultado.sentimento).toContain('POSITIVO');
    expect(resultado.nivelCrise).toBe(0);
  });

  test('deve retornar neutro sem menção', () => {
    const conteudo = 'Notícia sobre outro assunto qualquer';
    const resultado = analyzer.analisar(conteudo);

    expect(resultado.mencionaEntidade).toBe(false);
    expect(resultado.sentimento).toBe('NEUTRO');
  });

  test('deve identificar stakeholders', () => {
    const conteudo =
      'Gusttavo Lima perde patrocínio de marca após polêmica com fãs';
    const resultado = analyzer.analisar(conteudo);

    expect(resultado.stakeholdersAfetados).toContain('Patrocinadores');
    expect(resultado.stakeholdersAfetados).toContain('Fãs');
  });

  test('deve calcular canal de notificação correto', () => {
    const conteudoCritico =
      'Gusttavo Lima preso por corrupção e lavagem de dinheiro em operação policial';
    const resultado = analyzer.analisar(conteudoCritico);

    expect(resultado.canalNotificacao).toBe('TODOS_CANAIS_URGENTE');
  });
});
```

---

## Execução

```bash
# Instalar dependências
npm install

# Configurar variáveis de ambiente
cp .env.example .env
# Editar .env com suas credenciais

# Executar em desenvolvimento
npm run dev

# Build para produção
npm run build
npm start

# Executar testes
npm test
```
