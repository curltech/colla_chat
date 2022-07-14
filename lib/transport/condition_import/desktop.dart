import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

WebSocketChannel websocketConnect(
  String address, {
  Iterable? protocols,
  Map<String, dynamic>? headers,
  Duration? pingInterval,
}) {
  // HttpClient httpClient = HttpClient();
  // httpClient.badCertificateCallback =
  //     (X509Certificate cert, String host, int port) {
  //   return true;
  // };
  // WebSocket.connect(address, customClient: httpClient)
  //     .then((WebSocket webSocket) {
  //   WebSocketChannel channel = IOWebSocketChannel(webSocket);
  //   return channel;
  // });

  WebSocketChannel channel = IOWebSocketChannel.connect(Uri.parse(address),
      headers: headers, pingInterval: pingInterval);

  return channel;
}
