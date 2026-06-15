import 'user_role.dart';

export 'user_role.dart';

class PaginatedResponse<T> {
  PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pages,
  });

  final List<T> items;
  final int total;
  final int page;
  final int pages;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final raw = json['items'];
    return PaginatedResponse(
      items: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(fromItem)
              .toList()
          : [],
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pages: json['pages'] as int? ?? 1,
    );
  }
}

class LoginResponse {
  LoginResponse({
    required this.token,
    required this.role,
    required this.name,
    this.imageUrl,
  });

  final String token;
  final UserRole role;
  final String name;
  final String? imageUrl;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final role = UserRoleX.tryParse(json['papel'] as String?) ?? UserRole.leitor;
    return LoginResponse(
      token: json['token_sessao'] as String,
      role: role,
      name: json['nome'] as String? ?? '',
      imageUrl: json['imagem_url'] as String?,
    );
  }
}

class Book {
  Book({
    required this.id,
    required this.titulo,
    required this.autor,
    required this.preco,
    required this.estoque,
    required this.editorId,
    required this.editora,
    this.genero,
    this.descricao,
    this.imagemUrl,
    this.statusEstoque,
    this.condicao,
  });

  final int id;
  final String titulo;
  final String autor;
  final String preco;
  final int estoque;
  final int editorId;
  final String editora;
  final String? genero;
  final String? descricao;
  final String? imagemUrl;
  final String? statusEstoque;
  final String? condicao;

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: json['id'] as int,
        titulo: json['titulo'] as String? ?? '',
        autor: json['autor'] as String? ?? '',
        preco: json['preco']?.toString() ?? '0',
        estoque: json['estoque'] as int? ?? 0,
        editorId: json['editor_id'] as int? ?? 0,
        editora: json['editora'] as String? ?? '',
        genero: json['genero'] as String?,
        descricao: json['descricao'] as String?,
        imagemUrl: json['imagem_url'] as String?,
        statusEstoque: json['status_estoque'] as String?,
        condicao: json['condicao'] as String? ?? 'novo',
      );
}

class BookDetails extends Book {
  BookDetails({
    required super.id,
    required super.titulo,
    required super.autor,
    required super.preco,
    required super.estoque,
    required super.editorId,
    required super.editora,
    super.genero,
    super.descricao,
    super.imagemUrl,
    super.statusEstoque,
    this.editoraImagemUrl,
    this.myReading,
  });

  final String? editoraImagemUrl;
  final MyReadingStatus? myReading;

  factory BookDetails.fromJson(Map<String, dynamic> json) {
    final reading = json['my_reading'];
    return BookDetails(
      id: json['id'] as int,
      titulo: json['titulo'] as String? ?? '',
      autor: json['autor'] as String? ?? '',
      preco: json['preco']?.toString() ?? '0',
      estoque: json['estoque'] as int? ?? 0,
      editorId: json['editor_id'] as int? ?? 0,
      editora: json['editora'] as String? ?? '',
      genero: json['genero'] as String?,
      descricao: json['descricao'] as String?,
      imagemUrl: json['imagem_url'] as String?,
      statusEstoque: json['status_estoque'] as String?,
      editoraImagemUrl: json['editora_imagem_url'] as String?,
      myReading: reading is Map<String, dynamic>
          ? MyReadingStatus.fromJson(reading)
          : null,
    );
  }
}

class MyReadingStatus {
  MyReadingStatus({required this.id, required this.status, this.nota, this.comentario});

  final int id;
  final String status;
  final int? nota;
  final String? comentario;

  factory MyReadingStatus.fromJson(Map<String, dynamic> json) =>
      MyReadingStatus(
        id: json['id'] as int? ?? 0,
        status: json['status'] as String? ?? 'lendo',
        nota: json['nota'] as int?,
        comentario: json['comentario'] as String?,
      );
}

class FeedItem {
  FeedItem({
    required this.id,
    required this.leitorId,
    required this.leitorNome,
    required this.leitorImagemUrl,
    required this.livroTitulo,
    required this.livroAutor,
    required this.livroImagemUrl,
    required this.livroId,
    required this.status,
    this.nota,
    this.comentario,
    this.criadoEm,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.likedByMe = false,
  });

  final int id;
  final int leitorId;
  final String leitorNome;
  final String? leitorImagemUrl;
  final String livroTitulo;
  final String livroAutor;
  final String? livroImagemUrl;
  final int livroId;
  final String status;
  final int? nota;
  final String? comentario;
  final String? criadoEm;
  final int likesCount;
  final int commentsCount;
  final bool likedByMe;

  FeedItem copyWith({
    int? likesCount,
    int? commentsCount,
    bool? likedByMe,
  }) =>
      FeedItem(
        id: id,
        leitorId: leitorId,
        leitorNome: leitorNome,
        leitorImagemUrl: leitorImagemUrl,
        livroTitulo: livroTitulo,
        livroAutor: livroAutor,
        livroImagemUrl: livroImagemUrl,
        livroId: livroId,
        status: status,
        nota: nota,
        comentario: comentario,
        criadoEm: criadoEm,
        likesCount: likesCount ?? this.likesCount,
        commentsCount: commentsCount ?? this.commentsCount,
        likedByMe: likedByMe ?? this.likedByMe,
      );

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    final leitor = json['leitor'] as Map<String, dynamic>? ?? {};
    final livro = json['livro'] as Map<String, dynamic>? ?? {};
    return FeedItem(
      id: json['id'] as int,
      leitorId: leitor['id'] as int? ?? 0,
      leitorNome: leitor['nome'] as String? ?? '',
      leitorImagemUrl: leitor['imagem_url'] as String?,
      livroTitulo: livro['titulo'] as String? ?? '',
      livroAutor: livro['autor'] as String? ?? '',
      livroImagemUrl: livro['imagem_url'] as String?,
      livroId: livro['id'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      nota: json['nota'] as int?,
      comentario: json['comentario'] as String?,
      criadoEm: json['criado_em'] as String?,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      likedByMe: json['liked_by_me'] as bool? ?? false,
    );
  }
}

