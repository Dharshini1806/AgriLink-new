import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../features/orders/presentation/providers/orders_provider.dart';
import '../../../../shared/widgets/app_button.dart';

final _recipesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ref.watch(dioProvider).get(ApiEndpoints.recipes);
  return List<Map<String, dynamic>>.from(res.data as List);
});

final _recipeCartProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

class RecipePickerScreen extends ConsumerStatefulWidget {
  const RecipePickerScreen({super.key});
  @override
  ConsumerState<RecipePickerScreen> createState() => _RecipePickerScreenState();
}

class _RecipePickerScreenState extends ConsumerState<RecipePickerScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _pick(String recipeName) async {
    setState(() { _loading = true; _error = null; });
    try {
      Position? pos;
      try { pos = await Geolocator.getCurrentPosition(); } catch (_) {}

      final res = await ref.read(dioProvider).post(ApiEndpoints.recipeToCart, data: {
        'recipe_name': recipeName,
        if (pos != null) 'latitude': pos.latitude,
        if (pos != null) 'longitude': pos.longitude,
      });
      ref.read(_recipeCartProvider.notifier).state = res.data as Map<String, dynamic>;
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(_recipesProvider);
    final recipeCart   = ref.watch(_recipeCartProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cook a Recipe'),
        actions: [
          if (recipeCart != null)
            TextButton(
              onPressed: () => ref.read(_recipeCartProvider.notifier).state = null,
              child: const Text('Clear'),
            ),
        ],
      ),
      body: recipeCart != null
        ? _CartPreview(result: recipeCart)
        : Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    'Select a recipe and we\'ll auto-fill your cart with the best nearby ingredients!',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primary),
                  )),
                ]),
              ),
            ),
            if (_error != null) Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!, style: GoogleFonts.poppins(color: AppColors.error, fontSize: 12)),
            ),
            Expanded(
              child: _loading
                ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text('Finding best ingredients near you…'),
                  ]))
                : recipesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('$e')),
                    data: (recipes) => ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: recipes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final r = recipes[i];
                        return _RecipeCard(recipe: r, onTap: () => _pick(r['name'] as String));
                      },
                    ),
                  ),
            ),
          ]),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final VoidCallback onTap;
  const _RecipeCard({required this.recipe, required this.onTap});

  static const _emojis = ['🥘','🍛','🫕','🥗','🍲','🥗','🫔','🍱'];

  @override
  Widget build(BuildContext context) {
    final i = recipe['name'].hashCode.abs() % _emojis.length;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(_emojis[i], style: const TextStyle(fontSize: 28))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(recipe['name'] as String, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
            if (recipe['description'] != null)
              Text(recipe['description'] as String, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12)),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
        ]),
      ),
    );
  }
}

class _CartPreview extends ConsumerWidget {
  final Map<String, dynamic> result;
  const _CartPreview({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items   = List<Map<String, dynamic>>.from(result['cartItems'] as List? ?? []);
    final missing = List<String>.from(result['missingIngredients'] as List? ?? []);
    final subtotal = AppFormatters.parseDouble(result['estimatedSubtotal']);

    return Column(children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.success),
                const SizedBox(width: 10),
                Expanded(child: Text(result['message'] as String? ?? 'Cart ready!',
                  style: GoogleFonts.poppins(color: AppColors.success, fontSize: 13))),
              ]),
            ),
            const SizedBox(height: 16),
            ...items.map((item) {
              final p = item['product'] as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item['categoryName'] as String,
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint)),
                    Text(p['name'] as String, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    Text('from ${p['seller_name']}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('× ${item['quantity']}', style: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 12)),
                    Text(AppFormatters.currency(AppFormatters.parseDouble(p['price'])),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ]),
                ]),
              );
            }),
            if (missing.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Not available nearby:', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.warning, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(missing.join(', '), style: GoogleFonts.poppins(color: AppColors.warning, fontSize: 12)),
                ]),
              ),
            ],
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Estimated Total:', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
              Text(AppFormatters.currency(subtotal), style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary)),
            ]),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: AppButton(
          label: 'Add All to Cart',
          icon: Icons.add_shopping_cart_rounded,
          onPressed: () {
            final items = List<Map<String, dynamic>>.from(result['cartItems'] as List? ?? []);
            ref.read(cartProvider.notifier).addAll(items);
            context.push('/cart');
          },
        ),
      ),
    ]);
  }
}
