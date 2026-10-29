class LogProprietarioFacade
  def initialize(dao = LogProprietarioDao.new)
    @dao = dao
  end

  delegate :resumo_diario, to: :@dao
end
