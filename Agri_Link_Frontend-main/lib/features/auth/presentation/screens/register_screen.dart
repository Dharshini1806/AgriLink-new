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

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form        = GlobalKey<FormState>();
  final _nameC       = TextEditingController();
  final _emailC      = TextEditingController();
  final _phoneC      = TextEditingController();
  final _passC       = TextEditingController();
  final _confirmC    = TextEditingController();
  bool _obscure      = true;
  bool _gettingLoc   = false;
  double? _lat, _lng;

  @override
  void dispose() {
    _nameC.dispose(); _emailC.dispose(); _phoneC.dispose();
    _passC.dispose(); _confirmC.dispose(); super.dispose();
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
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registration Failed',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textPrimary.withOpacity(0.85),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              ref.read(authStateProvider.notifier).clearError();
            },
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(
                Icons.close_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(isSeller ? 'Seller Registration' : 'Create Account'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (errorMessage != null && errorMessage.isNotEmpty)
              _buildErrorBanner(errorMessage),

            if (isSeller) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    'Your location helps buyers find produce near them.',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primary),
                  )),
                ]),
              ),
              const SizedBox(height: 20),
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
                icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
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
            const SizedBox(height: 20),

            // Location
            InkWell(
              onTap: _gettingLoc ? null : _captureLocation,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: _lat != null ? AppColors.success : AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                  color: _lat != null ? AppColors.success.withOpacity(0.06) : AppColors.surfaceVariant,
                ),
                child: Row(children: [
                  Icon(
                    _lat != null ? Icons.location_on_rounded : Icons.location_off_outlined,
                    color: _lat != null ? AppColors.success : AppColors.textHint,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _gettingLoc
                    ? Text('Getting location...', style: GoogleFonts.poppins(color: AppColors.primary))
                    : _lat != null
                      ? Text('📍 Location captured (${_lat!.toStringAsFixed(3)}, ${_lng!.toStringAsFixed(3)})',
                          style: GoogleFonts.poppins(color: AppColors.success, fontSize: 13))
                      : Text(isSeller ? 'Tap to capture farm location' : 'Tap to capture your location',
                          style: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 13))),
                  if (_gettingLoc) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                ]),
              ),
            ),
            const SizedBox(height: 28),
            AppButton(label: 'Create Account', isLoading: isLoading, onPressed: _submit),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Already registered? ', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
              GestureDetector(
                onTap: () => context.pushReplacement('/login', extra: widget.role),
                child: Text('Sign In', style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}
