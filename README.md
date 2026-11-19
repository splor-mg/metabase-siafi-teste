# Teste Metabase + Postgres com dados SIAFI 2026

Projeto de teste do Metabase (edição open source) com PostgreSQL e dados do
[dados-siafi-2026](https://github.com/splor-mg/dados-siafi-2026). Os serviços
rodam em contêineres Docker.

A documentação de uso está em [`docs/index.md`](docs/index.md).

## Requisitos

- Git
- Docker com o comando `docker compose`
- Python 3

Os comandos abaixo são para Linux, macOS ou WSL. No Windows, use o WSL ou
adapte os comandos de ambiente virtual para o PowerShell.

## Passo a passo

1. Clone este repositório e entre na pasta:

   ```bash
   git clone https://github.com/splor-mg/metabase-siafi-teste.git
   cd metabase-siafi-teste
   ```

2. Crie o arquivo de configuração e defina as senhas indicadas nele:

   ```bash
   cp .env.exemplo .env
   ```

   Use senhas próprias para o ambiente de teste. Não compartilhe nem versione o
   arquivo `.env`.

3. Clone o repositório dos dados na pasta vizinha:

   ```bash
   git clone https://github.com/splor-mg/dados-siafi-2026.git ../dados-siafi-2026
   ```

4. Inicie os serviços:

   ```bash
   docker compose up -d
   ```

   Aguarde o PostgreSQL e o Metabase iniciarem antes de continuar.

5. Crie e carregue o banco SIAFI:

   ```bash
   bash scripts/docker_db.sh ../dados-siafi-2026
   ```

6. Crie um ambiente Python e instale a dependência usada pelo setup:

   ```bash
   python3 -m venv .venv
   .venv/bin/pip install requests
   ```

7. Execute a configuração do Metabase:

   ```bash
   set -a
   . ./.env
   set +a
   .venv/bin/python scripts/metabase_setup.py
   ```

8. Acesse o Metabase em <http://localhost:3000>.

Use o e-mail `admin@teste.local` e a senha definida em `MB_ADMIN_PASSWORD` no
arquivo `.env`.

## Problemas comuns

- **Erro 407 ao executar o script:** a rede pode exigir um proxy. O script
  `metabase_setup.py` deve ignorar o proxy ao se comunicar com `localhost`.
- **Usuários de teste não foram criados:** execute
  `.venv/bin/python scripts/criar_usuarios.py`.
- **Painel sem dados:** em **Admin settings > Databases > SIAFI 2026**, clique
  em **Sync database schema now**.
- **Recomeçar do zero:** `docker compose down -v` remove os volumes do Docker,
  incluindo os dados do PostgreSQL e do Metabase. Essa ação apaga os dados
  persistidos.

## Observações

- Os dados SIAFI não estão neste repositório; são obtidos de
  `dados-siafi-2026`.
- O arquivo `.env` contém credenciais e não deve ser versionado.
