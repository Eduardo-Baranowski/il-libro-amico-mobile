class BookClub {
  BookClub({
    required this.id,
    required this.nome,
    this.descricao,
    this.imagem,
    required this.privado,
    this.conviteCodigo,
    this.criadoEm,
    required this.isMember,
    this.membershipStatus,
    this.papel,
    this.userRole,
  });

  final int id;
  final String nome;
  final String? descricao;
  final String? imagem;
  final bool privado;
  final String? conviteCodigo;
  final String? criadoEm;
  final bool isMember;
  final String? membershipStatus;
  final String? papel;
  final String? userRole;

  factory BookClub.fromJson(Map<String, dynamic> json) => BookClub(
        id: json['id'] as int? ?? 0,
        nome: json['nome'] as String? ?? '',
        descricao: json['descricao'] as String?,
        imagem: json['imagem'] as String?,
        privado: json['privado'] as bool? ?? false,
        conviteCodigo: json['convite_codigo'] as String?,
        criadoEm: json['criado_em'] as String?,
        isMember: json['is_member'] as bool? ?? false,
        membershipStatus: json['membership_status'] as String?,
        papel: json['papel'] as String?,
        userRole: json['user_role'] as String?,
      );

  bool get isOwner => papel == 'dono' || userRole == 'dono';
  bool get isPending => membershipStatus == 'pending_approval';
  bool get isActiveMember =>
      membershipStatus == 'active' || (isMember && membershipStatus == null);
}

class BookClubListResponse {
  BookClubListResponse({required this.myClubs, required this.exploreClubs});

  final List<BookClub> myClubs;
  final List<BookClub> exploreClubs;

  factory BookClubListResponse.fromJson(Map<String, dynamic> json) {
    List<BookClub> parseList(dynamic raw) {
      if (raw is! List) return [];
      return raw.whereType<Map<String, dynamic>>().map(BookClub.fromJson).toList();
    }

    return BookClubListResponse(
      myClubs: parseList(json['my_clubs']),
      exploreClubs: parseList(json['explore_clubs']),
    );
  }
}

class BookClubMemberRequest {
  BookClubMemberRequest({
    required this.id,
    required this.userId,
    required this.userNome,
    this.userEmail,
    this.imagemUrl,
    required this.criadoEm,
  });

  final int id;
  final int userId;
  final String userNome;
  final String? userEmail;
  final String? imagemUrl;
  final String criadoEm;

  factory BookClubMemberRequest.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return BookClubMemberRequest(
      id: json['id'] as int? ?? 0,
      userId: user?['id'] as int? ?? 0,
      userNome: user?['nome'] as String? ?? '',
      userEmail: user?['email'] as String?,
      imagemUrl: user?['imagem_url'] as String?,
      criadoEm: json['criado_em'] as String? ?? '',
    );
  }
}

class BookClubMember {
  BookClubMember({
    required this.id,
    required this.userId,
    required this.userNome,
    this.imagemUrl,
    required this.papel,
    required this.criadoEm,
  });

  final int id;
  final int userId;
  final String userNome;
  final String? imagemUrl;
  final String papel;
  final String criadoEm;

  bool get isOwner => papel == 'dono';

  factory BookClubMember.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return BookClubMember(
      id: json['id'] as int? ?? 0,
      userId: user?['id'] as int? ?? json['user_id'] as int? ?? 0,
      userNome: user?['nome'] as String? ?? '',
      imagemUrl: user?['imagem_url'] as String?,
      papel: json['papel'] as String? ?? 'membro',
      criadoEm: json['criado_em'] as String? ?? '',
    );
  }
}

class BookClubCycleInfo {
  BookClubCycleInfo({
    required this.id,
    required this.titulo,
    required this.status,
    this.dataInicio,
    this.dataFimVotacao,
    this.dataSorteio,
    this.diasAteSorteio = 0,
  });

  final int id;
  final String titulo;
  final String status;
  final String? dataInicio;
  final String? dataFimVotacao;
  final String? dataSorteio;
  final int diasAteSorteio;

