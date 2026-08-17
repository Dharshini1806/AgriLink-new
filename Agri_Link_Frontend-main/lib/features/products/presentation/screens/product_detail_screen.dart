import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/trust_badge.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../providers/products_provider.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));
    final reviewsAsync = ref.watch(productReviewsProvider(productId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('$e')),
        data: (p) {
          final imageUrls = (p['image_urls'] as List?)?.cast<String>() ?? [];
          final price     = AppFormatters.parseDouble(p['price']);
          final rating    = AppFormatters.parseDouble(p['avg_rating']);
          final reviews   = p['review_count'] as int? ?? 0;
          final trust     = AppFormatters.parseDouble(p['seller_trust']);
          final qty       = p['quantity'] as int? ?? 0;
          final distKm    = p['distance_km'] != null ? AppFormatters.parseDouble(p['distance_km']) : null;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppColors.surface,
                actions: [
                  Consumer(
                    builder: (ctx, ref, _) {
                      final wishlistState = ref.watch(wishlistProvider);
                      final isWishlisted = wishlistState.ids.contains(productId);
                      return IconButton(
                        icon: Icon(
                          isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isWishlisted ? Colors.red : AppColors.textPrimary,
                        ),
                        onPressed: () => ref.read(wishlistProvider.notifier).toggle(p),
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: imageUrls.isEmpty
                    ? Container(color: AppColors.surfaceVariant,
                        child: const Icon(Icons.image_outlined, size: 80, color: AppColors.textHint))
                    : CarouselSlider(
                        options: CarouselOptions(height: 300, viewportFraction: 1, autoPlay: imageUrls.length > 1),
                        items: imageUrls.map((url) => CachedNetworkImage(
                          imageUrl: '$url?f_auto,q_auto,w_800',
                          fit: BoxFit.cover, width: double.infinity,
                        )).toList(),
                      ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Name & Grade
                    Row(children: [
                      Expanded(child: Text(p['name'] as String,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 22))),
                      if (p['quality_grade'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.gradeA.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(AppFormatters.qualityGrade(p['quality_grade'] as String?),
                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.gradeA, fontWeight: FontWeight.w600)),
                        ),
                    ]),
                    const SizedBox(height: 8),

                    // Price
                    Text(AppFormatters.currency(price),
                      style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    const SizedBox(height: 4),
                    Text('per ${p['quantity_unit'] ?? 'unit'}${qty > 0 ? ' • $qty ${p['quantity_unit'] ?? 'units'} in stock' : ' • Out of stock'}',
                      style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),

                    // Rating
                    if (reviews > 0) ...[
                      const SizedBox(height: 10),
                      Row(children: [
                        RatingBarIndicator(rating: rating, itemSize: 18,
                          itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: Colors.amber),
                          unratedColor: AppColors.border),
                        const SizedBox(width: 8),
                        Text('$rating ($reviews reviews)', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
                      ]),
                    ],

                    if (distKm != null) ...[
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(AppFormatters.distance(distKm), style: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 13)),
                      ]),
                    ],

                    const Divider(height: 28),

                    // Seller
                    Text('About the Farmer', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 24, backgroundColor: AppColors.primary.withOpacity(0.15),
                          child: Text((p['seller_name'] as String).substring(0, 1),
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 18)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p['seller_name'] as String, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          if (p['farm_name'] != null)
                            Text(p['farm_name'] as String, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                          TrustBadge(trustScore: trust, reviewCount: reviews, compact: true),
                        ])),
                      ]),
                    ),

                    // Description
                    if (p['description'] != null && (p['description'] as String).isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('Product Details', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(p['description'] as String,
                        style: GoogleFonts.poppins(color: AppColors.textSecondary, height: 1.6, fontSize: 13)),
                    ],

                    // Reviews
                    const SizedBox(height: 20),
                    Text('Reviews', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 8),
                    ref.watch(productReviewSummaryProvider(productId)).when(
                      data: (summary) => _ReviewSummaryCard(summary: summary, productId: productId),
                      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 8),
                    reviewsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (revList) => revList.isEmpty
                        ? Text('No reviews yet. Be the first!', style: GoogleFonts.poppins(color: AppColors.textHint))
                        : Column(children: revList.take(5).map((r) => _ReviewTile(review: r)).toList()),
                    ),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: productAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (p) {
          final qty = p['quantity'] as int? ?? 0;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: SafeArea(
              child: Row(children: [
                Expanded(child: AppButton(
                  label: 'Add to Cart',
                  icon: Icons.add_shopping_cart_rounded,
                  isOutlined: true,
                  onPressed: qty == 0 ? null : () {
                    ref.read(cartProvider.notifier).add(p);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added ${p['name']} to cart'),
                        action: SnackBarAction(label: 'View Cart', textColor: AppColors.primary, onPressed: () => context.push('/cart')),
                      ),
                    );
                  },
                )),
                const SizedBox(width: 12),
                Expanded(child: AppButton(
                  label: 'Buy Now',
                  onPressed: qty == 0 ? null : () {
                    ref.read(cartProvider.notifier).add(p);
                    context.push('/cart');
                  },
                )),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _ReviewSummaryCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> summary;
  final String productId;
  const _ReviewSummaryCard({required this.summary, required this.productId});

  @override
  ConsumerState<_ReviewSummaryCard> createState() => _ReviewSummaryCardState();
}

class _ReviewSummaryCardState extends ConsumerState<_ReviewSummaryCard> {
  bool _reanalyzing = false;

  Future<void> _reanalyze() async {
    setState(() => _reanalyzing = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post(ApiEndpoints.reanalyzeProductSentiment(widget.productId));
      ref.invalidate(productReviewSummaryProvider(widget.productId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sentiment scores updated!'), backgroundColor: Color(0xFF2E7D32)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _reanalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final double avg = (summary['averageRating'] as num?)?.toDouble() ?? 0.0;
    final int total = (summary['totalReviews'] as num?)?.toInt() ?? 0;
    final dist = summary['distribution'] as Map<String, dynamic>? ?? {};
    final sentiment = summary['sentimentSummary'] as Map<String, dynamic>? ?? {};

    final posPct = (sentiment['positive'] as num?)?.toDouble() ?? 0.0;
    final neuPct = (sentiment['neutral'] as num?)?.toDouble() ?? 0.0;
    final negPct = (sentiment['negative'] as num?)?.toDouble() ?? 0.0;

    // When all sentiment is 0 but there are reviews, it means existing reviews need re-analysis
    final needsReanalysis = total > 0 && (posPct + neuPct + negPct) == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      avg.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RatingBarIndicator(
                      rating: avg,
                      itemSize: 13,
                      itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: Colors.amber),
                      unratedColor: AppColors.border,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$total reviews',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Column(
                  children: List.generate(5, (index) {
                    final star = 5 - index;
                    final pctVal = (dist[star.toString()] as num?)?.toInt() ?? 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            star.toString(),
                            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.star_rounded, size: 10, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pctVal / 100.0,
                                minHeight: 6,
                                backgroundColor: AppColors.border.withOpacity(0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 26,
                            child: Text(
                              '$pctVal%',
                              textAlign: TextAlign.end,
                              style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textHint, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          if (total > 0) ...[
            const Divider(height: 24, thickness: 0.8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Customer Sentiment Analysis',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                // Show refresh button when sentiment needs reanalysis or always for manual refresh
                if (_reanalyzing)
                  const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                else
                  Tooltip(
                    message: needsReanalysis
                        ? 'Sentiment not computed — tap to analyze'
                        : 'Refresh sentiment scores',
                    child: InkWell(
                      onTap: _reanalyze,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          needsReanalysis ? Icons.analytics_outlined : Icons.refresh_rounded,
                          size: 16,
                          color: needsReanalysis ? AppColors.primary : AppColors.textHint,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (needsReanalysis) ...[
              const SizedBox(height: 4),
              Text(
                'Tap ↑ to compute sentiment from reviews',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppColors.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    if (posPct > 0)
                      Expanded(
                        flex: posPct.round(),
                        child: Container(color: const Color(0xFF2E7D32)),
                      ),
                    if (neuPct > 0)
                      Expanded(
                        flex: neuPct.round(),
                        child: Container(color: const Color(0xFFFFA000)),
                      ),
                    if (negPct > 0)
                      Expanded(
                        flex: negPct.round(),
                        child: Container(color: const Color(0xFFC62828)),
                      ),
                    // When all 0, show a placeholder grey bar
                    if (posPct == 0 && neuPct == 0 && negPct == 0)
                      Expanded(
                        flex: 100,
                        child: Container(color: AppColors.border.withOpacity(0.4)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SentimentLegend(label: 'Positive', pct: posPct, color: const Color(0xFF2E7D32)),
                _SentimentLegend(label: 'Neutral', pct: neuPct, color: const Color(0xFFFFA000)),
                _SentimentLegend(label: 'Negative', pct: negPct, color: const Color(0xFFC62828)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SentimentLegend extends StatelessWidget {
  final String label;
  final double pct;
  final Color color;
  const _SentimentLegend({required this.label, required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label (${pct.toStringAsFixed(0)}%)',
          style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 14, backgroundColor: AppColors.primary.withOpacity(0.12),
            child: Text((review['reviewer_name'] as String? ?? '?').substring(0, 1),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.primary)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(review['reviewer_name'] as String? ?? 'User',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13))),
          RatingBarIndicator(rating: (review['rating'] as int).toDouble(),
            itemSize: 14, itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: Colors.amber),
            unratedColor: AppColors.border),
        ]),
        if (review['comment'] != null && (review['comment'] as String).isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(review['comment'] as String,
            style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12, height: 1.5)),
        ],
        if (review['sentiment_label'] != null || (review['feedback_tags'] as List?)?.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (review['sentiment_label'] != null)
                _SentimentBadge(label: review['sentiment_label'] as String),
              ...?((review['feedback_tags'] as List?)?.map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.border.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  t.toString(),
                  style: GoogleFonts.poppins(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ))),
            ],
          ),
        ],
      ]),
    ),
  );
}

class _SentimentBadge extends StatelessWidget {
  final String label;
  const _SentimentBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (label.toLowerCase()) {
      case 'positive':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        break;
      case 'neutral':
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFFF57F17);
        break;
      case 'negative':
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        break;
      default:
        bg = AppColors.surfaceVariant;
        fg = AppColors.textHint;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.poppins(fontSize: 8, color: fg, fontWeight: FontWeight.bold),
      ),
    );
  }
}
