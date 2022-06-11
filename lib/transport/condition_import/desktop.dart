import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

WebSocketChannel websocketConnect(String address, {
  Iterable? protocols,
  Map<String, dynamic>? headers,
  Duration? pingInterval,
})  {
  WebSocketChannel channel = IOWebSocketChannel.connect(Uri.parse(address),
      headers: headers, pingInterval: pingInterval);

  return channel;
}
