import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// 通达信 7709 完整行情客户端
/// 全协议解析：实时行情 + 分时 + K线 + 十档 + 逐笔
class TdxFullParserClient {
  final List<String> _hosts = [
    '123.125.106.28',
    '115.238.106.227',
    '218.75.72.81',
  ];

  final int _port = 7709;
  Socket? _socket;
  bool _connected = false;
  bool _logined = false;
  Timer? _heartbeatTimer;

  // 回调
  Function(StockRealData)? onRealStock;
  Function(TimeShareData)? onTimeShare;
  Function(List<KLineData>)? onKLine;
  Function(Order10Data)? onOrder10;
  Function(List<TransactionData>)? onTransaction;

  // 连接
  Future<void> connect() async {
    for (final h in _hosts) {
      try {
        _socket =
            await Socket.connect(h, _port).timeout(const Duration(seconds: 3));
        _connected = true;
        _socket!
            .listen(_onRecv, onError: (e) => disconnect(), onDone: disconnect);
        _sendLogin();
        _startHeartbeat();
        print('✅ 已连接 $h:7709');
        return;
      } catch (_) {}
    }
    print('❌ 全部服务器连接失败');
  }

  // 登录
  void _sendLogin() {
    if (_logined) return;
    _logined = true;
    _sendRaw([0x0C, 0x01, 0x01, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0, 0, 0]);
  }

