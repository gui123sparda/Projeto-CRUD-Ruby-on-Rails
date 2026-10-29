class ProprietariosController < ApplicationController
  before_action :preparar

  def index
    mensagem
    case params[:acao]
    when "novo", "editar"
      @proprietario = params[:acao] == "editar" ? @facade.buscar(params[:id]) : Proprietario.new
      formulario
    when "visualizar", "veiculos"
      @proprietario = @facade.buscar(params[:id])
      @empresa = @proprietario.cpf_cnpj.length == 14
      page = VeiculoFacade.new.pagina({ "idProprietario" => @proprietario.id.to_s }, numero: params[:pagina])
      @veiculos_proprietario = paginar(page)
      @veiculos = @veiculos_proprietario
      @total_veiculos = @total
      render params[:acao] == "visualizar" ? "proprietario/detalhes" : "proprietario/veiculos"
    else
      listar
    end
  end

  def create
    if params[:acao] == "excluir"
      @facade.excluir(params[:id], confirmou: params[:confirmarCascata] == "true", total: params[:totalVeiculosConfirmado].to_i)
      redirect_to "/proprietarios.do", notice: "Proprietário excluído logicamente. Dados preservados no histórico."
    elsif params[:acao] == "salvar"
      @proprietario = params[:id].present? ? @facade.buscar(params[:id]) : Proprietario.new
      @proprietario.assign_attributes(atributos)
      @facade.salvar(@proprietario)
      redirect_to "/proprietarios.do?tipoPessoa=#{@proprietario.cpf_cnpj.length == 14 ? 'PJ' : 'PF'}", notice: "Proprietário salvo com sucesso."
    else
      raise ArgumentError, "Ação inválida."
    end
  rescue ActiveRecord::RecordInvalid => error
    @proprietario = error.record
    @erro = error.record.errors.full_messages.join(". ")
    formulario(status: :unprocessable_entity)
  rescue ProprietarioFacade::ConfirmacaoNecessaria => error
    @erro = error.message
    listar(status: :conflict)
  end

  def relatorio
    case params[:relatorio]
    when "proprietario"
      enviar_relatorio("Dados do proprietário", [ @facade.buscar(params[:id]) ])
    when "agrupado"
      proprietario = @facade.buscar(params[:idProprietario].presence || params[:id])
      enviar_relatorio("Proprietário e seus veículos", [ proprietario ], agrupado: true)
    else
      enviar_relatorio("Relatório de proprietários", @facade.listar(filtros))
    end
  end

  private

  def preparar
    @facade = ProprietarioFacade.new
    @caminho = "/proprietarios.do"
    @tipo_pessoa = params[:tipoPessoa].to_s
  end

  def atributos
    values = params.permit(:nome, :rua, :numero, :cep, :cidade, :estado, :complemento).to_h
    values["cpf_cnpj"] = params[:cpfCnpj] if params.key?(:cpfCnpj)
    values
  end

  def listar(status: :ok)
    @lista = paginar(@facade.pagina(filtros, numero: params[:pagina]))
    @totais_veiculos = @facade.totais_veiculos(@lista.map(&:id)).tap { |totals| totals.default = 0 }
    render "proprietario/lista", status: status
  end

  def formulario(status: :ok)
    @empresa = @tipo_pessoa == "PJ" || @proprietario.cpf_cnpj.to_s.gsub(/\W/, "").length == 14
    render "proprietario/formulario", status: status
  end
end
