require "test_helper"

class FormulariosCadastrosTest < ActionDispatch::IntegrationTest
  setup do
    @protecao_anterior = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
  end

  teardown do
    ActionController::Base.allow_forgery_protection = @protecao_anterior
  end

  test "owner forms create and edit with CSRF protection enabled" do
    get "/proprietarios.do", params: { acao: "novo" }
    enviar_formulario("form[method=post]", cpfCnpj: "529.982.247-25", nome: "João Silva")
    assert_response :redirect
    owner = Proprietario.find_by!(cpf_cnpj: "52998224725")

    get "/proprietarios.do", params: { acao: "editar", id: owner.id }
    enviar_formulario("form[method=post]", cpfCnpj: owner.cpf_cnpj, nome: "João atualizado")
    assert_response :redirect
    assert_equal "JOÃO ATUALIZADO", owner.reload.nome

    get "/proprietarios.do"
    enviar_formulario("#form-excluir-proprietario", id: owner.id)
    assert_response :redirect
    assert_not_nil owner.reload.excluido_em
  end

  test "company forms accept numeric and alphanumeric CNPJ with CSRF protection enabled" do
    %w[11222333000181 12ABC34501DE35].each do |document|
      get "/proprietarios.do", params: { acao: "novo", tipoPessoa: "PJ" }
      enviar_formulario("form[method=post]", cpfCnpj: document, nome: "Empresa teste")
      assert_response :redirect
      assert_equal "EMPRESA TESTE", Proprietario.find_by!(cpf_cnpj: document).nome
    end
  end

  test "vehicle forms create edit and delete from the list with CSRF protection enabled" do
    owner = criar_proprietario
    get "/veiculos.do", params: { acao: "novo" }
    enviar_formulario("form[method=post]", placa: "abc1d23", renavam: "12345678901",
      chassi: "9BWZZZ377VT004251", anoFabricacao: "2024", idProprietario: owner.id, tipo: "CARRO")
    assert_response :redirect
    vehicle = Veiculo.find_by!(placa: "ABC1D23")

    get "/veiculos.do", params: { acao: "editar", id: vehicle.id }
    enviar_formulario("form[method=post]", placa: vehicle.placa, renavam: vehicle.renavam,
      chassi: vehicle.chassi, anoFabricacao: "2025", idProprietario: owner.id, tipo: "MOTO")
    assert_response :redirect
    assert_equal 2025, vehicle.reload.ano_fabricacao
    assert_equal "MOTO", vehicle.tipo

    get "/veiculos.do"
    enviar_formulario("form[method=post]")
    assert_response :redirect
    assert_not_nil vehicle.reload.excluido_em
  end

  test "vehicle deletion from owner details includes a valid CSRF token" do
    owner = criar_proprietario
    vehicle = Veiculo.create!(placa: "ABC1D23", renavam: "12345678901", chassi: "9BWZZZ377VT004251",
      ano_fabricacao: 2024, id_proprietario: owner.id, tipo: "CARRO")
    get "/proprietarios.do", params: { acao: "veiculos", id: owner.id }
    enviar_formulario("form[method=post]")
    assert_response :redirect
    assert_not_nil vehicle.reload.excluido_em
  end

  private

  def criar_proprietario
    Proprietario.create!(cpf_cnpj: "52998224725", nome: "João Silva")
  end

  def enviar_formulario(selector, values = {})
    form = css_select(selector).first
    assert_not_nil form, "Formulário não encontrado: #{selector}"
    fields = form.css("input[type=hidden][name]").to_h { |input| [ input["name"], input["value"] ] }
    post form["action"], params: fields.merge(values.stringify_keys)
  end
end
