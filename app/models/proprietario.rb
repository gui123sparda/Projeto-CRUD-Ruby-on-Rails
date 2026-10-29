class Proprietario < ApplicationRecord
  self.table_name = "treino.proprietario"

  has_many :veiculos, foreign_key: :id_proprietario, inverse_of: :proprietario
  scope :ativos, -> { where(excluido_em: nil) }
  before_validation :normalizar
  validates :nome, presence: true, length: { maximum: 150 }
  validates :cpf_cnpj, presence: true, uniqueness: true
  validates :rua, length: { maximum: 150 }
  validates :numero, length: { maximum: 20 }
  validates :cidade, length: { maximum: 100 }
  validates :complemento, length: { maximum: 255 }
  validates :cep, format: { with: /\A[0-9]{8}\z/, message: "deve conter 8 dígitos" }, allow_blank: true
  validates :estado, format: { with: /\A[A-Z]{2}\z/, message: "deve conter a UF com 2 letras" }, allow_blank: true
  validate :documento_valido
  validate :cadastro_editavel

  private

  def normalizar
    %w[nome rua numero cidade estado complemento].each { |field| self[field] = self[field]&.strip&.upcase.presence }
    self.cpf_cnpj = cpf_cnpj.to_s.upcase.gsub(/[.\s\/-]/, "")
    self.cep = cep.to_s.gsub(/[.\s-]/, "").presence
  end

  def documento_valido
    errors.add(:cpf_cnpj, "inválido: confira o formato e os dígitos verificadores") unless Documento.valido?(cpf_cnpj.to_s)
  end

  def cadastro_editavel
    errors.add(:cpf_cnpj, "não pode ser alterado após o cadastro") if persisted? && cpf_cnpj_changed?
    errors.add(:base, "Registro inativo não pode ser alterado") if persisted? && excluido_em_in_database.present?
  end
end
