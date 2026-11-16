require "application_system_test_case"

class CadastrosSystemTest < ApplicationSystemTestCase
  test "vehicle owner search accepts names CPF and numeric or alphanumeric CNPJ" do
    owner = Proprietario.create!(nome: "João Silva", cpf_cnpj: "52998224725")
    company = Proprietario.create!(nome: "Empresa teste", cpf_cnpj: "11222333000181")
    alpha_company = Proprietario.create!(nome: "Empresa alfa", cpf_cnpj: "12ABC34501DE35")
    visit "/veiculos.do?acao=novo"

    { "joao" => owner, "529.982.247-25" => owner, "11.222.333/0001-81" => company,
      "12.abc.345/01de-35" => alpha_company }.each do |query, expected|
      fill_in "buscaProprietario", with: query
      assert_selector "#idProprietario option[value='#{expected.id}']", visible: :all
      assert_selector "#idProprietario option", count: 2, visible: :all
    end

    fill_in "buscaProprietario", with: "inexistente"
    assert_text "Nenhum proprietário encontrado."
    fill_in "buscaProprietario", with: ""
    assert_selector "#idProprietario option", count: 4, visible: :all
    select "JOÃO SILVA — 52998224725", from: "idProprietario"
    assert_selector "#dados-veiculo", visible: true
    fill_in "buscaProprietario", with: "empresa"
    assert_equal owner.id.to_s, find("#idProprietario").value
  end

  setup do
    @protecao_anterior = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
  end

  teardown do
    ActionController::Base.allow_forgery_protection = @protecao_anterior
  end

  test "user creates an owner and vehicle, queries plate, filters and confirms cascade" do
    visit "/proprietarios.do?acao=novo"
    fill_in "cpfCnpj", with: "52998224725"
    fill_in "nome", with: "João da Silva"
    fill_in "cidade", with: "Fortaleza"
    fill_in "estado", with: "CE"
    click_button "Salvar"
    assert_text "Proprietário salvo com sucesso."
    assert_text "JOÃO DA SILVA"
    visit "/veiculos.do?acao=novo"
    assert_no_selector "#dados-veiculo", visible: true
    select "JOÃO DA SILVA — 52998224725", from: "idProprietario"
    fill_in "placa", with: "abc1d23"
    fill_in "renavam", with: "12345678901"
    fill_in "chassi", with: "9BWZZZ377VT004251"
    fill_in "anoFabricacao", with: "2024"
    click_button "Salvar"
    assert_text "Veículo salvo com sucesso."
    within ".data-table" do
      click_link "Consultar placa"
    end
    assert_selector "#consulta-resultado"
    assert_text "JOÃO DA SILVA"
    assert_selector "img.placa-renderizada"
    visit "/proprietarios.do"
    fill_in "valor-filtro", with: "joao"
    click_button "Filtrar", exact: true
    assert_text "JOÃO DA SILVA"
    click_button "Excluir", exact: true
    assert_selector "#modal-confirmar-exclusao[open]"
    click_button "Continuar"
    assert_selector "#modal-confirmar-cascata[open]"
    click_button "Excluir proprietário e veículos"
    assert_text "Proprietário excluído logicamente."
    assert_no_text "JOÃO DA SILVA"
    visit "/historico-veiculos.do"
    assert_text "EXCLUSAO_LOGICA"
  end

  test "dashboard preserves the four indicators and adapts to mobile" do
    visit "/"
    assert_selector ".dashboard-metric", count: 4
    assert_selector ".dashboard-chart-day", count: 14
    assert_selector ".intro-overlay", visible: :all
    assert_selector ".intro-overlay", visible: :hidden, wait: 5
    save_screenshot(Rails.root.join("tmp/screenshots/dashboard-desktop.png"))
    page.driver.browser.manage.window.resize_to(390, 844)
    assert_selector ".mega-nav"
    assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, page.evaluate_script("window.innerWidth")
    save_screenshot(Rails.root.join("tmp/screenshots/dashboard-mobile.png"))
  ensure
    page.driver.browser.manage.window.resize_to(1440, 1100)
  end

  test "theme and generated fictitious form data work in a browser" do
    visit "/proprietarios.do?acao=novo&tipoPessoa=PJ"
    click_button "Gerar dados fictícios"
    assert_match(/EMPRESA FICTÍCIA/, find("#nome").value)
    assert find("#cpfCnpj").value.present?
    before = find("html")["data-theme"]
    find("#theme-toggle").click
    assert_no_selector "html[data-theme='#{before}']"
    click_button "Salvar"
    assert_text "Proprietário salvo com sucesso."
  end
end
