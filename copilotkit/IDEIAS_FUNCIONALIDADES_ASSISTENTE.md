# Ideias de Funcionalidades - Assistente de Gestão EstéticaPro

## Visão Geral

Assistente de IA integrado ao sistema EstéticaPro para auxiliar na gestão da clínica, humanizando a interpretação de dados e tornando a experiência mais intuitiva.

```
┌─────────────────────────────────────────────────────────────┐
│                    ESTETICAPRO + AI                         │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  📊 Dashboard / Análise Mensal                      │   │
│  │  (dados, gráficos, métricas)                        │   │
│  └─────────────────────────────────────────────────────┘   │
│                          │                                  │
│                          ▼                                  │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  🤖 ASSISTENTE DE GESTÃO                            │   │
│  │                                                      │   │
│  │  "Oi! Analisando seus dados de dezembro, vi que     │   │
│  │   as quartas-feiras estão com 40% menos movimento.  │   │
│  │   Que tal criar uma promoção específica?            │   │
│  │                                                      │   │
│  │   Também notei que a cliente Maria Silva não        │   │
│  │   retorna há 45 dias. Quer que eu sugira um         │   │
│  │   follow-up personalizado?"                          │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## Funcionalidades Detalhadas

### 1. Interpretação Humanizada de Dados

**Problema atual:**
```
Taxa de Retorno: 68%
Ticket Médio: R$ 187,50
Agendamentos: 142
```
*Usuário precisa interpretar sozinho os números*

**Solução com AI:**
> "Sua taxa de retorno está em 68% - isso é bom, mas percebi que caiu 5% comparado ao mês passado. Os clientes que não retornaram fizeram principalmente limpeza de pele. Talvez valha oferecer um pacote de manutenção para esse procedimento. Quer que eu liste esses clientes?"

**Implementação:**
```tsx
useCopilotReadable({
  description: "Métricas da clínica",
  value: {
    taxaRetorno: 68,
    ticketMedio: 187.50,
    agendamentos: 142,
    comparativoMesAnterior: { retorno: -5 }
  }
});
```

---

### 2. Insights Proativos

O AI analisa os dados e oferece insights sem o usuário precisar perguntar.

**Exemplo de contexto:**
```tsx
useCopilotReadable({
  description: "Métricas da clínica",
  value: {
    agendamentosHoje: 8,
    horariosPico: ["10:00", "15:00"],
    clientesSemRetorno: 23,
    procedimentoMaisVendido: "Harmonização Facial",
    tendencia: "crescimento 12%"
  }
});
```

**Pergunta do usuário:** *"Como está minha clínica?"*

**Resposta do AI:**
> "Sua clínica está indo bem! 📈
>
> **Hoje:** 8 agendamentos, com pico às 10h e 15h.
>
> **Destaque do mês:** Harmonização Facial lidera as vendas, com crescimento de 12%.
>
> **Atenção:** Você tem 23 clientes que não retornam há mais de 30 dias. Quer que eu prepare uma lista para follow-up?"

---

### 3. Ações Inteligentes

O AI não apenas informa, mas também executa ações no sistema.

**Implementação:**
```tsx
useCopilotAction({
  name: "prepararFollowUp",
  description: "Prepara lista de clientes para follow-up",
  parameters: [
    { name: "dias", type: "number", description: "Dias sem retorno" }
  ],
  handler: async ({ dias }) => {
    const clientes = await buscarClientesSemRetorno(dias);
    return clientes;
  },
  render: ({ result }) => (
    <ListaFollowUp clientes={result} />
  )
});
```

**Interação:**
- **Usuário:** *"Me mostra quem precisa de follow-up"*
- **AI:** Renderiza uma lista visual com nome, último procedimento, dias sem retorno, e botão para enviar WhatsApp.

---

### 4. Análise Comparativa Natural

**Pergunta:** *"Como foi dezembro comparado a novembro?"*

**Resposta do AI:**
> "Dezembro foi excelente! 🎉
>
> - **Faturamento:** R$ 45.200 (+18% vs novembro)
> - **Novos clientes:** 34 (+12)
> - **Procedimento destaque:** Pacotes de fim de ano venderam muito
>
> **Ponto de atenção:** Os cancelamentos aumentaram 8%. A maioria foi por conflito de horário. Talvez valha revisar a política de reagendamento."

---

### 5. Ajuda Contextual por Tela

O AI adapta suas sugestões baseado na tela que o usuário está visualizando.

**Na tela de Agendamentos:**
> "Vejo que você tem 3 horários vagos amanhã à tarde. Tenho 5 clientes que costumam agendar nesse horário. Quer que eu sugira enviar uma mensagem para eles?"

**Na tela de CRM:**
> "A cliente Ana tem aniversário semana que vem e gosta de tratamentos faciais. Que tal oferecer algo especial?"

**Na tela de Análise Mensal:**
> "Percebi que terças e quintas são seus dias mais lucrativos. Já pensou em concentrar os procedimentos premium nesses dias?"

---

### 6. Tela de Insights com Visualização Dinâmica

Uma aba dedicada onde o chat fica no canto e a área principal exibe visualizações dinâmicas baseadas nas perguntas do usuário.

**Layout da Tela:**
```
┌─────────────────────────────────────────────────────────────┐
│  📊 Central de Insights                                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌───────────────────────────────┐  ┌───────────────────┐  │
│  │                               │  │ 💬 Chat           │  │
│  │      ÁREA DE VISUALIZAÇÃO     │  │                   │  │
│  │                               │  │ Você: "Como foi   │  │
│  │   ┌─────────────────────┐    │  │ dezembro?"        │  │
│  │   │  📊 Gráfico aparece │    │  │                   │  │
│  │   │     AQUI            │    │  │ AI: "Dezembro foi │  │
│  │   │                     │    │  │ ótimo! Veja o     │  │
│  │   └─────────────────────┘    │  │ gráfico ao lado." │  │
│  │                               │  │                   │  │
│  │   ┌─────────────────────┐    │  │                   │  │
│  │   │  📋 Cards, tabelas  │    │  │                   │  │
│  │   │     também!         │    │  │                   │  │
│  │   └─────────────────────┘    │  │                   │  │
│  │                               │  │                   │  │
│  └───────────────────────────────┘  └───────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Conceito:**
- O chat responde com **texto explicativo**
- A área principal exibe **componentes visuais** (gráficos, tabelas, cards, listas)
- Usa **Shared State** para sincronizar chat e visualização

