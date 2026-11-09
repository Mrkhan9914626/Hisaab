/// Non-sensitive failure codes returned by the storage and application layers.
///
/// Failures never carry SQL, field contents, amounts, dates, notes, category
/// names, identifiers or other stored financial data.
enum AppFailureCode {
  storageUnavailable,
  initializationFailed,
  incompatibleStore,
  integrityFailure,
  calculationOverflow,
  outcomeUnavailable,
  privacyPolicyUnavailable,
}

/// How the UI should offer a retry for a failure.
enum RetryKind {
  ordinary,
  reconciliation,
}

class AppFailure {
  const AppFailure(
    this.code, {
    this.retryKind = RetryKind.ordinary,
    this.operation,
  });

  final AppFailureCode code;
  final RetryKind retryKind;
  final String? operation;

  String get userMessage {
    switch (code) {
      case AppFailureCode.storageUnavailable:
        return 'Saved data is unavailable right now. Try again.';
      case AppFailureCode.initializationFailed:
        return 'Expense storage could not be started. Try again.';
      case AppFailureCode.incompatibleStore:
        return 'This data was saved by a newer app version and cannot be opened.';
      case AppFailureCode.integrityFailure:
        return 'The saved records could not be verified.';
      case AppFailureCode.calculationOverflow:
        return 'The total is too large to display exactly.';
      case AppFailureCode.outcomeUnavailable:
        return 'The result of the save could not be confirmed yet. Check again.';
      case AppFailureCode.privacyPolicyUnavailable:
        return 'Private device storage is unavailable, so expenses cannot be opened.';
    }
  }

  @override
  String toString() => 'AppFailure(${code.name})';
}

sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.failure);

  final AppFailure failure;
}

extension ResultValue<T> on Result<T> {
  T? get valueOrNull => switch (this) {
        Success<T>(:final value) => value,
        Failure<T>() => null,
      };

  AppFailure? get failureOrNull => switch (this) {
        Success<T>() => null,
        Failure<T>(:final failure) => failure,
      };

  bool get isSuccess => this is Success<T>;
}
