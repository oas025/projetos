# Metodologia de Engenharia Reversa - Clinix API

## Objetivo

Documentar a metodologia utilizada para descobrir e mapear os endpoints da API do Clinix, um sistema de gestão de clínicas que **não possui documentação pública de API**.

---

## Ferramentas Utilizadas

### 1. Playwright MCP (Model Context Protocol)
- **O que é**: Servidor MCP que permite controlar um navegador Chromium via Claude Code
- **Uso**: Automação de navegação, interação com elementos, captura de estado da página

### 2. Interceptador de XHR/Fetch (JavaScript Injetado)
- **O que é**: Script JavaScript injetado na página para interceptar todas as requisições de rede
- **Uso**: Capturar endpoints, payloads, responses em tempo real

### 3. Console do Navegador
- **O que é**: Ferramenta `browser_console_messages` do Playwright MCP
- **Uso**: Ler logs do interceptador e mensagens de debug

---

## Metodologia Passo a Passo

### Fase 1: Preparação do Ambiente

#### 1.1 Abrir o navegador na aplicação alvo
```javascript
// Usando Playwright MCP
browser_navigate({ url: "https://gestao.clinix.app.br/#/login" })
```

#### 1.2 Injetar o Interceptador de Rede
```javascript
browser_evaluate({
  function: `() => {
    // Interceptar XMLHttpRequest
    const originalOpen = XMLHttpRequest.prototype.open;
    const originalSend = XMLHttpRequest.prototype.send;

    XMLHttpRequest.prototype.open = function(method, url) {
      this._method = method;
      this._url = url;
      return originalOpen.apply(this, arguments);
    };

    XMLHttpRequest.prototype.send = function(body) {
      this._body = body;
      this.addEventListener('load', function() {
        try {
          let responseText = '';
          if (this.responseType === '' || this.responseType === 'text') {
            responseText = this.responseText;
          }

          // Log básico de todas as requisições
          console.log('[INTERCEPTOR] XHR:', this._method, this._url, '→', this.status);

          // Captura detalhada para endpoints específicos
          if (this._url && this._url.includes('paciente')) {
            console.log('[CAPTURA] PACIENTE:', JSON.stringify({
              method: this._method,
              url: this._url,
              body: this._body,
              status: this.status,
              response: responseText.substring(0, 5000)
            }, null, 2));
          }
        } catch(e) {
          console.log('[INTERCEPTOR] XHR:', this._method, this._url, '→', this.status, '(blob)');
        }
      });
      return originalSend.apply(this, arguments);
    };

    // Interceptar Fetch API
    const originalFetch = window.fetch;
    window.fetch = function(url, options = {}) {
      const method = options.method || 'GET';
      console.log('[INTERCEPTOR] Fetch:', method, url);
      return originalFetch.apply(this, arguments)
        .then(response => {
          console.log('[INTERCEPTOR] Fetch Response:', method, url, '→', response.status);
          return response;
        });
    };

    console.log('[INTERCEPTOR] ✅ Interceptador de rede ativado!');
    return 'OK';
  }`
})
```

### Fase 2: Descoberta de Endpoints

#### 2.1 Realizar ações na interface
Para cada funcionalidade que queremos mapear:

1. **Navegar até a tela desejada**
```javascript
browser_navigate({ url: "https://gestao.clinix.app.br/#/paciente" })
```

2. **Aguardar carregamento**
```javascript
browser_wait_for({ text: "Nome do elemento esperado" })
// ou
browser_wait_for({ time: 3 })
```

3. **Interagir com elementos**
```javascript
browser_click({ element: "Botão Salvar", ref: "e1234" })
browser_type({ element: "Campo Nome", ref: "e5678", text: "Valor" })
```

4. **Capturar o snapshot da página (para encontrar refs)**
```javascript
browser_snapshot()
// Retorna estrutura YAML com refs de todos elementos
```

#### 2.2 Coletar logs do interceptador
```javascript
browser_console_messages()
// Retorna todos os logs, incluindo as capturas do interceptador
```

### Fase 3: Análise e Documentação

#### 3.1 Identificar padrões
Ao analisar os logs, identificamos:

- **Base URLs**: Diferentes microserviços
  ```
  clinix-autenticacao.azurewebsites.net  → Autenticação
  clinix-cadastro.azurewebsites.net      → Cadastros gerais
  clinix-financeiro.azurewebsites.net    → Operações financeiras
  clinix-api.azurewebsites.net           → API geral
  ```

- **Padrões de endpoint**:
  ```
  GET  /api/v1/{recurso}                 → Listar
  GET  /api/v1/{recurso}?id={id}         → Obter por ID
  POST /api/v1/{recurso}                 → Criar
  PATCH /api/v1/{recurso}                → Atualizar
  ```

