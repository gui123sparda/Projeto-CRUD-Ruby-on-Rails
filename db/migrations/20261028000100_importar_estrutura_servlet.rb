# SQL original mantido para preservar enum, funções, triggers, índices e auditoria.
class ImportarEstruturaServlet < ActiveRecord::Migration[8.1]
  def up
    %w[001 002 003 004 006 007 008 010 011 012 013 014].each do |version|
      path = Dir[Rails.root.join("db/migrations/#{version}_*.sql")].fetch(0)
      sql = File.read(path).gsub(/^BEGIN;\s*$/, "").gsub(/^COMMIT;\s*$/, "")
      execute sql
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Auditoria preservada: restaure um backup para reverter."
  end
end
