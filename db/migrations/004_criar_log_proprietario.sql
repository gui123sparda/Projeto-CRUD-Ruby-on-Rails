-- Depende de 001_criar_proprietario.sql e 003_conceder_permissoes.sql.
-- Sem chave estrangeira: o registro de log permanece após excluir o proprietário.
BEGIN;

CREATE TABLE treino.log_proprietario (
    id              SERIAL PRIMARY KEY,
    id_proprietario INTEGER NOT NULL UNIQUE,
    cpf_cnpj        VARCHAR(14) NOT NULL,
    data_criacao    TIMESTAMP(0) NOT NULL,
    data_alteracao  TIMESTAMP(0)
);

-- O usuário da aplicação pode consultar o histórico, mas só o trigger o altera.
GRANT SELECT ON TABLE treino.log_proprietario
    TO role_getran, role_getran_readonly;

CREATE FUNCTION treino.pkg_proprietario___registrar_log()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, treino
AS $function$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO treino.log_proprietario
            (id_proprietario, cpf_cnpj, data_criacao)
        VALUES (NEW.id, NEW.cpf_cnpj, CURRENT_TIMESTAMP);
    ELSIF TG_OP = 'UPDATE' THEN
        -- Também cobre proprietários cadastrados antes da instalação do trigger.
        -- Nesse caso, data_criacao registra o início do histórico disponível.
        INSERT INTO treino.log_proprietario
            (id_proprietario, cpf_cnpj, data_criacao, data_alteracao)
        VALUES (NEW.id, NEW.cpf_cnpj, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        ON CONFLICT (id_proprietario) DO UPDATE
            SET cpf_cnpj = EXCLUDED.cpf_cnpj,
                data_alteracao = EXCLUDED.data_alteracao;
    END IF;

    RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION treino.pkg_proprietario___registrar_log() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION treino.pkg_proprietario___registrar_log() TO role_getran;

CREATE TRIGGER trg_proprietario_log
AFTER INSERT OR UPDATE ON treino.proprietario
FOR EACH ROW
EXECUTE FUNCTION treino.pkg_proprietario___registrar_log();

COMMIT;
