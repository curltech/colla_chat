import 'package:colla_chat/entity/stock/day_line.dart';
import 'package:colla_chat/entity/stock/share.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/service/stock/day_line.dart';
import 'package:colla_chat/service/stock/eastmoney/crawler.dart';
import 'package:colla_chat/service/stock/min_line.dart';
import 'package:colla_chat/service/stock/share.dart';
import 'package:colla_chat/service/stock/wmqy_line.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:get/get.dart';

/// 某只股票的某种线型的数据控制器
class KlineController extends DataListController<dynamic> {
  /// 股票代码
  String tsCode;
  String name;

  /// 线型，有分钟线，日线，周线等，缺省100代表日线
  int lineType;

  int? count;

  KlineController(this.tsCode, this.name, {this.lineType = 101});
}

class MultiKlineController extends DataListController<String> {
  /// 加载数据的方式，true表示直接从网站加载，false表示从服务器加载，支持分批获取
  final RxBool online = true.obs;

  /// 当前线型
  final RxInt lineType = 101.obs;

  /// 所有股票的所有线型的数据控制器集合，键值为股票代码和线型
  final Map<String, Map<int, KlineController>> klineControllers = {};

  /// 当前股票控制器
  KlineController? get klineController {
    if (current != null) {
      return klineControllers[current]?[lineType.value];
    }
    return null;
  }

  /// 加入新的股票代码和控制器，包含所有的线型，并设置为当前
  put(String tsCode) async {
    if (tsCode.isEmpty) {
      return;
    }
    String name;
    Share? share = await shareService.findShare(tsCode);
    if (share != null && share.name != null) {
      name = share.name!;
    } else {
      return;
    }
    if (!data.contains(tsCode)) {
      data.add(tsCode);
    }
    if (current != tsCode || !klineControllers.containsKey(tsCode)) {
      if (!klineControllers.containsKey(tsCode)) {
        klineControllers[tsCode] = {};

        /// 100代表分时数据
        klineControllers[tsCode]?[100] =
            KlineController(tsCode, name, lineType: 100);
        klineControllers[tsCode]?[101] =
            KlineController(tsCode, name, lineType: 101);
        klineControllers[tsCode]?[102] =
            KlineController(tsCode, name, lineType: 102);
        klineControllers[tsCode]?[103] =
            KlineController(tsCode, name, lineType: 103);
        klineControllers[tsCode]?[104] =
            KlineController(tsCode, name, lineType: 104);
        klineControllers[tsCode]?[105] =
            KlineController(tsCode, name, lineType: 105);
        klineControllers[tsCode]?[106] =
            KlineController(tsCode, name, lineType: 106);
      }
      lineType(101);
      current = tsCode;
    }
  }

  remove(String tsCode) {
    if (klineControllers.containsKey(tsCode)) {
      klineControllers.remove(tsCode);
      data.remove(tsCode);
    }
  }

  /// 当前股票转为上一只股票
  previous() async {
    if (data.isEmpty) {
      setCurrentIndex = null;
    }
    if (this.currentIndex.value == null ||
        this.currentIndex.value == 0 ||
        this.currentIndex.value == 1) {
      setCurrentIndex = 0;
    }
    int currentIndex = this.currentIndex.value! - 1;
    if (currentIndex >= 0 && currentIndex < data.length) {
      String tsCode = data[currentIndex];
      if (!klineControllers.containsKey(tsCode)) {
        await put(tsCode);
      }
      setCurrentIndex = currentIndex;
    }
  }

  /// 当前股票转为下一只股票
  next() async {
    if (data.isEmpty) {
      setCurrentIndex = null;
    }
    if (this.currentIndex.value == null ||
        this.currentIndex.value == data.length - 1 ||
        this.currentIndex.value == data.length - 2) {
      setCurrentIndex = data.length - 1;
    }
    int currentIndex = this.currentIndex.value! + 1;
    if (currentIndex >= 0 && currentIndex < data.length) {
      String tsCode = data[currentIndex];
      if (!klineControllers.containsKey(tsCode)) {
        await put(tsCode);
      }
      setCurrentIndex = currentIndex;
    }
  }

  /// 装载日线
  loadDayLines({List<String>? tsCodes}) async {
    tsCodes ??= data;
    List<Future<Map<String, dynamic>?>> futures = [];
    for (String tsCode in tsCodes) {
      if (tsCode.isEmpty) {
        continue;
      }
      await put(tsCode);
      if (online.value) {
        futures.add(CrawlerUtil.getDayLine(tsCode));
      } else {
        futures.add(remoteDayLineService.sendFindPreceding(tsCode));
      }
    }
    List<Map<String, dynamic>?> responses = await Future.wait(futures);
    for (Map<String, dynamic>? response in responses) {
      if (response != null) {
        List<DayLine> dayLines = response['data'];
        if (dayLines.isNotEmpty) {
          String tsCode = dayLines.first.tsCode;

          KlineController? klineController = klineControllers[tsCode]?[101];
          if (klineController != null) {
            klineController.replaceAll(dayLines);
          }
        }
      }
    }
  }

