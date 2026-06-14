# Descrição do Projeto: Sistema de Cadastro de Leitura e Vendas de Livros

Este documento apresenta a descrição detalhada e as especificações técnicas para o desenvolvimento do **Sistema de Cadastro de Leitura e Vendas de Livros**. O sistema foi concebido sob uma arquitetura desacoplada (Client-Server), integrando um backend em Python/Flask a interfaces portáteis (Mobile/Flutter) e web de administração (Jinja2/Bootstrap).

---

## 1. Arquitetura do Sistema

O sistema é baseado no padrão **Client-Server Desacoplado**, visando alta escalabilidade, segurança e independência de plataformas. 

```mermaid
graph TD
    subgraph Cliente (Frontend)
        A[App Mobile - Flutter] -->|API REST / JSON| B[Porta de Entrada API]
        C[Admin Web - Jinja2 + Bootstrap] -->|Chamadas Internas / Session| D[Flask App Engine]
    end

    subgraph Servidor (Backend & Persistência)
        B --> D
        D -->|SQLAlchemy ORM| E[(Banco de Dados SQLite)]
        D -->|Autenticação| F[JWT / Session Controller]
    end

    subgraph Infraestrutura
        G[Docker Container] -->|Hospeda| D
        G -->|Conexão Integrada| H[Controle de Versão GitHub conectado a uma conta online]
    end
```

### Componentes de Arquitetura:
1. **Back-end (API e Lógica de Negócios):** Desenvolvido em Python com o framework Flask. Funciona como o provedor central de dados e regras de negócio, servindo rotas seguras através de uma API RESTful e renderizando painéis administrativos locais. A autenticação baseia-se em tokens JWT (para a API Mobile) e sessões seguras (para o painel administrativo).
2. **Front-end Mobile (Flutter & Dart):** Aplicativo multiplataforma reativo focado na experiência de leitura e vendas de livros pelo leitor e pela editora. Consome a API Flask de forma assíncrona.
3. **Painel Administrativo (Jinja2 & Bootstrap 5):** Interface web integrada diretamente ao backend Flask, otimizada para gerentes e administradores realizarem a gestão de atendentes e a visualização de relatórios consolidados.
4. **Infraestrutura em Contêineres (Docker):** Todo o ecossistema do backend e do banco de dados SQLite é empacotado em um contêiner Docker para assegurar a homogeneidade dos ambientes de desenvolvimento, homologação e produção.
5. **Integração Contínua e Versionamento (GitHub):** Controle de versão via Git com repositório remoto hospedado no GitHub conectado a uma conta online, permitindo fluxos ágeis de CI/CD.

---

## 2. Plataforma Tecnológica

A plataforma tecnológica do sistema foi selecionada para balancear simplicidade de implantação, robustez no gerenciamento de banco de dados relacional e alta performance de desenvolvimento, sendo composta por:

*   **Linguagem de Programação:** Python 3.10+
*   **Framework Web:** Flask (utilizado para o fornecimento da API REST e processamento de rotas administrativas)
*   **Template Engine (Web Admin):** Jinja 2 (renderização dinâmica de páginas do lado do servidor)
*   **Estilização Frontend Web:** Bootstrap 5 (para interfaces responsivas e limpas)
*   **Banco de Dados:** SQLite (banco relacional em arquivo local, mapeado via SQLAlchemy ORM)
*   **Contêiner de Execução:** Docker (toda a estrutura estará encapsulada em contêiner Docker, onde rodará o controlador de versões GitHub conectado a uma conta online para deploy e integração contínua).
*   **SDK Mobile (Front-end Reativo):** Flutter (linguagem Dart) com gerenciamento de estado via Riverpod e navegação via GoRouter.

---

## 3. Estrutura de Diretórios

A estrutura do projeto adota uma abordagem modular de fácil manutenção, separando as responsabilidades de backend, frontend web (Jinja2/Bootstrap) e as configurações de contêineres:

