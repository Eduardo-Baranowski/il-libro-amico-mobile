import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../core/api/api_exception.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bibliotheca.dart';
import '../../data/reader_repository.dart';
import 'address_notifier.dart';
import 'cart_notifier.dart';

// ─── Tipos locais ─────────────────────────────────────────────────────────────

enum _ShippingMethod { standard, express }

enum _PaymentMethod { creditCard, pix, applePay }

// ─── Formatters ───────────────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue value) {
    final digits = value.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final str = buffer.toString();
    return value.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue value) {
    final digits = value.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 4; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digits[i]);
    }
    final str = buffer.toString();
    return value.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

// ─── Validadores ─────────────────────────────────────────────────────────────

String? _validateCardholder(String? v) {
  if (v == null || v.trim().isEmpty) return 'Informe o nome no cartão';
  final parts = v.trim().split(RegExp(r'\s+'));
  if (parts.length < 2) return 'Informe nome e sobrenome';
  if (parts.any((p) => p.length < 2)) return 'Nome inválido';
  return null;
}

String? _validateCardNumber(String? v) {
  if (v == null || v.isEmpty) return 'Informe o número do cartão';
  final digits = v.replaceAll(' ', '');
  if (digits.length != 16) return 'O cartão deve ter 16 dígitos';
  if (!RegExp(r'^\d+$').hasMatch(digits)) return 'Apenas números';
  // Luhn check
  int sum = 0;
  bool alternate = false;
  for (int i = digits.length - 1; i >= 0; i--) {
    int n = int.parse(digits[i]);
    if (alternate) {
      n *= 2;
      if (n > 9) n -= 9;
    }
    sum += n;
    alternate = !alternate;
  }
  if (sum % 10 != 0) return 'Número de cartão inválido';
  return null;
}

String? _validateExpiry(String? v) {
  if (v == null || v.isEmpty) return 'Informe a validade';
  if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(v)) return 'Use o formato MM/AA';
  final parts = v.split('/');
  final month = int.tryParse(parts[0]) ?? 0;
  final year = int.tryParse(parts[1]) ?? 0;
  if (month < 1 || month > 12) return 'Mês inválido';
  final now = DateTime.now();
  final fullYear = 2000 + year;
  final expiry = DateTime(fullYear, month + 1);
  if (expiry.isBefore(now)) return 'Cartão vencido';
  return null;
}

String? _validateCvv(String? v) {
  if (v == null || v.isEmpty) return 'Informe o CVV';
  if (!RegExp(r'^\d{3,4}$').hasMatch(v)) return 'CVV inválido (3-4 dígitos)';
  return null;
}

