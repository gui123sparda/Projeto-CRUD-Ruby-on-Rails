class VeiculoDao < ApplicationDao
  def totais
    vehicles = Veiculo.ativos.joins(:proprietario).merge(Proprietario.ativos)
    types = vehicles.group(:tipo).count
    {
      total_veiculos: types.values.sum,
      total_carros: types.fetch("CARRO", 0),
      total_motos: types.fetch("MOTO", 0)
    }
  end

  def model
    Veiculo
  end

  def consulta(filters = {})
    scope = model.ativos.joins(:proprietario).merge(Proprietario.ativos)
    %w[placa renavam chassi].each { |field| scope = texto(scope, "treino.veiculo.#{field}", filters[field]&.delete("-")) }
    %w[cidade estado].each { |field| scope = texto(scope, "treino.proprietario.#{field}", filters[field]) }
    scope = texto(scope, "treino.proprietario.nome", filters["proprietario"])
    scope = texto(scope, "treino.proprietario.cpf_cnpj", filters["documento"]&.gsub(/[^A-Z0-9]/i, ""))
    scope = scope.where(tipo: filters["tipo"]) if %w[CARRO MOTO].include?(filters["tipo"])
    scope = scope.where(id_proprietario: filters["idProprietario"]) if filters["idProprietario"].present?
    scope = scope.where("ano_fabricacao >= ?", filters["anoDe"].to_i) if filters["anoDe"].present?
    scope = scope.where("ano_fabricacao <= ?", filters["anoAte"].to_i) if filters["anoAte"].present?
    scope = scope.where("placa ~ ?", filters["modeloPlaca"] == "ANTIGA" ? "^[A-Z]{3}[0-9]{4}$" : "^[A-Z]{3}[0-9][A-Z][0-9]{2}$") if %w[ANTIGA MERCOSUL].include?(filters["modeloPlaca"])
    scope.includes(:proprietario).order(:placa, :id)
  end

  def consultar_placa(placa)
    # Preserva a função PostgreSQL do Servlet e usa bind para a entrada.
    id = model.connection.select_value(model.sanitize_sql_array([ "SELECT id_veiculo FROM treino.consultar_placa(?)", placa ]))
    model.ativos.includes(:proprietario).find_by(id: id)
  end
end
