import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/products_provider.dart';

class TopSellersScreen extends ConsumerWidget {
  const TopSellersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellersAsync = ref.watch(topSellerDetailsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Premium gradient header ────────────────────────────────────
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2D5016), Color(0xFF4A7C28), Color(0xFFFFB800)],
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
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Text('🏆', style: TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: 14),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(
                              'Top Farmers',
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Ranked by buyer ratings',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ]),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────
          sellersAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.secondary)),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  Text('Could not load top farmers',
                    style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => ref.invalidate(topSellerDetailsProvider),
                    child: const Text('Retry'),
                  ),
                ]),
              ),
            ),
            data: (sellers) {
              if (sellers.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('🌾', style: TextStyle(fontSize: 56)),
                      const SizedBox(height: 12),
                      Text('No farmers yet',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                    ]),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _FarmerDetailCard(seller: sellers[i], rank: i + 1),
                    childCount: sellers.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Farmer expandable card ────────────────────────────────────────────────────
class _FarmerDetailCard extends StatefulWidget {
  final Map<String, dynamic> seller;
  final int rank;
  const _FarmerDetailCard({required this.seller, required this.rank});

  @override
  State<_FarmerDetailCard> createState() => _FarmerDetailCardState();
}

class _FarmerDetailCardState extends State<_FarmerDetailCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _ctrl;
  late final Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _rotate = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    // Auto-expand top 3
    if (widget.rank <= 3) {
      _expanded = true;
      _ctrl.value = 0.5;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _rankColor {
    switch (widget.rank) {
      case 1: return const Color(0xFFFFB800);
      case 2: return const Color(0xFFB0B8C4);
      case 3: return const Color(0xFFCD7F32);
      default: return AppColors.secondary;
    }
  }

  String get _rankEmoji {
    switch (widget.rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '#${widget.rank}';
    }
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final s           = widget.seller;
    final name        = s['farm_name'] as String? ?? s['name'] as String? ?? 'Farm';
    final sellerName  = s['name'] as String? ?? '';
    final farmDesc    = s['farm_desc'] as String? ?? '';
    final avgRating   = _toDouble(s['avg_rating']);
    final reviewCount = _toInt(s['review_count']);
    final profileImg  = s['profile_img'] as String?;
    final products    = (s['products'] as List?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: widget.rank <= 3 ? _rankColor.withOpacity(0.3) : AppColors.border,
          width: widget.rank <= 3 ? 1.5 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: (widget.rank <= 3 ? _rankColor : AppColors.primary).withOpacity(0.08),
            blurRadius: widget.rank <= 3 ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: [
        // ── Header row ─────────────────────────────────────────────
        InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              // Rank badge
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_rankColor, _rankColor.withOpacity(0.7)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _rankColor.withOpacity(0.4), blurRadius: 8)],
                ),
                child: Center(
                  child: Text(
                    widget.rank <= 3 ? _rankEmoji : '${widget.rank}',
                    style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: widget.rank <= 3 ? 18 : 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Avatar
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _rankColor.withOpacity(0.4), width: 2),
                ),
                child: ClipOval(
                  child: profileImg != null
                      ? CachedNetworkImage(imageUrl: profileImg, fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _initials(sellerName, _rankColor))
                      : _initials(sellerName, _rankColor),
                ),
              ),
              const SizedBox(width: 12),

              // Name + rating
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                  ),
                  Text(
                    sellerName,
                    style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint),
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    RatingBarIndicator(
                      rating: avgRating,
                      itemBuilder: (_, __) =>
                          const Icon(Icons.star_rounded, color: Color(0xFFFFB800)),
                      itemCount: 5,
                      itemSize: 14,
                      unratedColor: AppColors.border,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      avgRating > 0
                          ? '${avgRating.toStringAsFixed(1)} ($reviewCount reviews)'
                          : 'No reviews yet',
                      style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textHint),
                    ),
                  ]),
                ]),
              ),

              // Product count chip
              Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${products.length} products',
                    style: GoogleFonts.poppins(
                      fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.secondary),
                  ),
                ),
                const SizedBox(height: 6),
                RotationTransition(
                  turns: _rotate,
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textHint, size: 20),
                ),
              ]),
            ]),
          ),
        ),

        // Farm desc
        if (farmDesc.isNotEmpty && _expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              farmDesc,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary, height: 1.5),
            ),
          ),

        // ── Product list (expanded) ─────────────────────────────────
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 280),
          crossFadeState: _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: products.isEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text('No products listed yet.',
                    style: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 12)),
                )
              : Column(
                  children: [
                    // Section label
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Row(children: [
                        Container(
                          width: 3, height: 14,
                          decoration: BoxDecoration(
                            color: _rankColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Products by Selling %',
                          style: GoogleFonts.poppins(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary),
                        ),
                      ]),
                    ),
                    ...products.asMap().entries.map((entry) {
                      final i = entry.key;
                      final p = entry.value as Map<String, dynamic>;
                      return _ProductSellRow(
                        product: p,
                        rank: i + 1,
                        accentColor: _rankColor,
                        isLast: i == products.length - 1,
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                ),
          secondChild: const SizedBox.shrink(),
        ),
      ]),
    );
  }

  Widget _initials(String name, Color color) => Container(
    color: color.withOpacity(0.15),
    child: Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: GoogleFonts.poppins(
          color: color, fontSize: 18, fontWeight: FontWeight.w800),
      ),
    ),
  );
}

