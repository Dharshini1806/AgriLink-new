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
    final user      = ref.watch(authStateProvider).value?.user;
    final analytics = ref.watch(sellerAnalyticsProvider);
    final firstName = user?.name.split(' ').first ?? 'Farmer';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Gradient header ────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppColors.primary,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.secondary, AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Good day! 🌾',
                              style: GoogleFonts.poppins(
                                  color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                            Text(firstName,
                              style: GoogleFonts.playfairDisplay(
                                  color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                          ]),
                          const Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.notifications_outlined,
                                  color: Colors.white, size: 22),
                              onPressed: () {},
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: const [SizedBox.shrink()],
          ),

          // ── Body content ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: analytics.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.secondary),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 48, color: AppColors.textHint),
                    const SizedBox(height: 12),
                    Text('$e', textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref.refresh(sellerAnalyticsProvider),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ]),
                ),
              ),
              data: (data) {
                final earnings = data['earnings'] as Map<String, dynamic>;
                final orders   = data['orders'] as Map<String, dynamic>;
                final topProds = List<Map<String, dynamic>>.from(
                    data['topProducts'] as List? ?? []);

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // ── Earnings card ────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.secondary, AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(children: [
                        // Decorative circles
                        Positioned(
                          top: -20, right: -10,
                          child: Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.06),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -30, right: 40,
                          child: Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                        ),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.account_balance_wallet_rounded,
                                  color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Text('Total Earnings',
                              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                          ]),
                          const SizedBox(height: 10),
                          _AnimatedCurrencyCounter(
                            value: AppFormatters.parseDouble(earnings['total_earnings']),
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 34,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(children: [
                            Expanded(child: _EarningBadge(
                              label: 'This Week',
                              value: AppFormatters.currency(
                                  AppFormatters.parseDouble(earnings['week_earnings'])),
                              icon: Icons.today_rounded,
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: _EarningBadge(
                              label: 'This Month',
                              value: AppFormatters.currency(
                                  AppFormatters.parseDouble(earnings['month_earnings'])),
                              icon: Icons.calendar_month_rounded,
                            )),
                          ]),
                        ]),
                      ]),
                    ),

                    const SizedBox(height: 24),

                    // ── Order stats ──────────────────────────────────────
                    _SectionHeader(title: 'Orders Overview'),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _StatCard(
                        label: 'Pending',
                        value: '${orders['pending'] ?? 0}',
                        icon: Icons.hourglass_top_rounded,
                        color: AppColors.warning,
                        onTap: () => context.go('/seller/orders?status=pending'),
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _StatCard(
                        label: 'Delivered',
                        value: '${orders['delivered'] ?? 0}',
                        icon: Icons.check_circle_rounded,
                        color: AppColors.success,
                        onTap: () => context.go('/seller/orders?status=delivered'),
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _StatCard(
                        label: 'Cancelled',
                        value: '${orders['cancelled'] ?? 0}',
                        icon: Icons.cancel_rounded,
                        color: AppColors.error,
                        onTap: () => context.go('/seller/orders?status=cancelled'),
                      )),
                    ]),

                    const SizedBox(height: 24),

                    // ── Quick actions ─────────────────────────────────────
                    _SectionHeader(title: 'Quick Actions'),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _ActionCard(
                        icon: Icons.inventory_2_rounded, label: 'Products',
                        emoji: '📦',
                        gradientColors: [const Color(0xFF6B9E3F), AppColors.accent],
                        onTap: () => context.go('/seller/products'),
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _ActionCard(
                        icon: Icons.receipt_long_rounded, label: 'Orders',
                        emoji: '🧾',
                        gradientColors: [const Color(0xFF7B5EA7), const Color(0xFF5E35B1)],
                        onTap: () => context.go('/seller/orders'),
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _ActionCard(
                        icon: Icons.bar_chart_rounded, label: 'Analytics',
                        emoji: '📊',
                        gradientColors: [const Color(0xFF2E6B9E), const Color(0xFF0277BD)],
                        onTap: () => context.go('/seller/analytics'),
                      )),
                    ]),

                    // ── Add product CTA ──────────────────────────────────
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => context.push('/seller/add-product'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [AppColors.secondary, AppColors.primary]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Add New Product',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700, fontSize: 14,
                                    color: AppColors.textPrimary)),
                              Text('List fresh produce for buyers nearby',
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: AppColors.textSecondary)),
                            ]),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              color: AppColors.primary, size: 14),
                        ]),
                      ),
                    ),

                    // ── Top products ─────────────────────────────────────
                    if (topProds.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _SectionHeader(title: 'Top Selling Products'),
                      const SizedBox(height: 12),
                      ...topProds.asMap().entries.map((entry) {
                        final i = entry.key;
                        final p = entry.value;
                        return _TopProductTile(rank: i + 1, product: p);
                      }),
                    ],
                  ]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 4, height: 18, decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.primary], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      borderRadius: BorderRadius.circular(2),
    )),
    const SizedBox(width: 8),
    Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
  ]);
}

