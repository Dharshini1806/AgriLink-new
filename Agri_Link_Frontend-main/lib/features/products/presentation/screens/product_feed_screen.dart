import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/product_card.dart';
import '../providers/products_provider.dart';
import '../providers/location_provider.dart';

class ProductFeedScreen extends ConsumerStatefulWidget {
  const ProductFeedScreen({super.key});

  @override
  ConsumerState<ProductFeedScreen> createState() => _ProductFeedScreenState();
}

class _ProductFeedScreenState extends ConsumerState<ProductFeedScreen> {
  final _searchC  = TextEditingController();
  final _scroll   = ScrollController();
  String? _selCat;
  String? _selGrade;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFeed());
  }

  @override
  void dispose() {
    _searchC.dispose(); _scroll.dispose(); super.dispose();
  }

  void _loadFeed() {
    final loc = ref.read(userLocationProvider);
    ref.read(productFeedProvider.notifier).load(
      lat: loc.latitude, lng: loc.longitude,
      category: _selCat, grade: _selGrade,
    );
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      ref.read(productFeedProvider.notifier).loadMore();
    }
  }

  void _showLocationDialog(BuildContext context) {
    final locNotifier = ref.read(userLocationProvider.notifier);
    final currentLoc = ref.read(userLocationProvider);
    final latC = TextEditingController(text: currentLoc.latitude?.toString() ?? '');
    final lngC = TextEditingController(text: currentLoc.longitude?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Change Location', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter coordinates to find nearby farmers in that area.',
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: latC,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Latitude', hintText: 'e.g. 13.0827'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: lngC,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Longitude', hintText: 'e.g. 80.2707'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              locNotifier.detectLocation();
              Navigator.pop(ctx);
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.my_location_rounded, size: 16),
                SizedBox(width: 4),
                Text('Use GPS'),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              final lat = double.tryParse(latC.text);
              final lng = double.tryParse(lngC.text);
              if (lat != null && lng != null) {
                locNotifier.setCustomLocation(lat, lng);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(productFeedProvider);
    final categories = ref.watch(categoriesProvider).value ?? [];
    final compareIds = ref.watch(compareSelectionProvider);
    final wishlistState = ref.watch(wishlistProvider);
    final locationState = ref.watch(userLocationProvider);

    ref.listen(userLocationProvider, (prev, next) {
      if (prev?.latitude != next.latitude || prev?.longitude != next.longitude) {
        _loadFeed();
      }
    });

    // Responsive grid — compute aspect ratio from actual content dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200 ? 5 : screenWidth > 900 ? 4 : screenWidth > 600 ? 3 : 2;
    final totalSpacing = (crossAxisCount - 1) * 12.0;
    final cardWidth = (screenWidth - 32.0 - totalSpacing) / crossAxisCount; // 32 = padding 16*2
    final imageHeight = cardWidth * 3 / 4; // matches AspectRatio(4/3)
    const infoHeight = 100.0; // name + seller + price + rating + padding
    final childAspectRatio = cardWidth / (imageHeight + infoHeight);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              floating: true, snap: true, pinned: false,
              backgroundColor: AppColors.background,
              automaticallyImplyLeading: false,
              title: Row(children: [
                Image.asset('assets/images/logo.png', height: 32, width: 32),
                const SizedBox(width: 8),
                Text('AgriLink', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 20)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary),
                  onPressed: () => context.push('/search'),
                ),
                IconButton(
                  icon: Icon(
                    wishlistState.ids.isNotEmpty ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: wishlistState.ids.isNotEmpty ? Colors.red : AppColors.textPrimary,
                  ),
                  onPressed: () => context.push('/wishlist'),
                ),
              ]),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchC,
                    onSubmitted: (q) => ref.read(productFeedProvider.notifier).load(query: q),
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search tomatoes, rice, milk…',
                      hintStyle: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint),
                      suffixIcon: _searchC.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () { _searchC.clear(); _loadFeed(); })
                        : null,
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
                    ),
                  ),
                ),
              ),
            ),
          ],
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => _loadFeed(),
            child: CustomScrollView(
              controller: _scroll,
              slivers: [
                // Location Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: InkWell(
                      onTap: () => _showLocationDialog(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              locationState.label,
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                          ),
                          Text(
                            'Change',
                            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 16),
                        ]),
                      ),
                    ),
                  ),
                ),
                // Category chips
                if (categories.isNotEmpty) SliverToBoxAdapter(
                  child: SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categories.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (ctx, i) {
                        if (i == 0) {
                          return FilterChip(
                            label: const Text('All'),
                            selected: _selCat == null,
                            onSelected: (_) { setState(() => _selCat = null); _loadFeed(); },
                          );
                        }
                        final cat = categories[i - 1];
                        return FilterChip(
                          label: Text(cat['name'] as String),
                          selected: _selCat == cat['name'],
                          onSelected: (_) { setState(() => _selCat = cat['name']); _loadFeed(); },
                        );
                      },
                    ),
                  ),
                ),

                // Grade filter row
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(children: [
                      Text('Grade:', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(width: 8),
                      ...['A', 'B', 'C'].map((g) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(g),
                          selected: _selGrade == g,
                          onSelected: (_) { setState(() => _selGrade = _selGrade == g ? null : g); _loadFeed(); },
                          selectedColor: AppColors.primary.withOpacity(0.15),
                        ),
                      )),
                    ]),
                  ),
                ),

                // Compare bar
                if (compareIds.isNotEmpty) SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        const Icon(Icons.compare_arrows_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text('${compareIds.length} selected for compare',
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500))),
                        TextButton(
                          onPressed: () => context.push('/compare', extra: compareIds.toList()),
                          child: const Text('Compare', style: TextStyle(color: Colors.white)),
                        ),
                      ]),
                    ),
                  ),
                ),

                // Product Grid
                feedState.when(
                  loading: () => SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: childAspectRatio),
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => const _ShimmerCard(), childCount: 8),
                    ),
                  ),
                  error: (err, _) => SliverFillRemaining(
                    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textHint),
                      const SizedBox(height: 12),
                      Text('$err', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadFeed, child: const Text('Retry')),
                    ])),
                  ),
                  data: (products) {
                    if (products.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.search_off_rounded, size: 56, color: AppColors.textHint),
                          const SizedBox(height: 12),
                          Text('No produce available nearby', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          Text('Try increasing your radius or remove filters',
                            style: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 12)),
                        ])),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: childAspectRatio),
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            if (i >= products.length) return const _LoadingMore();
                            final p = products[i];
                            return ProductCard(
                              product: p,
                              showCompareToggle: true,
                              isSelected: compareIds.contains(p['id'] as String),
                              onCompareToggle: () => ref.read(compareSelectionProvider.notifier).toggle(p['id'] as String),
                              isWishlisted: wishlistState.ids.contains(p['id'] as String),
                              onWishlistToggle: () => ref.read(wishlistProvider.notifier).toggle(p),
                            );
                          },
                          childCount: products.length + 1,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: Colors.grey[200]!, highlightColor: Colors.grey[100]!,
    child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
  );
}

class _LoadingMore extends StatelessWidget {
  const _LoadingMore();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
    ),
  );
}
