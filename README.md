# Treinamento CRUD — Ruby on Rails

Aplicação de cadastro de proprietários e veículos em Ruby 4.0.6 e Rails 8.1.4, com PostgreSQL, interface em português e relatórios PDF.

O projeto adapta o sistema `TreinamentoCRUDServlet`, preservando as regras de cadastro, os recursos visuais e a estrutura do banco em um banco próprio. Os arquivos necessários estão incluídos neste repositório.

## Funcionalidades

- Painel com totais de proprietários, veículos, carros e motos.
- Cadastro, edição, consulta e exclusão lógica de proprietários e veículos.
- Filtros, paginação e busca de proprietários sem distinção de acentos.
- Consulta por placa, com dados do veículo, proprietário e imagem ilustrativa.
- Placas antigas e Mercosul, com formatos próprios para carros e motos.
- Histórico de alterações e exclusão de proprietário com confirmação dos veículos vinculados.
- Relatórios PDF individuais, de listagem, de histórico e agrupados por proprietário.

## Executar com Docker

Pré-requisitos: Docker Engine com Compose v2 e OpenSSL.

```sh
bin/setup-docker
```

Execute os comandos na raiz do projeto. Abra **http://localhost:6767** após a inicialização. O script gera `.env` com senhas aleatórias e permissão `0600`, caso o arquivo ainda não exista, constrói a aplicação, prepara o banco e aguarda as verificações de saúde. Execuções posteriores preservam as credenciais e os dados.

Para configurar manualmente, copie `.env.example` para `.env`, preencha `DB_PASSWORD` e `SECRET_KEY_BASE` com valores gerados por `openssl rand -hex 64`, e execute:

```sh
docker compose up --build -d --wait web
```

As imagens base oficiais têm versões fixas: `ruby:4.0.6-slim-bookworm` e `postgres:18.1-bookworm`. O Dockerfile tem estágios separados para dependências, testes e produção. O servidor roda sem root. O Postgres usa volume persistente e não publica uma porta no host. Apenas a aplicação é exposta, em `127.0.0.1:${APP_PORT:-6767}`.

```sh
docker compose logs -f web
docker compose stop
docker compose start
```

Depois de alterar o código, reconstrua a imagem para atualizar a aplicação em execução:

```sh
docker compose up --build -d --wait web
```

O serviço `web` usa o código copiado durante o build; alterações nos arquivos locais exigem essa reconstrução.

`docker compose down` remove os contêineres, preservando o volume. A aplicação inicia sem dados fictícios. Para carregar os dados de demonstração do Servlet, de forma opcional e idempotente:

```sh
docker compose exec -e SEED_DEMO=true web bin/rails db:seed
```

Não altere a senha de `.env` esperando mudar a senha de um volume Postgres já inicializado: as variáveis `POSTGRES_*` são aplicadas na primeira criação do volume.

### Configuração

O Docker Compose lê o arquivo `.env` na raiz do projeto. Use [.env.example](.env.example) como referência.

| Variável | Uso | Padrão |
| --- | --- | --- |
| `DB_NAME` | Banco usado pela aplicação no Compose | `rails_crud_production` |
| `DB_USER` | Usuário do PostgreSQL | `rails_crud` |
| `DB_PASSWORD` | Senha do PostgreSQL | Obrigatória |
| `SECRET_KEY_BASE` | Segredo do Rails em produção | Obrigatório |
| `APP_PORT` | Porta HTTP no host | `6767` |
| `RAILS_LOG_LEVEL` | Nível de log da aplicação | `info` |

Se alterar `APP_PORT`, use a nova porta no endereço de acesso. O PostgreSQL do Compose fica acessível aos contêineres pelo host `db`.

## Relatórios e placas

Os PDFs podem ser abertos pelos botões de relatório nas telas de cadastro, listagem, consulta de placa e histórico.

