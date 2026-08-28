part of '../edit_listing_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final ColorScheme cs;
  const _SectionLabel({required this.label, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface));
  }
}

class _RemoteImageTile extends StatelessWidget {
  final String url;
  final ColorScheme cs;
  final VoidCallback onRemove;
  const _RemoteImageTile(
      {required this.url, required this.cs, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedImageWidget(
            imageUrl: url,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorWidget: Container(
              width: 100,
              height: 100,
              color: cs.surfaceContainerHighest,
              child: Icon(Icons.broken_image_rounded,
                  color: cs.outline, size: 28),
            ),
          ),
        ),
        _RemoveButton(cs: cs, onRemove: onRemove),
      ],
    );
  }
}

class _LocalImageTile extends StatelessWidget {
  final String path;
  final ColorScheme cs;
  final VoidCallback onRemove;
  const _LocalImageTile(
      {required this.path, required this.cs, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(path),
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (context, error, _) => Container(
              width: 100,
              height: 100,
              color: cs.surfaceContainerHighest,
              child: Icon(Icons.broken_image_rounded,
                  color: cs.outline, size: 28),
            ),
          ),
        ),
        // "New" badge
        Positioned(
          bottom: 4,
          left: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(OnemarketAppStateScope.of(context).s.commonNew,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimary)),
          ),
        ),
        _RemoveButton(cs: cs, onRemove: onRemove),
      ],
    );
  }
}

class _RemoveButton extends StatelessWidget {
  final ColorScheme cs;
  final VoidCallback onRemove;
  const _RemoveButton({required this.cs, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 4,
      right: 4,
      child: GestureDetector(
        onTap: onRemove,
        child: Container(
          decoration:
              BoxDecoration(color: cs.error, shape: BoxShape.circle),
          padding: const EdgeInsets.all(4),
          child: Icon(Icons.close_rounded, size: 14, color: cs.onError),
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  final ColorScheme cs;
  final VoidCallback onTap;
  final String? label;
  const _AddTile({required this.cs, required this.onTap, this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: label != null ? 140 : 100,
        height: 100,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.5),
              style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_rounded,
                size: 28, color: cs.primary),
            if (label != null) ...[
              const SizedBox(height: 4),
              Text(label!,
                  style: TextStyle(
                      fontSize: 11,
                      color: cs.primary,
                      fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Spec definition — mirrors _SpecDef from the post wizard
// ─────────────────────────────────────────────────────────────────────────────

class _SpecDef {
  final String label;
  final List<String> keys;
  final List<String> labels;
  const _SpecDef({
    required this.label,
    required this.keys,
    required this.labels,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// _EditDropdownOrOther — dropdown with an "Other…" free-text fallback.
// Used for condition/status and spec fields in EditListingScreen.
// ─────────────────────────────────────────────────────────────────────────────

const String _editOtherSentinel = '__other__';

class _EditDropdownOrOther extends StatefulWidget {
  final String label;
  final String? currentValue;
  final List<String> options;
  final List<String> optionKeys;
  final String otherLabel;
  final String otherHint;
  final ValueChanged<String> onChanged;

  const _EditDropdownOrOther({
    required this.label,
    required this.currentValue,
    required this.options,
    required this.optionKeys,
    required this.otherLabel,
    required this.otherHint,
    required this.onChanged,
  });

  @override
  State<_EditDropdownOrOther> createState() => _EditDropdownOrOtherState();
}

class _EditDropdownOrOtherState extends State<_EditDropdownOrOther> {
  late TextEditingController _otherCtrl;
  bool _isOther = false;

  @override
  void initState() {
    super.initState();
    final inOptions = widget.currentValue == null ||
        widget.optionKeys.contains(widget.currentValue);
    _isOther =
        !inOptions && widget.currentValue != null && widget.currentValue!.isNotEmpty;
    _otherCtrl =
        TextEditingController(text: _isOther ? widget.currentValue : '');
  }

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    String? dropdownValue;
    if (_isOther) {
      dropdownValue = _editOtherSentinel;
    } else if (widget.currentValue != null &&
        widget.optionKeys.contains(widget.currentValue)) {
      dropdownValue = widget.currentValue;
    }

    final allKeys = [...widget.optionKeys, _editOtherSentinel];
    final allLabels = [...widget.options, widget.otherLabel];

    final decoration = InputDecoration(
      filled: true,
      fillColor: cs.surfaceContainerHighest,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: cs.onSurface),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: dropdownValue,
          dropdownColor: cs.surfaceContainerHighest,
          style: TextStyle(color: cs.onSurface, fontSize: 14),
          decoration: decoration,
          hint: Text(OnemarketAppStateScope.of(context).s.selectOrTypeHint,
              style: TextStyle(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
          items: List.generate(allKeys.length, (i) {
            final isOtherItem = allKeys[i] == _editOtherSentinel;
            return DropdownMenuItem<String>(
              value: allKeys[i],
              child: Text(
                allLabels[i],
                style: TextStyle(
                  color: isOtherItem
                      ? cs.onSurfaceVariant
                      : cs.onSurface,
                  fontStyle: isOtherItem
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
            );
          }),
          onChanged: (v) {
            if (v == _editOtherSentinel) {
              setState(() {
                _isOther = true;
                _otherCtrl.clear();
              });
              widget.onChanged('');
            } else if (v != null) {
              setState(() => _isOther = false);
              widget.onChanged(v);
            }
          },
        ),
        if (_isOther) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _otherCtrl,
            autofocus: true,
            style: TextStyle(color: cs.onSurface, fontSize: 14),
            decoration: decoration.copyWith(
              hintText: widget.otherHint,
              hintStyle: TextStyle(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
            ),
            onChanged: widget.onChanged,
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EditFreeTextField — labelled free-text field used for OTHERS specs
// ─────────────────────────────────────────────────────────────────────────────

class _EditFreeTextField extends StatefulWidget {
  final String label;
  final String initialValue;
  final String hint;
  final ValueChanged<String> onChanged;
  final ColorScheme cs;

  const _EditFreeTextField({
    required this.label,
    required this.initialValue,
    required this.hint,
    required this.onChanged,
    required this.cs,
  });

  @override
  State<_EditFreeTextField> createState() => _EditFreeTextFieldState();
}

class _EditFreeTextFieldState extends State<_EditFreeTextField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13, color: cs.onSurface),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _ctrl,
          onChanged: widget.onChanged,
          style: TextStyle(color: cs.onSurface),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle:
                TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
            filled: true,
            fillColor: cs.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
