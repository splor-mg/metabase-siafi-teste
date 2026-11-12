# Publicar a demonstração no Render

Este roteiro publica o Metabase do projeto para demonstrar o painel por um link
público. O serviço gratuito do Render é temporário e sujeito a limites de memória,
armazenamento e disponibilidade. Não use para produção.

## 1. Criar os serviços

1. Envie estas alterações para o repositório GitHub.
2. Crie uma conta no [Render](https://render.com/) e conecte o GitHub.
3. No Render, use **New > Blueprint**, selecione o repositório e confirme o `render.yaml`.
4. Preencha `METABASE_RO_PASSWORD` com uma senha forte. Guarde-a: ela também será
   usada no arquivo local `.env.render.local`.
5. Aguarde a criação do Postgres e o primeiro deploy do serviço web.

O Blueprint cria um único Postgres gratuito e um serviço Docker do Metabase.
O serviço web fica público, mas o painel só ficará acessível publicamente depois da
etapa 4. Não coloque senhas em arquivos versionados.

## 2. Preparar o Postgres de demonstração

O projeto não armazena os CSVs SIAFI neste repositório. Clone os dados localmente:

```bash
git clone https://github.com/splor-mg/dados-siafi-2026.git ../dados-siafi-2026
cp .env.render.example .env.render.local
```

No painel do Render, abra o Postgres e copie as credenciais de conexão **External**
para `.env.render.local`. Use a mesma senha de `METABASE_RO_PASSWORD` definida no
Blueprint. O arquivo local já está no `.gitignore`.

Requisitos locais: Python 3, `psql`, `zcat` e acesso externo ao Postgres.
Instale a dependência Python do projeto e rode:

```bash
python3 -m pip install requests
bash scripts/render_db_init.sh
```

O script cria os papéis e schemas, as tabelas e as views, e carrega somente
`execucao`, `receita` e `credito`, usados nas views do painel. Essa redução tenta
manter a base dentro do limite gratuito de 1 GB; não há garantia de que os dados
caibam. Se exceder, a carga falhará e será necessário reduzir a amostra.

## 3. Configurar a conexão no Metabase

Copie as variáveis `DB_HOST_FOR_METABASE`, `SIAFI_DB`, `METABASE_RO_USER` e
`METABASE_RO_PASSWORD` do serviço no Render. Em um terminal local, defina também:

- `MB_URL`: URL pública do serviço Metabase no Render;
- `MB_ADMIN_EMAIL`: e-mail de administração que escolher;
- `MB_ADMIN_PASSWORD`: senha forte exclusiva para o admin;
- `DB_HOST_FOR_METABASE`: host **Internal** do Postgres no Render;
- `SIAFI_DB`, `METABASE_RO_USER`, `METABASE_RO_PASSWORD`: valores do Blueprint.

Com essas variáveis no ambiente, execute uma única vez:

```bash
python3 scripts/metabase_setup.py
```

O setup cria o administrador, a conexão de leitura, os grupos, as coleções,
perguntas e o painel. Se o Metabase já estiver configurado, não rode novamente:
o script pode duplicar objetos. A aplicação precisa estar iniciada e acessível.

## 4. Tornar o painel acessível pelo link

Entre no Metabase, abra o painel, escolha **Compartilhar > Incorporar/publicar
publicamente** (o texto varia por versão), habilite o link público e copie a URL
gerada. Acrescente essa URL ao README do repositório para quem chegar pelo GitHub.

Compartilhar publicamente permite que qualquer pessoa com o link veja o painel.
Confira os dados e filtros antes de divulgar.

## Limites do plano gratuito

- O serviço web suspende após 15 minutos sem acesso e pode levar cerca de um minuto
  para voltar.
- O Postgres gratuito tem 1 GB e expira após 30 dias.
- O serviço web tem 512 MB de RAM; o Metabase pode não iniciar ou pode reiniciar
  por falta de memória.
- O disco do serviço web é temporário. A configuração do Metabase é mantida no
  Postgres, mas arquivos locais não são persistentes.

Consulte os [limites atuais do Render](https://render.com/docs/free). O link ficará
disponível enquanto os recursos gratuitos existirem e estiverem ativos.
