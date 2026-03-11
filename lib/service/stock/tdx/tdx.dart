import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// 通达信 L1 行情客户端（纯裸协议，无登录，无UI，真实数据）
/// 支持：实时行情 + 分时图 + 日K / 1/5/15/30/60分钟K线
class TdxL1FullClient {
  static const _host = "123.125.106.28";
  static const _port = 7709;

  Socket? _socket;
  bool _connected = false;

  // 回调
  Function(StockRealData)? onRealStock;
  Function(TimeShareData)? onTimeShare;
  Function(List<KLineData>)? onKLine;

  Future<void> connect() async {
    try {
      _socket = await Socket.connect(_host, _port);
      _connected = true;
      _socket!.listen(_onReceive, onError: (e) {
        _connected = false;
      }, onDone: () {
        _connected = false;
      });
      print("✅ 已连接通达信 L1 服务器（无需登录）");
    } catch (e) {
      print("❌ 连接失败: $e");
    }
  }

  // ===================== 请求接口 =====================
  // 1. 实时行情（L1）
  void reqReal(String code) {
    _sendQuery(0x0C, code);
  }

  // 2. 分时图
  void reqTimeShare(String code) {
    _sendQuery(0x0D, code);
  }

  // 3. 日K
  void reqDailyK(String code, int count) {
    _sendKLine(code, 0x01, count);
  }

  // 4. 1分钟K
  void reqMin1K(String code, int count) {
    _sendKLine(code, 0x02, count);
  }

  // 5. 5分钟K
  void reqMin5K(String code, int count) {
    _sendKLine(code, 0x03, count);
  }

  // 6. 15分钟K
  void reqMin15K(String code, int count) {
    _sendKLine(code, 0x04, count);
  }

  // 7. 30分钟K
  void reqMin30K(String code, int count) {
    _sendKLine(code, 0x05, count);
  }

  // 8. 60分钟K
  void reqMin60K(String code, int count) {
    _sendKLine(code, 0x06, count);
  }

  // ===================== 发包 =====================
  void _sendQuery(int cmd, String code) {
    if (!_connected || _socket == null) return;
    final market = code.startsWith('6') ? 1 : 0;
    final bb = BytesBuilder();
    bb.add([cmd, 0x01]);
    bb.addByte(market);
    bb.add(_padCode(code));
    _socket!.add(bb.toBytes());
  }

  void _sendKLine(String code, int type, int count) {
    if (!_connected || _socket == null) return;
    final market = code.startsWith('6') ? 1 : 0;
    final bb = BytesBuilder();
    bb.add([0x0E, 0x01]);
    bb.addByte(market);
    bb.add(_padCode(code));
    bb.addByte(type);
    bb.add([count & 0xFF, (count >> 8) & 0xFF]);
    _socket!.add(bb.toBytes());
  }

