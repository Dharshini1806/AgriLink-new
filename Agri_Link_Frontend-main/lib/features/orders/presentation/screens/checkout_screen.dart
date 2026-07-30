import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/orders_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _form    = GlobalKey<FormState>();
  final _addrC   = TextEditingController();
  final _notesC  = TextEditingController();
  bool _placing  = false;

  @override
  void dispose() { _addrC.dispose(); _notesC.dispose(); super.dispose(); }

  Future<void> _place() async {
    if (!_form.currentState!.validate()) return;
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) { context.go('/home'); return; }

    setState(() => _placing = true);
    final items = cart.map((i) => {'productId': i.productId, 'quantity': i.quantity}).toList();
    final ok = await ref.read(buyerOrdersProvider.notifier).placeOrder(
      items: items, deliveryAddress: _addrC.text.trim(), notes: _notesC.text.trim(),
    );
    setState(() => _placing = false);

    if (!mounted) return;
    if (ok) {
      ref.read(cartProvider.notifier).clear();
      _showSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order failed. Please try again.'), backgroundColor: AppColors.error),
      );
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 72, height: 72,
            decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 40)),
          const SizedBox(height: 16),
          Text('Order Placed!', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Your order has been sent to the farmer. You\'ll receive a confirmation shortly.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),
          AppButton(label: 'View Orders', onPressed: () { context.go('/orders'); }),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(cartProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Delivery Details', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 16),
            AppTextField(
              controller: _addrC,
              label: 'Delivery Address',
              hint: '123, Main Street, Chennai - 600001',
              prefixIcon: Icons.location_on_outlined,
              maxLines: 3,
              validator: (v) => AppValidators.required(v, 'Delivery address'),
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _notesC,
              label: 'Order Notes (optional)',
              hint: 'e.g. Leave at gate, call on arrival',
              prefixIcon: Icons.note_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Text('Order Summary', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Column(children: [
                ...ref.watch(cartProvider).map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Expanded(child: Text('${item.product['name']} × ${item.quantity}',
                      style: GoogleFonts.poppins(fontSize: 13))),
                    Text(AppFormatters.currency(item.subtotal),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  ]),
                )),
                const Divider(height: 20),
                _SumRow('Subtotal', AppFormatters.currency(notifier.subtotal)),
                const SizedBox(height: 4),
                _SumRow('Delivery charges', AppFormatters.currency(notifier.deliveryFee), isGrey: true),
                const Divider(height: 16),
                _SumRow('Total', AppFormatters.currency(notifier.total), isBold: true),
              ]),
            ),
            const SizedBox(height: 28),
            AppButton(
              label: 'Place Order  •  ${AppFormatters.currency(notifier.total)}',
              isLoading: _placing,
              onPressed: _place,
            ),
            const SizedBox(height: 12),
            Text('By placing an order you agree to our terms. Payment on delivery.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }
}

class _SumRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool isGrey;
  const _SumRow(this.label, this.value, {this.isBold = false, this.isGrey = false});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: GoogleFonts.poppins(fontSize: 13,
        color: isGrey ? AppColors.textSecondary : AppColors.textPrimary,
        fontWeight: isBold ? FontWeight.w700 : FontWeight.normal)),
      Text(value, style: GoogleFonts.poppins(fontSize: 13,
        color: isBold ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isBold ? FontWeight.w700 : FontWeight.w500)),
    ],
  );
}