**Implementação:**
```tsx
// Estado compartilhado entre chat e área visual
const [visualContent, setVisualContent] = useState(null);

// Action que atualiza a área visual
useCopilotAction({
  name: "mostrarVisualizacao",
  description: "Mostra conteúdo visual na área principal",
  parameters: [
    { name: "tipo", type: "string" },  // grafico, tabela, card, lista, calendario
    { name: "dados", type: "string" },
    { name: "titulo", type: "string" }
  ],
  handler: async ({ tipo, dados, titulo }) => {
    setVisualContent({
      tipo,
      dados: JSON.parse(dados),
      titulo
    });
    return "Visualização exibida!";
  }
});

// Layout da página
return (
  <div className="flex h-screen">
    {/* Área de visualização - reage ao estado */}
    <div className="flex-1 p-8 bg-gray-50">
      {visualContent ? (
        <VisualizadorDinamico content={visualContent} />
      ) : (
        <EstadoVazio mensagem="Faça uma pergunta para ver insights aqui" />
      )}
    </div>

    {/* Chat lateral */}
    <div className="w-96 border-l">
      <CopilotSidebar />
    </div>
  </div>
);
```

**Componente Visualizador Dinâmico:**
```tsx
function VisualizadorDinamico({ content }) {
  switch (content.tipo) {
    case 'grafico_vendas':
      return <GraficoVendas dados={content.dados} titulo={content.titulo} />;

    case 'lista_clientes':
      return <ListaClientes clientes={content.dados} acoes={true} />;

    case 'comparativo':
      return <ComparativoPeriodos dados={content.dados} />;

    case 'calendario':
      return <CalendarioAgendamentos dados={content.dados} />;

    case 'cards_metricas':
      return <GridMetricas metricas={content.dados} />;

    case 'tabela':
      return <TabelaDinamica dados={content.dados} titulo={content.titulo} />;

    default:
      return <CardGenerico dados={content.dados} />;
  }
}
```

