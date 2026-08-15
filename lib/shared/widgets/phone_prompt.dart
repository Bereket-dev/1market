import 'package:flutter/material.dart';

import '../models/app_strings.dart';
import '../services/app_state.dart';

/// Shows a phone-number dialog when the profile has no phone on file.
///
/// Call this at the top of any form's _save() before submitting a listing,
/// service, or hiring post.  The function:
///   - Does nothing (returns true) when the profile already has a phone.
///   - Shows the prompt when phone is empty.
///     • "Save & Continue" — saves to profile, returns true.
///     • "Cancel" — returns false (caller should abort save).
///
/// Phone is required for all posts — there is no skip path.
Future<bool> showPhonePromptIfNeeded(
  BuildContext context,
  KoolanAppState state,
) async {
  final phone = state.profile?.phone ?? '';
  if (phone.trim().isNotEmpty) return true;

  final entered = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _PhonePromptDialog(strings: state.s),
  );

  // null → Cancel — abort save without touching the network.
  if (entered == null) return false;
  final trimmed = entered.trim();
  if (trimmed.isEmpty) return false;

  await state.submitProfileUpdate(
    displayName: state.profile?.displayName ?? '',
    bio: state.profile?.bio ?? '',
    phone: trimmed,
    city: state.profile?.city ?? '',
    preferredCategory: state.profile?.preferredCategory,
  );
  return true;
}

/// Owns its [TextEditingController] so dispose runs after the route is gone,
/// avoiding `_dependents.isEmpty` assertions on cancel.
class _PhonePromptDialog extends StatefulWidget {
  const _PhonePromptDialog({required this.strings});

  final AppStrings strings;

  @override
  State<_PhonePromptDialog> createState() => _PhonePromptDialogState();
}

class _PhonePromptDialogState extends State<_PhonePromptDialog> {
  late final TextEditingController _ctrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        s.wizardPhonePromptTitle,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.wizardPhonePromptBody,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _ctrl,
              keyboardType: TextInputType.phone,
              autofocus: true,
              decoration: InputDecoration(
                hintText: s.wizardPhonePromptHint,
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? s.wizardPhonePromptRequired
                  : null,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // null → cancel
          child: Text(s.commonCancel),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop(_ctrl.text.trim());
            }
          },
          child: Text(s.wizardPhonePromptSave),
        ),
      ],
    );
  }
}
