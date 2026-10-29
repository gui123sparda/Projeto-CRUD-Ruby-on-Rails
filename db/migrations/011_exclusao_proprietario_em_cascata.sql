-- Permite excluir atomicamente os veículos vinculados ao apagar um proprietário.
BEGIN;

ALTER TABLE treino.veiculo
    DROP CONSTRAINT veiculo_id_proprietario_fkey;

ALTER TABLE treino.veiculo
    ADD CONSTRAINT veiculo_id_proprietario_fkey
    FOREIGN KEY (id_proprietario)
    REFERENCES treino.proprietario (id)
    ON DELETE CASCADE;

COMMIT;