**Exemplos de Interação:**

| Pergunta | Chat Responde | Área Visual Mostra |
|----------|---------------|-------------------|
| "Quais clientes não retornam há 30 dias?" | "Encontrei 23 clientes inativos. Veja a lista ao lado." | Lista com nome, dias, último procedimento, botões de ação |
| "Como foi dezembro?" | "Dezembro foi ótimo! Faturamento subiu 18%..." | Gráfico de vendas + cards com métricas |
| "Compara este mês com o anterior" | "Veja a comparação ao lado. Destaque para..." | Gráfico comparativo lado a lado |
| "Quais horários estão vagos amanhã?" | "Você tem 5 horários disponíveis. Veja no calendário." | Calendário visual do dia |
| "Mostre os aniversariantes da semana" | "São 4 clientes. Preparei cards com sugestões." | Cards com foto, data, sugestão de presente |
| "Qual procedimento mais vendeu?" | "Harmonização lidera com 34% das vendas." | Ranking visual com barras de progresso |

**Estado Vazio (quando não há pergunta ainda):**
```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                         🔍                                  │
│                                                             │
│              Faça uma pergunta para começar                 │
│                                                             │
│         Exemplos do que você pode perguntar:                │
│                                                             │
│         • "Como foi o mês passado?"                         │
│         • "Quem precisa de follow-up?"                      │
│         • "Quais horários estão vagos?"                     │
│         • "Compare janeiro com dezembro"                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Benefícios desta abordagem:**
- **Mais espaço visual** - Gráficos e tabelas ocupam área maior
- **Experiência conversacional** - Usuário pergunta naturalmente
- **Separação clara** - Texto no chat, visual na área principal
- **Interativo** - Componentes visuais podem ter botões de ação
- **Histórico preservado** - Chat mantém histórico das perguntas

---

## Capacidades por Área do Sistema

| Área | Capacidades do AI |
|------|-------------------|
| **Análise Mensal** | Explicar dados, comparar períodos, identificar tendências, alertar anomalias |
| **Agendamentos** | Sugerir otimizações, identificar horários vagos, facilitar reagendamentos |
| **CRM** | Follow-up inteligente, lembrar aniversários, reativar clientes inativos |
| **Vendas** | Análise de ticket médio, produtos mais vendidos, identificar oportunidades |
| **Financeiro** | Resumos em linguagem natural, alertas de despesas, previsões |
| **WhatsApp/Disparos** | Sugerir mensagens personalizadas, melhor horário para envio |
| **Antes/Depois** | Sugerir quais casos mostrar, organizar por procedimento |

---

## Personalidade do Assistente

### Configuração de Comportamento

```tsx
instructions={`
  Você é a assistente virtual da EstéticaPro.

  PERSONALIDADE:
  - Profissional mas acolhedora
  - Proativa em sugerir melhorias
  - Usa emojis com moderação
  - Celebra conquistas do usuário
  - Fala português brasileiro natural

  CONHECIMENTO:
  - Entende de gestão de clínicas de estética
  - Conhece os procedimentos oferecidos
  - Sabe interpretar métricas de negócio
  - Entende sazonalidade do setor

  REGRAS:
  - Sempre sugira ações práticas
  - Explique números de forma simples
  - Priorize o que gera mais resultado
  - Nunca invente dados que não foram fornecidos
  - Confirme antes de executar ações importantes
`}
```

### Labels em Português

```tsx
labels={{
  title: "Assistente EstéticaPro",
  initial: "Olá! Como posso ajudar você hoje?",
  placeholder: "Digite sua mensagem...",
}}
```

---

## Exemplos de Interações

### Cenário 1: Início do Dia
**Usuário abre o sistema**

> "Bom dia! 🌟 Aqui está seu resumo de hoje:
>
> - **8 agendamentos** confirmados
> - **2 retornos** de clientes antigos
> - **1 cliente nova** (primeira vez)
>
> Dica: A cliente das 14h gosta de chá de camomila. Lembrei porque ela mencionou da última vez!"

### Cenário 2: Análise de Problema
**Usuário:** *"Por que minhas vendas caíram?"*

> "Analisando os últimos 30 dias, identifiquei alguns fatores:
>
> 1. **Sazonalidade:** Janeiro costuma ter queda de 15-20% no setor
> 2. **Cancelamentos:** Aumentaram 12%, maioria por 'imprevisto financeiro'
> 3. **Horários vagos:** Segundas à tarde têm 40% de ociosidade
>
> **Sugestões:**
> - Criar promoção 'Segunda Especial' com 15% off
> - Oferecer parcelamento estendido para procedimentos acima de R$ 500
>
> Quer que eu detalhe algum ponto?"

### Cenário 3: Ação Rápida
**Usuário:** *"Manda mensagem de aniversário para quem faz anos essa semana"*

> "Encontrei 4 clientes aniversariantes esta semana:
>
> | Cliente | Data | Último Procedimento |
> |---------|------|---------------------|
> | Maria S. | 18/01 | Limpeza de Pele |
> | Ana P. | 19/01 | Harmonização |
> | Carla M. | 20/01 | Massagem |
> | Julia R. | 21/01 | Design de Sobrancelha |
>
> Preparei uma mensagem personalizada para cada uma. Quer revisar antes de enviar?"

---

## Ações Disponíveis (useCopilotAction)

### Lista de Ações Sugeridas

```tsx
// 1. Buscar clientes para follow-up
useCopilotAction({
  name: "buscarClientesFollowUp",
  description: "Lista clientes que não retornam há X dias",
  parameters: [{ name: "dias", type: "number" }]
});

