import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:dragonfly/framework/logging/dragonfly_log_manager.dart';
import 'package:dragonfly/framework/network/adapter/dragonfly_realtime_adapter.dart';
import 'package:dragonfly/framework/network/config/dragonfly_realtime_config.dart';

/// The narrow socket surface the adapter needs.
///
/// Keeping this separate from `package:web_socket_channel` lets the adapter be
/// driven by a fake in tests, and leaves room for other transports (SSE,
/// socket.io, an in-app message bus) without touching the adapter itself.
abstract interface class DragonflySocketConnection {
  /// Frames arriving from the peer.
  Stream<dynamic> get messages;

  /// Sends an encoded frame.
  void send(String data);

  /// Closes the connection.
  Future<void> close();
}

/// [DragonflySocketConnection] backed by `package:web_socket_channel`.
class WebSocketConnection implements DragonflySocketConnection {
  WebSocketConnection(this._channel);

  factory WebSocketConnection.connect(Uri uri) =>
      WebSocketConnection(WebSocketChannel.connect(uri));

  final WebSocketChannel _channel;

  @override
  Stream<dynamic> get messages => _channel.stream;

  @override
  void send(String data) => _channel.sink.add(data);

  @override
  Future<void> close() => _channel.sink.close();
}

/// WebSocket implementation of [DragonflyRealtimeAdapter].
///
/// Assumes a JSON envelope carrying a channel discriminator and a payload:
///
/// ```json
/// { "channel": "characters", "data": { "id": 1, "name": "Rick" } }
/// ```
///
/// Field names are configurable through [DragonflyRealtimeConfig] so the
/// adapter can match an existing backend rather than the other way round. A
/// server that emits bare payloads on a per-channel URL is supported by leaving
/// `channelField` null — every message is then routed to all subscribers.
///
/// Reconnects with exponential backoff and replays its subscribe payloads, so a
/// dropped connection is invisible to a repository holding the stream.
class DragonflyWebSocketAdapter implements DragonflyRealtimeAdapter {
  DragonflyWebSocketAdapter({
    required this.config,
    this.enableLogging = true,
    DragonflySocketConnection Function(Uri uri)? connectionFactory,
  }) : _connect = connectionFactory ?? WebSocketConnection.connect;

  final DragonflyRealtimeConfig config;
  final bool enableLogging;
  final DragonflySocketConnection Function(Uri uri) _connect;

  DragonflySocketConnection? _channel;
  StreamSubscription<dynamic>? _socketSubscription;

  final Map<String, _ChannelBinding> _bindings = {};
  final StreamController<DragonflyRealtimeState> _stateController =
      StreamController<DragonflyRealtimeState>.broadcast();

  DragonflyRealtimeState _state = DragonflyRealtimeState.disconnected;
  Completer<void>? _connecting;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;

  DragonflyLogManager get _log => DragonflyLogManager.instance;

  @override
  DragonflyRealtimeState get state => _state;

  @override
  Stream<DragonflyRealtimeState> get stateStream => _stateController.stream;

  @override
  Future<void> connect() {
    if (_state == DragonflyRealtimeState.connected) return Future.value();
    if (_connecting != null) return _connecting!.future;

    final completer = Completer<void>();
    _connecting = completer;
    _setState(_reconnectAttempt == 0
        ? DragonflyRealtimeState.connecting
        : DragonflyRealtimeState.reconnecting);

    try {
      final uri = Uri.parse(config.url);
      final channel = _connect(uri);
      _channel = channel;

      _socketSubscription = channel.messages.listen(
        _onMessage,
        onError: _onSocketError,
        onDone: _onSocketDone,
        cancelOnError: false,
      );

      _reconnectAttempt = 0;
      _setState(DragonflyRealtimeState.connected);
      if (enableLogging) {
        _log.success('Realtime connected: ${config.url}',
            source: 'DragonflyWebSocketAdapter');
      }

      // A reconnect must not leave the server unaware of our subscriptions.
      // Flags were cleared when the socket dropped, so this re-sends them all.
      for (final binding in _bindings.values) {
        _sendSubscribe(binding.channel, binding.params);
      }

      completer.complete();
    } catch (error, stackTrace) {
      if (enableLogging) {
        _log.error('Realtime connection failed',
            error: error,
            stackTrace: stackTrace,
            source: 'DragonflyWebSocketAdapter');
      }
      completer.completeError(
        DragonflyRealtimeException('Failed to connect to ${config.url}',
            cause: error),
        stackTrace,
      );
      _scheduleReconnect();
    } finally {
      _connecting = null;
    }

    return completer.future;
  }

