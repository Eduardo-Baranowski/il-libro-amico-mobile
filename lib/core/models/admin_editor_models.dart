import 'user_role.dart';

class Editora {
  Editora({
    required this.id,
    required this.nome,
    this.imagemUrl,
    required this.criadoEm,
  });

  final int id;
  final String nome;
  final String? imagemUrl;
  final String criadoEm;

  factory Editora.fromJson(Map<String, dynamic> json) => Editora(
        id: json['id'] as int,
        nome: json['nome'] as String? ?? '',
        imagemUrl: json['imagem_url'] as String?,
        criadoEm: json['criado_em'] as String? ?? '',
      );
}

class NacionalidadeAdmin {
  NacionalidadeAdmin({
    required this.id,
    required this.nome,
    this.flagUrl,
    required this.criadoEm,
  });

  final int id;
  final String nome;
  final String? flagUrl;
  final String criadoEm;

  factory NacionalidadeAdmin.fromJson(Map<String, dynamic> json) => NacionalidadeAdmin(
        id: json['id'] as int,
        nome: json['nome'] as String? ?? '',
        flagUrl: json['flag'] as String?,
        criadoEm: json['criado_em'] as String? ?? '',
      );
}

class AdminAuthor {
  AdminAuthor({
    required this.id,
    required this.nome,
    this.imagemUrl,
    this.nacionalidade,
  });

  final int id;
  final String nome;
  final String? imagemUrl;
  final String? nacionalidade;

  factory AdminAuthor.fromJson(Map<String, dynamic> json) => AdminAuthor(
        id: json['id'] as int,
        nome: json['nome'] as String? ?? '',
        imagemUrl: json['imagem_url'] as String?,
        nacionalidade: json['nacionalidade'] as String?,
      );
}

class AdminAuthorDetail {
  AdminAuthorDetail({
    required this.id,
    required this.nome,
    this.bio,
    this.imagemUrl,
    this.nacionalidade,
  });

  final int id;
  final String nome;
  final String? bio;
  final String? imagemUrl;
  final String? nacionalidade;

  factory AdminAuthorDetail.fromJson(Map<String, dynamic> json) => AdminAuthorDetail(
        id: json['id'] as int,
        nome: json['nome'] as String? ?? '',
        bio: json['bio'] as String?,
        imagemUrl: json['imagem_url'] as String?,
        nacionalidade: json['nacionalidade'] as String?,
      );
}

class AdminUser {
  AdminUser({
    required this.id,
    required this.nome,
    required this.email,
    required this.papel,
  });

  final int id;
  final String nome;
  final String email;
  final UserRole papel;

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: json['id'] as int,
        nome: json['nome'] as String? ?? '',
        email: json['email'] as String? ?? '',
        papel: UserRoleX.tryParse(json['papel'] as String?) ?? UserRole.leitor,
      );
}

class AdminReport {
  AdminReport({
    required this.totalUsuarios,
    required this.totalLivros,
    required this.usuarios,
    required this.solicitacoes,
  });

  final int totalUsuarios;
  final int totalLivros;
  final Map<String, int> usuarios;
  final Map<String, int> solicitacoes;

  factory AdminReport.fromJson(Map<String, dynamic> json) {
    Map<String, int> mapInt(dynamic raw) {
      if (raw is! Map) return {};
      return raw.map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0));
    }

    return AdminReport(
      totalUsuarios: json['total_usuarios'] as int? ?? 0,
      totalLivros: json['total_livros'] as int? ?? 0,
      usuarios: mapInt(json['usuarios']),
      solicitacoes: mapInt(json['solicitacoes']),
    );
  }
}

class BookLookupItem {
  BookLookupItem({
    required this.titulo,
    required this.autor,
    this.editora,
    this.descricao,
    this.genero,
    this.ano,
    this.isbn,
    this.coverId,
    this.imagemUrl,
    this.fonte,
    this.openLibraryKey,
  });

  final String titulo;
  final String autor;
  final String? editora;
  final String? descricao;
  final String? genero;
  final int? ano;
  final String? isbn;
  final int? coverId;
  final String? imagemUrl;
  final String? fonte;
  final String? openLibraryKey;

