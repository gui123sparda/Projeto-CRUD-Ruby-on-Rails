-- Estrutura inicial de proprietários usada por ibatis/proprietario.xml.
BEGIN;

CREATE SCHEMA IF NOT EXISTS treino;

CREATE TABLE treino.proprietario (
    id       SERIAL PRIMARY KEY,
    cpf_cnpj VARCHAR(14) NOT NULL UNIQUE,
    nome     VARCHAR(150) NOT NULL,
    endereco VARCHAR(255)
);

COMMIT;
