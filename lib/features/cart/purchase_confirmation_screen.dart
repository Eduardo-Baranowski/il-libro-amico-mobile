import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bibliotheca.dart';

class PurchaseConfirmationScreen extends StatelessWidget {
  const PurchaseConfirmationScreen({super.key, required this.confirmation});

  final PurchaseConfirmation confirmation;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: BibDetailAppBar(
        title: 'Bibliotheca',
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: AppTheme.primary),
            onPressed: () => context.go('/livros'),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            AppTheme.marginMobile, 0, AppTheme.marginMobile, 24 + bottomPad),
        children: [
          const SizedBox(height: 32),

          // ── Ícone de sucesso ──────────────────────────────────────────────
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryContainer.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    size: 44,
                    color: AppTheme.secondary,
                  ),
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Título ────────────────────────────────────────────────────────
          Text(
            'Sua jornada\ncomeça em breve!',
            textAlign: TextAlign.center,
            style: AppTheme.displaySerif.copyWith(fontSize: 26),
          ),
          const SizedBox(height: 10),
          Text(
            'Seu pedido foi confirmado. Uma curadoria de histórias\nestá sendo preparada para a sua estante.',
            textAlign: TextAlign.center,
            style: AppTheme.bodySans.copyWith(
                color: AppTheme.onSurfaceVariant, fontSize: 14),
          ),

          const SizedBox(height: 28),

          // ── Card do pedido ────────────────────────────────────────────────
          BibCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Número do pedido
                Text('NÚMERO DO PEDIDO',
                    style: AppTheme.captionSans.copyWith(
                        fontSize: 10,
                        letterSpacing: 0.1,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  confirmation.orderNumber,
                  style: AppTheme.titleSerif.copyWith(
                      color: AppTheme.primary, fontSize: 18),
                ),
                const SizedBox(height: 16),

                // Previsão de chegada
                Text('PREVISÃO DE ENTREGA',
                    style: AppTheme.captionSans.copyWith(
                        fontSize: 10,
                        letterSpacing: 0.1,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  confirmation.estimatedArrival,
                  style:
                      AppTheme.headlineSerif.copyWith(fontSize: 20),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(),
                ),

                // Itens do pedido
                Text('Resumo do Pedido',
                    style: AppTheme.titleSerif.copyWith(fontSize: 16)),
                const SizedBox(height: 12),
                ...confirmation.items.map((item) => _ConfirmationItem(item: item)),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),

                // Totais
                _TotalRow(
                    label: 'Subtotal',
                    value: 'R\$ ${confirmation.subtotal.toStringAsFixed(2)}'),
                const SizedBox(height: 6),
                _TotalRow(
                    label: 'Frete',
                    value: confirmation.shipping == 0
                        ? 'Grátis'
                        : 'R\$ ${confirmation.shipping.toStringAsFixed(2)}'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Total',
                        style: AppTheme.titleSerif
                            .copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text(
                      'R\$ ${confirmation.total.toStringAsFixed(2)}',
                      style: AppTheme.headlineSerif.copyWith(
                          color: AppTheme.primary, fontSize: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── CTAs ──────────────────────────────────────────────────────────
          FilledButton(
            onPressed: () => context.go('/'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.radiusLg),
            ),
            child: Text(
              'Continuar Explorando',
              style:
                  AppTheme.labelSans.copyWith(color: Colors.white, fontSize: 15),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Acompanhamento de pedido estará disponível em breve!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              foregroundColor: AppTheme.onSurface,
              side: BorderSide(
                  color: AppTheme.outlineVariant.withValues(alpha: 0.6)),
              shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.radiusLg),
            ),
            child: Text(
              'Acompanhar Pedido',
              style: AppTheme.labelSans.copyWith(fontSize: 15),
            ),
          ),

          // ── Journey Milestones ────────────────────────────────────────────
          const SizedBox(height: 28),
          BibCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Milestones da Jornada',
                    style: AppTheme.titleSerif.copyWith(fontSize: 16)),
                const SizedBox(height: 20),
                _JourneyMilestones(),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Widgets internos ─────────────────────────────────────────────────────────

class _ConfirmationItem extends StatelessWidget {
  const _ConfirmationItem({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppTheme.radiusSm,
            child: SizedBox(
              width: 44,
              height: 56,
              child: item.book.imagemUrl != null &&
                      item.book.imagemUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.book.imagemUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppTheme.surfaceContainer),
                    )
                  : Container(color: AppTheme.surfaceContainer),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.book.titulo,
                  style: AppTheme.labelSans.copyWith(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.book.autor}${item.quantity > 1 ? ' · ${item.quantity}x' : ''}',
                  style: AppTheme.captionSans.copyWith(fontSize: 11),
                ),
                Text(
                  'R\$ ${item.lineTotal.toStringAsFixed(2)}',
                  style: AppTheme.captionSans.copyWith(
                      color: AppTheme.primary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: AppTheme.bodySans
                .copyWith(fontSize: 13, color: AppTheme.onSurfaceVariant)),
        const Spacer(),
        Text(value, style: AppTheme.bodySans.copyWith(fontSize: 13)),
      ],
    );
  }
}

class _JourneyMilestones extends StatelessWidget {
  _JourneyMilestones();

  final _steps = const [
    _MilestoneStep(label: 'Pedido', active: true),
    _MilestoneStep(label: 'Processando', active: false),
    _MilestoneStep(label: 'Enviado', active: false),
    _MilestoneStep(label: 'Entregue', active: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < _steps.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                // Dot
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _steps[i].active
                        ? AppTheme.primary
                        : AppTheme.outlineVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _steps[i].label,
                  style: AppTheme.captionSans.copyWith(
                    fontSize: 10,
                    color: _steps[i].active
                        ? AppTheme.primary
                        : AppTheme.onSurfaceVariant,
                    fontWeight: _steps[i].active
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Connector line (between steps)
          if (i < _steps.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.outlineVariant.withValues(alpha: 0.5),
                  borderRadius: AppTheme.radiusSm,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _MilestoneStep {
  const _MilestoneStep({required this.label, required this.active});
  final String label;
  final bool active;
}
