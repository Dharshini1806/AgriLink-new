import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/formatters.dart';

final _analyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.watch(dioProvider).get(ApiEndpoints.sellerAnalytics);
  return res.data as Map<String, dynamic>;
});

class SellerAnalyticsScreen extends ConsumerWidget {
  const SellerAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_analyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_analyticsProvider),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text('$e', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => ref.invalidate(_analyticsProvider), child: const Text('Retry')),
        ])),
        data: (data) {
          final earnings   = data['earnings'] as Map<String, dynamic>;
          final orders     = data['orders']   as Map<String, dynamic>;
          final topProds   = List<Map<String, dynamic>>.from(data['topProducts'] as List? ?? []);

          final totalEarnings = AppFormatters.parseDouble(earnings['total_earnings']);
          final weekEarnings  = AppFormatters.parseDouble(earnings['week_earnings']);
          final monthEarnings = AppFormatters.parseDouble(earnings['month_earnings']);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Earnings cards
              Row(children: [
                Expanded(child: _EarningsCard('Total', totalEarnings, Icons.account_balance_wallet_outlined, AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(child: _EarningsCard('This Month', monthEarnings, Icons.calendar_month_outlined, const Color(0xFF7B1FA2))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _EarningsCard('This Week', weekEarnings, Icons.date_range_outlined, const Color(0xFF0277BD))),
                const SizedBox(width: 12),
                Expanded(child: _EarningsCard('Delivered', (orders['delivered'] as int?)?.toDouble() ?? 0,
                  Icons.check_circle_outline_rounded, AppColors.success, isCurrency: false, suffix: ' orders')),
              ]),
              const SizedBox(height: 24),

              // Order pie chart
              Text('Order Breakdown', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 0.5)),
                child: Row(children: [
                  Expanded(
                    child: PieChart(PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 36,
                      sections: [
                        _pieSection('Delivered', (orders['delivered'] as int?)?.toDouble() ?? 0, AppColors.success),
                        _pieSection('Pending',   (orders['pending']   as int?)?.toDouble() ?? 0, AppColors.statusPending),
                        _pieSection('Cancelled', (orders['cancelled'] as int?)?.toDouble() ?? 0, AppColors.error),
                      ].where((s) => s.value > 0).toList(),
                    )),
                  ),
                  const SizedBox(width: 16),
                  Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _Legend('Delivered', AppColors.success,  '${orders['delivered'] ?? 0}'),
                    const SizedBox(height: 8),
                    _Legend('Pending',   AppColors.statusPending, '${orders['pending'] ?? 0}'),
                    const SizedBox(height: 8),
                    _Legend('Cancelled', AppColors.error,    '${orders['cancelled'] ?? 0}'),
                    const SizedBox(height: 8),
                    _Legend('Total',     AppColors.textSecondary, '${orders['total'] ?? 0}'),
                  ]),
                ]),
              ),

              // Top products
              if (topProds.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Top Products', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 0.5)),
                  child: Column(children: topProds.asMap().entries.map((e) {
                    final p = e.value;
                    final maxOrders = (topProds.first['times_ordered'] as int? ?? 1).toDouble();
                    final pctOrders = ((p['times_ordered'] as int? ?? 0) / maxOrders);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12), shape: BoxShape.circle),
                            child: Center(child: Text('${e.key + 1}',
                              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(p['name'] as String,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13))),
                          Text('${p['times_ordered']} orders',
                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                        ]),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pctOrders,
                            backgroundColor: AppColors.surfaceVariant,
                            color: AppColors.primary,
                            minHeight: 6,
                          ),
                        ),
                      ]),
                    );
                  }).toList()),
                ),
              ],

              const SizedBox(height: 24),

              // Performance tip
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.secondary.withOpacity(0.25)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('💡', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Boost your sales', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      'Add high-quality photos, keep stock updated, and respond to buyer chats quickly to improve your trust score.',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                    ),
                  ])),
                ]),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  PieChartSectionData _pieSection(String title, double value, Color color) =>
    PieChartSectionData(
      value: value, color: color, radius: 50,
      title: value > 0 ? value.toInt().toString() : '',
      titleStyle: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
    );
}

class _EarningsCard extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final bool isCurrency;
  final String? suffix;
  const _EarningsCard(this.label, this.value, this.icon, this.color,
    {this.isCurrency = true, this.suffix});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border, width: 0.5)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 8),
      Text(
        isCurrency ? AppFormatters.currency(value) : '${value.toInt()}${suffix ?? ''}',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 18, color: color),
      ),
      Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
    ]),
  );
}

class _Legend extends StatelessWidget {
  final String label;
  final Color color;
  final String value;
  const _Legend(this.label, this.color, this.value);

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 6),
    Text('$label: $value', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
  ]);
}
