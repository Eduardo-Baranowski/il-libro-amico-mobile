import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>(
  (ref) => CartNotifier(),
);

// ─── Computed helpers ────────────────────────────────────────────────────────

extension CartHelpers on List<CartItem> {
  double get subtotal => fold(0.0, (sum, i) => sum + i.lineTotal);

  double get shipping => isEmpty ? 0.0 : 5.50;

  double get tax => 0.0;

  double get total => subtotal + shipping + tax;

  int get itemCount => fold(0, (sum, i) => sum + i.quantity);
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  /// Adiciona livro ao carrinho. Se já existir, incrementa a quantidade.
  void addBook(Book book) {
    final price = double.tryParse(book.preco) ?? 0.0;
    if (price <= 0) {
      return;
    }

    final index = state.indexWhere((i) => i.book.id == book.id);
    if (index >= 0) {
      final updated = List<CartItem>.from(state);
      updated[index] = updated[index].copyWith(
        quantity: updated[index].quantity + 1,
      );
      state = updated;
    } else {
      state = [...state, CartItem(book: book)];
    }
  }

  void removeBook(int bookId) {
    state = state.where((i) => i.book.id != bookId).toList();
  }

  void updateQuantity(int bookId, int qty) {
    if (qty <= 0) {
      removeBook(bookId);
      return;
    }
    state = state.map((i) {
      if (i.book.id == bookId) return i.copyWith(quantity: qty);
      return i;
    }).toList();
  }

  void clear() => state = [];
}
