class LogProprietario < ApplicationRecord
  self.table_name = "treino.log_proprietario"

  def readonly?
    true
  end
end
