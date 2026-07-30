import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_button.dart';

final _adminDashProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.watch(dioProvider).get(ApiEndpoints.adminDashboard);
  return res.data as Map<String, dynamic>;
});

final _adminFraudProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.watch(dioProvider).get(ApiEndpoints.adminFraud);
  return res.data as Map<String, dynamic>;
});

final _pendingProductsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.watch(dioProvider).get(ApiEndpoints.adminPending);
  return List<Map<String, dynamic>>.from(res.data as List? ?? []);
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync    = ref.watch(_adminDashProvider);
    final fraudAsync   = ref.watch(_adminFraudProvider);
    final pendingAsync = ref.watch(_pendingProductsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text('Admin Panel', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
          ]),
          automaticallyImplyLeading: false,
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Moderation'),
              Tab(text: 'Fraud'),
            ],
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
        body: TabBarView(children: [
          // ── OVERVIEW TAB ──────────────────────────────
          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.refresh(_adminDashProvider.future),
            child: dashAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(child: Text('$e')),
              data: (data) {
                final users    = data['users']    as Map<String, dynamic>;
                final products = data['products'] as Map<String, dynamic>;
                final orders   = data['orders']   as Map<String, dynamic>;
                final revenue  = data['revenue']  as Map<String, dynamic>;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Revenue card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A237E), Color(0xFF283593)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 20)],
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Platform Revenue', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(AppFormatters.currency(AppFormatters.parseDouble(revenue['total_revenue'])),
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 30)),
                        const SizedBox(height: 12),
                        Row(children: [
                          _RevBadge('Today', AppFormatters.currency(AppFormatters.parseDouble(revenue['today_revenue']))),
                          const SizedBox(width: 12),
                          _RevBadge('This Week', AppFormatters.currency(AppFormatters.parseDouble(revenue['week_revenue']))),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // Stats grid
                    Text('Platform Stats', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2, childAspectRatio: 1.5, crossAxisSpacing: 12, mainAxisSpacing: 12,
                      children: [
                        _AdminStatCard('Total Users',    '${users['total'] ?? 0}',    Icons.people_outline_rounded, Colors.blue),
                        _AdminStatCard('Buyers',         '${users['buyers'] ?? 0}',   Icons.shopping_bag_outlined, Colors.green),
                        _AdminStatCard('Sellers',        '${users['sellers'] ?? 0}',  Icons.storefront_outlined, Colors.orange),
                        _AdminStatCard('New This Week',  '${users['new_this_week'] ?? 0}', Icons.person_add_outlined, Colors.purple),
                        _AdminStatCard('Total Orders',   '${orders['total'] ?? 0}',   Icons.receipt_long_outlined, Colors.teal),
                        _AdminStatCard('Today\'s Orders','${orders['today'] ?? 0}',   Icons.today_outlined, Colors.red),
                        _AdminStatCard('Active Products','${products['active'] ?? 0}', Icons.inventory_outlined, Colors.indigo),
                        _AdminStatCard('Pending Review', '${products['pending_moderation'] ?? 0}', Icons.pending_outlined, Colors.amber),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),

          // ── MODERATION TAB ────────────────────────────
          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.refresh(_pendingProductsProvider.future),
            child: pendingAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(child: Text('$e')),
              data: (products) {
                if (products.isEmpty) {
                  return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 64, color: AppColors.success),
                    const SizedBox(height: 12),
                    Text('All clear!', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                    Text('No products pending review', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                  ]));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _ModerationCard(
                    product: products[i],
                    onDecision: (bool approve) async {
                      try {
                        await ref.read(dioProvider).patch(
                          ApiEndpoints.moderateProduct(products[i]['id'] as String),
                          data: {'approve': approve},
                        );
                        ref.invalidate(_pendingProductsProvider);
                        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                          content: Text(approve ? 'Product approved ✓' : 'Product rejected'),
                          backgroundColor: approve ? AppColors.success : AppColors.error,
                        ));
                      } catch (e) {
                        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
                      }
                    },
                  ),
                );
              },
            ),
          ),

          // ── FRAUD TAB ─────────────────────────────────
          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.refresh(_adminFraudProvider.future),
            child: fraudAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(child: Text('$e')),
              data: (data) {
                final highCancel  = List<Map<String, dynamic>>.from(data['highCancellationSellers'] as List? ?? []);
                final reviewVel   = List<Map<String, dynamic>>.from(data['reviewVelocityAnomalies']  as List? ?? []);
                final suspNew     = List<Map<String, dynamic>>.from(data['suspiciousNewAccounts']    as List? ?? []);
                final allClear    = highCancel.isEmpty && reviewVel.isEmpty && suspNew.isEmpty;

                if (allClear) {
                  return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.security_rounded, size: 64, color: AppColors.success),
                    const SizedBox(height: 12),
                    Text('No fraud signals detected', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                    Text('Platform looks healthy', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                  ]));
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (highCancel.isNotEmpty) ...[
                      _FraudSection(
                        title: '⚠️ High Cancellation Sellers',
                        color: AppColors.warning,
                        items: highCancel,
                        subtitle: (item) => '${item['cancel_rate']}% cancellation rate (${item['total_orders']} orders)',
                        onBan: (item) => _banUser(ctx: context, ref: ref, userId: item['id'] as String, name: item['name'] as String),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (reviewVel.isNotEmpty) ...[
                      _FraudSection(
                        title: '🔍 Review Velocity Anomaly',
                        color: AppColors.error,
                        items: reviewVel,
                        subtitle: (item) => '${item['reviews_today']} reviews in 24 hours',
                        onBan: (item) => _banUser(ctx: context, ref: ref, userId: item['id'] as String, name: item['name'] as String),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (suspNew.isNotEmpty)
                      _FraudSection(
                        title: '🚨 Suspicious New Accounts',
                        color: AppColors.error,
                        items: suspNew,
                        subtitle: (item) => 'Spent ${AppFormatters.currency(AppFormatters.parseDouble(item['total_spent']))} within 3 days',
                        onBan: (item) => _banUser(ctx: context, ref: ref, userId: item['id'] as String, name: item['name'] as String),
                      ),
                  ],
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _banUser({
    required BuildContext ctx, required WidgetRef ref,
    required String userId, required String name,
  }) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text('Ban $name?', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('This will suspend the account immediately.', style: GoogleFonts.poppins()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Ban Account'),
          ),
        ],
      ),
    );
    if (confirmed == true && ctx.mounted) {
      try {
        await ref.read(dioProvider).patch(ApiEndpoints.banUser(userId), data: {'reason': 'Fraud signal detected'});
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text('$name has been banned'), backgroundColor: AppColors.error));
          ref.invalidate(_adminFraudProvider);
        }
      } catch (e) {
        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }
}

