import 'package:flutter/services.dart';

import '../domain/app_failure.dart';

class PrivateStoreLocation {
  const PrivateStoreLocation(this.directoryPath);

  final String directoryPath;
}

/// Returns a verified app-private, backup-excluded directory for financial data.
abstract class LocalStoragePolicy {
  Future<Result<PrivateStoreLocation>> prepareExpenseDirectory();
}

/// Method-channel bridge implemented by the platform host at bootstrap time.
///
/// Android must return `context.noBackupFilesDir`; iOS must return a protected
/// Application Support child directory with `isExcludedFromBackup` set and
/// verified. Any failure is a privacy failure, never a fallback path.
class MethodChannelLocalStoragePolicy implements LocalStoragePolicy {
  const MethodChannelLocalStoragePolicy({
    MethodChannel channel = const MethodChannel('expense_tracker/storage_policy'),
  }) : _channel = channel;

  final MethodChannel _channel;

  @override
  Future<Result<PrivateStoreLocation>> prepareExpenseDirectory() async {
    try {
      final path = await _channel.invokeMethod<String>('prepareExpenseDirectory');
      if (path == null || path.trim().isEmpty) {
        return const Failure<PrivateStoreLocation>(
          AppFailure(AppFailureCode.privacyPolicyUnavailable),
        );
      }
      return Success(PrivateStoreLocation(path));
    } on PlatformException {
      return const Failure<PrivateStoreLocation>(
        AppFailure(AppFailureCode.privacyPolicyUnavailable),
      );
    } on MissingPluginException {
      return const Failure<PrivateStoreLocation>(
        AppFailure(AppFailureCode.privacyPolicyUnavailable),
      );
    } catch (_) {
      return const Failure<PrivateStoreLocation>(
        AppFailure(AppFailureCode.privacyPolicyUnavailable),
      );
    }
  }
}

class FixedDirectoryStoragePolicy implements LocalStoragePolicy {
  const FixedDirectoryStoragePolicy(this.directoryPath);

  final String directoryPath;

  @override
  Future<Result<PrivateStoreLocation>> prepareExpenseDirectory() async =>
      Success(PrivateStoreLocation(directoryPath));
}
