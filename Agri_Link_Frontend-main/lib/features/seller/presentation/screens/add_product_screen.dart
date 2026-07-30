import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../features/products/presentation/providers/products_provider.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final String? editProductId;
  const AddProductScreen({super.key, this.editProductId});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _form    = GlobalKey<FormState>();
  final _nameC   = TextEditingController();
  final _descC   = TextEditingController();
  final _priceC  = TextEditingController();
  final _qtyC    = TextEditingController();
  final _areaC   = TextEditingController();
  final _radiusC = TextEditingController(text: '30');

  String? _selectedCategory;
  String? _selectedGrade;
  List<PickedImage> _images = [];
  bool _saving = false;
  Map<String, dynamic>? _priceSuggestion;
  bool _loadingSuggestion = false;
  String _selectedUnit = 'kg';

  MediaType _getMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      default:
        return MediaType('image', 'jpeg');
    }
  }

  @override
  void dispose() {
    _nameC.dispose(); _descC.dispose(); _priceC.dispose();
    _qtyC.dispose(); _areaC.dispose(); _radiusC.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      final newImages = <PickedImage>[];
      for (final file in picked) {
        try {
          final bytes = await file.readAsBytes();
          newImages.add(PickedImage(file: file, bytes: bytes));
        } catch (e) {
          debugPrint('Failed to read image bytes: $e');
        }
      }
      setState(() {
        _images = [..._images, ...newImages].take(5).toList();
      });
    }
  }

  Future<void> _fetchPriceSuggestion(String categoryId) async {
    setState(() { _loadingSuggestion = true; _priceSuggestion = null; });
    try {
      final res = await ref.read(dioProvider).get(
        ApiEndpoints.priceSuggest, queryParameters: {'categoryId': categoryId},
      );
      setState(() => _priceSuggestion = res.data as Map<String, dynamic>);
    } catch (_) {} finally {
      setState(() => _loadingSuggestion = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() => _saving = true);
    try {
      final formData = FormData.fromMap({
        'name':               _nameC.text.trim(),
        'description':        _descC.text.trim(),
        'category_id':        _selectedCategory,
        'price':              _priceC.text.trim(),
        'quantity':           _qtyC.text.trim(),
        'quantity_unit':      _selectedUnit,
        if (_selectedGrade != null) 'quality_grade': _selectedGrade,
        'delivery_area':      _areaC.text.trim(),
        'delivery_radius_km': _radiusC.text.trim(),
      });

      for (final img in _images) {
        formData.files.add(
          MapEntry(
            'images',
            MultipartFile.fromBytes(
              img.bytes,
              filename: img.file.name,
              contentType: _getMimeType(img.file.name),
            ),
          ),
        );
      }

      await ref.read(dioProvider).post(ApiEndpoints.products, data: formData);
      if (mounted) {
        ref.invalidate(sellerProductsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product listed successfully! 🎉'), backgroundColor: AppColors.success));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.editProductId != null ? 'Edit Product' : 'List New Product')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image picker
            Text('Product Photos (max 5)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._images.asMap().entries.map((e) => Stack(children: [
                    Container(
                      width: 90, height: 90, margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(e.value.bytes, fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(top: 4, right: 12, child: GestureDetector(
                      onTap: () => setState(() => _images.removeAt(e.key)),
                      child: Container(
                        decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                      ),
                    )),
                  ])),
                  if (_images.length < 5) GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.surfaceVariant,
                      ),
                      child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 28),
                        Text('Add', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            AppTextField(controller: _nameC, label: 'Product Name', hint: 'Fresh Tomatoes', prefixIcon: Icons.local_florist_outlined,
              validator: (v) => AppValidators.required(v, 'Product name')),
            const SizedBox(height: 14),

            // Category dropdown
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Category', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              categoriesState.when(
                loading: () => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border.withOpacity(0.5)),
                  ),
                  child: const Row(children: [
                    SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                    SizedBox(width: 12),
                    Text('Loading categories...', style: TextStyle(color: AppColors.textHint, fontSize: 14)),
                  ]),
                ),
                error: (e, _) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Failed to load categories', 
                        style: GoogleFonts.poppins(color: AppColors.error, fontSize: 13)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20),
                      onPressed: () => ref.refresh(categoriesProvider),
                    ),
                  ]),
                ),
                data: (categoriesList) => DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    filled: true, fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    prefixIcon: const Icon(Icons.category_outlined, color: AppColors.textHint, size: 20),
                  ),
                  hint: Text('Select category', style: GoogleFonts.poppins(color: AppColors.textHint)),
                  items: categoriesList.map<DropdownMenuItem<String>>((c) => DropdownMenuItem<String>(
                    value: c.id,
                    child: Text(c.name, style: GoogleFonts.poppins()),
                  )).toList(),
                  onChanged: (val) {
                    setState(() => _selectedCategory = val);
                    if (val != null) _fetchPriceSuggestion(val);
                  },
                ),
              ),
            ]),
            const SizedBox(height: 14),

            // Price suggestion
            if (_loadingSuggestion) const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(color: AppColors.primary),
            ),
            if (_priceSuggestion != null) Builder(
              builder: (context) {
                final suggested = _priceSuggestion?['suggestedPrice'];
                final hasData = suggested != null && suggested > 0;
                return GestureDetector(
                  onTap: hasData ? () => _priceC.text = '$suggested' : null,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Smart Price Suggestion', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 13)),
                        Text(
                          hasData
                            ? '${AppFormatters.currency(suggested.toDouble())} (${_priceSuggestion!['trend']} demand) • Tap to use'
                            : 'No market data yet. Set your own price.',
                          style: GoogleFonts.poppins(color: AppColors.primary, fontSize: 11),
                        ),
                      ])),
                    ]),
                  ),
                );
              }
            ),

            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                flex: 2,
                child: AppTextField(controller: _priceC, label: 'Price (₹)', hint: '0.00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.currency_rupee_rounded,
                  validator: AppValidators.positiveNumber),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: AppTextField(controller: _qtyC, label: 'Quantity', hint: '50',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.scale_outlined,
                  validator: AppValidators.positiveInt),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Unit', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: InputDecoration(
                        filled: true, fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                      ),
                      items: ['kg', 'liters', 'pieces', 'bundles', 'boxes', 'grams']
                        .map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 13))))
                        .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedUnit = val);
                      },
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 14),

            // Quality grade
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Quality Grade', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(children: ['A', 'B', 'C'].map((g) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: FilterChip(
                  label: Text('Grade $g'),
                  selected: _selectedGrade == g,
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  onSelected: (_) => setState(() => _selectedGrade = _selectedGrade == g ? null : g),
                ),
              )).toList()),
            ]),
            const SizedBox(height: 14),

            AppTextField(controller: _descC, label: 'Description (optional)',
              hint: 'Fresh from the farm, organically grown…',
              prefixIcon: Icons.description_outlined, maxLines: 3),
            const SizedBox(height: 14),

            AppTextField(controller: _areaC, label: 'Delivery Area',
              hint: 'Chennai, Tambaram, OMR',
              prefixIcon: Icons.map_outlined),
            const SizedBox(height: 14),

            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Delivery Radius: ${_radiusC.text} km', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
              Slider(
                value: double.tryParse(_radiusC.text) ?? 30,
                min: 5, max: 200, divisions: 39,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _radiusC.text = v.round().toString()),
              ),
            ]),
            const SizedBox(height: 24),

            AppButton(label: 'Publish Listing', icon: Icons.publish_rounded, isLoading: _saving, onPressed: _save),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class PickedImage {
  final XFile file;
  final Uint8List bytes;
  PickedImage({required this.file, required this.bytes});
}
