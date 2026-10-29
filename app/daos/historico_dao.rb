class HistoricoDao < ApplicationDao
  def consulta(filters = {})
    entidade = filters.fetch("entidade", "proprietario")
    scope = Historico.where(entidade: entidade)
    scope = scope.where(registro_id: filters["registroId"]) if filters["registroId"].present?
    scope = scope.where(operacao: filters["operacao"]) if filters["operacao"].present?
    scope = scope.where("ocorrido_em >= ?", Time.zone.parse(filters["dataDe"]).beginning_of_day) if filters["dataDe"].present?
    scope = scope.where("ocorrido_em <= ?", Time.zone.parse(filters["dataAte"]).end_of_day) if filters["dataAte"].present?
    if filters["busca"].present?
      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(filters['busca'])}%"
      scope = scope.where("treino.normalizar_busca(coalesce(antes::text, '') || coalesce(depois::text, '')) LIKE treino.normalizar_busca(?)", pattern)
    end
    scope.order(ocorrido_em: :desc, id: :desc)
  end
end