// 2. Analisar período
useCopilotAction({
  name: "analisarPeriodo",
  description: "Compara métricas entre dois períodos",
  parameters: [
    { name: "periodoInicio", type: "string" },
    { name: "periodoFim", type: "string" }
  ]
});

// 3. Sugerir horários
useCopilotAction({
  name: "sugerirHorarios",
  description: "Sugere horários vagos para agendamento",
  parameters: [{ name: "procedimento", type: "string" }]
});

// 4. Preparar mensagem
useCopilotAction({
  name: "prepararMensagem",
  description: "Cria mensagem personalizada para cliente",
  parameters: [
    { name: "clienteId", type: "string" },
    { name: "tipo", type: "string" } // aniversário, follow-up, promoção
  ]
});

// 5. Gerar relatório
useCopilotAction({
  name: "gerarRelatorio",
  description: "Gera relatório resumido de um período",
  parameters: [{ name: "periodo", type: "string" }],
  render: ({ result }) => <RelatorioVisual dados={result} />
});

// 6. Identificar tendências
useCopilotAction({
  name: "identificarTendencias",
  description: "Analisa tendências nos dados",
  parameters: [{ name: "metrica", type: "string" }]
});
```

---

## Arquitetura Técnica

### Frontend (Vercel)
```
EstéticaPro Next.js
├── CopilotKit Provider
│   ├── useCopilotReadable (dados das telas)
│   ├── useCopilotAction (ações do sistema)
│   └── CopilotSidebar (interface do chat)
```

### Backend (VPS)
```
CopilotRuntime
├── GoogleGenerativeAIAdapter (Gemini)
├── Conexão com Supabase (dados)
└── Lógica de negócio
```

### Fluxo de Dados
```
Usuário → Chat → CopilotKit → VPS → Gemini
                     ↓
              Supabase (dados)
                     ↓
            Resposta humanizada
