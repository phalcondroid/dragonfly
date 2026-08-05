import 'dart:async';
import 'dart:convert';

import 'package:dragonfly/dragonfly.dart';
import 'package:flutter_test/flutter_test.dart';

/// An in-memory [DragonflySocketConnection] so the adapter can be driven
/// without a server.
class FakeSocket implements DragonflySocketConnection {
  final _incoming = StreamController<dynamic>.broadcast();
  final List<String> _sent = [];

  /// Frames the adapter wrote, decoded from JSON.
  List<Map<String, dynamic>> get sentFrames =>
      _sent.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

  /// Pushes a server frame to the adapter.
  void emit(Object? payload) => _incoming.add(jsonEncode(payload));

  /// Pushes a raw (possibly non-JSON) frame.
  void emitRaw(dynamic payload) => _incoming.add(payload);

  void fail(Object error) => _incoming.addError(error);

  void closeFromServer() => _incoming.close();

  @override
  Stream<dynamic> get messages => _incoming.stream;

  @override
  void send(String data) => _sent.add(data);

  @override
  Future<void> close() async {
    if (!_incoming.isClosed) await _incoming.close();
  }
}

void main() {
  late FakeSocket socket;
  late DragonflyWebSocketAdapter adapter;

  DragonflyWebSocketAdapter build({DragonflyRealtimeConfig? config}) {
    socket = FakeSocket();
    return DragonflyWebSocketAdapter(
      config: config ??
          const DragonflyRealtimeConfig(
            url: 'wss://example.test/ws',
            autoReconnect: false,
          ),
      enableLogging: false,
      connectionFactory: (_) => socket,
    );
  }

  setUp(() => adapter = build());
  tearDown(() async => adapter.disconnect());

  group('connection lifecycle', () {
    test('starts disconnected and reports connected after connect', () async {
      expect(adapter.state, DragonflyRealtimeState.disconnected);
      await adapter.connect();
      expect(adapter.state, DragonflyRealtimeState.connected);
    });

    test('connect is idempotent', () async {
      await adapter.connect();
      await adapter.connect();
      expect(adapter.state, DragonflyRealtimeState.connected);
    });

    test('disconnect moves to closed', () async {
      await adapter.connect();
      await adapter.disconnect();
      expect(adapter.state, DragonflyRealtimeState.closed);
    });

    test('does not connect until a stream is listened to', () async {
      adapter.subscribeToObject('characters');
      await Future<void>.delayed(Duration.zero);
      expect(adapter.state, DragonflyRealtimeState.disconnected);
    });
  });

  group('subscriptions', () {
    test('routes an enveloped payload to the matching channel', () async {
      final received = <Map<String, Object?>>[];
      adapter.subscribeToObject('characters').listen(received.add);

      await Future<void>.delayed(Duration.zero);
      socket.emit({
        'channel': 'characters',
        'data': {'id': 1, 'name': 'Rick'},
      });
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.single['name'], 'Rick');
    });

    test('does not deliver events for a different channel', () async {
      final received = <Map<String, Object?>>[];
      adapter.subscribeToObject('characters').listen(received.add);

      await Future<void>.delayed(Duration.zero);
      socket.emit({
        'channel': 'episodes',
        'data': {'id': 9},
      });
      await Future<void>.delayed(Duration.zero);

      expect(received, isEmpty);
    });

    test('subscribeToList yields a list of objects', () async {
      final received = <List<Map<String, Object?>>>[];
      adapter.subscribeToList('batch').listen(received.add);

      await Future<void>.delayed(Duration.zero);
      socket.emit({
        'channel': 'batch',
        'data': [
          {'id': 1},
          {'id': 2},
        ],
      });
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.single, hasLength(2));
      expect(received.single.last['id'], 2);
    });

    test('sends a subscribe frame naming the channel', () async {
      adapter.subscribeToObject('characters').listen((_) {});
      await Future<void>.delayed(Duration.zero);

      expect(
        socket.sentFrames,
        contains(allOf(
          containsPair('action', 'subscribe'),
          containsPair('channel', 'characters'),
        )),
      );
    });

    test('two listeners on one channel share a single subscribe frame',
        () async {
      final stream = adapter.subscribeToObject('characters');
      stream.listen((_) {});
      stream.listen((_) {});
      await Future<void>.delayed(Duration.zero);

      final subscribes = socket.sentFrames
          .where((f) => f['action'] == 'subscribe')
          .toList();
      expect(subscribes, hasLength(1));
    });

    test('malformed JSON is ignored rather than killing the stream', () async {
      final received = <Map<String, Object?>>[];
      var errored = false;
      adapter
          .subscribeToObject('characters')
          .listen(received.add, onError: (_) => errored = true);

      await Future<void>.delayed(Duration.zero);
      socket.emitRaw('this is not json');
      socket.emit({
        'channel': 'characters',
        'data': {'id': 1},
      });
      await Future<void>.delayed(Duration.zero);

      expect(errored, isFalse);
      expect(received, hasLength(1));
    });
  });

  group('envelope-free servers', () {
    test('with channelField null every message reaches every subscriber',
        () async {
      adapter = build(
        config: const DragonflyRealtimeConfig(
          url: 'wss://example.test/characters',
          channelField: null,
          subscribeAction: null,
          autoReconnect: false,
        ),
      );

      final received = <Map<String, Object?>>[];
      adapter.subscribeToObject('anything').listen(received.add);
      await Future<void>.delayed(Duration.zero);

      socket.emit({'id': 7, 'name': 'Morty'});
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.single['name'], 'Morty');
    });

    test('no subscribe frame is sent when subscribeAction is null', () async {
      adapter = build(
        config: const DragonflyRealtimeConfig(
          url: 'wss://example.test/characters',
          channelField: null,
          subscribeAction: null,
          autoReconnect: false,
        ),
      );
      adapter.subscribeToObject('anything').listen((_) {});
      await Future<void>.delayed(Duration.zero);

      expect(socket.sentFrames, isEmpty);
    });
  });

  group('publish', () {
    test('writes an envelope carrying channel and payload', () async {
      await adapter.connect();
      await adapter.publish('characters', {'name': 'Summer'});

      expect(
        socket.sentFrames,
        contains(allOf(
          containsPair('channel', 'characters'),
          containsPair('data', containsPair('name', 'Summer')),
        )),
      );
    });
  });

  group('failure handling', () {
    test('a socket error is surfaced on the channel stream', () async {
      final errors = <Object>[];
      adapter.subscribeToObject('characters').listen((_) {}, onError: errors.add);
      await Future<void>.delayed(Duration.zero);

      socket.fail(StateError('boom'));
      await Future<void>.delayed(Duration.zero);

      expect(errors, hasLength(1));
      expect(errors.single, isA<DragonflyRealtimeException>());
    });

    test('with autoReconnect off a closed socket ends in disconnected',
        () async {
      await adapter.connect();
      socket.closeFromServer();
      await Future<void>.delayed(Duration.zero);

      expect(adapter.state, DragonflyRealtimeState.disconnected);
    });
  });
}
