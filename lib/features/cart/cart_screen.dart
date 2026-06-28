import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bibliotheca.dart';
import '../../core/widgets/book_cover.dart';
import '../../data/reader_repository.dart';
import 'cart_notifier.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  List<Book> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    try {
      final result = await ref.read(readerRepositoryProvider).books(perPage: 8);
      if (mounted) setState(() => _suggestions = result.items);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    final cartBookIds = cartItems.map((i) => i.book.id).toSet();
    final suggestions =
        _suggestions.where((b) => !cartBookIds.contains(b.id)).take(4).toList();

    final subtotal = cartItems.subtotal;
    final shipping = cartItems.shipping;
    final total = cartItems.total;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: BibDetailAppBar(
        title: 'Bibliotheca',
        actions: [
          _CartBadgeIcon(
            count: cartItems.itemCount,
            onTap: () {},
          ),
        ],
      ),
      body: cartItems.isEmpty
          ? _EmptyCart(onBrowse: () => context.pop())
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppTheme.marginMobile, 0, AppTheme.marginMobile, 120),
              children: [
                const SizedBox(height: 24),
                // ── Header ───────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('Sua Seleção',
                        style: AppTheme.displaySerif.copyWith(fontSize: 26)),
                    const Spacer(),
                    Text(
                      '${cartItems.length} ${cartItems.length == 1 ? 'item' : 'itens'}',
                      style: AppTheme.captionSans,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Items ─────────────────────────────────────────────────
                ...cartItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CartItemCard(
                      item: item,
                      onRemove: () => cartNotifier.removeBook(item.book.id),
                      onDecrement: () => cartNotifier.updateQuantity(
                          item.book.id, item.quantity - 1),
                      onIncrement: () => cartNotifier.updateQuantity(
                          item.book.id, item.quantity + 1),
                    ),
                  ),
                ),

                // ── Sugestões ─────────────────────────────────────────────
                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SuggestionsSection(
                    suggestions: suggestions,
                    onAdd: (b) {
                      cartNotifier.addBook(b);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('"${b.titulo}" adicionado ao carrinho'),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],

                // ── Order Summary ─────────────────────────────────────────
                const SizedBox(height: 24),
                BibCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Resumo do Pedido',
                          style:
                              AppTheme.titleSerif.copyWith(fontSize: 18)),
                      const SizedBox(height: 16),
                      _SummaryRow(
                          label: 'Subtotal',
                          value: 'R\$ ${subtotal.toStringAsFixed(2)}'),
                      const SizedBox(height: 8),
                      _SummaryRow(
                          label: 'Frete',
                          value: 'R\$ ${shipping.toStringAsFixed(2)}'),
                      const SizedBox(height: 8),
                      _SummaryRow(label: 'Impostos', value: 'R\$ 0,00'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(),
                      ),
                      Row(
                        children: [
                          Text('Total',
                              style: AppTheme.titleSerif
                                  .copyWith(fontWeight: FontWeight.w700)),
                          const Spacer(),
                          Text(
                            'R\$ ${total.toStringAsFixed(2)}',
                            style: AppTheme.headlineSerif.copyWith(
                              color: AppTheme.primary,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Promo code
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                hintText: 'Código de desconto',
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: const BorderSide(color: AppTheme.primary),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                            child: const Text('Aplicar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

      // ── Sticky bottom CTA ──────────────────────────────────────────────────
      bottomNavigationBar: cartItems.isEmpty
          ? null
          : _BottomCheckoutBar(
              total: total,
              onCheckout: () => context.push('/checkout'),
            ),
    );
  }
}

// ─── Widgets internos ────────────────────────────────────────────────────────

class _CartBadgeIcon extends StatelessWidget {
  const _CartBadgeIcon({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_bag_outlined, color: AppTheme.primary),
          onPressed: onTap,
        ),
        if (count > 0)
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
                '$count',
                style: AppTheme.captionSans.copyWith(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.onRemove,
    required this.onDecrement,
    required this.onIncrement,
  });

  final CartItem item;
  final VoidCallback onRemove;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final book = item.book;

    return BibCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover
          BookCover(
            url: book.imagemUrl,
            width: 70,
            height: 90,
            borderRadius: 8,
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
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
                          Text(
                            book.titulo,
                            style: AppTheme.titleSerif.copyWith(fontSize: 15),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            book.autor,
                            style: AppTheme.captionSans.copyWith(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (book.genero != null &&
                              book.genero!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            BibStatusChip(
                                label: book.genero!,
                                tone: BibChipTone.sage),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 20, color: AppTheme.onSurfaceVariant),
                      onPressed: onRemove,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Quantity stepper
                    _QuantityStepper(
                      quantity: item.quantity,
                      onDecrement: onDecrement,
                      onIncrement: onIncrement,
                    ),
                    const Spacer(),
                    // Price
                    Text(
                      'R\$ ${item.lineTotal.toStringAsFixed(2)}',
                      style: AppTheme.titleSerif.copyWith(
                        color: AppTheme.primary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.outlineVariant),
        borderRadius: AppTheme.radiusMd,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(icon: Icons.remove, onTap: onDecrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$quantity',
              style: AppTheme.labelSans.copyWith(fontSize: 14),
            ),
          ),
          _StepButton(icon: Icons.add, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppTheme.radiusMd,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 16, color: AppTheme.onSurface),
      ),
    );
  }
}

class _SuggestionsSection extends StatelessWidget {
  const _SuggestionsSection({
    required this.suggestions,
    required this.onAdd,
  });

  final List<Book> suggestions;
  final ValueChanged<Book> onAdd;

  @override
  Widget build(BuildContext context) {
    return BibCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COMPLETE SUA COLEÇÃO',
            style: AppTheme.captionSans.copyWith(
              letterSpacing: 0.1,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final book = suggestions[i];
                return GestureDetector(
                  onTap: () => onAdd(book),
                  child: SizedBox(
                    width: 100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BookCover(
                          url: book.imagemUrl,
                          width: 100,
                          height: 120,
                          borderRadius: 8,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          book.titulo,
                          style: AppTheme.captionSans
                              .copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'R\$ ${double.tryParse(book.preco)?.toStringAsFixed(2) ?? book.preco}',
                          style: AppTheme.captionSans.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: AppTheme.bodySans.copyWith(fontSize: 14)),
        const Spacer(),
        Text(value,
            style:
                AppTheme.bodySans.copyWith(fontSize: 14, color: AppTheme.onSurface)),
      ],
    );
  }
}

class _BottomCheckoutBar extends StatelessWidget {
  const _BottomCheckoutBar({
    required this.total,
    required this.onCheckout,
  });

  final double total;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
          AppTheme.marginMobile, 16, AppTheme.marginMobile, 16 + bottomPad),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
            top: BorderSide(
                color: AppTheme.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(
            onPressed: onCheckout,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.radiusLg),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Prosseguir para o Checkout',
                  style: AppTheme.labelSans.copyWith(
                      color: Colors.white, fontSize: 15),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline_rounded,
                  size: 14, color: AppTheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('CHECKOUT SEGURO',
                  style: AppTheme.captionSans.copyWith(
                      letterSpacing: 0.08,
                      fontWeight: FontWeight.w600,
                      fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined,
              size: 64, color: AppTheme.outlineVariant),
          const SizedBox(height: 16),
          Text('Seu carrinho está vazio',
              style: AppTheme.headlineSerif.copyWith(fontSize: 20)),
          const SizedBox(height: 8),
          Text('Explore o catálogo e adicione livros',
              style: AppTheme.bodySans
                  .copyWith(color: AppTheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onBrowse,
            child: const Text('Explorar Catálogo'),
          ),
        ],
      ),
    );
  }
}
