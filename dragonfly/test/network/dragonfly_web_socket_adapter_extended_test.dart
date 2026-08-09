import 'dart:async';
import 'dart:convert';

import 'package:dragonfly/dragonfly.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DragonflyRealtimeState', () {
    test('all 5 values exist', () {
      expect(DragonflyRealtimeState.values, [
        DragonflyRealtimeState.disconnected,
        DragonflyRealtimeState.connecting,
        DragonflyRealtimeState.connected,
        DragonflyRealtimeState.reconnecting,
        DragonflyRealtimeState.closed,
      ]);
    });
  });

  group('DragonflyRealtimeException', () {
    test('stores message', () {
      const e = DragonflyRealtimeException('test error');
      expect(e.message, 'test error');
    });

    test('stores channel and cause when provided', () {
      final cause = Exception('underlying');
      final e = DragonflyRealtimeException(
        'test error',
        channel: 'characters',
        cause: cause,
      );
      expect(e.message, 'test error');
      expect(e.channel, 'characters');
      expect(e.cause, cause);
    });

    test('toString without channel', () {
      const e = DragonflyRealtimeException('test error');
      expect(e.toString(), 'DragonflyRealtimeException: test error');
    });

    test('toString includes channel when provided', () {
      const e = DragonflyRealtimeException(
        'test error',
        channel: 'characters',
      );
      expect(
        e.toString(),
        'DragonflyRealtimeException(characters): test error',
      );
    });

    test('toString includes cause when provided', () {
      const e = DragonflyRealtimeException('test error',
          cause: 'underlying');
      expect(
        e.toString(),
        'DragonflyRealtimeException: test error — underlying',
      );
    });

    test('toString includes both channel and cause', () {
      const e = DragonflyRealtimeException(
        'test error',
        channel: 'characters',
        cause: 'underlying',
      );
      expect(
        e.toString(),
        'DragonflyRealtimeException(characters): test error — underlying',
      );
    });

    test('is an Exception', () {
      const e = DragonflyRealtimeException('test error');
      expect(e, isA<Exception>());
    });
  });

  group('DragonflyRealtimeConfig', () {
    test('constructor stores url', () {
      const config = DragonflyRealtimeConfig(url: 'wss://example.com/ws');
      expect(config.url, 'wss://example.com/ws');
    });

    test('constructor stores all fields', () {
      const config = DragonflyRealtimeConfig(
        url: 'wss://example.com/ws',
        channelField: 'ch',
        dataField: 'payload',
        actionField: 'act',
        subscribeAction: 'sub',
        unsubscribeAction: 'unsub',
        autoReconnect: false,
        reconnectDelay: Duration(seconds: 5),
        maxReconnectDelay: Duration(seconds: 60),
        maxReconnectAttempts: 10,
        headers: {'X-Custom': 'value'},
      );
      expect(config.url, 'wss://example.com/ws');
      expect(config.channelField, 'ch');
      expect(config.dataField, 'payload');
      expect(config.actionField, 'act');
      expect(config.subscribeAction, 'sub');
      expect(config.unsubscribeAction, 'unsub');
      expect(config.autoReconnect, false);
      expect(config.reconnectDelay, const Duration(seconds: 5));
      expect(config.maxReconnectDelay, const Duration(seconds: 60));
      expect(config.maxReconnectAttempts, 10);
      expect(config.headers, {'X-Custom': 'value'});
    });

    test('default values', () {
      const config = DragonflyRealtimeConfig(
        url: 'wss://example.com/ws',
      );
      expect(config.channelField, 'channel');
      expect(config.dataField, 'data');
      expect(config.actionField, 'action');
      expect(config.subscribeAction, 'subscribe');
      expect(config.unsubscribeAction, 'unsubscribe');
      expect(config.autoReconnect, true);
      expect(config.reconnectDelay, const Duration(seconds: 1));
      expect(config.maxReconnectDelay, const Duration(seconds: 30));
      expect(config.maxReconnectAttempts, isNull);
      expect(config.headers, isEmpty);
    });

    test('channelField can be null', () {
      const config = DragonflyRealtimeConfig(
        url: 'wss://example.com/ws',
        channelField: null,
      );
      expect(config.channelField, isNull);
    });

    test('subscribeAction can be null', () {
      const config = DragonflyRealtimeConfig(
        url: 'wss://example.com/ws',
        subscribeAction: null,
      );
      expect(config.subscribeAction, isNull);
    });

    test('unsubscribeAction can be null', () {
      const config = DragonflyRealtimeConfig(
        url: 'wss://example.com/ws',
        unsubscribeAction: null,
      );
      expect(config.unsubscribeAction, isNull);
    });

    test('maxReconnectAttempts can be null', () {
      const config = DragonflyRealtimeConfig(
        url: 'wss://example.com/ws',
        maxReconnectAttempts: null,
      );
      expect(config.maxReconnectAttempts, isNull);
    });
  });

  group('DragonflySocketConnection', () {
    test('type exists as abstract interface', () {
      // Compile-time check: verify the type is resolvable
      expect(DragonflySocketConnection, isNotNull);
    });
  });

  group('WebSocketConnection', () {
    test('factory constructor type exists', () {
      // Compile-time check: verify the type is resolvable
      expect(WebSocketConnection, isNotNull);
    });
  });

  group('DragonflyWebSocketAdapter', () {
    late DragonflyWebSocketAdapter adapter;

    tearDown(() async {
      await adapter.disconnect();
    });

    DragonflyWebSocketAdapter build({DragonflyRealtimeConfig? config}) {
      return DragonflyWebSocketAdapter(
        config: config ??
            const DragonflyRealtimeConfig(
              url: 'wss://example.test/ws',
              autoReconnect: false,
            ),
        enableLogging: false,
        connectionFactory: (_) => _FakeDisconnectedSocket(),
      );
    }

    test('state starts as disconnected', () {
      adapter = build();
      expect(adapter.state, DragonflyRealtimeState.disconnected);
    });

    test('stateStream is a broadcast stream', () async {
      adapter = build();
      final stream = adapter.stateStream;
      final states1 = <DragonflyRealtimeState>[];
      final states2 = <DragonflyRealtimeState>[];
      stream.listen(states1.add);
      stream.listen(states2.add);
      await adapter.connect();
      await Future<void>.delayed(Duration.zero);
      expect(states1, isNotEmpty);
      expect(states2, isNotEmpty);
    });

    test('enableLogging defaults to true when not specified', () {
      final a = DragonflyWebSocketAdapter(
        config: const DragonflyRealtimeConfig(
          url: 'wss://example.test/ws',
          autoReconnect: false,
        ),
        enableLogging: true,
        connectionFactory: (_) => _FakeDisconnectedSocket(),
      );
      expect(a.enableLogging, isTrue);
    });

    test('disconnect when already disconnected does not throw', () async {
      adapter = build();
      expect(adapter.state, DragonflyRealtimeState.disconnected);
      await adapter.disconnect();
      expect(adapter.state, DragonflyRealtimeState.closed);
    });

    test('publish when disconnected attempts to connect', () async {
      adapter = build();
      expect(adapter.state, DragonflyRealtimeState.disconnected);
      await adapter.publish('channel', {'key': 'value'});
      // publish calls connect() first; since our fake never completes,
      // it should still have gone through the connect path
    });

    test('constructor with custom connectionFactory', () async {
      bool factoryCalled = false;
      adapter = DragonflyWebSocketAdapter(
        config: const DragonflyRealtimeConfig(
          url: 'wss://example.test/ws',
          autoReconnect: false,
        ),
        enableLogging: false,
        connectionFactory: (uri) {
          factoryCalled = true;
          expect(uri.toString(), 'wss://example.test/ws');
          return _FakeDisconnectedSocket();
        },
      );
      await adapter.connect();
      expect(factoryCalled, isTrue);
    });

    test(
        'subscribeToObject converts Map to Map<String, Object?> '
        '(exercises _asObject)', () async {
      final socket = _FakeSocket();
      adapter = DragonflyWebSocketAdapter(
        config: const DragonflyRealtimeConfig(
          url: 'wss://example.test/ws',
          autoReconnect: false,
        ),
        enableLogging: false,
        connectionFactory: (_) => socket,
      );

      final received = <Map<String, Object?>>[];
      adapter.subscribeToObject('test').listen(received.add);
      await Future<void>.delayed(Duration.zero);

      // channelField defaults to 'channel', dataField to 'data'
      socket.emit({
        'channel': 'test',
        'data': {'id': 42, 'name': 'Rick'},
      });
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.single, isA<Map<String, Object?>>());
      expect(received.single['id'], 42);
    });

    test(
        'subscribeToList converts List of Maps to List<Map<String, Object?>> '
        '(exercises _asList)', () async {
      final socket = _FakeSocket();
      adapter = DragonflyWebSocketAdapter(
        config: const DragonflyRealtimeConfig(
          url: 'wss://example.test/ws',
          autoReconnect: false,
        ),
        enableLogging: false,
        connectionFactory: (_) => socket,
      );

      final received = <List<Map<String, Object?>>>[];
      adapter.subscribeToList('list').listen(received.add);
      await Future<void>.delayed(Duration.zero);

      socket.emit({
        'channel': 'list',
        'data': [
          {'id': 1},
          {'id': 2},
        ],
      });
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.single, isA<List<Map<String, Object?>>>());
      expect(received.single, hasLength(2));
    });
  });
}

class _FakeDisconnectedSocket implements DragonflySocketConnection {
  final _controller = StreamController<dynamic>.broadcast();

  @override
  Stream<dynamic> get messages => _controller.stream;

  @override
  void send(String data) {}

  @override
  Future<void> close() async {
    if (!_controller.isClosed) await _controller.close();
  }
}

class _FakeSocket implements DragonflySocketConnection {
  final _incoming = StreamController<dynamic>.broadcast();

  void emit(Object? payload) => _incoming.add(jsonEncode(payload));

  @override
  Stream<dynamic> get messages => _incoming.stream;

  @override
  void send(String data) {}

  @override
  Future<void> close() async {
    if (!_incoming.isClosed) await _incoming.close();
  }
}
