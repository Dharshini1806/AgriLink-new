import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/formatters.dart';

final _compareResultProvider = FutureProvider.family<Map<String, dynamic>, List<String>>((ref, ids) async {
  final res = await ref.watch(dioProvider).get(ApiEndpoints.compare, queryParameters: {'ids': ids.join(',')});
  return res.data as Map<String, dynamic>;
});

class ProductCompareScreen extends ConsumerWidget {
  final List<String> ids;
  const ProductCompareScreen({super.key, required this.ids});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_compareResultProvider(ids));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Compare Products')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) {
          final products = List<Map<String, dynamic>>.from(data['products'] as List);
          final winners  = Map<String, String>.from(data['winners'] as Map? ?? {});

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Labels column
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SizedBox(height: 130), // image placeholder
                    ...[
                      'Price', 'Rating', 'Distance', 'Quality Grade', 'Trust Score', 'Value Score'
                    ].map((label) => Container(
                      height: 52, alignment: Alignment.centerLeft,
                      child: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
                    )),
                  ]),
                  const SizedBox(width: 12),
                  // Product columns
                  ...products.map((p) {
                    final pId = p['id'] as String;
                    final imageUrls = (p['image_urls'] as List?)?.cast<String>() ?? [];

                    bool isWinner(String attr) => winners[attr] == pId;

                    return Container(
                      width: 160,
                      margin: const EdgeInsets.only(left: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: Column(children: [
                        // Image
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                          child: imageUrls.isNotEmpty
                            ? CachedNetworkImage(imageUrl: imageUrls.first, height: 120, width: 160, fit: BoxFit.cover)
                            : Container(height: 120, color: AppColors.surfaceVariant,
                                child: const Icon(Icons.image_outlined, color: AppColors.textHint, size: 40)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(p['name'] as String, maxLines: 2, textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                        const Divider(height: 1),
                        // Attrs
                        ...[
                          ('price',       AppFormatters.currency(AppFormatters.parseDouble(p['price'])), 'price'),
                          ('avg_rating',  '${AppFormatters.parseDouble(p['avg_rating']).toStringAsFixed(1)} ⭐', 'avg_rating'),
                          ('distance_km', p['distance_km'] != null ? AppFormatters.distance(AppFormatters.parseDouble(p['distance_km'])) : '—', 'distance'),
                          ('quality_grade', p['quality_grade'] as String? ?? '—', null),
                          ('trust_score', p['trust_score'] != null ? AppFormatters.parseDouble(p['trust_score']).toStringAsFixed(2) : '—', 'trust_score'),
                          ('value_score', '${p['value_score'] ?? '—'}', 'value_score'),
                        ].map(((String, String, String?) tuple) {
                          final (_, value, winnerKey) = tuple;
                          final win = winnerKey != null && isWinner(winnerKey);
                          return Container(
                            height: 52, width: double.infinity,
                            color: win ? AppColors.primary.withOpacity(0.07) : null,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              if (win) const Icon(Icons.emoji_events_rounded, size: 14, color: AppColors.primary),
                              if (win) const SizedBox(width: 4),
                              Flexible(child: Text(value, textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: win ? FontWeight.w700 : FontWeight.normal,
                                  color: win ? AppColors.primary : AppColors.textPrimary,
                                ))),
                            ]),
                          );
                        }),
                      ]),
                    );
                  }),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}