```

---

## Status de Implementação (Atualizado: Dezembro 2024)

### ✅ Implementado

| Item | Status | Detalhes |
|------|--------|----------|
| CopilotKit v1.4.8 | ✅ Instalado | `@copilotkit/react-core`, `@copilotkit/react-ui`, `@copilotkit/runtime` |
| Central de Insights | ✅ Funcionando | Aba dedicada com chat + área de visualização |
| Análise Mensal | ✅ Funcionando | Chat integrado à página de relatório mensal |
| Runtime Self-hosted | ✅ Configurado | `/api/copilotkit/route.ts` com Gemini 2.5 Flash |
| DynamicVisualizer | ✅ Criado | Cards, gráficos de barra, tabelas, listas |
| Actions básicas | ✅ Implementadas | buscarLeads, buscarOrcamentos, buscarAgendamentos, consultarProcedimento |

### ⏳ Pendente

| Item | Prioridade | Observação |
|------|------------|------------|
| Gráfico de Pizza | Alta | Adicionar ao DynamicVisualizer |
| Exportar PDF | Alta | Botão para exportar visualizações |
| Persistir histórico | Média | Salvar conversas no banco de dados |
| Mais actions | Média | criarAgendamento, enviarMensagem, etc. |

---

## Como o Sistema Funciona (Explicação Simples)

### Analogia: A IA é como um funcionário novo

**Quando você instala o CopilotKit**, é como contratar um funcionário muito inteligente que **não sabe NADA** sobre sua empresa. Ele é esperto, sabe conversar, mas precisa ser ensinado.

### Quem ensina a IA? Nós!

O CopilotKit **não descobre sozinho** onde estão os dados. Nós ensinamos de duas formas:

#### 1. Damos uma "cola" para a IA (`useCopilotReadable`)

É como entregar um resumo escrito para o funcionário:
- "Temos 150 leads no total"
- "30 são de alta prioridade"
- "45 agendamentos esta semana"

A IA **lê essa cola** e consegue responder perguntas básicas.

#### 2. Damos "ferramentas" para a IA (`useCopilotAction`)

É como dar acesso a sistemas:
- "Se perguntarem detalhes de leads, use essa ferramenta para buscar no banco"

Quando o usuário pergunta algo específico, a IA usa a ferramenta, busca no banco, e retorna a resposta.

### Fluxo Visual

```
USUÁRIO PERGUNTA
       ↓
"Quantos leads de alta prioridade?"
       ↓
IA PENSA
       ↓
"Preciso buscar leads... tenho uma ferramenta para isso!"
       ↓
USA A ACTION (ferramenta)
       ↓
ACTION VAI NO BANCO DE DADOS
       ↓
RETORNA OS DADOS
       ↓
IA FORMATA E RESPONDE
       ↓
