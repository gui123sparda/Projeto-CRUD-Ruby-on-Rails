require "test_helper"

class DashboardTest < ActiveSupport::TestCase
  test "vehicle totals count only active vehicles with active owners" do
    owner = ProprietarioFacade.new.salvar(Proprietario.new(cpf_cnpj: "52998224725", nome: "Teste"))
    car = VeiculoFacade.new.salvar(Veiculo.new(placa: "ABC1D23", renavam: "12345678901", chassi: "9BWZZZ377VT004251", ano_fabricacao: 2024, id_proprietario: owner.id, tipo: "CARRO"))
    assert_equal({ total_veiculos: 1, total_carros: 1, total_motos: 0 }, VeiculoFacade.new.totais)
    assert_equal 1, ProprietarioFacade.new.total
    VeiculoFacade.new.excluir(car.id)
    assert_equal({ total_veiculos: 0, total_carros: 0, total_motos: 0 }, VeiculoFacade.new.totais)
    ProprietarioFacade.new.excluir(owner.id)
    assert_equal 0, ProprietarioFacade.new.total
  end

  test "daily activity uses Fortaleza day boundaries for UTC legacy timestamps" do
    travel_to Time.zone.local(2026, 10, 28, 9) do
      LogProprietario.connection.execute(<<~SQL)
        INSERT INTO treino.log_proprietario (id_proprietario, cpf_cnpj, data_criacao, data_alteracao)
        VALUES (42, '52998224725', '2026-10-28 01:30:00', '2026-10-28 02:00:00')
      SQL
      days = LogProprietarioFacade.new.resumo_diario("")
      previous = days.find { |day| day.dia == Date.new(2026, 10, 27) }
      today = days.find { |day| day.dia == Date.new(2026, 10, 28) }
      assert_equal 1, previous.cadastros
      assert_equal 1, previous.alteracoes
      assert_equal 0, today.cadastros
    end
  end
end
