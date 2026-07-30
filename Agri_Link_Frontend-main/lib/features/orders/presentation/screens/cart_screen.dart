import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_button.dart';
import '../providers/orders_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Cart')),
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.shopping_cart_outlined, size: 72, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('Your cart is empty', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('Add fresh produce from nearby farmers', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          SizedBox(width: 200, child: AppButton(label: 'Browse Products', onPressed: () => context.go('/home'))),
        ])),
      );
    }

    final grouped = notifier.groupedBySeller;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Cart (${notifier.itemCount} items)'),
        actions: [
          TextButton(onPressed: notifier.clear, child: const Text('Clear', style: TextStyle(color: AppColors.error))),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...grouped.entries.map((entry) {
                final parts    = entry.key.split('_');
                final sellerName = parts.length > 1 ? parts.sublist(1).join('_') : 'Seller';
                final items    = entry.value;
                return _SellerGroup(sellerName: sellerName, items: items, notifier: notifier);
              }),
              const SizedBox(height: 16),
              _SummaryCard(notifier: notifier),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: AppButton(
            label: 'Proceed to Checkout',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => context.push('/checkout'),
          ),
        ),
      ]),
    );
  }
}

class _SellerGroup extends StatelessWidget {
  final String sellerName;
  final List items;
  final CartNotifier notifier;
  const _SellerGroup({required this.sellerName, required this.items, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            const Icon(Icons.storefront_outlined, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(sellerName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
          ]),
        ),
        const Divider(height: 1),
        ...items.map((item) => _CartItemTile(item: item, notifier: notifier)),
      ]),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final item;
  final CartNotifier notifier;
  const _CartItemTile({required this.item, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final imageUrls = (item.product['image_urls'] as List?)?.cast<String>() ?? [];
    final img = imageUrls.isNotEmpty ? imageUrls.first : null;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: img != null
            ? CachedNetworkImage(imageUrl: img, width: 60, height: 60, fit: BoxFit.cover)
            : Container(width: 60, height: 60, color: AppColors.surfaceVariant,
                child: const Icon(Icons.image_outlined, color: AppColors.textHint)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.product['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13)),
          Text(AppFormatters.currency(AppFormatters.parseDouble(item.product['price'])),
            style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w600)),
        ])),
        // Qty stepper
        Row(children: [
          _QtyBtn(icon: Icons.remove_rounded, onTap: () => notifier.updateQty(item.productId, item.quantity - 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text('${item.quantity}', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
          _QtyBtn(icon: Icons.add_rounded, onTap: () => notifier.updateQty(item.productId, item.quantity + 1)),
        ]),
      ]),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon, size: 16, color: AppColors.textPrimary),
    ),
  );
}

class _SummaryCard extends StatelessWidget {
  final CartNotifier notifier;
  const _SummaryCard({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(children: [
        _Row('Subtotal', AppFormatters.currency(notifier.subtotal)),
        const SizedBox(height: 8),
        _Row('Delivery charges', AppFormatters.currency(notifier.deliveryFee), isSmall: true),
        const Divider(height: 20),
        _Row('Total Payable', AppFormatters.currency(notifier.total), isBold: true),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.success),
            const SizedBox(width: 6),
            Expanded(child: Text(
              'Delivery charges are calculated at ₹5 per km from the farm.',
              style: GoogleFonts.poppins(fontSize: 11, color: AppColors.success),
            )),
          ]),
        ),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool isSmall;
  const _Row(this.label, this.value, {this.isBold = false, this.isSmall = false});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: GoogleFonts.poppins(
        fontSize: isSmall ? 12 : 14, color: isSmall ? AppColors.textSecondary : AppColors.textPrimary,
        fontWeight: isBold ? FontWeight.w700 : FontWeight.normal)),
      Text(value, style: GoogleFonts.poppins(
        fontSize: isSmall ? 12 : 14, color: isBold ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isBold ? FontWeight.w700 : FontWeight.w500)),
    ],
  );
}