"Você tem 30 leads de alta prioridade"
```

---

## Actions Implementadas vs Futuras

### ✅ Actions JÁ Existentes

| Action | O que faz | Parâmetros |
|--------|-----------|------------|
| `buscarLeads` | Busca leads com filtros | etapa, prioridade, sentimento, limite |
| `buscarOrcamentos` | Busca orçamentos | status, período, limite |
| `buscarAgendamentos` | Busca agendamentos | período, limite |
| `consultarProcedimento` | Detalhes de procedimento | nome |

### 💡 Actions que PODEMOS Adicionar

| Action | O que faria | Complexidade |
|--------|-------------|--------------|
| `criarAgendamento` | IA agenda horário para cliente | Alta |
| `enviarMensagem` | IA envia WhatsApp para lead | Média |
| `atualizarLead` | IA muda etapa do funil | Média |
| `calcularComissao` | IA calcula comissão do profissional | Baixa |
| `gerarRelatorio` | IA gera relatório de período | Média |
| `buscarProfissionais` | IA lista profissionais disponíveis | Baixa |
| `verificarDisponibilidade` | IA verifica horários livres | Média |
| `prepararFollowUp` | Lista clientes para recontato | Média |
| `analisarTendencias` | Analisa padrões nos dados | Alta |

**Resumo:** Mais actions = IA mais poderosa. Você decide o que ela pode ou não fazer.

---

## Visualizações Disponíveis

### ✅ Implementadas no DynamicVisualizer

| Tipo | Componente | Uso |
|------|------------|-----|
| Cards de métricas | `MetricCards` | Números com ícones coloridos |
| Gráfico de barras | `BarChartVisual` | Comparativos, rankings |
| Lista de clientes | `ClientList` | Leads, pacientes |
| Lista de agendamentos | `ScheduleList` | Agenda do dia/semana |
| Tabela de dados | `DataTable` | Dados tabulares |

### ❌ Ainda NÃO Implementadas

| Tipo | Uso | Status |
|------|-----|--------|
| Gráfico de pizza | Distribuição percentual | Pendente |
| Gráfico de linha | Tendências ao longo do tempo | Pendente |
| Calendário visual | Visualização de agenda | Pendente |

---

## Funcionalidades Futuras

### 1. Exportar para PDF
- Botão "Exportar PDF" em cada visualização
- Usa `jsPDF` + `html2canvas`
- Gera documento com a visualização atual

### 2. Persistir Histórico de Conversas
- Salvar conversas no Supabase
- Carregar histórico ao abrir a página
- Permitir consultar conversas antigas

### 3. Gráfico de Pizza
- Leads por etapa do funil
- Orçamentos por status
- Sentimento dos leads
- Distribuição de procedimentos

---

## Reutilização em Outros Projetos (SaaS)

### Cada projeto PRECISA:

1. **Instalar os pacotes:**
   ```bash
   npm install @copilotkit/react-core @copilotkit/react-ui @copilotkit/runtime
   ```

2. **Copiar a API route:** `/api/copilotkit/route.ts`

3. **Copiar o DynamicVisualizer:** Como base para visualizações

4. **Criar CopilotProvider personalizado:** Com os dados específicos do SaaS

5. **Configurar `GOOGLE_API_KEY` no Vercel**

### O que pode REUTILIZAR:

| Item | Reutilizável? |
|------|---------------|
| Chave do Gemini | ✅ Sim, mesma chave |
| Estrutura da API route | ✅ Sim |
| DynamicVisualizer | ✅ Sim, como base |
| Estrutura do Provider | ✅ Sim, como base |

### O que precisa CUSTOMIZAR:

| Item | Por quê? |
|------|----------|
| `useCopilotReadable` | Cada SaaS tem dados diferentes |
| `useCopilotAction` | Cada SaaS tem ações diferentes |
| Tipos/Interfaces | Estrutura de dados única |

**Tempo estimado:** 1-2 horas para adaptar em novo projeto.

---

## Problemas Conhecidos e Soluções

### 1. Erro HTTPS/HTTP (Mixed Content)
- **Problema:** Vercel (HTTPS) não consegue chamar VPS (HTTP)
- **Solução:** Usar runtime self-hosted em `/api/copilotkit`

### 2. Turbopack Incompatível
- **Problema:** Next.js 16 com Turbopack não compila `@copilotkit/runtime`
- **Solução:** Adicionar `serverExternalPackages` no `next.config.js`:
  ```js
  serverExternalPackages: [
    '@copilotkit/runtime',
    'pino',
    'pino-pretty',
    'thread-stream',
    'type-graphql',
  ]
  ```

### 3. Contexto perdido ao recarregar
- **Problema:** Histórico da conversa se perde ao atualizar página
- **Solução futura:** Persistir no banco de dados

---

## Arquitetura Atual

### Frontend (Vercel)
```
EstéticaPro Next.js
├── /app/api/copilotkit/route.ts    ← Runtime self-hosted
├── /components/ai/
│   ├── CopilotProvider.tsx         ← Provider com dados e actions
│   ├── InsightsCentral.tsx         ← Aba Central de Insights
│   └── DynamicVisualizer.tsx       ← Componentes visuais
```

### Fluxo de Dados
```
Usuário → Chat → CopilotKit → API Route → Gemini 2.5 Flash
                     ↓
              useCopilotAction
                     ↓
              Supabase / APIs Clinix
                     ↓
            Resposta + Visualização
```

---

## Funcionalidades Avançadas do CopilotKit (Ainda Não Exploradas)

### 1. Copilot Textarea - IA em Qualquer Campo de Texto

Transforma qualquer input em um campo inteligente com auto-complete.

**Aplicações no EstéticaPro:**
- Campo de observações do agendamento → IA sugere texto
- Campo de mensagem para WhatsApp → IA escreve a mensagem
- Campo de descrição do lead → IA completa automaticamente

```
┌─────────────────────────────────────────────┐
│ Observações do agendamento:                 │
│ ┌─────────────────────────────────────────┐ │
│ │ Paciente com pele sensível, evitar...   │ │
│ │                                         │ │
│ │ 💡 Sugestão: "...produtos com ácido    │ │
│ │    glicólico. Preferência por          │ │
│ │    tratamentos suaves."                │ │
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

