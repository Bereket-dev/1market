import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/app_strings.dart';
import 'app_error.dart';

/// Maps exceptions to localized, user-safe strings.
///
/// Never returns [Object.toString], stack traces, URLs, or backend payloads.
class ErrorMapper {
  ErrorMapper._();

  static String userMessage(Object error, AppStrings s) {
    if (error is AuthException) {
      return _authMessage(error, s);
    }

    return switch (AppError.classify(error)) {
      AppErrorKind.network => s.errorNetwork,
      AppErrorKind.timeout => s.errorTimeout,
      AppErrorKind.sessionExpired => s.errorSessionExpired,
      AppErrorKind.unauthorized => s.errorUnauthorized,
      AppErrorKind.forbidden => s.errorForbidden,
      AppErrorKind.notFound => s.errorNotFound,
      AppErrorKind.validation => s.errorValidation,
      AppErrorKind.cancelled => s.errorCancelled,
      AppErrorKind.server => s.errorServer,
      AppErrorKind.unknown => s.errorUnknown,
    };
  }

  static String _authMessage(AuthException error, AppStrings s) {
    final lower = error.message.toLowerCase();

    if (lower.contains('email not confirmed') ||
        lower.contains('user not confirmed') ||
        lower.contains('confirmation required') ||
        lower.contains('verify your email') ||
        lower.contains('confirm your email')) {
      return s.authConfirmationRequired;
    }
    if (lower.contains('invalid login') ||
        lower.contains('invalid credentials') ||
        lower.contains('wrong password') ||
        lower.contains('invalid email or password')) {
      return s.errorInvalidCredentials;
    }
    if (lower.contains('user already registered') ||
        lower.contains('already been registered')) {
      return s.errorEmailAlreadyRegistered;
    }
    if (lower.contains('password') &&
        (lower.contains('least') ||
            lower.contains('weak') ||
            lower.contains('short'))) {
      return s.authPasswordMin;
    }
    if (lower.contains('access_denied') || lower.contains('access denied')) {
      return s.errorCancelled;
    }
    if (lower.contains('email') && lower.contains('external provider')) {
      return s.authFacebookEmailRequired;
    }

    return switch (AppError.classify(error)) {
      AppErrorKind.network => s.errorNetwork,
      AppErrorKind.timeout => s.errorTimeout,
      AppErrorKind.sessionExpired => s.errorSessionExpired,
      AppErrorKind.cancelled => s.errorCancelled,
      _ => s.errorAuthGeneric,
    };
  }
}