  // 心跳
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _sendRaw([0x0C, 0x01, 0x00, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30]);
    });
  }

  // ———————————————— 请求接口 ————————————————
  void reqRealStock(String code) => _send(0x0C, code);

  void reqTimeShare(String code) => _send(0x0D, code);

  void reqDailyK(String code, int count) => _sendK(code, 0x01, count);

  void reqMin1K(String code, int count) => _sendK(code, 0x02, count);

  void reqMin5K(String code, int count) => _sendK(code, 0x03, count);

  void reqMin15K(String code, int count) => _sendK(code, 0x04, count);

  void reqMin30K(String code, int count) => _sendK(code, 0x05, count);

  void reqMin60K(String code, int count) => _sendK(code, 0x06, count);

  void reqOrder10(String code) => _send(0x0F, code);

  void reqTransaction(String code) => _send(0x10, code);

  void _send(int cmd, String code) {
    final m = code.startsWith('6') ? 1 : 0;
    final b = BytesBuilder();
    b.add([cmd, 0x01]);
    b.addByte(m);
    b.add(_padCode(code));
    _sendRaw(b.toBytes());
  }

  void _sendK(String code, int type, int count) {
    final m = code.startsWith('6') ? 1 : 0;
    final b = BytesBuilder();
    b.add([0x0E, 0x01]);
    b.addByte(m);
    b.add(_padCode(code));
    b.addByte(type);
    b.add([count & 0xFF, (count >> 8) & 0xFF]);
    _sendRaw(b.toBytes());
  }

  // ———————————————— 数据分发 ————————————————
  void _onRecv(List<int> bytes) {
    final buf = Uint8List.fromList(bytes);
    if (buf.length < 2) return;
    final cmd = buf[0];
    try {
      switch (cmd) {
        case 0x0C:
          _parseRealStock(buf);
          break;
        case 0x0D:
          _parseTimeShare(buf);
          break;
        case 0x0E:
          _parseKLine(buf);
          break;
        case 0x0F:
          _parseOrder10(buf);
          break;
        case 0x10:
          _parseTransaction(buf);
          break;
      }
    } catch (_) {}
  }

  // ———————————————— ① 实时行情 完整解析 ————————————————
  void _parseRealStock(Uint8List buf) {
    final bd = ByteData.view(buf.buffer);
    final code = utf8.decode(buf.sublist(2, 8)).replaceAll('\x00', '');
    final name = utf8.decode(buf.sublist(29, 40)).replaceAll('\x00', '');

    final preClose = bd.getUint16(46, Endian.little) / 100;
    final open = bd.getUint16(44, Endian.little) / 100;
    final high = bd.getUint16(48, Endian.little) / 100;
    final low = bd.getUint16(50, Endian.little) / 100;
    final price = bd.getUint16(42, Endian.little) / 100;

    final vol = bd.getUint32(56, Endian.little);
    final amount = bd.getUint32(60, Endian.little) / 10000;

    final bid1 = bd.getUint16(62, Endian.little) / 100;
    final bid2 = bd.getUint16(64, Endian.little) / 100;
    final bid3 = bd.getUint16(66, Endian.little) / 100;
    final bid4 = bd.getUint16(68, Endian.little) / 100;
    final bid5 = bd.getUint16(70, Endian.little) / 100;

    final ask1 = bd.getUint16(72, Endian.little) / 100;
    final ask2 = bd.getUint16(74, Endian.little) / 100;
    final ask3 = bd.getUint16(76, Endian.little) / 100;
    final ask4 = bd.getUint16(78, Endian.little) / 100;
    final ask5 = bd.getUint16(80, Endian.little) / 100;

    final bidVol1 = bd.getUint32(92, Endian.little);
    final bidVol2 = bd.getUint32(96, Endian.little);
    final bidVol3 = bd.getUint32(100, Endian.little);
    final bidVol4 = bd.getUint32(104, Endian.little);
    final bidVol5 = bd.getUint32(108, Endian.little);

    final askVol1 = bd.getUint32(112, Endian.little);
    final askVol2 = bd.getUint32(116, Endian.little);
    final askVol3 = bd.getUint32(120, Endian.little);
    final askVol4 = bd.getUint32(124, Endian.little);
    final askVol5 = bd.getUint32(128, Endian.little);

    final upLimit = bd.getUint16(40, Endian.little) / 100;
    final downLimit = bd.getUint16(41, Endian.little) / 100;

    onRealStock?.call(StockRealData(
      code: code,
      name: name,
      preClose: preClose,
      open: open,
      high: high,
      low: low,
      price: price,
      vol: vol,
      amount: amount,
      bid1: bid1,
      bid2: bid2,
      bid3: bid3,
      bid4: bid4,
      bid5: bid5,
      ask1: ask1,
      ask2: ask2,
      ask3: ask3,
      ask4: ask4,
      ask5: ask5,
      bidVol1: bidVol1,
      bidVol2: bidVol2,
      bidVol3: bidVol3,
      bidVol4: bidVol4,
      bidVol5: bidVol5,
      askVol1: askVol1,
      askVol2: askVol2,
      askVol3: askVol3,
      askVol4: askVol4,
      askVol5: askVol5,
      upLimit: upLimit,
      downLimit: downLimit,
    ));
  }

  // ———————————————— ② 分时图 完整解析 ————————————————
  void _parseTimeShare(Uint8List buf) {
    final bd = ByteData.view(buf.buffer);
    final count = bd.getUint16(2, Endian.little);
    final points = <TimeSharePoint>[];

    for (int i = 0; i < count; i++) {
      final off = 8 + i * 4;
      if (off + 4 > buf.length) break;
      final price = bd.getUint16(off, Endian.little) / 100;
      final vol = bd.getUint16(off + 2, Endian.little);
      points.add(TimeSharePoint(price: price, vol: vol));
    }

    onTimeShare?.call(TimeShareData(count: count, points: points));
  }

  // ———————————————— ③ K线 完整解析 ————————————————
  void _parseKLine(Uint8List buf) {
    final bd = ByteData.view(buf.buffer);
    final count = bd.getUint16(2, Endian.little);
    final list = <KLineData>[];

    for (int i = 0; i < count; i++) {
      final off = 8 + i * 32;
      if (off + 32 > buf.length) break;

      final open = bd.getUint16(off + 0, Endian.little) / 100;
      final high = bd.getUint16(off + 2, Endian.little) / 100;
      final low = bd.getUint16(off + 4, Endian.little) / 100;
      final close = bd.getUint16(off + 6, Endian.little) / 100;
      final vol = bd.getUint32(off + 8, Endian.little);
      final amount = bd.getUint32(off + 12, Endian.little) / 10000;

      list.add(KLineData(
        open: open,
        high: high,
        low: low,
        close: close,
        vol: vol,
        amount: amount,
      ));
    }
    onKLine?.call(list);
  }

  // ———————————————— ④ 十档买卖盘 完整解析 ————————————————
  void _parseOrder10(Uint8List buf) {
    final bd = ByteData.view(buf.buffer);
    final o = Order10Data(
      bid1: bd.getUint16(2, Endian.little) / 100,
      bidVol1: bd.getUint32(4, Endian.little),
      bid2: bd.getUint16(8, Endian.little) / 100,
      bidVol2: bd.getUint32(10, Endian.little),
      bid3: bd.getUint16(14, Endian.little) / 100,
      bidVol3: bd.getUint32(16, Endian.little),
      bid4: bd.getUint16(20, Endian.little) / 100,
      bidVol4: bd.getUint32(22, Endian.little),
      bid5: bd.getUint16(26, Endian.little) / 100,
      bidVol5: bd.getUint32(28, Endian.little),
      ask1: bd.getUint16(32, Endian.little) / 100,
      askVol1: bd.getUint32(34, Endian.little),
      ask2: bd.getUint16(38, Endian.little) / 100,
      askVol2: bd.getUint32(40, Endian.little),
      ask3: bd.getUint16(44, Endian.little) / 100,
      askVol3: bd.getUint32(46, Endian.little),
      ask4: bd.getUint16(50, Endian.little) / 100,
      askVol4: bd.getUint32(52, Endian.little),
      ask5: bd.getUint16(56, Endian.little) / 100,
      askVol5: bd.getUint32(58, Endian.little),
    );
    onOrder10?.call(o);
  }

  // ———————————————— ⑤ 逐笔成交 完整解析 ————————————————
  void _parseTransaction(Uint8List buf) {
    final list = <TransactionData>[];
    final bd = ByteData.view(buf.buffer);
    final count = buf.length ~/ 16;

    for (int i = 0; i < count; i++) {
      final off = i * 16;
      final price = bd.getUint16(off, Endian.little) / 100;
      final vol = bd.getUint32(off + 2, Endian.little);
      final buy = bd.getUint32(off + 6, Endian.little) >
          bd.getUint32(off + 10, Endian.little);
      list.add(TransactionData(price: price, vol: vol, isBuy: buy));
    }
    onTransaction?.call(list);
  }

  // 工具
  Uint8List _padCode(String code) {
    final c = Uint8List(6);
    final b = utf8.encode(code);
    for (int i = 0; i < b.length && i < 6; i++) c[i] = b[i];
    return c;
  }

  void _sendRaw(List<int> b) {
    if (_connected && _socket != null) _socket!.add(b);
  }

  void disconnect() {
    _connected = false;
    _logined = false;
    _heartbeatTimer?.cancel();
    _socket?.close();
    _socket = null;
  }
}

