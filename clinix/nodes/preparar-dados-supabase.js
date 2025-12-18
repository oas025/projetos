// ========================================
// NODE: Preparar Dados Completos para Supabase
// ========================================
// Este node combina dados de vendaPerdida + detalhes
// e formata para os 62 campos da tabela vendas_perdidas

// Extrai dados da resposta de detalhes do orçamento
const detalhes = $input.item.json;

// Acessa os dados da venda perdida (node anterior "Filtra somente PERDIDOS")
const vendaPerdida = $item(0).$node["Filtra somente PERDIDOS"].json;

// Valida se há dados válidos
if (!detalhes.success || !detalhes.data) {
  throw new Error('Dados inválidos recebidos do endpoint de detalhes');
}

const data = detalhes.data;
const negociacao = data.negociacao || {};
const orcamento = negociacao.orcamento || {};
const paciente = orcamento.paciente || {};
const profissionalResponsavel = orcamento.profissionalResponsavel || {};

// ========================================
// 1. IDENTIFICADORES
// ========================================
const orcamento_id = vendaPerdida.orcamentoId || orcamento.id;
const painel_orcamento_id = vendaPerdida.id;

// ========================================
// 2. DADOS DO PACIENTE (8 campos)
// ========================================
const paciente_id = paciente.id;
const paciente_nome = paciente.nome;
const paciente_celular = paciente.celular;
const paciente_email = paciente.email;
const paciente_cpf = paciente.cpf;
const paciente_data_nascimento = paciente.dataNascimento;
const paciente_cidade = paciente.cidade;
const paciente_estado = paciente.estado;

// ========================================
// 3. DADOS DO PROFISSIONAL (4 campos)
// ========================================
const profissional_id = vendaPerdida.profissionalId || orcamento.profissionalResponsavelId;
const profissional_nome = vendaPerdida.profissionalNome;
const profissional_email = profissionalResponsavel.email || null;
const profissional_celular = profissionalResponsavel.celular || null;

// ========================================
// 4. DADOS DA CLÍNICA (3 campos)
// ========================================
const clinica_id = vendaPerdida.clinicaId || orcamento.clinicaId;
const clinica_nome = vendaPerdida.nomeClinica;
const conta_id = orcamento.contaId;

// ========================================
// 5. DADOS DA ESPECIALIDADE (2 campos)
// ========================================
const especialidade_id = vendaPerdida.especialidadeId;
const especialidade_nome = vendaPerdida.nomeEspecialidade;

// ========================================
// 6. VALORES FINANCEIROS (4 campos)
// ========================================
const valor_total = negociacao.valorTotal || vendaPerdida.valor || 0;
const valor_desconto_total = negociacao.valorTotalDesconto || 0;
const valor_acrescimo_total = negociacao.valorTotalAcrescimo || 0;
const valor_final = negociacao.valorTotal || vendaPerdida.valor || 0;

// ========================================
// 7. STATUS E MOTIVO DA PERDA (4 campos)
// ========================================
const status_card = vendaPerdida.statusCard;
const statusMap = {
  1: 'EM_ABERTO',
  2: 'EM_NEGOCIACAO',
  3: 'APROVADO',
  4: 'PERDIDO'
};
const status_descricao = statusMap[vendaPerdida.statusCard] || 'DESCONHECIDO';
const motivo_perda_id = vendaPerdida.motivoPerdaId;
const motivo_perda_nome = vendaPerdida.nomeMotivoPerda;

// ========================================
// 8. DATAS (5 campos)
// ========================================
const data_orcamento = vendaPerdida.dataOrcamento || orcamento.dataCadastro;
const data_aprovacao = vendaPerdida.dataAprovacao !== '0001-01-01T00:00:00'
  ? vendaPerdida.dataAprovacao
  : null;
const data_perda = vendaPerdida.dataPerda;
const data_movimentacao_negociacao = vendaPerdida.dataMovimentacaoNegociacao;
const data_retorno = vendaPerdida.dataRetorno;

