part of '../post_wizard_screen.dart';

class _DropdownOrOther extends StatefulWidget {
  final String label;
  final bool isRequired;
  final String? currentValue;
  final List<String> options; // translated display strings
  final List<String> optionKeys; // internal keys (same length as options)
  final String otherLabel; // translated "Other…"
  final String otherHint; // translated placeholder for free-text
  final String? requiredError;
  final ValueChanged<String> onChanged;

  const _DropdownOrOther({
    required this.label,
    required this.isRequired,
    required this.currentValue,
    required this.options,
    required this.optionKeys,
    required this.otherLabel,
    required this.otherHint,
    required this.onChanged,
    this.requiredError,
  });

  @override
  State<_DropdownOrOther> createState() => _DropdownOrOtherState();
}

class _DropdownOrOtherState extends State<_DropdownOrOther> {
  late TextEditingController _otherCtrl;
  bool _isOther = false;

  @override
  void initState() {
    super.initState();
    // If the current value is not in the known option keys it was typed — restore
    final inOptions = widget.currentValue == null ||
        widget.optionKeys.contains(widget.currentValue);
    _isOther = !inOptions && widget.currentValue!.isNotEmpty;
    _otherCtrl = TextEditingController(text: _isOther ? widget.currentValue : '');
  }

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = OnemarketAppStateScope.of(context).s;

    // Resolve the dropdown value: if _isOther use the sentinel, otherwise use
    // the currentValue if it's in the known keys (else null = no selection).
    String? dropdownValue;
    if (_isOther) {
      dropdownValue = _otherSentinel;
    } else if (widget.currentValue != null &&
        widget.optionKeys.contains(widget.currentValue)) {
      dropdownValue = widget.currentValue;
    }

    final allOptionKeys = [...widget.optionKeys, _otherSentinel];
    final allOptionLabels = [...widget.options, widget.otherLabel];

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: cs.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.error),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        _FieldLabel(
          label: widget.label,
          isRequired: widget.isRequired,
          requiredSuffix: s.wizardRequired,
        ),
        const SizedBox(height: 8),

        // Dropdown
        DropdownButtonFormField<String>(
          initialValue: dropdownValue,
          dropdownColor: cs.surfaceContainerHighest,
          style: TextStyle(color: cs.onSurface, fontSize: 14),
          decoration: inputDecoration,
          validator: widget.isRequired
              ? (v) {
                  if (v == null) return widget.requiredError;
                  if (v == _otherSentinel && _otherCtrl.text.trim().isEmpty) {
                    return widget.requiredError;
                  }
                  return null;
                }
              : null,
          items: List.generate(allOptionKeys.length, (i) {
            final key = allOptionKeys[i];
            final lbl = allOptionLabels[i];
            final isOtherItem = key == _otherSentinel;
            return DropdownMenuItem<String>(
              value: key,
              child: Text(
                lbl,
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
            if (v == _otherSentinel) {
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

        // "Other" free-text field — slides in when sentinel is selected
        if (_isOther) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _otherCtrl,
            autofocus: true,
            style: TextStyle(color: cs.onSurface, fontSize: 14),
            decoration: inputDecoration.copyWith(
              hintText: widget.otherHint,
              hintStyle: TextStyle(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
            ),
            validator: widget.isRequired
                ? (v) => (v == null || v.trim().isEmpty)
                    ? widget.requiredError
                    : null
                : null,
            onChanged: (v) => widget.onChanged(v),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FieldLabel — label + optional required asterisk
// ─────────────────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool isRequired;
  final String requiredSuffix;
  const _FieldLabel({
    required this.label,
    required this.isRequired,
    required this.requiredSuffix,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: cs.onSurface)),
        if (isRequired)
          Text(requiredSuffix,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: cs.error)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TextInputField — reusable labelled TextFormField
// ─────────────────────────────────────────────────────────────────────────────

class _TextInputField extends StatelessWidget {
  final String label;
  final String initial;
  final String hint;
  final bool isRequired;
  final ValueChanged<String> onChanged;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int maxLines;

  const _TextInputField({
    required this.label,
    required this.initial,
    required this.hint,
    required this.isRequired,
    required this.onChanged,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = OnemarketAppStateScope.of(context).s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(
          label: label,
          isRequired: isRequired,
          requiredSuffix: s.wizardRequired,
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initial,
          onChanged: onChanged,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(color: cs.onSurface, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
            filled: true,
            fillColor: cs.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.error),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 1 — Basic Info
// Category dropdown + condition dropdown + title + price
// ─────────────────────────────────────────────────────────────────────────────