  // ===================== 收包 & 解析 =====================
  void _onReceive(List<int> data) {
    final buf = Uint8List.fromList(data);
    if (buf.length < 2) return;

    final cmd = buf[0];
    try {
      switch (cmd) {
        case 0x0C:
          _parseReal(buf);
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

  // 解析实时行情
  void _parseReal(Uint8List buf) {
    final bd = ByteData.view(buf.buffer);
    final code = utf8.decode(buf.sublist(2, 8)).replaceAll('\x00', '');
    final name = utf8.decode(buf.sublist(29, 40)).replaceAll('\x00', '');

    final preClose = bd.getUint16(46, Endian.little) / 100;
    final now = bd.getUint16(42, Endian.little) / 100;
    final open = bd.getUint16(44, Endian.little) / 100;
    final high = bd.getUint16(48, Endian.little) / 100;
    final low = bd.getUint16(50, Endian.little) / 100;
    final vol = bd.getUint32(56, Endian.little);
    final amount = bd.getUint32(60, Endian.little) / 10000;

    // 五档盘口
    final bid1 = bd.getUint16(62, Endian.little) / 100;
    final ask1 = bd.getUint16(72, Endian.little) / 100;
    final bidVol1 = bd.getUint32(92, Endian.little);
    final askVol1 = bd.getUint32(112, Endian.little);

    onRealStock?.call(StockRealData(
      code: code,
      name: name,
      preClose: preClose,
      now: now,
      open: open,
      high: high,
      low: low,
      vol: vol,
      amount: amount,
      bid1: bid1,
      ask1: ask1,
      bidVol1: bidVol1,
      askVol1: askVol1,
    ));
  }

  // 解析分时
  void _parseTimeShare(Uint8List buf) {
    final bd = ByteData.view(buf.buffer);
    final count = bd.getUint16(2, Endian.little);
    final points = <TimeSharePoint>[];

    for (int i = 0; i < count; i++) {
      final offset = 8 + i * 4;
      if (offset + 4 > buf.length) break;
      final price = bd.getUint16(offset, Endian.little) / 100;
      final vol = bd.getUint16(offset + 2, Endian.little);
      points.add(TimeSharePoint(price: price, vol: vol));
    }

    onTimeShare?.call(TimeShareData(count: count, points: points));
  }

  // 解析K线
  void _parseKLine(Uint8List buf) {
    final bd = ByteData.view(buf.buffer);
    final count = bd.getUint16(2, Endian.little);
    final list = <KLineData>[];

    for (int i = 0; i < count; i++) {
      final offset = 8 + i * 32;
      if (offset + 32 > buf.length) break;

      final open = bd.getUint16(offset + 0, Endian.little) / 100;
      final high = bd.getUint16(offset + 2, Endian.little) / 100;
      final low = bd.getUint16(offset + 4, Endian.little) / 100;
      final close = bd.getUint16(offset + 6, Endian.little) / 100;
      final vol = bd.getUint32(offset + 8, Endian.little);
      final amount = bd.getUint32(offset + 12, Endian.little) / 10000;

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

  // ===================== 工具 =====================
  Uint8List _padCode(String code) {
    final c = Uint8List(6);
    final b = utf8.encode(code);
    for (int i = 0; i < b.length && i < 6; i++) {
      c[i] = b[i];
    }
    return c;
  }

  Future<void> close() async {
    _connected = false;
    await _socket?.close();
    _socket = null;
  }
}

// ===================== 数据结构 =====================
class StockRealData {
  final String code;
  final String name;
  final double preClose;
  final double now;
  final double open;
  final double high;
  final double low;
  final int vol;
  final double amount;
  final double bid1;
  final double ask1;
  final int bidVol1;
  final int askVol1;

  StockRealData({
    required this.code,
    required this.name,
    required this.preClose,
    required this.now,
    required this.open,
    required this.high,
    required this.low,
    required this.vol,
    required this.amount,
    required this.bid1,
    required this.ask1,
    required this.bidVol1,
    required this.askVol1,
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
  final double open;
  final double high;
  final double low;
  final double close;
  final int vol;
  final double amount;

  KLineData({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.vol,
    required this.amount,
  });
}

void main() async {
  final client = TdxL1FullClient();

  // 实时行情
  client.onRealStock = (data) {
    final pct = (data.now - data.preClose) / data.preClose * 100;
    print("【${data.code} ${data.name}】"
        " 现价: ${data.now} 涨幅: ${pct.toStringAsFixed(2)}%"
        " 买1: ${data.bid1}  卖1: ${data.ask1}");
  };

  // 分时
  client.onTimeShare = (data) {
    print("分时点数: ${data.count}");
    if (data.points.isNotEmpty) {
      final last = data.points.last;
      print("最新分时价: ${last.price} 量: ${last.vol}");
    }
  };

  // K线
  client.onKLine = (data) {
    print("K线数量: ${data.length}");
    if (data.isNotEmpty) {
      final last = data.last;
      print("最新K线: O:${last.open} H:${last.high} "
          "L:${last.low} C:${last.close} 量:${last.vol}");
    }
  };

  await client.connect();
  await Future.delayed(const Duration(seconds: 1));

  const code = "000001";

  // 一次性请求所有 L1 数据
  client.reqReal(code);
  client.reqTimeShare(code);
  client.reqDailyK(code, 100);
  client.reqMin5K(code, 80);

  await Future.delayed(const Duration(seconds: 10));
  await client.close();
}
