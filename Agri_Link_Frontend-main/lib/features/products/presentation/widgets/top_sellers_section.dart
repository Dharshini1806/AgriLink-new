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

class TopSellersSection extends ConsumerWidget {
  const TopSellersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellersAsync = ref.watch(topSellersProvider);

    return sellersAsync.when(
      loading: () => const _TopSellersShimmer(),
      error: (_, __) => const SizedBox.shrink(),
      data: (sellers) {
        if (sellers.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -- Section Header ------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB800), Color(0xFFFF8C00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x59FFB800),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('🏆', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Text(
                      'Top Farmers',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ]),
                ),
                const SizedBox(width: 8),
                Text(
                  'by buyer ratings',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.push('/top-sellers'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.secondary.withOpacity(0.25)),
                    ),
                    child: Text(
                      'See All →',
                      style: GoogleFonts.poppins(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ),
              ]),
            ),
            // -- Horizontal Farmer Cards ---------------------------------
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                itemCount: sellers.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) => _FarmerCard(
                  seller: sellers[i],
                  rank: i + 1,
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }
}

class _FarmerCard extends StatelessWidget {
  final Map<String, dynamic> seller;
  final int rank;
  const _FarmerCard({required this.seller, required this.rank});

  Color get _rankColor {
    switch (rank) {
      case 1: return const Color(0xFFFFB800);
      case 2: return const Color(0xFFB0B8C4);
      case 3: return const Color(0xFFCD7F32);
      default: return AppColors.secondary;
    }
  }

  String get _rankLabel => '#$rank';

  @override
  Widget build(BuildContext context) {
    final name       = seller['farm_name'] as String? ?? seller['name'] as String? ?? 'Farm';
    final sellerName = seller['name'] as String? ?? '';
    final salesPct   = _toDouble(seller['sales_pct']);
    final profileImg = seller['profile_img'] as String?;
    final topProducts = (seller['top_products'] as List?) ?? [];
    final topProduct  = topProducts.isNotEmpty ? topProducts.first as Map<String, dynamic>? : null;
    final topImgUrl   = topProduct != null
        ? ((topProduct['image_urls'] as List?)?.isNotEmpty == true ? topProduct['image_urls'][0] as String : null)
        : null;
    final sellerId = seller['id'] as String? ?? '';

    return GestureDetector(
      onTap: () => context.push('/farmer/$sellerId'),
      child: Container(
        width: 148,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: rank <= 3 ? _rankColor.withOpacity(0.35) : AppColors.border,
            width: rank <= 3 ? 1.5 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: (rank <= 3 ? _rankColor : AppColors.primary).withOpacity(0.1),
              blurRadius: rank <= 3 ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // -- Top product thumbnail -------------------------------
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            child: Stack(children: [
              SizedBox(
                height: 80, width: double.infinity,
                child: topImgUrl != null
                    ? CachedNetworkImage(
                        imageUrl: '$topImgUrl?f_auto,q_auto,w_300',
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppColors.surfaceVariant),
                        errorWidget:  (_, __, ___) => Container(color: AppColors.surfaceVariant),
                      )
                    : Container(
                        color: AppColors.surfaceVariant,
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '??',
                            style: GoogleFonts.playfairDisplay(fontSize: 28, color: AppColors.textHint),
                          ),
                        ),
                      ),
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 7, left: 7,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: _rankColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: _rankColor.withOpacity(0.5), blurRadius: 6)],
                  ),
                  child: Text(
                    _rankLabel,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ]),
          ),
          // -- Farmer info -----------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [_rankColor, _rankColor.withOpacity(0.6)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                  ),
                  child: profileImg != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: profileImg, fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => _initials(sellerName),
                          ),
                        )
                      : _initials(sellerName),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.textPrimary),
                    ),
                    Text(
                      sellerName, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 9, color: AppColors.textHint),
                    ),
                  ]),
                ),
              ]),
              const SizedBox(height: 8),
              // Sales % bar + top product name
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  RatingBarIndicator(
                    rating: _toDouble(seller['avg_rating']),
                    itemBuilder: (_, __) =>
                        const Icon(Icons.star_rounded, color: Color(0xFFFFB800)),
                    itemCount: 5,
                    itemSize: 11,
                    unratedColor: AppColors.border,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _toDouble(seller['avg_rating']).toStringAsFixed(1),
                    style: GoogleFonts.poppins(
                      fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFFFFB800)),
                  ),
                ]),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: math.min(salesPct / 100.0, 1.0),
                    minHeight: 5,
                    backgroundColor: _rankColor.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(_rankColor),
                  ),
                ),
              ]),
              if (topProduct != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.eco_outlined, size: 10, color: AppColors.textHint),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      topProduct['name'] as String? ?? '',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 9, color: AppColors.textHint),
                    ),
                  ),
                  Text(
                    AppFormatters.currency(AppFormatters.parseDouble(topProduct['price'])),
                    style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.secondary),
                  ),
                ]),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _initials(String name) => Center(
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
    ),
  );
}

/// Safely parses any numeric value (int, double, or String) to double.
double _toDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString()) ?? 0.0;
}

class _TopSellersShimmer extends StatelessWidget {
  const _TopSellersShimmer();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 212,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => Container(
          width: 148,
          decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }
}