// ———————————————— 全数据结构体 ————————————————
class StockRealData {
  final String code, name;
  final double preClose, open, high, low, price;
  final int vol;
  final double amount;
  final double bid1, bid2, bid3, bid4, bid5, ask1, ask2, ask3, ask4, ask5;
  final int bidVol1,
      bidVol2,
      bidVol3,
      bidVol4,
      bidVol5,
      askVol1,
      askVol2,
      askVol3,
      askVol4,
      askVol5;
  final double upLimit, downLimit;

  StockRealData({
    required this.code,
    required this.name,
    required this.preClose,
    required this.open,
    required this.high,
    required this.low,
    required this.price,
    required this.vol,
    required this.amount,
    required this.bid1,
    required this.bid2,
    required this.bid3,
    required this.bid4,
    required this.bid5,
    required this.ask1,
    required this.ask2,
    required this.ask3,
    required this.ask4,
    required this.ask5,
    required this.bidVol1,
    required this.bidVol2,
    required this.bidVol3,
    required this.bidVol4,
    required this.bidVol5,
    required this.askVol1,
    required this.askVol2,
    required this.askVol3,
    required this.askVol4,
    required this.askVol5,
    required this.upLimit,
    required this.downLimit,
  });
}

class TimeShareData {
  final int count;
  final List<TimeSharePoint> points;

  TimeShareData({required this.count, required this.points});
}

class TimeSharePoint {
  final double price;
  final int vol;

  TimeSharePoint({required this.price, required this.vol});
}

class KLineData {
  final double open, high, low, close;
  final int vol;
  final double amount;

  KLineData(
      {required this.open,
      required this.high,
      required this.low,
      required this.close,
      required this.vol,
      required this.amount});
}

class Order10Data {
  final double bid1, bid2, bid3, bid4, bid5, ask1, ask2, ask3, ask4, ask5;
  final int bidVol1,
      bidVol2,
      bidVol3,
      bidVol4,
      bidVol5,
      askVol1,
      askVol2,
      askVol3,
      askVol4,
      askVol5;

  Order10Data({
    required this.bid1,
    required this.bid2,
    required this.bid3,
    required this.bid4,
    required this.bid5,
    required this.ask1,
    required this.ask2,
    required this.ask3,
    required this.ask4,
    required this.ask5,
    required this.bidVol1,
    required this.bidVol2,
    required this.bidVol3,
    required this.bidVol4,
    required this.bidVol5,
    required this.askVol1,
    required this.askVol2,
    required this.askVol3,
    required this.askVol4,
    required this.askVol5,
  });
}

class TransactionData {
  final double price;
  final int vol;
  final bool isBuy;

  TransactionData(
      {required this.price, required this.vol, required this.isBuy});
}

void main() async {
  final tdx = TdxFullParserClient();

  // 实时行情
  tdx.onRealStock = (data) {
    print(
        '【${data.code} ${data.name}】 现价: ${data.price} 涨幅: ${((data.price - data.preClose) / data.preClose * 100).toStringAsFixed(2)}%');
  };

  // 分时
  tdx.onTimeShare = (data) {
    print('分时点数: ${data.count}');
  };

  // K线
  tdx.onKLine = (data) {
    print('K线数量: ${data.length}');
  };

  // 十档
  tdx.onOrder10 = (d) {
    print('买1: ${d.bid1} 量: ${d.bidVol1} | 卖1: ${d.ask1} 量: ${d.askVol1}');
  };

  // 逐笔
  tdx.onTransaction = (data) {
    if (data.isNotEmpty) {
      final t = data.last;
      print('逐笔 ${t.price}  ${t.vol}手 ${t.isBuy ? "主买" : "主卖"}');
    }
  };

  await tdx.connect();
  await Future.delayed(const Duration(seconds: 1));

  // 一次性拉全量数据
  final code = "000001";
  tdx.reqRealStock(code);
  tdx.reqTimeShare(code);
  tdx.reqDailyK(code, 100);
  tdx.reqMin5K(code, 80);
  tdx.reqOrder10(code);
  tdx.reqTransaction(code);

  await Future.delayed(const Duration(minutes: 5));
  tdx.disconnect();
}