```text
book_management_system/
├── docker/
│   ├── Dockerfile
│   └── docker-compose.yml
├── backend/
│   ├── app/
│   │   ├── __init__.py          # Inicialização do app Flask e extensões
│   │   ├── models.py            # Modelos do Banco de Dados (SQLAlchemy)
│   │   ├── database.py          # Configurações do banco SQLite
│   │   ├── routes/              # Rotas divididas por módulos/blueprints
│   │   │   ├── __init__.py
│   │   │   ├── auth.py          # Rotas de autenticação (API e Web Session)
│   │   │   ├── requests.py      # Rotas de Enviar/Consultar/Responder solicitações
│   │   │   ├── users.py         # CRUD de atendentes e autocadastro de clientes
│   │   │   └── reports.py       # Rotas de geração de relatórios gerenciais
│   │   ├── services/            # Camada de regras de negócio desacoplada
│   │   │   ├── __init__.py
│   │   │   ├── request_service.py
│   │   │   └── report_service.py
│   │   ├── static/              # Arquivos estáticos (Bootstrap CSS, JS, imagens)
│   │   │   ├── css/
│   │   │   │   └── custom.css
│   │   │   └── js/
│   │   └── templates/           # Templates HTML em Jinja2 para Admin/Atendente
│   │       ├── base.html        # Template base com Bootstrap
│   │       ├── dashboard.html   # Painel principal
│   │       ├── auth/
│   │       │   └── login.html
│   │       ├── requests/
│   │       │   ├── list.html
│   │       │   └── detail.html
│   │       └── users/
│   │           ├── list_attendants.html
│   │           └── create_attendant.html
│   ├── config.py                # Configurações de ambiente do Flask
│   ├── requirements.txt         # Dependências do Python
│   ├── setup_admin.py           # Script para inicializar o Administrador inicial
│   └── run.py                   # Ponto de entrada da aplicação
├── mobile/                      # Código fonte do App Mobile (Flutter)
│   ├── lib/
│   ├── pubspec.yaml
│   └── README.md
├── .gitignore
├── .env.example
└── README.md
```

---

## 4. Convenções do Projeto

Para manter a consistência do código entre todos os membros da equipe Full-Stack, adotam-se as seguintes convenções:

### Código Python (Backend)
*   **Padrão de Formatação:** PEP 8.
*   **Nomenclatura:**
    *   Classes: `PascalCase` (ex: `UserRequest`, `UserProfile`).
    *   Funções, variáveis e métodos: `snake_case` (ex: `get_report_by_date`, `is_admin`).
    *   Constantes: `UPPER_CASE` (ex: `DATABASE_URI`, `JWT_ACCESS_TOKEN_EXPIRES`).
*   **Documentação:** Docstrings em português para todas as funções de rotas e serviços.

### Código HTML/CSS (Jinja2/Bootstrap)
*   **Tags e Atributos HTML:** Letras minúsculas.
*   **Nomenclatura CSS:** `kebab-case` para classes personalizadas (ex: `btn-custom-terracotta`).
*   **Estrutura Bootstrap:** Utilização do grid system (`container`, `row`, `col-*`) para responsividade total.

### REST API Design
*   **URLs:** Substantivos no plural e letras minúsculas (ex: `/api/v1/requests`, `/api/v1/users`).
*   **Métodos HTTP:** 
    *   `GET` para busca e leitura de dados.
    *   `POST` para criação de novos recursos.
    *   `PUT`/`PATCH` para atualização de dados.
    *   `DELETE` para exclusão de dados.
*   **Formato de Dados:** Requisições e respostas obrigatoriamente estruturadas em JSON.
*   **Códigos de Status HTTP:**
    *   `200 OK` / `201 Created` para sucessos.
    *   `400 Bad Request` para falhas de validação.
    *   `401 Unauthorized` / `403 Forbidden` para falhas de autenticação e permissões.
    *   `404 Not Found` para recursos inexistentes.
    *   `500 Internal Server Error` para falhas no servidor.

### Controle de Versão (Git/GitHub)
*   **Nomenclatura de Branches:**
    *   `main`: Produção estável.
    *   `dev`: Integração de novas features.
    *   `feature/nome-da-feature`: Para novos desenvolvimentos.
    *   `bugfix/nome-do-bug`: Para correções de erros.
*   **Mensagens de Commit (Conventional Commits):**
    *   `feat: <descrição>` para novos recursos.
    *   `fix: <descrição>` para correções.
    *   `docs: <descrição>` para documentações.
    *   `refactor: <descrição>` para melhorias sem alteração de comportamento.

---

## 5. Serviços do Sistema

Os serviços centrais encapsulam as regras de negócios do sistema, isolando a lógica de banco de dados das rotas HTTP:

1.  **Serviço de Autenticação (`auth_service.py`):**
    *   Valida credenciais de usuários em banco.
    *   Cria e valida tokens JWT para o aplicativo móvel.
    *   Gerencia sessões (cookies) para o painel web admin em Jinja2.
2.  **Serviço de Atendimento / Solicitações (`request_service.py`):**
    *   `criar_solicitacao(cliente_id, dados)`: Permite que clientes cadastrem novas solicitações de suporte, leitura ou vendas.
    *   `listar_solicitacoes(user_id, user_role)`: Filtra solicitações abertas ou respondidas com base nas permissões do perfil.
    *   `responder_solicitacao(atendente_id, solicitacao_id, resposta)`: Permite a atendentes e administradores responderem a solicitações de clientes, atualizando o status do ticket.
