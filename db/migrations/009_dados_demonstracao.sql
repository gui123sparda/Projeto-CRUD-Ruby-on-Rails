-- Dados de demonstração para a estrutura criada até 008_tipo_veiculo.sql.
-- CPFs e CNPJs fictícios com dígitos verificadores válidos.
BEGIN;

INSERT INTO treino.proprietario
    (cpf_cnpj, nome, rua, numero, cidade, estado)
VALUES
    ('90000000175', 'Mariana Costa Demo', 'Rua Exemplo', '101', 'Fortaleza', 'CE'),
    ('90000000256', 'Rafael Lima Demo', 'Rua Exemplo', '102', 'Sobral', 'CE'),
    ('90000000337', 'Camila Rocha Demo', 'Rua Exemplo', '103', 'Juazeiro do Norte', 'CE'),
    ('90000000418', 'Pedro Alves Demo', 'Rua Exemplo', '104', 'Caucaia', 'CE'),
    ('90000000507', 'Juliana Moura Demo', 'Rua Exemplo', '105', 'Crato', 'CE'),
    ('90000000680', 'Diego Ferreira Demo', 'Rua Exemplo', '106', 'Maracanaú', 'CE'),
    ('90000000760', 'Larissa Gomes Demo', 'Rua Exemplo', '107', 'Iguatu', 'CE'),
    ('90000000841', 'Thiago Ribeiro Demo', 'Rua Exemplo', '108', 'Quixadá', 'CE'),
    ('90000000922', 'Beatriz Nogueira Demo', 'Rua Exemplo', '109', 'Aquiraz', 'CE'),
    ('90000001066', 'Felipe Carvalho Demo', 'Rua Exemplo', '110', 'Itapipoca', 'CE'),
    ('90000001147', 'Renata Barros Demo', 'Rua Exemplo', '111', 'Russas', 'CE'),
    ('90000001228', 'Lucas Martins Demo', 'Rua Exemplo', '112', 'Aracati', 'CE'),
    ('90000000001318', 'Oficina Demonstração Ltda', 'Rua Exemplo', '113', 'Fortaleza', 'CE'),
    ('90000000001407', 'Entregas Exemplo Ltda', 'Rua Exemplo', '114', 'Maracanaú', 'CE'),
    ('90000000001580', 'Comércio Modelo Ltda', 'Rua Exemplo', '115', 'Caucaia', 'CE')
ON CONFLICT (cpf_cnpj) DO NOTHING;

-- Um carro e uma moto por proprietário; metade das placas de cada formato.
INSERT INTO treino.veiculo
    (placa, renavam, chassi, ano_fabricacao, tipo, id_proprietario)
SELECT dados.placa, dados.renavam, dados.chassi, dados.ano_fabricacao,
       dados.tipo::treino.tipo_veiculo, proprietario.id
FROM (VALUES
    ('FCT1A01', '88000000001', '9BDFCTTST00000001', 2023, 'CARRO', '90000000175'),
    ('FCT2001', '88000000002', '9BDFCTTST00000002', 2014, 'MOTO', '90000000175'),
    ('FCT1002', '88000000003', '9BDFCTTST00000003', 2015, 'CARRO', '90000000256'),
    ('FCT2B02', '88000000004', '9BDFCTTST00000004', 2024, 'MOTO', '90000000256'),
    ('FCT1A03', '88000000005', '9BDFCTTST00000005', 2025, 'CARRO', '90000000337'),
    ('FCT2003', '88000000006', '9BDFCTTST00000006', 2016, 'MOTO', '90000000337'),
    ('FCT1004', '88000000007', '9BDFCTTST00000007', 2017, 'CARRO', '90000000418'),
    ('FCT2B04', '88000000008', '9BDFCTTST00000008', 2022, 'MOTO', '90000000418'),
    ('FCT1A05', '88000000009', '9BDFCTTST00000009', 2023, 'CARRO', '90000000507'),
    ('FCT2005', '88000000010', '9BDFCTTST00000010', 2018, 'MOTO', '90000000507'),
    ('FCT1006', '88000000011', '9BDFCTTST00000011', 2013, 'CARRO', '90000000680'),
    ('FCT2B06', '88000000012', '9BDFCTTST00000012', 2024, 'MOTO', '90000000680'),
    ('FCT1A07', '88000000013', '9BDFCTTST00000013', 2025, 'CARRO', '90000000760'),
    ('FCT2007', '88000000014', '9BDFCTTST00000014', 2014, 'MOTO', '90000000760'),
    ('FCT1008', '88000000015', '9BDFCTTST00000015', 2015, 'CARRO', '90000000841'),
    ('FCT2B08', '88000000016', '9BDFCTTST00000016', 2022, 'MOTO', '90000000841'),
    ('FCT1A09', '88000000017', '9BDFCTTST00000017', 2023, 'CARRO', '90000000922'),
    ('FCT2009', '88000000018', '9BDFCTTST00000018', 2016, 'MOTO', '90000000922'),
    ('FCT1010', '88000000019', '9BDFCTTST00000019', 2017, 'CARRO', '90000001066'),
    ('FCT2B10', '88000000020', '9BDFCTTST00000020', 2024, 'MOTO', '90000001066'),
    ('FCT1A11', '88000000021', '9BDFCTTST00000021', 2025, 'CARRO', '90000001147'),
    ('FCT2011', '88000000022', '9BDFCTTST00000022', 2018, 'MOTO', '90000001147'),
    ('FCT1012', '88000000023', '9BDFCTTST00000023', 2013, 'CARRO', '90000001228'),
    ('FCT2B12', '88000000024', '9BDFCTTST00000024', 2022, 'MOTO', '90000001228'),
    ('FCT1A13', '88000000025', '9BDFCTTST00000025', 2023, 'CARRO', '90000000001318'),
    ('FCT2013', '88000000026', '9BDFCTTST00000026', 2014, 'MOTO', '90000000001318'),
    ('FCT1014', '88000000027', '9BDFCTTST00000027', 2015, 'CARRO', '90000000001407'),
    ('FCT2B14', '88000000028', '9BDFCTTST00000028', 2024, 'MOTO', '90000000001407'),
    ('FCT1A15', '88000000029', '9BDFCTTST00000029', 2025, 'CARRO', '90000000001580'),
    ('FCT2015', '88000000030', '9BDFCTTST00000030', 2016, 'MOTO', '90000000001580')
) AS dados(placa, renavam, chassi, ano_fabricacao, tipo, cpf_cnpj)
JOIN treino.proprietario AS proprietario
  ON proprietario.cpf_cnpj = dados.cpf_cnpj
ON CONFLICT (placa) DO NOTHING;

COMMIT;
