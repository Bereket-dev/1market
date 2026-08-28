part of '../service_edit_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Form-level widgets for ServiceEditScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Single-image picker row for a service cover photo.
/// Shows the new local image, the existing remote image, or an add-tile.
class _ServiceImagePicker extends StatelessWidget {
  final List<String> existingImageUrls;
  final List<String> newImagePaths;
  final VoidCallback onPick;
  final VoidCallback onRemoveExisting;
  final VoidCallback onRemoveNew;

  const _ServiceImagePicker({
    required this.existingImageUrls,
    required this.newImagePaths,
    required this.onPick,
    required this.onRemoveExisting,
    required this.onRemoveNew,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (newImagePaths.isNotEmpty) {
      return SizedBox(
        height: 120,
        child: Row(children: [
          _LocalImageTile(
              path: newImagePaths.first, cs: cs, onRemove: onRemoveNew),
        ]),
      );
    }
    if (existingImageUrls.isNotEmpty) {
      return SizedBox(
        height: 120,
        child: Row(children: [
          _RemoteImageTile(
              url: existingImageUrls.first,
              cs: cs,
              onRemove: onRemoveExisting),
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

/// Styled [TextFormField] used for every field in [ServiceEditScreen].
class _ServiceFormField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _ServiceFormField({
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

/// Labelled availability toggle row (schedule icon + label + value text + switch).
class _AvailabilityToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AvailabilityToggle({
    required this.value,
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
          child: Text(s.servicesAvailabilityLabel,
              style: TextStyle(fontSize: 15, color: cs.onSurface)),
        ),
        Text(
          value ? s.servicesAvailable : s.servicesUnavailable,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: value ? cs.primary : cs.error),
        ),
        Switch.adaptive(value: value, onChanged: onChanged),
      ],
    );
  }
}