3.  **Serviço de Usuários (`user_service.py`):**
    *   `autocadastro_cliente(dados)`: Registra um novo cliente com perfil público padrão.
    *   `criar_atendente(dados, administrador_id)`: Permite que um administrador cadastrado crie um novo perfil de atendente no banco.
    *   `setup_inicial_admin()`: Garante a criação de um administrador padrão na primeira execução do sistema, caso nenhum administrador exista no banco.
4.  **Serviço de Relatórios (`report_service.py`):**
    *   `gerar_relatorio_atendimento()`: Consolida métricas como tempo de resposta, quantidade de solicitações resolvidas e ativas.
    *   `gerar_relatorio_vendas_leitura()`: Compila informações de cadastro de leitura e vendas consolidadas para visualização do administrador.

---

## 6. Variáveis de Ambiente

As configurações sensíveis e de ambiente são abstraídas em variáveis definidas em um arquivo `.env` local, não versionado no GitHub por motivos de segurança.

| Variável | Tipo | Descrição | Exemplo |
| :--- | :--- | :--- | :--- |
| `FLASK_APP` | String | Arquivo principal para iniciar a aplicação | `run.py` |
| `FLASK_ENV` | String | Define o ambiente (`development` ou `production`) | `development` |
| `SECRET_KEY` | String | Chave de segurança para sessões e hashing do Flask | `d3f5a892b10495bc20c5d733190ab78f` |
| `JWT_SECRET_KEY` | String | Chave secreta de criptografia dos tokens JWT | `8f4b23d91ca8e482390ba0381df498d2` |
| `DATABASE_URL` | String | URI de conexão com o banco SQLite | `sqlite:///instance/database.db` |
| `INITIAL_ADMIN_EMAIL` | String | E-mail do Administrador inicial padrão | `admin@bibliotheca.com` |
| `INITIAL_ADMIN_PASSWORD` | String | Senha inicial para o primeiro acesso do Administrador | `Admin123!` |

---

## 7. Definição de Usuários e Perfis de Acesso

O sistema gerencia três perfis de usuários com níveis de permissão estritos:

```
                  ┌──────────────────────────────┐
                  │    Administrador Inicial     │
                  └──────────────┬───────────────┘
                                 │
                                 ▼ (Cadastra)
                  ┌──────────────────────────────┐
                  │          Atendente           │
                  └──────────────┬───────────────┘
                                 │
                                 ▼ (Responde solicitações de)
┌────────────────┐               │
│    Cliente     ├───────────────┘
└────────────────┘ (Autocadastro)
```

### 1. Administrador (Admin)
*   **Origem e Criação:** O sistema gera um Administrador inicial automaticamente no primeiro deploy ou execução (via script de setup inicial como `setup_admin.py` ou serviço `setup_inicial_admin()`) usando as credenciais definidas nas variáveis de ambiente `INITIAL_ADMIN_EMAIL` e `INITIAL_ADMIN_PASSWORD`. Administradores adicionais só podem ser criados ou configurados no banco por outro administrador.
*   **Permissões:**
    *   Acesso e controle irrestrito a todas as funcionalidades do sistema.
    *   Gestão de usuários atendentes (CRUD completo de Atendentes).
    *   Visualização de painéis e relatórios gerenciais consolidados (tempo médio de atendimento, solicitações por status, estatísticas de vendas e leituras).
    *   Visualização e resposta a qualquer solicitação crítica cadastrada no sistema.

### 2. Atendente
*   **Origem e Criação:** Usuários atendentes são cadastrados exclusivamente por um Administrador através do painel de administração web. Não há opção de autocadastro público para atendentes.
*   **Permissões:**
    *   Visualização da lista de solicitações pendentes e em aberto atribuídas ou gerais.
    *   Responder a solicitações de clientes e atualizar seus respectivos status (ex: "Em Aberto", "Em Atendimento", "Resolvido").
    *   Visualizar dados de perfil básicos dos clientes associados às solicitações sob sua responsabilidade.

### 3. Cliente
*   **Origem e Criação:** O cliente realiza o autocadastro de forma autônoma e pública através da interface do aplicativo mobile ou por páginas públicas de registro da web.
*   **Permissões:**
    *   Enviar novas solicitações de atendimento, suporte ou contato.
    *   Consultar, filtrar e acompanhar o andamento e o histórico de suas próprias solicitações.
    *   Registrar leituras realizadas (marcar livros como lidos, lendo, quero ler) e avaliar livros.
    *   Visualizar catálogo de livros disponíveis para vendas, trocas e interações sociais.
    *   Editar e gerenciar seus próprios dados cadastrais e de perfil.
