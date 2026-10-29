-- Normaliza cadastros novos e legados, incluindo inativos, mantendo a auditoria.
BEGIN;
LOCK TABLE treino.proprietario, treino.veiculo IN ACCESS EXCLUSIVE MODE;

CREATE OR REPLACE FUNCTION treino.proteger_cadastro() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE dono bigint;
BEGIN
 IF TG_OP = 'DELETE' THEN RAISE EXCEPTION 'Exclusão física proibida. Utilize exclusão lógica.' USING ERRCODE='23514'; END IF;
 IF TG_OP = 'UPDATE' AND OLD.excluido_em IS NOT NULL THEN
  RAISE EXCEPTION 'Registro inativo não pode ser alterado.' USING ERRCODE='23514';
 END IF;
 IF TG_TABLE_NAME = 'proprietario' THEN
  NEW.cpf_cnpj=upper(NEW.cpf_cnpj);
  IF TG_OP = 'UPDATE' AND NEW.cpf_cnpj IS DISTINCT FROM OLD.cpf_cnpj THEN
   RAISE EXCEPTION 'CPF/CNPJ não pode ser alterado após o cadastro.' USING ERRCODE='23514';
  END IF;
  NEW.nome=upper(NEW.nome); NEW.rua=upper(NEW.rua); NEW.numero=upper(NEW.numero);
  NEW.cep=upper(NEW.cep); NEW.cidade=upper(NEW.cidade); NEW.estado=upper(NEW.estado);
  NEW.complemento=upper(NEW.complemento);
 ELSE
  NEW.placa=upper(NEW.placa); NEW.renavam=upper(NEW.renavam); NEW.chassi=upper(NEW.chassi);
  IF NEW.excluido_em IS NULL THEN
   SELECT id INTO dono FROM treino.proprietario WHERE id=NEW.id_proprietario AND excluido_em IS NULL FOR UPDATE;
   IF dono IS NULL THEN RAISE EXCEPTION 'Selecione um proprietário ativo.' USING ERRCODE='23503'; END IF;
  END IF;
 END IF;
 RETURN NEW;
END $$;

-- Exceção restrita a esta transação para converter também cadastros inativos.
-- O bloqueio das tabelas impede outras gravações durante a conversão.
-- Os triggers de auditoria permanecem ativos e registram antes/depois.
ALTER TABLE treino.proprietario DISABLE TRIGGER proteger_proprietario;
ALTER TABLE treino.veiculo DISABLE TRIGGER proteger_veiculo;

UPDATE treino.proprietario
SET cpf_cnpj=upper(cpf_cnpj), nome=upper(nome), rua=upper(rua), numero=upper(numero),
    cep=upper(cep), cidade=upper(cidade), estado=upper(estado), complemento=upper(complemento)
WHERE ROW(cpf_cnpj,nome,rua,numero,cep,cidade,estado,complemento)
 IS DISTINCT FROM ROW(upper(cpf_cnpj),upper(nome),upper(rua),upper(numero),upper(cep),upper(cidade),upper(estado),upper(complemento));

UPDATE treino.veiculo
SET placa=upper(placa), renavam=upper(renavam), chassi=upper(chassi)
WHERE ROW(placa,renavam,chassi) IS DISTINCT FROM ROW(upper(placa),upper(renavam),upper(chassi));

ALTER TABLE treino.proprietario ENABLE TRIGGER proteger_proprietario;
ALTER TABLE treino.veiculo ENABLE TRIGGER proteger_veiculo;
COMMIT;
