# Clinix API - Documentação de Endpoints

## Contexto e Objetivo

Esta documentação foi criada através de **engenharia reversa** da API do Clinix (sistema de gestão de clínicas odontológicas/estéticas) para possibilitar integrações com o **EsteticaPro** e outros sistemas.

> **Metodologia**: Veja [METODOLOGIA-ENGENHARIA-REVERSA.md](METODOLOGIA-ENGENHARIA-REVERSA.md) para entender como os endpoints foram descobertos.

---

## 📋 Changelog / Histórico de Atualizações

| Data | Seção | Alteração |
|------|-------|-----------|
| 2025-12-11 | 19 | **NOVO**: Seção Monitoramento de Vencimentos (Boletos/Faturas) com 5 endpoints |
| 2025-12-11 | 19.1 | **NOVO**: Endpoint `extratofinanceiro` - extrato financeiro com filtro por data de vencimento |
| 2025-12-11 | 19.2 | **NOVO**: Endpoint `metodopagamento` - métodos de pagamento (Boleto, PIX, etc) |
| 2025-12-11 | 19.3 | **NOVO**: Endpoint `financeiroalertacobranca` - alertas automáticos de cobrança |
| 2025-12-11 | 19.4-19.5 | **NOVO**: Endpoints `categoria` e `contacaixa/clinica` |
| 2025-12-08 | 18 | **NOVO**: Seção Painel de Inadimplentes - endpoint com filtro por data e `clinicaId=0` para todas clínicas |
| 2025-12-08 | 17 | **NOVO**: Seção Prontuários/Tratamentos com 3 endpoints para remarketing |
| 2025-12-08 | 17.1 | **NOVO**: Endpoint global `relatorioTratamentos` - lista tratamentos de TODOS pacientes |
| 2025-12-08 | 17.2-17.3 | **NOVO**: Endpoints por paciente (abertos/finalizados) |
| 2025-12-03 | 15.11 | **CORREÇÃO**: Endpoint `procedimentosespecialidade` → `procedimentoespecialidade` (sem 's'). Endpoint anterior retornava 404. |
| 2025-12-03 | - | Criado workflow n8n para buscar profissionais por procedimento usando `tipoProfissionalId` |

---

### Objetivos da Integração

Esta API pode ser utilizada para diversos fins:

1. **Agendamento via IA** - IA do EsteticaPro agenda automaticamente no Clinix
2. **Recuperação de Vendas** - Identificar pacientes que faltaram/cancelaram e reagendar
3. **Sincronização de Dados** - Manter EsteticaPro e Clinix sincronizados
4. **Relatórios e Analytics** - Extrair dados para dashboards e análises
5. **Automação de Processos** - Workflows automatizados via n8n ou similar

### Exemplo: Fluxo de Agendamento via IA
Permitir que a **IA do EsteticaPro** faça agendamentos automáticos que apareçam diretamente no Clinix:

```
┌─────────────────────────────────────────────────────────┐
│  CLIENTE ENTRA EM CONTATO (WhatsApp/Instagram)          │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│  IA DO ESTETICAPRO                                      │
├─────────────────────────────────────────────────────────┤
│  1. Captura dados do cliente (nome, telefone, etc)      │
│  2. Salva lead no EsteticaPro                           │
│  3. Consulta disponibilidade de agenda                  │
│  4. Oferece horários ao cliente                         │
│  5. Cliente escolhe → IA agenda                         │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│  CLINIX (via API)                                       │
├─────────────────────────────────────────────────────────┤
│  - Criar paciente (se não existir)                      │
│  - Criar consulta/agendamento                           │
│  → Aparece automaticamente na agenda do Clinix          │
└─────────────────────────────────────────────────────────┘
```

### Fluxo de Sincronização Inicial

Ao salvar as credenciais do Clinix no EsteticaPro, fazer sync dos dados estruturais:

| Dado | Endpoint | Por quê |
|------|----------|---------|
| Token + contaId | `POST /entrar` | Autenticação |
| Clínicas | `GET /Conta/clinicaconta` | Saber onde agendar |
| Profissionais | `GET /profissionalclinica/idclinica` | Quem atende + especialidadeId |
| **Cadeiras** | `GET /cadeira?clinicaId=X&todos=true` | **Obter cadeiraId** (obrigatório para agendar) |
| Tipos Atendimento | `GET /tipoatendimento/tipoAtendimentoPersonalizado` | Avaliação, Retorno, etc |
| Status Consulta | `GET /statusconsulta` | Mapeamento de IDs |
| Horários | `GET /horarioatendimento` | Para IA saber disponibilidade |

**NÃO precisa sincronizar pacientes** - a IA busca/cria sob demanda.

### Fluxo da IA para Agendar

```javascript
// 1. Buscar paciente por telefone/nome
POST /paciente/autocompleteNome { "prefixo": "11976308339" }

// 2. Se não existe → Criar paciente
POST /paciente { nome, celular, contaId, ... }

// 3. Verificar disponibilidade
POST /agenda/filtraragenda { data, profissionalId, clinicaId }

// 4. Criar agendamento
POST /Consulta/gravaconsulta { pacienteId, dataConsulta, profissionalId, ... }
```

### Fluxo para Reagendar/Cancelar

```javascript
// Reagendar (mudar data/hora)
PATCH /Consulta { id, dataInicio: "nova-data", dataFinal: "nova-data-fim", ... }

// Cancelar (mudar status para 8 = Cancelado)
PATCH /Consulta { id, statusConsulta: 8 }

// Desmarcou (mudar status para 7 = Desmarcou)
PATCH /Consulta { id, statusConsulta: 7 }
```

**IMPORTANTE**: Não existe endpoint DELETE para agendamentos. O cancelamento é feito via PATCH alterando o `statusConsulta`.

### Fluxo para Recuperação de Vendas

Para ver consultas de um paciente (ex: faltou, cancelou):
```javascript
GET /paciente/sobrepaciente?id={pacienteId}
// Retorna lista de consultas com status (Faltou, Cancelado, etc)
```

---

## Informações Gerais

### Base URLs
- **Autenticação**: `https://clinix-autenticacao.azurewebsites.net`
- **Cadastros**: `https://clinix-cadastro.azurewebsites.net/api/v1`
- **Financeiro**: `https://clinix-financeiro.azurewebsites.net`
- **API Geral**: `https://clinix-api.azurewebsites.net`

### Headers Padrão
```json
{
  "Content-Type": "application/json",
  "Accept": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Authorization": "Bearer {JWT_TOKEN}"
}
```

### Formato de Resposta Padrão
```json
{
  "success": true,
  "data": { ... }
}
```

---

## 1. AUTENTICAÇÃO

### 1.1 Login
**Endpoint**: `POST /api/v1/entrar`
**Base URL**: `https://clinix-autenticacao.azurewebsites.net`

**Request Body**:
```json
{
  "login": "email@exemplo.com",
  "password": "senha123"
}
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "user": {
      "idUsuario": 72,
      "nomeUsuario": "Nome do Usuário",
      "nomeConta": "NOME DA CLÍNICA",
      "idConta": 62,
      "idFranqueadora": 0,
      "idProfissional": null,
      "email": "email@exemplo.com",
      "novoLogin": false,
      "cidade": "Curitiba",
      "premium": true,
      "avaliacao": false,
      "dataValidade": null,
      "expirado": false,
      "countryData": {
        "countryCode": null,
        "countryCurrency": null
      },
      "statusPagamento": {
        "mensagem": "",
        "statusPagamento": false
      }
    },
    "grupo": {
      "id": 1,
      "nome": "Administrador",
      "ativo": true
    },
    "menu": [ ... ],
    "token": "eyJhbGciOiJQUzI1NiIs..."
  }
}
```

**Descrição**: Autentica o usuário e retorna um token JWT para uso nas demais requisições.

---

## 2. CONTA / USUÁRIO

### 2.1 Verificar Cartão de Crédito
**Endpoint**: `GET /api/v1/Conta/verificacartao`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
- `idConta` (number): ID da conta
- `idUsuario` (number): ID do usuário

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "needCreditCard": "admin"
  }
}
```

### 2.2 Verificar Inadimplência
**Endpoint**: `GET /api/v1/Conta/verificainadimplencia`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "isInadimplente": false,
    "diasRestantesBloqueio": null
  }
}
```

### 2.3 Obter Contas do Usuário
**Endpoint**: `GET /api/v1/usuarioconta/idusuario`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
- `usuarioId` (number): ID do usuário

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    {
      "id": 0,
      "nomeConta": "NOME DA CLÍNICA",
      "nomeUsuario": "Nome do Usuário",
      "email": "email@exemplo.com",
      "celular": "41999999999",
      "usuarioId": 72,
      "contaId": 62,
      "premium": true,
      "avaliacao": false,
      "expirado": false,
      "dataValidade": null
    }
  ]
}
```

### 2.4 Obter Clínicas da Conta
**Endpoint**: `GET /api/v1/Conta/clinicaconta`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
- `id` (number): ID da conta

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    {
      "id": 56,
      "contaId": 62,
      "conta": { ... },
      "clinicaId": 57,
      "clinica": {
        "id": 57,
        "nome": "Nome da Clínica",
        "fusoHorario": "PR",
        "nomeFantasia": "...",
        "nomeRazaoSocial": "...",
        "cpf": "...",
        "cnpj": null,
        "tipoPessoa": "F",
        "cep": "82115380",
        "rua": "...",
        "numero": "...",
        "bairro": "...",
        "cidade": "Curitiba",
        "estado": "PR",
        "telefone": "...",
        "fusoHorarioId": 2
      },
      "padrao": true,
      "avaliacao": false
    }
  ]
}
```

---

## 3. TIPOS E STATUS (Lookup Tables)

### 3.1 Tipos de Atendimento
**Endpoint**: `GET /api/v1/tipoatendimento`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    {
      "nome": "Avaliação",
      "padrao": true,
      "id": 2,
      "usuario": "...",
      "dataCadastro": "2021-06-24T20:24:34.913",
      "ativo": true
    },
    {
      "nome": "Inicio de Tratamento",
      "padrao": false,
      "id": 7
    },
    {
      "nome": "Reinicio",
      "padrao": false,
      "id": 12
    },
    {
      "nome": "Retorno",
      "padrao": false,
      "id": 14
    },
    {
      "nome": "Tratamento",
      "padrao": false,
      "id": 6
    },
    {
      "nome": "Urgência/Emergência",
      "padrao": false,
      "id": 5
    }
  ]
}
```

### 3.2 Tipos de Atendimento Personalizado (IMPORTANTE PARA AGENDAMENTO)
**Endpoint**: `GET /api/v1/tipoatendimento/tipoAtendimentoPersonalizado`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
- `isAtivos` (boolean): `true` = apenas ativos, `false` = todos

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    {
      "id": 806,
      "nome": "Avaliação",
      "tipoAtendimentoId": 2,
      "tipoAtendimento": {
        "nome": "Avaliação",
        "padrao": true,
        "id": 2
      },
      "contaId": 62,
      "clinicaId": 57,
      "ativo": true
    },
    {
      "id": 810,
      "nome": "Inicio de Tratamento",
      "tipoAtendimentoId": 7,
      "contaId": 62,
      "clinicaId": 57,
      "ativo": true
    }
  ]
}
```

**NOTA**: O campo `id` deste endpoint é o `tipoAtendimentoPersonalizadoId` usado no `POST /Consulta/gravaconsulta`!

### 3.3 Status de Consulta
**Endpoint**: `GET /api/v1/statusconsulta`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    { "nome": "Agendado", "padrao": true, "statusConsultaPainelId": 1, "id": 1 },
    { "nome": "Antecipou Consulta", "padrao": false, "statusConsultaPainelId": 3, "id": 6 },
    { "nome": "Atendido", "padrao": false, "statusConsultaPainelId": 3, "id": 4 },
    { "nome": "Cancelado", "padrao": false, "statusConsultaPainelId": 4, "id": 8 },
    { "nome": "Compareceu", "padrao": false, "statusConsultaPainelId": 3, "id": 2 },
    { "nome": "Confirmado", "padrao": false, "statusConsultaPainelId": 3, "id": 11 },
    { "nome": "Desmarcou", "padrao": false, "statusConsultaPainelId": 4, "id": 7 },
    { "nome": "Em Atendimento", "padrao": false, "statusConsultaPainelId": 3, "id": 3 },
    { "nome": "Faltou", "padrao": false, "statusConsultaPainelId": 2, "id": 5 },
    { "nome": "Reagendou", "padrao": false, "statusConsultaPainelId": 3, "id": 9 }
  ]
}
```

---

## 4. ESPECIALIDADES

### 4.1 Listar Especialidades por Clínica/Conta
**Endpoint**: `GET /api/v1/especialidade/clinicaconta`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
- `contaId` (number): ID da conta
- `clinicaId` (number): ID da clínica

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    { "nome": "Avaliação", "tipoProfissionalId": 1, "id": 12, "ativo": false },
    { "nome": "Cirurgia e Traumatologia - Maxilo - Facial", "tipoProfissionalId": 1, "id": 1, "ativo": true },
    { "nome": "Clinico Geral", "tipoProfissionalId": 1, "id": 13, "ativo": false },
    { "nome": "Dentistica", "tipoProfissionalId": 1, "id": 8, "ativo": true },
    { "nome": "Endodontia", "tipoProfissionalId": 1, "id": 3, "ativo": true },
    { "nome": "Harmonizacao Orofacial", "tipoProfissionalId": 1, "id": 11, "ativo": true },
    { "nome": "Implantodontia", "tipoProfissionalId": 1, "id": 6, "ativo": true },
    { "nome": "Odontogeriatria", "tipoProfissionalId": 1, "id": 5, "ativo": true },
    { "nome": "Odontopediatria", "tipoProfissionalId": 1, "id": 2, "ativo": true },
    { "nome": "Ortodontia", "tipoProfissionalId": 1, "id": 7, "ativo": true },
    { "nome": "Periodontia", "tipoProfissionalId": 1, "id": 4, "ativo": true },
    { "nome": "Protese Dentaria", "tipoProfissionalId": 1, "id": 10, "ativo": true },
    { "nome": "Radiologia Odontologica e Imaginologia", "tipoProfissionalId": 1, "id": 9, "ativo": true }
  ]
}
```

---

## 5. CADEIRAS (Consultórios)

### 5.1 Listar Cadeiras por Clínica
**Endpoint**: `GET /api/v1/cadeira`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
- `clinicaId` (number, obrigatório): ID da clínica
- `todos` (boolean, opcional): Se `true`, retorna todas as cadeiras (ativas e inativas)

**Exemplo de URL**:
```
GET /api/v1/cadeira?clinicaId=57&todos=true
```

**cURL**:
```bash
curl -X GET "https://clinix-cadastro.azurewebsites.net/api/v1/cadeira?clinicaId=57&todos=true" \
  -H "Authorization: Bearer TOKEN"
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    {
      "id": 62,
      "nome": "Cadeira 1",
      "clinicaId": 57,
      "clinica": {
        "id": 57,
        "nome": "Sorriso Dental",
        "fusoHorario": "PR",
        "nomeFantasia": "Nome Fantasia",
        "telefone": "41999999999",
        "ativo": true
      },
      "usuario": "usuario@email.com",
      "dataCadastro": "2022-04-27T17:22:10.190223",
      "ativo": true
    }
  ]
}
```

**IMPORTANTE**: Este é o endpoint correto para obter o `cadeiraId` necessário para criar agendamentos. O endpoint `/profissionalclinica/idclinica` **NÃO** retorna `cadeiraId`.

### 4.2 Especialidades por Conta
**Endpoint**: `GET /api/v1/especialidade/conta`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
- `contaId` (number): ID da conta

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    { "nome": "Cirurgia e Traumatologia - Maxilo - Facial", "tipoProfissionalId": 1, "id": 1, "ativo": true },
    { "nome": "Odontopediatria", "tipoProfissionalId": 1, "id": 2, "ativo": true },
    { "nome": "Endodontia", "tipoProfissionalId": 1, "id": 3, "ativo": true }
  ]
}
```

---

## 6. PACIENTES

### 6.1 Filtrar Pacientes
**Endpoint**: `GET /api/v1/pacientefiltro`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
- `clinicaId` (number): ID da clínica
- `contaId` (number): ID da conta
- `pageNumber` (number): Número da página (paginação)
- `pageSize` (number): Quantidade de registros por página
- `orderByProperty` (string): Campo para ordenação (ex: "nome")
- `orderByDesc` (boolean): Ordenação descendente

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "pageNumber": 1,
    "pageSize": 15,
    "totalRecords": 150,
    "totalPages": 10,
    "data": [
      {
        "id": 123,
        "nome": "Nome do Paciente",
        "cpf": "12345678901",
        "dataNascimento": "1990-01-15T00:00:00",
        "telefone": "41999999999",
        "email": "paciente@email.com",
        "ativo": true
      }
    ]
  }
}
```

### 6.2 Origem de Relacionamento
**Endpoint**: `GET /api/v1/origemrelacionamento`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    { "nome": "Facebook", "id": 1, "ativo": true },
    { "nome": "Google", "id": 2, "ativo": true },
    { "nome": "Indicação", "id": 3, "ativo": true },
    { "nome": "Instagram", "id": 4, "ativo": true },
    { "nome": "Outros", "id": 5, "ativo": true }
  ]
}
```

### 6.3 Campanhas
**Endpoint**: `GET /api/v1/campanha`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
- `contaId` (number): ID da conta

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "nome": "Campanha Marketing",
      "contaId": 62,
      "ativo": true
    }
  ]
}
```

### 6.4 Obter Próximo Código de Paciente
**Endpoint**: `GET /api/v1/paciente/GetProximoCodigoPaciente`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
- `contaId` (number): ID da conta

**Response (200 OK)**:
```json
{
  "success": true,
  "data": 40
}
```

### 6.5 CRIAR PACIENTE
**Endpoint**: `POST /api/v1/paciente`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Request Body COMPLETO**:
```json
{
  "nome": "Nome do Paciente",
  "sexo": "M",
  "celular": "11976308339",
  "telefone": null,
  "nomeSocial": null,
  "codigoPaciente": 39,
  "dataNascimento": "1958-12-23T03:00:00.000Z",
  "cpf": null,
  "planoId": 77,
  "email": "paciente@email.com",
  "origemRelacionamentoId": 452,
  "origemRelacionamentoOutros": null,
  "origemRelacionamentoPacienteId": null,
  "campanhaId": null,
  "possuiResponsavel": false,
  "nomeResponsavel": null,
  "cpfResponsavel": null,
  "dataNascimentoResponsavel": null,
  "cep": "03268110",
  "logradouro": "Rua Example",
  "numero": 200,
  "bairro": "Centro",
  "complemento": null,
  "cidade": "São Paulo",
  "estado": "SP",
  "observacao": null,
  "score": "0",
  "usuario": "Nome do Usuário",
  "contaId": 62
}
```

