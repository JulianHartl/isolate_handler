import 'package:isolate_handler/isolate_handler.dart';

void main() async {
  final squareIsolateHandler = IsolateHandler(handler: (int n) async => n * n);
  await squareIsolateHandler.spawn();
  final square = await squareIsolateHandler.send(params: 2);
  print(square);
}
