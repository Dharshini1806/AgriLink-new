import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../../shared/widgets/trust_badge.dart';
import '../providers/products_provider.dart';

class FarmerProfileScreen extends ConsumerWidget {
  final String farmerId;
  const FarmerProfileScreen({super.key, required this.farmerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(farmerProfileProvider(farmerId));
    final productsAsync = ref.watch(farmerProductsProvider(farmerId));
    final wishlistState = ref.watch(wishlistProvider);

    // Responsive grid configuration
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200 ? 5 : screenWidth > 900 ? 4 : screenWidth > 600 ? 3 : 2;
    final totalSpacing = (crossAxisCount - 1) * 12.0;
    final cardWidth = (screenWidth - 32.0 - totalSpacing) / crossAxisCount;
    final imageHeight = cardWidth * 3 / 4;
    const infoHeight = 115.0;
    final childAspectRatio = cardWidth / (imageHeight + infoHeight);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Failed to load profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              Text('$e', style: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 12)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(farmerProfileProvider(farmerId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) {
          final String name = profile['farm_name'] as String? ?? profile['name'] as String? ?? 'Farm';
          final String ownerName = profile['name'] as String? ?? '';
          final String desc = profile['farm_desc'] as String? ?? '';
          final String phone = profile['phone'] as String? ?? '';
          final String? profileImg = profile['profile_img'] as String?;
          final double trustScore = AppFormatters.parseDouble(profile['trust_score']);
          final int reviewCount = profile['review_count'] as int? ?? 0;

          return CustomScrollView(
            slivers: [
              // ── Banner & Profile Header ───────────────────────────
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Banner Header
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF1B5E20), Color(0xFF4CAF50), Color(0xFFFFB800)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 12,
                                left: 12,
                                child: SafeArea(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
                                      onPressed: () => context.pop(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Overlapping Avatar
                        Positioned(
                          bottom: -40,
                          left: 20,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surface,
                              border: Border.all(color: AppColors.surface, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: profileImg != null
                                  ? CachedNetworkImage(
                                      imageUrl: profileImg,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(color: AppColors.surfaceVariant),
                                      errorWidget: (_, __, ___) => _initials(ownerName),
                                    )
                                  : _initials(ownerName),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (ownerName.isNotEmpty && ownerName != name)
                                      Text(
                                        'Farmer: $ownerName',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: AppColors.textHint,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  TrustBadge(trustScore: trustScore, reviewCount: reviewCount),
                                  if (reviewCount > 0) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$trustScore ($reviewCount reviews)',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          if (phone.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined, size: 16, color: AppColors.textHint),
                                const SizedBox(width: 6),
                                Text(
                                  phone,
                                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                          if (desc.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              desc,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Divider(color: AppColors.border),
                          const SizedBox(height: 12),
                          Text(
                            "Farmer's Products",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Products list grid ────────────────────────────────
              productsAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
                error: (err, _) => SliverFillRemaining(
                  child: Center(child: Text('Could not load products: $err')),
                ),
                data: (products) {
                  if (products.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🌾', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text(
                              'No products listed by this farmer yet.',
                              style: GoogleFonts.poppins(
                                color: AppColors.textHint,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 60),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: childAspectRatio,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final p = products[i];
                          final pMap = p.toJson();
                          final String pId = p.id;
                          return ProductCard(
                            product: pMap,
                            isWishlisted: wishlistState.ids.contains(pId),
                            onWishlistToggle: () => ref.read(wishlistProvider.notifier).toggle(pMap),
                          );
                        },
                        childCount: products.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _initials(String name) => Container(
        color: AppColors.primary.withOpacity(0.15),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: GoogleFonts.poppins(
              color: AppColors.primary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
}