class _RevBadge extends StatelessWidget {
  final String label, value;
  const _RevBadge(this.label, this.value);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10)),
      Text(value, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
    ]),
  );
}

class _AdminStatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _AdminStatCard(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border, width: 0.5)),
    child: Row(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 18, color: color)),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
    ]),
  );
}

class _ModerationCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final Future<void> Function(bool) onDecision;
  const _ModerationCard({required this.product, required this.onDecision});
  @override
  State<_ModerationCard> createState() => _ModerationCardState();
}

class _ModerationCardState extends State<_ModerationCard> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(p['name'] as String, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
        Text('by ${p['seller_name']} (${p['seller_email']})',
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
        Text('${p['category_name']} • ₹${p['price']} • Qty: ${p['quantity']}',
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textHint)),
        if (p['description'] != null && (p['description'] as String).isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(p['description'] as String, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: _loading ? null : () async {
              setState(() => _loading = true);
              await widget.onDecision(false);
              setState(() => _loading = false);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Reject', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          )),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            onPressed: _loading ? null : () async {
              setState(() => _loading = true);
              await widget.onDecision(true);
              setState(() => _loading = false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: _loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Approve', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
          )),
        ]),
      ]),
    );
  }
}

class _FraudSection extends StatelessWidget {
  final String title;
  final Color color;
  final List<Map<String, dynamic>> items;
  final String Function(Map<String, dynamic>) subtitle;
  final Future<void> Function(Map<String, dynamic>) onBan;
  const _FraudSection({required this.title, required this.color, required this.items, required this.subtitle, required this.onBan});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
    const SizedBox(height: 10),
    ...items.map((item) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25))),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item['name'] as String, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          Text(item['email'] as String, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
          Text(subtitle(item), style: GoogleFonts.poppins(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ])),
        TextButton(
          onPressed: () => onBan(item),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: Text('Ban', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        ),
      ]),
    )),
  ]);
}
