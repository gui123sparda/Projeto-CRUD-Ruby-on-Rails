class LogProprietarioDao
  ResumoDiario = Data.define(:dia, :cadastros, :alteracoes)

  def resumo_diario(type)
    scope = LogProprietario.all
    scope = scope.where("length(cpf_cnpj) = ?", type == "PF" ? 11 : 14) if %w[PF PJ].include?(type)
    # Triggers gravam TIMESTAMP legado na sessão UTC do Active Record.
    # Converter explicitamente antes de agrupar evita trocar o dia em Fortaleza.
    start = 13.days.ago.to_date
    created = scope.where("data_criacao >= ?", start.in_time_zone.utc).group(Arel.sql("(data_criacao AT TIME ZONE 'UTC' AT TIME ZONE 'America/Fortaleza')::date")).distinct.count(:id_proprietario)
    changed = scope.where("data_alteracao >= ?", start.in_time_zone.utc).group(Arel.sql("(data_alteracao AT TIME ZONE 'UTC' AT TIME ZONE 'America/Fortaleza')::date")).distinct.count(:id_proprietario)
    (start..Date.current).map { |day| ResumoDiario.new(dia: day, cadastros: created.fetch(day, 0), alteracoes: changed.fetch(day, 0)) }
  end
end
