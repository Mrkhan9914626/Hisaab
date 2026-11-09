import 'package:expense_tracker/core/domain/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Success exposes its value and is success', () {
    const result = Success<int>(42);
    expect(result.value, 42);
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, 42);
    expect(result.failureOrNull, isNull);
  });

  test('Failure exposes a typed failure and is never success', () {
    const failure = AppFailure(
      AppFailureCode.outcomeUnavailable,
      retryKind: RetryKind.reconciliation,
    );
    const result = Failure<int>(failure);
    expect(result.isSuccess, isFalse);
    expect(result.valueOrNull, isNull);
    expect(result.failureOrNull, same(failure));
  });

  test('all failure codes carry safe user messages', () {
    for (final code in AppFailureCode.values) {
      final failure = AppFailure(code);
      expect(failure.userMessage.trim(), isNotEmpty);
      expect(failure.toString(), contains(code.name));
    }
  });

  test('retry kinds distinguish ordinary retry from reconciliation', () {
    expect(const AppFailure(AppFailureCode.storageUnavailable).retryKind,
        RetryKind.ordinary);
    expect(
      const AppFailure(
        AppFailureCode.outcomeUnavailable,
        retryKind: RetryKind.reconciliation,
      ).retryKind,
      RetryKind.reconciliation,
    );
  });
}
