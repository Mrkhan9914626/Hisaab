import 'package:expense_tracker/core/domain/app_failure.dart';
import 'package:expense_tracker/core/storage/local_storage_policy.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('expense_tracker/test_storage_policy');
  const policy = MethodChannelLocalStoragePolicy(channel: channel);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('returns the verified private directory path', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'prepareExpenseDirectory');
      return '/private/no-backup';
    });

    final result = await policy.prepareExpenseDirectory();
    expect(result.valueOrNull?.directoryPath, '/private/no-backup');
  });

  test('a missing path is a privacy policy failure', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => null);

    final result = await policy.prepareExpenseDirectory();
    expect(result, isA<Failure<PrivateStoreLocation>>());
    expect(
      (result as Failure<PrivateStoreLocation>).failure.code,
      AppFailureCode.privacyPolicyUnavailable,
    );
  });

  test('a platform failure is a privacy policy failure', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'storage_unavailable');
    });

    final result = await policy.prepareExpenseDirectory();
    expect(result, isA<Failure<PrivateStoreLocation>>());
    expect(
      (result as Failure<PrivateStoreLocation>).failure.code,
      AppFailureCode.privacyPolicyUnavailable,
    );
  });
}
