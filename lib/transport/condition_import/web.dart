import 'package:web_socket_channel/html.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

WebSocketChannel websocketConnect(
  String address, {
  Iterable? protocols,
  Map<String, dynamic>? headers,
  Duration? pingInterval,
}) {
  WebSocketChannel channel = HtmlWebSocketChannel.connect(Uri.parse(address));

  return channel;
}
