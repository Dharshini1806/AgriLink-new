import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/product_card.dart';
import '../providers/products_provider.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistState = ref.watch(wishlistProvider);
    final wishlistNotifier = ref.read(wishlistProvider.notifier);

    // Responsive grid
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200 ? 5 : screenWidth > 900 ? 4 : screenWidth > 600 ? 3 : 2;
    final totalSpacing = (crossAxisCount - 1) * 12.0;
    final cardWidth = (screenWidth - 32.0 - totalSpacing) / crossAxisCount;
    final imageHeight = cardWidth * 3 / 4;
    const infoHeight = 100.0;
    final childAspectRatio = cardWidth / (imageHeight + infoHeight);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Favorites', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: wishlistState.isLoading && wishlistState.items.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : wishlistState.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite_border_rounded, size: 64, color: AppColors.textHint),
                      const SizedBox(height: 12),
                      Text(
                        'No favorites added yet',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap the heart icon on any produce to save it here',
                        style: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => wishlistNotifier.load(),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: childAspectRatio,
                    ),
                    itemCount: wishlistState.items.length,
                    itemBuilder: (ctx, i) {
                      final productModel = wishlistState.items[i];
                      final pMap = productModel.toJson();
                      return ProductCard(
                        product: pMap,
                        isWishlisted: true,
                        onWishlistToggle: () => wishlistNotifier.toggle(productModel),
                      );
                    },
                  ),
                ),
    );
  }
}