  factory BookClubCycleInfo.fromJson(Map<String, dynamic> json) => BookClubCycleInfo(
        id: json['id'] as int? ?? 0,
        titulo: json['titulo'] as String? ?? '',
        status: json['status'] as String? ?? 'votacao',
        dataInicio: json['data_inicio'] as String?,
        dataFimVotacao: json['data_fim_votacao'] as String?,
        dataSorteio: json['data_sorteio'] as String?,
        diasAteSorteio: json['dias_ate_sorteio'] as int? ?? 0,
      );

  bool get isOpen => status == 'nominacao' || status == 'votacao';
}

class BookClubNominator {
  BookClubNominator({required this.id, required this.nome, this.imagemUrl});

  final int id;
  final String nome;
  final String? imagemUrl;

  factory BookClubNominator.fromJson(Map<String, dynamic>? json) => BookClubNominator(
        id: json?['id'] as int? ?? 0,
        nome: json?['nome'] as String? ?? '',
        imagemUrl: json?['imagem_url'] as String?,
      );
}

class BookClubNomination {
  BookClubNomination({
    required this.id,
    required this.cycleId,
    required this.titulo,
    required this.autor,
    this.genero,
    this.imagemUrl,
    this.livroId,
    this.motivo,
    required this.votesCount,
    required this.votedByMe,
    this.indicadoPor,
    this.cycleTitulo,
    this.criadoEm,
  });

  final int id;
  final int cycleId;
  final String titulo;
  final String autor;
  final String? genero;
  final String? imagemUrl;
  final int? livroId;
  final String? motivo;
  final int votesCount;
  final bool votedByMe;
  final BookClubNominator? indicadoPor;
  final String? cycleTitulo;
  final String? criadoEm;

  factory BookClubNomination.fromJson(Map<String, dynamic> json) => BookClubNomination(
        id: json['id'] as int? ?? 0,
        cycleId: json['cycle_id'] as int? ?? 0,
        titulo: json['titulo'] as String? ?? '',
        autor: json['autor'] as String? ?? '',
        genero: json['genero'] as String?,
        imagemUrl: json['imagem_url'] as String?,
        livroId: json['livro_id'] as int?,
        motivo: json['motivo'] as String?,
        votesCount: json['votes_count'] as int? ?? 0,
        votedByMe: json['voted_by_me'] as bool? ?? false,
        indicadoPor: json['indicado_por'] != null
            ? BookClubNominator.fromJson(json['indicado_por'] as Map<String, dynamic>)
            : null,
        cycleTitulo: json['cycle_titulo'] as String?,
        criadoEm: json['criado_em'] as String?,
      );

  BookClubNomination copyWith({int? votesCount, bool? votedByMe}) => BookClubNomination(
        id: id,
        cycleId: cycleId,
        titulo: titulo,
        autor: autor,
        genero: genero,
        imagemUrl: imagemUrl,
        livroId: livroId,
        motivo: motivo,
        votesCount: votesCount ?? this.votesCount,
        votedByMe: votedByMe ?? this.votedByMe,
        indicadoPor: indicadoPor,
        cycleTitulo: cycleTitulo,
        criadoEm: criadoEm,
      );
}

class BookClubUserStats {
  BookClubUserStats({
    required this.votesUsed,
    required this.votesRemaining,
    required this.hasNominated,
    this.myNominationId,
  });

  final int votesUsed;
  final int votesRemaining;
  final bool hasNominated;
  final int? myNominationId;

  factory BookClubUserStats.fromJson(Map<String, dynamic> json) => BookClubUserStats(
        votesUsed: json['votes_used'] as int? ?? 0,
        votesRemaining: json['votes_remaining'] as int? ?? 3,
        hasNominated: json['has_nominated'] as bool? ?? false,
        myNominationId: json['my_nomination_id'] as int?,
      );
}

class BookClubHub {
  BookClubHub({
    this.club,
    required this.cycle,
    this.featuredBook,
    required this.nominationsPreview,
    required this.totalNominations,
    required this.maxVotesPerUser,
    this.userStats,
  });