**Impacto:** Alto | **Dificuldade:** Média

---

### 2. Human-in-the-Loop - IA Pede Confirmação

A IA pode pedir confirmação antes de executar ações importantes.

**Exemplo:**
```
Usuário: "Cancela todos os agendamentos de amanhã"

IA: "Encontrei 8 agendamentos para amanhã.
     Tem certeza que deseja cancelar todos?

     [✅ Sim, cancelar]  [❌ Não, voltar]"
```

Evita erros acidentais em ações críticas.

**Impacto:** Alto | **Dificuldade:** Baixa

---

### 3. Generative UI Avançada - IA Cria Interfaces

A IA não só responde texto, ela pode **criar componentes visuais** dinamicamente.

**Exemplo:**
```
Usuário: "Me mostra um resumo visual dos leads"

IA gera na hora:
┌──────────────────────────────────────┐
│  📊 Resumo de Leads                  │
│  ┌────────┐ ┌────────┐ ┌────────┐   │
│  │  150   │ │   30   │ │   45   │   │
│  │ Total  │ │ Quentes│ │ Frios  │   │
│  └────────┘ └────────┘ └────────┘   │
│                                      │
│  [Ver detalhes] [Exportar] [Filtrar] │
└──────────────────────────────────────┘
```

**Impacto:** Alto | **Dificuldade:** Média

---

### 4. CoAgents - Agentes Autônomos

A IA pode executar **tarefas complexas de múltiplos passos** sozinha.

**Exemplo:**
```
Usuário: "Prepara a campanha de aniversariantes do mês"

IA executa automaticamente:
1. ✅ Buscar clientes que fazem aniversário
2. ✅ Verificar último procedimento de cada um
3. ✅ Criar mensagem personalizada para cada
4. ✅ Agendar envio para o dia do aniversário
5. ✅ Gerar relatório da campanha

"Pronto! Campanha criada para 12 clientes.
 Quer revisar antes de ativar?"
```

**Impacto:** Muito Alto | **Dificuldade:** Alta

---

### 5. Knowledge Base - Base de Conhecimento

Conectar documentos, PDFs, manuais para a IA consultar.

**Aplicações no EstéticaPro:**
- Upload do manual de procedimentos
- Upload de contraindicações médicas
- Upload de protocolos da clínica

```
Usuário: "Quais os cuidados pós botox?"

IA: (consulta o PDF do manual)
"De acordo com o protocolo da clínica:
- Não deitar por 4 horas
- Evitar exercícios por 24h
- Não massagear a região..."
```

**Impacto:** Alto | **Dificuldade:** Média

---

### 6. Sugestões Proativas

A IA pode **aparecer proativamente** quando detecta oportunidades.

**Exemplo:**
```
┌─────────────────────────────────────────────┐
│  🤖 Assistente detectou uma oportunidade:   │
│                                             │
│  "A cliente Maria não retorna há 45 dias    │
│   e costumava fazer limpeza de pele mensal. │
│   Quer que eu envie um lembrete?"           │
│                                             │
│  [Sim, enviar] [Ignorar] [Ver perfil]       │
└─────────────────────────────────────────────┘
```

**Impacto:** Alto | **Dificuldade:** Média

---

### 7. Múltiplos Assistentes Especializados

Ter assistentes diferentes para áreas diferentes do sistema.

| Área | Assistente | Personalidade |
|------|------------|---------------|
| CRM | "Vendedor Virtual" | Focado em conversão |
| Agenda | "Secretária IA" | Focada em organização |
| Financeiro | "Consultor IA" | Focado em números |
| Atendimento | "Concierge" | Focado em experiência |

**Impacto:** Médio | **Dificuldade:** Média

---

### 8. Análise de Sentimento em Tempo Real

A IA analisa conversas de WhatsApp e classifica o sentimento.

