import 'dart:convert';
import 'dart:typed_data';

import 'package:brainbox_core/brainbox_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/session_controller.dart';
import '../../auth/data/auth_repository.dart';
import '../../offline/offline_cache.dart';
import '../data/settings_repository.dart';

/// Saves bytes to a file the student picks. Returns false when cancelled.
typedef FileSaver = Future<bool> Function(String fileName, Uint8List bytes);

final fileSaverProvider = Provider<FileSaver>(
  (ref) =>
      (name, bytes) async =>
          await FilePicker.saveFile(fileName: name, bytes: bytes) != null,
);

/// What the last account action did.
enum AccountAction { idle, exporting, exported, deleting, failed }

class AccountState {
  const AccountState(this.action, [this.error]);

  final AccountAction action;
  final String? error;

  bool get busy =>
      action == AccountAction.exporting || action == AccountAction.deleting;
}

/// "Download my data" and "Delete my account" in Data & privacy.
class AccountController extends Notifier<AccountState> {
  @override
  AccountState build() => const AccountState(AccountAction.idle);

  /// `GET /auth/me/export`, saved as a JSON file.
  Future<void> exportData() async {
    state = const AccountState(AccountAction.exporting);
    try {
      final data = await ref.read(settingsRepositoryProvider).exportMyData();
      final bytes = Uint8List.fromList(
        utf8.encode(const JsonEncoder.withIndent('  ').convert(data)),
      );
      final day = DateTime.now().toIso8601String().substring(0, 10);
      final saved = await ref.read(fileSaverProvider)(
        'brainbox-my-data-$day.json',
        bytes,
      );
      if (ref.mounted) {
        state = AccountState(
          saved ? AccountAction.exported : AccountAction.idle,
        );
      }
    } catch (e) {
      if (ref.mounted) {
        state = AccountState(AccountAction.failed, ErrorMessages.of(e));
      }
    }
  }

  /// `DELETE /auth/me`, then wipes the offline cache and signs out.
  /// Returns true when the account is gone.
  Future<bool> deleteAccount() async {
    state = const AccountState(AccountAction.deleting);
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
    } on ApiException catch (e) {
      if (ref.mounted) {
        state = AccountState(AccountAction.failed, ErrorMessages.of(e));
      }
      return false;
    } catch (_) {
      // The backend already removed the Firebase login, so deleting the
      // local Firebase user can fail. The account is gone either way.
    }
    await ref.read(offlineCacheProvider).clear();
    try {
      await ref.read(sessionProvider.notifier).signOut();
    } catch (_) {}
    return true;
  }
}

final accountControllerProvider =
    NotifierProvider.autoDispose<AccountController, AccountState>(
      AccountController.new,
    );
