class HistoricoFacade
  def initialize(dao = HistoricoDao.new)
    @dao = dao
  end

  delegate :listar, :pagina, to: :@dao
end