**Exemplo:**
```
Nova mensagem do lead João:
"Achei muito caro, vou pensar..."

IA detecta: ⚠️ Sentimento NEGATIVO
Sugestão: "Oferecer desconto de primeira consulta?"
```

**Impacto:** Alto | **Dificuldade:** Média

---

### 9. Automações Inteligentes (Triggers)

A IA pode executar ações baseadas em gatilhos automáticos.

**Exemplos:**
| Gatilho | Ação da IA |
|---------|------------|
| Lead não responde há 3 dias | Envia follow-up automático |
| Agendamento cancelado | Oferece remarcar |
| Cliente completou 5 procedimentos | Sugere programa fidelidade |
| Horário vago detectado | Oferece para clientes em espera |
| Aniversário do cliente | Envia mensagem personalizada |
| Orçamento não respondido há 7 dias | Envia lembrete |

**Impacto:** Muito Alto | **Dificuldade:** Alta

---

### 10. Relatórios por Voz

Integração com voz para receber relatórios falados.

```
Você: 🎤 "Como foi o dia de hoje?"

IA: 🔊 "Hoje você teve 8 atendimentos,
     faturamento de R$ 2.400,
     e 2 novos leads entraram pelo Instagram."
```

**Impacto:** Médio | **Dificuldade:** Alta

---

### 11. Previsões e Forecasting

A IA pode prever tendências futuras baseada em dados históricos.

**Exemplo:**
```
Usuário: "Como será o próximo mês?"

IA: "Baseado nos últimos 6 meses, prevejo:
- Faturamento: ~R$ 42.000 (±5%)
- Agendamentos: ~180
- Melhor semana: segunda do mês (pós-salário)
- Risco: Janeiro costuma ter 15% menos movimento"
```

**Impacto:** Alto | **Dificuldade:** Alta

---

### Matriz de Priorização

| Funcionalidade | Impacto | Dificuldade | Prioridade |
|----------------|---------|-------------|------------|
| Human-in-the-Loop | Alto | Baixa | 🔴 Alta |
| Copilot Textarea | Alto | Média | 🔴 Alta |
| Sugestões Proativas | Alto | Média | 🔴 Alta |
| Generative UI avançada | Alto | Média | 🟡 Média |
| Knowledge Base (PDFs) | Alto | Média | 🟡 Média |
| Análise de Sentimento | Alto | Média | 🟡 Média |
| CoAgents (automação) | Muito Alto | Alta | 🟡 Média |
| Automações (triggers) | Muito Alto | Alta | 🟡 Média |
| Múltiplos assistentes | Médio | Média | 🟢 Baixa |
| Previsões/Forecasting | Alto | Alta | 🟢 Baixa |
| Voz | Médio | Alta | 🟢 Baixa |

---

## Próximos Passos

1. [x] ~~Definir quais telas terão o assistente primeiro~~ → Análise Mensal + Central de Insights
2. [x] ~~Mapear os dados que serão expostos ao AI~~ → CopilotProvider.tsx
3. [x] ~~Listar as ações que o AI poderá executar~~ → 4 actions implementadas
4. [x] ~~Configurar o CopilotRuntime~~ → Self-hosted com Gemini
5. [x] ~~Definir a personalidade e regras do assistente~~ → Labels em português
6. [x] ~~Implementar e testar em ambiente de desenvolvimento~~
7. [ ] Adicionar gráfico de pizza
8. [ ] Adicionar exportação para PDF
9. [ ] Persistir histórico de conversas
10. [ ] Adicionar mais actions (criar agendamento, enviar mensagem, etc.)
11. [ ] Refinar baseado no feedback dos usuários

---

## Referências

- [CopilotKit Docs](https://docs.copilotkit.ai/)
- [Generative UI](https://docs.copilotkit.ai/concepts/generative-ui)
- [useCopilotReadable](https://docs.copilotkit.ai/reference/hooks/useCopilotReadable)
- [useCopilotAction](https://docs.copilotkit.ai/reference/hooks/useCopilotAction)

---

*Documento criado em: Dezembro 2024*
*Última atualização: Dezembro 2024*
*Projeto: EstéticaPro - Assistente de Gestão com IA*
