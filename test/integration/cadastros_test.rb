require "test_helper"

class CadastrosTest < ActionDispatch::IntegrationTest
  def owner
    ProprietarioFacade.new.salvar(Proprietario.new(cpf_cnpj: "52998224725", nome: "João Silva", cidade: "Fortaleza", estado: "CE"))
  end

  def vehicle(proprietario)
    VeiculoFacade.new.salvar(Veiculo.new(placa: "abc-1d23", renavam: "12345678901", chassi: "9BWZZZ377VT004251", ano_fabricacao: 2024, id_proprietario: proprietario.id, tipo: "CARRO"))
  end

  test "dashboard and forms expose the original navigation and fields" do
    get "/"
    assert_response :success
    assert_select "h1", "Dashboard"
    assert_select ".dashboard-metric", 4
    get "/proprietarios.do", params: { acao: "novo" }
    assert_response :success
    assert_select "input#cpfCnpj"
    get "/veiculos.do", params: { acao: "novo" }
    assert_response :success
    assert_select "select#idProprietario"
  end

  test "owner CRUD normalizes data and refuses a changed document" do
    post "/proprietarios.do", params: { acao: "salvar", cpfCnpj: "529.982.247-25", nome: "João Silva" }
    assert_response :redirect
    record = Proprietario.find_by!(cpf_cnpj: "52998224725")
    assert_equal "JOÃO SILVA", record.nome
    post "/proprietarios.do", params: { acao: "salvar", id: record.id, cpfCnpj: "11144477735", nome: "Outro nome" }
    assert_response :unprocessable_entity
    assert_equal "52998224725", record.reload.cpf_cnpj
  end

  test "vehicle CRUD persists edits and plate lookup joins the owner" do
    person = owner
    post "/veiculos.do", params: { acao: "salvar", placa: "abc-1d23", renavam: "12345678901", chassi: "9BWZZZ377VT004251", anoFabricacao: "2024", idProprietario: person.id, tipo: "MOTO" }
    assert_response :redirect
    record = Veiculo.find_by!(placa: "ABC1D23")
    get "/veiculos.do", params: { acao: "consultarPlaca", placa: "abc-1d23" }
    assert_response :success
    assert_select "#consulta-resultado", text: /JOÃO SILVA/
    post "/veiculos.do", params: { acao: "salvar", id: record.id, placa: "ABC1D23", renavam: record.renavam, chassi: record.chassi, anoFabricacao: "2025", idProprietario: person.id, tipo: "CARRO" }
    assert_equal 2025, record.reload.ano_fabricacao
    post "/veiculos.do", params: { acao: "excluir", id: record.id }
    assert_response :redirect
    assert_not_nil record.reload.excluido_em
  end

  test "owner deletion requires confirmation and atomically inactivates vehicles with audit" do
    person = owner
    car = vehicle(person)
    post "/proprietarios.do", params: { acao: "excluir", id: person.id }
    assert_response :conflict
    assert_nil person.reload.excluido_em
    post "/proprietarios.do", params: { acao: "excluir", id: person.id, confirmarCascata: "true", totalVeiculosConfirmado: "1" }
    assert_response :redirect
    assert_not_nil person.reload.excluido_em
    assert_equal person.excluido_em, car.reload.excluido_em
    assert Historico.exists?(entidade: "veiculo", registro_id: car.id, operacao: "EXCLUSAO_LOGICA")
    get "/veiculos.do", params: { acao: "consultarPlaca", placa: car.placa }
    assert_select "#consulta-resultado", 0
  end

  test "accent insensitive filters and owner detail use real persisted data" do
    person = owner
    vehicle(person)
    get "/proprietarios.do", params: { campo: "nome", valor: "joao" }
    assert_response :success
    assert_select "td", text: "JOÃO SILVA"
    get "/proprietarios.do", params: { acao: "visualizar", id: person.id }
    assert_response :success
    assert_select ".owner-vehicle", 1
    get "/historico.do"
    assert_response :success
    assert_match "CADASTRO", response.body
    get "/relatorio-veiculos.do"
    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert response.body.start_with?("%PDF")
  end

  test "all populated screens, plates and report endpoints render" do
    person = owner
    car = vehicle(person)
    [ "/", "/veiculos.do", "/veiculos.do?acao=editar&id=#{car.id}",
     "/proprietarios.do?acao=editar&id=#{person.id}",
     "/proprietarios.do?acao=veiculos&id=#{person.id}",
     "/historico-veiculos.do" ].each do |path|
      get path
      assert_response :success, path
    end
    get "/placa-imagem.do", params: { id: car.id }
    assert_response :success
    assert_equal "image/svg+xml", response.media_type
    assert_match "viewBox", response.body
    %w[proprietario proprietarios veiculo veiculos historico historico-veiculos agrupado].each do |report|
      get "/relatorio-#{report}.do", params: { id: report == "veiculo" ? car.id : person.id }
      assert_response :success, report
      assert_equal "application/pdf", response.media_type
    end
  end

  test "pagination keeps filters and search escapes wildcards and HTML" do
    documents = %w[90000000175 90000000256 90000000337 90000000418 90000000507 90000000680 90000000760 90000000841 90000000922 90000001066 90000001147 90000001228]
    documents.each_with_index do |document, index|
      ProprietarioFacade.new.salvar(Proprietario.new(cpf_cnpj: document, nome: "Pessoa #{index}"))
    end
    get "/proprietarios.do", params: { tipoPessoa: "PF", campo: "nome", valor: "pessoa", pagina: 2 }
    assert_response :success
    assert_select ".data-table tbody tr", 2
    assert_select "input[name=valor][value=PESSOA]"
    get "/proprietarios.do", params: { campo: "nome", valor: "%" }
    assert_select ".data-table tbody tr", 0
    record = ProprietarioFacade.new.salvar(Proprietario.new(cpf_cnpj: "52998224725", nome: "<script>alert(1)</script>"))
    get "/proprietarios.do", params: { acao: "visualizar", id: record.id }
    assert_response :success
    assert_includes response.body, "&lt;SCRIPT&gt;"
    assert_no_match(/<SCRIPT>alert/i, response.body)
  end

  test "vehicle and grouped PDFs include plate illustrations for both models and vehicle types" do
    person = owner
    [ [ "ABC1D23", "CARRO", 1040, 280 ], [ "ABC1234", "CARRO", 800, 260 ],
      [ "XYZ2E45", "MOTO", 400, 340 ], [ "XYZ2345", "MOTO", 400, 340 ] ].each_with_index do |(plate, type, width, height), index|
      car = VeiculoFacade.new.salvar(Veiculo.new(placa: plate, tipo: type, renavam: "1234567890#{index}",
        chassi: "9BWZZZ377VT00425#{index}", ano_fabricacao: 2024, id_proprietario: person.id))
      [ "/relatorio-veiculo.do?id=#{car.id}", "/relatorio-veiculos.do?placa=#{plate}",
        "/relatorio-agrupado.do?idProprietario=#{person.id}" ].each do |path|
        get path
        assert_response :success
        images = response.body.scan(/\d+ 0 obj\s(.*?)endobj/m).flatten.select { |object| object.include?("/Subtype /Image") }
        assert images.any? { |image| image.match?(/\/Width #{width}\b/) && image.match?(/\/Height #{height}\b/) },
          "Imagem da placa #{plate} ausente em #{path}"
      end
    end
  end

  test "complete report includes only the selected owners active vehicles and plates" do
    person = owner
    vehicle(person)
    other = ProprietarioFacade.new.salvar(Proprietario.new(cpf_cnpj: "11144477735", nome: "Maria Souza"))
    VeiculoFacade.new.salvar(Veiculo.new(placa: "XYZ1234", tipo: "CARRO", renavam: "12345678902",
      chassi: "9BWZZZ377VT004252", ano_fabricacao: 2024, id_proprietario: other.id))
    deleted = VeiculoFacade.new.salvar(Veiculo.new(placa: "DEF2345", tipo: "MOTO", renavam: "12345678903",
      chassi: "9BWZZZ377VT004253", ano_fabricacao: 2024, id_proprietario: person.id))
    VeiculoFacade.new.excluir(deleted.id)

    get "/proprietarios.do", params: { acao: "visualizar", id: person.id }
    assert_select "a[href=?]", "/relatorio-agrupado.do?idProprietario=#{person.id}", count: 1

    get "/relatorio-agrupado.do", params: { idProprietario: person.id }
    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert response.body.match?(%r{/Width 1040\b}), "Placa do proprietário ausente"
    assert_not response.body.match?(%r{/Width 800\b}), "Incluiu a placa de outro proprietário"
    assert_not response.body.match?(%r{/Width 400\b}), "Incluiu a placa de um veículo excluído"
  end

  test "complete report for an owner without vehicles does not include other owners plates" do
    vehicle(owner)
    person = ProprietarioFacade.new.salvar(Proprietario.new(cpf_cnpj: "11144477735", nome: "Maria Souza"))

    get "/relatorio-agrupado.do", params: { idProprietario: person.id }
    assert_response :success
    assert_not response.body.match?(%r{/Width 1040\b}), "Incluiu a placa de outro proprietário"
  end

  test "complete report requires an existing active owner" do
    get "/relatorio-agrupado.do"
    assert_response :not_found
    get "/relatorio-agrupado.do", params: { idProprietario: 999999 }
    assert_response :not_found
    person = owner
    ProprietarioFacade.new.excluir(person.id)
    get "/relatorio-agrupado.do", params: { idProprietario: person.id }
    assert_response :not_found
  end

  test "CSRF protection refuses a write without a valid form token" do
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    post "/proprietarios.do", params: { acao: "salvar", cpfCnpj: "52998224725", nome: "Teste" }
    assert_response :unprocessable_entity
    assert_equal 0, Proprietario.count
  ensure
    ActionController::Base.allow_forgery_protection = previous
  end

  test "invalid input is rejected without persistence and unknown IDs return 404" do
    post "/proprietarios.do", params: { acao: "salvar", cpfCnpj: "11111111111", nome: "Inválido" }
    assert_response :unprocessable_entity
    assert_equal 0, Proprietario.count
    get "/proprietarios.do", params: { acao: "editar", id: 999999 }
    assert_response :not_found
    get "/proprietarios.do", params: { campo: "nome); DROP TABLE treino.proprietario;--", valor: "x" }
    assert_response :bad_request
  end
end
