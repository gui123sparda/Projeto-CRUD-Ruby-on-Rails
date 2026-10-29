class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  layout false
  rescue_from ActiveRecord::RecordNotFound, with: :nao_encontrado
  rescue_from ArgumentError, Date::Error, with: :parametro_invalido

  private

  def enviar_relatorio(titulo, registros, agrupado: false)
    pdf = RelatorioPdf.new.renderizar(titulo, registros, agrupado: agrupado)
    send_data pdf, type: "application/pdf", disposition: "inline", filename: "relatorio-#{params[:relatorio]}.pdf"
  end

  def filtros
    @filtros ||= FiltrosConsulta.ler(params)
  end

  def paginar(page)
    @total = page.total
    @paginas = page.paginas
    @pagina = page.numero
    @filtro_url = filtros.reject { |_, value| value.blank? }.to_query.then { |query| query.empty? ? "" : "&#{query}" }
    page.registros
  end

  def mensagem
    @mensagem = flash[:notice]
  end

  def nao_encontrado
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

  def parametro_invalido(error)
    render plain: error.message, status: :bad_request
  end
end
