import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// High-level error categories used for safe UI messaging and reporting.
enum AppErrorKind {
  network,
  timeout,
  unauthorized,
  sessionExpired,
  forbidden,
  notFound,
  validation,
  cancelled,
  server,
  unknown,
}

/// Classifies exceptions without exposing raw messages to the UI.
class AppError {
  AppError._();

  static AppErrorKind classify(Object error) {
    if (error is TimeoutException) return AppErrorKind.timeout;
    if (error is SocketException) return AppErrorKind.network;
    if (error is HttpException) return AppErrorKind.network;
    if (error is HandshakeException) return AppErrorKind.network;
    if (error is TlsException) return AppErrorKind.network;

    if (error is AuthException) {
      return _fromAuthMessage(error.message, statusCode: error.statusCode);
    }

    if (error is PostgrestException) {
      final code = error.code;
      if (code == '401' || code == 'PGRST301') {
        return AppErrorKind.sessionExpired;
      }
      if (code == '403') return AppErrorKind.forbidden;
      if (code == '404' || code == 'PGRST116') return AppErrorKind.notFound;
      if (code == '23505' || code == '23503' || code == '22P02') {
        return AppErrorKind.validation;
      }
      return AppErrorKind.server;
    }

    if (error is StorageException) {
      final status = error.statusCode;
      if (status == '401') return AppErrorKind.sessionExpired;
      if (status == '403') return AppErrorKind.forbidden;
      if (status == '404') return AppErrorKind.notFound;
      return AppErrorKind.server;
    }

    if (error is FunctionException) {
      if (error.status == 401) return AppErrorKind.sessionExpired;
      if (error.status == 403) return AppErrorKind.forbidden;
      if (error.status == 404) return AppErrorKind.notFound;
      if (error.status == 0) return AppErrorKind.network;
      if (error.status >= 500) return AppErrorKind.server;
      return AppErrorKind.server;
    }

    if (error is PlatformException) {
      final code = (error.code).toLowerCase();
      final msg = (error.message ?? '').toLowerCase();
      if (code.contains('network') ||
          msg.contains('network') ||
          msg.contains('socket') ||
          msg.contains('failed host lookup')) {
        return AppErrorKind.network;
      }
      if (code.contains('canceled') ||
          code.contains('cancelled') ||
          msg.contains('cancel')) {
        return AppErrorKind.cancelled;
      }
    }

    final text = error.toString().toLowerCase();
    if (_looksLikeSessionExpired(text)) return AppErrorKind.sessionExpired;
    if (_looksLikeUnauthorized(text)) return AppErrorKind.unauthorized;
    if (text.contains('timeout') || text.contains('timed out')) {
      return AppErrorKind.timeout;
    }
    if (text.contains('socket') ||
        text.contains('network') ||
        text.contains('connection') ||
        text.contains('failed host lookup') ||
        text.contains('connection refused') ||
        text.contains('connection reset')) {
      return AppErrorKind.network;
    }
    if (text.contains('cancel')) return AppErrorKind.cancelled;

    return AppErrorKind.unknown;
  }

  /// True when this failure should be queued for offline retry.
  static bool isTransientNetwork(Object error) {
    final kind = classify(error);
    return kind == AppErrorKind.network || kind == AppErrorKind.timeout;
  }

  /// True when the user must re-authenticate.
  static bool requiresReauth(Object error) {
    final kind = classify(error);
    return kind == AppErrorKind.sessionExpired ||
        kind == AppErrorKind.unauthorized;
  }

  static AppErrorKind _fromAuthMessage(String message, {String? statusCode}) {
    final lower = message.toLowerCase();
    final code = statusCode ?? '';
    if (code == '401' || _looksLikeSessionExpired(lower)) {
      return AppErrorKind.sessionExpired;
    }
    if (code == '403' || lower.contains('forbidden')) {
      return AppErrorKind.forbidden;
    }
    if (lower.contains('invalid login') ||
        lower.contains('invalid credentials') ||
        lower.contains('wrong password') ||
        lower.contains('email not confirmed') ||
        lower.contains('user not confirmed') ||
        lower.contains('user already registered') ||
        lower.contains('password') ||
        lower.contains('email')) {
      return AppErrorKind.validation;
    }
    if (lower.contains('access_denied') || lower.contains('access denied')) {
      return AppErrorKind.cancelled;
    }
    if (_looksLikeUnauthorized(lower)) return AppErrorKind.unauthorized;
    return AppErrorKind.unauthorized;
  }

  static bool _looksLikeSessionExpired(String lower) {
    return lower.contains('jwt expired') ||
        lower.contains('session expired') ||
        lower.contains('refresh_token') ||
        lower.contains('refresh token') ||
        lower.contains('token is expired') ||
        lower.contains('invalid claim') ||
        lower.contains('not authenticated') ||
        lower.contains('no session');
  }

  static bool _looksLikeUnauthorized(String lower) {
    return lower.contains('unauthorized') ||
        lower.contains('401') ||
        lower.contains('invalid jwt') ||
        lower.contains('auth session missing');
  }
}
