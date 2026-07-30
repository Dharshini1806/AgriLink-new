import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/trust_badge.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _form     = GlobalKey<FormState>();
  final _nameC    = TextEditingController();
  final _phoneC   = TextEditingController();
  final _farmNameC= TextEditingController();
  final _farmDescC= TextEditingController();
  bool _editing   = false;
  bool _saving    = false;
  XFile? _avatar;
  Uint8List? _avatarBytes;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).value?.user;
    if (user != null) {
      _nameC.text     = user.name;
      _phoneC.text    = user.phone ?? '';
      _farmNameC.text = user.farmName ?? '';
      _farmDescC.text = user.farmDesc ?? '';
    }
  }

  @override
  void dispose() {
    _nameC.dispose(); _phoneC.dispose();
    _farmNameC.dispose(); _farmDescC.dispose(); super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _avatar = picked;
        _avatarBytes = bytes;
      });
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final formData = FormData.fromMap({
        'name':      _nameC.text.trim(),
        'phone':     _phoneC.text.trim(),
        'farm_name': _farmNameC.text.trim(),
        'farm_desc': _farmDescC.text.trim(),
      });
      if (_avatar != null && _avatarBytes != null) {
        formData.files.add(
          MapEntry(
            'avatar',
            MultipartFile.fromBytes(
              _avatarBytes!,
              filename: _avatar!.name,
            ),
          ),
        );
      }
      await ref.read(dioProvider).put(ApiEndpoints.userProfile, data: formData);
      await ref.read(authStateProvider.notifier).refreshUser();
      setState(() { _editing = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated ✓'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value?.user;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', height: 28, width: 28),
            const SizedBox(width: 8),
            const Text('Profile'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _editing = !_editing),
            child: Text(_editing ? 'Cancel' : 'Edit',
              style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(children: [
            // Avatar
            Center(
              child: Stack(children: [
                GestureDetector(
                  onTap: _editing ? _pickAvatar : null,
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    backgroundImage: _avatarBytes != null
                      ? MemoryImage(_avatarBytes!)
                      : (user.profileImg != null
                          ? CachedNetworkImageProvider(user.profileImg!) as ImageProvider
                          : null),
                    child: (_avatarBytes == null && user.profileImg == null)
                      ? Text(user.name.substring(0, 1).toUpperCase(),
                          style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.primary))
                      : null,
                  ),
                ),
                if (_editing) Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 30, height: 30,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Text(user.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 22)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(user.role.toUpperCase(),
                style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 11, letterSpacing: 1)),
            ),
            const SizedBox(height: 8),
            TrustBadge(trustScore: user.trustScore),
            const SizedBox(height: 24),

            // Stats row
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.5)),
              child: Row(children: [
                _StatItem('Member since', AppFormatters.date(user.createdAt)),
                _divider(),
                _StatItem('Trust Score', user.trustScore > 0 ? user.trustScore.toStringAsFixed(1) : 'New'),
                if (user.isSeller) ...[_divider(), _StatItem('Status', user.isActive ? 'Active' : 'Suspended')],
              ]),
            ),
            const SizedBox(height: 24),

            // Editable fields
            if (_editing) ...[
              AppTextField(controller: _nameC, label: 'Full Name', prefixIcon: Icons.person_outline_rounded, validator: AppValidators.name),
              const SizedBox(height: 14),
              AppTextField(controller: _phoneC, label: 'Phone', keyboardType: TextInputType.phone, prefixIcon: Icons.phone_outlined, validator: AppValidators.phone),
              const SizedBox(height: 14),
              if (user.isSeller) ...[
                AppTextField(controller: _farmNameC, label: 'Farm Name', prefixIcon: Icons.agriculture_rounded),
                const SizedBox(height: 14),
                AppTextField(controller: _farmDescC, label: 'About Your Farm', prefixIcon: Icons.info_outline_rounded, maxLines: 3),
                const SizedBox(height: 14),
              ],
              AppButton(label: 'Save Changes', isLoading: _saving, onPressed: _save),
            ] else ...[
              // Read-only info
              _InfoTile(Icons.email_outlined,   'Email',  user.email),
              _InfoTile(Icons.phone_outlined,   'Phone',  user.phone ?? 'Not added'),
              if (user.isSeller) ...[
                if (user.farmName != null && user.farmName!.isNotEmpty)
                  _InfoTile(Icons.agriculture_rounded, 'Farm', user.farmName!),
                if (user.farmDesc != null && user.farmDesc!.isNotEmpty)
                  _InfoTile(Icons.description_outlined, 'About', user.farmDesc!),
              ],
            ],

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),

            // Danger zone
            OutlinedButton.icon(
              onPressed: () => _showLogoutDialog(context),
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              label: Text('Sign Out', style: GoogleFonts.poppins(color: AppColors.error, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sign Out', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to sign out?', style: GoogleFonts.poppins()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go('/role-select');
            },
            child: Text('Sign Out', style: GoogleFonts.poppins(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  const _StatItem(this.label, this.value);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primary)),
      Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
    ]),
  );
}

Widget _divider() => Container(width: 1, height: 36, color: AppColors.border);

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoTile(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.surface, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border, width: 0.5)),
    child: Row(children: [
      Icon(icon, size: 18, color: AppColors.textHint),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint)),
        Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      ])),
    ]),
  );
}
