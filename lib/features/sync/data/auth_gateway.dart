import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Why a sign-in or sign-up did not work, in terms the UI can explain.
enum AuthFailure {
  invalidCredentials,
  emailTaken,
  weakPassword,
  emailNotConfirmed,
  network,
  unknown,
}

class SignInException implements Exception {
  const SignInException(this.failure);

  final AuthFailure failure;

  @override
  String toString() => 'SignInException($failure)';
}

/// Email + password accounts. Two implementations: Supabase Auth, and a
/// fake for tests.
abstract interface class AuthGateway {
  String? get userId;
  String? get email;

  /// Emits whenever the signed-in user changes (null: signed out).
  Stream<String?> get userChanges;

  Future<void> signIn({required String email, required String password});

  /// Returns false when the account still has to be confirmed by email
  /// before anyone can sign in with it.
  Future<bool> signUp({required String email, required String password});
  Future<void> signOut();
}

class SupabaseAuthGateway implements AuthGateway {
  SupabaseAuthGateway(this._auth);

  final GoTrueClient _auth;

  @override
  String? get userId => _auth.currentUser?.id;

  @override
  String? get email => _auth.currentUser?.email;

  @override
  Stream<String?> get userChanges =>
      _auth.onAuthStateChange.map((state) => state.session?.user.id).distinct();

  @override
  Future<void> signIn({required String email, required String password}) =>
      _guard(() => _auth.signInWithPassword(email: email, password: password));

  @override
  Future<bool> signUp({required String email, required String password}) async {
    AuthResponse? response;
    await _guard(
      () async =>
          response = await _auth.signUp(email: email, password: password),
    );
    return response?.session != null;
  }

  @override
  Future<void> signOut() => _auth.signOut();

  /// Maps Supabase errors to [AuthFailure]; the raw message may contain
  /// the email address, so it is never shown or logged.
  Future<void> _guard(Future<Object?> Function() call) async {
    try {
      await call();
    } on AuthApiException catch (e) {
      throw SignInException(switch (e.code) {
        'invalid_credentials' => AuthFailure.invalidCredentials,
        'user_already_exists' || 'email_exists' => AuthFailure.emailTaken,
        'weak_password' => AuthFailure.weakPassword,
        'email_not_confirmed' => AuthFailure.emailNotConfirmed,
        _ => AuthFailure.unknown,
      });
    } on AuthRetryableFetchException {
      throw const SignInException(AuthFailure.network);
    } on AuthWeakPasswordException {
      throw const SignInException(AuthFailure.weakPassword);
    }
  }
}
