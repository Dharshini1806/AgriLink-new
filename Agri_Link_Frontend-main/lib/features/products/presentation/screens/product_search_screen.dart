import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../data/models/product_model.dart';
import '../providers/products_provider.dart';

class ProductSearchScreen extends ConsumerStatefulWidget {
  const ProductSearchScreen({super.key});
  @override
  ConsumerState<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends ConsumerState<ProductSearchScreen> {
  final _c = TextEditingController();

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(productFeedProvider);
    final wishlistState = ref.watch(wishlistProvider);

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
        titleSpacing: 0,
        title: TextField(
          controller: _c,
          autofocus: true,
          onChanged: (q) {
            if (q.length > 2 || q.isEmpty) {
              ref.read(productFeedProvider.notifier).load(query: q);
            }
          },
          style: GoogleFonts.poppins(fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Search produce…',
            hintStyle: GoogleFonts.poppins(color: AppColors.textHint),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
        actions: [
          if (_c.text.isNotEmpty)
            IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () {
              _c.clear();
              ref.read(productFeedProvider.notifier).load();
            }),
        ],
      ),
      body: results.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('$e')),
        data: (products) => products.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.search_off_rounded, size: 56, color: AppColors.textHint),
              const SizedBox(height: 12),
              Text('No results found', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
              Text('Try a different keyword', style: GoogleFonts.poppins(color: AppColors.textHint)),
            ]))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: childAspectRatio),
              itemCount: products.length,
              itemBuilder: (_, i) {
                final p = products[i];
                final pMap = p is ProductModel ? p.toJson() : (p as Map<String, dynamic>);
                final String pId = pMap['id'] as String;
                return ProductCard(
                  product: pMap,
                  isWishlisted: wishlistState.ids.contains(pId),
                  onWishlistToggle: () => ref.read(wishlistProvider.notifier).toggle(pMap),
                );
              },
            ),
      ),
    );
  }
}
