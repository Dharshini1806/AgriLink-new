import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/product_card.dart';
import '../providers/products_provider.dart';
import '../providers/location_provider.dart';

// ── Hero banner data ─────────────────────────────────────────────────────────
const _heroBanners = [
  _BannerData('🌽', 'Corn Season', 'Fresh harvest from local farms', Color(0xFFF5A623)),
  _BannerData('🍅', 'Tomato Special', 'Farm-ripened, zero chemicals', Color(0xFFD94F3A)),
  _BannerData('🥦', 'Green Harvest', 'Nutrient-packed veggies nearby', Color(0xFF4A7C3F)),
  _BannerData('🌾', 'Grain Market', 'Direct from paddy fields', Color(0xFF9C6B4A)),
];

class _BannerData {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  const _BannerData(this.emoji, this.title, this.subtitle, this.color);
}

class ProductFeedScreen extends ConsumerStatefulWidget {
  const ProductFeedScreen({super.key});

  @override
  ConsumerState<ProductFeedScreen> createState() => _ProductFeedScreenState();
}

class _ProductFeedScreenState extends ConsumerState<ProductFeedScreen>
    with SingleTickerProviderStateMixin {
  final _searchC  = TextEditingController();
  final _scroll   = ScrollController();
  final _pageCtrl = PageController();
  String? _selCat;
  String? _selGrade;
  int _bannerPage = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFeed());

    // Auto-rotate banner every 3.5s
    Future.delayed(const Duration(milliseconds: 500), _rotateBanner);
  }

  void _rotateBanner() {
    if (!mounted) return;
    final next = (_bannerPage + 1) % _heroBanners.length;
    if (_pageCtrl.hasClients) {
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
    Future.delayed(const Duration(milliseconds: 3500), _rotateBanner);
  }

  @override
  void dispose() {
    _searchC.dispose();
    _scroll.dispose();
    _pageCtrl.dispose();
    super.dispose();
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
        title: Text('Change Location', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
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
        ]),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.my_location_rounded, size: 16),
            label: const Text('Use GPS'),
            onPressed: () { locNotifier.detectLocation(); Navigator.pop(ctx); },
          ),
          TextButton(
            onPressed: () {
              final lat = double.tryParse(latC.text);
              final lng = double.tryParse(lngC.text);
              if (lat != null && lng != null) locNotifier.setCustomLocation(lat, lng);
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
    final feedState     = ref.watch(productFeedProvider);
    final categories    = ref.watch(categoriesProvider).value ?? [];
    final compareIds    = ref.watch(compareSelectionProvider);
    final wishlistState = ref.watch(wishlistProvider);
    final locationState = ref.watch(userLocationProvider);

    ref.listen(userLocationProvider, (prev, next) {
      if (prev?.latitude != next.latitude || prev?.longitude != next.longitude) {
        _loadFeed();
      }
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200 ? 5 : screenWidth > 900 ? 4 : screenWidth > 600 ? 3 : 2;
    final totalSpacing   = (crossAxisCount - 1) * 12.0;
    final cardWidth      = (screenWidth - 32.0 - totalSpacing) / crossAxisCount;
    final imageHeight    = cardWidth * 3 / 4;
    const infoHeight     = 120.0;
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
              elevation: 0,
              title: Row(children: [
                // Logo
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.secondary, AppColors.primary],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(child: Text('🌾', style: TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 10),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppColors.secondary, AppColors.primary],
                  ).createShader(bounds),
                  child: Text(
                    'AgriLink',
                    style: GoogleFonts.playfairDisplay(
                      fontWeight: FontWeight.w800, fontSize: 22, color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary),
                  onPressed: () => context.push('/search'),
                ),
                IconButton(
                  icon: Icon(
                    wishlistState.ids.isNotEmpty
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: wishlistState.ids.isNotEmpty ? const Color(0xFFE55252) : AppColors.textPrimary,
                  ),
                  onPressed: () => context.push('/wishlist'),
                ),
              ]),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: TextField(
                    controller: _searchC,
                    onSubmitted: (q) => ref.read(productFeedProvider.notifier).load(query: q),
                    style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search tomatoes, rice, milk…',
                      hintStyle: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
                      suffixIcon: _searchC.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: AppColors.textHint),
                              onPressed: () { _searchC.clear(); _loadFeed(); })
                          : null,
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border, width: 0.8)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.secondary, width: 1.5)),
                    ),
                  ),
                ),
              ),
            ),
          ],
          body: RefreshIndicator(
            color: AppColors.secondary,
            backgroundColor: AppColors.surface,
            onRefresh: () async => _loadFeed(),
            child: CustomScrollView(
              controller: _scroll,
              slivers: [
                // ── Hero banner ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        height: 130,
                        child: PageView.builder(
                          controller: _pageCtrl,
                          onPageChanged: (i) => setState(() => _bannerPage = i),
                          itemCount: _heroBanners.length,
                          itemBuilder: (ctx, i) {
                            final b = _heroBanners[i];
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [b.color, b.color.withOpacity(0.7)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Row(children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(b.title,
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: 22, fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        )),
                                      const SizedBox(height: 4),
                                      Text(b.subtitle,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12, color: Colors.white.withOpacity(0.85))),
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.22),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: Colors.white.withOpacity(0.4)),
                                        ),
                                        child: Text('Explore →',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11, fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          )),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(b.emoji, style: const TextStyle(fontSize: 64)),
                              ]),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // Banner dots
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_heroBanners.length, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _bannerPage == i ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _bannerPage == i ? AppColors.secondary : AppColors.border,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ),
                ),

                // ── Location Bar ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: InkWell(
                      onTap: () => _showLocationDialog(context),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
                        ),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.location_on_rounded,
                                color: AppColors.secondary, size: 14),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              locationState.label,
                              style: GoogleFonts.poppins(
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                  color: AppColors.primary),
                            ),
                          ),
                          Text('Change',
                            style: GoogleFonts.poppins(
                                fontSize: 11, fontWeight: FontWeight.w700,
                                color: AppColors.secondary)),
                          const SizedBox(width: 2),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppColors.secondary, size: 16),
                        ]),
                      ),
                    ),
                  ),
                ),

                // ── Category chips ────────────────────────────────────────
                if (categories.isNotEmpty) SliverToBoxAdapter(
                  child: SizedBox(
                    height: 46,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categories.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (ctx, i) {
                        if (i == 0) {
                          return _EarthyChip(
                            label: '🌿 All',
                            isSelected: _selCat == null,
                            onSelected: (_) { setState(() => _selCat = null); _loadFeed(); },
                          );
                        }
                        final cat = categories[i - 1];
                        return _EarthyChip(
                          label: cat['name'] as String,
                          isSelected: _selCat == cat['name'],
                          onSelected: (_) {
                            setState(() => _selCat = cat['name']);
                            _loadFeed();
                          },
                        );
                      },
                    ),
                  ),
                ),

                // ── Grade filter ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: Row(children: [
                      Text('Grade:',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                      const SizedBox(width: 8),
                      _GradeChip(
                        grade: 'A', color: AppColors.gradeA,
                        isSelected: _selGrade == 'A',
                        onTap: () {
                          setState(() => _selGrade = _selGrade == 'A' ? null : 'A');
                          _loadFeed();
                        },
                      ),
                      const SizedBox(width: 6),
                      _GradeChip(
                        grade: 'B', color: AppColors.gradeB,
                        isSelected: _selGrade == 'B',
                        onTap: () {
                          setState(() => _selGrade = _selGrade == 'B' ? null : 'B');
                          _loadFeed();
                        },
                      ),
                      const SizedBox(width: 6),
                      _GradeChip(
                        grade: 'C', color: AppColors.gradeC,
                        isSelected: _selGrade == 'C',
                        onTap: () {
                          setState(() => _selGrade = _selGrade == 'C' ? null : 'C');
                          _loadFeed();
                        },
                      ),
                    ]),
                  ),
                ),

                // ── Compare bar ────────────────────────────────────────────
                if (compareIds.isNotEmpty) SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.secondary, AppColors.primary],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withOpacity(0.25),
                              blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(children: [
                        const Icon(Icons.compare_arrows_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('${compareIds.length} selected for compare',
                            style: GoogleFonts.poppins(
                                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                        TextButton(
                          onPressed: () => context.push('/compare', extra: compareIds.toList()),
                          child: const Text('Compare →',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ]),
                    ),
                  ),
                ),

                // ── Products section header ────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(children: [
                      Text('Nearby Produce',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        )),
                      const Spacer(),
                      Text('Fresh picks',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: AppColors.textHint, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ),

                // ── Product Grid ──────────────────────────────────────────
                feedState.when(
                  loading: () => SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12, mainAxisSpacing: 12,
                        childAspectRatio: childAspectRatio,
                      ),
                      delegate: SliverChildBuilderDelegate(
                          (_, __) => const _WarmShimmerCard(), childCount: 8),
                    ),
                  ),
                  error: (err, _) => SliverFillRemaining(
                    child: Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.wifi_off_rounded,
                              size: 40, color: AppColors.textHint),
                        ),
                        const SizedBox(height: 16),
                        Text('Connection issue',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(height: 6),
                        Text('$err',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _loadFeed,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Try Again'),
                        ),
                      ]),
                    ),
                  ),
                  data: (products) {
                    if (products.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const Text('🌾', style: TextStyle(fontSize: 56)),
                            const SizedBox(height: 12),
                            Text('No produce nearby',
                              style: GoogleFonts.playfairDisplay(
                                fontWeight: FontWeight.w700, fontSize: 20,
                                color: AppColors.textPrimary)),
                            const SizedBox(height: 6),
                            Text('Try changing your location or removing filters',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary, fontSize: 13)),
                          ]),
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12, mainAxisSpacing: 14,
                          childAspectRatio: childAspectRatio,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            if (i >= products.length) return const _LoadingMore();
                            final p = products[i];
                            return ProductCard(
                              product: p,
                              showCompareToggle: true,
                              isSelected: compareIds.contains(p['id'] as String),
                              onCompareToggle: () => ref
                                  .read(compareSelectionProvider.notifier)
                                  .toggle(p['id'] as String),
                              isWishlisted: wishlistState.ids.contains(p['id'] as String),
                              onWishlistToggle: () =>
                                  ref.read(wishlistProvider.notifier).toggle(p),
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

// ── Custom earthy filter chip ─────────────────────────────────────────────────
class _EarthyChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final void Function(bool) onSelected;
  const _EarthyChip({required this.label, required this.isSelected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelected(!isSelected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.secondary.withOpacity(0.25),
                  blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Grade chip ────────────────────────────────────────────────────────────────
class _GradeChip extends StatelessWidget {
  final String grade;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  const _GradeChip({
    required this.grade, required this.color,
    required this.isSelected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(isSelected ? 0 : 0.3)),
        ),
        child: Text(
          '★ $grade',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

// ── Warm shimmer card ─────────────────────────────────────────────────────────
class _WarmShimmerCard extends StatelessWidget {
  const _WarmShimmerCard();

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: const Color(0xFFF0E6D6),
        highlightColor: const Color(0xFFFBF5EC),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
}

// ── Loading more ──────────────────────────────────────────────────────────────
class _LoadingMore extends StatelessWidget {
  const _LoadingMore();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            width: 24, height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.secondary),
          ),
        ),
      );
}