**Campos Obrigatórios**:
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `nome` | string | Nome completo do paciente |
| `celular` | string | Celular (apenas números) |
| `contaId` | number | ID da conta |
| `planoId` | number | ID do plano/convênio |

**Campos Opcionais**:
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `sexo` | string | "M" = Masculino, "F" = Feminino |
| `telefone` | string | Telefone fixo |
| `nomeSocial` | string | Nome social |
| `codigoPaciente` | number | Código sequencial (usar GetProximoCodigoPaciente) |
| `dataNascimento` | string | Data nascimento (ISO 8601) |
| `cpf` | string | CPF (apenas números) |
| `email` | string | E-mail do paciente |
| `origemRelacionamentoId` | number | ID da origem (Facebook, Google, etc) |
| `campanhaId` | number | ID da campanha de marketing |
| `possuiResponsavel` | boolean | Se paciente tem responsável |
| `nomeResponsavel` | string | Nome do responsável (se menor) |
| `cpfResponsavel` | string | CPF do responsável |
| `dataNascimentoResponsavel` | string | Data nascimento responsável |
| `cep` | string | CEP (apenas números) |
| `logradouro` | string | Rua/Avenida |
| `numero` | number | Número do endereço |
| `bairro` | string | Bairro |
| `complemento` | string | Complemento |
| `cidade` | string | Cidade |
| `estado` | string | UF (2 letras) |
| `observacao` | string | Observações gerais |
| `score` | string | Score do paciente |
| `usuario` | string | Nome do usuário que cadastrou |

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "id": 170939,
    "nome": "Nome do Paciente",
    "contaId": 62,
    "celular": "11976308339",
    "email": "paciente@email.com",
    "statusPacienteId": 1,
    "planoId": 77,
    "codigoPaciente": 39,
    "dataCadastro": "2025-11-27T19:53:11.800643",
    "ativo": true
  }
}
```

### 6.6 Busca de CEP (API Externa)
**Endpoint**: `GET /api/v1/Cep/GetPorCep/{cep}`
**Base URL**: `https://cep.odontosfera.com.br`

**Response (200 OK)**:
```json
{
  "cep": "03268110",
  "logradouro": "R do Bispo",
  "bairro": "Vila Tolstoi",
  "cidade": "São Paulo",
  "estado": "SP"
}
```

### 6.7 Obter Paciente por ID (para edição)
**Endpoint**: `POST /api/v1/paciente/id`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Request Body**:
```json
["46711"]
```

**Nota**: Enviar array com ID(s) do(s) paciente(s) como strings.

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    {
      "id": 46711,
      "nome": "Abílio Diniz",
      "nomeSocial": null,
      "nomeMae": null,
      "rendaAtual": 0,
      "sexo": null,
      "celular": "21971978101",
      "telefone": null,
      "cpf": "24741070026",
      "nif": null,
      "dataNascimento": "1988-12-09T02:00:00",
      "planoId": 77,
      "statusPacienteId": 1,
      "email": "ivan.mastrange@clinix.app.br",
      "possuiResponsavel": false,
      "nomeResponsavel": null,
      "cpfResponsavel": null,
      "nifResponsavel": null,
      "dataNascimentoResponsavel": null,
      "cep": "82110000",
      "logradouro": "R Alexandre V Humboldt",
      "numero": "350",
      "complemento": "",
      "bairro": "Pilarzinho",
      "cidade": "Curitiba",
      "estado": "PR",
      "codigoPostal": null,
      "localidade": null,
      "concelho": null,
      "distrito": null,
      "observacao": null,
      "avatarUrl": "https://azclinixstorage.blob.core.windows.net/conta62/...",
      "emancipado": false,
      "docEmancipado": null,
      "score": 0,
      "confirmaConsultaEnvio": true,
      "planoResponsavel": null,
      "planoCpfResponsavel": null,
      "planoNIFResponsavel": null,
      "numeroCarteira": null,
      "rg": null,
      "emissor": null,
      "dataEmissao": null,
      "dataAlteracao": null,
      "codigoPaciente": 27,
      "idAsaas": null,
      "isAniversario": false,
      "rnm": null,
      "origemRelacionamentoId": 6,
      "origemRelacionamento": {
        "contaId": 62,
        "nome": "Outros",
        "campoAdicional": "-",
        "isAgendamentoConsulta": true,
        "isCampoAdicional": true,
        "isCampoPaciente": false
      },
      "origemRelacionamentoOutros": null,
      "origemRelacionamentoPacienteId": null,
      "statusPaciente": {
        "id": 1,
        "nome": "AVALIAÇÃO"
      },
      "plano": {
        "id": 77,
        "nome": "Plano Particular",
        "contaId": 62,
        "tipoProfissionalId": 1,
        "padrao": true,
        "fontePagadora": 1,
        "possuiFranquia": false
      },
      "contaId": 62,
      "conta": {
        "id": 62,
        "nome": "SORRISO DENTAL 2",
        "email": "henrique.silva@clinix.app.br"
      },
      "campanhaId": null,
      "campanha": null,
      "contaPossuiPermissaoEdicao": true,
      "usuario": "Henrique Lopes da Silva",
      "dataCadastro": "2024-07-30T17:25:31.591536",
      "ativo": true
    }
  ]
}
```

### 6.8 EDITAR/ATUALIZAR PACIENTE
**Endpoint**: `PATCH /api/v1/paciente`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Request Body** (enviar campos que deseja atualizar):
```json
{
  "id": 46711,
  "nome": "Abílio Diniz",
  "sexo": "M",
  "celular": "21971978101",
  "telefone": null,
  "nomeSocial": null,
  "dataNascimento": "1988-12-09T02:00:00",
  "cpf": "24741070026",
  "planoId": 77,
  "email": "novo.email@exemplo.com",
  "origemRelacionamentoId": 6,
  "cep": "82110000",
  "logradouro": "R Alexandre V Humboldt",
  "numero": "350",
  "bairro": "Pilarzinho",
  "complemento": "",
  "cidade": "Curitiba",
  "estado": "PR",
  "observacao": "Observações atualizadas",
  "contaId": 62
}
```

**Campos Obrigatórios para PATCH**:
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | number | ID do paciente |
| `contaId` | number | ID da conta |

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "id": 46711,
    "nome": "Abílio Diniz",
    ...
  }
}
```

### 6.9 Verificar CPF Duplicado
**Endpoint**: `GET /api/v1/paciente/cpf`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
- `cpf` (string): CPF a verificar
- `id` (number): ID do paciente atual (para excluir da verificação)

**Response (200 OK)**:
```json
{
  "success": true,
  "data": null
}
```

**Nota**: Se `data` for `null`, o CPF está disponível. Se retornar dados de paciente, significa que já existe outro paciente com esse CPF.

### 6.10 Obter Página "Sobre" do Paciente (com Consultas Agendadas)
**Endpoint**: `GET /api/v1/paciente/sobrepaciente`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
- `id` (number, required): ID do paciente

**Request**:
```
GET /api/v1/paciente/sobrepaciente?id=46711
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "id": 46711,
    "nome": "Abílio Diniz",
    "nomeSocial": null,
    "celular": "21971978101",
    "telefone": null,
    "cpf": "24741070026",
    "dataNascimento": "1988-12-09T02:00:00",
    "email": "paciente@email.com",
    "sexo": "M",
    "planoId": 77,
    "plano": {
      "id": 77,
      "nome": "Plano Particular"
    },
    "numeroCarteira": null,
    "cep": "82110000",
    "logradouro": "R Alexandre V Humboldt",
    "numero": "350",
    "complemento": "",
    "bairro": "Pilarzinho",
    "cidade": "Curitiba",
    "estado": "PR",
    "origemRelacionamentoId": 6,
    "origemRelacionamento": {
      "nome": "Outros"
    },
    "codigoPaciente": 27,
    "statusPacienteId": 1,
    "statusPaciente": {
      "id": 1,
      "nome": "AVALIAÇÃO"
    },
    "confirmaConsultaEnvio": true,
    "consultas": [
      {
        "id": 711720,
        "dataConsulta": "2025-12-05T09:00:00",
        "statusConsultaId": 6,
        "statusConsulta": {
          "id": 6,
          "nome": "Cancelado"
        },
        "profissionalId": 1674,
        "profissional": {
          "id": 1674,
          "nome": "Ana F."
        },
        "especialidadeId": 1,
        "especialidade": {
          "id": 1,
          "nome": "Clinico Geral"
        }
      }
    ],
    "ultimaEvolucao": {
      "procedimento": "Restauracao de amalgama - 1 face",
      "status": "concluído",
      "data": "2024-09-13",
      "profissionalExecutante": "Alda Silva"
    }
  }
}
```

**Descrição**: Retorna os dados completos da página "Sobre" do paciente, incluindo:
- Informações pessoais (nome, contato, endereço, etc.)
- Lista de consultas agendadas com status, profissional e especialidade
- Última evolução do paciente
- Configuração de envio de mensagem de confirmação

**Uso**: Este endpoint é chamado ao acessar a tela de perfil do paciente em `/#/paciente/sobre/{pacienteId}`.

### 6.11 Obter Dados Financeiros do Paciente
**Endpoint**: `GET /api/v1/paciente/financeiropaciente`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
- `id` (number, required): ID do paciente

**Request**:
```
GET /api/v1/paciente/financeiropaciente?id=46711
```

**Descrição**: Retorna os dados financeiros resumidos do paciente exibidos na página "Sobre".

### 6.12 Obter Indicações do Paciente
**Endpoint**: `GET /api/v1/indicacao/indicacoespaciente`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
- `pacienteId` (number, required): ID do paciente

**Request**:
```
GET /api/v1/indicacao/indicacoespaciente?pacienteId=46711
```

**Descrição**: Retorna a lista de indicações (referrals) associadas ao paciente.

### 6.13 Obter Gráfico Financeiro do Paciente
**Endpoint**: `GET /api/v1/financeirodetalhes/grafico`
**Base URL**: `https://clinix-financeiro.azurewebsites.net`

**Query Parameters**:
- `pacienteId` (number, required): ID do paciente

**Request**:
```
GET /api/v1/financeirodetalhes/grafico?pacienteId=46711
```

**Descrição**: Retorna os dados para renderização do gráfico financeiro do paciente.

### 6.14 BUSCAR PACIENTE (Autocomplete por CPF/Nome/Telefone)
**Endpoint**: `POST /api/v1/paciente/autocompleteNome`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `prefixo` | string | Sim | CPF, nome ou telefone para busca |
| `contaId` | number | Sim | ID da conta |

**Request Body**:
```json
{
  "prefixo": "24741070026",
  "contaId": 62
}
```

**Request Exemplo**:
```
POST /api/v1/paciente/autocompleteNome?prefixo=24741070026&contaId=62
```

**Response (200 OK) - Paciente encontrado**:
```json
{
  "success": true,
  "data": [
    {
      "id": 46711,
      "nome": "Abílio Diniz",
      "nomeSocial": null,
      "cpf": "24741070026",
      "celular": "11976308339",
      "telefone": null,
      "email": "paciente@email.com",
      "dataNascimento": "1988-12-09T02:00:00",
      "sexo": null,
      "cep": "82110000",
      "logradouro": "R Alexandre V Humboldt",
      "numero": "350",
      "bairro": "Pilarzinho",
      "cidade": "Curitiba",
      "estado": "PR",
      "planoId": 77,
      "plano": {
        "nome": "Plano Particular",
        "id": 77
      },
      "statusPacienteId": 1,
      "statusPaciente": {
        "id": 1,
        "nome": "AVALIAÇÃO"
      },
      "origemRelacionamentoId": 6,
      "origemRelacionamento": {
        "nome": "Outros",
        "id": 6
      },
      "contaId": 62,
      "codigoPaciente": 27,
      "dataCadastro": "2024-07-30T17:25:31.591536",
      "ativo": true
    }
  ]
}
```

**Response (200 OK) - Paciente NÃO encontrado**:
```json
{
  "success": true,
  "data": []
}
```

**Uso Recomendado**:
- Verificar se paciente já existe antes de cadastrar
- Busca por CPF (mais precisa) ou por nome/telefone
- Retorna dados completos do paciente para uso imediato

**Exemplo de Lógica**:
```javascript
// 1. Buscar paciente por CPF
const response = await fetch('/api/v1/paciente/autocompleteNome?prefixo=12345678900&contaId=62', {
  method: 'POST',
  body: JSON.stringify({ prefixo: '12345678900', contaId: 62 })
});
const result = await response.json();

// 2. Verificar se existe
if (result.data.length > 0) {
  // Paciente existe - usar o ID retornado
  const pacienteId = result.data[0].id;
} else {
  // Paciente não existe - criar novo
  // POST /api/v1/paciente
}
```

### 6.15 BUSCAR PACIENTE (Lista Filtrada com Pesquisa)
**Endpoint**: `GET /api/v1/paciente/pacientefiltro`
**Base URL**: `https://clinix-financeiro.azurewebsites.net`

**Query Parameters**:
| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `contaId` | number | Sim | ID da conta |
| `pesquisa` | string | Não | Texto de busca (CPF, nome ou celular) |
| `pagina` | number | Não | Número da página (default: 1) |
| `tamanhoPagina` | number | Não | Itens por página (default: 10) |
| `ordenacao` | string | Não | Campo para ordenação (ex: "Nome") |
| `ordem` | string | Não | Direção (ASC/DESC) |
| `todos` | boolean | Não | Incluir inativos |
| `profissionalId` | number | Não | Filtrar por profissional |
| `especialidadeId` | number | Não | Filtrar por especialidade |
| `origemRelacionamentoId` | number | Não | Filtrar por origem |
| `campanhaId` | number | Não | Filtrar por campanha |

**Request Exemplo** (busca por CPF):
```
GET /api/v1/paciente/pacientefiltro?contaId=62&pesquisa=24741070026&pagina=1&tamanhoPagina=10
```

**Response (200 OK) - Paciente encontrado**:
```json
{
  "success": true,
  "data": {
    "pacientes": [
      {
        "id": 46711,
        "contaId": 62,
        "nome": "Abílio Diniz",
        "celular": "11976308339",
        "cpf": "24741070026",
        "dataCadastro": "2024-07-30T17:25:31.591536",
        "dataNascimento": "1988-12-09T02:00:00",
        "idade": 36,
        "sexo": null,
        "ativo": true,
        "isContrato": false,
        "contrato": 2,
        "tratamento": 1
      }
    ],
    "totalizadorPrincipal": {
      "cadastros": 55,
      "contratos": 15,
      "pctContrato": 27.27
    }
  }
}
```

**Response (200 OK) - Nenhum resultado**:
```json
{
  "success": true,
  "data": {
    "pacientes": [],
    "totalizadorPrincipal": {
      "cadastros": 55,
      "contratos": 15,
      "pctContrato": 27.27
    }
  }
}
```

**Diferença entre autocompleteNome e pacientefiltro**:
| Característica | autocompleteNome | pacientefiltro |
|----------------|------------------|----------------|
| **Método** | POST | GET |
| **Base URL** | clinix-cadastro | clinix-financeiro |
| **Dados retornados** | Completos (endereço, plano, etc) | Resumidos (lista) |
| **Paginação** | Não | Sim |
| **Filtros avançados** | Não | Sim (profissional, especialidade) |
| **Uso ideal** | Verificar existência + obter dados | Listar/pesquisar pacientes |

### Resumo: Operações de Paciente

| Operação | Método | Endpoint | Descrição |
|----------|--------|----------|-----------|
| **Listar** | GET | `/pacientefiltro` | Lista paginada com filtros e busca por texto |
| **Buscar (Autocomplete)** | POST | `/paciente/autocompleteNome` | Busca rápida por CPF, nome ou telefone |
| **Obter por ID** | POST | `/paciente/id` | Dados completos para edição |
| **Criar** | POST | `/paciente` | Cadastrar novo paciente |
| **Editar** | PATCH | `/paciente` | Atualizar dados existentes |
| **Verificar CPF** | GET | `/paciente/cpf` | Verificar duplicidade |
| **Próximo Código** | GET | `/paciente/GetProximoCodigoPaciente` | Sequencial para novo cadastro |
| **Página Sobre** | GET | `/paciente/sobrepaciente` | Dados + Consultas agendadas |
| **Financeiro Paciente** | GET | `/paciente/financeiropaciente` | Dados financeiros do paciente |
| **Indicações** | GET | `/indicacao/indicacoespaciente` | Indicações do paciente |
| **Gráfico Financeiro** | GET | `/financeirodetalhes/grafico` | Dados do gráfico financeiro |

---

## 7. PROFISSIONAIS

### 7.1 Listar Profissionais por Conta (Lista Completa com Especialidades)
**Endpoint**: `GET /api/v1/profissional`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `contaId` | number | Sim | ID da conta |
| `todos` | boolean | Não | `false` = apenas ativos, `true` = todos |

**Request**:
```
GET /api/v1/profissional?contaId=62&todos=false
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    {
      "id": 166,
      "nome": "Alda Silva",
      "cpf": "55156764088",
      "email": "charles.almeida@clinix.app.br",
      "celular": "16994645653",
      "contaId": 62,
      "tipoProfissionalId": 1,
      "nomeTipoProfissional": "Dentista",
      "usuarioId": null,
      "dataCadastro": "0001-01-01T00:00:00",
      "ativo": true,
      "avatarUrl": "https://ui-avatars.com/api/?background=c200ce",
      "avatarCor": "#c200ce",
      "registroConselho": "123www",
      "tempoConsulta": 20,
      "ufConselho": "AL",
      "permiteEncaixe": true,
      "remuneracao": false,
      "valorRemuneracaoFixa": 0,
      "diaRemuneracaoFixa": 0,
      "cep": null,
      "logradouro": null,
      "numero": 0,
      "complemento": null,
      "bairro": null,
      "cidade": null,
      "estado": null,
      "cnpj": null,
      "nif": null,
      "registroOmd": null,
      "distritoOmd": null,
      "tipoPessoa": 0,
      "dataUltimaRemuneracao": "2023-11-14T00:00:00",
      "dataAtualizacao": null,
      "especialidadesProfissional": [
        { "id": 12, "nome": "Avaliação", "profissionalNome": "Alda Silva" },
        { "id": 2, "nome": "Odontopediatria", "profissionalNome": "Alda Silva" },
        { "id": 11, "nome": "Harmonizacao Orofacial", "profissionalNome": "Alda Silva" },
        { "id": 13, "nome": "Clinico Geral", "profissionalNome": "Alda Silva" }
      ]
    }
  ]
}
```

