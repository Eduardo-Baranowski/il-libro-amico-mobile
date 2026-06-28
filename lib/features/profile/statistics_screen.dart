import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bibliotheca.dart';
import '../../core/widgets/book_cover.dart';
import '../../data/reader_repository.dart';

final _statisticsProvider = FutureProvider.autoDispose.family<ReaderStatistics, int?>((ref, year) {
  return ref.watch(readerRepositoryProvider).statistics(year: year);
});

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  int? _selectedYear;

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(_statisticsProvider(_selectedYear));

    return Scaffold(
      appBar: const BibDetailAppBar(title: 'Estatísticas'),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (err, stack) {
          final message = err is ApiException ? err.message : 'Erro ao carregar estatísticas.';
          return _ErrorState(
            message: message,
            onRetry: () => ref.invalidate(_statisticsProvider(_selectedYear)),
          );
        },
        data: (stats) {
          _selectedYear ??= stats.year;
          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () async => ref.refresh(_statisticsProvider(_selectedYear).future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(AppTheme.marginMobile, 8, AppTheme.marginMobile, 28),
              children: [
                _YearSelector(
                  years: stats.years.isEmpty ? [stats.year] : stats.years,
                  selectedYear: _selectedYear ?? stats.year,
                  onSelected: (year) => setState(() => _selectedYear = year),
                ),
                const SizedBox(height: 18),
                _WeekCard(stats: stats),
                const SizedBox(height: 14),
                _TopMetrics(stats: stats),
                const SizedBox(height: 14),
                _ReactionCard(stats.reactions.items),
                const SizedBox(height: 14),
                _MonthChart(stats.months),
                const SizedBox(height: 14),
                _GenreChart(stats.genres),
                const SizedBox(height: 14),
                _SmallMetricGrid(stats: stats),
                const SizedBox(height: 14),
                _LargestSmallestCard(stats.largestSmallest),
                const SizedBox(height: 14),
                _SocialMetricGrid(stats: stats),
                const SizedBox(height: 14),
                _PopularityCard(stats.popularity),
                const SizedBox(height: 14),
                _PeopleCard(title: 'Editoras mais lidas', items: stats.editors, icon: Icons.business_rounded),
                const SizedBox(height: 14),
                _PeopleCard(title: 'Autores mais lidos', items: stats.authors, icon: Icons.person_rounded),
                const SizedBox(height: 14),
                _TopReadCard(stats.topRead),
                const SizedBox(height: 14),
                _FormatsCard(stats.formats),
                const SizedBox(height: 14),
                _LanguagesCard(stats.languages),
                const SizedBox(height: 14),
                _PeopleCard(
                  title: 'Nacionalidade dos autores lidos',
                  items: stats.nationalities
                      .map((n) => StatsPersonOrPublisher(name: n.name, count: n.count, imageUrl: null))
                      .toList(),
                  icon: Icons.public_rounded,
                ),
                const SizedBox(height: 18),
                Text(
                  'A estatística é baseada apenas nos livros lidos.',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _YearSelector extends StatelessWidget {
  const _YearSelector({
    required this.years,
    required this.selectedYear,
    required this.onSelected,
  });

  final List<int> years;
  final int selectedYear;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: years.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final year = years[index];
          final selected = year == selectedYear;
          return ChoiceChip(
            label: SizedBox(
              width: 82,
              child: Text('$year', textAlign: TextAlign.center),
            ),
            selected: selected,
            onSelected: (_) => onSelected(year),
            showCheckmark: false,
            selectedColor: AppTheme.primary,
            backgroundColor: AppTheme.surfaceContainer,
            labelStyle: AppTheme.labelSans.copyWith(
              color: selected ? Colors.white : AppTheme.onSurface,
              fontSize: 16,
            ),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          );
        },
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.stats});

  final ReaderStatistics stats;

  @override
  Widget build(BuildContext context) {
    const labels = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
    return _StatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Como está a semana', style: AppTheme.labelSans.copyWith(fontSize: 17)),
                    Text(
                      'Vezes que você fez um histórico de leitura',
                      style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Icon(Icons.local_fire_department_rounded, color: AppTheme.primaryContainer, size: 30),
              const SizedBox(width: 4),
              Text('${stats.week.historyCount}', style: AppTheme.titleSerif.copyWith(color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < stats.week.days.length; i++)
                _WeekDayDot(day: stats.week.days[i], label: labels[i]),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekDayDot extends StatelessWidget {
  const _WeekDayDot({required this.day, required this.label});

  final StatsWeekDay day;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = day.active ? AppTheme.primarySoft : AppTheme.surfaceWhite;
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: day.today ? AppTheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Icon(
            Icons.menu_book_rounded,
            color: day.active ? AppTheme.primary : AppTheme.outlineVariant,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: AppTheme.labelSans.copyWith(color: day.today ? AppTheme.primary : AppTheme.onSurface)),
      ],
    );
  }
}

class _TopMetrics extends StatelessWidget {
  const _TopMetrics({required this.stats});

  final ReaderStatistics stats;

  @override
  Widget build(BuildContext context) {
    return _TwoColumn(
      children: [
        _MetricCard(
          title: 'Maior reação',
          value: stats.reactions.top?.emoji ?? '-',
          unit: stats.reactions.top?.label ?? '',
          footer: 'Usado ${stats.reactions.top?.count ?? 0} vezes',
        ),
        _MetricCard(
          title: 'Páginas do ano',
          value: '${stats.summary.pagesRead}',
          unit: 'páginas',
          footer: '${_decimal(stats.summary.pagesPerDay)} páginas dia',
        ),
        _ProgressMetricCard(
          title: 'Avaliações',
          primary: stats.summary.ratingsCount,
          secondary: stats.summary.readBooks,
          primaryLabel: 'Avaliações feitas',
          secondaryLabel: 'Livros lidos',
        ),
        _ProgressMetricCard(
          title: 'Resenhas',
          primary: stats.summary.reviewsCount,
          secondary: stats.summary.readBooks,
          primaryLabel: 'Resenhas feitas',
          secondaryLabel: 'Livros lidos',
        ),
      ],
    );
  }
}

class _SmallMetricGrid extends StatelessWidget {
  const _SmallMetricGrid({required this.stats});

  final ReaderStatistics stats;

  @override
  Widget build(BuildContext context) {
    return _TwoColumn(
      children: [
        _MetricCard(
          title: 'Dias seguidos',
          value: '${stats.summary.consecutiveDays}',
          unit: 'dias lendo',
          footer: '${stats.summary.currentReadings} leitura atual',
        ),
        _MetricCard(
          title: 'Ritmo de leitura',
          value: _decimal(stats.summary.pagesPerDay),
          unit: 'páginas por dia',
          footer: '${stats.summary.pagesRead} lidos na meta',
        ),
        _MetricCard(
          title: 'Tempo total restante',
          value: '${stats.summary.remainingDays}',
          unit: 'dias',
          footer: '${stats.summary.unreadBooks} livros não lidos',
        ),
        _MetricCard(
          title: 'Média de avaliação',
          value: '★ ${_decimal(stats.summary.averageRating)}',
          unit: '',
          footer: '${stats.summary.ratingsCount} leituras avaliadas',
          valueColor: AppTheme.primaryContainer,
        ),
      ],
    );
  }
}

class _SocialMetricGrid extends StatelessWidget {
  const _SocialMetricGrid({required this.stats});

  final ReaderStatistics stats;

  @override
  Widget build(BuildContext context) {
    return _TwoColumn(
      children: [
        _MetricCard(
          title: 'Comentários em resenhas',
          value: '${stats.summary.commentsReceived}',
          unit: 'comentários',
          footer: 'Em ${stats.summary.reviewsCount} resenhas',
        ),
        _MetricCard(
          title: 'Curtidas recebidas',
          value: '${stats.summary.likesReceived}',
          unit: 'curtidas',
          footer: 'Em resenhas',
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.footer,
    this.valueColor,
  });

  final String title;
  final String value;
  final String unit;
  final String footer;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return _StatCard(
      minHeight: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTheme.labelSans.copyWith(fontSize: 17)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.displaySerif.copyWith(
                    fontSize: value.length > 5 ? 28 : 36,
                    color: valueColor ?? AppTheme.onSurface,
                  ),
                ),
                if (unit.isNotEmpty)
                  Text(unit, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.bodySans.copyWith(fontSize: 16)),
              ],
            ),
          ),
          Text(footer, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant, fontSize: 14)),
        ],
      ),
    );
  }
}

