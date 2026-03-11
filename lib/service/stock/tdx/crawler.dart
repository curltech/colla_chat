import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:colla_chat/plugin/talker_logger.dart';

/// 简易 Dart 版通达信行情客户端（免费 Level-1）
class TdxClient {
  final String host;
  final int port;
  Socket? _socket;

  TdxClient(this.host, this.port);

  Future<void> connect() async {
    _socket = await Socket.connect(host, port);
    logger.i('✅ 连接通达信行情服务器成功');
  }

  Future<void> close() async {
    await _socket?.close();
  }

  /// 获取股票实时行情
  /// market: 1=沪市, 0=深市
  Future<Uint8List> getQuotes(List<Map<String, dynamic>> stocks) async {
    if (_socket == null) {
      await connect();
    }
    final socket = _socket!;

    // 构造通达信查询行情包头（简化版，可正常解析）
    final header = [
      0x0C,
      0x0C,
      0x0D,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00
    ];

    final body = <int>[];
    for (final s in stocks) {
      final market = s['market'] as int;
      final code = s['code'] as String;
      body.add(market);
      body.addAll(utf8.encode(code.padRight(6, ' ')));
    }

    final packet = [...header, ...body];
    socket.add(packet);

    await socket.flush();
    final response = await socket.first;

    return response;
  }
}

final TdxClient tdxClient = TdxClient("119.147.212.81", 7709);

class CrawlerUtil {
  getDayLines() async {}
}
