class ReaderStatistics {
  ReaderStatistics({
    required this.year,
    required this.years,
    required this.week,
    required this.summary,
    required this.reactions,
    required this.months,
    required this.genres,
    required this.largestSmallest,
    required this.popularity,
    required this.editors,
    required this.authors,
    required this.topRead,
    required this.formats,
    required this.languages,
    required this.nationalities,
  });

  final int year;
  final List<int> years;
  final StatsWeek week;
  final StatsSummary summary;
  final StatsReactions reactions;
  final List<StatsCount> months;
  final List<StatsCount> genres;
  final StatsLargestSmallest largestSmallest;
  final StatsPopularity popularity;
  final List<StatsPersonOrPublisher> editors;
  final List<StatsPersonOrPublisher> authors;
  final List<StatsBook> topRead;
  final List<StatsCount> formats;
  final List<StatsCount> languages;
  final List<StatsCount> nationalities;

  factory ReaderStatistics.fromJson(Map<String, dynamic> json) {
    return ReaderStatistics(
      year: json['year'] as int? ?? DateTime.now().year,
      years: (json['years'] as List? ?? []).whereType<int>().toList(),
      week: StatsWeek.fromJson(json['week'] as Map<String, dynamic>? ?? {}),
      summary: StatsSummary.fromJson(json['summary'] as Map<String, dynamic>? ?? {}),
      reactions: StatsReactions.fromJson(json['reactions'] as Map<String, dynamic>? ?? {}),
      months: _list(json['months'], StatsCount.fromJson),
      genres: _list(json['genres'], StatsCount.fromJson),
      largestSmallest: StatsLargestSmallest.fromJson(json['largest_smallest'] as Map<String, dynamic>? ?? {}),
      popularity: StatsPopularity.fromJson(json['popularity'] as Map<String, dynamic>? ?? {}),
      editors: _list(json['editors'], StatsPersonOrPublisher.fromJson),
      authors: _list(json['authors'], StatsPersonOrPublisher.fromJson),
      topRead: _list(json['top_read'], StatsBook.fromJson),
      formats: _list(json['formats'], StatsCount.fromJson),
      languages: _list(json['languages'], StatsCount.fromJson),
      nationalities: _list(json['author_nationalities'], StatsCount.fromJson),
    );
  }
}

List<T> _list<T>(dynamic raw, T Function(Map<String, dynamic>) parser) {
  return (raw as List? ?? [])
      .whereType<Map<String, dynamic>>()
      .map(parser)
      .toList();
}

class StatsWeek {
  StatsWeek({required this.historyCount, required this.days});

  final int historyCount;
  final List<StatsWeekDay> days;

  factory StatsWeek.fromJson(Map<String, dynamic> json) => StatsWeek(
        historyCount: json['history_count'] as int? ?? 0,
        days: _list(json['days'], StatsWeekDay.fromJson),
      );
}

class StatsWeekDay {
  StatsWeekDay({required this.key, required this.active, required this.today});

  final String key;
  final bool active;
  final bool today;

  factory StatsWeekDay.fromJson(Map<String, dynamic> json) => StatsWeekDay(
        key: json['key'] as String? ?? '',
        active: json['active'] as bool? ?? false,
        today: json['today'] as bool? ?? false,
      );
}

class StatsSummary {
  StatsSummary({
    required this.readBooks,
    required this.pagesRead,
    required this.pagesPerDay,
    required this.ratingsCount,
    required this.reviewsCount,
    required this.consecutiveDays,
    required this.currentReadings,
    required this.unreadBooks,
    required this.remainingDays,
    required this.averageRating,
    required this.commentsReceived,
    required this.likesReceived,
  });

  final int readBooks;
  final int pagesRead;
  final double pagesPerDay;
  final int ratingsCount;
  final int reviewsCount;
  final int consecutiveDays;
  final int currentReadings;
  final int unreadBooks;
  final int remainingDays;
  final double averageRating;
  final int commentsReceived;
  final int likesReceived;

