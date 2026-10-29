class LogProprietariosController < ApplicationController
  def index
    @tipo_pessoa_historico = params[:tipoPessoa].to_s
    totais = VeiculoFacade.new.totais
    historico = LogProprietarioFacade.new.resumo_diario(@tipo_pessoa_historico)
    resumo = totais.merge(
      total_proprietarios: ProprietarioFacade.new.total,
      percentual_carros: totais[:total_veiculos].zero? ? 0 : (totais[:total_carros] * 100.0 / totais[:total_veiculos]).round,
      historico_proprietarios: historico,
      escala_historico: [ 1, *historico.flat_map { |dia| [ dia.cadastros, dia.alteracoes ] } ].max
    )
    @total_veiculos = resumo[:total_veiculos]
    @total_carros = resumo[:total_carros]
    @total_motos = resumo[:total_motos]
    @total_proprietarios = resumo[:total_proprietarios]
    @percentual_carros = resumo[:percentual_carros]
    @historico_proprietarios = resumo[:historico_proprietarios]
    @escala_historico = resumo[:escala_historico]
    render "log_proprietario/index"
  end
end
