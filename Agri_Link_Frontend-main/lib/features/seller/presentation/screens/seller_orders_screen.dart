import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../features/orders/presentation/providers/orders_provider.dart';
import '../../../../shared/widgets/app_button.dart';

class SellerOrdersScreen extends ConsumerStatefulWidget {
  const SellerOrdersScreen({super.key});
  @override
  ConsumerState<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends ConsumerState<SellerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  static const _statuses = ['pending', 'confirmed', 'packed', 'out_for_delivery', 'delivered', 'cancelled'];
  static const _labels   = ['Pending', 'Confirmed', 'Packed', 'On Way', 'Done', 'Cancelled'];

  static const _nextStatus = {
    'pending':          'confirmed',
    'confirmed':        'packed',
    'packed':           'out_for_delivery',
    'out_for_delivery': 'delivered',
  };

  static const _nextLabel = {
    'pending':          'Accept',
    'confirmed':        '📦 Mark Packed',
    'packed':           '🚚 Dispatch',
    'out_for_delivery': '✅ Mark Delivered',
  };

  static const _statusColors = {
    'pending':          AppColors.statusPending,
    'confirmed':        AppColors.statusConfirmed,
    'packed':           AppColors.statusPacked,
    'out_for_delivery': AppColors.statusDelivery,
    'delivered':        AppColors.statusDelivered,
    'cancelled':        AppColors.statusCancelled,
  };

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _statuses.length, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> orders, String status) =>
    orders.where((o) => o['status'] == status).toList();

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(sellerOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Orders'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
          tabs: _labels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('$e')),
        data: (orders) => TabBarView(
          controller: _tabs,
          children: _statuses.map((status) {
            final filtered = _filter(orders, status);
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref.read(sellerOrdersProvider.notifier).load(),
              child: filtered.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.inbox_rounded, size: 56, color: AppColors.textHint),
                              const SizedBox(height: 12),
                              Text('No ${AppFormatters.orderStatus(status)} orders',
                                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) => _SellerOrderCard(
                      order: filtered[i],
                      statusColor: _statusColors[status] ?? AppColors.textHint,
                      nextStatus: _nextStatus[status],
                      nextLabel: _nextLabel[status],
                      onStatusUpdate: (String next) async {
                        final orderId = filtered[i]['id']?.toString() ?? '';
                        final ok = await ref.read(sellerOrdersProvider.notifier)
                            .updateStatus(orderId, next);
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Order updated to ${AppFormatters.orderStatus(next)}'),
                            backgroundColor: AppColors.success,
                          ));
                        }
                      },
                    ),
                  ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SellerOrderCard extends StatefulWidget {
  final Map<String, dynamic> order;
  final Color statusColor;
  final String? nextStatus;
  final String? nextLabel;
  final Future<void> Function(String) onStatusUpdate;
  const _SellerOrderCard({
    required this.order, required this.statusColor,
    this.nextStatus, this.nextLabel, required this.onStatusUpdate,
  });
  @override
  State<_SellerOrderCard> createState() => _SellerOrderCardState();
}

class _SellerOrderCardState extends State<_SellerOrderCard> {
  bool _updating = false;

  @override
  Widget build(BuildContext context) {
    final order  = widget.order;
    final itemsList = order['items'] as List? ?? [];
    final items = itemsList.map((item) {
      if (item is Map) {
        return Map<String, dynamic>.from(item);
      }
      return <String, dynamic>{};
    }).toList();
    final createdAt = DateTime.tryParse(order['created_at'] as String? ?? '');

    final orderIdStr = order['id']?.toString() ?? '';
    final orderIdShort = orderIdStr.length >= 8 ? orderIdStr.substring(0, 8) : orderIdStr;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Order #${orderIdShort.toUpperCase()}',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
              Text('Buyer: ${order['buyer_name'] ?? ''} • ${order['buyer_phone'] ?? ''}',
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
              if (createdAt != null)
                Text(AppFormatters.dateTime(createdAt),
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: widget.statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
              child: Text(AppFormatters.orderStatus(order['status']?.toString() ?? ''),
                style: GoogleFonts.poppins(color: widget.statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),

        const Divider(height: 1),

        // Items
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Items', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                Expanded(child: Text('• ${item['name'] ?? ''} × ${item['quantity'] ?? ''}',
                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary))),
                Text(AppFormatters.currency(AppFormatters.parseDouble(item['unit_price']) * AppFormatters.parseDouble(item['quantity'])),
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
              ]),
            )),
            const Divider(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Your Payout', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              Text(AppFormatters.currency(AppFormatters.parseDouble(order['total_amount']) * 0.99),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 15)),
            ]),
            if (order['delivery_address'] != null) ...[
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Expanded(child: Text(order['delivery_address']?.toString() ?? '',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint))),
              ]),
            ],
          ]),
        ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () => context.push('/order/${order['id']}/chat'),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
              label: Text('Chat', style: GoogleFonts.poppins(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            )),
            Consumer(
              builder: (context, ref, _) {
                final status = order['status']?.toString() ?? 'pending';
                if (status != 'pending' && status != 'confirmed') return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: OutlinedButton(
                    onPressed: _updating ? null : () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Cancel Order'),
                          content: const Text('Are you sure you want to cancel this order?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, Cancel')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        setState(() => _updating = true);
                        final orderId = order['id']?.toString() ?? '';
                        await ref.read(sellerOrdersProvider.notifier).cancelOrder(orderId);
                        setState(() => _updating = false);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                  ),
                );
              }
            ),
            if (widget.nextStatus != null) ...[
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _updating ? null : () async {
                    if (widget.nextStatus != null) {
                      setState(() => _updating = true);
                      await widget.onStatusUpdate(widget.nextStatus!);
                      setState(() => _updating = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _updating
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(widget.nextLabel ?? '',
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}
