class HistoricosController < ApplicationController
  def index
    @historico_veiculos = request.path.include?("veiculos")
    @lista = paginar(HistoricoFacade.new.pagina(filtros.merge("entidade" => @historico_veiculos ? "veiculo" : "proprietario"), numero: params[:pagina]))
    render "historico/lista"
  end
  def relatorio
    entidade = params[:relatorio] == "historico-veiculos" ? "veiculo" : "proprietario"
    enviar_relatorio("Histórico de cadastros", HistoricoFacade.new.listar(filtros.merge("entidade" => entidade)))
  end
end
