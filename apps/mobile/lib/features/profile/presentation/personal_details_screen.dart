import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/routes.dart';
import '../../auth/application/session_controller.dart';
import '../application/profile_overview_controller.dart';
import '../data/personal_details_repository.dart';

/// Edit profile: photo, full name, phone and bio.
///
/// Route: `/settings/personal-details`. Study goals and availability have
/// their own screens, linked from the bottom of this page.
class PersonalDetailsScreen extends ConsumerWidget {
  const PersonalDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(personalDetailsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: switch (state) {
          AsyncData(:final value) => _Form(details: value),
          AsyncError(:final error) => Center(
            child: ErrorBanner(
              message: ErrorMessages.of(error),
              onRetry: () => ref.invalidate(personalDetailsProvider),
            ),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.details});

  final PersonalDetails details;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  late final _name = TextEditingController(text: widget.details.fullName);
  late final _phone = TextEditingController(text: widget.details.phone ?? '');
  late final _bio = TextEditingController(text: widget.details.bio ?? '');
  late String? _avatarUrl = widget.details.avatarUrl;
  bool _saving = false;
  bool _photoBusy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _bio.dispose();
    super.dispose();
  }

  /// The Profile page and the session show the name, so refresh them too.
  Future<void> _refreshOthers() async {
    ref.invalidate(profileOverviewControllerProvider);
    await ref.read(sessionProvider.notifier).refreshOrThrow();
  }

  Future<void> _pickPhoto() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (photo == null) return; // the student closed the gallery
    setState(() {
      _photoBusy = true;
      _error = null;
    });
    try {
      final saved = await ref
          .read(personalDetailsRepositoryProvider)
          .uploadPhoto(await photo.readAsBytes(), photo.name);
      if (mounted) setState(() => _avatarUrl = saved.avatarUrl);
    } catch (e) {
      if (mounted) setState(() => _error = ErrorMessages.of(e));
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _removePhoto() async {
    setState(() {
      _photoBusy = true;
      _error = null;
    });
    try {
      await ref.read(personalDetailsRepositoryProvider).removePhoto();
      if (mounted) setState(() => _avatarUrl = null);
    } catch (e) {
      if (mounted) setState(() => _error = ErrorMessages.of(e));
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter your name.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(personalDetailsRepositoryProvider)
          .save(
            fullName: name,
            phone: _phone.text.trim(),
            bio: _bio.text.trim(),
          );
      await _refreshOthers();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved')));
      context.canPop() ? context.pop() : context.go(AppRoutes.settings);
    } catch (e) {
      if (mounted) setState(() => _error = ErrorMessages.of(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _avatarUrl;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Center(
          child: CircleAvatar(
            radius: 52,
            backgroundColor: AppColors.amber,
            foregroundImage: url == null ? null : NetworkImage(url),
            child: _photoBusy
                ? const CircularProgressIndicator()
                : Text(Formatters.initials(_name.text)),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _photoBusy ? null : _pickPhoto,
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(url == null ? 'Add photo' : 'Change photo'),
            ),
            if (url != null)
              TextButton(
                onPressed: _photoBusy ? null : _removePhoto,
                child: const Text('Remove'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Full name',
          controller: _name,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Phone (optional)',
          controller: _phone,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'About me (optional)',
          hint: 'Your school, goals or favourite topic',
          controller: _bio,
          maxLines: 4,
        ),
        if (widget.details.email != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Email: ${widget.details.email}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(_error!, style: const TextStyle(color: AppColors.error)),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppButton(label: 'Save changes', isLoading: _saving, onPressed: _save),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Change study setup',
          variant: AppButtonVariant.ghost,
          onPressed: () => context.push(AppRoutes.settingsEditProfilePath()),
        ),
      ],
    );
  }
}