  final BookClub? club;
  final BookClubCycleInfo cycle;
  final BookClubNomination? featuredBook;
  final List<BookClubNomination> nominationsPreview;
  final int totalNominations;
  final int maxVotesPerUser;
  final BookClubUserStats? userStats;

  factory BookClubHub.fromJson(Map<String, dynamic> json) {
    final previewRaw = json['nominations_preview'];
    return BookClubHub(
      club: json['club'] != null
          ? BookClub.fromJson(json['club'] as Map<String, dynamic>)
          : null,
      cycle: BookClubCycleInfo.fromJson(json['cycle'] as Map<String, dynamic>? ?? {}),
      featuredBook: json['featured_book'] != null
          ? BookClubNomination.fromJson(json['featured_book'] as Map<String, dynamic>)
          : null,
      nominationsPreview: previewRaw is List
          ? previewRaw
              .whereType<Map<String, dynamic>>()
              .map(BookClubNomination.fromJson)
              .toList()
          : [],
      totalNominations: json['total_nominations'] as int? ?? 0,
      maxVotesPerUser: json['max_votes_per_user'] as int? ?? 3,
      userStats: json['user_stats'] != null
          ? BookClubUserStats.fromJson(json['user_stats'] as Map<String, dynamic>)
          : null,
    );
  }

  BookClubHub copyWith({
    BookClub? club,
    BookClubCycleInfo? cycle,
    BookClubNomination? featuredBook,
    List<BookClubNomination>? nominationsPreview,
    int? totalNominations,
    int? maxVotesPerUser,
    BookClubUserStats? userStats,
  }) =>
      BookClubHub(
        club: club ?? this.club,
        cycle: cycle ?? this.cycle,
        featuredBook: featuredBook ?? this.featuredBook,
        nominationsPreview: nominationsPreview ?? this.nominationsPreview,
        totalNominations: totalNominations ?? this.totalNominations,
        maxVotesPerUser: maxVotesPerUser ?? this.maxVotesPerUser,
        userStats: userStats ?? this.userStats,
      );
}

class BookClubActivity {
  BookClubActivity({
    required this.tipo,
    required this.userNome,
    required this.livroTitulo,
    required this.criadoEm,
  });

  final String tipo;
  final String userNome;
  final String livroTitulo;
  final String criadoEm;

  factory BookClubActivity.fromJson(Map<String, dynamic> json) => BookClubActivity(
        tipo: json['tipo'] as String? ?? '',
        userNome: json['user_nome'] as String? ?? '',
        livroTitulo: json['livro_titulo'] as String? ?? '',
        criadoEm: json['criado_em'] as String? ?? '',
      );

  String get description {
    if (tipo == 'voto') {
      return '$userNome votou em "$livroTitulo"';
    }
    return '$userNome indicou "$livroTitulo"';
  }
}

class BookClubNominationsPage {
  BookClubNominationsPage({
    required this.cycle,
    required this.items,
    required this.total,
    required this.page,
    required this.pages,
    required this.maxVotesPerUser,
  });

  final BookClubCycleInfo cycle;
  final List<BookClubNomination> items;
  final int total;
  final int page;
  final int pages;
  final int maxVotesPerUser;

  factory BookClubNominationsPage.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return BookClubNominationsPage(
      cycle: BookClubCycleInfo.fromJson(json['cycle'] as Map<String, dynamic>? ?? {}),
      items: raw is List
          ? raw.whereType<Map<String, dynamic>>().map(BookClubNomination.fromJson).toList()
          : [],
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pages: json['pages'] as int? ?? 1,
      maxVotesPerUser: json['max_votes_per_user'] as int? ?? 3,
    );
  }
}

class BookClubVoteResult {
  BookClubVoteResult({
    required this.voted,
    required this.votesCount,
    required this.votesRemaining,
  });

  final bool voted;
  final int votesCount;
  final int votesRemaining;

  factory BookClubVoteResult.fromJson(Map<String, dynamic> json) => BookClubVoteResult(
        voted: json['voted'] as bool? ?? false,
        votesCount: json['votes_count'] as int? ?? 0,
        votesRemaining: json['votes_remaining'] as int? ?? 0,
      );
}
