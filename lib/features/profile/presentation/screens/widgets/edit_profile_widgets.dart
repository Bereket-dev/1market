part of '../edit_profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Edit-profile screen sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Avatar picker circle with camera badge.
class _AvatarPickerSection extends StatelessWidget {
  final String? avatarUrl;
  final String? displayName;
  final bool uploading;
  final VoidCallback onTap;
  final String changePhotoLabel;

  const _AvatarPickerSection({
    required this.avatarUrl,
    required this.displayName,
    required this.uploading,
    required this.onTap,
    required this.changePhotoLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 24, bottom: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: uploading ? null : onTap,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: cs.primary,
                  child: uploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : (avatarUrl != null
                          ? CachedCircularImage(imageUrl: avatarUrl!, radius: 44)
                          : CircleAvatar(
                              radius: 44,
                              backgroundColor: cs.primaryContainer,
                              child: Text(
                                (displayName ?? '?').isNotEmpty
                                    ? (displayName ?? '?')[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onPrimaryContainer,
                                ),
                              ),
                            )),
                ),
                if (!uploading)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.surface, width: 2),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.camera_alt_rounded,
                          size: 14, color: cs.onPrimary),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              changePhotoLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single labelled text field for the edit-profile form.
class _ProfileFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final AppStrings s;
  final int maxLines;
  final TextInputType keyboardType;
  final String? hint;
  final bool isRequired;
  final String? existingValue;

  const _ProfileFormField({
    required this.label,
    required this.controller,
    required this.s,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.hint,
    this.isRequired = false,
    this.existingValue,
  });

  @override
  Widget build(BuildContext context) {
    final hasExisting =
        existingValue != null && existingValue!.trim().isNotEmpty;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: hasExisting ? 'Cannot be removed once set' : null,
        helperStyle: const TextStyle(fontSize: 11),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      validator: isRequired
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return s.editProfileDisplayNameRequired;
              }
              return null;
            }
          : hasExisting
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number cannot be removed';
                  }
                  return null;
                }
              : null,
    );
  }
}