**Campos Importantes**:
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | number | ID do profissional (usar em agendamentos) |
| `nome` | string | Nome completo |
| `tempoConsulta` | number | Duração padrão da consulta em minutos |
| `permiteEncaixe` | boolean | Se permite encaixes na agenda |
| `especialidadesProfissional` | array | Lista de todas especialidades do profissional |
| `avatarCor` | string | Cor para exibição na agenda |
| `nomeTipoProfissional` | string | "Dentista", "Esteticista", etc. |

**Uso recomendado**: Listagem administrativa, cadastro, relatórios.

---

### 7.2 Listar Profissionais por Clínica (Para Agenda) ⭐ RECOMENDADO PARA AGENDA
**Endpoint**: `GET /api/v1/profissionalclinica/idclinica`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `contaId` | number | Sim | ID da conta |
| `clinicaId` | number | Sim | ID da clínica |

**Request**:
```
GET /api/v1/profissionalclinica/idclinica?contaId=62&clinicaId=57
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "clinica": [
      {
        "id": 57,
        "nome": "Sorriso Dental",
        "fusoHorario": "PR",
        "nomeFantasia": "Henrique Lopes da Silva",
        "nomeRazaoSocial": "Henrique Lopes da Silva",
        "cep": "82115380",
        "rua": "R Otalino A de Souza",
        "numero": "325",
        "bairro": "Pilarzinho",
        "cidade": "Curitiba",
        "estado": "PR",
        "telefone": "41996318162",
        "fusoHorarioId": 2,
        "atendeDiaTodo": true,
        "ativo": true
      }
    ],
    "profissionais": [
      {
        "profissional": {
          "id": 166,
          "nome": "Alda Silva",
          "cpf": "55156764088",
          "email": "charles.almeida@clinix.app.br",
          "celular": "16994645653",
          "tipoProfissionalId": 1,
          "registroConselho": "123www",
          "ufConselho": "AL",
          "tempoConsulta": 20,
          "avatarUrl": "https://ui-avatars.com/api/?background=c200ce",
          "avatarCor": "#c200ce",
          "usuarioId": null,
          "contaId": 62,
          "permiteEncaixe": true,
          "remuneracao": false,
          "valorRemuneracaoFixa": 0,
          "diaRemuneracaoFixa": 0,
          "ativo": true
        },
        "posJornada": null
      },
      {
        "profissional": {
          "id": 1674,
          "nome": "Ana Flávia",
          "cpf": "37935378037",
          "email": "anaflavia@teste.com",
          "celular": "41996318162",
          "tipoProfissionalId": 1,
          "registroConselho": "AF1234",
          "ufConselho": "PR",
          "tempoConsulta": 10,
          "avatarUrl": "https://ui-avatars.com/api/?background=B4D610",
          "avatarCor": "#B4D610",
          "usuarioId": 951,
          "contaId": 62,
          "permiteEncaixe": false,
          "remuneracao": true,
          "valorRemuneracaoFixa": 1500,
          "diaRemuneracaoFixa": 6,
          "ativo": true
        },
        "posJornada": null
      }
    ]
  }
}
```

**Campos Importantes**:
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `data.clinica` | array | Dados da clínica (inclui fuso horário) |
| `data.profissionais` | array | Lista de profissionais da clínica |
| `profissional.id` | number | ID do profissional (usar em agendamentos) |
| `profissional.tempoConsulta` | number | Duração padrão em minutos |
| `profissional.avatarCor` | string | Cor para exibição na agenda |
| `profissional.permiteEncaixe` | boolean | Se aceita encaixes |
| `posJornada` | object/null | Posição na jornada de trabalho |

**Uso recomendado**: Tela de agenda, seleção de profissional para agendamento.

---

### 7.3 Obter Profissional por ID
**Endpoint**: `GET /api/v1/profissional/id`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `id` | number | Sim | ID do profissional |

**Request**:
```
GET /api/v1/profissional/id?id=1674
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "id": 1674,
    "nome": "Ana Flávia",
    "cpf": "37935378037",
    "email": "anaflavia@teste.com",
    "celular": "41996318162",
    "tipoProfissionalId": 1,
    "registroConselho": "AF1234",
    "ufConselho": "PR",
    "tempoConsulta": 10,
    "avatarCor": "#B4D610",
    "permiteEncaixe": false,
    "ativo": true
  }
}
```

---

### Comparativo: Qual Endpoint Usar?

| Característica | `/profissional` | `/profissionalclinica/idclinica` |
|----------------|-----------------|----------------------------------|
| **Filtro por clínica** | ❌ Não (apenas contaId) | ✅ Sim |
| **Lista especialidades** | ✅ Array completo | ❌ Não inclui |
| **Info da clínica** | ❌ Não retorna | ✅ Retorna junto |
| **posJornada** | ❌ Não inclui | ✅ Inclui |
| **nomeTipoProfissional** | ✅ Inclui | ❌ Não inclui |
| **Estrutura** | Array simples | Agrupado por clínica |
| **Uso ideal** | Listagem/Cadastro | **Agenda** ⭐ |

### Resumo: Operações de Profissional

| Operação | Método | Endpoint | Uso |
|----------|--------|----------|-----|
| **Listar (completo)** | GET | `/profissional?contaId={}&todos=false` | Listagem administrativa |
| **Listar (para agenda)** | GET | `/profissionalclinica/idclinica?contaId={}&clinicaId={}` | **Tela de agenda** ⭐ |
| **Obter por ID** | GET | `/profissional/id?id={}` | Detalhes de um profissional |

---

## 8. USUÁRIOS

### 8.1 Listar Usuários
**Endpoint**: `GET /api/v1/usuario`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
- `contaId` (number): ID da conta

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    {
      "id": 72,
      "nome": "Nome do Usuário",
      "email": "usuario@email.com",
      "grupoId": 1,
      "grupo": {
        "id": 1,
        "nome": "Administrador"
      },
      "ativo": true
    }
  ]
}
```

### 8.2 Verificar se CPF já Existe
**Endpoint**: `GET /api/v1/usuario/cpf`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
- `cpf` (string): CPF do usuário (apenas números, 11 dígitos)

**Response (200 OK)**:
```json
{
  "success": true,
  "data": true  // true = CPF já cadastrado, false = CPF disponível
}
```

**Descrição**: Verifica se um CPF já está cadastrado no sistema antes de criar um novo usuário.

### 8.3 Listar Grupos de Usuários
**Endpoint**: `GET /api/v1/grupo`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    { "id": 1, "nome": "Administrador", "ativo": true },
    { "id": 2, "nome": "Profissionais de saude", "ativo": true },
    { "id": 4, "nome": "Secretarias(os)", "ativo": true }
  ]
}
```

**Descrição**: Lista os grupos disponíveis para atribuir a um usuário.

### 8.4 Listar Permissões do Grupo
**Endpoint**: `GET /api/v1/grupopermissao/id`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
- `id` (number): ID do grupo

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "nome": "Planos",
      "permissoes": [
        { "id": 1, "nome": "Cadastrar Planos", "padrao": true }
      ]
    },
    {
      "id": 8,
      "nome": "Agenda",
      "permissoes": [
        { "id": 8, "nome": "Visualizar Agenda", "padrao": true },
        { "id": 9, "nome": "Incluir Agendamento", "padrao": true },
        { "id": 10, "nome": "Excluir Agendamento", "padrao": true },
        { "id": 11, "nome": "Cadastrar Paciente", "padrao": true }
      ]
    }
    // ... mais categorias de permissões
  ]
}
```

**Descrição**: Lista todas as permissões disponíveis para um grupo específico, organizadas por categoria.

### 8.5 Validar Dados do Usuário (pré-criação)
**Endpoint**: `POST /api/v1/validardadosusuario`
**Base URL**: `https://clinix-autenticacao.azurewebsites.net`

**Query Parameters**:
- `email` (string): Email do usuário
- `celular` (string): Celular do usuário

**Request Body**:
```json
{
  "nome": "Nome do Usuário",
  "cpf": "52998224725",
  "celular": "41999887766",
  "email": "usuario@email.com",
  "confirmarEmail": "usuario@email.com",
  "grupoId": 1,
  "profissional_saude": {
    "tipoProfissionalId": "",
    "registroConselho": "",
    "ufConselho": "",
    "distritoOmd": null,
    "registroOmd": null
  },
  "nif": null,
  "senha": "Senha@123",
  "confirmarSenha": "Senha@123",
  "login": "usuario@email.com",
  "contaId": 62,
  "permissoesUsuarioConta": [
    { "permissaoId": 1, "ativo": true },
    { "permissaoId": 8, "ativo": true }
  ]
}
```

**Response (200 OK)**: Response vazia - validação passou

**Descrição**: Valida os dados do usuário antes da criação. Se houver erros, retornará um código de erro diferente de 200.

### 8.6 Criar Novo Usuário ⭐
**Endpoint**: `POST /api/v1/usuario/novousuario`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Request Body**:
```json
{
  "nome": "Nome do Usuário",
  "cpf": "52998224725",
  "celular": "41999887766",
  "email": "usuario@email.com",
  "confirmarEmail": "usuario@email.com",
  "grupoId": 1,
  "profissional_saude": {
    "tipoProfissionalId": "",
    "registroConselho": "",
    "ufConselho": "",
    "distritoOmd": null,
    "registroOmd": null
  },
  "nif": null,
  "senha": "Senha@123",
  "confirmarSenha": "Senha@123",
  "login": "usuario@email.com",
  "contaId": 62,
  "permissoesUsuarioConta": [
    { "permissaoId": 1, "ativo": true },
    { "permissaoId": 8, "ativo": true },
    { "permissaoId": 9, "ativo": true }
  ]
}
```

**Campos Obrigatórios**:
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `nome` | string | Nome completo do usuário |
| `cpf` | string | CPF (apenas números, 11 dígitos) |
| `celular` | string | Celular (apenas números, com DDD) |
| `email` | string | Email do usuário |
| `confirmarEmail` | string | Confirmação do email (deve ser igual) |
| `grupoId` | number | ID do grupo (1=Admin, 2=Profissional, 4=Secretária) |
| `senha` | string | Senha (mín 6 chars, letra maiúscula, número, caracter especial) |
| `confirmarSenha` | string | Confirmação da senha (deve ser igual) |
| `login` | string | Login do usuário (normalmente o email) |
| `contaId` | number | ID da conta/clínica |
| `permissoesUsuarioConta` | array | Lista de permissões do usuário |

**Campos Opcionais**:
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `profissional_saude` | object | Dados do profissional de saúde (se aplicável) |
| `nif` | string | NIF (para Portugal) |

**Requisitos da Senha**:
- Mínimo 6 caracteres
- Ao menos 1 caracter especial (!@#$%^&*)
- Ao menos 1 letra e 1 número
- Ao menos 1 letra maiúscula

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "usuario": {
      "idUsuario": 1770,
      "nomeUsuario": "Nome do Usuário",
      "contaId": 62,
      "email": "usuario@email.com",
      "celular": "41999887766",
      "ativo": true,
      "profissionalId": null,
      "grupo": {
        "id": 1,
        "nomeGrupo": "Administrador",
        "ativo": true
      },
      "permissoes": [
        {
          "permissaoId": 8,
          "permissaoNome": "Visualizar Agenda",
          "menuId": 8,
          "menuNome": null,
          "ativo": true
        }
      ],
      "loginFirst": false,
      "premium": false,
      "avaliacao": false,
      "dataValidade": "0001-01-01T00:00:00",
      "cpf": "52998224725"
    },
    "usuarioConta": [
      {
        "id": 0,
        "nomeConta": "Nome da Clínica",
        "nomeUsuario": "Nome do Usuário",
        "email": "usuario@email.com",
        "celular": "41999887766",
        "usuarioId": 1770,
        "contaId": 62,
        "premium": true,
        "avaliacao": false,
        "expirado": false,
        "dataValidade": null
      }
    ],
    "profissional": null,
    "emailsInformativosHabilitados": null
  }
}
```

**cURL de Exemplo**:
```bash
curl -X POST "https://clinix-cadastro.azurewebsites.net/api/v1/usuario/novousuario" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {seu_token}" \
  -d '{
    "nome": "Usuario Teste API",
    "cpf": "52998224725",
    "celular": "41999887766",
    "email": "teste.api@email.com",
    "confirmarEmail": "teste.api@email.com",
    "grupoId": 4,
    "profissional_saude": {
      "tipoProfissionalId": "",
      "registroConselho": "",
      "ufConselho": "",
      "distritoOmd": null,
      "registroOmd": null
    },
    "nif": null,
    "senha": "Senha@123",
    "confirmarSenha": "Senha@123",
    "login": "teste.api@email.com",
    "contaId": 62,
    "permissoesUsuarioConta": [
      {"permissaoId": 8, "ativo": true},
      {"permissaoId": 9, "ativo": true},
      {"permissaoId": 11, "ativo": true},
      {"permissaoId": 12, "ativo": true}
    ]
  }'
```

**Descrição**: Cria um novo usuário no sistema com suas permissões. O usuário receberá acesso ao sistema via email.

### 8.7 Atualizar Permissões do Usuário
**Endpoint**: `PATCH /api/v1/usuario`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Request Body**:
```json
{
  "id": 1770,
  "permissoesUsuarioConta": [
    { "permissaoId": 1, "ativo": true },
    { "permissaoId": 8, "ativo": true },
    { "permissaoId": 9, "ativo": true }
  ],
  "grupoId": 1
}
```

**Response (200 OK)**: Retorna o usuário atualizado (mesmo formato do POST)

**Descrição**: Atualiza as permissões e/ou grupo de um usuário existente.

### 8.8 Obter Usuário por ID
**Endpoint**: `GET /api/v1/usuario/id`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
- `id` (number): ID do usuário

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "usuario": {
      "idUsuario": 1770,
      "nomeUsuario": "Nome do Usuário",
      "contaId": 62,
      "email": "usuario@email.com",
      "celular": "41999887766",
      "ativo": true,
      "profissionalId": null,
      "grupo": {
        "id": 1,
        "nomeGrupo": "Administrador",
        "ativo": true
      },
      "permissoes": [...],
      "loginFirst": false,
      "premium": false,
      "avaliacao": false,
      "dataValidade": "0001-01-01T00:00:00",
      "cpf": "52998224725"
    },
    "usuarioConta": [...],
    "profissional": null,
    "emailsInformativosHabilitados": null
  }
}
```

**Descrição**: Retorna os detalhes completos de um usuário específico.

---

## 9. FINANCEIRO

### 9.1 Categorias Financeiras
**Endpoint**: `GET /api/v1/categoria`
**Base URL**: `https://clinix-financeiro.azurewebsites.net`

**Query Parameters**:
- `contaId` (number): ID da conta

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "nome": "Receitas",
      "tipo": "R",
      "contaId": 62,
      "subCategorias": [
        { "id": 10, "nome": "Consultas", "categoriaId": 1 },
        { "id": 11, "nome": "Procedimentos", "categoriaId": 1 },
        { "id": 12, "nome": "Outros", "categoriaId": 1 }
      ]
    },
    {
      "id": 2,
      "nome": "Despesas",
      "tipo": "D",
      "contaId": 62,
      "subCategorias": [
        { "id": 20, "nome": "Materiais", "categoriaId": 2 },
        { "id": 21, "nome": "Salários", "categoriaId": 2 },
        { "id": 22, "nome": "Aluguel", "categoriaId": 2 }
      ]
    }
  ]
}
```

### 9.2 Métodos de Pagamento
**Endpoint**: `GET /api/v1/metodopagamento`
**Base URL**: `https://clinix-financeiro.azurewebsites.net`

**Query Parameters**:
- `contaId` (number): ID da conta

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    { "id": 1, "nome": "Boleto", "ativo": true },
    { "id": 2, "nome": "Crédito", "ativo": true },
    { "id": 3, "nome": "Débito", "ativo": true },
    { "id": 4, "nome": "Dinheiro", "ativo": true },
    { "id": 5, "nome": "PIX", "ativo": true },
    { "id": 6, "nome": "Operadora", "ativo": true }
  ]
}
```

### 9.3 Contas Caixa
**Endpoint**: `GET /api/v1/contacaixa/clinica`
**Base URL**: `https://clinix-financeiro.azurewebsites.net`

**Query Parameters**:
- `clinicaId` (number): ID da clínica

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    {
      "id": 15,
      "nome": "Caixa Principal",
      "clinicaId": 57,
      "saldoInicial": 0,
      "ativo": true
    }
  ]
}
```

### 9.4 Extrato Financeiro
**Endpoint**: `POST /api/v1/extratofinanceiro`
**Base URL**: `https://clinix-financeiro.azurewebsites.net`

**Request Body**:
```json
{
  "clinicaId": 57,
  "contaId": 62,
  "dataInicio": "2025-11-01",
  "dataFim": "2025-11-27",
  "contaCaixaId": null,
  "categoriaId": null,
  "subCategoriaId": null,
  "metodoPagamentoId": null,
  "tipo": null,
  "pageNumber": 1,
  "pageSize": 50
}
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "pageNumber": 1,
    "pageSize": 50,
    "totalRecords": 25,
    "totalPages": 1,
    "saldoAnterior": 1500.00,
    "totalEntradas": 5000.00,
    "totalSaidas": 2000.00,
    "saldoFinal": 4500.00,
    "data": [
      {
        "id": 1234,
        "descricao": "Consulta - Paciente X",
        "valor": 250.00,
        "tipo": "R",
        "dataVencimento": "2025-11-15",
        "dataPagamento": "2025-11-15",
        "categoria": "Receitas",
        "subCategoria": "Consultas",
        "metodoPagamento": "PIX",
        "contaCaixa": "Caixa Principal",
        "pacienteId": 123,
        "pacienteNome": "Nome do Paciente"
      }
    ]
  }
}
```

---

## 10. AGENDA E CONSULTAS

