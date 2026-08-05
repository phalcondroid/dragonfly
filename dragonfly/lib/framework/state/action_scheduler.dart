import 'dart:async';

/// Schedules state-manager actions with debounce and throttle semantics.
///
/// Owned by a [StateManager]; every pending timer is cancelled when the manager
/// is disposed, so a debounced action can never fire against a dead manager.
///
/// Actions are keyed by name. Scheduling a debounced action again before its
/// delay elapses replaces the pending call — only the last one runs. A throttled
/// action runs immediately and then ignores further calls until its window
/// closes.
class ActionScheduler {
  final Map<String, Timer> _debounceTimers = {};
  final Map<String, void Function()> _pendingBodies = {};
  final Map<String, DateTime> _throttleGates = {};
  bool _disposed = false;

  /// Whether this scheduler has been disposed.
  bool get isDisposed => _disposed;

  /// Keys of actions with a pending debounced call.
  Iterable<String> get pendingKeys => _debounceTimers.keys;

  /// Whether [key] has a debounced call waiting to fire.
  bool isPending(String key) => _debounceTimers.containsKey(key);

  /// Runs [body] according to [debounce] / [throttle].
  ///
  /// With neither, [body] runs synchronously. Passing both applies the throttle
  /// gate first and debounces what gets through.
  ///
  /// Returns `true` if [body] ran (or was scheduled to run), `false` if it was
  /// dropped by the throttle gate or because the scheduler is disposed.
  bool run(
    String key,
    void Function() body, {
    Duration? debounce,
    Duration? throttle,
  }) {
    if (_disposed) return false;

    if (throttle != null) {
      final lastRun = _throttleGates[key];
      final now = DateTime.now();
      if (lastRun != null && now.difference(lastRun) < throttle) {
        return false;
      }
      _throttleGates[key] = now;
    }

    if (debounce != null) {
      _debounceTimers.remove(key)?.cancel();
      _pendingBodies[key] = body;
      _debounceTimers[key] = Timer(debounce, () {
        _debounceTimers.remove(key);
        final pending = _pendingBodies.remove(key);
        if (!_disposed) pending?.call();
      });
      return true;
    }

    body();
    return true;
  }

  /// Cancels any pending debounced call for [key] and reopens its throttle gate.
  void cancel(String key) {
    _debounceTimers.remove(key)?.cancel();
    _pendingBodies.remove(key);
    _throttleGates.remove(key);
  }

  /// Runs a pending debounced call for [key] now instead of waiting out its delay.
  ///
  /// Does nothing when nothing is pending. Useful on form submit, where the
  /// debounced validation should not be lost to the submit itself.
  void flush(String key) {
    _debounceTimers.remove(key)?.cancel();
    final pending = _pendingBodies.remove(key);
    if (!_disposed) pending?.call();
  }

  /// Cancels every pending call and clears all throttle gates.
  void cancelAll() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _pendingBodies.clear();
    _throttleGates.clear();
  }

  /// Cancels everything and marks the scheduler unusable.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    cancelAll();
  }
}
