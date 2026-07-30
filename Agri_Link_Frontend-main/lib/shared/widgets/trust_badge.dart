import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class TrustBadge extends StatelessWidget {
  final double trustScore;
  final int? reviewCount;
  final bool compact;

  const TrustBadge({super.key, required this.trustScore, this.reviewCount, this.compact = false});

  Color get _color {
    if ((reviewCount ?? 0) < 3) return AppColors.textHint;
    if (trustScore >= 4.5) return const Color(0xFF2E7D32);
    if (trustScore >= 3.5) return AppColors.primary;
    if (trustScore >= 2.5) return AppColors.warning;
    return AppColors.error;
  }

  String get _label {
    if ((reviewCount ?? 0) < 3) return 'New';
    if (trustScore >= 4.5) return 'Trusted';
    if (trustScore >= 3.5) return 'Good';
    if (trustScore >= 2.5) return 'Fair';
    return 'New';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: compact
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          (reviewCount ?? 0) < 3 ? Icons.fiber_new_rounded : Icons.verified_rounded,
          color: _color, size: compact ? 12 : 14,
        ),
        const SizedBox(width: 4),
        if ((reviewCount ?? 0) >= 3) ...[
          Text(
            trustScore.toStringAsFixed(1),
            style: GoogleFonts.poppins(fontSize: compact ? 10 : 12, fontWeight: FontWeight.w600, color: _color),
          ),
          const SizedBox(width: 2),
        ],
        Text(_label,
          style: GoogleFonts.poppins(fontSize: compact ? 10 : 12, fontWeight: FontWeight.w500, color: _color)),
      ]),
    );
  }
}
