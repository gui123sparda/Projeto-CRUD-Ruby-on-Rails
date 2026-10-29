class Veiculo < ApplicationRecord
  self.table_name = "treino.veiculo"

  belongs_to :proprietario, foreign_key: :id_proprietario, inverse_of: :veiculos
  scope :ativos, -> { where(excluido_em: nil) }
  before_validation :normalizar
  validates :placa, format: { with: /\A[A-Z]{3}[0-9][A-Z0-9][0-9]{2}\z/, message: "deve ter o formato ABC1234 ou ABC1D23" }, uniqueness: true
  validates :renavam, format: { with: /\A[0-9]{11}\z/, message: "deve conter 11 dígitos" }, uniqueness: true
  validates :chassi, format: { with: /\A[A-HJ-NPR-Z0-9]{17}\z/, message: "deve conter 17 caracteres válidos" }, uniqueness: true
  validates :tipo, inclusion: { in: %w[CARRO MOTO] }
  validates :ano_fabricacao, numericality: { only_integer: true, greater_than_or_equal_to: 1900, less_than_or_equal_to: ->(_) { Date.current.year + 1 } }
  validate :cadastro_editavel

  def tipo_rotulo
    tipo == "MOTO" ? "Moto" : "Carro"
  end

  private

  def normalizar
    self.placa = placa.to_s.strip.upcase.delete("-")
    self.renavam = renavam.to_s.strip
    self.chassi = chassi.to_s.strip.upcase
  end

  def cadastro_editavel
    errors.add(:proprietario, "selecione um proprietário ativo") unless proprietario && proprietario.excluido_em.nil?
    errors.add(:base, "Registro inativo não pode ser alterado") if persisted? && excluido_em_in_database.present?
  end
end
