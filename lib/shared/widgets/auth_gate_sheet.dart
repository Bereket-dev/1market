import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/errors/app_error.dart';
import '../../core/errors/error_mapper.dart';
import '../services/app_state.dart';
part 'widgets/auth_gate_logos.dart';
part 'widgets/auth_gate_content.dart';

// ─────────────────────────────────────────────────────────────────────────────
// showAuthGateSheet
//
// Soft-gate modal bottom sheet for every auth-gated action post first-install.
//
// Layout (new design):
//   • Drag handle
//   • Continue with Google   → completes auth inline, sheet closes
//   • Continue with Facebook → completes auth inline (stub snackbar for now)
//   • Log in with Email      → navigates to AuthScreen
//   • "Don't have an account? Create one now" text link → AuthScreen sign-up
//
// No logo, no lock icon, no body copy — clean action-focused sheet.
// ─────────────────────────────────────────────────────────────────────────────

enum AuthGateReason {
  post,
  save,
  messages,
  notifications,
  profile,
  apply,
  chat,
  requestCall,
  generic,
}

Future<void> showAuthGateSheet(
  BuildContext context, {
  AuthGateReason reason = AuthGateReason.generic,
}) {
  return showModalBottomSheet<void>(
    context: context,
    clipBehavior: Clip.antiAlias,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    barrierColor: Colors.black54,
    isDismissible: true,
    enableDrag: true,
    builder: (ctx) => _AuthGateSheetContent(reason: reason),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