  factory BookLookupItem.fromJson(Map<String, dynamic> json) => BookLookupItem(
        titulo: json['titulo'] as String? ?? '',
        autor: json['autor'] as String? ?? '',
        editora: json['editora'] as String?,
        descricao: json['descricao'] as String?,
        genero: json['genero'] as String?,
        ano: json['ano'] as int?,
        isbn: json['isbn'] as String?,
        coverId: json['cover_id'] as int?,
        imagemUrl: json['imagem_url'] as String?,
        fonte: json['fonte'] as String?,
        openLibraryKey: json['open_library_key'] as String?,
      );
}

class BookLookupResponse {
  BookLookupResponse({
    required this.items,
    this.fonte = 'open_library',
    this.existingBook,
  });

  final List<BookLookupItem> items;
  final String fonte;
  final ExistingBookHit? existingBook;

  factory BookLookupResponse.fromJson(Map<String, dynamic> json) => BookLookupResponse(
        items: (json['items'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(BookLookupItem.fromJson)
            .toList(),
        fonte: json['fonte'] as String? ?? 'open_library',
        existingBook: json['existing_book'] is Map<String, dynamic>
            ? ExistingBookHit.fromJson(json['existing_book'] as Map<String, dynamic>)
            : null,
      );
}

class ExistingBookHit {
  ExistingBookHit({required this.id, required this.titulo, required this.autor});

  final int id;
  final String titulo;
  final String autor;

  factory ExistingBookHit.fromJson(Map<String, dynamic> json) => ExistingBookHit(
        id: json['id'] as int,
        titulo: json['titulo'] as String? ?? '',
        autor: json['autor'] as String? ?? '',
      );
}

class EditorBook {
  EditorBook({
    required this.id,
    required this.titulo,
    required this.autor,
    required this.preco,
    required this.estoque,
    this.genero,
    this.descricao,
    this.imagemUrl,
    this.condicao,
    this.paginas = 0,
  });

  final int id;
  final String titulo;
  final String autor;
  final String preco;
  final int estoque;
  final String? genero;
  final String? descricao;
  final String? imagemUrl;
  final String? condicao;
  final int paginas;

  factory EditorBook.fromJson(Map<String, dynamic> json) => EditorBook(
        id: json['id'] as int,
        titulo: json['titulo'] as String? ?? '',
        autor: json['autor'] as String? ?? '',
        preco: json['preco']?.toString() ?? '0',
        estoque: json['estoque'] as int? ?? 0,
        genero: json['genero'] as String?,
        descricao: json['descricao'] as String?,
        imagemUrl: json['imagem_url'] as String?,
        condicao: json['condicao'] as String? ?? 'novo',
        paginas: json['paginas'] as int? ?? 0,
      );
}

class EditorRequest {
  EditorRequest({
    required this.id,
    required this.leitorId,
    required this.leitorNome,
    this.livroTitulo,
    this.livroAutor,
    this.livroImagemUrl,
    required this.conteudo,
    this.resposta,
    required this.status,
    this.dataCriacao,
  });

  final int id;
  final int leitorId;
  final String leitorNome;
  final String? livroTitulo;
  final String? livroAutor;
  final String? livroImagemUrl;
  final String conteudo;
  final String? resposta;
  final String status;
  final String? dataCriacao;

  factory EditorRequest.fromJson(Map<String, dynamic> json) => EditorRequest(
        id: json['id'] as int,
        leitorId: json['leitor_id'] as int,
        leitorNome: json['leitor_nome'] as String? ?? '',
        livroTitulo: json['livro_titulo'] as String?,
        livroAutor: json['livro_autor'] as String?,
        livroImagemUrl: json['livro_imagem_url'] as String?,
        conteudo: json['conteudo'] as String? ?? '',
        resposta: json['resposta'] as String?,
        status: json['status'] as String? ?? 'pendente',
        dataCriacao: json['data_criacao'] as String?,
      );
}

class GlobalSearchResult {
  GlobalSearchResult({
    required this.books,
    required this.users,
    required this.editors,
  });

  final List<SearchBookHit> books;
  final List<SearchUserHit> users;
  final List<SearchEditorHit> editors;
}

class SearchBookHit {
  SearchBookHit({
    required this.id,
    required this.titulo,
    required this.autor,
    this.imagemUrl,
    required this.preco,
    required this.editora,
  });

  final int id;
  final String titulo;
  final String autor;
  final String? imagemUrl;
  final String preco;
  final String editora;

  factory SearchBookHit.fromJson(Map<String, dynamic> json) => SearchBookHit(
        id: json['id'] as int,
        titulo: json['titulo'] as String? ?? '',
        autor: json['autor'] as String? ?? '',
        imagemUrl: json['imagem_url'] as String?,
        preco: json['preco']?.toString() ?? '0',
        editora: json['editora'] as String? ?? '',
      );
}

class SearchUserHit {
  SearchUserHit({
    required this.id,
    required this.nome,
    required this.papel,
    this.imagemUrl,
  });

  final int id;
  final String nome;
  final UserRole papel;
  final String? imagemUrl;

  factory SearchUserHit.fromJson(Map<String, dynamic> json) => SearchUserHit(
        id: json['id'] as int,
        nome: json['nome'] as String? ?? '',
        papel: UserRoleX.tryParse(json['papel'] as String?) ?? UserRole.leitor,
        imagemUrl: json['imagem_url'] as String?,
      );
}

class SearchEditorHit {
  SearchEditorHit({
    required this.id,
    required this.nome,
    this.imagemUrl,
  });

  final int id;
  final String nome;
  final String? imagemUrl;

  factory SearchEditorHit.fromJson(Map<String, dynamic> json) => SearchEditorHit(
        id: json['id'] as int,
        nome: json['nome'] as String? ?? '',
        imagemUrl: json['imagem_url'] as String?,
      );
}

class AdminBook {
  AdminBook({
    required this.id,
    required this.titulo,
    required this.autor,
    this.autorNacionalidade,
    required this.editorNome,
    this.editorId,
    this.editoraId,
    required this.preco,
    required this.estoque,
    this.genero,
    this.dataCadastro,
  });

  final int id;
  final String titulo;
  final String autor;
  final String? autorNacionalidade;
  final String editorNome;
  final int? editorId;
  final int? editoraId;
  final String preco;
  final int estoque;
  final String? genero;
  final String? dataCadastro;

  factory AdminBook.fromJson(Map<String, dynamic> json) => AdminBook(
        id: json['id'] as int,
        titulo: json['titulo'] as String? ?? '',
      autor: json['autor'] as String? ?? '',
      autorNacionalidade: json['author_nationality'] as String? ?? json['autor_nacionalidade'] as String? ?? json['nacionalidade_autor'] as String?,
        editorNome: json['editor_nome'] as String? ?? '',
        editorId: json['editor_id'] as int?,
        editoraId: json['editora_id'] as int?,
        preco: json['preco']?.toString() ?? '0',
        estoque: json['estoque'] as int? ?? 0,
        genero: json['genero'] as String?,
        dataCadastro: json['data_cadastro'] as String?,
      );
}

class AdminBookDetail {
  AdminBookDetail({
    required this.id,
    required this.titulo,
    required this.autor,
    required this.editorNome,
    this.editorId,
    this.editoraId,
    required this.preco,
    required this.estoque,
    this.genero,
    this.descricao,
    this.imagemUrl,
    this.autorNacionalidade,
    this.paginas = 0,
  });

  final int id;
  final String titulo;
  final String autor;
  final String editorNome;
  final int? editorId;
  final int? editoraId;
  final String preco;
  final int estoque;
  final String? genero;
  final String? descricao;
  final String? imagemUrl;
  final String? autorNacionalidade;
  final int paginas;

  factory AdminBookDetail.fromJson(Map<String, dynamic> json) => AdminBookDetail(
        id: json['id'] as int,
        titulo: json['titulo'] as String? ?? '',
        autor: json['autor'] as String? ?? '',
        editorNome: json['editor_nome'] as String? ?? '',
        editorId: json['editor_id'] as int?,
        editoraId: json['editora_id'] as int?,
        preco: json['preco']?.toString() ?? '0',
        estoque: json['estoque'] as int? ?? 0,
        genero: json['genero'] as String?,
        descricao: json['descricao'] as String?,
        imagemUrl: json['imagem_url'] as String?,
        autorNacionalidade: json['author_nationality'] as String? ?? json['autor_nacionalidade'] as String? ?? json['nacionalidade_autor'] as String?,
        paginas: json['paginas'] as int? ?? 0,
      );
}
