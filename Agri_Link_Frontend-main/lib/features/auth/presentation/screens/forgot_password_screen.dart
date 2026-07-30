import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

enum ResetStep { requestEmail, verifyOtp, resetPassword }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  ResetStep _currentStep = ResetStep.requestEmail;

  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey   = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final _emailC    = TextEditingController();
  final _otpC      = TextEditingController();
  final _passC     = TextEditingController();
  final _confirmC  = TextEditingController();

  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  String? _successMessage;

  int _resendCountdown = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void dispose() {
    _timer?.cancel();
    _emailC.dispose();
    _otpC.dispose();
    _passC.dispose();
    _confirmC.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendCountdown = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown <= 1) {
        timer.cancel();
        if (mounted) setState(() => _canResend = true);
      } else {
        if (mounted) setState(() => _resendCountdown--);
      }
    });
  }

  Future<void> _handleSendOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final remoteDs = ref.read(authRemoteDataSourceProvider);
      final msg = await remoteDs.forgotPassword(_emailC.text.trim());
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _successMessage = msg;
        _currentStep = ResetStep.verifyOtp;
      });
      _startResendTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('AppException(400): ', '');
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final remoteDs = ref.read(authRemoteDataSourceProvider);
      final isValid = await remoteDs.verifyOtp(_emailC.text.trim(), _otpC.text.trim());
      if (!mounted) return;
      if (isValid) {
        setState(() {
          _isLoading = false;
          _currentStep = ResetStep.resetPassword;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid OTP code. Please try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('AppException(401): ', '');
      });
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;
    if (_passC.text != _confirmC.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final remoteDs = ref.read(authRemoteDataSourceProvider);
      final msg = await remoteDs.resetPassword(
        _emailC.text.trim(),
        _otpC.text.trim(),
        _passC.text,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _successMessage = msg;
      });

      // Navigate to login after 1.5 seconds
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) context.go('/login');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('AppException(400): ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Password Reset', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Icon & Title ─────────────────────
              Center(
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _currentStep == ResetStep.requestEmail
                        ? Icons.lock_reset_rounded
                        : _currentStep == ResetStep.verifyOtp
                            ? Icons.mark_email_read_outlined
                            : Icons.key_outlined,
                    size: 36,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _currentStep == ResetStep.requestEmail
                    ? 'Forgot Password?'
                    : _currentStep == ResetStep.verifyOtp
                        ? 'Enter Verification Code'
                        : 'Set New Password',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                _currentStep == ResetStep.requestEmail
                    ? 'Enter your registered email address and we will send you a 6-digit OTP code.'
                    : _currentStep == ResetStep.verifyOtp
                        ? 'We sent a 6-digit code to ${_emailC.text}. Enter it below.'
                        : 'Your identity is verified. Enter your new account password.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // ── Step Indicator ──────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStepDot(ResetStep.requestEmail),
                  _buildStepLine(ResetStep.verifyOtp),
                  _buildStepDot(ResetStep.verifyOtp),
                  _buildStepLine(ResetStep.resetPassword),
                  _buildStepDot(ResetStep.resetPassword),
                ],
              ),
              const SizedBox(height: 28),

              // ── Messages ────────────────────────────────
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage!, style: GoogleFonts.poppins(fontSize: 12, color: Colors.red.shade800))),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              if (_successMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_successMessage!, style: GoogleFonts.poppins(fontSize: 12, color: Colors.green.shade800))),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              // ── Step 1: Request OTP Form ────────────────
              if (_currentStep == ResetStep.requestEmail)
                Form(
                  key: _emailFormKey,
                  child: Column(children: [
                    AppTextField(
                      controller: _emailC,
                      label: 'Email Address',
                      hint: 'your.name@example.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: AppValidators.email,
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Send OTP Code',
                      isLoading: _isLoading,
                      onPressed: _handleSendOtp,
                    ),
                  ]),
                ),

              // ── Step 2: Verify OTP Form ─────────────────
              if (_currentStep == ResetStep.verifyOtp)
                Form(
                  key: _otpFormKey,
                  child: Column(children: [
                    AppTextField(
                      controller: _otpC,
                      label: '6-Digit OTP Code',
                      hint: '123456',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.pin_outlined,
                      validator: (v) {
                        if (v == null || v.trim().length != 6) return 'Please enter 6-digit OTP code';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => setState(() {
                            _currentStep = ResetStep.requestEmail;
                            _errorMessage = null;
                          }),
                          child: Text('Change Email', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
                        ),
                        TextButton(
                          onPressed: _canResend ? _handleSendOtp : null,
                          child: Text(
                            _canResend ? 'Resend OTP' : 'Resend in ${_resendCountdown}s',
                            style: GoogleFonts.poppins(
                              color: _canResend ? AppColors.primary : AppColors.textHint,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: 'Verify OTP',
                      isLoading: _isLoading,
                      onPressed: _handleVerifyOtp,
                    ),
                  ]),
                ),

              // ── Step 3: Reset Password Form ─────────────
              if (_currentStep == ResetStep.resetPassword)
                Form(
                  key: _resetFormKey,
                  child: Column(children: [
                    AppTextField(
                      controller: _passC,
                      label: 'New Password',
                      hint: '••••••••',
                      obscureText: _obscurePass,
                      prefixIcon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        onPressed: () => setState(() => _obscurePass = !_obscurePass),
                      ),
                      validator: AppValidators.password,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _confirmC,
                      label: 'Confirm New Password',
                      hint: '••••••••',
                      obscureText: _obscureConfirm,
                      prefixIcon: Icons.lock_clock_outlined,
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please confirm your new password';
                        if (v != _passC.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Reset Password',
                      isLoading: _isLoading,
                      onPressed: _handleResetPassword,
                    ),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepDot(ResetStep step) {
    final isActive = _currentStep.index >= step.index;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.surfaceVariant,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isActive
            ? const Icon(Icons.check, size: 14, color: Colors.white)
            : Text('${step.index + 1}', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildStepLine(ResetStep step) {
    final isActive = _currentStep.index >= step.index;
    return Container(
      width: 40,
      height: 2,
      color: isActive ? AppColors.primary : AppColors.surfaceVariant,
    );
  }
}
