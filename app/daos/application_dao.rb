# Persistência compartilhada; consultas recebem somente colunas da lista permitida.
class ApplicationDao
  Pagina = Data.define(:registros, :total, :numero, :paginas)

  def listar(filters = {})
    consulta(filters).to_a
  end

  def pagina(filters, numero: 1)
    scope = consulta(filters)
    total = scope.count
    paginas = [ (total / 10.0).ceil, 1 ].max
    numero = numero.to_i.clamp(1, paginas)
    Pagina.new(registros: scope.limit(10).offset((numero - 1) * 10).to_a, total: total, numero: numero, paginas: paginas)
  end

  def buscar(id)
    model.ativos.find(id)
  end

  def salvar(record)
    model.transaction(requires_new: true) { record.save! }
    record.reload
  rescue ActiveRecord::RecordNotUnique
    record.errors.add(:base, "Já existe um cadastro com este documento, placa, RENAVAM ou chassi")
    raise ActiveRecord::RecordInvalid, record
  end

  def excluir(id)
    model.transaction do
      record = model.ativos.lock.find(id)
      record.update!(excluido_em: Time.current)
    end
  end

  private

  def texto(scope, column, value)
    return scope if value.blank?
    owner = Proprietario.arel_table
    vehicle = Veiculo.arel_table
    columns = %w[nome cidade estado rua numero cep complemento cpf_cnpj].index_with { |name| owner[name] }
    %w[nome cidade estado rua numero cep complemento].each { |name| columns["treino.proprietario.#{name}"] = owner[name] }
    %w[placa renavam chassi].each { |name| columns["treino.veiculo.#{name}"] = vehicle[name] }
    columns["treino.proprietario.cpf_cnpj"] = owner[:cpf_cnpj]
    columns["nome || ' ' || cpf_cnpj"] = Arel::Nodes::NamedFunction.new("concat_ws", [ Arel::Nodes.build_quoted(" "), owner[:nome], owner[:cpf_cnpj] ])
    normalized = Arel::Nodes::NamedFunction.new("treino.normalizar_busca", [ columns.fetch(column) ])
    pattern = Arel::Nodes::NamedFunction.new("treino.normalizar_busca", [ Arel::Nodes.build_quoted("%#{ActiveRecord::Base.sanitize_sql_like(value)}%") ])
    scope.where(normalized.matches(pattern))
  end
end
