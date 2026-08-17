import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
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

final _adminReviewStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.watch(dioProvider).get(ApiEndpoints.adminReviewsStats);
  return res.data as Map<String, dynamic>;
});

final _adminReviewsListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.watch(dioProvider).get(ApiEndpoints.adminReviews);
  return List<Map<String, dynamic>>.from(res.data['data'] as List? ?? []);
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync    = ref.watch(_adminDashProvider);
    final fraudAsync   = ref.watch(_adminFraudProvider);
    final pendingAsync = ref.watch(_pendingProductsProvider);

    return DefaultTabController(
      length: 4,
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
              Tab(text: 'Reviews'),
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
          
          // ── REVIEWS TAB ────────────────────────────────
          const _AdminReviewsTab(),
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

class _AdminReviewsTab extends ConsumerWidget {
  const _AdminReviewsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(_adminReviewStatsProvider);
    final listAsync = ref.watch(_adminReviewsListProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(_adminReviewStatsProvider);
        ref.invalidate(_adminReviewsListProvider);
      },
      child: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('$e')),
        data: (stats) {
          final summary = stats['summary'] as Map<String, dynamic>;
          final highlyNeg = List<Map<String, dynamic>>.from(stats['highlyNegativeProducts'] as List? ?? []);
          final positiveProds = List<Map<String, dynamic>>.from(stats['consistentlyPositiveProducts'] as List? ?? []);
          
          final posPct = (summary['sentimentSplit']['positive'] as num?)?.toDouble() ?? 0.0;
          final neuPct = (summary['sentimentSplit']['neutral'] as num?)?.toDouble() ?? 0.0;
          final negPct = (summary['sentimentSplit']['negative'] as num?)?.toDouble() ?? 0.0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Global Review Metrics', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _ReviewMetricCol('Total Reviews', '${summary['totalReviews'] ?? 0}'),
                        _ReviewMetricCol('Avg Rating', '${summary['averageRating'] ?? 0.0} ★'),
                      ],
                    ),
                    const Divider(height: 24),
                    Text('Global Sentiment Split', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 8,
                        child: Row(
                          children: [
                            if (posPct > 0) Expanded(flex: posPct.round(), child: Container(color: const Color(0xFF2E7D32))),
                            if (neuPct > 0) Expanded(flex: neuPct.round(), child: Container(color: const Color(0xFFFFA000))),
                            if (negPct > 0) Expanded(flex: negPct.round(), child: Container(color: const Color(0xFFC62828))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _LegendDot('Positive ($posPct%)', const Color(0xFF2E7D32)),
                        _LegendDot('Neutral ($neuPct%)', const Color(0xFFFFA000)),
                        _LegendDot('Negative ($negPct%)', const Color(0xFFC62828)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (highlyNeg.isNotEmpty) ...[
                Text('🚨 Warning: Highly Negative Products', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.error)),
                const SizedBox(height: 8),
                ...highlyNeg.map((p) => _ProductStatusCard(product: p, isNegative: true)),
                const SizedBox(height: 24),
              ],

              if (positiveProds.isNotEmpty) ...[
                Text('🌟 Consistently Positive Products', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.success)),
                const SizedBox(height: 8),
                ...positiveProds.map((p) => _ProductStatusCard(product: p, isNegative: false)),
                const SizedBox(height: 24),
              ],

              Text('Platform Reviews Log', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 10),
              listAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                error: (err, _) => Center(child: Text('Error loading reviews: $err')),
                data: (reviews) => reviews.isEmpty
                  ? Center(child: Text('No reviews submitted yet', style: GoogleFonts.poppins(color: AppColors.textHint)))
                  : Column(
                      children: reviews.map((r) => _AdminReviewTile(
                        review: r,
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('Delete review?', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                              content: Text('Are you sure you want to delete this review? This action cannot be undone.', style: GoogleFonts.poppins()),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await ref.read(dioProvider).delete(ApiEndpoints.deleteAdminReview(r['id'] as String));
                              ref.invalidate(_adminReviewStatsProvider);
                              ref.invalidate(_adminReviewsListProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Review deleted successfully'), backgroundColor: AppColors.error),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to delete review: $e'), backgroundColor: AppColors.error),
                                );
                              }
                            }
                          }
                        },
                      )).toList(),
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReviewMetricCol extends StatelessWidget {
  final String label, value;
  const _ReviewMetricCol(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendDot(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _ProductStatusCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool isNegative;
  const _ProductStatusCard({required this.product, required this.isNegative});

  @override
  Widget build(BuildContext context) {
    final images = (product['image_urls'] as List?)?.cast<String>() ?? [];
    final imgUrl = images.isNotEmpty ? images.first : null;
    final color = isNegative ? AppColors.error : AppColors.success;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
      ),
      child: Row(
        children: [
          if (imgUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: '$imgUrl?f_auto,q_auto,w_80',
                width: 44, height: 44, fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.eco_outlined, size: 20, color: AppColors.textHint),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['name'] as String? ?? 'Product', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                Text(
                  isNegative 
                    ? 'Rating: ${product['avg_rating']} ★ (${product['review_count']} reviews) • ${product['negative_pct']}% Negative sentiment'
                    : 'Rating: ${product['avg_rating']} ★ (${product['review_count']} reviews) • ${product['positive_pct']}% Positive sentiment',
                  style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminReviewTile extends StatelessWidget {
  final Map<String, dynamic> review;
  final VoidCallback onDelete;
  const _AdminReviewTile({required this.review, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final String label = review['sentiment_label'] as String? ?? 'neutral';
    Color bg;
    Color fg;
    switch (label.toLowerCase()) {
      case 'positive':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        break;
      case 'neutral':
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFFF57F17);
        break;
      case 'negative':
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        break;
      default:
        bg = AppColors.surfaceVariant;
        fg = AppColors.textHint;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Buyer: ${review['reviewer_name'] ?? 'User'}', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('Product: ${review['product_name'] ?? 'General Review'}', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textHint)),
                  ],
                ),
              ),
              RatingBarIndicator(
                rating: (review['rating'] as num?)?.toDouble() ?? 0.0,
                itemSize: 12,
                itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: Colors.amber),
                unratedColor: AppColors.border,
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (review['comment'] != null && (review['comment'] as String).isNotEmpty)
            Text(review['comment'] as String, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
                    child: Text(label.toUpperCase(), style: GoogleFonts.poppins(fontSize: 8, color: fg, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 6),
                  if (review['sentiment_score'] != null)
                    Text('Score: ${review['sentiment_score']}', style: GoogleFonts.poppins(fontSize: 9, color: AppColors.textHint, fontWeight: FontWeight.w600)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
