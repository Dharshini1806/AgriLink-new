import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

final sellerAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.watch(dioProvider).get(ApiEndpoints.sellerAnalytics);
  return res.data as Map<String, dynamic>;
});

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user       = ref.watch(authStateProvider).value?.user;
    final analytics  = ref.watch(sellerAnalyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Dashboard', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
          Text('Welcome back, ${user?.name.split(' ').first ?? 'Farmer'}!',
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Add Product', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        onPressed: () => context.push('/seller/add-product'),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.refresh(sellerAnalyticsProvider.future),
        child: analytics.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(child: Text('$e')),
          data: (data) {
            final earnings = data['earnings'] as Map<String, dynamic>;
            final orders   = data['orders'] as Map<String, dynamic>;
            final topProds = List<Map<String, dynamic>>.from(data['topProducts'] as List? ?? []);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Earnings card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Total Earnings', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(AppFormatters.currency(
                      AppFormatters.parseDouble(earnings['total_earnings'])),
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 32)),
                    const SizedBox(height: 16),
                    Row(children: [
                      _EarningBadge(label: 'This Week',
                        value: AppFormatters.currency(AppFormatters.parseDouble(earnings['week_earnings']))),
                      const SizedBox(width: 12),
                      _EarningBadge(label: 'This Month',
                        value: AppFormatters.currency(AppFormatters.parseDouble(earnings['month_earnings']))),
                    ]),
                  ]),
                ),
                const SizedBox(height: 20),

                // Order stats
                Text('Orders', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _StatCard('Pending',   '${orders['pending'] ?? 0}', Icons.hourglass_top_rounded, AppColors.warning)),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard('Delivered', '${orders['delivered'] ?? 0}', Icons.check_circle_outlined, AppColors.success)),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard('Cancelled', '${orders['cancelled'] ?? 0}', Icons.cancel_outlined, AppColors.error)),
                ]),

                const SizedBox(height: 20),

                // Quick actions
                Text('Quick Actions', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _ActionCard(
                    icon: Icons.inventory_2_outlined, label: 'My Products', color: AppColors.primary,
                    onTap: () => context.go('/seller/products'),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _ActionCard(
                    icon: Icons.receipt_long_outlined, label: 'Orders', color: const Color(0xFF5E35B1),
                    onTap: () => context.go('/seller/orders'),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _ActionCard(
                    icon: Icons.bar_chart_rounded, label: 'Analytics', color: const Color(0xFF0277BD),
                    onTap: () => context.go('/seller/analytics'),
                  )),
                ]),

                // Top products
                if (topProds.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Top Selling Products', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 12),
                  ...topProds.map((p) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p['name'] as String, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('${p['times_ordered']} orders • ${AppFormatters.currency(AppFormatters.parseDouble(p['price']))}',
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                      ])),
                      Text('⭐ ${p['avg_rating'] != null ? AppFormatters.parseDouble(p['avg_rating']).toStringAsFixed(1) : '—'}',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    ]),
                  )),
                ],
                const SizedBox(height: 80),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EarningBadge extends StatelessWidget {
  final String label, value;
  const _EarningBadge({required this.label, required this.value});

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

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border, width: 0.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 6),
      Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 20, color: color)),
      Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
    ]),
  );
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]),
    ),
  );
}
