# Descrição do Aplicativo Mobile de Cadastro de Leitura e Vendas de Livros

Este documento detalha o projeto para o aplicativo mobile da plataforma centralizada de interação e vendas entre leitores e editoras. O aplicativo visa fornecer uma interface portátil, responsiva e reativa para o gerenciamento de leituras, interação social e catálogos de livros.

## 1. Usuários e Casos de Uso

O sistema suportará os seguintes tipos de usuários e casos de uso no aplicativo:

### Usuários

| Tipo de Usuário | Descrição | Cadastro |
| :--- | :--- | :--- |
| **Administrador** | Usuário com acesso total para gerenciar o sistema móvel, visualizando relatórios e alternando a ativação de usuários. | Configurado na API ou definido inicialmente. |
| **Editora** | Conta institucional responsável por gerenciar seu catálogo de livros (incluindo busca externa por metadados) e responder às solicitações dos leitores. | Cadastrada pelo Administrador. |
| **Leitor** | Usuário final (cliente) que busca livros, gerencia amizades, registra leituras e envia mensagens para editoras. | Autocadastro pelo aplicativo. |

### Casos de Uso

*   **Explorar e Registrar Leitura (Leitor):** O leitor pode buscar livros, visualizar detalhes, e cadastrar/atualizar o status de sua leitura (quero ler, lendo, lido) fornecendo nota e comentários.
*   **Gerenciar Catálogo e Responder Solicitação (Editora):** A editora pode criar novos livros (com preenchimento automático via busca na API Open Library), editar informações de catálogo, arquivar livros e responder a solicitações pendentes.
*   **Sistema Social e Mensagens (Leitor):** Leitores podem acompanhar as atualizações de leitura de outros usuários em seu círculo através do feed da comunidade e trocar mensagens diretas em tempo real através do chat.
*   **Moderar Usuários (Administrador):** O administrador pode visualizar a listagem geral de usuários e ativar/inativar qualquer conta do sistema.
*   **Visualizar Painel de Estatísticas (Administrador):** Visualização de relatórios gerenciais consolidados do sistema (número de leituras, total de livros e usuários ativos).

---

## 2. Arquitetura

A arquitetura do sistema será **Desacoplada (Client-Server)**, utilizando o padrão API RESTful.

*   **Camada de Apresentação (Front-end Mobile):** Aplicativo móvel construído em **Flutter** e **Dart**, que renderiza a interface reativa de forma nativa e consome a API RESTful de forma assíncrona, gerenciando o estado localmente sem travamentos de tela.
*   **Camada de Lógica de Negócio (Back-end API):** Servidor Flask (projeto `doc` externo) responsável por fornecer os endpoints JSON, aplicar regras de negócio, autenticar requisições usando tokens JWT e gerenciar a persistência do banco.
*   **Camada de Dados (Model):** Representada no aplicativo pelos repositórios que se comunicam com o cliente de API e pelos modelos Dart fortemente tipados que mapeiam os retornos JSON.

---

## 3. Plataforma Tecnológica

*   **Linguagem de Programação:** Dart (compilada nativamente via AOT para máxima performance no celular)
*   **Framework Mobile:** Flutter SDK (canal stable, com suporte a Material Design 3 e estética *Stitch Bibliotheca Aesthetic*)
*   **Gerenciamento de Estado:** Riverpod (`flutter_riverpod`)
*   **Roteamento e Navegação:** GoRouter (`go_router` com abas persistentes)
*   **Consumo de API:** HTTP (`http` package para requisições RESTful assíncronas)
*   **Armazenamento e Cache Local:** SharedPreferences (`shared_preferences` para credenciais JWT, perfil e URL do servidor)
*   **Controle de Versão:** GitHub

---

## 4. Estrutura de Diretórios

