import 'dart:async';
import 'dart:isolate';

typedef Handler<Params, Response> = Future<Response> Function(Params);

/// Makes it easier to interact with an [Isolate].
///
/// Executes one [Function] with [Params] and returns a [Response].
class IsolateHandler<Params, Response> {
  late final SendPort _isolateSendPort;
  Isolate? _isolate;
  bool _closed = false;

  final Completer _initializedCompleter = Completer();

  /// Is called whenever [send] is called.
  final Handler<Params, Response> handler;

  IsolateHandler({
    required this.handler,
  });

  /// Kills the [Isolate] and interrupts all ongoing tasks immediately.
  ///
  /// Isolate cannot be used after.
  void close() {
    _closed = true;
    _isolate?.kill(priority: Isolate.immediate);
  }

  /// Executes the [handler] with the given [params] and returns the corresponding [Response].
  Future<Response> send({required Params params}) async {
    await _initializedCompleter.future;
    if (_closed) {
      throw Exception('Cannot send after closing the isolate.');
    }
    ReceivePort responsePort = ReceivePort();

    _isolateSendPort.send({
      'params': params,
      'port': responsePort.sendPort,
    });
    final response = (await responsePort.first) as Response;
    return response;
  }

  bool get isSpawned => _initializedCompleter.isCompleted;

  /// Spawns the [Isolate].
  ///
  /// Needs to be called before any other interactions.
  Future<void> spawn() async {
    if (isSpawned) return;
    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(
      _isolateEntry,
      _IsolateParams(
        mainThreadSendPort: receivePort.sendPort,
        handler: handler,
      ),
    );

    _isolateSendPort = await receivePort.first;
    _initializedCompleter.complete();
  }

  static void _isolateEntry(_IsolateParams params) {
    ReceivePort port = ReceivePort();
    params.mainThreadSendPort.send(port.sendPort);

    final handler = params.handler;
    port.listen((receivedData) async {
      final params = receivedData['params'];
      final SendPort sendPort = receivedData['port'];
      final result = await handler(params);
      sendPort.send(result);
    });
  }
}

class _IsolateParams {
  final SendPort mainThreadSendPort;

  // Should be of type Handler, but doesn't work in dart 2.16 --> Change when upgraded to dart 2.17
  final dynamic handler;

  const _IsolateParams({
    required this.mainThreadSendPort,
    required this.handler,
  });
}
