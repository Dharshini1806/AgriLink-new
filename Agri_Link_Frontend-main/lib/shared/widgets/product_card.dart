import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/products/presentation/providers/products_provider.dart';

class ProductCard extends ConsumerWidget {
  final dynamic product;
  final bool showDistance;
  final bool showSellerInfo;
  final bool showCompareToggle;
  final bool isSelected;
  final VoidCallback? onCompareToggle;
  final VoidCallback? onWishlistToggle;
  final bool? isWishlisted;
  final bool isTopSeller;
  final bool showSellPct;

  const ProductCard({
    super.key,
    required this.product,
    this.showDistance = true,
    this.showSellerInfo = true,
    this.showCompareToggle = false,
    this.isSelected = false,
    this.onCompareToggle,
    this.onWishlistToggle,
    this.isWishlisted,
    this.isTopSeller = false,
    this.showSellPct = true,
  });

  Color get _gradeColor {
    switch (product['quality_grade']) {
      case 'A': return AppColors.gradeA;
      case 'B': return AppColors.gradeB;
      case 'C': return AppColors.gradeC;
      default: return AppColors.textHint;
    }
  }

  String get _gradeEmoji {
    switch (product['quality_grade']) {
      case 'A': return '★';
      case 'B': return '◆';
      case 'C': return '●';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrls = (product['image_urls'] as List?)?.cast<String>() ?? [];
    final imageUrl  = imageUrls.isNotEmpty ? imageUrls.first : null;
    final price     = AppFormatters.parseDouble(product['price']);
    final rating    = AppFormatters.parseDouble(product['avg_rating']);
    final reviews   = product['review_count'] as int? ?? 0;
    final distKm    = product['distance_km'] != null
        ? AppFormatters.parseDouble(product['distance_km'])
        : null;
    final grade     = product['quality_grade'] as String?;

    final String pId = product['id'] as String? ?? '';
    final wishlistState = ref.watch(wishlistProvider);
    final activeWishlisted = isWishlisted ?? wishlistState.ids.contains(pId);
    final activeWishlistToggle =
        onWishlistToggle ?? () => ref.read(wishlistProvider.notifier).toggle(product);

    return GestureDetector(
      onTap: () => context.push('/product/$pId'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.border,
            width: isSelected ? 2 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: (isSelected ? AppColors.secondary : AppColors.primary).withOpacity(0.08),
              blurRadius: isSelected ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Image ────────────────────────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            child: Stack(children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: '$imageUrl?f_auto,q_auto,w_400',
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.surfaceVariant,
                          child: const Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 1.5, color: AppColors.secondary),
                          ),
                        ),
                        errorWidget: (_, __, ___) => _NoImagePlaceholder(),
                      )
                    : _NoImagePlaceholder(),
              ),
              // Gradient overlay at bottom of image
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.35), Colors.transparent],
                    ),
                  ),
                ),
              ),
              // Grade badge
              if (grade != null)
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _gradeColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: _gradeColor.withOpacity(0.4), blurRadius: 6)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _gradeEmoji,
                          style: const TextStyle(color: Colors.white, fontSize: 8),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Grade $grade',
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              // Wishlist & Compare
              Positioned(
                top: 6, right: 6,
                child: Column(children: [
                  _GlassActionBtn(
                    icon: activeWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: activeWishlisted ? const Color(0xFFE55252) : Colors.white,
                    onTap: activeWishlistToggle,
                  ),
                  if (showCompareToggle && onCompareToggle != null) ...[
                    const SizedBox(height: 4),
                    _GlassActionBtn(
                      icon: isSelected ? Icons.compare_arrows_rounded : Icons.add_chart_rounded,
                      color: isSelected ? AppColors.secondary : Colors.white,
                      onTap: onCompareToggle!,
                    ),
                  ],
                ]),
              ),
              // 🔥 Hot Seller badge
              if (isTopSeller)
                Positioned(
                  bottom: 6, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B00), Color(0xFFFFB800)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Color(0x66FF6B00), blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Text('🔥', style: TextStyle(fontSize: 8)),
                      const SizedBox(width: 3),
                      Text(
                        'Hot Seller',
                        style: GoogleFonts.poppins(
                          color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800,
                        ),
                      ),
                    ]),
                  ),
                ),
            ]),
          ),
          // ── Info ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                product['name'] as String? ?? 'Produce',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
              ),
              if (showSellerInfo) ...[
                const SizedBox(height: 1),
                Row(children: [
                  const Icon(Icons.storefront_outlined, size: 11, color: AppColors.textHint),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      product['seller_name'] as String? ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textHint),
                    ),
                  ),
                ]),
              ],
              const SizedBox(height: 5),
              Row(children: [
                Expanded(
                  child: Text(
                    AppFormatters.currency(price),
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.secondary),
                  ),
                ),
                if (showDistance && distKm != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppFormatters.distance(distKm),
                      style: GoogleFonts.poppins(fontSize: 9, color: AppColors.textHint, fontWeight: FontWeight.w500),
                    ),
                  ),
              ]),
              if (rating > 0 || reviews > 0) ...[
                const SizedBox(height: 4),
                Row(children: [
                  RatingBarIndicator(
                    rating: rating,
                    itemBuilder: (_, __) =>
                        const Icon(Icons.star_rounded, color: AppColors.secondary),
                    itemCount: 5,
                    itemSize: 11,
                    unratedColor: AppColors.border,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '($reviews)',
                    style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textHint),
                  ),
                ]),
              ],
              // ── Selling percentage badge ──────────────────────────────
              if (showSellPct) _SellPctBar(product: product),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _NoImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.surfaceVariant,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.eco_outlined, color: AppColors.border, size: 32),
            const SizedBox(height: 4),
            Text('No image', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textHint)),
          ]),
        ),
      );
}

class _GlassActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _GlassActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.22),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 0.8),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      );
}

// ── Selling percentage progress bar ──────────────────────────────────────────
/// Shows what percentage of a seller's total sales this product accounts for.
/// Hidden automatically when sell_pct == 0 (new products / no order history).
class _SellPctBar extends StatelessWidget {
  final dynamic product;
  const _SellPctBar({required this.product});

  double get _pct {
    final raw = product['sell_pct'];
    if (raw == null) return 0.0;
    if (raw is num) return raw.toDouble().clamp(0.0, 100.0);
    return double.tryParse(raw.toString())?.clamp(0.0, 100.0) ?? 0.0;
  }

  Color _barColor(double pct) {
    if (pct >= 50) return const Color(0xFF2E7D32);
    if (pct >= 25) return const Color(0xFF558B2F);
    return const Color(0xFF7B9E3C);
  }

  @override
  Widget build(BuildContext context) {
    final pct = _pct;
    if (pct <= 0) return const SizedBox.shrink();

    final color = _barColor(pct);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('📈', style: TextStyle(fontSize: 9)),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                '${pct.toStringAsFixed(1)}% of seller\'s sales',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: pct / 100),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 4,
                backgroundColor: AppColors.border.withOpacity(0.4),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