// ─── Tela ─────────────────────────────────────────────────────────────────────

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  _ShippingMethod _shipping = _ShippingMethod.standard;
  _PaymentMethod _payment = _PaymentMethod.creditCard;
  Address? _selectedAddress;
  bool _placing = false;
  bool _autoValidate = false;

  final _cardHolderCtrl = TextEditingController();
  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  @override
  void dispose() {
    _cardHolderCtrl.dispose();
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  double get _shippingCost =>
      _shipping == _ShippingMethod.express ? 14.00 : 5.50;

  bool _validateForm() {
    // Para Pix / Apple Pay não há campos de cartão para validar
    if (_payment != _PaymentMethod.creditCard) return true;
    setState(() => _autoValidate = true);
    return _formKey.currentState?.validate() ?? false;
  }

  Future<void> _placeOrder(List<CartItem> cartItems) async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione ou adicione um endereço de entrega.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    if (!_validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Corrija os erros antes de continuar.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _placing = true);
    try {
      final repo = ref.read(readerRepositoryProvider);
      // Registra compra no backend para cada item (sem gateway de pagamento real)
      await Future.wait(
        cartItems.map(
          (item) => repo.purchaseBook(item.book.id, quantidade: item.quantity),
        ),
      );

      final subtotal = cartItems.subtotal;
      final confirmation = PurchaseConfirmation(
        orderNumber: '#BIB-${(DateTime.now().millisecondsSinceEpoch % 9000000) + 1000000}',
        estimatedArrival: _estimatedArrival(),
        items: List.from(cartItems),
        subtotal: subtotal,
        shipping: _shippingCost,
      );

      ref.read(cartProvider.notifier).clear();

      if (mounted) {
        context.go('/compra/confirmacao', extra: confirmation);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao finalizar pedido. Tente novamente.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  String _estimatedArrival() {
    final base = DateTime.now();
    final months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
    ];
    if (_shipping == _ShippingMethod.express) {
      final d = base.add(const Duration(days: 1));
      return '${d.day} ${months[d.month - 1]}';
    }
    final start = base.add(const Duration(days: 3));
    final end = base.add(const Duration(days: 5));
    return '${start.day} ${months[start.month - 1]} – ${end.day} ${months[end.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final addressState = ref.watch(addressProvider);
    final subtotal = cartItems.subtotal;
    final total = subtotal + _shippingCost;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const BibDetailAppBar(title: 'Bibliotheca'),
      body: Form(
        key: _formKey,
        autovalidateMode: _autoValidate
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              AppTheme.marginMobile, 0, AppTheme.marginMobile, 16 + bottomPad + 80),
          children: [
            const SizedBox(height: 24),

            // ── Endereço de entrega ──────────────────────────────────────────
            _SectionHeader(
              icon: Icons.location_on_outlined,
              title: 'Endereço de Entrega',
              action: TextButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => _AddAddressBottomSheet(
                      onSave: (data) async {
                        final newAddr = await ref
                            .read(addressProvider.notifier)
                            .addAddress(data);
                        setState(() {
                          _selectedAddress = newAddr;
                        });
                      },
                    ),
                  );
                },
                child: Text(
                  '+ Adicionar Novo',
                  style: AppTheme.labelSans
                      .copyWith(color: AppTheme.primary, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 12),
            addressState.when(
              data: (addresses) {
                if (addresses.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Nenhum endereço cadastrado. Adicione um para continuar.',
                      style: AppTheme.bodySans
                          .copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                  );
                }
                if (_selectedAddress == null ||
                    !addresses.any((a) => a.id == _selectedAddress?.id)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && addresses.isNotEmpty) {
                      setState(() {
                        _selectedAddress = addresses.first;
                      });
                    }
                  });
                }
                return Column(
                  children: addresses
                      .map((addr) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _AddressCard(
                              address: addr,
                              selected: _selectedAddress?.id == addr.id,
                              onTap: () =>
                                  setState(() => _selectedAddress = addr),
                            ),
                          ))
                      .toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Erro ao carregar endereços: $err',
                  style: AppTheme.bodySans.copyWith(color: AppTheme.error),
                ),
              ),
            ),

            // ── Método de envio ──────────────────────────────────────────────
            const SizedBox(height: 24),
            _SectionHeader(
              icon: Icons.local_shipping_outlined,
              title: 'Método de Envio',
            ),
            const SizedBox(height: 12),
            _ShippingOption(
              label: 'Entrega Padrão',
              subtitle: '3–5 dias úteis',
              price: 'R\$ 5,50',
              selected: _shipping == _ShippingMethod.standard,
              onTap: () => setState(() => _shipping = _ShippingMethod.standard),
            ),
            const SizedBox(height: 8),
            _ShippingOption(
              label: 'Entrega Expressa',
              subtitle: 'Amanhã até 18h',
              price: 'R\$ 14,00',
              selected: _shipping == _ShippingMethod.express,
              onTap: () => setState(() => _shipping = _ShippingMethod.express),
            ),

            // ── Forma de pagamento ───────────────────────────────────────────
            const SizedBox(height: 24),
            _SectionHeader(
              icon: Icons.credit_card_outlined,
              title: 'Forma de Pagamento',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PaymentButton(
                    icon: Icons.credit_card_rounded,
                    label: 'Cartão',
                    selected: _payment == _PaymentMethod.creditCard,
                    onTap: () =>
                        setState(() => _payment = _PaymentMethod.creditCard),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PaymentButton(
                    icon: Icons.pix_rounded,
                    label: 'Pix',
                    selected: _payment == _PaymentMethod.pix,
                    onTap: () => setState(() => _payment = _PaymentMethod.pix),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PaymentButton(
                    icon: Icons.phone_iphone_rounded,
                    label: 'Apple Pay',
                    selected: _payment == _PaymentMethod.applePay,
                    onTap: () =>
                        setState(() => _payment = _PaymentMethod.applePay),
                  ),
                ),
              ],
            ),

            // ── Campos do cartão (com validação real) ─────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _payment == _PaymentMethod.creditCard
                  ? Padding(
                      key: const ValueKey('card_fields'),
                      padding: const EdgeInsets.only(top: 14),
                      child: BibCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cardholder
                            _FieldLabel('NOME NO CARTÃO'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _cardHolderCtrl,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                hintText: 'NOME SOBRENOME',
                              ),
                              validator: _validateCardholder,
                            ),
                            const SizedBox(height: 14),

                            // Card number
                            _FieldLabel('NÚMERO DO CARTÃO'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _cardNumberCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [_CardNumberFormatter()],
                              decoration: const InputDecoration(
                                hintText: '0000 0000 0000 0000',
                                suffixIcon: Icon(
                                    Icons.lock_outline_rounded, size: 18),
                              ),
                              validator: (v) =>
                                  _validateCardNumber(v?.replaceAll(' ', '')),
                            ),
                            const SizedBox(height: 14),

                            // Expiry + CVV
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _FieldLabel('VALIDADE'),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _expiryCtrl,
                                        keyboardType:
                                            TextInputType.datetime,
                                        inputFormatters: [
                                          _ExpiryFormatter(),
                                        ],
                                        decoration: const InputDecoration(
                                            hintText: 'MM/AA'),
                                        validator: _validateExpiry,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _FieldLabel('CVV'),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _cvvCtrl,
                                        keyboardType: TextInputType.number,
                                        obscureText: true,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(4),
                                        ],
                                        decoration: const InputDecoration(
                                            hintText: '***'),
                                        validator: _validateCvv,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  : _payment == _PaymentMethod.pix
                      ? Padding(
                          key: const ValueKey('pix_info'),
                          padding: const EdgeInsets.only(top: 14),
                          child: BibCard(
                            child: Row(
                              children: [
                                const Icon(Icons.pix_rounded,
                                    color: AppTheme.secondary, size: 32),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Um QR Code Pix será gerado após a confirmação do pedido.',
                                    style: AppTheme.bodySans
                                        .copyWith(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Padding(
                          key: const ValueKey('applepay_info'),
                          padding: const EdgeInsets.only(top: 14),
                          child: BibCard(
                            child: Row(
                              children: [
                                const Icon(Icons.phone_iphone_rounded,
                                    color: AppTheme.onSurfaceVariant,
                                    size: 32),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'A autenticação Apple Pay será solicitada ao confirmar o pedido.',
                                    style: AppTheme.bodySans
                                        .copyWith(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
            ),

            // ── Resumo do Pedido ─────────────────────────────────────────────
            const SizedBox(height: 24),
            BibCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Resumo do Pedido',
                      style: AppTheme.titleSerif.copyWith(fontSize: 17)),
                  const SizedBox(height: 12),
                  ...cartItems.map((item) => _OrderItem(item: item)),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(),
                  ),
                  _SummaryLine(
                      label: 'Subtotal',
                      value: 'R\$ ${subtotal.toStringAsFixed(2)}'),
                  const SizedBox(height: 6),
                  _SummaryLine(
                      label: 'Frete',
                      value: 'R\$ ${_shippingCost.toStringAsFixed(2)}'),
                  const SizedBox(height: 6),
                  _SummaryLine(label: 'Impostos', value: 'R\$ 0,00'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
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
                            color: AppTheme.primary, fontSize: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Center(
              child: Text(
                'Ao finalizar, você concorda com os Termos de Serviço\ne Política de Privacidade da Bibliotheca.',
                textAlign: TextAlign.center,
                style: AppTheme.captionSans.copyWith(fontSize: 11),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.security_rounded,
                    size: 14, color: AppTheme.secondary),
                const SizedBox(width: 4),
                Text(
                  'Checkout SSL seguro. Seus dados estão protegidos.',
                  style: AppTheme.captionSans.copyWith(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),

      // ── Sticky footer ─────────────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            AppTheme.marginMobile, 12, AppTheme.marginMobile, 12 + bottomPad),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(
              top: BorderSide(
                  color: AppTheme.outlineVariant.withValues(alpha: 0.3))),
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TOTAL',
                    style: AppTheme.captionSans.copyWith(
                        fontSize: 10,
                        letterSpacing: 0.08,
                        fontWeight: FontWeight.w700)),
                Text(
                  'R\$ ${total.toStringAsFixed(2)}',
                  style: AppTheme.titleSerif
                      .copyWith(color: AppTheme.primary, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed: _placing || cartItems.isEmpty
                    ? null
                    : () => _placeOrder(cartItems),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.radiusLg),
                ),
                child: _placing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Finalizar Pedido',
                              style: AppTheme.labelSans
                                  .copyWith(color: Colors.white, fontSize: 15)),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 16),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets internos ─────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTheme.captionSans.copyWith(
          fontSize: 10,
          letterSpacing: 0.08,
          fontWeight: FontWeight.w700,
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.action,
  });

  final IconData icon;
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(title, style: AppTheme.titleSerif.copyWith(fontSize: 17)),
        const Spacer(),
        if (action != null) action!,
      ],
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.selected,
    required this.onTap,
  });

  final Address address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: AppTheme.radiusXl,
          border: Border.all(
            color: selected
                ? AppTheme.primary
                : AppTheme.outlineVariant.withValues(alpha: 0.35),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(address.label,
                      style: AppTheme.labelSans.copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('${address.rua}, ${address.numero}',
                      style: AppTheme.bodySans.copyWith(
                          fontSize: 13, color: AppTheme.onSurfaceVariant)),
                  Text(address.bairro,
                      style: AppTheme.bodySans.copyWith(
                          fontSize: 13, color: AppTheme.onSurfaceVariant)),
                  Text('${address.cidade} - ${address.estado}, CEP ${address.cep}',
                      style: AppTheme.bodySans.copyWith(
                          fontSize: 13, color: AppTheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ShippingOption extends StatelessWidget {
  const _ShippingOption({
    required this.label,
    required this.subtitle,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final String price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: AppTheme.radiusXl,
          border: Border.all(
            color: selected
                ? AppTheme.primary
                : AppTheme.outlineVariant.withValues(alpha: 0.35),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppTheme.primary : Colors.transparent,
                border: Border.all(
                  color: selected ? AppTheme.primary : AppTheme.outline,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.circle, color: Colors.white, size: 10)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTheme.labelSans.copyWith(fontSize: 14)),
                  Text(subtitle,
                      style: AppTheme.captionSans.copyWith(fontSize: 12)),
                ],
              ),
            ),
            Text(price,
                style: AppTheme.labelSans
                    .copyWith(color: AppTheme.primary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _PaymentButton extends StatelessWidget {
  const _PaymentButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primarySoft : AppTheme.surfaceWhite,
          borderRadius: AppTheme.radiusXl,
          border: Border.all(
            color: selected
                ? AppTheme.primary
                : AppTheme.outlineVariant.withValues(alpha: 0.4),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected
                    ? AppTheme.primary
                    : AppTheme.onSurfaceVariant,
                size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.captionSans.copyWith(
                fontSize: 11,
                color: selected ? AppTheme.primary : AppTheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderItem extends StatelessWidget {
  const _OrderItem({required this.item});

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

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

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

class _CepFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue value) {
    final digits = value.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 8; i++) {
      if (i == 5) buffer.write('-');
      buffer.write(digits[i]);
    }
    final str = buffer.toString();
    return value.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

class _AddAddressBottomSheet extends StatefulWidget {
  const _AddAddressBottomSheet({required this.onSave});

  final Future<void> Function(Map<String, dynamic> data) onSave;

  @override
  State<_AddAddressBottomSheet> createState() => _AddAddressBottomSheetState();
}

class _AddAddressBottomSheetState extends State<_AddAddressBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  String _selectedLabel = 'Casa';
  final _customLabelCtrl = TextEditingController();
  final _ruaCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _estadoCtrl = TextEditingController();
  final _cepCtrl = TextEditingController();
  bool _saving = false;
  String _lastCep = '';

  @override
  void initState() {
    super.initState();
    _cepCtrl.addListener(_onCepChanged);
  }

  void _onCepChanged() {
    final clean = _cepCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 8 && clean != _lastCep) {
      _lastCep = clean;
      _lookupCep(clean);
    }
  }

  Future<void> _lookupCep(String cep) async {
    try {
      final res = await http.get(Uri.parse('https://viacep.com.br/ws/$cep/json/'));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        if (decoded['erro'] == true || decoded['erro'] == 'true') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('CEP não encontrado.'),
                backgroundColor: AppTheme.error,
              ),
            );
          }
          return;
        }

        setState(() {
          _ruaCtrl.text = decoded['logradouro'] as String? ?? '';
          _bairroCtrl.text = decoded['bairro'] as String? ?? '';
          _cidadeCtrl.text = decoded['localidade'] as String? ?? '';
          _estadoCtrl.text = decoded['uf'] as String? ?? '';
        });
      }
    } catch (_) {
      // Ignorar erros de rede silenciosamente ou sem quebrar o fluxo
    }
  }

  @override
  void dispose() {
    _cepCtrl.removeListener(_onCepChanged);
    _customLabelCtrl.dispose();
    _ruaCtrl.dispose();
    _numeroCtrl.dispose();
    _bairroCtrl.dispose();
    _cidadeCtrl.dispose();
    _estadoCtrl.dispose();
    _cepCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPad),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Novo Endereço de Entrega',
                style: AppTheme.titleSerif.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 16),
              
              // Chips de Categoria
              Text(
                'CATEGORIA',
                style: AppTheme.captionSans.copyWith(
                  fontSize: 10,
                  letterSpacing: 0.08,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: ['Casa', 'Trabalho', 'Outro'].map((label) {
                  final isSelected = _selectedLabel == label;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedLabel = label);
                        }
                      },
                      selectedColor: AppTheme.primarySoft,
                      labelStyle: AppTheme.labelSans.copyWith(
                        fontSize: 13,
                        color: isSelected ? AppTheme.primary : AppTheme.onSurface,
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_selectedLabel == 'Outro') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customLabelCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Ex: Casa de Praia, Sítio',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome da categoria' : null,
                ),
              ],
              const SizedBox(height: 16),

              // CEP + Número
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CEP',
                          style: AppTheme.captionSans.copyWith(
                            fontSize: 10,
                            letterSpacing: 0.08,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _cepCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [_CepFormatter()],
                          decoration: const InputDecoration(
                            hintText: '00000-000',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Obrigatório';
                            final clean = v.replaceAll(RegExp(r'\D'), '');
                            if (clean.length != 8) return 'CEP inválido';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NÚMERO',
                          style: AppTheme.captionSans.copyWith(
                            fontSize: 10,
                            letterSpacing: 0.08,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _numeroCtrl,
                          decoration: const InputDecoration(
                            hintText: '123',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Rua
              Text(
                'RUA / LOGRADOURO',
                style: AppTheme.captionSans.copyWith(
                  fontSize: 10,
                  letterSpacing: 0.08,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _ruaCtrl,
                decoration: const InputDecoration(
                  hintText: 'Av. Paulista, Rua das Flores',
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Informe a rua' : null,
              ),
              const SizedBox(height: 14),

              // Bairro
              Text(
                'BAIRRO',
                style: AppTheme.captionSans.copyWith(
                  fontSize: 10,
                  letterSpacing: 0.08,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _bairroCtrl,
                decoration: const InputDecoration(
                  hintText: 'Centro, Copacabana',
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Informe o bairro' : null,
              ),
              const SizedBox(height: 14),

              // Cidade + Estado
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CIDADE',
                          style: AppTheme.captionSans.copyWith(
                            fontSize: 10,
                            letterSpacing: 0.08,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _cidadeCtrl,
                          decoration: const InputDecoration(
                            hintText: 'São Paulo',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ESTADO',
                          style: AppTheme.captionSans.copyWith(
                            fontSize: 10,
                            letterSpacing: 0.08,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _estadoCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            hintText: 'SP',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Obrigatório';
                            if (v.trim().length != 2) return 'Use a sigla';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Botões
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppTheme.radiusLg,
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppTheme.radiusLg,
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Salvar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _saving = true);
      try {
        final finalLabel = _selectedLabel == 'Outro'
            ? _customLabelCtrl.text.trim()
            : _selectedLabel;
        final payload = {
          'label': finalLabel,
          'rua': _ruaCtrl.text.trim(),
          'numero': _numeroCtrl.text.trim(),
          'bairro': _bairroCtrl.text.trim(),
          'cidade': _cidadeCtrl.text.trim(),
          'estado': _estadoCtrl.text.trim().toUpperCase(),
          'cep': _cepCtrl.text.trim(),
        };
        await widget.onSave(payload);
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar endereço: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _saving = false);
        }
      }
    }
  }
}

