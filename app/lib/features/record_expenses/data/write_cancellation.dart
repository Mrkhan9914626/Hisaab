class WriteCancellation {
  bool isCancelled = false;
}

class CancellationRollback implements Exception {
  const CancellationRollback();
}

/// A write failed after a transaction was dispatched, so commit state is not
/// proven. Callers must quarantine the connection and reconcile; this is never
/// treated as a known-unsaved result.
class UncertainWriteException implements Exception {
  const UncertainWriteException();
}
