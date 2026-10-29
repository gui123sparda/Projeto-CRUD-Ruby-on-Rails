-- Retorna os dados de um veículo e de seu proprietário a partir da placa.
-- Depende das migrations 001, 002 e 003.
BEGIN;

CREATE OR REPLACE FUNCTION treino.consultar_placa(p_placa TEXT)
RETURNS TABLE (
    id_veiculo INTEGER,
    placa VARCHAR(7),
    renavam VARCHAR(11),
    chassi VARCHAR(17),
    ano_fabricacao INTEGER,
    id_proprietario INTEGER,
    nome_proprietario VARCHAR(150),
    cpf_cnpj VARCHAR(14),
    endereco_proprietario VARCHAR(255)
)
LANGUAGE SQL
STABLE
AS $funcao$
    SELECT v.id, v.placa, v.renavam, v.chassi, v.ano_fabricacao,
           p.id, p.nome, p.cpf_cnpj, p.endereco
    FROM treino.veiculo AS v
    JOIN treino.proprietario AS p ON p.id = v.id_proprietario
    WHERE v.placa = upper(replace(btrim(p_placa), '-', ''))
$funcao$;

REVOKE ALL ON FUNCTION treino.consultar_placa(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION treino.consultar_placa(TEXT)
    TO role_getran, role_getran_readonly;

COMMIT;
