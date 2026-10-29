-- Divide o endereço do proprietário sem descartar os endereços antigos.
-- Execute após 001 a 004 e, se desejado, após os dados fictícios de 005.
BEGIN;

ALTER TABLE treino.proprietario
    ADD COLUMN rua VARCHAR(150),
    ADD COLUMN numero VARCHAR(20),
    ADD COLUMN cep VARCHAR(8),
    ADD COLUMN cidade VARCHAR(100),
    ADD COLUMN estado VARCHAR(2),
    ADD COLUMN complemento VARCHAR(255);

-- O endereço anterior não tem estrutura confiável para separar as partes.
UPDATE treino.proprietario
SET complemento = endereco
WHERE endereco IS NOT NULL AND btrim(endereco) <> '';

-- A função é recriada para retornar os campos separados do proprietário.
DROP FUNCTION IF EXISTS treino.consultar_placa(TEXT);
ALTER TABLE treino.proprietario DROP COLUMN endereco;

CREATE FUNCTION treino.consultar_placa(p_placa TEXT)
RETURNS TABLE (
    id_veiculo INTEGER,
    placa VARCHAR(7),
    renavam VARCHAR(11),
    chassi VARCHAR(17),
    ano_fabricacao INTEGER,
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
LANGUAGE SQL
STABLE
AS $funcao$
    SELECT v.id, v.placa, v.renavam, v.chassi, v.ano_fabricacao,
           p.id, p.nome, p.cpf_cnpj, p.rua, p.numero, p.cep,
           p.cidade, p.estado, p.complemento
    FROM treino.veiculo AS v
    JOIN treino.proprietario AS p ON p.id = v.id_proprietario
    WHERE v.placa = upper(replace(btrim(p_placa), '-', ''))
$funcao$;

REVOKE ALL ON FUNCTION treino.consultar_placa(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION treino.consultar_placa(TEXT)
    TO role_getran, role_getran_readonly;

COMMIT;
