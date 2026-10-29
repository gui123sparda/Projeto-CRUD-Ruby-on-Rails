class VeiculosController < ApplicationController
  before_action :preparar

  def index
    mensagem
    case params[:acao]
    when "novo", "editar"
      @veiculo = params[:acao] == "editar" ? @facade.buscar(params[:id]) : Veiculo.new(id_proprietario: params[:idProprietario])
      formulario
    when "consultarPlaca"
      consultar_placa
    else
      @lista = paginar(@facade.pagina(filtros, numero: params[:pagina]))
      @nomes_proprietarios = @lista.to_h { |record| [ record.id_proprietario, record.proprietario.nome ] }
      render "veiculo/lista"
    end
  end

  def create
    if params[:acao] == "excluir"
      @facade.excluir(params[:id])
      destination = params[:idProprietarioRetorno].present? ? "/proprietarios.do?acao=veiculos&id=#{params[:idProprietarioRetorno].to_i}" : "/veiculos.do"
      redirect_to destination, notice: "Veículo excluído logicamente. Dados preservados no histórico."
    elsif params[:acao] == "salvar"
      @veiculo = params[:id].present? ? @facade.buscar(params[:id]) : Veiculo.new
      @veiculo.assign_attributes(params.permit(:placa, :renavam, :chassi, :tipo).to_h.merge(ano_fabricacao: params[:anoFabricacao], id_proprietario: params[:idProprietario]))
      @facade.salvar(@veiculo)
      redirect_to "/veiculos.do", notice: "Veículo salvo com sucesso."
    else
      raise ArgumentError, "Ação inválida."
    end
  rescue ActiveRecord::RecordInvalid => error
    @veiculo = error.record
    @erro = error.record.errors.full_messages.join(". ")
    formulario(status: :unprocessable_entity)
  end

  def placa
    record = @facade.buscar(params[:id])
    send_data PlacaImagem.new.renderizar(record), type: "image/svg+xml", disposition: "inline"
  end

  def relatorio
    if params[:relatorio] == "veiculo"
      enviar_relatorio("Dados do veículo", [ @facade.buscar(params[:id]) ])
    else
      enviar_relatorio("Relatório de veículos", @facade.listar(filtros))
    end
  end

  private

  def preparar
    @facade = VeiculoFacade.new
    @caminho = "/veiculos.do"
  end

  def formulario(status: :ok)
    @proprietarios = ProprietarioFacade.new.listar
    @proprietario_selecionado = @veiculo.id_proprietario.to_s
    @ano_informado = @veiculo.ano_fabricacao
    render "veiculo/formulario", status: status
  end

  def consultar_placa
    @placa_pesquisada = params[:placa].to_s
    if @placa_pesquisada.present?
      begin
        @resultado = @facade.consultar_placa(@placa_pesquisada)
        @mensagem = "Nenhum veículo encontrado para a placa informada." unless @resultado
      rescue ArgumentError => error
        @erro = error.message
      end
    end
    @proprietario_resultado = @resultado&.proprietario
    @placa_mercosul = @resultado&.placa.to_s.match?(/\A[A-Z]{3}[0-9][A-Z][0-9]{2}\z/)
    @placa_moto = @resultado&.tipo == "MOTO"
    @placa_exibida = @resultado&.placa
    @exibir_painel_consulta = @resultado.nil?
    render "veiculo/consulta-placa"
  end
end