| Relatório | Rota | Conteúdo |
| --- | --- | --- |
| Proprietário | `/relatorio-proprietario.do?id=ID` | Dados de um proprietário |
| Proprietários | `/relatorio-proprietarios.do` | Listagem conforme os filtros |
| Veículo | `/relatorio-veiculo.do?id=ID` | Dados e imagem da placa de um veículo |
| Veículos | `/relatorio-veiculos.do` | Listagem com dados e imagens das placas |
| Proprietário e veículos | `/relatorio-agrupado.do?idProprietario=ID` | Um proprietário e seus veículos ativos, com imagens das placas |
| Histórico de proprietários | `/relatorio-historico.do` | Eventos de auditoria de proprietários |
| Histórico de veículos | `/relatorio-historico-veiculos.do` | Eventos de auditoria de veículos |

Substitua `ID` pelo identificador do cadastro. Os relatórios de listagem e histórico aceitam os filtros das respectivas telas. O relatório completo exige o identificador de um proprietário ativo no parâmetro `idProprietario` (ou `id`) e inclui somente os veículos ativos desse cadastro.

As placas são ilustrações. Nas telas, `PlacaImagem` produz SVG com glifos FE para o modelo Mercosul e fonte Mandatory para o modelo antigo. Nos relatórios de veículos e no agrupado, o SVG é convertido em PNG em resolução dupla com libvips e incorporado ao PDF pelo Prawn. Isso inclui os formatos de carro e moto; a placa antiga usa a cidade e o estado do proprietário na tarjeta.

## Estrutura do projeto

- `db/migrations/`: migration Rails e SQLs de estrutura e demonstração.
- `public/css/`, `public/js/` e `public/img/`: recursos estáticos usados pelas telas e relatórios.
- `app/assets/fonts/`: fontes e glifos das placas e PDFs, com os avisos de licença.

Todos os arquivos necessários estão neste projeto; não há dependência de pastas do projeto Servlet. A aplicação carrega apenas os módulos Rails usados pelo CRUD, pelas views e pelos testes. Arquivos de exemplo de PWA, mailers, jobs, Kamal, Hotwire e bancos auxiliares foram removidos.

## Camadas

```text
HTTP / rotas .do
  → app/controllers     parâmetros, status HTTP e seleção das views
  → app/facades         casos de uso e coordenação
  → app/daos            consultas, paginação, transações e persistência
  → app/models          Proprietario, Veiculo, LogProprietario, Historico
  → PostgreSQL          schema treino, funções, índices e triggers originais

app/views               HTML original convertido de JSP para ERB
app/presenters          documentos PDF e imagens de placas em SVG/PNG
public/servlet          CSS, JavaScript e imagens reaproveitados do Servlet
```

Controllers, facades e DAOs são organizados somente pelas quatro tabelas do domínio: `Proprietario`, `Veiculo`, `LogProprietario` e `Historico`. `ApplicationController`, `ApplicationDao` e `ApplicationRecord` concentram o comportamento técnico compartilhado.

O painel é apresentado por `LogProprietariosController`, que combina o resumo de `LogProprietarioFacade` com os totais de `ProprietarioFacade` e `VeiculoFacade`. `HistoricoDao` consulta apenas os eventos de `treino.historico`; `LogProprietarioDao` consulta `treino.log_proprietario`. Relatórios são ações dos controllers das respectivas entidades, com a geração do PDF em `RelatorioPdf`; a imagem da placa é uma ação de `VeiculosController`, com apresentação em `PlacaImagem`. A validação dos filtros HTTP fica em `lib/filtros_consulta.rb`.

Os modelos permanecem como Active Record, sem substituir entidades por hashes. Os nomes singulares das tabelas, suas colunas e relacionamentos são preservados por mapeamento explícito. Filtros passam por uma lista de campos permitidos; os valores de consulta são vinculados ou representados por nós Arel.

Os caminhos `.do` e os nomes de campos HTTP foram mantidos para conservar links e scripts. A interface reaproveita o HTML, classes CSS, assets, menus, cores, temas, animação inicial, formulários e modais. O daisyUI **5.7.50**, resolução da versão 5 usada pelo Servlet, está versionado localmente; a apresentação não depende do CDN. A consulta de CEP mantém a integração externa com ViaCEP e o preenchimento manual quando indisponível.

Os PDFs são gerados em Ruby com Prawn, fontes e imagens institucionais originais. A composição dos relatórios foi reimplementada em Ruby; a execução da aplicação usa as dependências definidas no Dockerfile e no Gemfile.

