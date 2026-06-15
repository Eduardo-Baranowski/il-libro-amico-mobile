import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

/// Barra superior fixa estilo Stitch (título Bibliotheca + busca).
class BibTopBar extends StatelessWidget implements PreferredSizeWidget {
  const BibTopBar({super.key, this.showSearch = true, this.onSearch, this.onCart, this.cartCount});

  final bool showSearch;
  final VoidCallback? onSearch;
  final VoidCallback? onCart;
  final int? cartCount;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      elevation: 0,
      shadowColor: Colors.black26,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.marginMobile),
            child: Row(
              children: [
                Text('Bibliotheca', style: AppTheme.headlineSerif.copyWith(color: AppTheme.primary)),
                const Spacer(),
                if (showSearch)
                  IconButton(
                    onPressed: onSearch ?? () => context.push('/buscar'),
                    icon: const Icon(Icons.search_rounded, color: AppTheme.primary),
                    tooltip: 'Buscar',
                  ),
                if (onCart != null)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        onPressed: onCart,
                        icon: const Icon(Icons.shopping_bag_outlined, color: AppTheme.primary),
                        tooltip: 'Carrinho',
                      ),
                      if (cartCount != null && cartCount! > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$cartCount',
                              style: AppTheme.captionSans.copyWith(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BibSectionHeader extends StatelessWidget {
  const BibSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTheme.headlineSerif.copyWith(fontSize: 22))),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: AppTheme.labelSans.copyWith(color: AppTheme.primary),
              ),
            ),
        ],
      ),
    );
  }
}

class BibStatusChip extends StatelessWidget {
  const BibStatusChip({super.key, required this.label, this.tone = BibChipTone.sage});

  final String label;
  final BibChipTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      BibChipTone.sage => (AppTheme.secondaryContainer, AppTheme.onSecondaryContainer),
      BibChipTone.terracotta => (AppTheme.primarySoft, AppTheme.primary),
      BibChipTone.neutral => (AppTheme.surfaceContainer, AppTheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppTheme.radiusSm,
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTheme.captionSans.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 10,
          color: fg,
          letterSpacing: 0.06,
        ),
      ),
    );
  }
}

enum BibChipTone { sage, terracotta, neutral }

class BibGenreChip extends StatelessWidget {
  const BibGenreChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, style: AppTheme.labelSans.copyWith(fontSize: 13)),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      backgroundColor: AppTheme.surfaceHighest,
      selectedColor: AppTheme.secondaryContainer,
      labelStyle: TextStyle(
        color: selected ? AppTheme.onSecondaryContainer : AppTheme.onSurfaceVariant,
      ),
      side: BorderSide(
        color: selected ? AppTheme.secondary.withValues(alpha: 0.3) : Colors.transparent,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusLg),
    );
  }
}

class BibPriceText extends StatelessWidget {
  const BibPriceText(this.price, {super.key, this.style});

  final String price;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      'R\$ $price',
      style: style ??
          AppTheme.titleSerif.copyWith(
            fontSize: 16,
            color: AppTheme.primary,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class BibCard extends StatelessWidget {
  const BibCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: AppTheme.radiusXl,
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.25)),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: padding,
      child: child,
    );
  }
}

/// AppBar para telas fora do shell (detalhe, chat, etc.).
class BibDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BibDetailAppBar({
    super.key,
    this.title = 'Bibliotheca',
    this.actions = const [],
  });

  final String title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => context.pop(),
      ),
      title: Text(title, style: AppTheme.headlineSerif.copyWith(fontSize: 20, color: AppTheme.primary)),
      actions: actions,
    );
  }
}