  Future<List<DayLine>> findLatestDayLines({List<String>? tsCodes}) async {
    tsCodes ??= data;
    List<DayLine> dayLines = [];
    for (String tsCode in tsCodes) {
      if (tsCode.isEmpty) {
        continue;
      }
      KlineController? klineController = klineControllers[tsCode]?[101];
      if (klineController == null) {
        await put(tsCode);
        klineController = klineControllers[tsCode]?[101];
      }
      if (klineController != null) {
        DayLine? dayLine = klineController.data.lastOrNull;
        if (dayLine == null) {
          await loadDayLines(tsCodes: [tsCode]);
          dayLine = klineController.data.lastOrNull;
        }
        if (dayLine != null) {
          if (dayLine.tsCode != tsCode) {
            continue;
          }
          dayLines.add(dayLine);
          Share? share = await shareService.findShare(tsCode);
          if (share != null) {
            dayLine.name = share.name;
          }
        }
      }
    }

    return dayLines;
  }

  /// 加载当前的tsCode和lineType全部（在线模式）或者更多的数据（服务器模式）
  Future<void> _loadMore() async {
    if (klineController == null) {
      return;
    }

    int lineType = klineController!.lineType;
    String tsCode = klineController!.tsCode;
    int length = klineController!.length;
    Map<String, dynamic>? response;
    DateTime start = DateTime.now();

    /// 分钟线
    if (lineType == 100) {
      ///在线获取
      if (online.value) {
        int? tradeDate;
        if (klineController!.data.isNotEmpty) {
          Map map = JsonUtil.toJson(klineController!.data[0]);
          tradeDate = map['tradeDate'];
        }
        if (tradeDate != null) {
          response = await CrawlerUtil.getMinLine(tsCode, beg: tradeDate);
        } else {
          response = await CrawlerUtil.getMinLine(tsCode);
        }
      } else {
        response = {};
        response['data'] = await remoteMinLineService.sendFindMinLines(tsCode);
        response['count'] = 240;
      }
    } else if (lineType == 101) {
      /// 日线
      if (online.value) {
        int? tradeDate;
        if (klineController!.data.isNotEmpty) {
          Map map = JsonUtil.toJson(klineController!.data[0]);
          tradeDate = map['tradeDate'];
        }
        if (tradeDate != null) {
          response = await CrawlerUtil.getDayLine(tsCode, end: tradeDate);
        } else {
          response = await CrawlerUtil.getDayLine(tsCode);
        }
      } else {
        response = await remoteDayLineService.sendFindPreceding(tsCode,
            from: length, limit: 100);
      }
    } else {
      /// 其他的线，包括周线，月线等
      if (online.value) {
        int? tradeDate;
        if (klineController!.data.isNotEmpty) {
          Map map = JsonUtil.toJson(klineController!.data[0]);
          tradeDate = map['tradeDate'];
        }
        if (tradeDate != null) {
          response = await CrawlerUtil.getWmqyLine(tsCode,
              end: tradeDate, klt: lineType);
        } else {
          response = await CrawlerUtil.getWmqyLine(tsCode, klt: lineType);
        }
      } else {
        response = await remoteWmqyLineService.sendFindLinePreceding(tsCode,
            lineType: lineType, from: length, limit: 100);
      }
    }
    DateTime end = DateTime.now();
    logger.i('find more data duration:${end.difference(start).inMilliseconds}');
    if (response == null) {
      return;
    }
    List<dynamic>? data = response['data'];
    int? count = response['count'];
    klineController!.count = count;

    /// 获取的数据如果是在线的，则是所有的数据取代原有的数据
    /// 如果是服务器的，则添加，服务器支持分批获取
    if (data != null && data.isNotEmpty) {
      if (online.value) {
        klineController!.replaceAll(data);
      } else {
        klineController!.insertAll(0, data);
      }
    }
  }

  /// 检查当前的数据是否存在，是否加载完毕决定加载数据
  Future<void> load() async {
    if (klineController == null) {
      return;
    }
    int length = klineController!.data.length;
    int? count = klineController!.count;
    // 判断是否有更多的数据可以加载
    if (count == null || length == 0 || length < count) {
      await _loadMore();
    }
  }
}

final MultiKlineController multiKlineController = MultiKlineController();
