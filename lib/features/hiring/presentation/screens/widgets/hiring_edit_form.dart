part of '../hiring_edit_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Form-level widgets for HiringEditScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Single-image picker row for a hiring post cover photo.
class _HiringImagePicker extends StatelessWidget {
  final String existingImageUrl;
  final String? newImagePath;
  final VoidCallback onPick;
  final VoidCallback onRemoveExisting;
  final VoidCallback onRemoveNew;

  const _HiringImagePicker({
    required this.existingImageUrl,
    required this.newImagePath,
    required this.onPick,
    required this.onRemoveExisting,
    required this.onRemoveNew,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (newImagePath != null) {
      return SizedBox(
        height: 120,
        child: Row(children: [
          _LocalImageTile(
              path: newImagePath!, cs: cs, onRemove: onRemoveNew),
        ]),
      );
    }
    if (existingImageUrl.isNotEmpty) {
      return SizedBox(
        height: 120,
        child: Row(children: [
          _RemoteImageTile(
              url: existingImageUrl, cs: cs, onRemove: onRemoveExisting),
          const SizedBox(width: 8),
          _AddTile(cs: cs, onTap: onPick),
        ]),
      );
    }
    return SizedBox(
      height: 120,
      child: Row(children: [
        _AddTile(cs: cs, label: OnemarketAppStateScope.of(context).s.addCoverPhotoLabel, onTap: onPick),
      ]),
    );
  }
}

/// Styled [TextFormField] for every text field in [HiringEditScreen].
class _HiringFormField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _HiringFormField({
    required this.label,
    required this.hint,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      validator: validator,
    );
  }
}

/// Labelled open/closed toggle row (schedule icon + label + value text + switch).
class _HiringStatusToggle extends StatelessWidget {
  final bool isOpen;
  final ValueChanged<bool> onChanged;

  const _HiringStatusToggle({
    required this.isOpen,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s  = OnemarketAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        const Icon(Icons.schedule),
        const SizedBox(width: 10),
        Expanded(
          child: Text(s.hiringStatusLabel,
              style: TextStyle(fontSize: 15, color: cs.onSurface)),
        ),
        Text(
          isOpen ? s.hiringStatusOpen : s.hiringStatusClosed,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isOpen ? cs.primary : cs.error),
        ),
        Switch.adaptive(value: isOpen, onChanged: onChanged),
      ],
    );
  }
}
