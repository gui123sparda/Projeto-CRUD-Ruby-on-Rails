# Carga opcional, idempotente e compatível com a estrutura atual.
if ENV["SEED_DEMO"] == "true"
  sql = Rails.root.join("db/migrations/009_dados_demonstracao.sql").read
  sql = sql.gsub(/^BEGIN;\s*$/, "").gsub(/^COMMIT;\s*$/, "")
  ActiveRecord::Base.transaction { ActiveRecord::Base.connection.execute(sql) }
end
