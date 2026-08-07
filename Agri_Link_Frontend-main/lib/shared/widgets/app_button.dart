import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

/// A premium gradient button with press-scale animation.
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? color;
  final IconData? icon;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.color,
    this.icon,
    this.width,
    this.height = 54,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _ctrl.reverse();
  void _onTapUp(TapUpDetails _) => _ctrl.forward();
  void _onTapCancel() => _ctrl.forward();

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? AppColors.primary;

    if (widget.isOutlined) {
      return SizedBox(
        width: widget.width ?? double.infinity,
        height: widget.height,
        child: OutlinedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: effectiveColor,
            side: BorderSide(color: effectiveColor, width: 1.8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _buildChild(Colors.transparent),
        ),
      );
    }

    return GestureDetector(
      onTapDown: widget.isLoading || widget.onPressed == null ? null : _onTapDown,
      onTapUp: widget.isLoading || widget.onPressed == null ? null : _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: widget.onPressed == null
                  ? [Colors.grey.shade300, Colors.grey.shade400]
                  : [AppColors.secondary, effectiveColor],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: widget.onPressed == null
                ? []
                : [
                    BoxShadow(
                      color: effectiveColor.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(child: _buildChild(Colors.white)),
        ),
      ),
    );
  }

  Widget _buildChild(Color textColor) {
    if (widget.isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          color: widget.isOutlined ? widget.color ?? AppColors.primary : Colors.white,
          strokeWidth: 2.5,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: widget.isOutlined ? (widget.color ?? AppColors.primary) : Colors.white),
          const SizedBox(width: 8),
        ],
        Text(
          widget.label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: widget.isOutlined ? (widget.color ?? AppColors.primary) : Colors.white,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