- **Estrutura de resposta padrão**:
  ```json
  {
    "success": true,
    "data": { ... }
  }
  ```

#### 3.2 Documentar cada endpoint
Para cada endpoint descoberto, documentar:

1. **Método HTTP** (GET, POST, PATCH, DELETE)
2. **URL completa** com base URL
3. **Query Parameters** (se houver)
4. **Request Body** (para POST/PATCH)
5. **Response Body** (estrutura e campos importantes)
6. **Contexto de uso** (quando é chamado)

---

## Exemplo Prático: Descobrindo o Fluxo de Agendamento

### Passo 1: Login
```
Ação: Preencher credenciais e clicar em Entrar
Captura: POST /api/v1/entrar → 200
Response: { token, user: { idConta, idUsuario, ... } }
```

### Passo 2: Navegar para Agenda
```
Ação: Clicar no menu "Agenda"
Capturas:
  - GET /api/v1/Conta/clinicaconta → Clínicas
  - GET /api/v1/profissionalclinica/idclinica → Profissionais
  - GET /api/v1/statusconsulta → Status disponíveis
  - POST /api/v1/Consulta/filtroagenda → Consultas do período
```

### Passo 3: Criar Agendamento
```
Ação: Clicar em horário vazio → Preencher dados → Salvar
Capturas:
  - POST /api/v1/paciente/autocompleteNome → Buscar paciente
  - GET /api/v1/horarioatendimento → Verificar disponibilidade
  - POST /api/v1/Consulta/gravaconsulta → CRIAR AGENDAMENTO
```

### Passo 4: Documentar payload completo
```json
// POST /api/v1/Consulta/gravaconsulta
{
  "pacienteId": 46711,
  "profissionalId": 1674,
  "cadeiraId": 72,
  "clinicaId": 57,
  "especialidadeId": 1,
  "tipoAtendimentoPersonalizadoId": 806,
  "dataConsulta": "2025-12-10T09:00:00.000Z",
  "observacao": "",
  "statusConsultaId": 1,
  "contaId": 62
}
```

---

## Dicas e Truques

### 1. Interceptador não capturou a requisição?
- **Causa**: Requisição foi feita antes do interceptador ser injetado
- **Solução**: Reinjetar interceptador e repetir a ação

### 2. Response está como "blob"
- **Causa**: `responseType` está configurado como 'blob' (para downloads)
- **Solução**: O endpoint foi identificado, mas o body não pode ser lido. Fazer requisição manual para ver o response.

### 3. Muitas requisições no log
- **Solução**: Filtrar por URL específica:
```javascript
if (this._url && this._url.includes('Consulta')) {
  console.log('[CAPTURA]', ...);
}
```

### 4. Página recarregou e perdeu o interceptador
- **Causa**: Navegação SPA ou refresh
- **Solução**: Reinjetar o interceptador após cada navegação significativa

### 5. Descobrir campos obrigatórios
- **Método**: Enviar payload incompleto e analisar erro de validação
- **Alternativa**: Comparar múltiplas requisições bem-sucedidas

---

## Limitações

1. **Endpoints não utilizados pela UI**: Se a interface não usa um endpoint, não conseguimos descobri-lo
2. **Autenticação**: Precisamos de credenciais válidas para acessar a aplicação
3. **Rate Limiting**: Muitas requisições podem bloquear temporariamente
4. **Mudanças na API**: Endpoints podem mudar sem aviso (não há contrato público)

---

## Estrutura de Arquivos Gerados

```
api-documentation/
├── clinix-api-endpoints.md           # Documentação completa dos endpoints
├── METODOLOGIA-ENGENHARIA-REVERSA.md # Este arquivo
└── (futuro) schemas/                 # JSON Schemas dos payloads
```

---

## Comandos Úteis do Playwright MCP

| Comando | Uso |
|---------|-----|
| `browser_navigate` | Navegar para URL |
| `browser_snapshot` | Capturar estado da página (elementos + refs) |
| `browser_click` | Clicar em elemento |
| `browser_type` | Digitar em campo |
| `browser_evaluate` | Executar JavaScript na página |
| `browser_console_messages` | Ler logs do console |
| `browser_wait_for` | Aguardar texto ou tempo |
| `browser_fill_form` | Preencher múltiplos campos |

---

## Próximos Passos para Expandir a Documentação

1. **Descobrir mais endpoints**: Navegar por todas as telas da aplicação
2. **Mapear erros**: Documentar respostas de erro e códigos HTTP
3. **Criar JSON Schemas**: Formalizar estrutura dos payloads
4. **Testar limites**: Descobrir rate limits e timeouts
5. **Documentar WebSocket**: O Clinix usa WebSocket para notificações em tempo real

---

*Documentação criada em 27/11/2025*
*Metodologia desenvolvida para o projeto de integração EsteticaPro ↔ Clinix*
