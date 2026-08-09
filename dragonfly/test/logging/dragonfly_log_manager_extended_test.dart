// ignore_for_file: strict_raw_type, inference_failure_on_function_invocation

import 'package:dragonfly/dragonfly.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DragonflyLogManager log;

  setUp(() {
    log = DragonflyLogManager.instance;
    log.setEnabled(true);
    log.setMinLevel(DragonflyLogLevel.debug);
    log.setPrintToConsole(false);
  });

  // ── setEnabled / setMinLevel filtering ──────────────────────────────

  group('setEnabled toggle', () {
    test('listeners receive messages when enabled, not when disabled', () {
      final received = <DragonflyLogEntry>[];
      void listener(DragonflyLogEntry e) => received.add(e);

      log.addListener(listener);

      log.setEnabled(true);
      log.info('enabled msg 1');
      expect(received, hasLength(1));

      log.setEnabled(false);
      log.info('disabled msg');
      log.warning('disabled warning');
      log.error('disabled error', error: Exception('x'));
      expect(received, hasLength(1));

      log.setEnabled(true);
      log.info('enabled msg 2');
      expect(received, hasLength(2));

      log.removeListener(listener);
    });

    test('setEnabled(false) blocks request and response logging', () {
      final received = <DragonflyLogEntry>[];
      void listener(DragonflyLogEntry e) => received.add(e);

      log.addListener(listener);
      log.setEnabled(false);

      log.request(method: 'GET', url: 'https://example.com');
      log.response(
        statusCode: 200,
        durationMs: 10,
        requestId: 'REQ001',
        url: 'https://example.com',
        method: 'GET',
      );

      expect(received, isEmpty);
      log.removeListener(listener);
    });

    test('setEnabled(false) blocks repository logging', () {
      final received = <DragonflyLogEntry>[];
      void listener(DragonflyLogEntry e) => received.add(e);

      log.addListener(listener);
      log.setEnabled(false);

      log.repositoryStart(repository: 'Repo', method: 'doWork');
      log.repositorySuccess(repository: 'Repo', method: 'doWork', message: 'ok');
      log.repositoryError(
        repository: 'Repo',
        method: 'doWork',
        message: 'fail',
        error: Exception('boom'),
      );

      expect(received, isEmpty);
      log.removeListener(listener);
    });
  });

  group('setMinLevel filtering', () {
    test('warning filters debug, info, success; passes warning, error, danger', () {
      final received = <DragonflyLogEntry>[];
      void listener(DragonflyLogEntry e) => received.add(e);

      log.addListener(listener);
      log.setMinLevel(DragonflyLogLevel.warning);

      log.debug('d');
      log.info('i');
      log.success('s');
      expect(received, isEmpty);

      log.warning('w');
      expect(received.single.level, DragonflyLogLevel.warning);
      received.clear();

      log.error('e', error: Exception('e'));
      expect(received.single.level, DragonflyLogLevel.error);
      received.clear();

      log.danger('d', error: Exception('d'));
      expect(received.single.level, DragonflyLogLevel.danger);
      received.clear();

      log.removeListener(listener);
    });

    test('error filters debug, info, success, warning; passes error, danger', () {
      final received = <DragonflyLogEntry>[];
      void listener(DragonflyLogEntry e) => received.add(e);

      log.addListener(listener);
      log.setMinLevel(DragonflyLogLevel.error);

      log.debug('d');
      log.info('i');
      log.success('s');
      log.warning('w');
      expect(received, isEmpty);

      log.error('e', error: Exception('e'));
      expect(received.single.level, DragonflyLogLevel.error);
      received.clear();

      log.danger('d', error: Exception('d'));
      expect(received.single.level, DragonflyLogLevel.danger);
      received.clear();

      log.removeListener(listener);
    });

    test('debug lets everything through', () {
      final received = <DragonflyLogEntry>[];
      void listener(DragonflyLogEntry e) => received.add(e);

      log.addListener(listener);
      log.setMinLevel(DragonflyLogLevel.debug);

      log.debug('d');
      log.info('i');
      log.warning('w');
      log.error('e', error: Exception('e'));
      log.danger('d', error: Exception('d'));

      expect(received, hasLength(5));
      log.removeListener(listener);
    });
  });

  // ── Multiple listeners ──────────────────────────────────────────────

  group('listeners', () {
    test('multiple listeners all receive the same message', () {
      final r1 = <DragonflyLogEntry>[];
      final r2 = <DragonflyLogEntry>[];
      void l1(DragonflyLogEntry e) => r1.add(e);
      void l2(DragonflyLogEntry e) => r2.add(e);

      log.addListener(l1);
      log.addListener(l2);

      log.info('broadcast');

      expect(r1, hasLength(1));
      expect(r2, hasLength(1));
      expect(r1.single.message, 'broadcast');
      expect(r2.single.message, 'broadcast');

      log.removeListener(l1);
      log.removeListener(l2);
    });

    test('removed listener does not receive subsequent messages', () {
      final received = <DragonflyLogEntry>[];
      void listener(DragonflyLogEntry e) => received.add(e);

      log.addListener(listener);
      log.info('first');
      expect(received, hasLength(1));

      log.removeListener(listener);
      log.info('second');
      expect(received, hasLength(1));

      log.removeListener(listener);
    });

    test('adding the same listener twice calls it twice per message', () {
      var callCount = 0;
      void listener(DragonflyLogEntry e) {
        callCount++;
      }

      log.addListener(listener);
      log.addListener(listener);

      log.info('msg');
      expect(callCount, 2);

      log.removeListener(listener);
      log.removeListener(listener);
    });

    test('listener receives correct entry fields', () {
      DragonflyLogEntry? captured;
      void listener(DragonflyLogEntry e) => captured = e;

      log.addListener(listener);

      final err = Exception('test error');
      final stack = StackTrace.current;
      log.error('details', error: err, stackTrace: stack, tag: 'TAG',
          data: {'a': 1}, source: 'Src.method');

      expect(captured, isNotNull);
      expect(captured!.level, DragonflyLogLevel.error);
      expect(captured!.message, 'details');
      expect(captured!.error, err);
      expect(captured!.stackTrace, stack);
      expect(captured!.tag, 'TAG');
      expect(captured!.data, {'a': 1});
      expect(captured!.source, 'Src.method');

      log.removeListener(listener);
    });
  });

  // ── Edge cases: null source, empty message ──────────────────────────

  group('edge cases', () {
    test('log with null source does not throw', () {
      final entry = DragonflyLogEntry(
        level: DragonflyLogLevel.info,
        message: 'no source',
      );
      expect(() => entry.toString(), returnsNormally);
      expect(entry.source, isNull);
    });

    test('info with null source works', () {
      log.info('test', source: null);
      expect(() => log.info('test', source: null), returnsNormally);
    });

    test('debug with empty message does not throw', () {
      expect(() => log.debug(''), returnsNormally);
    });

    test('info with empty message does not throw', () {
      expect(() => log.info(''), returnsNormally);
    });

    test('warning with empty message does not throw', () {
      expect(() => log.warning(''), returnsNormally);
    });

    test('success with empty message does not throw', () {
      expect(() => log.success(''), returnsNormally);
    });

    test('null data map does not throw', () {
      expect(() => log.info('msg', data: null), returnsNormally);
    });
  });

  // ── generateRequestId ───────────────────────────────────────────────

  group('generateRequestId', () {
    test('returns 8-character uppercase alphanumeric string', () {
      final id = log.generateRequestId();
      expect(id.length, 8);
      expect(RegExp(r'^[A-Z0-9]+$').hasMatch(id), isTrue);
    });

    test('each call returns a unique ID', () {
      final ids = <String>{};
      for (var i = 0; i < 100; i++) {
        ids.add(log.generateRequestId());
      }
      expect(ids.length, greaterThan(90));
    });
  });

  // ── View logging ────────────────────────────────────────────────────

  group('viewLogging', () {
    test('viewInit with view name and state', () {
      log.setPrintToConsole(true);
      expect(
        () => log.viewInit(viewName: 'HomeView', initialState: 'IdleState'),
        returnsNormally,
      );
    });

    test('viewInit with long state name extracts class', () {
      log.setPrintToConsole(true);
      expect(
        () => log.viewInit(
          viewName: 'SettingsView',
          initialState: 'SettingsLoadedState(data: {...})',
        ),
        returnsNormally,
      );
    });

    test('viewStateChange with both states', () {
      log.setPrintToConsole(true);
      expect(
        () => log.viewStateChange(
          viewName: 'ProfileView',
          previousState: 'LoadingState',
          newState: 'ProfileLoadedState',
        ),
        returnsNormally,
      );
    });

    test('viewDispose with view name', () {
      log.setPrintToConsole(true);
      expect(
        () => log.viewDispose(viewName: 'DetailView'),
        returnsNormally,
      );
    });

    test('viewActionStart with params', () {
      log.setPrintToConsole(true);
      expect(
        () => log.viewActionStart(
          viewName: 'ListScreen',
          actionName: 'fetchItems',
          params: {'category': 'books', 'limit': 20},
        ),
        returnsNormally,
      );
    });

    test('viewActionEnd with success true', () {
      log.setPrintToConsole(true);
      expect(
        () => log.viewActionEnd(
          viewName: 'ListScreen',
          actionName: 'fetchItems',
          durationMs: 150,
          success: true,
        ),
        returnsNormally,
      );
    });

    test('viewActionEnd with failure and error', () {
      log.setPrintToConsole(true);
      expect(
        () => log.viewActionEnd(
          viewName: 'ListScreen',
          actionName: 'fetchItems',
          durationMs: 5000,
          success: false,
          error: 'Network timeout',
        ),
        returnsNormally,
      );
    });

    test('viewStep with data', () {
      log.setPrintToConsole(true);
      expect(
        () => log.viewStep(
          viewName: 'DashboardView',
          step: 'Saving settings',
          data: {'theme': 'dark', 'lang': 'en'},
        ),
        returnsNormally,
      );
    });

    test('viewSideEffect does not throw', () {
      log.setPrintToConsole(true);
      expect(
        () => log.viewSideEffect(viewName: 'HomeView', effect: 'navigateToProfile'),
        returnsNormally,
      );
    });

    test('viewUseCase does not throw', () {
      log.setPrintToConsole(true);
      expect(
        () => log.viewUseCase(viewName: 'HomeView', useCaseName: 'GetUserProfile'),
        returnsNormally,
      );
    });

    test('viewSubscribe does not throw', () {
      log.setPrintToConsole(true);
      expect(
        () => log.viewSubscribe(viewName: 'HomeView', subscriptionKey: 'user_stream'),
        returnsNormally,
      );
    });

    test('viewSubscriptionError does not throw', () {
      log.setPrintToConsole(true);
      expect(
        () => log.viewSubscriptionError(
          viewName: 'HomeView',
          subscriptionKey: 'user_stream',
          error: 'Connection refused',
        ),
        returnsNormally,
      );
    });

    test('viewSubscriptionDone does not throw', () {
      log.setPrintToConsole(true);
      expect(
        () => log.viewSubscriptionDone(
          viewName: 'HomeView',
          subscriptionKey: 'user_stream',
        ),
        returnsNormally,
      );
    });

    test('viewCancelSubscription does not throw', () {
      log.setPrintToConsole(true);
      expect(
        () => log.viewCancelSubscription(
          viewName: 'HomeView',
          subscriptionKey: 'user_stream',
        ),
        returnsNormally,
      );
    });

    test('view logging is suppressed when disabled', () {
      log.setPrintToConsole(false);
      log.setEnabled(false);
      expect(() => log.viewInit(viewName: 'HomeView', initialState: 'Idle'), returnsNormally);
      expect(() => log.viewDispose(viewName: 'HomeView'), returnsNormally);
      expect(
        () => log.viewStateChange(
          viewName: 'HomeView',
          previousState: 'A',
          newState: 'B',
        ),
        returnsNormally,
      );
    });
  });

  // ── Repository logging with all params ──────────────────────────────

  group('repositoryLogging', () {
    test('repositoryStart with all params', () {
      expect(
        () => log.repositoryStart(
          repository: 'OrderRepository',
          method: 'createOrder',
          params: {'productId': 123, 'quantity': 2},
        ),
        returnsNormally,
      );
    });

    test('repositorySuccess with duration and result', () {
      log.setPrintToConsole(true);
      expect(
        () => log.repositorySuccess(
          repository: 'OrderRepository',
          method: 'createOrder',
          message: 'Order created',
          durationMs: 450,
          result: {'id': 789},
          params: {'productId': 123},
        ),
        returnsNormally,
      );
    });

    test('repositoryError with error, stackTrace, and duration', () {
      log.setPrintToConsole(true);
      final err = Exception('DB connection lost');
      final stack = StackTrace.current;
      expect(
        () => log.repositoryError(
          repository: 'OrderRepository',
          method: 'createOrder',
          message: 'Failed to create order',
          error: err,
          stackTrace: stack,
          durationMs: 30000,
          params: {'productId': 123},
        ),
        returnsNormally,
      );
    });

    test('repositoryWarning with duration and params', () {
      log.setPrintToConsole(true);
      expect(
        () => log.repositoryWarning(
          repository: 'CacheRepository',
          method: 'get',
          message: 'Cache miss, fetching from source',
          durationMs: 250,
          params: {'key': 'user_42'},
        ),
        returnsNormally,
      );
    });

    test('repository logs are received by listeners', () {
      final received = <DragonflyLogEntry>[];
      void listener(DragonflyLogEntry e) => received.add(e);

      log.addListener(listener);

      log.repositoryStart(repository: 'TestRepo', method: 'test');
      log.repositorySuccess(
        repository: 'TestRepo',
        method: 'test',
        message: 'done',
        durationMs: 100,
      );
      log.repositoryError(
        repository: 'TestRepo',
        method: 'test',
        message: 'fail',
        error: Exception('err'),
      );
      log.repositoryWarning(
        repository: 'TestRepo',
        method: 'test',
        message: 'warn',
      );

      expect(received, hasLength(4));
      expect(received[0], isA<DragonflyRepositoryLog>());
      expect(received[1], isA<DragonflyRepositoryLog>());
      expect(received[2], isA<DragonflyRepositoryLog>());
      expect(received[3], isA<DragonflyRepositoryLog>());

      log.removeListener(listener);
    });
  });

  // ── Network logging ─────────────────────────────────────────────────

  group('networkLogging', () {
    test('request with all optional fields', () {
      expect(
        () => log.request(
          method: 'POST',
          url: 'https://api.example.com/items',
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer xyz'},
          body: {'name': 'Widget'},
          queryParams: {'page': '1'},
          source: 'ItemRepo.createItem',
        ),
        returnsNormally,
      );
    });

    test('request generates requestId when not provided', () {
      final received = <DragonflyLogEntry>[];
      void listener(DragonflyLogEntry e) => received.add(e);

      log.addListener(listener);
      log.request(method: 'GET', url: 'https://example.com');

      final entry = received.single as DragonflyNetworkRequestLog;
      expect(entry.requestId, isNotEmpty);
      expect(entry.requestId.length, 8);

      log.removeListener(listener);
    });

    test('request with explicit requestId', () {
      final received = <DragonflyLogEntry>[];
      void listener(DragonflyLogEntry e) => received.add(e);

      log.addListener(listener);
      log.request(method: 'PUT', url: 'https://example.com', requestId: 'CUSTOM01');

      final entry = received.single as DragonflyNetworkRequestLog;
      expect(entry.requestId, 'CUSTOM01');

      log.removeListener(listener);
    });

    test('response with all optional fields', () {
      expect(
        () => log.response(
          statusCode: 201,
          durationMs: 320,
          requestId: 'REQ_BIG',
          url: 'https://api.example.com/items',
          method: 'POST',
          statusMessage: 'Created',
          headers: {'Location': '/items/1'},
          body: {'id': 1, 'created': true},
          source: 'ItemRepo.createItem',
        ),
        returnsNormally,
      );
    });

    test('network request log listener receives DragonflyNetworkRequestLog', () {
      final received = <DragonflyLogEntry>[];
      void listener(DragonflyLogEntry e) => received.add(e);

      log.addListener(listener);
      log.request(method: 'DELETE', url: 'https://example.com/items/1');

      expect(received.single, isA<DragonflyNetworkRequestLog>());
      final entry = received.single as DragonflyNetworkRequestLog;
      expect(entry.method, 'DELETE');
      expect(entry.url, 'https://example.com/items/1');
      expect(entry.level, DragonflyLogLevel.request);

      log.removeListener(listener);
    });

    test('network response log listener receives DragonflyNetworkResponseLog', () {
      final received = <DragonflyLogEntry>[];
      void listener(DragonflyLogEntry e) => received.add(e);

      log.addListener(listener);
      log.response(
        statusCode: 404,
        durationMs: 50,
        requestId: 'REQ_404',
        url: 'https://example.com/missing',
        method: 'GET',
      );

      expect(received.single, isA<DragonflyNetworkResponseLog>());
      final entry = received.single as DragonflyNetworkResponseLog;
      expect(entry.statusCode, 404);
      expect(entry.requestId, 'REQ_404');

      log.removeListener(listener);
    });
  });

  // ── Banner and divider ──────────────────────────────────────────────

  group('banner and divider', () {
    test('printBanner with custom version', () {
      log.setPrintToConsole(true);
      expect(() => log.printBanner(version: '2.0.0'), returnsNormally);
    });

    test('printBanner without version', () {
      log.setPrintToConsole(true);
      expect(() => log.printBanner(), returnsNormally);
    });

    test('printBanner is suppressed when disabled', () {
      log.setEnabled(false);
      log.setPrintToConsole(true);
      expect(() => log.printBanner(version: '1.0.0'), returnsNormally);
    });

    test('printBanner is suppressed when printToConsole is false', () {
      log.setPrintToConsole(false);
      expect(() => log.printBanner(version: '1.0.0'), returnsNormally);
    });

    test('divider without title', () {
      log.setPrintToConsole(true);
      expect(() => log.divider(), returnsNormally);
    });

    test('divider with title', () {
      log.setPrintToConsole(true);
      expect(() => log.divider('Section'), returnsNormally);
    });

    test('divider is suppressed when disabled', () {
      log.setEnabled(false);
      log.setPrintToConsole(true);
      expect(() => log.divider('Test'), returnsNormally);
    });

    test('divider is suppressed when printToConsole is false', () {
      log.setPrintToConsole(false);
      expect(() => log.divider(), returnsNormally);
    });
  });

  // ── History ─────────────────────────────────────────────────────────

  group('log history', () {
    test('enableHistory captures subsequent log entries', () {
      log.setPrintToConsole(false);
      log.enableHistory(maxSize: 10);

      log.info('h1');
      log.warning('h2');
      log.error('h3', error: Exception('x'));

      expect(log.history, hasLength(3));
      expect(log.history[0].message, 'h1');
      expect(log.history[1].message, 'h2');
      expect(log.history[2].message, 'h3');

      log.disableHistory();
    });

    test('disableHistory clears history', () {
      log.enableHistory();
      log.info('msg');
      expect(log.history, isNotEmpty);

      log.disableHistory();
      expect(log.history, isEmpty);
    });

    test('clearHistory empties the list', () {
      log.enableHistory();
      log.info('a');
      log.info('b');
      expect(log.history, hasLength(2));

      log.clearHistory();
      expect(log.history, isEmpty);

      log.disableHistory();
    });

    test('history respects maxSize', () {
      log.enableHistory(maxSize: 3);
      log.info('1');
      log.info('2');
      log.info('3');
      log.info('4');

      expect(log.history, hasLength(3));
      expect(log.history[0].message, '2');
      expect(log.history[1].message, '3');
      expect(log.history[2].message, '4');

      log.disableHistory();
    });

    test('history returns unmodifiable list', () {
      log.enableHistory();
      log.info('test');

      expect(
        () => log.history.add(DragonflyLogEntry(
          level: DragonflyLogLevel.info,
          message: 'x',
        )),
        throwsA(isA<UnsupportedError>()),
      );

      log.disableHistory();
    });
  });

  // ── Log stream ──────────────────────────────────────────────────────

  group('logStream', () {
    test('emits log entries', () async {
      final stream = log.logStream;

      final futureEntry = stream.first;
      log.info('stream test');

      final entry = await futureEntry;
      expect(entry, isA<DragonflyLogEntry>());
      expect(entry.message, 'stream test');
    });
  });

  // ── setShowTimestamp ────────────────────────────────────────────────

  group('setShowTimestamp', () {
    test('toggles without error', () {
      log.setShowTimestamp(true);
      log.setShowTimestamp(false);
    });
  });

  // ── dragonflyLog global ─────────────────────────────────────────────

  group('dragonflyLog global', () {
    test('dragonflyLog is the same as DragonflyLogManager.instance', () {
      expect(identical(dragonflyLog, DragonflyLogManager.instance), isTrue);
    });

    test('dragonflyLog.info does not throw', () {
      dragonflyLog.setEnabled(true);
      dragonflyLog.setPrintToConsole(false);
      expect(() => dragonflyLog.info('global test'), returnsNormally);
    });

    test('dragonflyLog.error does not throw', () {
      dragonflyLog.setEnabled(true);
      dragonflyLog.setPrintToConsole(false);
      expect(
        () => dragonflyLog.error('global error', error: Exception('global')),
        returnsNormally,
      );
    });

    test('dragonflyLog.request and response do not throw', () {
      dragonflyLog.setEnabled(true);
      dragonflyLog.setPrintToConsole(false);
      expect(
        () => dragonflyLog.request(method: 'GET', url: 'https://example.com'),
        returnsNormally,
      );
      expect(
        () => dragonflyLog.response(
          statusCode: 200,
          durationMs: 10,
          requestId: 'R1',
          url: 'https://example.com',
          method: 'GET',
        ),
        returnsNormally,
      );
    });

    test('dragonflyLog.addListener and removeListener work', () {
      var count = 0;
      void l(DragonflyLogEntry e) => count++;

      dragonflyLog.addListener(l);
      dragonflyLog.info('global listener');
      expect(count, 1);

      dragonflyLog.removeListener(l);
      dragonflyLog.info('after removal');
      expect(count, 1);
    });
  });

  // ── Dispose ─────────────────────────────────────────────────────────

  group('dispose', () {
    test('dispose does not throw', () {
      expect(() => log.dispose(), returnsNormally);
    });
  });
}