### 10.1 Listar Profissionais da Clínica (para Agenda)
**Endpoint**: `GET /api/v1/profissionalclinica/idclinica`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
- `contaId` (number): ID da conta
- `clinicaId` (number): ID da clínica

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1674,
      "profissionalId": 1674,
      "nome": "Dr. Nome do Profissional",
      "especialidadeId": 13,
      "especialidade": { "nome": "Harmonizacao Orofacial" },
      "cadeiraId": 62,
      "clinicaId": 57,
      "ativo": true
    }
  ]
}
```

### 10.2 Obter Horário de Atendimento do Profissional ⭐ IMPORTANTE
**Endpoint**: `GET /api/v1/horarioatendimento`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `contaid` | number | Sim | ID da conta |
| `clinicaid` | number | Sim | ID da clínica |
| `profissionalId` | number | Sim | ID do profissional |

**Request**:
```
GET /api/v1/horarioatendimento?contaid=62&clinicaid=57&profissionalId=166
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    {
      "horarioAtendimentoId": 4774,
      "profissionalId": 166,
      "profissionalNome": "Alda Silva",
      "contaId": 62,
      "contaNome": "SORRISO DENTAL 2",
      "clinicaId": 57,
      "clinica": "Sorriso Dental",
      "segundaInicio": null,
      "segundaFim": null,
      "tercaInicio": null,
      "tercaFim": null,
      "qurtaInicio": null,
      "quartaFim": null,
      "quinInicio": null,
      "quintaFim": null,
      "sextaInicio": null,
      "sextaFim": null,
      "sabadoInicio": null,
      "sabadoFim": null,
      "domingoInicio": "08:00",
      "domingoFim": "20:00"
    },
    {
      "horarioAtendimentoId": 1615,
      "profissionalId": 166,
      "profissionalNome": "Alda Silva",
      "contaId": 62,
      "contaNome": "SORRISO DENTAL 2",
      "clinicaId": 57,
      "clinica": "Sorriso Dental",
      "segundaInicio": null,
      "segundaFim": null,
      "tercaInicio": null,
      "tercaFim": null,
      "qurtaInicio": null,
      "quartaFim": null,
      "quinInicio": null,
      "quintaFim": null,
      "sextaInicio": null,
      "sextaFim": null,
      "sabadoInicio": "08:00",
      "sabadoFim": "19:00",
      "domingoInicio": null,
      "domingoFim": null
    },
    {
      "horarioAtendimentoId": 1616,
      "profissionalId": 166,
      "profissionalNome": "Alda Silva",
      "contaId": 62,
      "contaNome": "SORRISO DENTAL 2",
      "clinicaId": 57,
      "clinica": "Sorriso Dental",
      "segundaInicio": "08:00",
      "segundaFim": "19:00",
      "tercaInicio": null,
      "tercaFim": null,
      "qurtaInicio": null,
      "quartaFim": null,
      "quinInicio": null,
      "quintaFim": null,
      "sextaInicio": null,
      "sextaFim": null,
      "sabadoInicio": null,
      "sabadoFim": null,
      "domingoInicio": null,
      "domingoFim": null
    }
  ]
}
```

**Estrutura de Horários**:
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `horarioAtendimentoId` | number | ID único do registro |
| `profissionalId` | number | ID do profissional |
| `segundaInicio` / `segundaFim` | string | Horário de segunda-feira (formato "HH:mm") |
| `tercaInicio` / `tercaFim` | string | Horário de terça-feira |
| `qurtaInicio` / `quartaFim` | string | Horário de quarta-feira (NOTA: typo "qurta" na API) |
| `quinInicio` / `quintaFim` | string | Horário de quinta-feira |
| `sextaInicio` / `sextaFim` | string | Horário de sexta-feira |
| `sabadoInicio` / `sabadoFim` | string | Horário de sábado |
| `domingoInicio` / `domingoFim` | string | Horário de domingo |

**Importante**:
- O retorno contém múltiplos registros, cada um representando um dia específico
- Valores `null` indicam que o profissional NÃO atende naquele dia
- Deve-se combinar todos os registros para montar a grade semanal completa
- A duração da consulta vem do campo `tempoConsulta` do profissional (endpoint `/profissional`)

### 10.3 Verificar Disponibilidade por Especialidade/Horário
**Endpoint**: `GET /api/v1/horarioatendimento/especialidade`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
- `horario` (string): Horário desejado (formato: "HH:mm")
- `tipo` (number): Tipo de busca (4 = por especialidade)
- `clinicaId` (number): ID da clínica
- `dataSelecionada` (string): Data desejada (formato: YYYY-MM-DD)

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    {
      "profissionalId": 1674,
      "profissionalNome": "Dr. Nome",
      "especialidadeId": 13,
      "disponivel": true,
      "horarioInicio": "09:00",
      "horarioFim": "09:30"
    }
  ]
}
```

### 10.4 Filtrar Agenda (Verificar Horários Ocupados)
**Endpoint**: `POST /api/v1/agenda/filtraragenda`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Request Body**:
```json
{
  "clinicaId": 57,
  "contaId": 62,
  "profissionalId": 1674,
  "dataInicio": "2025-11-28",
  "dataFim": "2025-11-28",
  "cadeiraId": null
}
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    {
      "id": 5678,
      "dataInicio": "2025-11-28T09:00:00",
      "dataFim": "2025-11-28T09:30:00",
      "profissionalId": 1674,
      "cadeiraId": 62,
      "statusConsultaId": 1
    }
  ]
}
```

### 10.5 Buscar Paciente (Autocomplete)
**Endpoint**: `POST /api/v1/paciente/autocompleteNome`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Request Body**:
```json
{
  "contaId": 62,
  "clinicaId": 57,
  "nome": "Abílio"
}
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    {
      "id": 46711,
      "nome": "Abílio Diniz",
      "cpf": "12345678901",
      "celular": "11941871233",
      "email": "paciente@email.com",
      "planoId": 77,
      "planoNome": "Particular"
    }
  ]
}
```

### 10.6 Listar Planos/Convênios
**Endpoint**: `GET /api/v1/plano`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
- `contaId` (number): ID da conta

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    {
      "id": 77,
      "nome": "Particular",
      "contaId": 62,
      "ativo": true
    },
    {
      "id": 78,
      "nome": "Unimed",
      "contaId": 62,
      "ativo": true
    }
  ]
}
```

### 10.7 Obter Detalhes do Profissional
**Endpoint**: `GET /api/v1/profissional/id`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
- `id` (number): ID do profissional

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "id": 1674,
    "nome": "Dr. Nome do Profissional",
    "cpf": "12345678901",
    "cro": "12345",
    "especialidadeId": 13,
    "especialidade": { "nome": "Harmonizacao Orofacial" },
    "tempoConsulta": 10,
    "cadeiraId": 62,
    "ativo": true
  }
}
```

### 10.8 CRIAR AGENDAMENTO (ENDPOINT PRINCIPAL)
**Endpoint**: `POST /api/v1/Consulta/gravaconsulta`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Request Body COMPLETO**:
```json
{
  "clinicaID": 57,
  "profissionalId": 1674,
  "cadeiraId": 62,
  "especialidadeId": 13,
  "pacienteId": 46711,
  "celularPaciente": "11941871233",
  "planoId": 77,
  "dataInicio": "2025-11-28T12:00:00.000Z",
  "hora_inicio": "09:00",
  "tempoConsulta": 10,
  "tipoAtendimentoPersonalizadoId": 807,
  "statusConsulta": 1,
  "retorno": false,
  "tipoRetorno": "1",
  "periodoRetorno": "1",
  "observacao": "Observações do agendamento",
  "origemRelacionamentoId": null,
  "origemRelacionamentoOutros": null,
  "dataFinal": "2025-11-28T12:10:00.000Z",
  "tituloConsulta": "Nome do Paciente",
  "contaId": 62,
  "painelLeadsId": null,
  "pacienteSimples": false,
  "usuario": "Nome do Usuário que está Agendando",
  "pacienteElegivel": null
}
```

**Campos Obrigatórios**:
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `clinicaID` | number | ID da clínica |
| `profissionalId` | number | ID do profissional |
| `cadeiraId` | number | ID da cadeira/consultório |
| `especialidadeId` | number | ID da especialidade |
| `pacienteId` | number | ID do paciente |
| `planoId` | number | ID do plano/convênio |
| `dataInicio` | string | Data/hora início (ISO 8601 UTC) |
| `dataFinal` | string | Data/hora fim (ISO 8601 UTC) |
| `hora_inicio` | string | Hora início formato "HH:mm" |
| `tempoConsulta` | number | Duração em minutos |
| `statusConsulta` | number | Status inicial (1 = Agendado) |
| `contaId` | number | ID da conta |
| `tituloConsulta` | string | Nome do paciente (exibido na agenda) |

**Campos Opcionais**:
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `celularPaciente` | string | Celular do paciente |
| `tipoAtendimentoPersonalizadoId` | number | ID do tipo de atendimento personalizado |
| `retorno` | boolean | Se é consulta de retorno |
| `tipoRetorno` | string | Tipo de retorno |
| `periodoRetorno` | string | Período de retorno |
| `observacao` | string | Observações |
| `origemRelacionamentoId` | number | ID da origem (Facebook, Google, etc) |
| `painelLeadsId` | number | ID do lead (se veio de campanha) |
| `pacienteSimples` | boolean | Cadastro simplificado |
| `usuario` | string | Nome do usuário que fez o agendamento |

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "id": 12345,
    "mensagem": "Consulta agendada com sucesso"
  }
}
```

### 10.9 Listar Consultas por Período
**Endpoint**: `POST /api/v1/Consulta/filtroagenda`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Request Body**:
```json
{
  "clinicaId": 57,
  "contaId": 62,
  "dataInicio": "2025-11-01",
  "dataFim": "2025-11-30",
  "profissionalId": null,
  "cadeiraId": null,
  "statusConsultaId": null
}
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    {
      "id": 12345,
      "pacienteId": 46711,
      "pacienteNome": "Abílio Diniz",
      "profissionalId": 1674,
      "profissionalNome": "Dr. Nome",
      "cadeiraId": 62,
      "cadeiraNome": "Cadeira 1",
      "dataInicio": "2025-11-28T09:00:00",
      "dataFim": "2025-11-28T09:10:00",
      "especialidadeId": 13,
      "especialidadeNome": "Harmonizacao Orofacial",
      "tipoAtendimentoId": 807,
      "statusConsultaId": 1,
      "statusConsulta": "Agendado",
      "planoId": 77,
      "planoNome": "Particular",
      "observacao": "Observações",
      "retorno": false
    }
  ]
}
```

### 10.10 REAGENDAR/EDITAR CONSULTA
**Endpoint**: `PATCH /api/v1/Consulta`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Request Body** (Reagendamento):
```json
{
  "id": "711720",
  "clinicaID": 57,
  "profissionalId": 1674,
  "cadeiraId": 62,
  "especialidadeId": 13,
  "pacienteId": 46711,
  "celularPaciente": "11941871233",
  "planoId": 77,
  "dataInicio": "2025-12-05T12:00:00.000Z",
  "hora_inicio": "09:00",
  "tempoConsulta": 10,
  "tipoAtendimentoPersonalizadoId": 807,
  "statusConsulta": 1,
  "retorno": false,
  "tipoRetorno": 1,
  "periodoRetorno": 1,
  "observacao": "observações",
  "origemRelacionamentoId": null,
  "origemRelacionamentoOutros": null,
  "dataFinal": "2025-12-05T12:10:00.000Z",
  "tituloConsulta": "Nome do Paciente"
}
```

**Campos Obrigatórios para PATCH**:
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | string | ID da consulta (consultaId) |
| `statusConsulta` | number | Novo status (ver tabela abaixo) |
| `dataInicio` | string | Nova data/hora início |
| `dataFinal` | string | Nova data/hora fim |

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "consultaId": 711720,
    "statusConsulta": 1,
    "dataInicio": "2025-12-05T09:00:00",
    "dataFinal": "2025-12-05T09:10:00"
  }
}
```

### 10.11 CANCELAR CONSULTA
**Endpoint**: `PATCH /api/v1/Consulta`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Request Body** (Cancelamento - apenas muda statusConsulta para 8):
```json
{
  "id": "711720",
  "clinicaID": 57,
  "profissionalId": 1674,
  "cadeiraId": 62,
  "especialidadeId": 13,
  "pacienteId": 46711,
  "celularPaciente": "11941871233",
  "planoId": 77,
  "dataInicio": "2025-12-05T12:00:00.000Z",
  "hora_inicio": "09:00",
  "tempoConsulta": 10,
  "tipoAtendimentoPersonalizadoId": 807,
  "statusConsulta": 8,
  "retorno": false,
  "tipoRetorno": 1,
  "periodoRetorno": 1,
  "observacao": "observações",
  "origemRelacionamentoId": null,
  "origemRelacionamentoOutros": null,
  "dataFinal": "2025-12-05T12:10:00.000Z",
  "tituloConsulta": "Nome do Paciente"
}
```

**Para Cancelar**: Basta enviar o mesmo body mas com `"statusConsulta": 8`

### 10.12 Obter Consulta por ID
**Endpoint**: `GET /api/v1/Consulta/id`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
- `id` (number): ID da consulta

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "consultaId": 711720,
    "pacienteId": 46711,
    "tituloConsulta": "Nome do Paciente",
    "profissionalId": 1674,
    "clinicaID": 57,
    "dataInicio": "2025-12-05T09:00:00",
    "dataFinal": "2025-12-05T09:10:00",
    "statusConsulta": 1,
    "planoId": 77,
    "tempoConsulta": 10,
    "observacao": "observações"
  }
}
```

### Resumo: Operações de Consulta

| Operação | Método | Endpoint | statusConsulta |
|----------|--------|----------|----------------|
| **Criar** | POST | `/Consulta/gravaconsulta` | 1 (Agendado) |
| **Reagendar** | PATCH | `/Consulta` | 1 (Agendado) + nova data |
| **Cancelar** | PATCH | `/Consulta` | 8 (Cancelado) |
| **Confirmar** | PATCH | `/Consulta` | 11 (Confirmado) |
| **Marcar Falta** | PATCH | `/Consulta` | 5 (Faltou) |
| **Obter** | GET | `/Consulta/id?id={id}` | - |
| **Listar** | POST | `/Consulta/filtroagenda` | - |

---

## Observações para Integração n8n

### Autenticação
1. Fazer POST para `/api/v1/entrar` com credenciais
2. Extrair o `token` da resposta
3. Usar o token em todas as requisições subsequentes no header `Authorization: Bearer {token}`

### IDs Importantes
- `idConta`: Identificador da conta/empresa
- `idUsuario`: Identificador do usuário logado
- `clinicaId`: Identificador da clínica específica
- `contaId`: Mesmo que idConta em alguns contextos

### Token JWT
- O token tem validade limitada (verificar campo `exp` no JWT)
- Algoritmo: PS256
- Audiences: clinix-cadastro, clinix-financeiro, clinix-api

---

## Exemplos Práticos para n8n

### Fluxo de Autenticação
```
1. HTTP Request Node (POST)
   URL: https://clinix-autenticacao.azurewebsites.net/api/v1/entrar
   Body: { "login": "{{$credentials.email}}", "password": "{{$credentials.password}}" }

2. Set Node
   token = {{$json.data.token}}
   idConta = {{$json.data.user.idConta}}
   idUsuario = {{$json.data.user.idUsuario}}
```

### Buscar Pacientes com Filtro
```
HTTP Request Node (GET)
URL: https://clinix-cadastro.azurewebsites.net/api/v1/pacientefiltro
Query Parameters:
  - clinicaId: {{$node.auth.json.clinicaId}}
  - contaId: {{$node.auth.json.idConta}}
  - pageNumber: 1
  - pageSize: 100
Headers:
  - Authorization: Bearer {{$node.auth.json.token}}
```

### Criar Agendamento Completo (Workflow Recomendado)

**Passo 1 - Buscar Profissionais Disponíveis**:
```
HTTP Request Node (GET)
URL: https://clinix-cadastro.azurewebsites.net/api/v1/profissionalclinica/idclinica
Query Parameters:
  - contaId: {{$node.auth.json.idConta}}
  - clinicaId: {{$node.clinica.json.clinicaId}}
Headers:
  - Authorization: Bearer {{$node.auth.json.token}}
```

**Passo 2 - Verificar Horários do Profissional**:
```
HTTP Request Node (GET)
URL: https://clinix-cadastro.azurewebsites.net/api/v1/horarioatendimento
Query Parameters:
  - contaid: {{$node.auth.json.idConta}}
  - clinicaid: {{$node.clinica.json.clinicaId}}
  - profissionalId: {{$node.profissionais.json.data[0].profissionalId}}
Headers:
  - Authorization: Bearer {{$node.auth.json.token}}
```

**Passo 3 - Buscar Paciente por Nome**:
```
HTTP Request Node (POST)
URL: https://clinix-cadastro.azurewebsites.net/api/v1/paciente/autocompleteNome
Headers:
  - Authorization: Bearer {{$node.auth.json.token}}
  - Content-Type: application/json
Body:
{
  "contaId": {{$node.auth.json.idConta}},
  "clinicaId": {{$node.clinica.json.clinicaId}},
  "nome": "{{$json.nomePaciente}}"
}
```

**Passo 4 - Verificar Agenda (Horários Ocupados)**:
```
HTTP Request Node (POST)
URL: https://clinix-cadastro.azurewebsites.net/api/v1/agenda/filtraragenda
Headers:
  - Authorization: Bearer {{$node.auth.json.token}}
  - Content-Type: application/json
Body:
{
  "clinicaId": {{$node.clinica.json.clinicaId}},
  "contaId": {{$node.auth.json.idConta}},
  "profissionalId": {{$node.profissional.json.id}},
  "dataInicio": "{{$json.data}}",
  "dataFim": "{{$json.data}}",
  "cadeiraId": null
}
```

**Passo 5 - CRIAR AGENDAMENTO**:
```
HTTP Request Node (POST)
URL: https://clinix-cadastro.azurewebsites.net/api/v1/Consulta/gravaconsulta
Headers:
  - Authorization: Bearer {{$node.auth.json.token}}
  - Content-Type: application/json
Body:
{
  "clinicaID": {{$node.clinica.json.clinicaId}},
  "profissionalId": {{$node.profissional.json.id}},
  "cadeiraId": {{$node.profissional.json.cadeiraId}},
  "especialidadeId": {{$node.profissional.json.especialidadeId}},
  "pacienteId": {{$node.paciente.json.id}},
  "celularPaciente": "{{$node.paciente.json.celular}}",
  "planoId": {{$node.paciente.json.planoId}},
  "dataInicio": "{{$json.dataHoraInicio}}",
  "hora_inicio": "{{$json.horaInicio}}",
  "tempoConsulta": {{$node.profissional.json.tempoConsulta || 30}},
  "tipoAtendimentoPersonalizadoId": 807,
  "statusConsulta": 1,
  "retorno": false,
  "tipoRetorno": "1",
  "periodoRetorno": "1",
  "observacao": "{{$json.observacao || ''}}",
  "origemRelacionamentoId": null,
  "origemRelacionamentoOutros": null,
  "dataFinal": "{{$json.dataHoraFim}}",
  "tituloConsulta": "{{$node.paciente.json.nome}}",
  "contaId": {{$node.auth.json.idConta}},
  "painelLeadsId": null,
  "pacienteSimples": false,
  "usuario": "{{$node.auth.json.nomeUsuario}}",
  "pacienteElegivel": null
}
```

### Criar Agendamento (Versão Simplificada)
```
HTTP Request Node (POST)
URL: https://clinix-cadastro.azurewebsites.net/api/v1/Consulta/gravaconsulta
Headers:
  - Authorization: Bearer {{$node.auth.json.token}}
  - Content-Type: application/json
