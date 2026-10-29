-- Aplicar após 011. Não remove nem recria registros existentes.
BEGIN;
ALTER TABLE treino.proprietario ADD COLUMN excluido_em timestamptz;
ALTER TABLE treino.veiculo ADD COLUMN excluido_em timestamptz;
ALTER TABLE treino.veiculo DROP CONSTRAINT veiculo_id_proprietario_fkey;
ALTER TABLE treino.veiculo ADD CONSTRAINT veiculo_id_proprietario_fkey
 FOREIGN KEY (id_proprietario) REFERENCES treino.proprietario(id) ON DELETE RESTRICT;

CREATE TABLE treino.historico (
 id bigserial PRIMARY KEY, entidade text NOT NULL, registro_id bigint NOT NULL,
 operacao text NOT NULL, ocorrido_em timestamptz NOT NULL DEFAULT clock_timestamp(),
 usuario_banco text NOT NULL DEFAULT session_user, antes jsonb, depois jsonb
);
CREATE INDEX historico_entidade_registro ON treino.historico(entidade,registro_id,ocorrido_em DESC);
CREATE INDEX historico_data ON treino.historico(ocorrido_em DESC,id DESC);
CREATE INDEX proprietario_ativo_nome ON treino.proprietario(nome) WHERE excluido_em IS NULL;
CREATE INDEX veiculo_ativo_proprietario ON treino.veiculo(id_proprietario) WHERE excluido_em IS NULL;

CREATE FUNCTION treino.proteger_cadastro() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE dono bigint;
BEGIN
 IF TG_OP = 'DELETE' THEN RAISE EXCEPTION 'Exclusão física proibida. Utilize exclusão lógica.' USING ERRCODE='23514'; END IF;
 IF TG_OP = 'UPDATE' AND OLD.excluido_em IS NOT NULL THEN
  RAISE EXCEPTION 'Registro inativo não pode ser alterado.' USING ERRCODE='23514';
 END IF;
 IF TG_TABLE_NAME = 'proprietario' THEN
  IF TG_OP = 'UPDATE' AND NEW.cpf_cnpj IS DISTINCT FROM OLD.cpf_cnpj THEN
   RAISE EXCEPTION 'CPF/CNPJ não pode ser alterado após o cadastro.' USING ERRCODE='23514';
  END IF;
  NEW.nome=upper(NEW.nome); NEW.rua=upper(NEW.rua); NEW.numero=upper(NEW.numero);
  NEW.cidade=upper(NEW.cidade); NEW.estado=upper(NEW.estado); NEW.complemento=upper(NEW.complemento);
 ELSE
  NEW.placa=upper(NEW.placa); NEW.chassi=upper(NEW.chassi);
  IF NEW.excluido_em IS NULL THEN
   -- Bloqueio comum com a inativação do proprietário evita vínculos concorrentes.
   SELECT id INTO dono FROM treino.proprietario WHERE id=NEW.id_proprietario AND excluido_em IS NULL FOR UPDATE;
   IF dono IS NULL THEN RAISE EXCEPTION 'Selecione um proprietário ativo.' USING ERRCODE='23503'; END IF;
  END IF;
 END IF;
 RETURN NEW;
END $$;
CREATE FUNCTION treino.auditar_cadastro() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,treino AS $$
BEGIN
 INSERT INTO treino.historico(entidade,registro_id,operacao,antes,depois)
 VALUES(TG_TABLE_NAME,NEW.id,CASE WHEN TG_OP='INSERT' THEN 'CADASTRO'
 WHEN NEW.excluido_em IS NOT NULL AND OLD.excluido_em IS NULL THEN 'EXCLUSAO_LOGICA' ELSE 'ALTERACAO' END,
 CASE WHEN TG_OP='INSERT' THEN NULL ELSE to_jsonb(OLD) END,to_jsonb(NEW));
 IF TG_TABLE_NAME='proprietario' AND NEW.excluido_em IS NOT NULL AND OLD.excluido_em IS NULL THEN
  UPDATE treino.veiculo SET excluido_em=NEW.excluido_em WHERE id_proprietario=NEW.id AND excluido_em IS NULL;
 END IF;
 RETURN NEW;
END $$;
-- Logs legados são preservados como eventos parciais, sem inventar snapshots.
INSERT INTO treino.historico(entidade,registro_id,operacao,ocorrido_em,depois)
 SELECT 'proprietario',id_proprietario,'LEGADO',coalesce(data_alteracao,data_criacao),
 jsonb_build_object('origem','log_proprietario','log_id',id,'cpf_cnpj',cpf_cnpj,
 'data_criacao',data_criacao,'data_alteracao',data_alteracao,'observacao','Log legado parcial; dados completos indisponíveis')
 FROM treino.log_proprietario;
-- Marco inicial: não inventar versões anteriores à implantação.
INSERT INTO treino.historico(entidade,registro_id,operacao,depois)
 SELECT 'proprietario',id,'MARCO_INICIAL',to_jsonb(p) FROM treino.proprietario p;
INSERT INTO treino.historico(entidade,registro_id,operacao,depois)
 SELECT 'veiculo',id,'MARCO_INICIAL',to_jsonb(v) FROM treino.veiculo v;
CREATE TRIGGER proteger_proprietario BEFORE INSERT OR UPDATE OR DELETE ON treino.proprietario FOR EACH ROW EXECUTE PROCEDURE treino.proteger_cadastro();
CREATE TRIGGER proteger_veiculo BEFORE INSERT OR UPDATE OR DELETE ON treino.veiculo FOR EACH ROW EXECUTE PROCEDURE treino.proteger_cadastro();
CREATE TRIGGER auditar_proprietario AFTER INSERT OR UPDATE ON treino.proprietario FOR EACH ROW EXECUTE PROCEDURE treino.auditar_cadastro();
CREATE TRIGGER auditar_veiculo AFTER INSERT OR UPDATE ON treino.veiculo FOR EACH ROW EXECUTE PROCEDURE treino.auditar_cadastro();
CREATE FUNCTION treino.proteger_historico() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN RAISE EXCEPTION 'Histórico é imutável.' USING ERRCODE='23514'; END $$;
CREATE TRIGGER proteger_historico BEFORE UPDATE OR DELETE ON treino.historico FOR EACH ROW EXECUTE PROCEDURE treino.proteger_historico();
REVOKE DELETE, TRUNCATE ON treino.proprietario,treino.veiculo FROM role_getran;
GRANT SELECT ON treino.historico TO role_getran,role_getran_readonly;
CREATE TRIGGER impedir_truncate_proprietario BEFORE TRUNCATE ON treino.proprietario FOR EACH STATEMENT EXECUTE PROCEDURE treino.proteger_historico();
CREATE TRIGGER impedir_truncate_veiculo BEFORE TRUNCATE ON treino.veiculo FOR EACH STATEMENT EXECUTE PROCEDURE treino.proteger_historico();
CREATE TRIGGER impedir_truncate_historico BEFORE TRUNCATE ON treino.historico FOR EACH STATEMENT EXECUTE PROCEDURE treino.proteger_historico();
CREATE OR REPLACE FUNCTION treino.consultar_placa(p_placa TEXT)
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
    WHERE v.excluido_em IS NULL AND p.excluido_em IS NULL AND v.placa = upper(replace(btrim(p_placa), '-', ''))
$funcao$;


COMMIT;
