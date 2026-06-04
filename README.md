# Bibliotheca — Mobile (Flutter)

App Flutter para a API REST do projeto [`doc`](../doc). Interface inspirada no design Stitch **Bibliotheca Aesthetic** (parchment, terracotta, Literata + Plus Jakarta Sans).

## Pré-requisitos

- Flutter SDK (stable) em `PATH`
- API Flask rodando (local ou Docker)

## Configuração da API

Por padrão:

| Plataforma | URL |
|------------|-----|
| **Genymotion** (padrão Android) | `http://10.0.3.2:5000` |
| Android Studio AVD | `http://10.0.2.2:5000` |
| iOS simulador / Linux / macOS | `http://127.0.0.1:5000` |

Na aba **Conta** do app dá para alterar a URL sem recompilar.

Dispositivo físico ou API em outra máquina:

```bash
flutter run --dart-define=API_BASE_URL=http://10.24.0.243:5000
```

Com Docker Compose do projeto `doc`:

```bash
cd ../doc && docker compose up -d
cd ../mobile && flutter run
```

## Executar

```bash
cd /home/ebaranowski/Documents/dev/mobile
flutter pub get
flutter run
```

Web (opcional):

```bash
flutter run -d chrome
```

## Funcionalidades

- Feed da comunidade (`/reader/feed`)
- Catálogo e detalhe do livro (leitores) / **meu catálogo** com CRUD (editores)
- **Busca global** (`/reader/search`) — livros, usuários e editoras
- Login / cadastro de leitor
- Mensagens (lista + chat com polling)
- Conta e logout
- **Admin:** usuários e relatórios (`/admin/*`)
- **Editor:** solicitações, criar/editar/arquivar livros; busca Open Library por título/autor/ISBN (`/editor/books/lookup`)

## Estrutura

```
lib/
  config/          # API_BASE_URL
  core/            # API, auth, models, theme, widgets
  data/            # ReaderRepository
  features/        # telas por domínio
  routing/         # go_router + shell com abas
```

## Testes

```bash
flutter analyze
flutter test
```