// ── Individual product row with sell% bar ─────────────────────────────────────
class _ProductSellRow extends StatelessWidget {
  final Map<String, dynamic> product;
  final int rank;
  final Color accentColor;
  final bool isLast;

  const _ProductSellRow({
    required this.product,
    required this.rank,
    required this.accentColor,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final name       = product['name'] as String? ?? '';
    final price      = AppFormatters.parseDouble(product['price']);
    final sellPct    = _toDouble(product['sell_pct']);
    final qtySold    = _toInt(product['qty_sold']);
    final grade      = product['quality_grade'] as String?;
    final imageUrls  = (product['image_urls'] as List?)?.cast<String>() ?? [];
    final imageUrl   = imageUrls.isNotEmpty ? imageUrls.first : null;
    final productId  = product['id'] as String? ?? '';

    Color gradeColor = AppColors.textHint;
    if (grade == 'A') gradeColor = AppColors.gradeA;
    else if (grade == 'B') gradeColor = AppColors.gradeB;
    else if (grade == 'C') gradeColor = AppColors.gradeC;

    return GestureDetector(
      onTap: () => context.push('/product/$productId'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          border: isLast ? null : Border(
            bottom: BorderSide(color: AppColors.border, width: 0.6),
          ),
        ),
        child: Row(children: [
          // Rank number
          SizedBox(
            width: 22,
            child: Text(
              '$rank',
              style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w800,
                color: rank == 1 ? accentColor : AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),

          // Product thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 48, height: 48,
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: '$imageUrl?f_auto,q_auto,w_100',
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppColors.surfaceVariant),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.eco_outlined, color: AppColors.textHint, size: 20),
                      ),
                    )
                  : Container(
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.eco_outlined, color: AppColors.textHint, size: 20),
                    ),
            ),
          ),
          const SizedBox(width: 10),

          // Name + sell% bar
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, fontSize: 12,
                      color: AppColors.textPrimary),
                  ),
                ),
                if (grade != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: gradeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Grade $grade',
                      style: GoogleFonts.poppins(
                        fontSize: 8, fontWeight: FontWeight.w700, color: gradeColor),
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: 4),
              // Sell % progress bar
              Row(children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: math.min(sellPct / 100.0, 1.0),
                      minHeight: 4,
                      backgroundColor: accentColor.withOpacity(0.10),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        sellPct > 50 ? accentColor : AppColors.secondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${sellPct.toStringAsFixed(1)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 10, fontWeight: FontWeight.w800,
                    color: sellPct > 0 ? accentColor : AppColors.textHint,
                  ),
                ),
              ]),
              const SizedBox(height: 2),
              Row(children: [
                Text(
                  AppFormatters.currency(price),
                  style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondary),
                ),
                const SizedBox(width: 8),
                if (qtySold > 0)
                  Text(
                    '$qtySold sold',
                    style: GoogleFonts.poppins(fontSize: 9, color: AppColors.textHint),
                  ),
              ]),
            ]),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 16),
        ]),
      ),
    );
  }
}

// ── Safe numeric parsers (API may return num fields as Strings) ───────────────
double _toDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString()) ?? 0.0;
}

int _toInt(dynamic val) {
  if (val == null) return 0;
  if (val is int) return val;
  if (val is num) return val.toInt();
  return int.tryParse(val.toString()) ?? 0;
}
