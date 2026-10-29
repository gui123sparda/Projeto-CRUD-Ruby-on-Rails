class ProprietarioFacade
  class ConfirmacaoNecessaria < StandardError; end

  def initialize(dao = ProprietarioDao.new)
    @dao = dao
  end

  delegate :buscar, :listar, :pagina, :salvar, :totais_veiculos, :listar_agrupado, :total, to: :@dao

  def excluir(id, confirmou: false, total: 0)
    @dao.excluir_confirmado(id, confirmou: confirmou, total: total)
  end
end