```text
├── mobile/
│   ├── lib/
│   │   ├── config/             # Configurações globais (api_config.dart)
│   │   ├── core/               # Recursos compartilhados da aplicação
│   │   │   ├── api/            # Cliente HTTP e exceções de API
│   │   │   ├── auth/           # Gerenciador de sessão e estado do usuário
│   │   │   ├── models/         # Modelos de dados e enumerações de papéis
│   │   │   ├── storage/        # Utilitários de persistência de tokens
│   │   │   ├── theme/          # Estilização (Stitch "Bibliotheca Aesthetic")
│   │   │   └── widgets/        # Componentes visuais comuns (capa de livro, cartões)
│   │   ├── data/               # Repositórios de acesso a dados (API)
│   │   ├── features/           # Módulos e telas divididos por domínio de negócio
│   │   │   ├── admin/          # Telas do Administrador (relatórios e usuários)
│   │   │   ├── auth/           # Login e registro de leitores
│   │   │   ├── books/          # Detalhes de livros e vitrine geral
│   │   │   ├── editor/         # CRUD de livros e painel de solicitações
│   │   │   ├── home/           # Feed da comunidade
│   │   │   ├── messages/       # Chat de mensagens e lista de conversas
│   │   │   ├── profile/        # Configuração de conta e ajuste de URL da API
│   │   │   ├── search/         # Tela de busca unificada
│   │   │   └── shell/          # Contêiner de navegação em abas (MainShell)
│   │   ├── routing/            # Configuração do GoRouter (app_router.dart)
│   │   ├── app.dart            # Configuração principal do MaterialApp
│   │   └── main.dart           # Entrada principal da execução (main)
│   ├── pubspec.yaml            # Dependências e assets do Flutter
│   └── README.md               # Instruções de compilação e execução
```

---

## 5. Convenções

*   **Nomenclatura (Dart):** Seguir as diretrizes oficiais do *Effective Dart*. Classes e tipos em `PascalCase`, variáveis, métodos e parâmetros em `camelCase`, arquivos e diretórios em `snake_case`.
*   **Componentização:** Widgets reutilizáveis devem ser isolados em `core/widgets` ou na pasta local da feature, mantendo o estado o mais granular possível.
*   **Commits (Git):** Padrão Conventional Commits (ex: `feat: adiciona busca na open library`, `fix: corrige envio de mensagem nula`).

---

## 6. Serviços

*   **Serviço de Autenticação (`/auth`):** Permite login de usuários, autocadastro de Leitores e guarda a sessão ativa no SharedPreferences.
*   **Serviço de Leitores (`/reader`):** Feed público, listagem geral de livros, gerenciamento de conversas, envio de mensagens e registros de leituras.
*   **Serviço do Editor (`/editor`):** Gerenciamento do catálogo da editora conectada e respostas a solicitações.
*   **Serviço do Administrador (`/admin`):** Moderação de contas e estatísticas de uso.

---

## 7. Variáveis e Configurações Locais

Os dados locais e configurações sensíveis do dispositivo móvel são mantidos em armazenamento local via chave-valor:

| Chave de Armazenamento | Finalidade | Exemplo de Valor |
| :--- | :--- | :--- |
| `api_base_url_override` | Endereço personalizado da API REST. | `http://10.0.3.2:5000` |
| `doc.jwt` | Token JWT da sessão atual do usuário. | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` |
| `doc.role` | Papel associado ao usuário (`admin`, `leitor`, `editor`). | `leitor` |
| `doc.name` | Nome exibido do usuário conectado. | `Eduardo Baranowski` |
| `doc.image` | URL da imagem de perfil (avatar) do usuário. | `/static/uploads/avatar_1.png` |

---

## 8. Definição de Usuários e Fluxo de Cadastro

*   **Leitor (Autocadastro):**
    1. Acessa a tela de registro no aplicativo.
    2. Preenche nome, e-mail, senha e envia.
    3. O aplicativo faz a requisição `/auth/register` e inicia a sessão automaticamente.
*   **Editora (Cadastro pelo Admin):**
    1. Criada via endpoint administrativo. As credenciais são inseridas no banco.
    2. O usuário faz login com o e-mail da editora diretamente na tela de login do aplicativo.
*   **Fluxo de Login:**
    1. Usuário informa e-mail e senha.
    2. Aplicativo valida localmente e envia para `/auth/login`.
    3. O token JWT retornado é salvo no cache local do dispositivo junto com o perfil e nome do usuário.

---

# 4. Especificação Técnica (Spec)

## 4.1. Mobile Application (Flutter)

```text
/lib/main.dart
- ação: consultar
- descrição: Ponto de entrada do aplicativo. Inicializa os bindings visuais, carrega as configurações locais de URL da API e roda o widget principal envelopado no ProviderScope do Riverpod.
- pseudocódigo:
  INICIAR Função main() ASSÍNCRONA:
    CHAMAR WidgetsFlutterBinding.ensureInitialized()
    AGUARDAR ApiConfig.instance.load()
    CHAMAR runApp(
      ProviderScope(
        child: LuminaApp()
      )
    )
