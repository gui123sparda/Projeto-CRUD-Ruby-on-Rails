require "test_helper"

class CadastroTest < ActiveSupport::TestCase
  test "CPF and alphanumeric CNPJ validate their check digits" do
    [ "52998224725", "11222333000181", "12ABC34501DE35" ].each do |document|
      assert Proprietario.new(cpf_cnpj: document, nome: "Teste").valid?, document
    end
    [ "11111111111", "52998224724", "11222333000182", "12ABC34501DE36" ].each do |document|
      assert_not Proprietario.new(cpf_cnpj: document, nome: "Teste").valid?, document
    end
  end

  test "vehicle validates plate chassi year and active ownership" do
    record = Veiculo.new(placa: "INVALID", renavam: "1", chassi: "IIIIIIIIIIIIIIIII", ano_fabricacao: 1800, id_proprietario: 999, tipo: "BARCO")
    assert_not record.valid?
    %i[placa renavam chassi ano_fabricacao tipo proprietario].each { |field| assert record.errors[field].present?, field }
  end

  test "Servlet demonstration seed is repeatable and produces valid models" do
    previous = ENV["SEED_DEMO"]
    ENV["SEED_DEMO"] = "true"
    2.times { load Rails.root.join("db/seeds.rb") }
    assert_equal 15, Proprietario.count
    assert_equal 30, Veiculo.count
    assert_equal 15, Historico.where(entidade: "proprietario", operacao: "CADASTRO").count
    Proprietario.find_each { |record| assert record.valid?, record.errors.full_messages.join(", ") }
    Veiculo.find_each { |record| assert record.valid?, record.errors.full_messages.join(", ") }
  ensure
    ENV["SEED_DEMO"] = previous
  end

  test "database refuses physical deletion and audit modification" do
    owner = ProprietarioFacade.new.salvar(Proprietario.new(cpf_cnpj: "52998224725", nome: "Teste"))
    assert_raises(ActiveRecord::StatementInvalid) do
      Proprietario.transaction(requires_new: true) { owner.delete }
    end
    event = Historico.find_by!(entidade: "proprietario", registro_id: owner.id)
    assert_raises(ActiveRecord::StatementInvalid) do
      Historico.transaction(requires_new: true) { Historico.where(id: event.id).update_all(operacao: "ADULTERADO") }
    end
  end
end
