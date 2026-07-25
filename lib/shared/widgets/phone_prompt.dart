import 'package:flutter/material.dart';

import '../services/app_state.dart';

/// Shows a phone-number dialog when the profile has no phone on file.
///
/// Call this at the top of any form's _save() before submitting a listing,
/// service, or hiring post.  The function:
///   - Does nothing (returns true) when the profile already has a phone.
///   - Shows the prompt when phone is empty.
///     • "Save & Continue" — saves to profile, returns true.
///     • "Skip for now"    — leaves phone empty, still returns true (allowed).
///     • Barrier dismiss / null — returns false (caller should abort save).
///
/// Returns `false` only when the dialog was dismissed by tapping outside —
/// meaning the user wants to exit. Callers should `return` (abort) on false.
Future<bool> showPhonePromptIfNeeded(
  BuildContext context,
  KoolanAppState state,
) async {
  final phone = state.profile?.phone ?? '';
  if (phone.trim().isNotEmpty) return true; // already have a phone

  final s = state.s;
  final ctrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
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
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: formKey,
              child: TextFormField(
                controller: ctrl,
                keyboardType: TextInputType.phone,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: s.wizardPhonePromptHint,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? s.wizardPhonePromptRequired
                        : null,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false), // skip
            child: Text(s.wizardPhonePromptSkip),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true); // save
              }
            },
            child: Text(s.wizardPhonePromptSave),
          ),
        ],
      );
    },
  );

  // result == null  → barrier dismissed (treat as cancel → abort save)
  if (result == null) {
    ctrl.dispose();
    return false;
  }

  // result == true  → user tapped Save & Continue
  if (result && ctrl.text.trim().isNotEmpty) {
    await state.submitProfileUpdate(
      displayName: state.profile?.displayName ?? '',
      bio: state.profile?.bio ?? '',
      phone: ctrl.text.trim(),
      city: state.profile?.city ?? '',
      preferredCategory: state.profile?.preferredCategory,
    );
  }

  ctrl.dispose();
  return true; // true (saved) or false (skipped) — both allow the form to proceed
}
