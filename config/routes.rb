Rails.application.routes.draw do
  root "log_proprietarios#index"
  get "up" => "rails/health#show", as: :rails_health_check
  get "proprietarios.do" => "proprietarios#index"
  post "proprietarios.do" => "proprietarios#create"
  get "veiculos.do" => "veiculos#index"
  post "veiculos.do" => "veiculos#create"
  get "historico.do" => "historicos#index"
  get "historico-veiculos.do" => "historicos#index"
  get "placa-imagem.do" => "veiculos#placa"
  {
    "proprietarios" => %w[proprietario proprietarios agrupado],
    "veiculos" => %w[veiculo veiculos],
    "historicos" => %w[historico historico-veiculos]
  }.each do |controller, nomes|
    nomes.each do |nome|
      get "relatorio-#{nome}.do", to: "#{controller}#relatorio", defaults: { relatorio: nome }
    end
  end
end
