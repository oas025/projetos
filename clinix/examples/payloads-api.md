# Exemplos de Payloads - API Clinix

## 📝 Autenticação

### Request: Login

```http
POST /api/v1/entrar HTTP/1.1
Host: clinix-autenticacao.azurewebsites.net
Content-Type: application/json
Accept: application/json

{
  "login": "henrique.silva@nst.com.br",
  "password": "Teste@123"
}
```

### Response: Login Sucesso

```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJQUzI1NiIsImtpZCI6IlJzSVh0MGxyVGltSTA0WHYzajZPV2ciLCJ0eXAiOiJKV1QifQ...",
    "user": {
      "idUsuario": 72,
      "idConta": 62,
      "nomeUsuario": "Henrique Lopes da Silva",
      "email": "henrique.silva@nst.com.br",
      "isGestor": true,
      "isAtendente": true
    }
  },
  "message": null
}
```

---

## 📊 Buscar Orçamentos

### Request: Painel de Orçamentos

```http
GET /api/v1/painelorcamento?contaId=62&clinicaId=0&inicio=2024-01-01T00:00:00&final=2025-12-31T23:59:59&tipoRecorrencia=0 HTTP/1.1
Host: clinix-financeiro.azurewebsites.net
Authorization: Bearer eyJhbGci...
Accept: application/json
```

### Response: Lista de Orçamentos

```json
{
  "success": true,
  "data": [
    {
      "id": 123456,
      "orcamentoId": 253235,
      "statusCard": 4,
      "nome": "Orçamento Implante",
      "pacienteId": 46711,
      "nomePaciente": "Abílio Diniz",
      "celular": "16994660219",
      "profissionalId": 166,
      "profissionalNome": "Alda Silva",
      "especialidadeId": 13,
      "nomeEspecialidade": "Dentística",
      "valor": 1390.00,
      "dataOrcamento": "2025-04-16T12:56:19.741963",
      "dataAprovacao": "0001-01-01T00:00:00",
      "dataPerda": "2025-04-16T12:58:26.541276",
      "dataMovimentacaoNegociacao": "2025-04-16T12:58:26.541276",
      "motivoPerdaId": 5,
      "nomeMotivoPerda": "Preço alto",
      "nomeClinica": "Clínica Odonto Vida",
      "clinicaId": 57,
      "isRecorrencia": false,
      "orcamentoInicial": null,
      "isContatoRealizado": false,
      "dataRetorno": null,
      "painelObservacoes": []
    }
  ]
}
```

---

## 🔍 Detalhes do Orçamento

### Request: Buscar Detalhes

```http
GET /api/v1/negociacaoorcamento/orcamento?orcamentoId=253235&contaId=62 HTTP/1.1
Host: clinix-financeiro.azurewebsites.net
Authorization: Bearer eyJhbGci...
Accept: application/json
```

### Response: Detalhes Completos

```json
{
  "success": true,
  "data": {
    "procedimentos": [
      {
        "s": {
          "orcamentoId": 253235,
          "procedimentoId": 10299,
          "descricaoProcedimento": "Profilaxia|85400319",
          "dadosRegiao": [80],
          "observacao": "",
          "aprovado": true,
          "planoId": 77,
          "profissionalId": 166,
          "valor": 164.15,
          "valorDesconto": 64.15,
          "valorFinal": 100.00,
          "status": 1,
          "procedimento": {
            "tuss": 85400319,
            "codigo": null,
            "nome": "Profilaxia",
            "especialidadeId": 8,
            "regiaoId": 7
          },
          "profissional": {
            "nome": "Alda Silva",
            "cpf": "55156764088",
            "email": "charles.almeida@clinix.app.br",
            "celular": "16994645653"
          },
          "plano": {
            "nome": "Plano Particular",
            "contaId": 62
          }
        },
        "dadosRegiao": [
          {
            "id": 80,
            "descricao": "Arcadas Superiores e inferiores",
            "valor": "ASAI",
            "regiaoId": 7
          }
        ],
        "dentesSelecionados": [],
        "facesDentesSelecionados": []
      }
    ],
    "negociacao": {
      "orcamentoId": 253235,
      "descontoFinalProcedimentosPct": 0,
      "descontoFinalProcedimentosVl": 0,
      "tipoDesconto": 1,
      "valorFinalProcedimentos": 1390.00,
      "metodoPagamentoId": 38,
      "valorTotalAcrescimo": 0,
      "valorTotalDesconto": 85.66,
      "valorTotal": 1390.00,
      "orcamento": {
        "descricao": "(253235) - Plano de Tratamento de Abílio Diniz",
        "pacienteId": 46711,
        "statusOrcamentoId": 4,
        "clinicaId": 57,
        "contaId": 62,
        "queixaPrincipal": "Teste",
        "dataAlteracaoOrcamento": "2025-04-16T12:58:26.541276",
        "profissionalResponsavelId": 50,
        "paciente": {
          "id": 46711,
          "contaId": 62,
          "nome": "Abílio Diniz",
          "celular": "16994660219",
          "telefone": null,
          "cpf": "24741070026",
          "dataNascimento": "1988-12-09T02:00:00",
          "email": "ivan.mastrange@clinix.app.br",
          "cep": "82110000",
          "logradouro": "R Alexandre V Humboldt",
          "numero": "350",
          "bairro": "Pilarzinho",
          "cidade": "Curitiba",
          "estado": "PR"
        }
      }
    },
    "negociacaoPagamento": [
      {
        "metodoPagamentoId": 38,
        "negociacaoOrcamentoId": 257700,
        "numeroParcela": 1,
        "dataVencimentoParcela": "2025-04-16T23:59:59",
        "qtdParcelas": 1,
        "valorParcela": 1390.00,
        "valorTotalParcelas": 1390.00,
        "metodoPagamento": {
          "formaPagamento": "DINHEIRO",
          "tipoPagamentoId": 1
        }
      }
    ]
  }
}
```

