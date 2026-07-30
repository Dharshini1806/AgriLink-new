import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_button.dart';
import '../providers/orders_provider.dart';
import '../widgets/review_dialog.dart';

class OrderTrackingScreen extends ConsumerWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  static const _steps = [
    ('pending',          Icons.hourglass_top_rounded,     'Order Placed'),
    ('confirmed',        Icons.check_circle_outline,      'Confirmed'),
    ('packed',           Icons.inventory_2_outlined,      'Packed'),
    ('out_for_delivery', Icons.local_shipping_outlined,   'Out for Delivery'),
    ('delivered',        Icons.home_outlined,             'Delivered'),
  ];

  int _stepIndex(String status) {
    for (int i = 0; i < _steps.length; i++) {
      if (_steps[i].$1 == status) return i;
    }
    return status == 'cancelled' ? -1 : 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final orderIdShort = orderId.length >= 8 ? orderId.substring(0, 8) : orderId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Order #${orderIdShort.toUpperCase()}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            onPressed: () => context.push('/order/$orderId/chat'),
          ),
        ],
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('$e')),
        data: (order) {
          final status = order['status'] as String;
          final isCancelled = status == 'cancelled';
          final currentStep = _stepIndex(status);
          final items = (order['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCancelled ? AppColors.error.withOpacity(0.08) : AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isCancelled ? AppColors.error.withOpacity(0.2) : AppColors.primary.withOpacity(0.15)),
                ),
                child: Row(children: [
                  Icon(
                    isCancelled ? Icons.cancel_outlined : Icons.local_shipping_rounded,
                    color: isCancelled ? AppColors.error : AppColors.primary, size: 32,
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(AppFormatters.orderStatus(status),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18,
                        color: isCancelled ? AppColors.error : AppColors.primary)),
                    Text('From: ${order['seller_name'] ?? ''}',
                      style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
                  ]),
                ]),
              ),
              const SizedBox(height: 20),

              // Stepper
              if (!isCancelled) Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Column(children: List.generate(_steps.length, (i) {
                  final isDone    = i <= currentStep;
                  final isCurrent = i == currentStep;
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Column(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone ? AppColors.primary : AppColors.surfaceVariant,
                          border: isCurrent ? Border.all(color: AppColors.primary, width: 2) : null,
                        ),
                        child: Icon(_steps[i].$2,
                          color: isDone ? Colors.white : AppColors.textHint, size: 18),
                      ),
                      if (i < _steps.length - 1) Container(
                        width: 2, height: 28,
                        color: i < currentStep ? AppColors.primary : AppColors.border,
                      ),
                    ]),
                    const SizedBox(width: 12),
                    Expanded(child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      child: Text(_steps[i].$3,
                        style: GoogleFonts.poppins(
                          fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                          color: isDone ? AppColors.textPrimary : AppColors.textHint,
                        )),
                    )),
                  ]);
                })),
              ),

              const SizedBox(height: 16),

              // Items
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Items', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Expanded(child: Text('${item['name']} × ${item['quantity']}',
                        style: GoogleFonts.poppins(fontSize: 13))),
                      Text(AppFormatters.currency(AppFormatters.parseDouble(item['unit_price']) * AppFormatters.parseDouble(item['quantity'])),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13)),
                    ]),
                  )),
                  const Divider(),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Total Paid', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                    Text(AppFormatters.currency(AppFormatters.parseDouble(order['total_amount'])),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ]),
                ]),
              ),

              const SizedBox(height: 16),

              // Delivery address
              if (order['delivery_address'] != null) Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Row(children: [
                  const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(order['delivery_address'] as String,
                    style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary))),
                ]),
              ),

              const SizedBox(height: 20),

              // Chat button
              AppButton(
                label: 'Chat with Farmer',
                icon: Icons.chat_bubble_outline_rounded,
                isOutlined: true,
                onPressed: () => context.push('/order/$orderId/chat'),
              ),

              if (status == 'delivered') ...[
                const SizedBox(height: 12),
                AppButton(
                  label: 'Rate Order',
                  icon: Icons.star_outline_rounded,
                  color: Colors.amber[800],
                  onPressed: () {
                    final firstProduct = items.isNotEmpty ? items.first : null;
                    showDialog(
                      context: context,
                      builder: (ctx) => ReviewDialog(
                        orderId: orderId,
                        productId: firstProduct?['product_id'] as String?,
                        sellerId: order['seller_id'] as String?,
                        sellerName: order['seller_name'] as String? ?? 'Farmer',
                      ),
                    );
                  },
                ),
              ],

              if (status == 'pending' || status == 'confirmed') ...[
                const SizedBox(height: 12),
                AppButton(
                  label: 'Cancel Order',
                  color: AppColors.error,
                  onPressed: () async {
                    final ok = await ref.read(buyerOrdersProvider.notifier).cancelOrder(orderId);
                    if (ok && context.mounted) {
                      ref.invalidate(orderDetailProvider(orderId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Order cancelled')));
                    }
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