```

```text
/lib/app.dart
- ação: consultar
- descrição: Widget raiz da aplicação móvel. Configura o título do aplicativo, desativa a faixa de debug, define a paleta e tema Stitch "Bibliotheca Aesthetic" e injeta as definições do GoRouter.
- pseudocódigo:
  CLASSE LuminaApp EXTENDE ConsumerWidget:
    METODO build(context, ref):
      router = ESCUTAR appRouterProvider
      RETORNAR MaterialApp.router(
        title: 'Bibliotheca',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: router
      )
```

```text
/lib/config/api_config.dart
- ação: modificar
- descrição: Singleton responsável por gerenciar a URL de conexão com a API REST. Permite obter URLs de fallback baseadas na plataforma (como 10.0.3.2 para Genymotion no Android) ou aplicar uma URL de substituição digitada pelo usuário na tela de configurações.
- pseudocódigo:
  CLASSE ApiConfig:
    ATRIBUTOS: _override, _prefsKey = 'api_base_url_override'
    METODO load() ASSÍNCRONO:
      prefs = AGUARDAR SharedPreferences.getInstance()
      _override = prefs.getString(_prefsKey) sem espaços nas bordas
    METODO baseUrl RETORNA String:
      SE _override não for nulo/vazio: RETORNAR _override
      envVar = String.fromEnvironment('API_BASE_URL')
      SE envVar não for vazia: RETORNAR envVar
      SE Plataforma for Android: RETORNAR 'http://10.0.3.2:5000'
      RETORNAR 'http://127.0.0.1:5000'
    METODO setOverride(url) ASSÍNCRONO:
      prefs = AGUARDAR SharedPreferences.getInstance()
      SE url for nulo/vazio:
        _override = nulo
        AGUARDAR prefs.remove(_prefsKey)
      SENÃO:
        _override = url formatado
        AGUARDAR prefs.setString(_prefsKey, _override)
```

```text
/lib/core/api/api_client.dart
- ação: consultar
- descrição: Cliente de comunicação HTTP que encapsula as requisições GET, POST, PUT, DELETE e Multipart. Adiciona automaticamente os cabeçalhos de autorização Bearer JWT e manipula erros de rede ou de status HTTP não autorizados (401).
- pseudocódigo:
  CLASSE ApiClient:
    CONSTRUTOR(getToken, onUnauthorized)
    METODO PRIVADO _headers(jsonBody) ASSÍNCRONO:
      headers = {'Accept': 'application/json'}
      SE jsonBody for verdadeiro: headers['Content-Type'] = 'application/json'
      token = AGUARDAR getToken()
      SE token não for nulo: headers['Authorization'] = 'Bearer ' + token
      RETORNAR headers
    METODO PRIVADO _handleResponse(res) ASSÍNCRONO:
      SE res.statusCode == 401 e onUnauthorized for fornecido:
        AGUARDAR onUnauthorized()
      body = decodificarJSON(res.body)
      SE res.statusCode >= 200 e res.statusCode < 300:
        RETORNAR body
      mensagem_erro = extrairMensagem(body) ou res.reasonPhrase
      LANÇAR ApiException(res.statusCode, mensagem_erro)
    METODO get(path, query, parser) ASSÍNCRONO:
      headers = AGUARDAR _headers()
      RETORNAR _send(() => http.get(_uri(path, query), headers), parser)
    METODO post(path, body, parser) ASSÍNCRONO:
      headers = AGUARDAR _headers(jsonBody: body != nulo)
      RETORNAR _send(() => http.post(_uri(path), headers, codificar(body)), parser)