class ReadingItem {
  ReadingItem({
    required this.id,
    required this.livroId,
    required this.titulo,
    required this.autor,
    this.imagemUrl,
    required this.status,
    this.nota,
    this.comentario,
  });

  final int id;
  final int livroId;
  final String titulo;
  final String autor;
  final String? imagemUrl;
  final String status;
  final int? nota;
  final String? comentario;

  factory ReadingItem.fromJson(Map<String, dynamic> json) {
    final livro = json['livro'] as Map<String, dynamic>? ?? {};
    return ReadingItem(
      id: json['id'] as int,
      livroId: livro['id'] as int? ?? 0,
      titulo: livro['titulo'] as String? ?? '',
      autor: livro['autor'] as String? ?? '',
      imagemUrl: livro['imagem_url'] as String?,
      status: json['status'] as String? ?? '',
      nota: json['nota'] as int?,
      comentario: json['comentario'] as String?,
    );
  }
}

class BookReview {
  BookReview({
    required this.id,
    required this.leitorId,
    required this.leitorNome,
    this.leitorImagemUrl,
    this.nota,
    this.comentario,
    required this.status,
  });

  final int id;
  final int leitorId;
  final String leitorNome;
  final String? leitorImagemUrl;
  final int? nota;
  final String? comentario;
  final String status;

  factory BookReview.fromJson(Map<String, dynamic> json) => BookReview(
        id: json['id'] as int,
        leitorId: json['leitor_id'] as int? ?? 0,
        leitorNome: json['leitor_nome'] as String? ?? '',
        leitorImagemUrl: json['leitor_imagem_url'] as String?,
        nota: json['nota'] as int?,
        comentario: json['comentario'] as String?,
        status: json['status'] as String? ?? '',
      );
}

class FeedComment {
  FeedComment({
    required this.id,
    required this.userNome,
    this.userImagemUrl,
    required this.conteudo,
    this.criadoEm,
  });

  final int id;
  final String userNome;
  final String? userImagemUrl;
  final String conteudo;
  final String? criadoEm;

  factory FeedComment.fromJson(Map<String, dynamic> json) => FeedComment(
        id: json['id'] as int,
        userNome: json['user_nome'] as String? ?? '',
        userImagemUrl: json['user_imagem_url'] as String?,
        conteudo: json['conteudo'] as String? ?? '',
        criadoEm: json['criado_em'] as String?,
      );
}

class RecommendedBook {
  RecommendedBook({
    required this.id,
    required this.titulo,
    required this.autor,
    this.imagemUrl,
    required this.averageRating,
  });

  final int id;
  final String titulo;
  final String autor;
  final String? imagemUrl;
  final double averageRating;

  factory RecommendedBook.fromJson(Map<String, dynamic> json) =>
      RecommendedBook(
        id: json['id'] as int,
        titulo: json['titulo'] as String? ?? '',
        autor: json['autor'] as String? ?? '',
        imagemUrl: json['imagem_url'] as String?,
        averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
      );
}

class Conversation {
  Conversation({
    required this.userId,
    required this.userNome,
    this.userImagemUrl,
    required this.lastMessage,
    this.lastMessageTime,
    required this.unreadCount,
  });

  final int userId;
  final String userNome;
  final String? userImagemUrl;
  final String lastMessage;
  final String? lastMessageTime;
  final int unreadCount;

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        userId: json['user_id'] as int,
        userNome: json['user_nome'] as String? ?? '',
        userImagemUrl: json['user_imagem_url'] as String?,
        lastMessage: json['last_message'] as String? ?? '',
        lastMessageTime: json['last_message_time'] as String?,
        unreadCount: json['unread_count'] as int? ?? 0,
      );
}

class DirectMessage {
  DirectMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.conteudo,
    required this.lida,
    this.dataEnvio,
  });

  final int id;
  final int senderId;
  final int receiverId;
  final String conteudo;
  final bool lida;
  final String? dataEnvio;

  factory DirectMessage.fromJson(Map<String, dynamic> json) => DirectMessage(
        id: json['id'] as int,
        senderId: json['sender_id'] as int,
        receiverId: json['receiver_id'] as int,
        conteudo: json['conteudo'] as String? ?? '',
        lida: json['lida'] as bool? ?? false,
        dataEnvio: json['data_envio'] as String?,
      );
}

class PublicUser {
  PublicUser({
    required this.id,
    required this.nome,
    required this.papel,
    this.imagemUrl,
    this.headline,
    this.bio,
    this.lidos = 0,
    this.seguidores = 0,
  });

  final int id;
  final String nome;
  final UserRole papel;
  final String? imagemUrl;
  final String? headline;
  final String? bio;
  final int lidos;
  final int seguidores;

  factory PublicUser.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    return PublicUser(
      id: json['id'] as int,
      nome: json['nome'] as String? ?? '',
      papel: UserRoleX.tryParse(json['papel'] as String?) ?? UserRole.leitor,
      imagemUrl: json['imagem_url'] as String?,
      headline: json['headline'] as String?,
      bio: json['bio'] as String?,
      lidos: stats['lidos'] as int? ?? 0,
      seguidores: stats['seguidores'] as int? ?? 0,
    );
  }
}
