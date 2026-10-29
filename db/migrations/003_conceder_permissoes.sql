-- Depende de 001_criar_proprietario.sql e 002_criar_veiculo.sql.
-- Os papéis são NOLOGIN; usuários da aplicação podem receber associação a eles.
BEGIN;

DO $roles$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_getran') THEN
        CREATE ROLE role_getran NOLOGIN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_getran_readonly') THEN
        CREATE ROLE role_getran_readonly NOLOGIN;
    END IF;
END;
$roles$;

GRANT USAGE ON SCHEMA treino TO role_getran, role_getran_readonly;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE
    treino.proprietario,
    treino.veiculo
TO role_getran;

GRANT USAGE, SELECT ON SEQUENCE
    treino.proprietario_id_seq,
    treino.veiculo_id_seq
TO role_getran;

GRANT SELECT ON TABLE
    treino.proprietario,
    treino.veiculo
TO role_getran_readonly;

COMMIT;
