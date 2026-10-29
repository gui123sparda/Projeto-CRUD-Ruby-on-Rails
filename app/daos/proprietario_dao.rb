class ProprietarioDao < ApplicationDao
  def total
    model.ativos.count
  end

  def model
    Proprietario
  end

  def consulta(filters = {})
    scope = model.ativos
    type = filters["tipoPessoa"]
    scope = scope.where("length(cpf_cnpj) = ?", type == "PF" ? 11 : 14) if %w[PF PJ].include?(type)
    %w[nome cidade estado rua numero cep complemento].each do |field|
      scope = texto(scope, "treino.proprietario.#{field}", filters[field])
    end
    scope = texto(scope, "cpf_cnpj", filters["documento"]&.gsub(/[^A-Z0-9]/i, ""))
    scope = texto(scope, "nome || ' ' || cpf_cnpj", filters["busca"])
    if %w[COM SEM].include?(filters["vinculos"])
      owners = Veiculo.ativos.select(:id_proprietario)
      scope = filters["vinculos"] == "COM" ? scope.where(id: owners) : scope.where.not(id: owners)
    end
    scope.order(:nome, :id)
  end

  def excluir_confirmado(id, confirmou:, total:)
    model.transaction do
      record = model.ativos.lock.find(id)
      count = record.veiculos.ativos.count
      if count.positive? && (!confirmou || total != count)
        raise ProprietarioFacade::ConfirmacaoNecessaria, "Este proprietário possui #{count} veículos. Confirme a exclusão de todos os vínculos atualizados."
      end
      record.update!(excluido_em: Time.current)
    end
  end

  def listar_agrupado(filters)
    consulta(filters).includes(:veiculos).to_a
  end

  def totais_veiculos(ids)
    Veiculo.ativos.where(id_proprietario: ids).group(:id_proprietario).count
  end
end