Body (campos mínimos obrigatórios):
{
  "clinicaID": {{$node.clinica.json.clinicaId}},
  "profissionalId": {{$json.profissionalId}},
  "cadeiraId": {{$json.cadeiraId}},
  "especialidadeId": {{$json.especialidadeId}},
  "pacienteId": {{$json.pacienteId}},
  "planoId": {{$json.planoId}},
  "dataInicio": "{{$json.dataHoraInicio}}",
  "dataFinal": "{{$json.dataHoraFim}}",
  "hora_inicio": "{{$json.horaInicio}}",
  "tempoConsulta": {{$json.tempoConsulta}},
  "statusConsulta": 1,
  "contaId": {{$node.auth.json.idConta}},
  "tituloConsulta": "{{$json.nomePaciente}}"
}
```

### Consultar Extrato Financeiro
```
HTTP Request Node (POST)
URL: https://clinix-financeiro.azurewebsites.net/api/v1/extratofinanceiro
Headers:
  - Authorization: Bearer {{$node.auth.json.token}}
Body:
{
  "clinicaId": {{$node.clinica.json.clinicaId}},
  "contaId": {{$node.auth.json.idConta}},
  "dataInicio": "{{$today.minus({days: 30}).format('yyyy-MM-dd')}}",
  "dataFim": "{{$today.format('yyyy-MM-dd')}}",
  "pageNumber": 1,
  "pageSize": 100
}
```

---

## 14. TIPOS DE PROFISSIONAL E REGIÕES

### 14.1 Listar Tipos de Profissional
**Endpoint**: `GET /api/v1/tipoprofissional`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    {
      "nome": "Dentista",
      "especialidades": [
        { "nome": "Cirurgia e Traumatologia - Maxilo - Facial", "tipoProfissionalId": 1, "id": 1, "ativo": true },
        { "nome": "Odontopediatria", "tipoProfissionalId": 1, "id": 2, "ativo": true },
        { "nome": "Endodontia", "tipoProfissionalId": 1, "id": 3, "ativo": true },
        { "nome": "Periodontia", "tipoProfissionalId": 1, "id": 4, "ativo": true },
        { "nome": "Odontogeriatria", "tipoProfissionalId": 1, "id": 5, "ativo": true },
        { "nome": "Implantodontia", "tipoProfissionalId": 1, "id": 6, "ativo": true },
        { "nome": "Ortodontia", "tipoProfissionalId": 1, "id": 7, "ativo": true },
        { "nome": "Dentistica", "tipoProfissionalId": 1, "id": 8, "ativo": true },
        { "nome": "Radiologia Odontologica e Imaginologia", "tipoProfissionalId": 1, "id": 9, "ativo": true },
        { "nome": "Protese Dentaria", "tipoProfissionalId": 1, "id": 10, "ativo": true },
        { "nome": "Harmonizacao Orofacial", "tipoProfissionalId": 1, "id": 11, "ativo": true },
        { "nome": "Avaliação", "tipoProfissionalId": 1, "id": 12, "ativo": true },
        { "nome": "Clinico Geral", "tipoProfissionalId": 1, "id": 13, "ativo": true }
      ],
      "id": 1,
      "dataCadastro": "2021-06-24T20:24:18.677",
      "ativo": true
    },
    {
      "nome": "Esteticista",
      "especialidades": [],
      "id": 2,
      "dataCadastro": "2021-06-24T20:24:18.677",
      "ativo": true
    },
    {
      "nome": "Fonoaudiólogo",
      "especialidades": [],
      "id": 3,
      "ativo": true
    },
    {
      "nome": "Psicólogo",
      "especialidades": [],
      "id": 4,
      "ativo": true
    },
    {
      "nome": "Nutricionista",
      "especialidades": [],
      "id": 5,
      "ativo": true
    },
    {
      "nome": "Outro",
      "especialidades": [],
      "id": 6,
      "ativo": true
    }
  ]
}
```

**Campos Importantes**:
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | number | ID do tipo de profissional |
| `nome` | string | Nome do tipo (Dentista, Esteticista, etc.) |
| `especialidades` | array | Lista de especialidades associadas a esse tipo |
| `especialidades[].id` | number | ID da especialidade |
| `especialidades[].tipoProfissionalId` | number | Referência ao tipo de profissional |

**Uso**: Listagem de tipos de profissionais disponíveis no sistema e suas especialidades.

---

### 14.2 Listar Regiões de Tratamento
**Endpoint**: `GET /api/v1/regiao`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `tipoProfissionalId` | number | Sim | ID do tipo de profissional (ex: 1 = Dentista) |

**Request**:
```
GET /api/v1/regiao?tipoProfissionalId=1
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    { "nome": "Dente", "id": 1, "ativo": true },
    { "nome": "Dente e Face", "id": 2, "ativo": true },
    { "nome": "Sextante", "id": 3, "ativo": true },
    { "nome": "Hemi-arcada", "id": 4, "ativo": true },
    { "nome": "Arcada", "id": 5, "ativo": true },
    { "nome": "Boca", "id": 6, "ativo": true },
    { "nome": "Lingua", "id": 7, "ativo": true },
    { "nome": "Mucosa", "id": 8, "ativo": true },
    { "nome": "Labio", "id": 9, "ativo": true },
    { "nome": "Sessão", "id": 10, "ativo": true }
  ]
}
```

**Descrição**: Regiões anatômicas onde procedimentos podem ser aplicados. Usado em procedimentos/tratamentos para especificar a área de aplicação.

---

## 15. TABELA DE PREÇOS E PROCEDIMENTOS

### 15.1 Listar Tabelas de Preço
**Endpoint**: `GET /api/v1/tabelapreco/tabelapreco`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `contaId` | number | Sim | ID da conta |
| `planoId` | number | Não | ID do plano (filtrar por plano específico) |
| `todos` | boolean | Não | `true` = todos, `false` = apenas ativos |

**Request**:
```
GET /api/v1/tabelapreco/tabelapreco?contaId=62&planoId=77&todos=true
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "pageNumber": 1,
    "pageSize": 50,
    "totalRecords": 1,
    "totalPages": 1,
    "data": [
      {
        "tabelaPrecoId": 217,
        "nome": "Tabela de Preço Bradesco",
        "codigoTabela": "",
        "dataCriacao": "2024-04-30T08:00:06.1786116",
        "ativo": true
      }
    ]
  }
}
```

**Campos Importantes**:
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `tabelaPrecoId` | number | ID da tabela de preço |
| `nome` | string | Nome da tabela |
| `codigoTabela` | string | Código identificador da tabela |
| `ativo` | boolean | Se a tabela está ativa |

---

### 15.2 Listar Procedimentos por Especialidade (Paginado) ⭐ IMPORTANTE
**Endpoint**: `GET /api/v1/tabelapreco/procedimentoespecialidade/paginado`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `contaId` | number | Sim | ID da conta |
| `tabelaPrecoId` | number | Sim | ID da tabela de preço |
| `especialidadeId` | number | Não | Filtrar por especialidade |
| `pageNumber` | number | Não | Número da página (default: 1) |
| `pageSize` | number | Não | Itens por página (default: 50) |
| `orderByProperty` | string | Não | Campo para ordenação |
| `orderByDesc` | boolean | Não | Ordenação descendente |

**Request**:
```
GET /api/v1/tabelapreco/procedimentoespecialidade/paginado?contaId=62&tabelaPrecoId=217&pageNumber=1&pageSize=50
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "pageNumber": 1,
    "pageSize": 50,
    "totalRecords": 150,
    "totalPages": 3,
    "data": [
      {
        "id": 12345,
        "procedimentoId": 1001,
        "procedimento": {
          "id": 1001,
          "codigo": "81000065",
          "nome": "Aplicação de cariostático",
          "especialidadeId": 8,
          "especialidade": { "nome": "Dentistica", "id": 8 },
          "regiaoId": 1,
          "regiao": { "nome": "Dente", "id": 1 },
          "ativo": true
        },
        "tabelaPrecoId": 217,
        "valor": 45.00,
        "valorCusto": 15.00,
        "ativo": true
      },
      {
        "id": 12346,
        "procedimentoId": 1002,
        "procedimento": {
          "id": 1002,
          "codigo": "81000111",
          "nome": "Aplicação de selante",
          "especialidadeId": 8,
          "especialidade": { "nome": "Dentistica", "id": 8 },
          "regiaoId": 1,
          "regiao": { "nome": "Dente", "id": 1 },
          "ativo": true
        },
        "tabelaPrecoId": 217,
        "valor": 65.00,
        "valorCusto": 20.00,
        "ativo": true
      }
    ]
  }
}
```

**Campos Importantes**:
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | number | ID do registro procedimento-tabela |
| `procedimentoId` | number | ID do procedimento |
| `procedimento.codigo` | string | Código TUSS/interno do procedimento |
| `procedimento.nome` | string | Nome do procedimento |
| `procedimento.especialidadeId` | number | Especialidade associada |
| `procedimento.regiaoId` | number | Região anatômica de aplicação |
| `tabelaPrecoId` | number | ID da tabela de preço |
| `valor` | number | Preço de venda |
| `valorCusto` | number | Custo do procedimento |

**Nota Importante**: A **duração do procedimento** NÃO está neste endpoint. A duração da consulta vem do campo `tempoConsulta` do profissional (endpoint `/profissional`).

---

### 15.3 Obter Dados do Profissional por Clínica
**Endpoint**: `GET /api/v1/profissionalclinica/idprofissional`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `id` | number | Sim | ID do profissional |
| `contaId` | number | Sim | ID da conta |

**Request**:
```
GET /api/v1/profissionalclinica/idprofissional?id=166&contaId=62
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "profissional": {
      "id": 166,
      "nome": "Alda Silva",
      "cpf": "55156764088",
      "email": "charles.almeida@clinix.app.br",
      "celular": "16994645653",
      "tipoProfissionalId": 1,
      "registroConselho": "123www",
      "ufConselho": "AL",
      "tempoConsulta": 20,
      "avatarUrl": "https://ui-avatars.com/api/?background=c200ce",
      "avatarCor": "#c200ce",
      "permiteEncaixe": true,
      "contaId": 62,
      "ativo": true
    },
    "clinicas": [
      {
        "id": 57,
        "nome": "Sorriso Dental",
        "fusoHorario": "PR",
        "cidade": "Curitiba",
        "estado": "PR",
        "ativo": true
      }
    ]
  }
}
```

**Descrição**: Retorna os dados completos do profissional junto com as clínicas onde ele atende. Útil para obter informações detalhadas de um profissional específico.

---

### 15.4 Listar Especialidades da Tabela de Preço por Plano ⭐ NOVO
**Endpoint**: `GET /api/v1/tabelapreco/especialidadestabelapreco`
**Base URL**: `https://clinix-financeiro.azurewebsites.net`

**Query Parameters**:
| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `planoId` | number | Sim | ID do plano |
| `todos` | boolean | Não | `true` = todos, `false` = apenas ativos |

**Request**:
```
GET /api/v1/tabelapreco/especialidadestabelapreco?planoId=154&todos=true
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "tabelaPrecoId": 257,
    "especialidades": [
      {
        "nome": "Corporal",
        "tipoProfissionalId": 15,
        "id": 22,
        "ativo": true
      },
      {
        "nome": "Harmonização Orofacial",
        "tipoProfissionalId": 15,
        "id": 23,
        "ativo": true
      }
    ]
  }
}
```

**Descrição**: Retorna as especialidades disponíveis na tabela de preço de um plano específico, junto com o `tabelaPrecoId` necessário para consultar os procedimentos.

---

### 15.5 Listar Procedimentos por Especialidade e Tabela de Preço (Paginado) ⭐ NOVO
**Endpoint**: `GET /api/v1/tabelapreco/tabelaprecoespecialidade/paginado`
**Base URL**: `https://clinix-financeiro.azurewebsites.net`

**Query Parameters**:
| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `especialidadeId` | number | Sim | ID da especialidade |
| `tabelaPrecoId` | number | Sim | ID da tabela de preço |
| `pag` | number | Não | Número da página (default: 1) |
| `qtdPag` | number | Não | Itens por página (default: 10) |

**Request**:
```
GET /api/v1/tabelapreco/tabelaprecoespecialidade/paginado?especialidadeId=22&tabelaPrecoId=257&pag=1&qtdPag=100
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    {
      "tabelaPrecoId": 257,
      "procedimentoId": 1783,
      "procedimentoContaId": 16344,
      "valorTratamento": 100,
      "valorFranquia": 0,
      "calculoFranquia": 0,
      "calculoTratamento": 100,
      "valorTotal": 0,
      "taxaAliquota": 0.0,
      "tabelaPreco": {
        "nome": "Tabela ESTÉTICA NOVOS PROCEDIMENTOS",
        "contaId": 62,
        "planoId": 154,
        "padrao": false,
        "valorUS": 1,
        "id": 257,
        "ativo": true
      },
      "procedimentos": {
        "tuss": null,
        "codigo": null,
        "nome": "BIOESTIMULADOR DE COLAGENO - ELLEVA X",
        "especialidadeId": 22,
        "regiaoId": 11,
        "id": 16344,
        "ativo": true
      },
      "procedimentoConta": {
        "nome": "BIOESTIMULADOR DE COLAGENO - ELLEVA X",
        "especialidadeId": 22,
        "contaId": 62,
        "recorrente": false,
        "id": 16344,
        "ativo": true
      },
      "id": 62947,
      "ativo": true
    }
  ]
}
```

**Campos Importantes**:
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `procedimentoId` | number | ID global do procedimento |
| `procedimentoContaId` | number | ID do procedimento na conta |
| `procedimentos.nome` | string | Nome do procedimento |
| `procedimentos.codigo` | string | Código TUSS (se houver) |
| `valorTratamento` | number | Valor do procedimento em US |
| `calculoTratamento` | number | Valor calculado em R$ |
| `tabelaPreco.valorUS` | number | Conversão US→R$ |

**Descrição**: Endpoint detalhado para listar procedimentos de uma especialidade específica dentro de uma tabela de preço. Usado na tela de remuneração do profissional.

---

### 15.6 Detalhes de Remuneração do Profissional por Plano ⭐ NOVO
**Endpoint**: `POST /api/v1/detalhesprofissional/getAll`
**Base URL**: `https://clinix-financeiro.azurewebsites.net`

**Request Body**:
```json
{
  "profissionalId": 166,
  "planoId": 154
}
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "listaDetalhesProfissional": [
      {
        "profissionalId": 166,
        "planoId": 154,
        "tipoComissaoId": 1,
        "tipoRemuneracaoId": 1,
        "formaCRemuneracao": 0,
        "formaCComissao": 0,
        "tipoComissao": {
          "nome": "Sem Comissão",
          "id": 1
        },
        "tipoRemuneracao": {
          "nome": "Sem Remuneração",
          "id": 1
        },
        "especialidadeId": 22,
        "especialidade": {
          "nome": "Corporal",
          "tipoProfissionalId": 15,
          "id": 22,
          "ativo": true
        },
        "id": 515,
        "ativo": true
      }
    ]
  }
}
```

**Descrição**: Retorna os detalhes de remuneração e comissão de um profissional para um plano específico, separado por especialidade.

---

### 15.7 Remunerações de Procedimentos por Profissional/Plano ⭐ NOVO
**Endpoint**: `GET /api/v1/remuneracaoprofissional/profissionalplano`
**Base URL**: `https://clinix-financeiro.azurewebsites.net`

**Query Parameters**:
| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `profissionalId` | number | Sim | ID do profissional |
| `planoId` | number | Sim | ID do plano |

**Request**:
```
GET /api/v1/remuneracaoprofissional/profissionalplano?profissionalId=166&planoId=154
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    {
      "id": 240434,
      "planoId": 154,
      "profissionalId": 166,
      "tabelaPrecoItemId": 62949,
      "pctRemuneracao": null,
      "pctComissao": null,
      "valorRemuneracao": 0,
      "valorComissao": 0,
      "saldoFinal": 0,
      "ativo": true,
      "dataRemuneracao": "2023-04-13T12:25:45.920375",
      "plano": {
        "nome": "ESTÉTICA NOVOS PROCEDIMENTOS",
        "id": 154
      },
      "profissional": {
        "nome": "Alda Silva",
        "id": 166
      },
      "tabelaPrecoItem": {
        "tabelaPrecoId": 257,
        "procedimentoId": 1781,
        "valorTratamento": 102,
        "id": 62949
      }
    }
  ]
}
```

**Descrição**: Lista os valores de remuneração/comissão específicos de cada procedimento para um profissional em um plano. Permite configurar valores diferentes por procedimento.

---

### 15.8 Fluxo Completo: Obter Procedimentos por Profissional ⭐ IMPORTANTE

**Não existe um endpoint único** que liste todos os procedimentos de todos os profissionais. A estrutura é hierárquica:

```
Profissional → Planos (vinculados) → Tabela de Preço → Especialidades → Procedimentos
```

**Fluxo para Obter Procedimentos de um Profissional:**

```javascript
// 1. Listar os planos vinculados ao profissional
GET /api/v1/detalhesprofissional/profissional?profissionalId={id}
// Retorna os planos onde o profissional atua

// 2. Para cada plano, obter o tabelaPrecoId e especialidades
GET /api/v1/tabelapreco/especialidadestabelapreco?planoId={planoId}&todos=true
// Retorna tabelaPrecoId e lista de especialidades

// 3. Para cada especialidade, listar os procedimentos
GET /api/v1/tabelapreco/tabelaprecoespecialidade/paginado?especialidadeId={espId}&tabelaPrecoId={tpId}&pag=1&qtdPag=100
// Retorna os procedimentos com valores
```

**Exemplo Prático (JavaScript/n8n):**
```javascript
// Buscar procedimentos do profissional 166
const profissionalId = 166;

// 1. Buscar planos do profissional
const planosResp = await fetch(
  `https://clinix-financeiro.azurewebsites.net/api/v1/detalhesprofissional/profissional?profissionalId=${profissionalId}`,
  { headers: { Authorization: `Bearer ${token}` } }
);
const planos = await planosResp.json();

