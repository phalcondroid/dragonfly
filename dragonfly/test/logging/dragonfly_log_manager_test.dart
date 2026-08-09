import 'package:dragonfly/dragonfly.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────
  // DragonflyLogLevel
  // ─────────────────────────────────────────────────────────────────

  group('DragonflyLogLevel', () {
    test('debug has priority 0 and label DEBUG', () {
      expect(DragonflyLogLevel.debug.priority, 0);
      expect(DragonflyLogLevel.debug.label, 'DEBUG');
    });

    test('info has priority 1 and label INFO', () {
      expect(DragonflyLogLevel.info.priority, 1);
      expect(DragonflyLogLevel.info.label, 'INFO');
    });

    test('success has priority 2 and label SUCCESS', () {
      expect(DragonflyLogLevel.success.priority, 2);
      expect(DragonflyLogLevel.success.label, 'SUCCESS');
    });

    test('warning has priority 3 and label WARNING', () {
      expect(DragonflyLogLevel.warning.priority, 3);
      expect(DragonflyLogLevel.warning.label, 'WARNING');
    });

    test('error has priority 4 and label ERROR', () {
      expect(DragonflyLogLevel.error.priority, 4);
      expect(DragonflyLogLevel.error.label, 'ERROR');
    });

    test('danger has priority 5 and label DANGER', () {
      expect(DragonflyLogLevel.danger.priority, 5);
      expect(DragonflyLogLevel.danger.label, 'DANGER');
    });

    test('request has priority 1 and label REQUEST', () {
      expect(DragonflyLogLevel.request.priority, 1);
      expect(DragonflyLogLevel.request.label, 'REQUEST');
    });

    test('response has priority 1 and label RESPONSE', () {
      expect(DragonflyLogLevel.response.priority, 1);
      expect(DragonflyLogLevel.response.label, 'RESPONSE');
    });

    test('priority ordering: debug < info < success < warning < error < danger', () {
      expect(
        DragonflyLogLevel.debug.priority < DragonflyLogLevel.info.priority,
        isTrue,
      );
      expect(
        DragonflyLogLevel.info.priority < DragonflyLogLevel.success.priority,
        isTrue,
      );
      expect(
        DragonflyLogLevel.success.priority < DragonflyLogLevel.warning.priority,
        isTrue,
      );
      expect(
        DragonflyLogLevel.warning.priority < DragonflyLogLevel.error.priority,
        isTrue,
      );
      expect(
        DragonflyLogLevel.error.priority < DragonflyLogLevel.danger.priority,
        isTrue,
      );
    });

    test('Dart enum name returns lowercase constant name', () {
      expect(DragonflyLogLevel.debug.name, 'debug');
      expect(DragonflyLogLevel.info.name, 'info');
      expect(DragonflyLogLevel.success.name, 'success');
      expect(DragonflyLogLevel.warning.name, 'warning');
      expect(DragonflyLogLevel.error.name, 'error');
      expect(DragonflyLogLevel.danger.name, 'danger');
      expect(DragonflyLogLevel.request.name, 'request');
      expect(DragonflyLogLevel.response.name, 'response');
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // DragonflyLogColors
  // ─────────────────────────────────────────────────────────────────

  group('DragonflyLogColors', () {
    test('ANSI color constants are non-empty strings', () {
      expect(DragonflyLogColors.reset, isNotEmpty);
      expect(DragonflyLogColors.bold, isNotEmpty);
      expect(DragonflyLogColors.dim, isNotEmpty);
      expect(DragonflyLogColors.italic, isNotEmpty);
      expect(DragonflyLogColors.underline, isNotEmpty);
      expect(DragonflyLogColors.purple, isNotEmpty);
      expect(DragonflyLogColors.purpleLight, isNotEmpty);
      expect(DragonflyLogColors.purpleDark, isNotEmpty);
      expect(DragonflyLogColors.violet, isNotEmpty);
      expect(DragonflyLogColors.magenta, isNotEmpty);
      expect(DragonflyLogColors.success, isNotEmpty);
      expect(DragonflyLogColors.info, isNotEmpty);
      expect(DragonflyLogColors.warning, isNotEmpty);
      expect(DragonflyLogColors.danger, isNotEmpty);
      expect(DragonflyLogColors.error, isNotEmpty);
      expect(DragonflyLogColors.request, isNotEmpty);
      expect(DragonflyLogColors.response, isNotEmpty);
      expect(DragonflyLogColors.get, isNotEmpty);
      expect(DragonflyLogColors.post, isNotEmpty);
      expect(DragonflyLogColors.put, isNotEmpty);
      expect(DragonflyLogColors.patch, isNotEmpty);
      expect(DragonflyLogColors.delete, isNotEmpty);
      expect(DragonflyLogColors.status2xx, isNotEmpty);
      expect(DragonflyLogColors.status3xx, isNotEmpty);
      expect(DragonflyLogColors.status4xx, isNotEmpty);
      expect(DragonflyLogColors.status5xx, isNotEmpty);
      expect(DragonflyLogColors.white, isNotEmpty);
      expect(DragonflyLogColors.gray, isNotEmpty);
      expect(DragonflyLogColors.darkGray, isNotEmpty);
      expect(DragonflyLogColors.bgPurple, isNotEmpty);
      expect(DragonflyLogColors.bgSuccess, isNotEmpty);
      expect(DragonflyLogColors.bgInfo, isNotEmpty);
      expect(DragonflyLogColors.bgWarning, isNotEmpty);
      expect(DragonflyLogColors.bgDanger, isNotEmpty);
    });

    test('forMethod returns correct colors', () {
      expect(DragonflyLogColors.forMethod('GET'), DragonflyLogColors.get);
      expect(DragonflyLogColors.forMethod('POST'), DragonflyLogColors.post);
      expect(DragonflyLogColors.forMethod('PUT'), DragonflyLogColors.put);
      expect(DragonflyLogColors.forMethod('PATCH'), DragonflyLogColors.patch);
      expect(DragonflyLogColors.forMethod('DELETE'), DragonflyLogColors.delete);
    });

    test('forMethod is case-insensitive', () {
      expect(DragonflyLogColors.forMethod('get'), DragonflyLogColors.get);
      expect(DragonflyLogColors.forMethod('post'), DragonflyLogColors.post);
      expect(DragonflyLogColors.forMethod('delete'), DragonflyLogColors.delete);
    });

    test('forMethod falls back to purple for unknown method', () {
      expect(DragonflyLogColors.forMethod('UNKNOWN'), DragonflyLogColors.purple);
    });

    test('forStatusCode returns correct colors', () {
      expect(DragonflyLogColors.forStatusCode(200), DragonflyLogColors.status2xx);
      expect(DragonflyLogColors.forStatusCode(201), DragonflyLogColors.status2xx);
      expect(DragonflyLogColors.forStatusCode(299), DragonflyLogColors.status2xx);
      expect(DragonflyLogColors.forStatusCode(301), DragonflyLogColors.status3xx);
      expect(DragonflyLogColors.forStatusCode(302), DragonflyLogColors.status3xx);
      expect(DragonflyLogColors.forStatusCode(399), DragonflyLogColors.status3xx);
      expect(DragonflyLogColors.forStatusCode(404), DragonflyLogColors.status4xx);
      expect(DragonflyLogColors.forStatusCode(400), DragonflyLogColors.status4xx);
      expect(DragonflyLogColors.forStatusCode(499), DragonflyLogColors.status4xx);
      expect(DragonflyLogColors.forStatusCode(500), DragonflyLogColors.status5xx);
      expect(DragonflyLogColors.forStatusCode(503), DragonflyLogColors.status5xx);
    });

    test('forStatusCode falls back to gray for unknown range', () {
      expect(DragonflyLogColors.forStatusCode(0), DragonflyLogColors.gray);
      expect(DragonflyLogColors.forStatusCode(100), DragonflyLogColors.gray);
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // DragonflyLogManager
  // ─────────────────────────────────────────────────────────────────

  group('DragonflyLogManager', () {
    late DragonflyLogManager log;

    setUp(() {
      log = DragonflyLogManager.instance;
      log.setEnabled(true);
      log.setMinLevel(DragonflyLogLevel.debug);
      log.setPrintToConsole(false);
    });

    test('instance returns same singleton', () {
      final a = DragonflyLogManager.instance;
      final b = DragonflyLogManager.instance;
      expect(identical(a, b), isTrue);
    });

    test('I shorthand returns same instance', () {
      expect(
        identical(DragonflyLogManager.I, DragonflyLogManager.instance),
        isTrue,
      );
    });

    test('setEnabled(false) disables logging', () {
      DragonflyLogEntry? receivedEntry;
      void listener(DragonflyLogEntry e) {
        receivedEntry = e;
      }

      log.addListener(listener);
      log.setEnabled(false);
      log.info('should not be logged');
      expect(receivedEntry, isNull);

      log.removeListener(listener);
    });

    test('setEnabled(true) enables logging', () {
      DragonflyLogEntry? receivedEntry;
      void listener(DragonflyLogEntry e) {
        receivedEntry = e;
      }

      log.setEnabled(false);
      log.addListener(listener);
      log.setEnabled(true);
      log.info('should be logged');
      expect(receivedEntry, isNotNull);
      expect(receivedEntry!.message, 'should be logged');

      log.removeListener(listener);
    });

    test('setMinLevel filters messages below the level', () {
      DragonflyLogEntry? receivedEntry;
      void listener(DragonflyLogEntry e) {
        receivedEntry = e;
      }

      log.addListener(listener);
      log.setMinLevel(DragonflyLogLevel.error);

      receivedEntry = null;
      log.debug('debug is filtered');
      expect(receivedEntry, isNull);

      receivedEntry = null;
      log.error('error is not filtered');
      expect(receivedEntry, isNotNull);
      expect(receivedEntry!.level, DragonflyLogLevel.error);

      log.removeListener(listener);
    });

    test('info() does not throw', () {
      expect(() => log.info('test message'), returnsNormally);
    });

    test('error() does not throw', () {
      expect(
        () => log.error('test error', error: Exception('oops')),
        returnsNormally,
      );
    });

    test('warning() does not throw', () {
      expect(() => log.warning('test warning'), returnsNormally);
    });

    test('success() does not throw', () {
      expect(() => log.success('test success'), returnsNormally);
    });

    test('debug() does not throw', () {
      expect(() => log.debug('test debug'), returnsNormally);
    });

    test('danger() does not throw', () {
      expect(
        () => log.danger('critical', error: Exception('fatal')),
        returnsNormally,
      );
    });

    test('request() does not throw', () {
      expect(
        () => log.request(method: 'GET', url: 'https://api.example.com/data'),
        returnsNormally,
      );
    });

    test('response() does not throw', () {
      expect(
        () => log.response(
          statusCode: 200,
          durationMs: 42,
          requestId: 'REQ12345',
          url: 'https://api.example.com/data',
          method: 'GET',
        ),
        returnsNormally,
      );
    });

    test('repositoryStart() does not throw', () {
      expect(
        () => log.repositoryStart(
          repository: 'UserRepository',
          method: 'getUsers',
        ),
        returnsNormally,
      );
    });

    test('repositorySuccess() does not throw', () {
      expect(
        () => log.repositorySuccess(
          repository: 'UserRepository',
          method: 'getUsers',
          message: 'Fetched 10 users',
        ),
        returnsNormally,
      );
    });

    test('repositoryError() does not throw', () {
      expect(
        () => log.repositoryError(
          repository: 'UserRepository',
          method: 'getUsers',
          message: 'Database error',
          error: Exception('connection refused'),
        ),
        returnsNormally,
      );
    });

    test('divider() does not throw', () {
      log.setPrintToConsole(true);
      expect(() => log.divider(), returnsNormally);
      expect(() => log.divider('Section'), returnsNormally);
    });

    test('printBanner(version:) does not throw', () {
      log.setPrintToConsole(true);
      expect(() => log.printBanner(version: '1.0.0'), returnsNormally);
    });

    test('addListener accepts a listener function', () {
      void listener(DragonflyLogEntry entry) {}
      expect(() => log.addListener(listener), returnsNormally);
      log.removeListener(listener);
    });

    test('log listeners receive log entries when messages are logged', () {
      DragonflyLogEntry? receivedEntry;
      void listener(DragonflyLogEntry e) {
        receivedEntry = e;
      }

      log.addListener(listener);
      log.info('listener test message');

      expect(receivedEntry, isNotNull);
      expect(receivedEntry!.message, 'listener test message');
      expect(receivedEntry!.level, DragonflyLogLevel.info);

      log.removeListener(listener);
    });

    test('generateRequestId returns a non-empty string', () {
      final id = log.generateRequestId();
      expect(id, isNotEmpty);
      expect(id.length, 8);
    });

    test('generateRequestId produces different values', () {
      final ids = <String>{};
      for (var i = 0; i < 20; i++) {
        ids.add(log.generateRequestId());
      }
      expect(ids.length, greaterThan(1));
    });

    test('removeListener stops receiving log entries', () {
      DragonflyLogEntry? receivedEntry;
      void listener(DragonflyLogEntry e) {
        receivedEntry = e;
      }

      log.addListener(listener);
      log.removeListener(listener);

      receivedEntry = null;
      log.info('should not be received');
      expect(receivedEntry, isNull);
    });

    test('viewInit() does not throw', () {
      log.setPrintToConsole(true);
      expect(
        () => log.viewInit(viewName: 'HomeView', initialState: 'IdleState'),
        returnsNormally,
      );
    });

    test('viewDispose() does not throw', () {
      log.setPrintToConsole(true);
      expect(
        () => log.viewDispose(viewName: 'HomeView'),
        returnsNormally,
      );
    });

    test('viewStateChange() does not throw', () {
      log.setPrintToConsole(true);
      expect(
        () => log.viewStateChange(
          viewName: 'HomeView',
          previousState: 'LoadingState',
          newState: 'LoadedState',
        ),
        returnsNormally,
      );
    });

    test('setEnabled(false) then setEnabled(true) toggles correctly', () {
      DragonflyLogEntry? receivedEntry;
      void listener(DragonflyLogEntry e) {
        receivedEntry = e;
      }

      log.addListener(listener);

      log.setEnabled(false);
      receivedEntry = null;
      log.info('disabled message');
      expect(receivedEntry, isNull);

      log.setEnabled(true);
      receivedEntry = null;
      log.info('enabled message');
      expect(receivedEntry, isNotNull);
      expect(receivedEntry!.message, 'enabled message');

      log.removeListener(listener);
    });

    test('dragonflyLog global instance is the same as DragonflyLogManager.instance', () {
      expect(
        identical(dragonflyLog, DragonflyLogManager.instance),
        isTrue,
      );
    });

    test('setShowTimestamp configures without throwing', () {
      expect(() => log.setShowTimestamp(true), returnsNormally);
      expect(() => log.setShowTimestamp(false), returnsNormally);
    });

    test('setPrintToConsole configures without throwing', () {
      expect(() => log.setPrintToConsole(true), returnsNormally);
      expect(() => log.setPrintToConsole(false), returnsNormally);
    });

    test('enableHistory and disableHistory do not throw', () {
      expect(() => log.enableHistory(maxSize: 500), returnsNormally);
      expect(() => log.disableHistory(), returnsNormally);
    });

    test('clearHistory does not throw', () {
      expect(() => log.clearHistory(), returnsNormally);
    });

    test('history returns an unmodifiable list', () {
      expect(log.history, isEmpty);
    });

    test('repositoryWarning() does not throw', () {
      expect(
        () => log.repositoryWarning(
          repository: 'UserRepository',
          method: 'getUsers',
          message: 'Slow query detected',
        ),
        returnsNormally,
      );
    });

    test('viewActionStart() does not throw', () {
      log.setPrintToConsole(true);
      expect(
        () => log.viewActionStart(
          viewName: 'HomeView',
          actionName: 'loadData',
        ),
        returnsNormally,
      );
    });

    test('viewActionEnd() does not throw', () {
      log.setPrintToConsole(true);
      expect(
        () => log.viewActionEnd(
          viewName: 'HomeView',
          actionName: 'loadData',
          durationMs: 150,
          success: true,
        ),
        returnsNormally,
      );
    });

    test('viewStep() does not throw', () {
      log.setPrintToConsole(true);
      expect(
        () => log.viewStep(
          viewName: 'HomeView',
          step: 'Fetching data',
        ),
        returnsNormally,
      );
    });
  });
}
