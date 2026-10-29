require "prawn"

# Apresentação de documentos com os recursos e dimensões dos JRXML originais.
class RelatorioPdf
  include ApplicationHelper

  def renderizar(title, records, agrupado: false)
    pdf = Prawn::Document.new(page_size: "A4", margin: [ 32, 36, 50, 36 ])
    fonts = Rails.root.join("app/assets/fonts")
    pdf.font_families.update("Kanit" => { normal: fonts.join("Kanit-Regular.ttf"), bold: fonts.join("Kanit-Bold.ttf") }, "Maitree" => { normal: fonts.join("Maitree-Regular.ttf") })
    pdf.font("Kanit")
    pdf.image Rails.public_path.join("img/BRASAO_DETRAN.png"), at: [ 30, pdf.cursor - 24 ], fit: [ 51, 58 ]
    pdf.image Rails.public_path.join("img/LOGO_ESTADO_CE.png"), at: [ 255, pdf.cursor - 8 ], fit: [ 238, 76 ]
    pdf.move_down 98
    pdf.fill_color "465564"
    pdf.text title, size: 20, style: :bold
    pdf.text Time.current.strftime("%d/%m/%Y %H:%M"), size: 9
    pdf.move_down 16
    pdf.font("Maitree", size: 9)
    pdf.text "Total: #{records.length} registros"
    pdf.move_down 12
    pdf.text "Nenhum registro encontrado para os filtros informados." if records.empty?
    records.each do |record|
      desenhar_placa(pdf, record) if record.is_a?(Veiculo)
      fields = campos(record)
      fields.each do |label, value|
        pdf.text "#{label}: #{value}", leading: 3
      end
      if agrupado
        record.veiculos.select { |v| v.excluido_em.nil? }.each do |vehicle|
          desenhar_placa(pdf, vehicle)
          pdf.text "#{vehicle.placa} · #{vehicle.tipo_rotulo} · #{vehicle.renavam} · #{vehicle.chassi} · #{vehicle.ano_fabricacao}", indent_paragraphs: 12
          pdf.move_down 6
        end
      end
      pdf.move_down 10
      pdf.stroke_color "D9E1EA"
      pdf.stroke_horizontal_rule
      pdf.move_down 10
    end
    pdf.repeat(:all) do
      pdf.image Rails.public_path.join("img/RODAPE.png"), at: [ 0, -8 ], fit: [ 523, 24 ]
    end
    pdf.number_pages "Página <page> de <total>", at: [ 400, -30 ], width: 123, align: :right, size: 8
    pdf.render
  end

  private

  def desenhar_placa(pdf, vehicle)
    png = PlacaImagem.new.renderizar_png(vehicle)
    pdf.image StringIO.new(png), fit: [ 220, 95 ]
    pdf.move_down 6
  end

  def campos(record)
    case record
    when Proprietario
      { "CPF/CNPJ" => formatar_documento(record.cpf_cnpj), "Nome / razão social" => record.nome, "Endereço" => formatar_endereco(record) }
    when Veiculo
      { "Placa" => record.placa, "Tipo" => record.tipo_rotulo, "RENAVAM" => record.renavam, "Chassi" => record.chassi, "Ano" => record.ano_fabricacao, "Proprietário" => record.proprietario.nome }
    when Historico
      { "Data" => record.ocorrido_em.in_time_zone.strftime("%d/%m/%Y %H:%M:%S"), "Cadastro / ID" => "#{record.entidade} / #{record.registro_id}", "Operação" => record.operacao, "Antes" => JSON.pretty_generate(record.antes), "Depois" => JSON.pretty_generate(record.depois), "Usuário do banco" => record.usuario_banco }
    end
  end
end
