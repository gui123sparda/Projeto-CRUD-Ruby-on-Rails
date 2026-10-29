# Inclui public (metadados Rails/extensão unaccent) e treino (domínio/triggers).
# --clean/--if-exists permite restaurar public, criado automaticamente pelo PG.
ActiveRecord::Tasks::DatabaseTasks.structure_dump_flags = [ "--clean", "--if-exists" ]
