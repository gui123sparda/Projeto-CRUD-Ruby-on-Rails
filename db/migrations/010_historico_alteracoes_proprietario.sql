-- Mantém cada alteração para permitir o histórico diário no dashboard.
-- Execute após 004_criar_log_proprietario.sql.
BEGIN;

ALTER TABLE treino.log_proprietario
    DROP CONSTRAINT log_proprietario_id_proprietario_key;

CREATE INDEX idx_log_proprietario_id_proprietario
    ON treino.log_proprietario (id_proprietario);
CREATE INDEX idx_log_proprietario_data_criacao
    ON treino.log_proprietario (data_criacao);
CREATE INDEX idx_log_proprietario_data_alteracao
    ON treino.log_proprietario (data_alteracao);

CREATE OR REPLACE FUNCTION treino.pkg_proprietario___registrar_log()
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
        -- Repete a data de cadastro para manter o modelo atual e acrescenta
        -- uma linha por alteração. COUNT(DISTINCT id_proprietario) evita
        -- contar o cadastro repetido nas consultas diárias.
        INSERT INTO treino.log_proprietario
            (id_proprietario, cpf_cnpj, data_criacao, data_alteracao)
        VALUES (
            NEW.id,
            NEW.cpf_cnpj,
            COALESCE(
                (SELECT MIN(data_criacao)
                   FROM treino.log_proprietario
                  WHERE id_proprietario = NEW.id),
                CURRENT_TIMESTAMP
            ),
            CURRENT_TIMESTAMP
        );
    END IF;

    RETURN NEW;
END;
$function$;

COMMIT;
