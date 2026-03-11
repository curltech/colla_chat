import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// 通达信 L1 极简客户端
/// 无登录 + 自动重连 + 批量订阅 + 行情/分时/K线
class TdxL1SimpleClient {
  static const String _host = '123.125.106.28';
  static const int _port = 7709;
  static const int _reconnectDelay = 5000;

  Socket? _socket;
  bool _connected = false;
  bool _isConnecting = false;
  Timer? _reconnectTimer;

  List<String> subscribeCodes = [];

  Function(StockRealData)? onStock;
  Function(TimeShareData)? onTimeShare;
  Function(List<KLineData>)? onKLine;

  // 启动（自动重连）
  void start() {
    _connect();
  }

  // 批量订阅
  void subscribe(List<String> codes) {
    subscribeCodes = codes;
    if (_connected) _refreshSubscribe();
  }

  // 单只订阅
  void reqStock(String code) => _send(0x0C, code);

  void reqTimeShare(String code) => _send(0x0D, code);

  void reqDailyK(String code, int count) => _sendK(code, 0x01, count);

  void reqMin5K(String code, int count) => _sendK(code, 0x03, count);

  // 连接 + 自动重连
  Future<void> _connect() async {
    if (_isConnecting) return;
    _isConnecting = true;

    try {
      _socket?.close();
      _socket = await Socket.connect(_host, _port)
          .timeout(const Duration(seconds: 3));
      _connected = true;
      print('✅ 已连接');

      _socket!.listen(_onData,
          onError: (e) => _disconnect(), onDone: () => _disconnect());
      _refreshSubscribe();
    } catch (e) {
      print('❌ 连接失败，$_reconnectDelay ms 后重试');
      _disconnect();
    } finally {
      _isConnecting = false;
    }
  }

  // 断开后自动重连
  void _disconnect() {
    _connected = false;
    _socket?.close();
    _socket = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: _reconnectDelay), _connect);
    print('🔌 已断开，等待重连');
  }

  // 重新订阅所有股票
  void _refreshSubscribe() {
    for (var code in subscribeCodes) {
      reqStock(code);
    }
  }

  // 发包
  void _send(int cmd, String code) {
    if (!_connected) return;
    final market = code.startsWith('6') ? 1 : 0;
    final b = BytesBuilder();
    b.add([cmd, 0x01]);
    b.addByte(market);
    b.add(_pad6(code));
    _socket?.add(b.toBytes());
  }

  void _sendK(String code, int type, int count) {
    if (!_connected) return;
    final market = code.startsWith('6') ? 1 : 0;
    final b = BytesBuilder();
    b.add([0x0E, 0x01]);
    b.addByte(market);
    b.add(_pad6(code));
    b.addByte(type);
    b.add([count & 0xFF, (count >> 8) & 0xFF]);
    _socket?.add(b.toBytes());
  }

  // 收数据
  void _onData(List<int> data) {
    final buf = Uint8List.fromList(data);
    if (buf.length < 2) return;
    try {
      switch (buf[0]) {
        case 0x0C:
          _parseStock(buf);
          break;
        case 0x0D:
          _parseTimeShare(buf);
          break;
        case 0x0E:
          _parseKLine(buf);
          break;
      }
    } catch (_) {}
  }

  // 行情解析
  void _parseStock(Uint8List buf) {
    final bd = ByteData.view(buf.buffer);
    final code = utf8.decode(buf.sublist(2, 8)).replaceAll('\x00', '');
    final name = utf8.decode(buf.sublist(29, 40)).replaceAll('\x00', '');
    final pre = bd.getUint16(46, Endian.little) / 100;
    final now = bd.getUint16(42, Endian.little) / 100;
    final open = bd.getUint16(44, Endian.little) / 100;
    final high = bd.getUint16(48, Endian.little) / 100;
    final low = bd.getUint16(50, Endian.little) / 100;
    final vol = bd.getUint32(56, Endian.little);

    onStock?.call(StockRealData(
      code: code,
      name: name,
      pre: pre,
      now: now,
      open: open,
      high: high,
      low: low,
      vol: vol,
    ));
  }

  // 分时解析
  void _parseTimeShare(Uint8List buf) {
    final bd = ByteData.view(buf.buffer);
    final count = bd.getUint16(2, Endian.little);
    final points = <TimeSharePoint>[];
    for (int i = 0; i < count; i++) {
      final o = 8 + i * 4;
      if (o + 4 > buf.length) break;
      final p = bd.getUint16(o, Endian.little) / 100;
      final v = bd.getUint16(o + 2, Endian.little);
      points.add(TimeSharePoint(p, v));
    }
    onTimeShare?.call(TimeShareData(count, points));
  }

  // K线解析
  void _parseKLine(Uint8List buf) {
    final bd = ByteData.view(buf.buffer);
    final count = bd.getUint16(2, Endian.little);
    final list = <KLineData>[];
    for (int i = 0; i < count; i++) {
      final o = 8 + i * 32;
      if (o + 32 > buf.length) break;
      final open = bd.getUint16(o + 0, Endian.little) / 100;
      final high = bd.getUint16(o + 2, Endian.little) / 100;
      final low = bd.getUint16(o + 4, Endian.little) / 100;
      final close = bd.getUint16(o + 6, Endian.little) / 100;
      final vol = bd.getUint32(o + 8, Endian.little);
      list.add(KLineData(open, high, low, close, vol));
    }
    onKLine?.call(list);
  }

  Uint8List _pad6(String code) {
    final c = Uint8List(6);
    final b = utf8.encode(code);
    for (int i = 0; i < b.length && i < 6; i++) c[i] = b[i];
    return c;
  }

  void stop() {
    _connected = false;
    _reconnectTimer?.cancel();
    _socket?.close();
  }
}

// 极简结构
class StockRealData {
  final String code, name;
  final double pre, now, open, high, low;
  final int vol;

  StockRealData(
      {required this.code,
      required this.name,
      required this.pre,
      required this.now,
      required this.open,
      required this.high,
      required this.low,
      required this.vol});
}

class TimeShareData {
  final int count;
  final List<TimeSharePoint> points;

  TimeShareData(this.count, this.points);
}

class TimeSharePoint {
  final double price;
  final int vol;

  TimeSharePoint(this.price, this.vol);
}

class KLineData {
  final double open, high, low, close;
  final int vol;

  KLineData(this.open, this.high, this.low, this.close, this.vol);
}

void main() async {
  final client = TdxL1SimpleClient();

  // 行情回调
  client.onStock = (data) {
    final pct = (data.now - data.pre) / data.pre * 100;
    print(
        '[${data.code}] ${data.name}  ${data.now}  ${pct.toStringAsFixed(2)}%');
  };

  // 启动 + 批量订阅
  client.start();
  await Future.delayed(Duration(seconds: 1));

  // 一次订阅多只股票
  client.subscribe(['000001', '600000', '600036', '601318', '300750']);

  // 额外查一只股票的日K + 分时
  client.reqDailyK('000001', 80);
  client.reqTimeShare('000001');
}
