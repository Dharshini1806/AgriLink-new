import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String role;
  const RegisterScreen({super.key, required this.role});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _form        = GlobalKey<FormState>();
  final _nameC       = TextEditingController();
  final _emailC      = TextEditingController();
  final _phoneC      = TextEditingController();
  final _passC       = TextEditingController();
  final _confirmC    = TextEditingController();
  bool _obscure      = true;
  bool _gettingLoc   = false;
  double? _lat, _lng;
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
    _nameC.dispose(); _emailC.dispose(); _phoneC.dispose();
    _passC.dispose(); _confirmC.dispose(); _headerCtrl.dispose();
    super.dispose();
  }

  void _clearErrorIfPresent() {
    final state = ref.read(authStateProvider).value;
    if (state?.error != null) {
      ref.read(authStateProvider.notifier).clearError();
    }
  }

  Future<void> _captureLocation() async {
    setState(() => _gettingLoc = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services disabled');
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) throw Exception('Permission denied');
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      setState(() { _lat = pos.latitude; _lng = pos.longitude; });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _gettingLoc = false);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_passC.text != _confirmC.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: AppColors.error),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    await ref.read(authStateProvider.notifier).register(
      name: _nameC.text.trim(),
      email: _emailC.text.trim(),
      password: _passC.text,
      role: widget.role,
      phone: _phoneC.text.trim().isEmpty ? null : _phoneC.text.trim(),
      latitude: _lat, longitude: _lng,
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
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
            color: AppColors.error.withOpacity(0.12), shape: BoxShape.circle),
          child: const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Registration Failed',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.error)),
            const SizedBox(height: 3),
            Text(error,
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;
    final errorMessage = authState.value?.error;
    final isSeller  = widget.role == 'seller';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // ── Curved gradient header ──────────────────────────────────────
        FadeTransition(
          opacity: _headerFade,
          child: Container(
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
                    blurRadius: 20, offset: const Offset(0, 8)),
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
                    isSeller ? '🌾 Join as a Farmer' : '🛒 Create Account',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSeller
                        ? 'Start selling your harvest to nearby buyers'
                        : 'Get farm-fresh produce delivered to you',
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                ]),
              ),
            ),
          ),
        ),

        // ── Form ────────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Form(
              key: _form,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (errorMessage != null && errorMessage.isNotEmpty)
                  _buildErrorBanner(errorMessage),

                if (isSeller) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.secondary.withOpacity(0.25)),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on_rounded,
                            color: AppColors.secondary, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your location helps buyers find produce near them.',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.primary, height: 1.4),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 18),
                ],

                AppTextField(
                  controller: _nameC,
                  label: 'Full Name',
                  hint: 'Ravi Kumar',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: AppValidators.name,
                  onChanged: (_) => _clearErrorIfPresent(),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _emailC,
                  label: 'Email Address',
                  hint: 'you@email.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: AppValidators.email,
                  onChanged: (_) => _clearErrorIfPresent(),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _phoneC,
                  label: 'Phone (optional)',
                  hint: '+91 9999999999',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: AppValidators.phone,
                  onChanged: (_) => _clearErrorIfPresent(),
                ),
                const SizedBox(height: 14),
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
                  validator: AppValidators.password,
                  onChanged: (_) => _clearErrorIfPresent(),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _confirmC,
                  label: 'Confirm Password',
                  hint: '••••••••',
                  obscureText: _obscure,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: (v) => v == null || v.isEmpty ? 'Please confirm password' : null,
                  onChanged: (_) => _clearErrorIfPresent(),
                ),
                const SizedBox(height: 18),

                // ── Location capture ───────────────────────────────────
                GestureDetector(
                  onTap: _gettingLoc ? null : _captureLocation,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _lat != null ? AppColors.accent : AppColors.border,
                        width: _lat != null ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      color: _lat != null
                          ? AppColors.accent.withOpacity(0.06)
                          : AppColors.surfaceVariant,
                      boxShadow: _lat != null
                          ? [BoxShadow(color: AppColors.accent.withOpacity(0.12),
                              blurRadius: 8, offset: const Offset(0, 3))]
                          : [],
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (_lat != null ? AppColors.accent : AppColors.textHint).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _lat != null ? Icons.location_on_rounded : Icons.location_off_outlined,
                          color: _lat != null ? AppColors.accent : AppColors.textHint,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _gettingLoc
                          ? Text('Getting your location…',
                              style: GoogleFonts.poppins(color: AppColors.primary, fontSize: 13))
                          : _lat != null
                            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Location captured!',
                                  style: GoogleFonts.poppins(
                                    color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 13)),
                                Text('${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}',
                                  style: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 11)),
                              ])
                            : Text(
                                isSeller ? 'Tap to capture farm location' : 'Tap to add your location',
                                style: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 13)),
                      ),
                      if (_gettingLoc)
                        const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                      if (!_gettingLoc && _lat == null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('GPS',
                            style: GoogleFonts.poppins(
                                color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                    ]),
                  ),
                ),

                const SizedBox(height: 28),
                AppButton(
                  label: 'Create Account',
                  isLoading: isLoading,
                  onPressed: _submit,
                  icon: Icons.person_add_rounded,
                ),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Already registered? ',
                    style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14)),
                  GestureDetector(
                    onTap: () => context.pushReplacement('/login', extra: widget.role),
                    child: Text('Sign In',
                      style: GoogleFonts.poppins(
                          color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
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
