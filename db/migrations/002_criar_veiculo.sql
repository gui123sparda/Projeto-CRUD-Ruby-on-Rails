-- Depende de 001_criar_proprietario.sql.
BEGIN;

CREATE TABLE treino.veiculo (
    id              SERIAL PRIMARY KEY,
    placa           VARCHAR(7) NOT NULL UNIQUE,
    renavam         VARCHAR(11) NOT NULL UNIQUE,
    chassi          VARCHAR(17) NOT NULL UNIQUE,
    ano_fabricacao  INTEGER NOT NULL,
    id_proprietario INTEGER NOT NULL REFERENCES treino.proprietario (id)
);

CREATE INDEX idx_veiculo_id_proprietario
    ON treino.veiculo (id_proprietario);

COMMIT;