// ========================================
// 9. PROCEDIMENTOS - JSONB (3 campos)
// ========================================
const procedimentos = (data.procedimentos || []).map(proc => {
  const s = proc.s;

  // Monta descrição completa
  let descricaoCompleta = s.descricaoProcedimento || s.procedimento.nome;

  // Adiciona região
  if (proc.dadosRegiao?.length > 0) {
    const regioes = proc.dadosRegiao.map(r => r.descricao).join(', ');
    descricaoCompleta += ` - ${regioes}`;
  }

  // Adiciona dentes
  if (proc.dentesSelecionados?.length > 0) {
    descricaoCompleta += ` (Dentes: ${proc.dentesSelecionados.join(', ')})`;
  }

  // Adiciona faces
  if (proc.facesDentesSelecionados?.length > 0) {
    const faces = proc.facesDentesSelecionados
      .map(f => `${f.denteId}: ${f.faces.join(', ')}`)
      .join(' | ');
    descricaoCompleta += ` - Faces: ${faces}`;
  }

  // Status do procedimento
  const statusProcMap = {
    1: 'PENDENTE',
    2: 'EM ANDAMENTO',
    3: 'FINALIZADO',
    4: 'CANCELADO'
  };

  return {
    procedimento_id: s.procedimentoId,
    nome: s.procedimento.nome,
    descricao: descricaoCompleta,
    codigo_tuss: s.procedimento.tuss,
    valor_original: s.valor,
    valor_desconto: s.valorDesconto,
    valor_final: s.valorFinal,
    profissional: s.profissional?.nome,
    plano: s.plano?.nome,
    status: s.status,
    status_nome: statusProcMap[s.status] || 'DESCONHECIDO',
    aprovado: s.aprovado,
    regiao: proc.dadosRegiao?.map(r => r.descricao).join(', ') || null,
    dentes: proc.dentesSelecionados?.join(', ') || null,
    faces: proc.facesDentesSelecionados?.length > 0
      ? proc.facesDentesSelecionados.map(f => `${f.denteId}: ${f.faces.join(', ')}`).join(' | ')
      : null,
    observacao: s.observacao || null
  };
});

const total_procedimentos = procedimentos.length;
const procedimentos_resumo = procedimentos
  .map(p => `${p.nome} (R$ ${p.valor_final.toFixed(2)})`)
  .join('; ');

// ========================================
// 10. OBSERVAÇÕES - JSONB (3 campos)
// ========================================
const observacoes = (vendaPerdida.painelObservacoes || []).map(obs => ({
  id: obs.id,
  observacao: obs.observacao,
  status: obs.status,
  tipo_marcacao: obs.tipoMarcacao,
  usuario: obs.usuario,
  data_cadastro: obs.dataCadastro,
  ativo: obs.ativo
}));

const total_observacoes = observacoes.length;
const ultima_observacao = observacoes.length > 0
  ? observacoes[observacoes.length - 1].observacao
  : null;

// ========================================
// 11. PAGAMENTO (5 campos)
// ========================================
const pagamento = data.negociacaoPagamento?.[0] || {};
const metodoPagamento = pagamento.metodoPagamento || {};

const forma_pagamento = metodoPagamento.formaPagamento;
const metodo_pagamento_id = pagamento.metodoPagamentoId;
const numero_parcelas = pagamento.qtdParcelas || 0;
const valor_parcela = pagamento.valorParcela || 0;
const data_vencimento_primeira_parcela = pagamento.dataVencimentoParcela;

// ========================================
// 12. RECORRÊNCIA (3 campos)
// ========================================
const is_recorrencia = vendaPerdida.isRecorrencia || false;
const orcamento_inicial = vendaPerdida.orcamentoInicial;
const tipo_recorrencia = 0; // Fixo por enquanto

