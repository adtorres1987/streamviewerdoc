import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/subscription.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

part 'auth_provider.freezed.dart';
part 'auth_provider.g.dart';

// ---------------------------------------------------------------------------
// Secure storage key
// ---------------------------------------------------------------------------

const _kTokenKey = 'syncpdf_auth_token';

// ---------------------------------------------------------------------------
// AuthState — freezed sealed union
// ---------------------------------------------------------------------------

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.loading() = AuthLoading;
  const factory AuthState.authenticated({
    required User user,
    required String token,
    Subscription? subscription,
  }) = AuthAuthenticated;
  const factory AuthState.unauthenticated() = AuthUnauthenticated;
  const factory AuthState.error(String message) = AuthError;
}

// ---------------------------------------------------------------------------
// AuthNotifier
// ---------------------------------------------------------------------------

@riverpod
class AuthNotifier extends _$AuthNotifier {
  late final AuthService _authService;
  late final FlutterSecureStorage _storage;

  @override
  AuthState build() {
    _authService = AuthService();
    _storage = const FlutterSecureStorage();
    // Kick off token restoration asynchronously after the provider is built.
    Future.microtask(_restoreSession);
    return const AuthState.initial();
  }

  // --------------------------------------------------------------------------
  // Session restoration
  // --------------------------------------------------------------------------

  /// Reads a stored JWT from secure storage and calls /auth/me to validate it.
  /// Transitions to [AuthState.authenticated] on success or
  /// [AuthState.unauthenticated] if the token is missing/invalid.
  Future<void> _restoreSession() async {
    state = const AuthState.loading();
    try {
      final token = await _storage.read(key: _kTokenKey);
      if (token == null) {
        state = const AuthState.unauthenticated();
        return;
      }

      final response = await _authService.getMe(token);
      final data = response['data'] as Map<String, dynamic>;
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      final subscription = data['subscription'] != null
          ? Subscription.fromJson(data['subscription'] as Map<String, dynamic>)
          : null;

      state = AuthState.authenticated(
        user: user,
        token: token,
        subscription: subscription,
      );
    } catch (_) {
      // Token invalid or network error at startup — go to login.
      await _storage.delete(key: _kTokenKey);
      state = const AuthState.unauthenticated();
    }
  }

  // --------------------------------------------------------------------------
  // Public mutations
  // --------------------------------------------------------------------------

  /// Authenticates the user and persists the JWT.
  Future<void> login(String email, String password) async {
    state = const AuthState.loading();
    try {
      final response = await _authService.login(email, password);
      final data = response['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      final subscription = data['subscription'] != null
          ? Subscription.fromJson(data['subscription'] as Map<String, dynamic>)
          : null;

      await _storage.write(key: _kTokenKey, value: token);

      state = AuthState.authenticated(
        user: user,
        token: token,
        subscription: subscription,
      );
    } on Exception catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// Registers a new account.  On success the backend sends an activation
  /// email; callers should navigate to [ActivateScreen].
  Future<void> register(
    String email,
    String password,
    String fullName,
  ) async {
    state = const AuthState.loading();
    try {
      await _authService.register(email, password, fullName);
      // Stay unauthenticated — user must activate before they can log in.
      state = const AuthState.unauthenticated();
    } on Exception catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// Submits the 6-digit activation code.  On success navigate to login.
  Future<void> activate(String email, String code) async {
    state = const AuthState.loading();
    try {
      await _authService.activate(email, code);
      state = const AuthState.unauthenticated();
    } on Exception catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// Sends a password-reset code to [email].
  Future<void> forgotPassword(String email) async {
    state = const AuthState.loading();
    try {
      await _authService.forgotPassword(email);
      state = const AuthState.unauthenticated();
    } on Exception catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// Clears the JWT and transitions to unauthenticated.
  Future<void> logout() async {
    await _storage.delete(key: _kTokenKey);
    state = const AuthState.unauthenticated();
  }
}

// ---------------------------------------------------------------------------
// Convenience derived providers
// ---------------------------------------------------------------------------

/// Exposes the currently authenticated [User] or null.
@riverpod
User? currentUser(Ref ref) {
  final authState = ref.watch(authNotifierProvider);
  return switch (authState) {
    AuthAuthenticated(:final user) => user,
    _ => null,
  };
}

/// Exposes the current user's [Subscription] or null.
@riverpod
Subscription? currentSubscription(Ref ref) {
  final authState = ref.watch(authNotifierProvider);
  return switch (authState) {
    AuthAuthenticated(:final subscription) => subscription,
    _ => null,
  };
}

/// True only while the auth state is being determined at startup.
@riverpod
bool authIsLoading(Ref ref) {
  return switch (ref.watch(authNotifierProvider)) {
    AuthInitial() || AuthLoading() => true,
    _ => false,
  };
}