---

## 📅 Criar Agendamento

### Request: Gravar Consulta

```http
POST /api/v1/Consulta/gravaconsulta HTTP/1.1
Host: clinix-cadastro.azurewebsites.net
Authorization: Bearer eyJhbGci...
Content-Type: application/json
Accept: application/json

{
  "clinicaID": 57,
  "profissionalId": 1674,
  "cadeiraId": 62,
  "especialidadeId": 13,
  "pacienteId": 46711,
  "celularPaciente": "16994660219",
  "planoId": 77,
  "dataInicio": "2025-11-13T12:00:00.000Z",
  "hora_inicio": "09:00",
  "tempoConsulta": 10,
  "tipoAtendimentoPersonalizadoId": 807,
  "statusConsulta": 1,
  "retorno": false,
  "tipoRetorno": "1",
  "periodoRetorno": "1",
  "observacao": "Recuperação de venda perdida - Orçamento #253235",
  "origemRelacionamentoId": null,
  "origemRelacionamentoOutros": null,
  "dataFinal": "2025-11-13T12:10:00.000Z",
  "tituloConsulta": "Abílio Diniz",
  "contaId": 62,
  "painelLeadsId": null,
  "pacienteSimples": false,
  "usuario": "Henrique Lopes da Silva",
  "pacienteElegivel": null
}
```

### Response: Agendamento Criado

```json
{
  "success": true,
  "data": {
    "id": 12345,
    "consultaId": 12345
  },
  "message": "Consulta criada com sucesso"
}
```

### Response: Erro - Horário Ocupado

```json
{
  "success": false,
  "message": "Horário já ocupado",
  "errors": [
    {
      "field": "dataInicio",
      "message": "O profissional já possui agendamento neste horário"
    }
  ]
}
```

---

## 🔍 Estrutura JSONB - Procedimentos

### Exemplo de Procedimento Formatado

```json
{
  "procedimento_id": 10299,
  "nome": "Profilaxia",
  "descricao": "Profilaxia - Arcadas Superiores e inferiores (Dentes: 11, 21, 31, 41) - Faces: 11: O/I, 21: O/I",
  "codigo_tuss": 85400319,
  "valor_original": 164.15,
  "valor_desconto": 64.15,
  "valor_final": 100.00,
  "profissional": "Alda Silva",
  "plano": "Plano Particular",
  "status": 1,
  "status_nome": "PENDENTE",
  "aprovado": true,
  "regiao": "Arcadas Superiores e inferiores",
  "dentes": "11, 21, 31, 41",
  "faces": "11: O/I | 21: O/I | 31: O/I | 41: O/I",
  "observacao": null
}
```

---

## 🔍 Estrutura JSONB - Observações

### Exemplo de Observação Formatada

```json
{
  "id": 1001,
  "observacao": "Cliente pediu para retornar em fevereiro",
  "status": 1,
  "tipo_marcacao": 0,
  "usuario": "Maria Silva",
  "data_cadastro": "2025-01-25T16:50:00",
  "ativo": true
}
```

---

## 🔐 Headers Padrão

### Headers para GET

```http
Authorization: Bearer {token}
Accept: application/json
Content-Type: application/json
Origin: https://gestao.clinix.app.br
```

### Headers para POST

```http
Authorization: Bearer {token}
Accept: application/json
Content-Type: application/json
Origin: https://gestao.clinix.app.br
Access-Control-Allow-Origin: *
```

---

## 📊 Códigos de Status

| Status | Significado | Ação |
|--------|-------------|------|
| 200 | OK | Sucesso |
| 201 | Created | Recurso criado |
| 400 | Bad Request | Validar payload |
| 401 | Unauthorized | Renovar token |
| 403 | Forbidden | Verificar permissões |
| 404 | Not Found | Verificar endpoint |
| 409 | Conflict | Dados duplicados |
| 500 | Internal Server Error | Erro no servidor |

---

## 🎯 Mapeamento de Status

### Status Card (Orçamento)

```javascript
{
  1: "EM_ABERTO",
  2: "EM_NEGOCIACAO",
  3: "APROVADO",
  4: "PERDIDO"
}
```

### Status Procedimento

```javascript
{
  1: "PENDENTE",
  2: "EM ANDAMENTO",
  3: "FINALIZADO",
  4: "CANCELADO"
}
```

### Status Consulta

```javascript
{
  1: "AGENDADO",
  2: "CONFIRMADO",
  3: "REALIZADO",
  4: "FALTOU",
  5: "CANCELADO"
}
```

---

## 🔄 Fluxo Completo de Dados

```
1. Autenticação
   POST /api/v1/entrar
   → Retorna token JWT

2. Buscar Orçamentos
   GET /api/v1/painelorcamento
   → Retorna lista com statusCard = 4

3. Buscar Detalhes
   GET /api/v1/negociacaoorcamento/orcamento
   → Retorna dados completos (paciente, procedimentos, pagamento)

4. Processar Dados
   Combinar painel + detalhes
   Formatar para 62 campos

5. Salvar no Supabase
   INSERT INTO vendas_perdidas
   → Registro completo armazenado

6. Criar Agendamento (opcional)
   POST /api/v1/Consulta/gravaconsulta
   → Agendamento de recuperação criado

7. Atualizar Status
   UPDATE vendas_perdidas
   SET status_recuperacao = 'agendado'
```