## Banco e migrations

O banco próprio padrão é `rails_crud_production`, com `rails_crud_test` separado para testes. A aplicação não se conecta ao banco do Servlet.

`db/migrations/` reúne a migration Rails e os SQLs usados pela aplicação. O Rails está configurado para ler essa pasta. A migration executa, em ordem e dentro de uma transação, as versões estruturais **001–004, 006–008 e 010–014**. Os comandos `BEGIN`/`COMMIT` externos são retirados para que a transação seja controlada pelo Rails.

- **009**: dados demonstrativos compatíveis com a estrutura final; disponíveis em `db:seed` com `SEED_DEMO=true`.
- **012**: exclusão lógica, cascata auditada, snapshots antes/depois e proteção de histórico.
- **013**: extensão `unaccent` e função de comparação sem acentos.
- **014**: normalização em maiúsculas, preservando os acentos dos dados.

`db/structure.sql` mantém funções, enum e triggers que um `schema.rb` não representaria integralmente. A inicialização usa `db:prepare`. A reversão da migration é explicitamente irreversível para preservar a auditoria.

CPF e CNPJ, incluindo o formato alfanumérico do Servlet, são normalizados e têm dígitos verificadores validados. CPF/CNPJ é permanente após o cadastro. Veículos validam placa, chassi, RENAVAM, ano, tipo e proprietário ativo. Exclusões inativam os registros, sem liberar seus identificadores únicos. A exclusão de proprietário com veículos exige confirmação da quantidade atual e usa bloqueio transacional; os triggers inativam os vínculos e registram os eventos atomicamente.

Como na referência, não há autenticação individual: a auditoria identifica a conta do banco. O ambiente Compose foi preparado para uso local; publicação em rede requer definir autenticação, TLS e a política de acesso apropriada ao ambiente.

## Verificação

Execute os testes de modelos, integração HTTP, navegador Chromium, RuboCop e Brakeman em contêiner:

```sh
docker compose --profile test run --build --rm test
```

A imagem de testes inclui Chromium/ChromeDriver; a imagem de produção não inclui essas ferramentas. O banco de testes é separado do banco de uso da aplicação. Os testes usam transações, sem truncar tabelas protegidas pelos triggers de auditoria.

Os testes cobrem cadastros, validações, filtros, paginação, CSRF, exclusão lógica, auditoria, consulta de placa e geração de relatórios. A regressão dos PDFs verifica a presença das imagens das placas antigas e Mercosul para carros e motos nos relatórios individual, de listagem e agrupado. As capturas dos testes de navegador ficam em `tmp/screenshots/`.

### Verificação fora do Docker

Instale Ruby 4.0.6, Bundler, PostgreSQL com a extensão `unaccent`, bibliotecas de desenvolvimento do PostgreSQL, libvips 8.13 ou superior e as ferramentas de compilação necessárias às gems. Para os testes de navegador, também são necessários Chromium/Chrome e ChromeDriver compatíveis; `CHROME_BIN` pode indicar o caminho do navegador.

Exporte `DB_HOST`, `DB_PORT`, `DB_USER` e `DB_PASSWORD` para uma instância PostgreSQL acessível pelo terminal. O usuário precisa de permissão para preparar o banco de testes, criar o schema `treino` e instalar `unaccent`. Fora do Compose, o padrão de conexão é `localhost:5432`; o Rails não carrega automaticamente o arquivo `.env` deste projeto.

O banco de desenvolvimento padrão é `rails_crud_development`; o de testes é `rails_crud_test`, configurável por `DB_TEST_NAME`. O PostgreSQL do Compose não publica porta no host, portanto os comandos abaixo exigem uma conexão PostgreSQL disponível fora dessa rede interna.

```sh
bundle install
RAILS_ENV=test bin/rails db:prepare
bin/rails test
bin/rails test:system
bin/rubocop
bin/brakeman --no-pager
bin/bundler-audit
```

A pipeline em `.github/workflows/ci.yml` executa a suíte Docker e verifica o build e a saúde do servidor de produção.
