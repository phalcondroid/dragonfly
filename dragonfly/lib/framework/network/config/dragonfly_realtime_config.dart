/// Configuration for a realtime (socket) connection.
///
/// The field names are configurable because backends disagree about envelope
/// shape. The defaults match the common
/// `{"action": "...", "channel": "...", "data": {...}}` convention.
///
/// For a server that opens one socket per resource and emits bare payloads, set
/// [channelField] to `null` and leave [subscribeAction] unset — every message is
/// then delivered to all subscribers on that connection.
class DragonflyRealtimeConfig {
  const DragonflyRealtimeConfig({
    required this.url,
    this.channelField = 'channel',
    this.dataField = 'data',
    this.actionField = 'action',
    this.subscribeAction = 'subscribe',
    this.unsubscribeAction = 'unsubscribe',
    this.autoReconnect = true,
    this.reconnectDelay = const Duration(seconds: 1),
    this.maxReconnectDelay = const Duration(seconds: 30),
    this.maxReconnectAttempts,
    this.headers = const {},
  });

  /// Socket URL, e.g. `wss://api.example.com/ws`.
  final String url;

  /// Envelope key naming the channel. `null` means the server does not
  /// multiplex and every message goes to every subscriber.
  final String? channelField;

  /// Envelope key holding the payload.
  final String dataField;

  /// Envelope key naming the client action.
  final String actionField;

  /// Value sent to subscribe to a channel. `null` disables subscribe frames.
  final String? subscribeAction;

  /// Value sent to unsubscribe. `null` disables unsubscribe frames.
  final String? unsubscribeAction;

  /// Whether to reconnect automatically after an unexpected drop.
  final bool autoReconnect;

  /// Delay before the first reconnect; doubles per attempt.
  final Duration reconnectDelay;

  /// Upper bound for the backoff delay.
  final Duration maxReconnectDelay;

  /// Give up after this many attempts. `null` retries indefinitely.
  final int? maxReconnectAttempts;

  /// Extra headers for the handshake, where the platform supports them.
  final Map<String, String> headers;
}
