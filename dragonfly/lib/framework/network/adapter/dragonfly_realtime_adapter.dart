import 'dart:async';

/// Connection state of a realtime transport.
enum DragonflyRealtimeState {
  /// No connection and none being attempted.
  disconnected,

  /// A connection attempt is in flight.
  connecting,

  /// Connected and able to send and receive.
  connected,

  /// Disconnected unexpectedly; a reconnect may be scheduled.
  reconnecting,

  /// Closed permanently by the application.
  closed,
}

/// Transport contract for realtime data, alongside
/// `DragonflyBaseNetworkAdapter` for request/response.
///
/// Generated repositories call [subscribeToObject] and [subscribeToList] the
/// same way they call `callForObject` / `callForList`, so a `Stream`-returning
/// repository method needs no hand-written plumbing.
///
/// Implementations must be safe to subscribe to more than once per channel and
/// must not drop the connection until every listener has cancelled.
abstract interface class DragonflyRealtimeAdapter {
  /// Current connection state.
  DragonflyRealtimeState get state;

  /// Broadcast of connection-state transitions.
  Stream<DragonflyRealtimeState> get stateStream;

  /// Opens the connection. Safe to call when already connected.
  Future<void> connect();

  /// Closes the connection and completes every open subscription.
  Future<void> disconnect();

  /// Stream of JSON objects arriving on [channel].
  ///
  /// [params] is transport-specific — a subscribe payload for a
  /// pub/sub server, query parameters for a plain socket URL.
  Stream<Map<String, Object?>> subscribeToObject(
    String channel, {
    Map<String, dynamic>? params,
  });

  /// Stream of JSON arrays arriving on [channel].
  Stream<List<Map<String, Object?>>> subscribeToList(
    String channel, {
    Map<String, dynamic>? params,
  });

  /// Publishes [payload] to [channel].
  Future<void> publish(String channel, Map<String, dynamic> payload);
}

/// Thrown when a realtime transport fails.
class DragonflyRealtimeException implements Exception {
  const DragonflyRealtimeException(this.message, {this.channel, this.cause});

  final String message;
  final String? channel;
  final Object? cause;

  @override
  String toString() => 'DragonflyRealtimeException'
      '${channel != null ? '($channel)' : ''}: $message'
      '${cause != null ? ' — $cause' : ''}';
}