  factory StatsSummary.fromJson(Map<String, dynamic> json) => StatsSummary(
        readBooks: json['read_books'] as int? ?? 0,
        pagesRead: json['pages_read'] as int? ?? 0,
        pagesPerDay: (json['pages_per_day'] as num?)?.toDouble() ?? 0,
        ratingsCount: json['ratings_count'] as int? ?? 0,
        reviewsCount: json['reviews_count'] as int? ?? 0,
        consecutiveDays: json['consecutive_days'] as int? ?? 0,
        currentReadings: json['current_readings'] as int? ?? 0,
        unreadBooks: json['unread_books'] as int? ?? 0,
        remainingDays: json['remaining_days'] as int? ?? 0,
        averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
        commentsReceived: json['comments_received'] as int? ?? 0,
        likesReceived: json['likes_received'] as int? ?? 0,
      );
}

class StatsReactions {
  StatsReactions({this.top, required this.items});

  final StatsReaction? top;
  final List<StatsReaction> items;

  factory StatsReactions.fromJson(Map<String, dynamic> json) => StatsReactions(
        top: json['top'] is Map<String, dynamic> ? StatsReaction.fromJson(json['top'] as Map<String, dynamic>) : null,
        items: _list(json['items'], StatsReaction.fromJson),
      );
}

class StatsReaction {
  StatsReaction({
    required this.label,
    required this.emoji,
    required this.count,
    required this.percent,
  });

  final String label;
  final String emoji;
  final int count;
  final int percent;

  factory StatsReaction.fromJson(Map<String, dynamic> json) => StatsReaction(
        label: json['label'] as String? ?? '',
        emoji: json['emoji'] as String? ?? '',
        count: json['count'] as int? ?? 0,
        percent: json['percent'] as int? ?? 0,
      );
}

class StatsCount {
  StatsCount({
    required this.name,
    required this.count,
    this.icon,
    this.code,
  });

  final String name;
  final int count;
  final String? icon;
  final String? code;

  factory StatsCount.fromJson(Map<String, dynamic> json) => StatsCount(
        name: (json['name'] ?? json['month'] ?? '').toString(),
        count: json['count'] as int? ?? 0,
        icon: json['icon'] as String?,
        code: json['code'] as String?,
      );
}

class StatsBook {
  StatsBook({
    required this.id,
    required this.titulo,
    required this.autor,
    required this.paginas,
    this.genero,
    this.imagemUrl,
    this.readers = 0,
    this.position,
  });

  final int id;
  final String titulo;
  final String autor;
  final int paginas;
  final String? genero;
  final String? imagemUrl;
  final int readers;
  final int? position;

  factory StatsBook.fromJson(Map<String, dynamic> json) => StatsBook(
        id: json['id'] as int? ?? 0,
        titulo: json['titulo'] as String? ?? '',
        autor: json['autor'] as String? ?? '',
        paginas: json['pages'] as int? ?? json['paginas'] as int? ?? 0,
        genero: json['genero'] as String?,
        imagemUrl: json['imagem_url'] as String?,
        readers: json['readers'] as int? ?? 0,
        position: json['position'] as int?,
      );
}

class StatsLargestSmallest {
  StatsLargestSmallest({this.largest, this.smallest});

  final StatsBook? largest;
  final StatsBook? smallest;

  factory StatsLargestSmallest.fromJson(Map<String, dynamic> json) => StatsLargestSmallest(
        largest: json['largest'] is Map<String, dynamic> ? StatsBook.fromJson(json['largest'] as Map<String, dynamic>) : null,
        smallest: json['smallest'] is Map<String, dynamic> ? StatsBook.fromJson(json['smallest'] as Map<String, dynamic>) : null,
      );
}

class StatsPopularity {
  StatsPopularity({this.most, this.least});

  final StatsBook? most;
  final StatsBook? least;

  factory StatsPopularity.fromJson(Map<String, dynamic> json) => StatsPopularity(
        most: json['most'] is Map<String, dynamic> ? StatsBook.fromJson(json['most'] as Map<String, dynamic>) : null,
        least: json['least'] is Map<String, dynamic> ? StatsBook.fromJson(json['least'] as Map<String, dynamic>) : null,
      );
}

class StatsPersonOrPublisher {
  StatsPersonOrPublisher({
    required this.name,
    required this.count,
    this.imageUrl,
  });

  final String name;
  final int count;
  final String? imageUrl;

  factory StatsPersonOrPublisher.fromJson(Map<String, dynamic> json) => StatsPersonOrPublisher(
        name: json['name'] as String? ?? '',
        count: json['count'] as int? ?? 0,
        imageUrl: json['image_url'] as String?,
      );
}