// 2. Para cada plano, buscar especialidades
for (const detalhe of planos.data) {
  const planoId = detalhe.planoId;

  const espResp = await fetch(
    `https://clinix-financeiro.azurewebsites.net/api/v1/tabelapreco/especialidadestabelapreco?planoId=${planoId}&todos=true`,
    { headers: { Authorization: `Bearer ${token}` } }
  );
  const espData = await espResp.json();
  const tabelaPrecoId = espData.data.tabelaPrecoId;

  // 3. Para cada especialidade, buscar procedimentos
  for (const esp of espData.data.especialidades) {
    const procResp = await fetch(
      `https://clinix-financeiro.azurewebsites.net/api/v1/tabelapreco/tabelaprecoespecialidade/paginado?especialidadeId=${esp.id}&tabelaPrecoId=${tabelaPrecoId}&pag=1&qtdPag=100`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    const procedimentos = await procResp.json();

    console.log(`Especialidade: ${esp.nome}`);
    for (const proc of procedimentos.data) {
      console.log(`- ${proc.procedimentos.nome}: R$ ${proc.calculoTratamento}`);
    }
  }
}
```

---

### 15.9 Listar Todos os Planos da Conta ⭐ NOVO
**Endpoint**: `GET /api/v1/plano`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `contaId` | number | Sim | ID da conta |
| `todos` | boolean | Não | Se true, retorna todos (ativos e inativos) |

**Request**:
```
GET /api/v1/plano?contaId=62&todos=true
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    {
      "nome": "ESTÉTICA NOVOS PROCEDIMENTOS",
      "contaId": 62,
      "tipoProfissionalId": 15,
      "padrao": false,
      "fontePagadora": 1,
      "tipoProfissional": {
        "nome": "Estética Facial",
        "id": 15
      },
      "id": 154,
      "dataCadastro": "2023-01-05T17:57:49",
      "ativo": true
    },
    {
      "nome": "Plano Particular",
      "contaId": 62,
      "tipoProfissionalId": 1,
      "padrao": true,
      "fontePagadora": 1,
      "tipoProfissional": {
        "nome": "Dentista",
        "id": 1
      },
      "id": 77,
      "dataCadastro": "2022-04-27T17:22:10",
      "ativo": true
    }
  ]
}
```

**Descrição**: Lista todos os planos cadastrados na conta. Cada plano possui um `tipoProfissionalId` que indica qual tipo de profissional pode usar esse plano. Útil para sincronização inicial.

---

### 15.10 Detalhes de um Plano Específico ⭐ NOVO
**Endpoint**: `GET /api/v1/plano/id`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `id` | number | Sim | ID do plano |

**Request**:
```
GET /api/v1/plano/id?id=154
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "nome": "ESTÉTICA NOVOS PROCEDIMENTOS",
    "contaId": 62,
    "planoReplicaId": null,
    "tipoProfissionalId": 15,
    "padrao": false,
    "fontePagadora": 1,
    "possuiFranquia": false,
    "integracaoId": null,
    "tipoProfissional": {
      "nome": "Estética Facial",
      "id": 15
    },
    "id": 154,
    "dataCadastro": "2023-01-05T17:57:49.045473",
    "ativo": true
  }
}
```

**Descrição**: Retorna os detalhes completos de um plano específico pelo ID.

---

### 15.11 Listar Procedimentos de uma Especialidade no Plano ⭐ NOVO

> ⚠️ **Corrigido em 2025-12-03**: Endpoint era `procedimentoespecialidade` (singular), não `procedimentosespecialidade` (com 's'). A versão anterior retornava 404.

**Endpoint**: `GET /api/v1/tabelapreco/procedimentoespecialidade`
**Base URL**: `https://clinix-financeiro.azurewebsites.net`

**Query Parameters**:
| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `tabelaPrecoId` | number | Sim | ID da tabela de preços do plano |
| `especialidadeId` | number | Sim | ID da especialidade |
| `ativos` | boolean | Não | Filtrar apenas ativos |

**Request**:
```
GET /api/v1/tabelapreco/procedimentoespecialidade?tabelaPrecoId=257&especialidadeId=22&ativos=true
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    {
      "id": 62949,
      "tabelaPrecoId": 257,
      "procedimentoId": 1781,
      "especialidadeId": 22,
      "regiaoId": 14,
      "valorTratamento": 100.00,
      "valorUS": 1,
      "codigo": null,
      "tuss": null,
      "recorrente": false,
      "procedimentos": {
        "nome": "BIOESTIMULADOR DE COLAGENO - ELLEVA X",
        "id": 1781,
        "ativo": true
      },
      "especialidade": {
        "nome": "Corporal",
        "tipoProfissionalId": 15,
        "id": 22
      },
      "regiao": {
        "nome": "Face",
        "id": 14
      },
      "ativo": true
    },
    {
      "id": 62950,
      "tabelaPrecoId": 257,
      "procedimentoId": 1782,
      "especialidadeId": 22,
      "regiaoId": 14,
      "valorTratamento": 110.00,
      "procedimentos": {
        "nome": "BIOESTIMULADOR DE COLAGENO - PERFECT GLUTEO",
        "id": 1782
      },
      "especialidade": {
        "nome": "Corporal",
        "id": 22
      },
      "ativo": true
    }
  ]
}
```

**Descrição**: Lista todos os procedimentos de uma especialidade dentro de um plano (via tabela de preço). Retorna nome, valor, código TUSS e outras informações do procedimento.

---

### 15.12 Fluxo Recomendado: Mapear Procedimentos ↔ Profissionais ⭐ IMPORTANTE

**Problema**: Não existe endpoint direto "Procedimento → Profissionais que fazem".

**Solução**: A relação é feita através do `tipoProfissionalId`:
- Procedimentos estão em Planos
- Planos têm um `tipoProfissionalId` (Dentista=1, Estética=15, etc.)
- Profissionais têm um `tipoProfissionalId`

**Fluxo de Sync Inicial (JavaScript/n8n)**:
```javascript
// =====================================================
// SYNC INICIAL - Mapear Procedimentos e Profissionais
// =====================================================

const BASE_CADASTRO = 'https://clinix-cadastro.azurewebsites.net';
const BASE_FINANCEIRO = 'https://clinix-financeiro.azurewebsites.net';
const headers = { Authorization: `Bearer ${token}` };

// 1. LISTAR TODOS OS PLANOS
const planosResp = await fetch(
  `${BASE_CADASTRO}/api/v1/plano?contaId=${contaId}&todos=true`,
  { headers }
);
const planos = (await planosResp.json()).data;

// 2. PARA CADA PLANO, OBTER ESPECIALIDADES E PROCEDIMENTOS
const procedimentosMap = [];

for (const plano of planos) {
  // Obter especialidades do plano
  const espResp = await fetch(
    `${BASE_FINANCEIRO}/api/v1/tabelapreco/especialidadestabelapreco?planoId=${plano.id}&todos=true`,
    { headers }
  );
  const espData = (await espResp.json()).data;
  const tabelaPrecoId = espData.tabelaPrecoId;

  // Para cada especialidade, obter procedimentos
  for (const esp of espData.especialidades) {
    const procResp = await fetch(
      `${BASE_FINANCEIRO}/api/v1/tabelapreco/tabelaprecoespecialidade/paginado?especialidadeId=${esp.id}&tabelaPrecoId=${tabelaPrecoId}&pag=1&qtdPag=100`,
      { headers }
    );
    const procedimentos = (await procResp.json()).data;

    for (const proc of procedimentos) {
      procedimentosMap.push({
        procedimentoId: proc.procedimentos.id,
        nome: proc.procedimentos.nome,
        valor: proc.calculoTratamento,
        especialidadeId: esp.id,
        especialidadeNome: esp.nome,
        planoId: plano.id,
        planoNome: plano.nome,
        tipoProfissionalId: plano.tipoProfissionalId  // CHAVE PARA RELACIONAR!
      });
    }
  }
}

// 3. LISTAR PROFISSIONAIS
const profResp = await fetch(
  `${BASE_CADASTRO}/api/v1/profissionalclinica/idclinica?contaId=${contaId}&clinicaId=${clinicaId}`,
  { headers }
);
const profissionais = (await profResp.json()).data.profissionais.map(p => ({
  id: p.profissional.id,
  nome: p.profissional.nome,
  tipoProfissionalId: p.profissional.tipoProfissionalId,
  tempoConsulta: p.profissional.tempoConsulta
}));

// 4. RESULTADO FINAL - Salvar no banco de dados local
const syncData = {
  procedimentos: procedimentosMap,
  profissionais: profissionais,
  syncDate: new Date().toISOString()
};

console.log(`Sync completo: ${procedimentosMap.length} procedimentos, ${profissionais.length} profissionais`);
```

**Uso na IA do WhatsApp**:
```javascript
// =====================================================
// FLUXO IA - Buscar Profissionais para um Procedimento
// =====================================================

function buscarProfissionaisParaProcedimento(nomeProcedimento, procedimentos, profissionais) {
  // 1. Buscar procedimento (pode usar fuzzy search)
  const procedimento = procedimentos.find(p =>
    p.nome.toLowerCase().includes(nomeProcedimento.toLowerCase())
  );

  if (!procedimento) {
    return { encontrado: false, mensagem: "Procedimento não encontrado" };
  }

  // 2. Filtrar profissionais pelo tipoProfissionalId
  const profissionaisAptos = profissionais.filter(p =>
    p.tipoProfissionalId === procedimento.tipoProfissionalId
  );

  return {
    encontrado: true,
    procedimento: procedimento,
    profissionais: profissionaisAptos
  };
}

// Exemplo de uso:
const resultado = buscarProfissionaisParaProcedimento(
  "botox",
  syncData.procedimentos,
  syncData.profissionais
);

// resultado = {
//   encontrado: true,
//   procedimento: { nome: "BOTOX - APLICAÇÃO", valor: 500, tipoProfissionalId: 15 },
//   profissionais: [
//     { id: 166, nome: "Dra. Ana Silva", tipoProfissionalId: 15 },
//     { id: 167, nome: "Dr. João Santos", tipoProfissionalId: 15 }
//   ]
// }
```

---

## Sumário de Endpoints

| Categoria | Endpoint | Método | Base URL |
|-----------|----------|--------|----------|
| **Autenticação** | `/api/v1/entrar` | POST | clinix-autenticacao |
| **Conta** | `/api/v1/Conta/verificacartao` | GET | clinix-cadastro |
| **Conta** | `/api/v1/Conta/verificainadimplencia` | GET | clinix-cadastro |
| **Conta** | `/api/v1/usuarioconta/idusuario` | GET | clinix-cadastro |
| **Conta** | `/api/v1/Conta/clinicaconta` | GET | clinix-cadastro |
| **Tipos** | `/api/v1/tipoatendimento` | GET | clinix-cadastro |
| **Tipos** | `/api/v1/tipoatendimento/tipoAtendimentoPersonalizado` | GET | clinix-cadastro |
| **Tipos** | `/api/v1/statusconsulta` | GET | clinix-cadastro |
| **Especialidades** | `/api/v1/especialidade/clinicaconta` | GET | clinix-cadastro |
| **Especialidades** | `/api/v1/especialidade/conta` | GET | clinix-cadastro |
| **Cadeiras** | `/api/v1/cadeira` | GET | clinix-cadastro |
| **Pacientes** | `/api/v1/pacientefiltro` | GET | clinix-cadastro |
| **Pacientes** | `/api/v1/paciente/autocompleteNome` | POST | clinix-cadastro |
| **Pacientes** | `/api/v1/paciente/GetProximoCodigoPaciente` | GET | clinix-cadastro |
| **Pacientes** | `/api/v1/paciente` | POST | clinix-cadastro |
| **Pacientes** | `/api/v1/paciente/id` | POST | clinix-cadastro |
| **Pacientes** | `/api/v1/paciente` | PATCH | clinix-cadastro |
| **Pacientes** | `/api/v1/paciente/cpf` | GET | clinix-cadastro |
| **Pacientes** | `/api/v1/origemrelacionamento` | GET | clinix-cadastro |
| **Pacientes** | `/api/v1/campanha` | GET | clinix-cadastro |
| **CEP** | `/api/v1/Cep/GetPorCep/{cep}` | GET | cep.odontosfera.com.br |
| **Profissionais** | `/api/v1/profissional` | GET | clinix-cadastro |
| **Profissionais** | `/api/v1/profissional/id` | GET | clinix-cadastro |
| **Profissionais** | `/api/v1/profissional/conta` | GET | clinix-cadastro |
| **Profissionais** | `/api/v1/profissionalclinica/idclinica` | GET | clinix-cadastro |
| **Usuários** | `/api/v1/usuario` | GET | clinix-cadastro |
| **Financeiro** | `/api/v1/categoria` | GET | clinix-financeiro |
| **Financeiro** | `/api/v1/metodopagamento` | GET | clinix-financeiro |
| **Financeiro** | `/api/v1/contacaixa/clinica` | GET | clinix-financeiro |
| **Financeiro** | `/api/v1/extratofinanceiro` | POST | clinix-financeiro |
| **Planos** | `/api/v1/plano` | GET | clinix-cadastro |
| **Agenda** | `/api/v1/horarioatendimento` | GET | clinix-cadastro |
| **Agenda** | `/api/v1/horarioatendimento/especialidade` | GET | clinix-cadastro |
| **Agenda** | `/api/v1/agenda/filtraragenda` | POST | clinix-cadastro |
| **Agenda** | `/api/v1/Consulta/gravaconsulta` | POST | clinix-cadastro |
| **Agenda** | `/api/v1/Consulta/filtroagenda` | POST | clinix-cadastro |
| **Agenda** | `/api/v1/agenda/status` | PUT | clinix-cadastro |
| **Agenda** | `/api/v1/Consulta` | PATCH | clinix-cadastro |
| **Agenda** | `/api/v1/Consulta/id` | GET | clinix-cadastro |
| **Tipos Profissional** | `/api/v1/tipoprofissional` | GET | clinix-cadastro |
| **Regiões** | `/api/v1/regiao` | GET | clinix-cadastro |
| **Tabela Preço** | `/api/v1/tabelapreco/tabelapreco` | GET | clinix-cadastro |
| **Procedimentos** | `/api/v1/tabelapreco/procedimentoespecialidade/paginado` | GET | clinix-cadastro |
| **Profissionais** | `/api/v1/profissionalclinica/idprofissional` | GET | clinix-cadastro |
| **CRM - Agendamentos** | `/api/v1/agenda/painel` | POST | clinix-cadastro |
| **CRM - Inadimplentes** | `/api/v1/painelfinanceiropaciente/inadimplentes` | GET | clinix-financeiro |
| **CRM - Leads** | `/api/v1/leads/dashboard/filtro` | POST | clinix-cadastro |
| **CRM - Vendas** | `/api/v1/painelorcamento` | GET | clinix-financeiro |

---

## Mapeamento de IDs Comuns

### Status de Consulta
| ID | Nome | Painel |
|----|------|--------|
| 1 | Agendado | Aguardando |
| 2 | Compareceu | Confirmado |
| 3 | Em Atendimento | Confirmado |
| 4 | Atendido | Confirmado |
| 5 | Faltou | Não Compareceu |
| 6 | Antecipou Consulta | Confirmado |
| 7 | Desmarcou | Cancelado |
| 8 | Cancelado | Cancelado |
| 9 | Reagendou | Confirmado |
| 11 | Confirmado | Confirmado |

### Tipos de Atendimento
| ID | Nome |
|----|------|
| 2 | Avaliação |
| 5 | Urgência/Emergência |
| 6 | Tratamento |
| 7 | Inicio de Tratamento |
| 12 | Reinicio |
| 14 | Retorno |

### Métodos de Pagamento
| ID | Nome |
|----|------|
| 1 | Boleto |
| 2 | Crédito |
| 3 | Débito |
| 4 | Dinheiro |
| 5 | PIX |
| 6 | Operadora |

### Tipos de Profissional
| ID | Nome |
|----|------|
| 1 | Dentista |
| 2 | Esteticista |
| 3 | Fonoaudiólogo |
| 4 | Psicólogo |
| 5 | Nutricionista |
| 6 | Outro |

### Regiões de Tratamento (Odontológico)
| ID | Nome |
|----|------|
| 1 | Dente |
| 2 | Dente e Face |
| 3 | Sextante |
| 4 | Hemi-arcada |
| 5 | Arcada |
| 6 | Boca |
| 7 | Lingua |
| 8 | Mucosa |
| 9 | Labio |
| 10 | Sessão |

---

## Fluxo Completo de Agendamento (Resumo)

Para criar um agendamento via API, siga esta sequência:

```
1. Autenticação
   POST /api/v1/entrar → Obter token JWT

2. Obter IDs necessários (pode fazer em paralelo):
   GET /api/v1/Conta/clinicaconta → clinicaId
   GET /api/v1/profissionalclinica/idclinica → profissionalId, cadeiraId, especialidadeId
   GET /api/v1/plano → planoId

3. Buscar paciente:
   POST /api/v1/paciente/autocompleteNome → pacienteId

4. Verificar disponibilidade:
   GET /api/v1/horarioatendimento → Horários de trabalho do profissional
   POST /api/v1/agenda/filtraragenda → Horários já ocupados

5. Criar agendamento:
   POST /api/v1/Consulta/gravaconsulta → Criar consulta

6. (Opcional) Listar/verificar:
   POST /api/v1/Consulta/filtroagenda → Confirmar agendamento criado
```

### IDs Necessários para Agendamento

| Campo | Como obter | Endpoint |
|-------|------------|----------|
| `clinicaID` | Login ou Conta | `/Conta/clinicaconta` |
| `contaId` | Login | `/entrar` (retorna `idConta`) |
| `profissionalId` | Lista profissionais | `/profissionalclinica/idclinica` |
| `cadeiraId` | Dados do profissional | `/profissionalclinica/idclinica` |
| `especialidadeId` | Dados do profissional | `/profissionalclinica/idclinica` |
| `pacienteId` | Busca por nome | `/paciente/autocompleteNome` |
| `planoId` | Lista de planos | `/plano` |
| `tipoAtendimentoPersonalizadoId` | Tipos personalizados | `/tipoatendimento/tipoAtendimentoPersonalizado` |

### Mapeamento de Tipos de Atendimento

| ID Personalizado | Nome | Categoria (tipoAtendimentoId) |
|------------------|------|------------------------------|
| 806 | Avaliação | 2 |
| 810 | Inicio de Tratamento | 7 |
| (verificar) | Reinicio | 12 |
| (verificar) | Retorno | 14 |
| (verificar) | Tratamento | 6 |
| (verificar) | Urgência/Emergência | 5 |

**Nota**: Os IDs personalizados variam por clínica. Use o endpoint `/tipoatendimento/tipoAtendimentoPersonalizado` para obter os IDs corretos.

---

## Referência Rápida - Endpoints Essenciais para Integração

### Sync Inicial (ao salvar credenciais)

| Operação | Método | Endpoint | Base URL |
|----------|--------|----------|----------|
| Login | POST | `/api/v1/entrar` | clinix-autenticacao |
| Clínicas | GET | `/api/v1/Conta/clinicaconta?id={contaId}` | clinix-cadastro |
| Profissionais | GET | `/api/v1/profissionalclinica/idclinica?contaId={}&clinicaId={}` | clinix-cadastro |
| Tipos Atendimento | GET | `/api/v1/tipoatendimento/tipoAtendimentoPersonalizado?isAtivos=true` | clinix-cadastro |
| Status Consulta | GET | `/api/v1/statusconsulta` | clinix-cadastro |
| Horários | GET | `/api/v1/horarioatendimento?contaid={}&clinicaid={}&profissionalId={}` | clinix-cadastro |