class _ProgressMetricCard extends StatelessWidget {
  const _ProgressMetricCard({
    required this.title,
    required this.primary,
    required this.secondary,
    required this.primaryLabel,
    required this.secondaryLabel,
  });

  final String title;
  final int primary;
  final int secondary;
  final String primaryLabel;
  final String secondaryLabel;

  @override
  Widget build(BuildContext context) {
    final maxValue = [primary, secondary, 1].reduce((a, b) => a > b ? a : b);
    return _StatCard(
      minHeight: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTheme.labelSans.copyWith(fontSize: 17)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bar(value: primary / maxValue, label: '$primary', color: AppTheme.primary),
                const SizedBox(height: 10),
                _Bar(value: secondary / maxValue, label: '$secondary', color: AppTheme.secondaryContainer),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Legend(color: AppTheme.primary, label: primaryLabel),
              const SizedBox(height: 4),
              _Legend(color: AppTheme.secondaryContainer, label: secondaryLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReactionCard extends StatelessWidget {
  const _ReactionCard(this.items);

  final List<StatsReaction> items;

  @override
  Widget build(BuildContext context) {
    return _StatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Minhas reações', style: AppTheme.labelSans.copyWith(fontSize: 17)),
              Icon(Icons.info_outline_rounded, size: 20, color: AppTheme.outlineVariant),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Baseadas nas suas avaliações de estrelas',
            style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: Column(
                    children: [
                      Text(items[i].emoji, style: const TextStyle(fontSize: 34)),
                      const SizedBox(height: 4),
                      Text(
                        items[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.captionSans.copyWith(fontSize: 12, color: AppTheme.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${5 - i}', style: AppTheme.captionSans.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                          Icon(Icons.star_rounded, size: 10, color: AppTheme.primary),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('${items[i].percent}%', style: AppTheme.captionSans),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthChart extends StatelessWidget {
  const _MonthChart(this.months);

  final List<StatsCount> months;

  @override
  Widget build(BuildContext context) {
    const labels = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    final maxValue = months.fold<int>(1, (max, item) => item.count > max ? item.count : max);
    return _StatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lidos por mês', style: AppTheme.labelSans.copyWith(fontSize: 17)),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < labels.length; i++)
                  Expanded(
                    child: _VerticalBar(
                      label: labels[i],
                      value: i < months.length ? months[i].count : 0,
                      maxValue: maxValue,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreChart extends StatelessWidget {
  const _GenreChart(this.items);

  final List<StatsCount> items;

  @override
  Widget build(BuildContext context) {
    final visible = items.take(5).toList();
    final maxValue = visible.fold<int>(1, (max, item) => item.count > max ? item.count : max);
    return _StatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gêneros mais lidos', style: AppTheme.labelSans.copyWith(fontSize: 17)),
          const SizedBox(height: 18),
          SizedBox(
            height: 190,
            child: visible.isEmpty
                ? const _EmptyInline(label: 'Nenhum gênero lido neste ano.')
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final item in visible)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: 112 * (item.count / maxValue).clamp(0.18, 1).toDouble(),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    borderRadius: AppTheme.radiusLg,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.name,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.captionSans.copyWith(color: AppTheme.onSurface, fontSize: 11),
                                ),
                                Text('${item.count}', style: AppTheme.captionSans),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _LargestSmallestCard extends StatelessWidget {
  const _LargestSmallestCard(this.data);

  final StatsLargestSmallest data;

  @override
  Widget build(BuildContext context) {
    return _BookPairCard(
      title: 'Maior e menor lido',
      first: data.largest,
      firstLabel: 'Maior',
      firstIcon: Icons.arrow_circle_up_rounded,
      firstColor: AppTheme.secondary,
      second: data.smallest,
      secondLabel: 'Menor',
      secondIcon: Icons.arrow_circle_down_rounded,
      secondColor: AppTheme.error,
      metricBuilder: (book) => '${book.paginas} páginas',
    );
  }
}

class _PopularityCard extends StatelessWidget {
  const _PopularityCard(this.data);

  final StatsPopularity data;

  @override
  Widget build(BuildContext context) {
    return _BookPairCard(
      title: 'Mais e menos popular',
      first: data.most,
      firstLabel: 'Mais popular',
      firstIcon: Icons.local_fire_department_rounded,
      firstColor: AppTheme.primaryContainer,
      second: data.least,
      secondLabel: 'Menos popular',
      secondIcon: Icons.ac_unit_rounded,
      secondColor: AppTheme.secondary,
      metricBuilder: (book) => '${book.readers} leitores',
    );
  }
}

class _BookPairCard extends StatelessWidget {
  const _BookPairCard({
    required this.title,
    required this.first,
    required this.firstLabel,
    required this.firstIcon,
    required this.firstColor,
    required this.second,
    required this.secondLabel,
    required this.secondIcon,
    required this.secondColor,
    required this.metricBuilder,
  });

  final String title;
  final StatsBook? first;
  final String firstLabel;
  final IconData firstIcon;
  final Color firstColor;
  final StatsBook? second;
  final String secondLabel;
  final IconData secondIcon;
  final Color secondColor;
  final String Function(StatsBook book) metricBuilder;

  @override
  Widget build(BuildContext context) {
    return _StatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.labelSans.copyWith(fontSize: 17)),
          const SizedBox(height: 16),
          if (first == null && second == null)
            const _EmptyInline(label: 'Ainda não há livros suficientes.')
          else ...[
            if (first != null)
              _BookStatRow(
                book: first!,
                label: firstLabel,
                icon: firstIcon,
                color: firstColor,
                metric: metricBuilder(first!),
              ),
            if (first != null && second != null) const SizedBox(height: 16),
            if (second != null)
              _BookStatRow(
                book: second!,
                label: secondLabel,
                icon: secondIcon,
                color: secondColor,
                metric: metricBuilder(second!),
              ),
          ],
        ],
      ),
    );
  }
}

class _BookStatRow extends StatelessWidget {
  const _BookStatRow({
    required this.book,
    required this.label,
    required this.icon,
    required this.color,
    required this.metric,
  });

  final StatsBook book;
  final String label;
  final IconData icon;
  final Color color;
  final String metric;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BookCover(url: book.imagemUrl, width: 74, height: 104, borderRadius: 8),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(book.titulo, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTheme.labelSans.copyWith(fontSize: 16)),
              Text('Por: ${book.autor}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.bodySans.copyWith(fontSize: 14)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$label\n$metric',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant, height: 1.2),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PeopleCard extends StatelessWidget {
  const _PeopleCard({required this.title, required this.items, required this.icon});

  final String title;
  final List<StatsPersonOrPublisher> items;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final visible = items.take(4).toList();
    return _StatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.labelSans.copyWith(fontSize: 17)),
          const SizedBox(height: 16),
          if (visible.isEmpty)
            const _EmptyInline(label: 'Nada por aqui neste ano.')
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in visible)
                  Expanded(
                    child: Column(
                      children: [
                        // Mostrar bandeira/ícone específico para nacionalidades comuns
                        Builder(builder: (context) {
                          final name = item.name.toLowerCase();
                          if (name.contains('brasil') || name.contains('brasileir')) {
                            return CircleAvatar(
                              radius: 32,
                              backgroundColor: AppTheme.secondaryContainer,
                              child: const Text('🇧🇷', style: TextStyle(fontSize: 28)),
                            );
                          }

                          if (name.contains('estrange')) {
                            return CircleAvatar(
                              radius: 32,
                              backgroundColor: AppTheme.surfaceWhite,
                              child: Icon(Icons.public_rounded, color: AppTheme.primary, size: 26),
                            );
                          }

                          return UserAvatar(url: item.imageUrl, name: item.name, radius: 32);
                        }),
                        const SizedBox(height: 10),
                        Text(
                          item.name,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.labelSans.copyWith(fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text('${item.count}', style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant, fontSize: 14)),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TopReadCard extends StatelessWidget {
  const _TopReadCard(this.books);

  final List<StatsBook> books;

  @override
  Widget build(BuildContext context) {
    final visible = books.take(10).toList();
    return _StatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top 10 lidos', style: AppTheme.labelSans.copyWith(fontSize: 17)),
          const SizedBox(height: 16),
          if (visible.isEmpty)
            const _EmptyInline(label: 'Leia livros para montar seu top 10.')
          else
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final book = visible[index];
                  return SizedBox(
                    width: 92,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Positioned.fill(
                          bottom: 18,
                          child: BookCover(url: book.imagemUrl, width: 92, height: 136, borderRadius: 8),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.onSurfaceVariant,
                            borderRadius: AppTheme.radiusSm,
                          ),
                          child: Text('${book.position ?? index + 1}º', style: AppTheme.labelSans.copyWith(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemCount: visible.length,
              ),
            ),
        ],
      ),
    );
  }
}

class _FormatsCard extends StatelessWidget {
  const _FormatsCard(this.items);

  final List<StatsCount> items;

  @override
  Widget build(BuildContext context) {
    return _StatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Formatos mais lidos', style: AppTheme.labelSans.copyWith(fontSize: 17)),
          const SizedBox(height: 20),
          Row(
            children: [
              for (final item in items)
                Expanded(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppTheme.surfaceWhite,
                        child: Icon(_formatIcon(item.icon), color: AppTheme.primary, size: 30),
                      ),
                      const SizedBox(height: 10),
                      Text(item.name, textAlign: TextAlign.center, style: AppTheme.labelSans),
                      const SizedBox(height: 18),
                      Text('${item.count}', style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguagesCard extends StatelessWidget {
  const _LanguagesCard(this.items);

  final List<StatsCount> items;

  @override
  Widget build(BuildContext context) {
    final visible = items.take(3).toList();
    return _StatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Idiomas lidos', style: AppTheme.labelSans.copyWith(fontSize: 17)),
          const SizedBox(height: 18),
          if (visible.isEmpty)
            const _EmptyInline(label: 'Nenhum idioma identificado.')
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final item in visible)
                  Expanded(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppTheme.secondaryContainer,
                          child: Text(_languageMark(item.code), style: AppTheme.labelSans.copyWith(color: AppTheme.onSecondaryContainer)),
                        ),
                        const SizedBox(height: 10),
                        Text(item.name, textAlign: TextAlign.center, style: AppTheme.labelSans),
                        const SizedBox(height: 18),
                        Text('${item.count}', style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TwoColumn extends StatelessWidget {
  const _TwoColumn({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      final left = children[i];
      final right = i + 1 < children.length ? children[i + 1] : null;

      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: left),
              const SizedBox(width: 12),
              Expanded(child: right ?? const SizedBox()),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          rows[i],
          if (i < rows.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.child, this.minHeight});

  final Widget child;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight ?? 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: AppTheme.radiusXl,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.label, required this.color});

  final double value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: value.clamp(0, 1).toDouble(),
              color: color,
              backgroundColor: AppTheme.surfaceWhite,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(width: 28, child: Text(label, textAlign: TextAlign.right, style: AppTheme.labelSans)),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppTheme.captionSans.copyWith(color: AppTheme.onSurface))),
      ],
    );
  }
}

class _VerticalBar extends StatelessWidget {
  const _VerticalBar({required this.label, required this.value, required this.maxValue});

  final String label;
  final int value;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    final height = value == 0 ? 8.0 : 104 * (value / maxValue).clamp(0.12, 1).toDouble();
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('$value', style: AppTheme.captionSans.copyWith(color: AppTheme.onSurface)),
        const SizedBox(height: 6),
        Container(
          width: 8,
          height: height,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: AppTheme.captionSans),
      ],
    );
  }
}

class _EmptyInline extends StatelessWidget {
  const _EmptyInline({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTheme.bodySans.copyWith(color: AppTheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.marginMobile),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.query_stats_rounded, size: 44, color: AppTheme.primary.withValues(alpha: 0.7)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: AppTheme.bodySans),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Tentar novamente')),
          ],
        ),
      ),
    );
  }
}

IconData _formatIcon(String? icon) {
  return switch (icon) {
    'phone' => Icons.smartphone_rounded,
    'headphones' => Icons.headphones_rounded,
    _ => Icons.menu_book_rounded,
  };
}

String _languageMark(String? code) {
  return switch (code) {
    'pt-BR' => 'BR',
    'pt-PT' => 'PT',
    'en' => 'EN',
    'es' => 'ES',
    _ => (code ?? '--').toUpperCase().substring(0, (code ?? '--').length.clamp(0, 2)),
  };
}

String _decimal(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1);
}
