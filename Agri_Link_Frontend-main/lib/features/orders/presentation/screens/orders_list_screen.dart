import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/orders_provider.dart';
import '../widgets/review_dialog.dart';

class OrdersListScreen extends ConsumerWidget {
  const OrdersListScreen({super.key});

  static const _statusColors = {
    'pending': AppColors.statusPending,
    'confirmed': AppColors.statusConfirmed,
    'packed': AppColors.statusPacked,
    'out_for_delivery': AppColors.statusDelivery,
    'delivered': AppColors.statusDelivered,
    'cancelled': AppColors.statusCancelled,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(buyerOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Orders')),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(buyerOrdersProvider.notifier).load(),
        child: ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('$e', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(buyerOrdersProvider.notifier).load(),
              child: const Text('Retry'),
            ),
          ])),
          data: (orders) {
            if (orders.isEmpty) {
              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('No orders yet', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('Your order history will appear here', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: () => context.go('/home'), child: const Text('Browse Produce')),
              ]));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final order  = orders[i];
                final status = order['status'] as String;
                final color  = _statusColors[status] ?? AppColors.textHint;
                final items  = (order['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                final createdAt = DateTime.tryParse(order['created_at'] as String? ?? '');

                final orderIdStr = order['id']?.toString() ?? '';
                final orderIdShort = orderIdStr.length >= 8 ? orderIdStr.substring(0, 8) : orderIdStr;

                return GestureDetector(
                  onTap: () => context.push('/order/${order['id']}'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(
                          'Order #${orderIdShort.toUpperCase()}',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(AppFormatters.orderStatus(status),
                            style: GoogleFonts.poppins(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text('From: ${order['seller_name'] ?? ''}',
                        style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12)),
                      if (createdAt != null) Text(AppFormatters.dateTime(createdAt),
                        style: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 11)),
                      const SizedBox(height: 10),
                      // Items preview
                      if (items.isNotEmpty) Text(
                        items.take(2).map((it) => '${it['name']} ×${it['quantity']}').join(', ') +
                          (items.length > 2 ? ' +${items.length - 2} more' : ''),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const Divider(height: 16),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(AppFormatters.currency(AppFormatters.parseDouble(order['total_amount'])),
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.primary)),
                        Row(children: [
                          if (status == 'delivered') ...[
                            GestureDetector(
                              onTap: () {
                                final firstProduct = items.isNotEmpty ? items.first : null;
                                showDialog(
                                  context: context,
                                  builder: (ctx) => ReviewDialog(
                                    orderId: order['id'] as String,
                                    productId: firstProduct?['product_id'] as String?,
                                    sellerId: order['seller_id'] as String?,
                                    sellerName: order['seller_name'] as String? ?? 'Farmer',
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star_outline_rounded, size: 16, color: Colors.amber[700]),
                                  const SizedBox(width: 4),
                                  Text('Rate', style: GoogleFonts.poppins(fontSize: 12, color: Colors.amber[700])),
                                  const SizedBox(width: 12),
                                ],
                              ),
                            ),
                          ],
                          Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                        ]),
                      ]),
                    ]),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