### Operações da IA (em tempo real)

| Operação | Método | Endpoint | Base URL |
|----------|--------|----------|----------|
| Buscar Paciente | POST | `/api/v1/paciente/autocompleteNome` | clinix-financeiro |
| Criar Paciente | POST | `/api/v1/paciente` | clinix-cadastro |
| Verificar Disponibilidade | POST | `/api/v1/agenda/filtraragenda` | clinix-cadastro |
| **Criar Agendamento** | POST | `/api/v1/Consulta/gravaconsulta` | clinix-cadastro |
| **Reagendar** | PATCH | `/api/v1/Consulta` | clinix-cadastro |
| **Cancelar** | PATCH | `/api/v1/Consulta` (statusConsulta: 8) | clinix-cadastro |
| Consultas do Paciente | GET | `/api/v1/paciente/sobrepaciente?id={}` | clinix-cadastro |

### Status de Consulta (para referência)

| ID | Nome | Uso |
|----|------|-----|
| 1 | Agendado | Novo agendamento |
| 2 | Confirmado | Paciente confirmou |
| 3 | Aguardando | Na recepção |
| 4 | Em Atendimento | Sendo atendido |
| 5 | Atendido | Concluído |
| 6 | **Cancelado** | Para cancelar consulta |
| 7 | **Faltou** | Paciente não compareceu |

---

## 16. CRM (Customer Relationship Management)

O módulo CRM do Clinix possui 4 painéis principais para gestão de relacionamento com pacientes:
- **Agendamentos**: Painel Kanban para acompanhamento de consultas
- **Inadimplentes**: Gestão de pacientes com débitos em atraso
- **Leads**: Dashboard de leads para conversão
- **Vendas**: Painel Kanban de orçamentos/propostas comerciais

### 16.1 Painel de Agendamentos (CRM)
**URL da Aplicação**: `#/paineis/agendamentos`

**Endpoint**: `POST /api/v1/agenda/painel`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Request Body**:
```json
{
  "clinicaId": 57,
  "profissionalId": 0,
  "especialidadeId": 0,
  "dataInicio": "2025-12-01T03:00:00.000Z",
  "dataFinal": "2025-12-31T03:00:00.000Z",
  "statusConsultaPainelId": 0,
  "statusPacienteId": 0,
  "tipoAtendimentoId": 0,
  "statusConsultaId": 0,
  "pacienteId": 0
}
```

**Campos do Request**:
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `clinicaId` | number | ID da clínica (obrigatório) |
| `profissionalId` | number | Filtro por profissional (0 = todos) |
| `especialidadeId` | number | Filtro por especialidade (0 = todos) |
| `dataInicio` | string | Data início do período (ISO 8601) |
| `dataFinal` | string | Data fim do período (ISO 8601) |
| `statusConsultaPainelId` | number | Status no painel (0 = todos) |
| `statusPacienteId` | number | Filtro por status do paciente |
| `tipoAtendimentoId` | number | Filtro por tipo de atendimento |
| `statusConsultaId` | number | Filtro por status da consulta |
| `pacienteId` | number | Filtro por paciente específico |

**Response (200 OK)**:
Retorna consultas organizadas em colunas Kanban:
- **A Confirmar / Faltantes**: Consultas pendentes de confirmação ou onde o paciente faltou
- **Confirmados**: Consultas confirmadas
- **Perdidos**: Consultas canceladas ou perdidas

**Uso**: Dashboard para equipe de recepção/atendimento visualizar e gerenciar agendamentos.

---

### 16.2 Painel de Inadimplentes (CRM)
**URL da Aplicação**: `#/paineis/financeiro`

**Endpoint**: `GET /api/v1/painelfinanceiropaciente/inadimplentes`
**Base URL**: `https://clinix-financeiro.azurewebsites.net`

**Query Parameters**:
| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `dataInicio` | string | Sim | Data início (ISO 8601) |
| `dataFinal` | string | Sim | Data fim (ISO 8601) |
| `pacienteId` | number | Não | Filtro por paciente (null = todos) |
| `clinicaId` | number | Sim | ID da clínica |
| `tipoOrdenacao` | number | Não | Tipo de ordenação |
| `tipoRecorrencia` | number | Não | Tipo de recorrência |
| `periodoCompleto` | boolean | Não | Período completo |

**Request**:
```
GET /api/v1/painelfinanceiropaciente/inadimplentes?dataInicio=2025-12-01T00:00:00.000Z&dataFinal=2025-12-31T23:59:59.000Z&pacienteId=null&clinicaId=57&tipoOrdenacao=5&tipoRecorrencia=0&periodoCompleto=false
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "itens": [...],
    "qntInadimplentes": 10,
    "valorInadimplentes": 5000.00,
    "qntNegociacao": 3,
    "valorNegociacao": 1500.00,
    "qntRecebidos": 5,
    "valorRecebidos": 2500.00,
    "qntPerdas": 2,
    "valorPerdas": 1000.00
  }
}
```

**Campos da Response**:
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `itens` | array | Lista de pacientes inadimplentes |
| `qntInadimplentes` | number | Quantidade de inadimplentes |
| `valorInadimplentes` | number | Valor total em atraso |
| `qntNegociacao` | number | Quantidade em negociação |
| `valorNegociacao` | number | Valor em negociação |
| `qntRecebidos` | number | Quantidade recebidos |
| `valorRecebidos` | number | Valor recebido |
| `qntPerdas` | number | Quantidade de perdas |
| `valorPerdas` | number | Valor de perdas |

**Uso**: Gestão de cobranças e acompanhamento de pacientes com débitos.

---

### 16.3 Dashboard de Leads (CRM)
**URL da Aplicação**: `#/dashboard/leads`

#### 16.3.1 Filtrar Dashboard de Leads
**Endpoint**: `POST /api/v1/leads/dashboard/filtro`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Request Body**:
```json
{
  "dataInicio": "2025-12-01T03:00:00.000Z",
  "dataFim": "2025-12-31T03:00:00.000Z",
  "clinicaId": 57,
  "profissionalId": 0,
  "especialidadeId": 0,
  "motivoPerda": 0,
  "origemRelacionamentoId": 0
}
```

**Campos do Request**:
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `dataInicio` | string | Data início do período |
| `dataFim` | string | Data fim do período |
| `clinicaId` | number | ID da clínica |
| `profissionalId` | number | Filtro por profissional (0 = todos) |
| `especialidadeId` | number | Filtro por especialidade (0 = todos) |
| `motivoPerda` | number | Filtro por motivo de perda (0 = todos) |
| `origemRelacionamentoId` | number | Filtro por origem/canal (0 = todos) |

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "totalLeads": 7,
    "semRegistro": 5,
    "agendados": 1,
    "perdidos": 1,
    "tempoMedio": "0 hora(s) e 0 minuto(s)",
    "agendamentoEspecialidade": [...],
    ...
  }
}
```

**Campos da Response**:
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `totalLeads` | number | Total de leads no período |
| `semRegistro` | number | Leads sem registro/contato |
| `agendados` | number | Leads que agendaram |
| `perdidos` | number | Leads perdidos |
| `tempoMedio` | string | Tempo médio de conversão |
| `agendamentoEspecialidade` | array | Agendamentos por especialidade |

#### 16.3.2 Motivos de Perda de Leads
**Endpoint**: `GET /api/v1/leads/perdas`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Descrição**: Retorna lista de motivos de perda de leads para uso nos filtros.

#### 16.3.3 Canais de Marketing (Origem)
**Endpoint**: `GET /api/v1/origemrelacionamento/getall`
**Base URL**: `https://clinix-cadastro.azurewebsites.net`

**Query Parameters**:
| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `todos` | boolean | Não | `true` = todos, `false` = apenas ativos |

**Descrição**: Retorna canais de marketing/origem dos leads (Instagram, Google, Indicação, etc.).

**Uso**: Dashboard analítico para acompanhamento de conversão de leads em pacientes.

---

### 16.4 Painel de Vendas/Orçamentos (CRM)
**URL da Aplicação**: `#/paineis/vendas`

#### 16.4.1 Listar Orçamentos do Painel
**Endpoint**: `GET /api/v1/painelorcamento`
**Base URL**: `https://clinix-financeiro.azurewebsites.net`

**Query Parameters**:
| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `contaId` | number | Sim | ID da conta |
| `clinicaId` | number | Não | ID da clínica (0 = todas) |
| `inicio` | string | Sim | Data início (ISO 8601) |
| `final` | string | Sim | Data fim (ISO 8601) |
| `tipoRecorrencia` | number | Não | Tipo de recorrência |

**Request**:
```
GET /api/v1/painelorcamento?contaId=62&clinicaId=0&inicio=2025-12-01T03:00:00.000Z&final=2025-12-31T03:00:00.000Z&tipoRecorrencia=0
```

**Response (200 OK)**:
Retorna orçamentos organizados em colunas Kanban:
- **Em Aberto**: Orçamentos criados aguardando negociação
- **Em Negociação**: Orçamentos em processo de negociação
- **Aprovados**: Orçamentos aprovados pelo paciente
- **Perdidos**: Orçamentos não aprovados/cancelados

Cada orçamento contém:
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `orcamentoId` | number | ID do orçamento |
| `pacienteId` | number | ID do paciente |
| `nomePaciente` | string | Nome do paciente |
| `valor` | number | Valor do orçamento |
| `dataCriacao` | string | Data de criação |
| `dataAprovacao` | string | Data de aprovação (se aplicável) |
| `dataPerda` | string | Data de perda (se aplicável) |
| `profissionalId` | number | ID do profissional responsável |
| `clinicaId` | number | ID da clínica |
| `comentarios` | array | Histórico de comentários |

#### 16.4.2 Motivos de Perda de Orçamento
**Endpoint**: `GET /api/v1/painelorcamento/perdas`
**Base URL**: `https://clinix-financeiro.azurewebsites.net`

**Descrição**: Retorna lista de motivos de perda de orçamentos para filtros e registro.

#### 16.4.3 Endpoints Auxiliares para Filtros de Vendas

**Clínicas para Orçamento**:
```
GET /api/v1/clinica/orc?contaId={contaId}
Base URL: clinix-cadastro
```

**Especialidades para Orçamento**:
```
GET /api/v1/especialidade/orc?contaId={contaId}
Base URL: clinix-cadastro
```

**Procedimentos para Orçamento**:
```
GET /api/v1/procedimentos/orc?contaId={contaId}
Base URL: clinix-financeiro
```

**Uso**: Painel de funil de vendas para equipe comercial acompanhar orçamentos e propostas.

---

## 17. Prontuários / Tratamentos

Endpoints para gerenciamento de prontuários e tratamentos de pacientes. Essenciais para **remarketing** e ofertas baseadas em tratamentos finalizados.

### 17.1 Relatório Global de Tratamentos (⭐ PRINCIPAL)

**Endpoint**: `POST /api/v1/tratamentosorcamento/relatorioTratamentos`
**Base URL**: `https://clinix-financeiro.azurewebsites.net`

**Descrição**: Lista todos os tratamentos/prontuários de **TODOS os pacientes** com filtros avançados. Ideal para campanhas de remarketing e análise de tratamentos finalizados.

**Request Body**:
```json
{
  "tipoProfissional": 0,
  "profissionalId": 0,
  "especialidadeIds": [],
  "motivoPerdaId": 0,
  "statusIds": [2],
  "tipoData": 1,
  "dataInicial": "2024-01-01T03:00:00.000Z",
  "dataFinal": "2025-12-31T03:00:00.000Z"
}
```

**Parâmetros do Body**:
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `tipoProfissional` | number | Tipo de profissional (0 = todos) |
| `profissionalId` | number | ID do profissional (0 = todos) |
| `especialidadeIds` | array | IDs das especialidades (vazio = todas) |
| `motivoPerdaId` | number | ID do motivo de perda (0 = todos) |
| `statusIds` | array | **Status dos tratamentos** (ver tabela abaixo) |
| `tipoData` | number | 1 = Data Aprovação, 2 = Data Finalização |
| `dataInicial` | string | Data início do período (ISO 8601) |
| `dataFinal` | string | Data fim do período (ISO 8601) |

**Códigos de Status (statusIds)**:
| Código | Status | Descrição |
|--------|--------|-----------|
| 1 | Aberto | Tratamento em aberto/pendente |
| 2 | Finalizado | Tratamento concluído |
| 3 | Cancelado | Tratamento cancelado |
| 5 | Faltou | Paciente faltou |
| 6 | Em Tratamento | Tratamento em andamento |
| 7 | Alta | Paciente recebeu alta |

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1320738,
      "ativo": true,
      "paciente": "Nome do Paciente",
      "pacienteId": 46711,
      "celularPaciente": "41996201955",
      "orcamento": 540488,
      "guia": 540488,
      "status": 2,
      "profissionalId": 50,
      "profissional": "Dr. Nome",
      "profissionalExecutanteId": 0,
      "profissionalExecutante": null,
      "especialidade": "Clínico Geral",
      "dataAprovacao": "2025-12-02T00:00:00",
      "dataFinalizacao": "2025-12-05T00:00:00",
      "dataPerda": null,
      "isRecorrente": false,
      "motivoPerdaId": 0,
      "procedimento": "LIMPEZA PROFILÁTICA",
      "statusAssinatura": 0,
      "dadosRegiaoTratamento": [80]
    }
  ]
}
```

**Campos da Response**:
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | number | ID do tratamento |
| `paciente` | string | Nome do paciente |
| `pacienteId` | number | ID do paciente |
| `celularPaciente` | string | **Celular para contato** (remarketing) |
| `orcamento` | number | ID do orçamento relacionado |
| `guia` | number | Número da guia |
| `status` | number | Status atual do tratamento |
| `profissionalId` | number | ID do profissional responsável |
| `profissional` | string | Nome do profissional |
| `especialidade` | string | Especialidade do procedimento |
| `dataAprovacao` | string | Data de aprovação |
| `dataFinalizacao` | string | Data de finalização |
| `procedimento` | string | Nome do procedimento realizado |
| `isRecorrente` | boolean | Se é tratamento recorrente |

**Uso Prático - Remarketing**:
```javascript
// Buscar todos os tratamentos finalizados nos últimos 6 meses
const response = await fetch('https://clinix-financeiro.azurewebsites.net/api/v1/tratamentosorcamento/relatorioTratamentos', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer {token}'
  },
  body: JSON.stringify({
    tipoProfissional: 0,
    profissionalId: 0,
    especialidadeIds: [],
    motivoPerdaId: 0,
    statusIds: [2], // Finalizados
    tipoData: 2, // Por data de finalização
    dataInicial: "2024-06-01T03:00:00.000Z",
    dataFinal: "2024-12-31T03:00:00.000Z"
  })
});

// Usar celularPaciente para enviar ofertas via WhatsApp
```

---

### 17.2 Prontuários por Paciente - Abertos

**Endpoint**: `GET /api/v1/tratamentosorcamento/paciente`
**Base URL**: `https://clinix-financeiro.azurewebsites.net`

**Query Parameters**:
| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `pacienteId` | number | ID do paciente |
| `todos` | boolean | `false` = apenas abertos |
| `especialidadeId` | number | ID da especialidade (0 = todas) |

**Request**:
```
GET /api/v1/tratamentosorcamento/paciente?pacienteId=46711&todos=false&especialidadeId=0
```

**Descrição**: Lista os tratamentos/prontuários **abertos** de um paciente específico.

---

### 17.3 Prontuários por Paciente - Finalizados

**Endpoint**: `GET /api/v1/tratamentosorcamento/prontuario`
**Base URL**: `https://clinix-financeiro.azurewebsites.net`

**Query Parameters**:
| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `pacienteId` | number | ID do paciente |
| `especialidadeId` | number | ID da especialidade (0 = todas) |

**Request**:
```
GET /api/v1/tratamentosorcamento/prontuario?pacienteId=46711&especialidadeId=0
```

**Descrição**: Lista os tratamentos/prontuários **finalizados** de um paciente específico.

---

### Resumo: Endpoints de Prontuários

| Funcionalidade | Endpoint | Método | Base URL |
|----------------|----------|--------|----------|
| **Relatório Global** | `/api/v1/tratamentosorcamento/relatorioTratamentos` | POST | clinix-financeiro |
| Abertos (paciente) | `/api/v1/tratamentosorcamento/paciente` | GET | clinix-financeiro |
| Finalizados (paciente) | `/api/v1/tratamentosorcamento/prontuario` | GET | clinix-financeiro |

---

## 18. Painel de Inadimplentes (CRM Financeiro)

Endpoints para gestão de clientes inadimplentes - útil para campanhas de recuperação de crédito e negociação de dívidas.

### 18.1 Listar Inadimplentes (⭐ PRINCIPAL)

**Endpoint**: `GET /api/v1/painelfinanceiropaciente/inadimplentes`
**Base URL**: `https://clinix-financeiro.azurewebsites.net`

**Query Parameters**:
| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `dataInicio` | ISO 8601 | ✅ | Data inicial do filtro |
| `dataFinal` | ISO 8601 | ✅ | Data final do filtro |
| `clinicaId` | number | ✅ | ID da clínica (**use `0` para TODAS**) |
| `pacienteId` | string | ❌ | ID do paciente ou `null` para todos |
| `tipoOrdenacao` | number | ❌ | 5 = Maior valor (default) |
| `tipoRecorrencia` | number | ❌ | 0 = Todos os tipos |
| `periodoCompleto` | boolean | ❌ | `false` = período específico |

**Request - Todas as clínicas**:
```
GET /api/v1/painelfinanceiropaciente/inadimplentes
  ?dataInicio=2025-01-01T00:00:00.000Z
  &dataFinal=2025-12-31T23:59:59.000Z
  &pacienteId=null
  &clinicaId=0
  &tipoOrdenacao=5
  &tipoRecorrencia=0
  &periodoCompleto=false
```