// ========================================
// 13. RECUPERAÇÃO (8 campos - valores padrão)
// ========================================
const is_contato_realizado = vendaPerdida.isContatoRealizado || false;
const data_ultimo_contato = null;
const tipo_ultimo_contato = null;
const total_tentativas_recuperacao = 0;
const status_recuperacao = 'pendente';
const proxima_acao = null;
const responsavel_recuperacao = null;
const observacao_recuperacao = null;

// ========================================
// 14. DADOS COMPLETOS - JSONB (1 campo)
// ========================================
const dados_completos_json = {
  venda_perdida: vendaPerdida,
  detalhes_completos: detalhes
};

// ========================================
// 15. CONTROLE (3 campos)
// ========================================
const sincronizado_em = new Date().toISOString();
const atualizado_em = new Date().toISOString();
const ativo = true;

// ========================================
// OBJETO FINAL COMPLETO PARA SUPABASE
// ========================================
const registroCompleto = {
  // 1. Identificadores
  orcamento_id: orcamento_id,
  painel_orcamento_id: painel_orcamento_id,

  // 2. Paciente
  paciente_id: paciente_id,
  paciente_nome: paciente_nome,
  paciente_celular: paciente_celular,
  paciente_email: paciente_email,
  paciente_cpf: paciente_cpf,
  paciente_data_nascimento: paciente_data_nascimento,
  paciente_cidade: paciente_cidade,
  paciente_estado: paciente_estado,

  // 3. Profissional
  profissional_id: profissional_id,
  profissional_nome: profissional_nome,
  profissional_email: profissional_email,
  profissional_celular: profissional_celular,

  // 4. Clínica
  clinica_id: clinica_id,
  clinica_nome: clinica_nome,
  conta_id: conta_id,

  // 5. Especialidade
  especialidade_id: especialidade_id,
  especialidade_nome: especialidade_nome,

  // 6. Valores
  valor_total: valor_total,
  valor_desconto_total: valor_desconto_total,
  valor_acrescimo_total: valor_acrescimo_total,
  valor_final: valor_final,

  // 7. Status e Motivo
  status_card: status_card,
  status_descricao: status_descricao,
  motivo_perda_id: motivo_perda_id,
  motivo_perda_nome: motivo_perda_nome,

  // 8. Datas
  data_orcamento: data_orcamento,
  data_aprovacao: data_aprovacao,
  data_perda: data_perda,
  data_movimentacao_negociacao: data_movimentacao_negociacao,
  data_retorno: data_retorno,

  // 9. Procedimentos JSONB
  procedimentos: procedimentos,
  total_procedimentos: total_procedimentos,
  procedimentos_resumo: procedimentos_resumo,

  // 10. Observações JSONB
  observacoes: observacoes,
  ultima_observacao: ultima_observacao,
  total_observacoes: total_observacoes,

  // 11. Pagamento
  forma_pagamento: forma_pagamento,
  metodo_pagamento_id: metodo_pagamento_id,
  numero_parcelas: numero_parcelas,
  valor_parcela: valor_parcela,
  data_vencimento_primeira_parcela: data_vencimento_primeira_parcela,

  // 12. Recorrência
  is_recorrencia: is_recorrencia,
  orcamento_inicial: orcamento_inicial,
  tipo_recorrencia: tipo_recorrencia,

  // 13. Recuperação
  is_contato_realizado: is_contato_realizado,
  data_ultimo_contato: data_ultimo_contato,
  tipo_ultimo_contato: tipo_ultimo_contato,
  total_tentativas_recuperacao: total_tentativas_recuperacao,
  status_recuperacao: status_recuperacao,
  proxima_acao: proxima_acao,
  responsavel_recuperacao: responsavel_recuperacao,
  observacao_recuperacao: observacao_recuperacao,

  // 14. Dados Completos
  dados_completos_json: dados_completos_json,

  // 15. Controle
  sincronizado_em: sincronizado_em,
  atualizado_em: atualizado_em,
  ativo: ativo
};

// Retorna o registro completo pronto para inserir no Supabase
return { json: registroCompleto };
