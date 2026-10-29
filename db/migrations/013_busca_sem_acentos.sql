-- Normaliza somente a comparação: os textos armazenados mantêm seus acentos.
BEGIN;
CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;

CREATE OR REPLACE FUNCTION treino.normalizar_busca(valor text)
RETURNS text LANGUAGE sql STABLE PARALLEL SAFE AS $$
    SELECT lower(public.unaccent('public.unaccent'::regdictionary, coalesce(valor, '')))
$$;

GRANT EXECUTE ON FUNCTION treino.normalizar_busca(text) TO role_getran, role_getran_readonly;
COMMIT;