**Request - Clínica específica**:
```
GET /api/v1/painelfinanceiropaciente/inadimplentes
  ?dataInicio=2025-09-01T00:00:00.000Z
  &dataFinal=2025-12-08T23:59:59.000Z
  &pacienteId=null
  &clinicaId=57
  &tipoOrdenacao=5
  &tipoRecorrencia=0
  &periodoCompleto=false
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "itens": [
      {
        "pacienteId": 40441,
        "nomePaciente": "Anestésico dos Santos",
        "cpfPaciente": "90436173000",
        "celular": "41996201955",
        "telefone": null,
        "dias": 497,
        "dataUltimoVencimento": "2025-12-01T00:00:00",
        "valorTotal": 4803.69,
        "valorDebito": 4025.82,
        "valorRecebido": 0.00,
        "dataCard": "0001-01-01T00:00:00",
        "situacaoAtual": 2,
        "dataNegociacao": null,
        "dataDesfecho": "2025-10-08T00:00:00",
        "parcelas": 31,
        "contratoAtivo": true,
        "detalhes": []
      }
    ],
    "qntInadimplentes": 3,
    "valorInadimplentes": 7019.98,
    "qntNegociacao": 0,
    "valorNegociacao": 0,
    "qntRecebidos": 0,
    "valorRecebidos": 0,
    "qntPerdas": 0,
    "valorPerdas": 0
  }
}
```

**Campos do Response**:
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `pacienteId` | number | ID do paciente inadimplente |
| `nomePaciente` | string | Nome completo do paciente |
| `cpfPaciente` | string | CPF do paciente |
| `celular` | string | Celular para contato |
| `dias` | number | Dias em atraso |
| `valorTotal` | decimal | Valor total do contrato |
| `valorDebito` | decimal | Valor em débito (a receber) |
| `valorRecebido` | decimal | Valor já recebido |
| `parcelas` | number | Quantidade de parcelas em atraso |
| `contratoAtivo` | boolean | Se o contrato ainda está ativo |
| `situacaoAtual` | number | 2 = Inadimplente |
| `dataUltimoVencimento` | ISO 8601 | Data do último vencimento |

**Descrição**:
Lista todos os pacientes inadimplentes para trabalhar negociação de dívidas. Use `clinicaId=0` para buscar de TODAS as clínicas simultaneamente.

---

### 18.2 Detalhes Financeiros do Paciente (⭐ ESSENCIAL)

**Endpoint**: `GET /api/v1/financeirodetalhes/paciente`
**Base URL**: `https://clinix-financeiro.azurewebsites.net`

Retorna **todas as parcelas/títulos** de um paciente, permitindo ver exatamente o que está em aberto ou pago.

**Query Parameters**:
| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `pacienteId` | number | ✅ | ID do paciente |
| `todos` | boolean | ❌ | `true` = todos os registros, `false` = apenas pendentes |

**Request - Apenas pendentes**:
```
GET /api/v1/financeirodetalhes/paciente?pacienteId=40441&todos=false
```

**Request - Histórico completo**:
```
GET /api/v1/financeirodetalhes/paciente?pacienteId=40441&todos=true
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "dadosFinanceiro": [
      {
        "id": 30170,
        "nome": "(23827) - Plano de Tratamento de Anestésico D. Santos",
        "profissionalId": 166,
        "nomeProfissional": "Alda Silva",
        "nomePaciente": "Anestésico dos Santos",
        "pacienteId": 40441,
        "orcamentoId": 23827,
        "dataVencimento": "2024-05-02T23:59:59",
        "numeroParcela": 1,
        "totalParcelas": 10,
        "valor": 143.57,
        "dataRecebimento": "2024-12-10T10:29:54.166",
        "valorRecebido": 143.57,
        "tipoPagamentoId": 38,
        "nomeTipoPagamento": "Dinheiro",
        "tipoLancamento": 8,
        "statusPagamento": 4,
        "clinicaId": 57,
        "usuario": "Henrique Lopes da Silva"
      }
    ]
  }
}
```

**Campos do Response**:
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | number | ID único do lançamento financeiro |
| `nome` | string | Descrição (inclui ID do orçamento) |
| `orcamentoId` | number | ID do plano de tratamento/orçamento |
| `numeroParcela` | number | Número da parcela atual |
| `totalParcelas` | number | Total de parcelas do parcelamento |
| `valor` | decimal | Valor da parcela |
| `dataVencimento` | ISO 8601 | Data de vencimento |
| `valorRecebido` | decimal | Valor efetivamente pago |
| `dataRecebimento` | ISO 8601 | Data do pagamento (se pago) |
| `statusPagamento` | number | Status: 1=Pendente, 4=Pago |
| `tipoPagamentoId` | number | ID da forma de pagamento |
| `nomeTipoPagamento` | string | Nome da forma (Dinheiro, Cartão, etc) |
| `profissionalId` | number | ID do profissional responsável |
| `nomeProfissional` | string | Nome do profissional |
| `clinicaId` | number | ID da clínica |
| `usuario` | string | Usuário que registrou |

**Fluxo de Uso para Negociação de Dívidas**:
1. Primeiro, buscar inadimplentes com `/api/v1/painelfinanceiropaciente/inadimplentes`
2. Para cada `pacienteId` inadimplente, buscar detalhes com este endpoint
3. Filtrar por `statusPagamento=1` para ver apenas parcelas pendentes
4. Usar `numeroParcela` e `totalParcelas` para entender o parcelamento

---

### 18.3 Resumo Financeiro do Paciente

**Endpoint**: `GET /api/v1/financeirodetalhes/resumo`
**Base URL**: `https://clinix-financeiro.azurewebsites.net`

Retorna um resumo consolidado dos valores financeiros do paciente em um período.

**Query Parameters**:
| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `pacienteId` | number | ✅ | ID do paciente |
| `De` | ISO 8601 | ✅ | Data inicial do período |
| `Ate` | ISO 8601 | ✅ | Data final do período |

**Request**:
```
GET /api/v1/financeirodetalhes/resumo
  ?pacienteId=40441
  &De=2024-01-01T00:00:00.000Z
  &Ate=2025-12-31T23:59:59.000Z
```

**Descrição**:
Use este endpoint para obter totalizadores (valor total, recebido, pendente) sem precisar processar cada parcela individualmente.

---

### Resumo: Endpoints do CRM

| Painel | Endpoint | Método | Base URL |
|--------|----------|--------|----------|
| Agendamentos | `/api/v1/agenda/painel` | POST | clinix-cadastro |
| Inadimplentes | `/api/v1/painelfinanceiropaciente/inadimplentes` | GET | clinix-financeiro |
| **Detalhes Financeiros** | `/api/v1/financeirodetalhes/paciente` | GET | clinix-financeiro |
| **Resumo Financeiro** | `/api/v1/financeirodetalhes/resumo` | GET | clinix-financeiro |
| Leads | `/api/v1/leads/dashboard/filtro` | POST | clinix-cadastro |
| Leads - Motivos | `/api/v1/leads/perdas` | GET | clinix-cadastro |
| Leads - Canais | `/api/v1/origemrelacionamento/getall` | GET | clinix-cadastro |
| Vendas | `/api/v1/painelorcamento` | GET | clinix-financeiro |
| Vendas - Motivos | `/api/v1/painelorcamento/perdas` | GET | clinix-financeiro |
| Vendas - Clínicas | `/api/v1/clinica/orc` | GET | clinix-cadastro |
| Vendas - Especialidades | `/api/v1/especialidade/orc` | GET | clinix-cadastro |
| Vendas - Procedimentos | `/api/v1/procedimentos/orc` | GET | clinix-financeiro |

---

## 19. Monitoramento de Vencimentos (Boletos/Faturas)

Esta seção documenta os endpoints relacionados ao monitoramento de vencimentos de boletos, faturas e alertas de cobrança automatizados.

---

### 19.1 Extrato Financeiro (⭐ PRINCIPAL)

**Endpoint**: `POST /api/v1/extratofinanceiro`
**Base URL**: `https://clinix-financeiro.azurewebsites.net`

Endpoint principal para consultar transações financeiras com filtro por data de vencimento, status de pagamento e método de pagamento (boleto, PIX, etc).

**Request Body**:
```json
{
  "clinicaId": 57,
  "contaCaixaId": 0,
  "filtros": [0],
  "tipo": 0,
  "tipoData": 2,
  "dataInicio": "2025-12-01T03:00:00.000Z",
  "dataFinal": "2025-12-31T03:00:00.000Z",
  "metodoPagamentoId": 0,
  "categoriaId": 0,
  "pacienteId": 0,
  "profissionalId": 0,
  "statusPagamento": 0,
  "textoSearch": "",
  "contaId": 62
}
```

**Campos do Request**:
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `clinicaId` | number | ID da clínica (0 para todas) |
| `contaCaixaId` | number | ID da conta caixa (0 para todas) |
| `filtros` | array | Array de filtros [0] |
| `tipo` | number | Tipo de extrato (0=geral) |
| `tipoData` | number | **2=Data de Vencimento**, 1=Data de Pagamento, 0=Data de Lançamento |
| `dataInicio` | ISO 8601 | Data inicial do período |
| `dataFinal` | ISO 8601 | Data final do período |
| `metodoPagamentoId` | number | Filtrar por método (0=todos, ver 19.2) |
| `categoriaId` | number | Filtrar por categoria (0=todas) |
| `pacienteId` | number | Filtrar por paciente (0=todos) |
| `profissionalId` | number | Filtrar por profissional (0=todos) |
| `statusPagamento` | number | **0=Todos, 1=Pendente, 2=Aguardando Pagamento** |
| `textoSearch` | string | Busca textual |
| `contaId` | number | ID da conta principal |

**Response (200 OK)**:
```json
{
  "success": true,
  "data": {
    "extratoFinanceiros": [
      {
        "id": 258488,
        "dataVencimento": "2025-12-11T00:00:00",
        "dataPagamento": null,
        "dataLancamento": "2025-12-02T00:00:00",
        "metodoPagamentoId": 96,
        "metodoPagamentoNome": "Boleto Pagseguro",
        "statusPagamento": 1,
        "statusPagamentoNome": "Pendente",
        "valor": 500.00,
        "valorPago": 0.00,
        "valorRestante": 500.00,
        "pacienteId": 12345,
        "pacienteNome": "NOME DO PACIENTE",
        "pacienteCelular": "(11) 99999-9999",
        "profissionalId": 123,
        "profissionalNome": "Dr. Nome",
        "clinicaId": 57,
        "clinicaNome": "Nome da Clínica",
        "descricao": "Parcela 1/3 - Tratamento X",
        "parcelaNumero": 1,
        "parcelaTotal": 3,
        "contaCaixaId": 144,
        "contaCaixaNome": "Conta Principal",
        "categoriaId": 5,
        "categoriaNome": "Receita Procedimentos",
        "orcamentoId": 54321
      }
    ],
    "totalReceita": 15000.00,
    "totalDespesa": 0.00,
    "saldoPeriodo": 15000.00
  }
}
```

**Campos Importantes da Response**:
| Campo | Descrição |
|-------|-----------|
| `dataVencimento` | **Data de vencimento do boleto/fatura** |
| `dataPagamento` | Data em que foi pago (null se pendente) |
| `statusPagamento` | 1=Pendente, 2=Aguardando, 3=Pago, 4=Cancelado |
| `metodoPagamentoNome` | "Boleto Pagseguro", "PIX Asaas", "CRÉDITO ASAAS", etc |
| `valorRestante` | Valor ainda a receber |
| `parcelaNumero/parcelaTotal` | Informação de parcelamento (ex: 1/3) |

**Casos de Uso**:
- Listar boletos vencendo hoje: `tipoData=2`, `statusPagamento=1`, data de hoje
- Listar boletos vencidos: `tipoData=2`, `statusPagamento=1`, dataFinal no passado
- Listar apenas boletos: `metodoPagamentoId=96` (ID do Boleto Pagseguro)

---

### 19.2 Métodos de Pagamento

**Endpoint**: `GET /api/v1/metodopagamento`
**Base URL**: `https://clinix-financeiro.azurewebsites.net`

Lista todos os métodos de pagamento disponíveis, incluindo boleto, PIX e cartões.

**Query Parameters**:
| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `contaId` | number | ✅ | ID da conta |

**Request**:
```
GET /api/v1/metodopagamento?contaId=62
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    {
      "id": 96,
      "nome": "Boleto Pagseguro",
      "ativo": true,
      "tipoPagamento": 3
    },
    {
      "id": 97,
      "nome": "PIX Asaas",
      "ativo": true,
      "tipoPagamento": 4
    },
    {
      "id": 98,
      "nome": "CRÉDITO ASAAS",
      "ativo": true,
      "tipoPagamento": 1
    },
    {
      "id": 99,
      "nome": "DÉBITO ASAAS",
      "ativo": true,
      "tipoPagamento": 2
    },
    {
      "id": 1,
      "nome": "Dinheiro",
      "ativo": true,
      "tipoPagamento": 0
    }
  ]
}
```

**Tipos de Pagamento**:
| tipoPagamento | Descrição |
|---------------|-----------|
| 0 | Dinheiro |
| 1 | Crédito |
| 2 | Débito |
| 3 | **Boleto** |
| 4 | PIX |

---

### 19.3 Alertas de Cobrança Automática (⭐ CONFIGURAÇÃO)

**Endpoint**: `GET /api/v1/financeiroalertacobranca/getall`
**Base URL**: `https://clinix-financeiro.azurewebsites.net`

Lista as configurações de alertas automáticos de cobrança, que enviam notificações antes ou depois do vencimento.

**Query Parameters**:
| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `todos` | boolean | ❌ | `true` para incluir inativos |

**Request**:
```
GET /api/v1/financeiroalertacobranca/getall?todos=false
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    {
      "id": 15,
      "nome": "Lembrete 3 dias antes",
      "periodo": 3,
      "quando": 0,
      "metodoPagamentoId": 96,
      "metodoPagamentoNome": "Boleto Pagseguro",
      "notificacao": [1],
      "especialidades": [5, 12],
      "ativo": true,
      "mensagem": "Olá {nome}, seu boleto vence em 3 dias..."
    },
    {
      "id": 16,
      "nome": "Cobrança 1 dia após vencimento",
      "periodo": 1,
      "quando": 1,
      "metodoPagamentoId": 0,
      "metodoPagamentoNome": null,
      "notificacao": [1],
      "especialidades": [],
      "ativo": true,
      "mensagem": "Olá {nome}, identificamos um boleto vencido..."
    }
  ]
}
```

**Campos Importantes**:
| Campo | Descrição |
|-------|-----------|
| `periodo` | Quantidade de dias (antes ou depois do vencimento) |
| `quando` | **0=Antes do Vencimento, 1=Depois do Vencimento** |
| `metodoPagamentoId` | 0=Todos os métodos, ou ID específico |
| `notificacao` | Array de canais: **[1]=WhatsApp**, [2]=Email, [3]=SMS |
| `especialidades` | Filtrar por especialidades (array vazio=todas) |
| `mensagem` | Template da mensagem com variáveis |

**Variáveis do Template**:
- `{nome}` - Nome do paciente
- `{valor}` - Valor do boleto
- `{vencimento}` - Data de vencimento
- `{link}` - Link do boleto

---

### 19.4 Categorias Financeiras

**Endpoint**: `GET /api/v1/categoria`
**Base URL**: `https://clinix-financeiro.azurewebsites.net`

Lista as categorias financeiras (receitas e despesas).

**Request**:
```
GET /api/v1/categoria
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    {
      "id": 5,
      "nome": "Receita Procedimentos",
      "tipo": 1,
      "ativo": true
    },
    {
      "id": 8,
      "nome": "Despesas Operacionais",
      "tipo": 2,
      "ativo": true
    }
  ]
}
```

**Tipos**:
- `tipo: 1` = Receita
- `tipo: 2` = Despesa

---

### 19.5 Contas Caixa por Clínica

**Endpoint**: `GET /api/v1/contacaixa/clinica`
**Base URL**: `https://clinix-financeiro.azurewebsites.net`

Lista as contas caixa disponíveis para uma clínica específica.

**Query Parameters**:
| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `contaId` | number | ✅ | ID da conta principal |
| `clinicaId` | number | ✅ | ID da clínica |

**Request**:
```
GET /api/v1/contacaixa/clinica?contaId=62&clinicaId=57
```

**Response (200 OK)**:
```json
{
  "success": true,
  "data": [
    {
      "id": 144,
      "nome": "Conta Principal",
      "clinicaId": 57,
      "ativo": true,
      "saldo": 25000.00
    },
    {
      "id": 145,
      "nome": "Conta Secundária",
      "clinicaId": 57,
      "ativo": true,
      "saldo": 5000.00
    }
  ]
}
```

---

### Resumo: Endpoints de Monitoramento de Vencimentos

| Função | Endpoint | Método | Base URL |
|--------|----------|--------|----------|
| **Extrato Financeiro** | `/api/v1/extratofinanceiro` | POST | clinix-financeiro |
| **Métodos Pagamento** | `/api/v1/metodopagamento` | GET | clinix-financeiro |
| **Alertas Cobrança** | `/api/v1/financeiroalertacobranca/getall` | GET | clinix-financeiro |
| **Categorias** | `/api/v1/categoria` | GET | clinix-financeiro |
| **Contas Caixa** | `/api/v1/contacaixa/clinica` | GET | clinix-financeiro |

### Fluxo para Monitorar Vencimentos

```javascript
// 1. Buscar métodos de pagamento para obter ID do Boleto
GET /api/v1/metodopagamento?contaId=62
// → Encontrar id onde nome="Boleto Pagseguro" (ex: 96)

// 2. Buscar boletos vencendo nos próximos 3 dias
POST /api/v1/extratofinanceiro
{
  "clinicaId": 0,  // todas as clínicas
  "tipoData": 2,   // por data de vencimento
  "dataInicio": "2025-12-11T00:00:00.000Z",
  "dataFinal": "2025-12-14T00:00:00.000Z",
  "metodoPagamentoId": 96,  // apenas boletos
  "statusPagamento": 1,     // apenas pendentes
  "contaId": 62
}

// 3. Para cada boleto, pode enviar lembrete via WhatsApp
// usando os dados: pacienteNome, pacienteCelular, valor, dataVencimento
```

---

*Documentação gerada via engenharia reversa em 27/11/2025*
*Atualizada com fluxo completo de agendamento em 27/11/2025*
*Atualizada com criação de paciente em 27/11/2025*
*Atualizada com reagendamento/cancelamento de consultas em 27/11/2025*
*Atualizada com edição de paciente em 27/11/2025*
*Atualizada com endpoints da página "Sobre" do paciente (consultas agendadas) em 27/11/2025*
*Atualizada com detalhamento completo dos endpoints de profissionais em 02/12/2025*
*Atualizada com tipos de profissional, regiões, tabela de preços e procedimentos em 02/12/2025*
*Atualizada com módulo CRM (Agendamentos, Inadimplentes, Leads, Vendas) em 04/12/2025*
*Atualizada com Prontuários/Tratamentos para remarketing em 08/12/2025*
*Atualizada com Painel de Inadimplentes (negociação de dívidas) em 08/12/2025*
*Atualizada com Detalhes Financeiros do Paciente (parcelas/títulos) em 08/12/2025*
*Atualizada com Monitoramento de Vencimentos (Boletos/Faturas) em 11/12/2025*
*Total de endpoints mapeados: 72*
