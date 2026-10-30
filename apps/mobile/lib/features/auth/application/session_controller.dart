import 'dart:async';

import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../onboarding/application/onboarding_controller.dart';
import '../data/auth_repository.dart';
import '../domain/auth_models.dart';

part 'session_controller.g.dart';

/// Everything the router needs to decide where the student belongs.
class SessionState {
  const SessionState({
    required this.welcomeSeen,
    this.account,
    this.user,
    this.signedOutReason,
  });

  /// The welcome carousel was already seen on this device.
  final bool welcomeSeen;

  /// Why the app signed the student out by itself (e.g. `USER_DISABLED`).
  /// Log in shows it; null normally.
  final ApiException? signedOutReason;

  /// Firebase account (null = signed out).
  final AuthAccount? account;

  /// Backend user from `GET /auth/me` (null when signed out).
  final AppUser? user;

  bool get signedIn => account != null && user != null;
  bool get emailVerified => user?.emailVerified ?? false;
  bool get profileCompleted => user?.onboarding.profileCompleted ?? false;

  /// Diagnostic finished OR skipped.
  bool get diagnosticDone =>
      (user?.onboarding.diagnosticCompleted ?? false) ||
      (user?.onboarding.diagnosticSkipped ?? false);
}

/// The signed-in student and their onboarding progress.
///
/// Built from: the "welcome seen" flag + the Firebase account +
/// `GET /auth/me` (if the backend has no user yet, we call
/// `POST /auth/register` with the Firebase display name - it upserts).
///
/// Screens call [refresh] after sign in / sign up / verifying the email /
/// finishing a setup step; the router then moves the student on.
@Riverpod(keepAlive: true)
class Session extends _$Session {
  @override
  Future<SessionState> build() async {
    final repo = ref.watch(authRepositoryProvider);
    final welcomeSeen = await ref.watch(welcomeSeenProvider.future);

    final account = repo.currentAccount;

    // Someone signed out or switched account outside our screens (token
    // revoked, account deleted...): rebuild. Sign-ins from our own screens
    // call refresh() themselves when they are ready.
    final sub = repo.accountChanges().listen((next) {
      if (account != null && next == null) ref.invalidateSelf();
    });
    ref.onDispose(sub.cancel);

    if (account == null) return SessionState(welcomeSeen: welcomeSeen);

    try {
      final user = await _loadUser(repo, account);
      return SessionState(
        welcomeSeen: welcomeSeen,
        account: account,
        user: user,
      );
    } on ApiException catch (e) {
      if (e.code != 'USER_DISABLED') rethrow;
      // The backend blocked this account: sign out and say why on Log in.
      await repo.signOut();
      return SessionState(welcomeSeen: welcomeSeen, signedOutReason: e);
    }
  }

  static Future<AppUser> _loadUser(
    AuthRepository repo,
    AuthAccount account,
  ) async {
    try {
      return await repo.me();
    } on ApiException catch (e) {
      if (e.code != 'USER_NOT_FOUND' && e.code != 'USER_NOT_REGISTERED') {
        rethrow;
      }
      // Signed in to Firebase but unknown to the backend (e.g. the app was
      // closed during sign up): register now. Safe to repeat.
      return repo.register(fullName: nameFor(account), consent: true);
    }
  }

  /// The name for `POST /auth/register` (it must not be empty): the
  /// Firebase display name, else the part of the email before the "@".
  static String nameFor(AuthAccount account) {
    final name = account.displayName?.trim() ?? '';
    if (name.isNotEmpty) return name;
    final local = account.email.split('@').first.trim();
    return local.isEmpty ? 'Student' : local;
  }

  /// Reloads the session and waits for it.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Like [refresh], but throws when the session signed the student out by
  /// itself (e.g. `USER_DISABLED`), so the form that called it shows why.
  Future<void> refreshOrThrow() async {
    await refresh();
    final reason = state.value?.signedOutReason;
    if (reason != null) throw reason;
  }

  /// Signs out and clears the session (the router then shows Log in).
  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    await refresh();
  }
}

/// Whether the onboarding redirect is on.
///
/// On when sign-in can actually work (Firebase configured, or the fake API)
/// and not switched off with `--dart-define=DISABLE_AUTH_GUARD=true`.
/// Tests override it.
@Riverpod(keepAlive: true)
bool authGuardEnabled(Ref ref) =>
    (FirebaseSetup.isReady || Env.useFakeApi) && !Env.disableAuthGuard;
