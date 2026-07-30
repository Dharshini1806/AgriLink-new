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
  });

  Color get _gradeColor {
    switch (product['quality_grade']) {
      case 'A': return AppColors.gradeA;
      case 'B': return AppColors.gradeB;
      case 'C': return AppColors.gradeC;
      default: return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrls = (product['image_urls'] as List?)?.cast<String>() ?? [];
    final imageUrl  = imageUrls.isNotEmpty ? imageUrls.first : null;
    final price     = AppFormatters.parseDouble(product['price']);
    final rating    = AppFormatters.parseDouble(product['avg_rating']);
    final reviews   = product['review_count'] as int? ?? 0;
    final distKm    = product['distance_km'] != null ? AppFormatters.parseDouble(product['distance_km']) : null;
    final grade     = product['quality_grade'] as String?;

    final String pId = product['id'] as String? ?? '';
    final wishlistState = ref.watch(wishlistProvider);
    final activeWishlisted = isWishlisted ?? wishlistState.ids.contains(pId);
    final activeWishlistToggle = onWishlistToggle ?? () => ref.read(wishlistProvider.notifier).toggle(product);

    return GestureDetector(
      onTap: () => context.push('/product/$pId'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 0.5,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Stack(children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: '$imageUrl?f_auto,q_auto,w_400',
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppColors.surfaceVariant,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 1.5))),
                      errorWidget: (_, __, ___) => Container(color: AppColors.surfaceVariant,
                        child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textHint)),
                    )
                  : Container(color: AppColors.surfaceVariant,
                      child: const Center(child: Icon(Icons.agriculture_rounded, color: AppColors.textHint, size: 40))),
              ),
              // Grade badge
              if (grade != null) Positioned(
                top: 8, left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _gradeColor, borderRadius: BorderRadius.circular(20)),
                  child: Text('Grade $grade', style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ),
              // Wishlist & Compare
              Positioned(top: 6, right: 6,
                child: Column(children: [
                  _ActionBtn(
                    icon: activeWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: activeWishlisted ? Colors.red : Colors.white,
                    onTap: activeWishlistToggle,
                  ),
                  if (showCompareToggle && onCompareToggle != null) ...[
                    const SizedBox(height: 4),
                    _ActionBtn(
                      icon: isSelected ? Icons.compare_arrows_rounded : Icons.add_chart_rounded,
                      color: isSelected ? AppColors.primary : Colors.white,
                      onTap: onCompareToggle!,
                    ),
                  ],
                ]),
              ),
            ]),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product['name'] as String? ?? 'Produce',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              if (showSellerInfo)
                Text(product['seller_name'] as String? ?? '',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                  child: Text(AppFormatters.currency(price),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primary)),
                ),
                if (showDistance && distKm != null)
                  Text(AppFormatters.distance(distKm),
                    style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textHint)),
              ]),
              if (rating > 0 || reviews > 0) ...[
                const SizedBox(height: 4),
                Row(children: [
                  RatingBarIndicator(
                    rating: rating,
                    itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: Colors.amber),
                    itemCount: 5, itemSize: 12, unratedColor: AppColors.border,
                  ),
                  const SizedBox(width: 4),
                  Text('($reviews)', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textHint)),
                ]),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30, height: 30,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 16),
    ),
  );
}
