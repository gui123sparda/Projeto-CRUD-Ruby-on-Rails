# Objeto de entrada: valida parâmetros, sem acessar persistência.
class FiltrosConsulta
  PROPRIETARIO = [ [ "nome", "Nome / razão social", "text", "" ], [ "documento", "CPF/CNPJ", "text", "" ], [ "cidade", "Cidade", "text", "" ], [ "estado", "UF", "text", "" ], [ "rua", "Rua", "text", "" ], [ "numero", "Número", "text", "" ], [ "cep", "CEP (prefixo)", "text", "" ], [ "complemento", "Complemento", "text", "" ], [ "vinculos", "Veículos vinculados", "select", "COM:Com veículos|SEM:Sem veículos" ] ].freeze
  VEICULO = [ [ "placa", "Placa", "text", "" ], [ "renavam", "RENAVAM", "text", "" ], [ "chassi", "Chassi", "text", "" ], [ "anoDe", "Ano inicial", "number", "" ], [ "anoAte", "Ano final", "number", "" ], [ "proprietario", "Nome do proprietário", "text", "" ], [ "documento", "CPF/CNPJ do proprietário", "text", "" ], [ "idProprietario", "ID do proprietário", "number", "" ], [ "cidade", "Cidade do proprietário", "text", "" ], [ "estado", "UF do proprietário", "text", "" ] ].freeze
  CAMPOS = (PROPRIETARIO + VEICULO).map(&:first).uniq.freeze
  EXTRAS = %w[campo valor busca tipoPessoa tipo modeloPlaca entidade operacao registroId dataDe dataAte].freeze

  def self.ler(params)
    filters = (CAMPOS + EXTRAS).index_with { |field| params[field].to_s.strip.upcase.first(150) }
    field = params[:campo].to_s
    if field.present?
      raise ArgumentError, "Campo de pesquisa inválido." unless CAMPOS.include?(field)
      filters["campo"] = field
      filters[field] = filters["valor"]
    end
    %w[anoDe anoAte idProprietario registroId].each do |key|
      value = filters[key]
      raise ArgumentError, "Filtro numérico inválido: #{key}" if value.present? && !value.match?(/\A[1-9][0-9]{0,8}\z/)
    end
    %w[dataDe dataAte].each { |key| Date.iso8601(filters[key]) if filters[key].present? }
    if filters["anoDe"].present? && filters["anoAte"].present? && filters["anoDe"].to_i > filters["anoAte"].to_i
      raise ArgumentError, "Ano inicial deve ser menor ou igual ao final."
    end
    if filters["dataDe"].present? && filters["dataAte"].present? && filters["dataDe"] > filters["dataAte"]
      raise ArgumentError, "Data inicial deve ser menor ou igual à final."
    end
    filters
  end
end
