class VeiculoFacade
  def initialize(dao = VeiculoDao.new)
    @dao = dao
  end

  delegate :buscar, :listar, :pagina, :salvar, :excluir, :totais, to: :@dao

  def consultar_placa(value)
    placa = value.to_s.strip.upcase.delete("-")
    raise ArgumentError, "A placa deve ter o formato ABC1234 ou ABC1D23." unless placa.match?(/\A[A-Z]{3}[0-9][A-Z0-9][0-9]{2}\z/)
    @dao.consultar_placa(placa)
  end
end
