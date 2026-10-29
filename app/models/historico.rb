class Historico < ApplicationRecord
  self.table_name = "treino.historico"

  def readonly?
    true
  end
end
