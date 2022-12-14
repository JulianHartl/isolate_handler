
import 'package:isolate_handler/isolate_handler.dart';
import 'package:test/test.dart';

class _IsolateParams {
  final int index;

  const _IsolateParams(this.index);
}

Future<int> _handler(_IsolateParams params) async {
  return params.index;
}

void main() {
  group('IsolateHandler', () {
    late IsolateHandler<_IsolateParams, int> isolateHandler;

    setUp(() {
      const Handler<_IsolateParams, int> handler = _handler;
      isolateHandler = IsolateHandler(handler: handler);
    });

    tearDown(() {
      isolateHandler.close();
    });

    test('Isolate should be spawned without an error', () async {
      try {
        await isolateHandler.spawn();
        expect(true, true);
      } catch (e) {
        fail(e.toString());
      }
    });

    test('Isolate communication', () async {
      await isolateHandler.spawn();
      const params = _IsolateParams(2);
      final response = await isolateHandler.send(params: params);
      expect(response, equals(params.index));
    });

    test('Isolate should not be usable after being closed', () async {
      await isolateHandler.spawn();
      isolateHandler.close();
      try {
        await isolateHandler.send(params: const _IsolateParams(2));
      } catch (e) {
        expect(true, equals(true));
        return;
      }
      fail('No exception was thrown');
    });
  });
}
