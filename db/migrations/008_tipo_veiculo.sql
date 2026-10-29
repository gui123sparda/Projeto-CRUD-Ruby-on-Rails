-- Executar após 007. Veículos existentes são classificados como carro e podem ser editados.
BEGIN;

CREATE TYPE treino.tipo_veiculo AS ENUM ('CARRO', 'MOTO');

ALTER TABLE treino.veiculo
    ADD COLUMN tipo treino.tipo_veiculo NOT NULL DEFAULT 'CARRO';

GRANT USAGE ON TYPE treino.tipo_veiculo TO role_getran, role_getran_readonly;

DROP FUNCTION treino.consultar_placa(TEXT);
CREATE FUNCTION treino.consultar_placa(p_placa TEXT)
RETURNS TABLE (
    id_veiculo INTEGER,
    placa VARCHAR(7),
    renavam VARCHAR(11),
    chassi VARCHAR(17),
    ano_fabricacao INTEGER,
    tipo TEXT,
    id_proprietario INTEGER,
    nome_proprietario VARCHAR(150),
    cpf_cnpj VARCHAR(14),
    rua_proprietario VARCHAR(150),
    numero_proprietario VARCHAR(20),
    cep_proprietario VARCHAR(8),
    cidade_proprietario VARCHAR(100),
    estado_proprietario VARCHAR(2),
    complemento_proprietario VARCHAR(255)
)
LANGUAGE SQL STABLE
AS $funcao$
    SELECT v.id, v.placa, v.renavam, v.chassi, v.ano_fabricacao,
           v.tipo::text, p.id, p.nome, p.cpf_cnpj, p.rua, p.numero, p.cep,
           p.cidade, p.estado, p.complemento
    FROM treino.veiculo AS v
    JOIN treino.proprietario AS p ON p.id = v.id_proprietario
    WHERE v.placa = upper(replace(btrim(p_placa), '-', ''))
$funcao$;

REVOKE ALL ON FUNCTION treino.consultar_placa(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION treino.consultar_placa(TEXT)
    TO role_getran, role_getran_readonly;

COMMIT;
