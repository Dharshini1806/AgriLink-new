import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _form    = GlobalKey<FormState>();
  final _emailC  = TextEditingController();
  final _passC   = TextEditingController();
  bool _obscure  = true;
  late final AnimationController _headerCtrl;
  late final Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerCtrl.forward();
  }

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    _headerCtrl.dispose();
    super.dispose();
  }

  void _clearErrorIfPresent() {
    final state = ref.read(authStateProvider).value;
    if (state?.error != null) {
      ref.read(authStateProvider.notifier).clearError();
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref.read(authStateProvider.notifier).login(
        _emailC.text.trim(), _passC.text);
  }

  Widget _buildErrorBanner(String error) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      builder: (ctx, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * -8), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1.2),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Authentication Failed',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.error)),
              const SizedBox(height: 3),
              Text(error,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
            ]),
          ),
          GestureDetector(
            onTap: () => ref.read(authStateProvider.notifier).clearError(),
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.close_rounded, color: AppColors.textHint, size: 18),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;
    final errorMessage = authState.value?.error;
    final isSeller = widget.role == 'seller';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // ── Curved header ──────────────────────────────────────────────────
        FadeTransition(
          opacity: _headerFade,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isSeller
                    ? [AppColors.secondary, AppColors.primary]
                    : [const Color(0xFF7BA05B), AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                    onPressed: () => context.pop(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSeller ? '👨‍🌾 Welcome, Farmer!' : '👋 Welcome back!',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sign in to continue to AgriLink',
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
                  ),
                ]),
              ),
            ),
          ),
        ),

        // ── Form ──────────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Form(
              key: _form,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (errorMessage != null && errorMessage.isNotEmpty)
                  _buildErrorBanner(errorMessage),

                AppTextField(
                  controller: _emailC,
                  label: 'Email Address',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: AppValidators.email,
                  onChanged: (_) => _clearErrorIfPresent(),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _passC,
                  label: 'Password',
                  hint: '••••••••',
                  obscureText: _obscure,
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textHint,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Password is required' : null,
                  onChanged: (_) => _clearErrorIfPresent(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: Text(
                      'Forgot password?',
                      style: GoogleFonts.poppins(
                          color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: 'Sign In',
                  isLoading: isLoading,
                  onPressed: _submit,
                  icon: Icons.login_rounded,
                ),
                const SizedBox(height: 24),

                // Divider
                Row(children: [
                  Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or', style: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 12)),
                  ),
                  Expanded(child: Divider(color: AppColors.border)),
                ]),

                const SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(
                    "Don't have an account? ",
                    style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () => context.pushReplacement('/register', extra: widget.role),
                    child: Text(
                      'Register',
                      style: GoogleFonts.poppins(
                          color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