  @override
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempt = 0;

    await _socketSubscription?.cancel();
    _socketSubscription = null;
    await _channel?.close();
    _channel = null;

    // Snapshot and clear first: closing a binding fires its onCancel, which
    // removes it from _bindings and would otherwise mutate the map mid-iteration.
    final bindings = _bindings.values.toList();
    _bindings.clear();
    for (final binding in bindings) {
      await binding.close();
    }

    _setState(DragonflyRealtimeState.closed);
  }

  @override
  Stream<Map<String, Object?>> subscribeToObject(
    String channel, {
    Map<String, dynamic>? params,
  }) {
    return _binding(channel, params).stream.map(_asObject);
  }

  @override
  Stream<List<Map<String, Object?>>> subscribeToList(
    String channel, {
    Map<String, dynamic>? params,
  }) {
    return _binding(channel, params).stream.map(_asList);
  }

  @override
  Future<void> publish(String channel, Map<String, dynamic> payload) async {
    await connect();
    final envelope = <String, dynamic>{
      if (config.channelField != null) config.channelField!: channel,
      config.dataField: payload,
    };
    _channel?.send(jsonEncode(envelope));
  }

  // --- internals ----------------------------------------------------------

  _ChannelBinding _binding(String channel, Map<String, dynamic>? params) {
    final existing = _bindings[channel];
    if (existing != null) return existing;

    late final _ChannelBinding binding;
    binding = _ChannelBinding(
      channel: channel,
      params: params,
      onListen: () {
        // Connect lazily: a repository can build the stream long before the UI
        // actually listens to it.
        unawaited(connect().then((_) => _sendSubscribe(channel, params)).catchError(
          (Object error) {
            binding.addError(error);
          },
        ));
      },
      onCancel: () async {
        _bindings.remove(channel);
        _sendUnsubscribe(channel);
      },
    );
    _bindings[channel] = binding;
    return binding;
  }

  void _sendSubscribe(String channel, Map<String, dynamic>? params) {
    final action = config.subscribeAction;
    if (action == null || _channel == null) return;

    // connect() replays every binding and onListen sends its own; without this
    // guard a channel would be subscribed twice on the first listen.
    final binding = _bindings[channel];
    if (binding == null || binding.subscribed) return;
    binding.subscribed = true;

    _channel!.send(jsonEncode(<String, dynamic>{
      config.actionField: action,
      if (config.channelField != null) config.channelField!: channel,
      if (params != null && params.isNotEmpty) config.dataField: params,
    }));
  }

  void _sendUnsubscribe(String channel) {
    final action = config.unsubscribeAction;
    if (action == null || _channel == null) return;
    _channel!.send(jsonEncode(<String, dynamic>{
      config.actionField: action,
      if (config.channelField != null) config.channelField!: channel,
    }));
  }

  void _onMessage(dynamic raw) {
    Object? decoded;
    try {
      decoded = raw is String ? jsonDecode(raw) : raw;
    } catch (error) {
      if (enableLogging) {
        _log.warning('Realtime message was not valid JSON: $raw',
            source: 'DragonflyWebSocketAdapter');
      }
      return;
    }

    if (decoded is! Map) {
      // No envelope to inspect — broadcast to every subscriber.
      for (final binding in _bindings.values) {
        binding.add(decoded);
      }
      return;
    }

    final envelope = Map<String, Object?>.from(decoded);
    final channelField = config.channelField;

    if (channelField == null) {
      for (final binding in _bindings.values) {
        binding.add(envelope[config.dataField] ?? envelope);
      }
      return;
    }

    final channel = envelope[channelField];
    if (channel is! String) return;

    final binding = _bindings[channel];
    if (binding == null) return;

    binding.add(envelope[config.dataField] ?? envelope);
  }

  void _onSocketError(Object error, StackTrace stackTrace) {
    if (enableLogging) {
      _log.error('Realtime socket error',
          error: error,
          stackTrace: stackTrace,
          source: 'DragonflyWebSocketAdapter');
    }
    for (final binding in _bindings.values) {
      binding.addError(
        DragonflyRealtimeException('Socket error',
            channel: binding.channel, cause: error),
      );
    }
    _scheduleReconnect();
  }

  void _onSocketDone() {
    if (_state == DragonflyRealtimeState.closed) return;
    if (enableLogging) {
      _log.warning('Realtime socket closed by peer',
          source: 'DragonflyWebSocketAdapter');
    }
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    // The server has forgotten our subscriptions; allow them to be re-sent.
    for (final binding in _bindings.values) {
      binding.subscribed = false;
    }

    if (!config.autoReconnect) {
      _setState(DragonflyRealtimeState.disconnected);
      return;
    }
    if (_state == DragonflyRealtimeState.closed) return;
    if (_reconnectTimer?.isActive ?? false) return;
    if (config.maxReconnectAttempts != null &&
        _reconnectAttempt >= config.maxReconnectAttempts!) {
      _setState(DragonflyRealtimeState.disconnected);
      return;
    }

    _setState(DragonflyRealtimeState.reconnecting);

    // Exponential backoff, capped, so a dead server is not hammered.
    final backoff = config.reconnectDelay * (1 << _reconnectAttempt);
    final delay = backoff > config.maxReconnectDelay
        ? config.maxReconnectDelay
        : backoff;
    _reconnectAttempt++;

    _reconnectTimer = Timer(delay, () {
      _socketSubscription?.cancel();
      _socketSubscription = null;
      _channel = null;
      unawaited(connect().catchError((_) {}));
    });
  }

  void _setState(DragonflyRealtimeState next) {
    if (_state == next) return;
    _state = next;
    if (!_stateController.isClosed) _stateController.add(next);
  }

  static Map<String, Object?> _asObject(Object? value) {
    if (value is Map<String, Object?>) return value;
    if (value is Map) return Map<String, Object?>.from(value);
    throw DragonflyRealtimeException(
        'Expected a JSON object but got ${value.runtimeType}');
  }

  static List<Map<String, Object?>> _asList(Object? value) {
    if (value is List) {
      return value.map(_asObject).toList();
    }
    throw DragonflyRealtimeException(
        'Expected a JSON array but got ${value.runtimeType}');
  }
}

/// One channel's broadcast controller plus the payload used to (re)subscribe.
class _ChannelBinding {
  _ChannelBinding({
    required this.channel,
    required this.params,
    required void Function() onListen,
    required Future<void> Function() onCancel,
  }) {
    _controller = StreamController<Object?>.broadcast(
      onListen: onListen,
      onCancel: onCancel,
    );
  }

  final String channel;
  final Map<String, dynamic>? params;

  /// Whether a subscribe frame for this channel is currently in force.
  bool subscribed = false;

  late final StreamController<Object?> _controller;

  Stream<Object?> get stream => _controller.stream;

  void add(Object? event) {
    if (!_controller.isClosed) _controller.add(event);
  }

  void addError(Object error) {
    if (!_controller.isClosed) _controller.addError(error);
  }

  Future<void> close() => _controller.close();
}
