require "test_helper"

class PlacaImagemTest < ActiveSupport::TestCase
  test "old plates preserve the narrow digit one on screen and in reports" do
    owner = Proprietario.new(nome: "Teste", cidade: "Fortaleza", estado: "CE")
    presenter = PlacaImagem.new
    car = Veiculo.new(placa: "ABC1234", tipo: "CARRO", proprietario: owner)
    report = Vips::Image.new_from_buffer(presenter.renderizar_png(car), "")
    screen = Vips::Image.svgload_buffer(presenter.renderizar(car), scale: 2)

    [ screen, report ].each do |image|
      widths = [ 396, 486 ].map do |x|
        (image.crop(x, 70, 90, 150).extract_band(0) < 70).find_trim(background: [ 0 ])[2]
      end
      assert_operator widths.first, :>, 0
      assert_operator widths.first, :<, widths.last * 0.5,
        "O número 1 deve conservar sua largura estreita, sem ser esticado"
    end
  end

  test "old car plates keep a visible gap between every character in report images" do
    owner = Proprietario.new(nome: "Teste", cidade: "Fortaleza", estado: "CE")
    car = Veiculo.new(placa: "ABC1234", tipo: "CARRO", proprietario: owner)
    png = PlacaImagem.new.renderizar_png(car)
    image = Vips::Image.new_from_buffer(png, "")

    assert_equal [ 800, 260 ], [ image.width, image.height ]
    (1..7).each do |index|
      # Fronteiras entre as oito posições de ABC-1234, longe da tarjeta e bordas.
      gap = image.crop((18 + index * 45) * 2 - 2, 80, 4, 130).extract_band(0, n: 3)
      assert_operator gap.min, :>, 70, "Caracteres se encostam na posição #{index}"
    end
    assert_operator image.crop(349, 90, 4, 20).extract_band(0, n: 3).min, :>, 70,
      "O hífen deve manter sua altura original"
    assert_operator image.crop(349, 135, 4, 4).extract_band(0, n: 3).max, :<, 70,
      "O hífen deve aparecer no centro da placa"
  end
end
