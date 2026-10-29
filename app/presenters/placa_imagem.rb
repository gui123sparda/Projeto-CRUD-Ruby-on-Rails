require "base64"
require "cgi"
require "vips"

# SVG autossuficiente: glifos FE e fonte Mandatory copiados do Servlet.
class PlacaImagem
  def renderizar_png(record)
    # O SVG é produzido por este presenter, com recursos locais e texto escapado.
    # Libera apenas o leitor de SVG em memória, bloqueado por padrão pelo Rails.
    Vips.block("VipsForeignLoadSvgBuffer", false)
    Vips::Image.svgload_buffer(renderizar(record), scale: 2).pngsave_buffer
  end

  def renderizar(record)
    plate = record.placa
    modern = plate[4].match?(/[A-Z]/)
    moto = record.tipo == "MOTO"
    width = moto ? 200 : modern ? 520 : 400
    height = moto ? 170 : modern ? 140 : 130
    band = modern ? (moto ? 25 : 28) : (moto ? 24 : 25)
    parts = [ "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 #{width} #{height}' role='img' aria-label='Placa ilustrativa #{plate}'>",
      "<defs><linearGradient id='b' x2='0' y2='1'><stop stop-color='#d2d5d6'/><stop offset='1' stop-color='#676b6c'/></linearGradient><linearGradient id='p' x2='0' y2='1'><stop stop-color='#{modern ? '#fff' : '#dadcd8'}'/><stop offset='1' stop-color='#{modern ? '#f1f2ed' : '#a4a8a3'}'/></linearGradient>#{relevo_caracteres}</defs>",
      "<rect width='#{width}' height='#{height}' rx='16' fill='url(#b)'/><rect x='2' y='2' width='#{width - 4}' height='#{height - 4}' rx='14' fill='url(#p)'/><rect x='4' y='4' width='#{width - 8}' height='#{height - 8}' rx='12' fill='none' stroke='#3a3c3a' stroke-width='#{modern ? 1 : 2}'/>" ]
    if modern
      parts << "<path d='M16 3H#{width - 16}Q#{width - 3} 3 #{width - 3} 16V#{band + 3}H3V16Q3 3 16 3' fill='#003095'/><text x='#{width / 2}' y='#{band - 6}' fill='white' font-family='sans-serif' font-weight='bold' font-size='#{moto ? 12 : 18}' text-anchor='middle'>BRASIL</text><text x='#{moto ? 9 : 16}' y='#{band - 4}' fill='white' font-family='sans-serif' font-size='#{moto ? 4 : 6}'>MERCOSUL</text>"
      x = width - (moto ? 34 : 49)
      fw = moto ? 25 : 34
      fh = moto ? 15 : 20
      parts << "<svg x='#{x}' y='7' width='#{fw}' height='#{fh}' viewBox='0 0 34 20'><rect width='34' height='20' fill='#009739'/><path d='M17 2L32 10 17 18 2 10Z' fill='#ffdf00'/><circle cx='17' cy='10' r='5' fill='#002776'/><path d='M13 9L21 11' stroke='white'/></svg><text x='#{moto ? 9 : 12}' y='#{height - 8}' font-family='sans-serif' font-weight='bold' font-size='#{moto ? 8 : 10}'>BR</text>"
      parts << "<image x='#{moto ? 8 : 11}' y='#{band + 8}' width='#{moto ? 15 : 20}' height='#{moto ? 15 : 20}' href='data:image/svg+xml;base64,#{Base64.strict_encode64(File.binread(Rails.public_path.join('img/qr-ilustrativo.svg')))}'/>"
    else
      owner = record.proprietario
      location = CGI.escapeHTML([ owner.estado.presence || "UF", owner.cidade.presence || "MUNICÍPIO" ].join(" - "))
      parts << "<rect x='#{moto ? 10 : 42}' y='8' width='#{width - (moto ? 20 : 84)}' height='18' rx='3' fill='#cdcfca' stroke='#7d817e'/><text x='#{width / 2}' y='21' font-family='sans-serif' font-weight='bold' font-size='#{moto ? 9 : 12}' text-anchor='middle'>#{location}</text>"
    end
    if moto
      parts << caracteres(plate[0, 3], modern ? 34 : 24, band + 7, width - (modern ? 45 : 48), 58, modern)
      parts << caracteres(plate[3, 4], 14, band + 69, width - 28, 61, modern)
    else
      text = modern ? plate : "#{plate[0, 3]}-#{plate[3, 4]}"
      parts << caracteres(text, modern ? 46 : 18, band + 10, width - (modern ? 60 : 36), modern ? 94 : 73, modern)
    end
    inset = moto ? 40 : modern ? 90 : 32
    [ inset, width - inset ].each { |x| parts << "<circle cx='#{x}' cy='8' r='3' fill='#b4b7b7' stroke='#525252'/><path d='M#{x - 1} 6L#{x + 1} 10' stroke='#525252' stroke-width='.7'/>" }
    parts << "</svg>"
    parts.join
  end

  private

  def relevo_caracteres
    # Luz acima à esquerda e lateral escura abaixo à direita: letras em alto-relevo.
    <<~SVG
      <filter id='relevo-caracteres' x='-10%' y='-10%' width='120%' height='120%' color-interpolation-filters='sRGB'>
        <feGaussianBlur in='SourceAlpha' stdDeviation='.7'/>
        <feOffset dx='1.5' dy='2' result='sombra'/>
        <feFlood flood-color='#000' flood-opacity='.45'/>
        <feComposite in2='sombra' operator='in' result='sombra-colorida'/>
        <feOffset in='SourceAlpha' dx='-.7' dy='-.7' result='luz'/>
        <feFlood flood-color='#fff' flood-opacity='.9'/>
        <feComposite in2='luz' operator='in' result='luz-colorida'/>
        <feOffset in='SourceAlpha' dx='.7' dy='1' result='lateral'/>
        <feFlood flood-color='#464a47'/>
        <feComposite in2='lateral' operator='in' result='lateral-colorida'/>
        <feMerge>
          <feMergeNode in='sombra-colorida'/><feMergeNode in='luz-colorida'/>
          <feMergeNode in='lateral-colorida'/><feMergeNode in='SourceGraphic'/>
        </feMerge>
      </filter>
    SVG
  end

  def caracteres(text, x, y, width, height, modern)
    cell = width / text.length
    unless modern
      reference = Vips::Image.text("A", font: "Mandatory #{height * 2}",
        fontfile: Rails.root.join("app/assets/fonts/Mandatory.otf").to_s)
    end
    glyphs = text.chars.each_with_index.map do |char, index|
      glyph_width = [ cell * 0.83, height * 0.63 ].min
      if modern
        glyph = Base64.strict_encode64(File.binread(Rails.root.join("app/assets/fonts/fe-glyphs/#{char}.png")))
        "<image x='#{x + index * cell + (cell - glyph_width) / 2}' y='#{y}' width='#{glyph_width}' height='#{height}' preserveAspectRatio='none' href='data:image/png;base64,#{glyph}'/>"
      else
        # Usa os mesmos glifos na tela e nos relatórios, preservando a largura
        # natural de cada caractere, especialmente do número 1 e do hífen.
        mask = Vips::Image.text(char, font: "Mandatory #{height * 2}",
          fontfile: Rails.root.join("app/assets/fonts/Mandatory.otf").to_s)
        glyph = Base64.strict_encode64(mask.new_from_image([ 16, 18, 17 ]).bandjoin(mask).pngsave_buffer)
        ink_width = glyph_width * mask.width / reference.width
        ink_height = height.to_f * mask.height / reference.height
        ink_y = y + height.to_f * (mask.yoffset - reference.yoffset) / reference.height
        "<image x='#{x + index * cell + (cell - ink_width) / 2}' y='#{ink_y}' width='#{ink_width}' height='#{ink_height}' preserveAspectRatio='none' href='data:image/png;base64,#{glyph}'/>"
      end
    end.join
    "<g filter='url(#relevo-caracteres)'>#{glyphs}</g>"
  end
end
