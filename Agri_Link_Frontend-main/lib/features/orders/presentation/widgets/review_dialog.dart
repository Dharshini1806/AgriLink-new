import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/orders_provider.dart';

class ReviewDialog extends ConsumerStatefulWidget {
  final String orderId;
  final String? productId;
  final String? sellerId;
  final String sellerName;

  const ReviewDialog({
    super.key,
    required this.orderId,
    this.productId,
    this.sellerId,
    required this.sellerName,
  });

  @override
  ConsumerState<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends ConsumerState<ReviewDialog> {
  double _rating = 5.0;
  final _commentC = TextEditingController();
  bool _submitting = false;
  final Set<String> _selectedTags = {};

  static const _positiveTags = [
    'Good Quality',
    'Excellent Product',
    'Value for Money',
    'Fast Delivery'
  ];

  static const _negativeTags = [
    'Poor Quality',
    'Not as Expected',
    'Damaged Product',
    'Wrong Product'
  ];

  @override
  void dispose() {
    _commentC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final ok = await ref.read(buyerOrdersProvider.notifier).submitReview(
          orderId: widget.orderId,
          productId: widget.productId,
          revieweeId: widget.sellerId,
          rating: _rating.round(),
          comment: _commentC.text.trim(),
          feedbackTags: _selectedTags.toList(),
        );
    setState(() => _submitting = false);

    if (mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully! 🎉'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit review. You may have already reviewed this order.'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tags = _rating >= 4 ? _positiveTags : _negativeTags;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Rate your order', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'How was your experience with ${widget.sellerName}?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: RatingBar.builder(
                initialRating: 5,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => const Icon(
                  Icons.star_rounded,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  setState(() {
                    _rating = rating;
                    _selectedTags.clear();
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentC,
              maxLines: 3,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Write a comment about the produce or delivery quality (optional)...',
                hintStyle: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 13),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select feedback tags:',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return ChoiceChip(
                  label: Text(
                    tag,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceVariant,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _submitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Submit', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