```

```text
/lib/core/auth/auth_notifier.dart
- ação: modificar
- descrição: StateNotifier encarregado de sincronizar e expor o estado de login e perfil do usuário ativo. Controla persistência no TokenStorage e dispara transições de tela no router ao atualizar o estado.
- pseudocódigo:
  CLASSE AuthNotifier EXTENDE StateNotifier<AuthState>:
    CONSTRUTOR(storage): _restore()
    METODO _restore() ASSÍNCRONO:
      token = AGUARDAR storage.getToken()
      SE token não nulo:
        state = AuthState(token, role, name, imageUrl)
    METODO login(api, email, senha) ASSÍNCRONO:
      state = state.copyWith(isLoading: true)
      TENTAR:
        res = AGUARDAR api.post('/auth/login', {'email': email, 'senha': senha})
        dados = LoginResponse.fromJson(res)
        AGUARDAR storage.saveSession(dados)
        state = AuthState(dados)
      FINAMENTE:
        state = state.copyWith(isLoading: false)
    METODO logout() ASSÍNCRONO:
      AGUARDAR storage.clear()
      state = AuthState vazio
```

```text
/lib/routing/app_router.dart
- ação: consultar
- descrição: Centraliza as rotas da aplicação usando o GoRouter. Implementa interceptação de navegação (guards) baseada no status de autenticação e no papel do usuário conectado (impedindo leitores de acessarem rotas administrativas e editores de acessarem recursos de leitores).
- pseudocódigo:
  PROVEDOR appRouterProvider:
    auth = ESCUTAR authProvider
    RETORNAR GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        path = state.uri.path
        isAuthRoute = path == '/entrar' ou '/cadastro'
        needsAuth = path.startsWith('/mensagens') ou '/admin' ou '/editor/'
        SE needsAuth e NÃO auth.isAuthenticated:
          RETORNAR '/entrar'
        SE isAuthRoute e auth.isAuthenticated:
          RETORNAR '/'
        SE path.startsWith('/admin') e auth.role não for Admin:
          RETORNAR '/'
        SE path.startsWith('/editor/') e auth.role não for Editor:
          RETORNAR '/'
        RETORNAR nulo
      },
      routes: [
        StatefulShellRoute (MainShell com abas: /, /livros, /buscar, /conta),
        Rota '/livro/:id' -> BookDetailScreen,
        Rota '/entrar' -> LoginScreen,
        Rota '/cadastro' -> RegisterScreen,
        Rota '/mensagens' -> ConversationsScreen,
        Rota '/mensagens/:userId' -> ChatScreen,
        Rota '/admin/usuarios' -> AdminUsersScreen,
        Rota '/admin/relatorios' -> AdminReportsScreen,
        Rota '/editor/livro/novo' -> EditorBookFormScreen,
        Rota '/editor/livro/:id' -> EditorBookFormScreen,
        Rota '/editor/solicitacoes' -> EditorRequestsScreen
      ]
    )
```

```text
/lib/data/reader_repository.dart
- ação: consultar
- descrição: Repositório que expõe endpoints de leitores e interações sociais da API.
- pseudocódigo:
  CLASSE ReaderRepository:
    METODO feed(page) RETORNA PaginatedResponse<FeedItem>:
      RETORNAR api.get('/reader/feed', query: {page}, parser: FeedItem.fromJson)
    METODO books(page, genero) RETORNA PaginatedResponse<Book>:
      RETORNAR api.get('/reader/books', query: {page, genero}, parser: Book.fromJson)
    METODO messagesWith(userId, afterId) RETORNA List<DirectMessage>:
      RETORNAR api.get('/reader/users/userId/messages', query: {afterId}, parser: DirectMessage.fromJsonList)
    METODO registerReading(livroId, status, nota, comentario) ASSÍNCRONO:
      AGUARDAR api.post('/reader/readings', {'livro_id': livroId, 'status': status, 'nota': nota, 'comentario': comentario})
```

```text
/lib/data/editor_repository.dart
- ação: consultar
- descrição: Repositório para o gerenciamento de catálogos e livros pelas editoras, incluindo busca externa de livros na API Open Library.
- pseudocódigo:
  CLASSE EditorRepository:
    METODO listBooks(page, q) RETORNA PaginatedResponse<EditorBook>:
      RETORNAR api.get('/editor/books', query: {page, q}, parser: EditorBook.fromJson)
    METODO lookupBooks(q) RETORNA BookLookupResponse:
      RETORNAR api.get('/editor/books/lookup', query: {q}, parser: BookLookupResponse.fromJson)
    METODO createBook(titulo, autor, preco, estoque, genero, openLibraryCoverId) ASSÍNCRONO:
      AGUARDAR api.postMultipart('/editor/books', fields: {titulo, autor, preco, estoque, genero, openLibraryCoverId})
    METODO respondRequest(id, resposta) ASSÍNCRONO:
      AGUARDAR api.put('/editor/requests/id/respond', {'resposta': resposta})
