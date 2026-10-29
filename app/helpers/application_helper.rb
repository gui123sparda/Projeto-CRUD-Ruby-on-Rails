module ApplicationHelper
  def formatar_documento(value)
    document = value.to_s
    if document.length == 11
      document.gsub(/(\w{3})(\w{3})(\w{3})(\w{2})/, '\1.\2.\3-\4')
    elsif document.length == 14
      document.gsub(/(\w{2})(\w{3})(\w{3})(\w{4})(\w{2})/, '\1.\2.\3/\4-\5')
    else
      document
    end
  end

  def formatar_cep(value)
    value.to_s.gsub(/(\d{5})(\d{3})/, '\1-\2')
  end

  def formatar_endereco(record)
    [ record.rua, record.numero, record.complemento, record.cidade, record.estado, formatar_cep(record.cep) ].compact_blank.join(", ")
  end
end