// ── Animated Currency Counter ──────────────────────────────────────────────────
class _AnimatedCurrencyCounter extends StatelessWidget {
  final double value;
  final TextStyle style;
  const _AnimatedCurrencyCounter({required this.value, required this.style});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => Text(AppFormatters.currency(v), style: style),
      );
}

// ── Earning Badge ─────────────────────────────────────────────────────────────
class _EarningBadge extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _EarningBadge({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withOpacity(0.2)),
    ),
    child: Row(children: [
      Icon(icon, color: Colors.white60, size: 14),
      const SizedBox(width: 6),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.poppins(color: Colors.white60, fontSize: 10)),
        Text(value, style: GoogleFonts.poppins(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
      ])),
    ]),
  );
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _StatCard({
    required this.label, required this.value,
    required this.icon, required this.color, this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 10),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: double.tryParse(value) ?? 0),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => Text(
            '${v.toInt()}',
            style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w800, fontSize: 24, color: color),
          ),
        ),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
      ]),
    ),
  );
}

// ── Action Card ───────────────────────────────────────────────────────────────
class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String label, emoji;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon, required this.label, required this.emoji,
    required this.gradientColors, required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _pressed = true),
    onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      transform: Matrix4.identity()..scale(_pressed ? 0.95 : 1.0),
      transformAlignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.gradientColors.first.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: widget.gradientColors.first.withOpacity(0.12),
            blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradientColors,
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(widget.emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
        const SizedBox(height: 8),
        Text(widget.label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ]),
    ),
  );
}

// ── Top Product Tile ──────────────────────────────────────────────────────────
class _TopProductTile extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> product;
  const _TopProductTile({required this.rank, required this.product});

  @override
  Widget build(BuildContext context) {
    final rankColors = [AppColors.secondary, AppColors.textSecondary, AppColors.gradeC];
    final rankColor = rank <= 3 ? rankColors[rank - 1] : AppColors.border;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
      ),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: rankColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800, fontSize: 11, color: rankColor),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product['name'] as String,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.shopping_bag_outlined, size: 11, color: AppColors.textHint),
              const SizedBox(width: 3),
              Text('${product['times_ordered']} orders',
                style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint)),
              const SizedBox(width: 8),
              const Icon(Icons.sell_outlined, size: 11, color: AppColors.textHint),
              const SizedBox(width: 3),
              Text(AppFormatters.currency(AppFormatters.parseDouble(product['price'])),
                style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint)),
            ]),
          ]),
        ),
        if (product['avg_rating'] != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star_rounded, color: AppColors.secondary, size: 12),
              const SizedBox(width: 3),
              Text(
                AppFormatters.parseDouble(product['avg_rating']).toStringAsFixed(1),
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.secondary)),
            ]),
          ),
      ]),
    );
  }
}
