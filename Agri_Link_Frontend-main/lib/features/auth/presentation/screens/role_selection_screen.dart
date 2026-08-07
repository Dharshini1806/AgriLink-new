import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _slideCtrl;
  late final Animation<double> _pulse;
  late final Animation<Offset> _buyerSlide;
  late final Animation<Offset> _sellerSlide;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _buyerSlide = Tween<Offset>(
      begin: const Offset(-0.6, 0), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic)));

    _sellerSlide = Tween<Offset>(
      begin: const Offset(0.6, 0), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic)));

    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideCtrl, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background gradient ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.5),
                radius: 1.2,
                colors: [
                  Color(0xFFFFF3D6), // warm gold center
                  Color(0xFFFBF7F0), // cream outer
                ],
              ),
            ),
          ),

          // Decorative circles
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            top: 80, right: -30,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: 80, left: -50,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.06),
              ),
            ),
          ),

          // ── Main content ──────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),

                      // Logo
                      ScaleTransition(
                        scale: _pulse,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: const LinearGradient(
                              colors: [AppColors.secondary, AppColors.primary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('🌾', style: TextStyle(fontSize: 46)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        'AgriLink',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Farm-fresh produce, straight to you.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 44),

                      Text(
                        'How would you like to continue?',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHint,
                          letterSpacing: 0.3,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Buyer card
                      SlideTransition(
                        position: _buyerSlide,
                        child: _RoleCard(
                          emoji: '🛒',
                          title: 'Buy Fresh Produce',
                          subtitle: 'Discover farm-fresh fruits, vegetables & more from nearby farmers.',
                          gradientColors: [const Color(0xFF4A7C3F), AppColors.accent],
                          accentColor: AppColors.accent,
                          onTap: () => context.push('/login', extra: 'buyer'),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Seller card
                      SlideTransition(
                        position: _sellerSlide,
                        child: _RoleCard(
                          emoji: '🌾',
                          title: 'Sell My Harvest',
                          subtitle: 'List your produce, set fair prices and connect directly with buyers.',
                          gradientColors: [AppColors.secondary, AppColors.primary],
                          accentColor: AppColors.primary,
                          onTap: () => context.push('/login', extra: 'seller'),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Trust badge
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.verified_rounded, size: 14, color: AppColors.accent),
                        const SizedBox(width: 6),
                        Text(
                          'Trusted by 10,000+ farmers across India',
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textHint),
                        ),
                      ]),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final Color accentColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _hovered = true),
      onTapUp: (_) {
        setState(() => _hovered = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.diagonal3Values(
          _hovered ? 0.975 : 1.0,
          _hovered ? 0.975 : 1.0,
          1.0,
        ),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: widget.accentColor.withOpacity(0.2), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: widget.accentColor.withOpacity(_hovered ? 0.18 : 0.10),
              blurRadius: _hovered ? 20 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(children: [
          // Icon container with gradient
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.gradientColors.map((c) => c.withOpacity(0.15)).toList(),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: widget.accentColor.withOpacity(0.15)),
            ),
            child: Center(
              child: Text(widget.emoji, style: const TextStyle(fontSize: 30)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                widget.title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ]),
          ),
          const SizedBox(width: 10),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
          ),
        ]),
      ),
    );
  }
}