```

```text
/lib/features/home/home_screen.dart
- ação: consultar
- descrição: Tela inicial do aplicativo. Mostra uma seção horizontal de destaques de livros à venda e uma listagem paginada (feed infinito) das atividades de leitura dos usuários seguidos.
- pseudocódigo:
  CLASSE HomeScreen EXTENDE ConsumerStatefulWidget:
    METODO initState():
      AGUARDAR carregarLivrosDestaque()
      AGUARDAR carregarFeed(page: 1)
      escutarScrollParaCarregarMais()
    METODO build(context):
      RETORNAR RefreshIndicator(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(carrosselHorizontalDeLivros),
            SliverList(listaDeAtividadesDoFeed)
          ]
        )
      )
```

```text
/lib/features/books/book_detail_screen.dart
- ação: consultar
- descrição: Exibe a ficha de metadados de um livro específico. Permite ao leitor registrar ou editar o status de sua leitura (quero ler, lendo, lido) através de um diálogo modal e redireciona para iniciar chat com a editora proprietária.
- pseudocódigo:
  CLASSE BookDetailScreen EXTENDE ConsumerStatefulWidget:
    METODO build(context):
      livro = ESCUTAR FutureProvider de obterDetalhes(bookId)
      RETORNAR livro.quando(
        dados: (b) => Column(
          exibirImagem(b.imagemUrl),
          exibirDetalhes(b.titulo, b.autor, b.preco, b.estoque),
          SE leitorAutenticado:
            Botao "Registrar Leitura" -> abrirDiálogoDeLeitura(
              Ao Salvar: chamar readerRepository.registerReading(b.id, status, nota, comentario)
            ),
          Botao "Conversar com Editora" -> navegarPara('/mensagens/b.editoraId?nome=b.editoraNome')
        )
      )
```

```text
/lib/features/messages/chat_screen.dart
- action: consultar
- descrição: Tela de chat de mensagens diretas entre usuários e editoras. Implementa um temporizador interno de polling de 3 segundos para manter o histórico atualizado em tempo real.
- pseudocódigo:
  CLASSE ChatScreen EXTENDE ConsumerStatefulWidget:
    METODO initState():
      AGUARDAR carregarMensagensIniciais()
      timer = Timer.periodic(3 segundos, (_) => verificarNovasMensagens())
    METODO dispose():
      timer.cancel()
    METODO enviarMensagem() ASSÍNCRONO:
      texto = controller.text
      SE texto vazio: RETORNAR
      AGUARDAR readerRepository.sendMessage(userId, texto)
      verificarNovasMensagens()
    METODO build(context):
      RETORNAR Scaffold(
        corpo: ListaDeBaloesDeMensagens,
        barra_inferior: TextField + BotaoEnviar
      )
```

```text
/lib/features/editor/editor_book_form_screen.dart
- ação: criar
- descrição: Tela com formulário para cadastro ou edição de livros por parte da editora. Oferece funcionalidade de auto-preenchimento integrada com a Open Library baseada em termo de busca (ISBN ou título).
- pseudocódigo:
  CLASSE EditorBookFormScreen EXTENDE ConsumerStatefulWidget:
    METODO autoPreencherOpenLibrary() ASSÍNCRONO:
      pesquisa = _tituloController.text
      SE pesquisa vazia: RETORNAR
      res = AGUARDAR editorRepository.lookupBooks(pesquisa)
      SE res.items não vazio:
        livroOL = res.items.first
        _tituloController.text = livroOL.titulo
        _autorController.text = livroOL.autor
        _generoController.text = livroOL.genero
        _openLibraryCoverId = livroOL.coverId
    METODO salvarLivro() ASSÍNCRONO:
      SE formularioValido:
        SE editando:
          AGUARDAR editorRepository.updateBook(id, titulo, autor, preco, estoque, genero, _openLibraryCoverId)
        SENÃO:
          AGUARDAR editorRepository.createBook(titulo, autor, preco, estoque, genero, _openLibraryCoverId)
        voltarTela()
```
