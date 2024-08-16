import 'package:candlesticks/candlesticks.dart';
import 'package:colla_chat/entity/stock/share.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/stock/day_line.dart';
import 'package:colla_chat/service/stock/eastmoney/crawler.dart';
import 'package:colla_chat/service/stock/min_line.dart';
import 'package:colla_chat/service/stock/share.dart';
import 'package:colla_chat/service/stock/wmqy_line.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/loading_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:get/state_manager.dart';

class StockLineController extends DataListController<dynamic> {
  String tsCode;
  String name;
  int lineType;

  int? count;

  StockLineController(this.tsCode, this.name, {this.lineType = 100});
}

class MultiStockLineController extends DataListController<String> {
  final RxInt _lineType = 100.obs;

  /// 增加自选股的查询结果控制器
  final Map<String, Map<int, StockLineController>> stockLineControllers = {};

  /// 当前数据类型
  int get lineType {
    return _lineType.value;
  }

  set lineType(int lineType) {
    _lineType(lineType);
  }

  /// 当前股票控制器
  StockLineController? get stockLineController {
    if (current != null) {
      return stockLineControllers[current]?[_lineType.value];
    }
    return null;
  }

  /// 加入股票代码和控制器，并设置为当前
  put(String tsCode, String name) {
    if (!data.contains(tsCode)) {
      data.add(tsCode);
    }
    if (current != tsCode || !stockLineControllers.containsKey(tsCode)) {
      if (!stockLineControllers.containsKey(tsCode)) {
        stockLineControllers[tsCode] = {};

        /// 100代表分时数据
        stockLineControllers[tsCode]?[100] =
            StockLineController(tsCode, name, lineType: 100);
        stockLineControllers[tsCode]?[101] =
            StockLineController(tsCode, name, lineType: 101);
        stockLineControllers[tsCode]?[102] =
            StockLineController(tsCode, name, lineType: 102);
        stockLineControllers[tsCode]?[103] =
            StockLineController(tsCode, name, lineType: 103);
        stockLineControllers[tsCode]?[104] =
            StockLineController(tsCode, name, lineType: 104);
        stockLineControllers[tsCode]?[105] =
            StockLineController(tsCode, name, lineType: 105);
        stockLineControllers[tsCode]?[106] =
            StockLineController(tsCode, name, lineType: 106);
      }
      _lineType(100);
      current = tsCode;
    }
  }

  remove(String tsCode) {
    if (stockLineControllers.containsKey(tsCode)) {
      stockLineControllers.remove(tsCode);
    }
  }

  previous() async {
    int currentIndex = this.currentIndex - 1;
    if (currentIndex >= 0 && currentIndex < data.length) {
      String tsCode = data[currentIndex];
      if (!stockLineControllers.containsKey(tsCode)) {
        Share? share = await shareService.findShare(tsCode);
        if (share != null) {
          String? name = share.name;
          name ??= '';
          put(tsCode, name);
        }
      }
      this.currentIndex = currentIndex;
    }
  }

  next() async {
    int currentIndex = this.currentIndex + 1;
    if (currentIndex >= 0 && currentIndex < data.length) {
      String tsCode = data[currentIndex];
      if (!stockLineControllers.containsKey(tsCode)) {
        Share? share = await shareService.findShare(tsCode);
        if (share != null) {
          String? name = share.name;
          name ??= '';
          put(tsCode, name);
        }
      }
      this.currentIndex = currentIndex;
    }
  }
}

final MultiStockLineController multiStockLineController =
    MultiStockLineController();

class StockLineChartWidget extends StatelessWidget with TileDataMixin {
  StockLineChartWidget({super.key}) {
    online.addListener(reload);
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'stockline_chart';

  @override
  IconData get iconData => Icons.insert_chart_outlined;

  @override
  String get title => 'StockLineChart';

  List<Indicator> indicators = [
    MovingAverageIndicator(
      length: 5,
      color: Colors.blue,
    ),
    MovingAverageIndicator(
      length: 10,
      color: Colors.yellowAccent,
    ),
    MovingAverageIndicator(
      length: 20,
      color: Colors.purpleAccent,
    ),
    MovingAverageIndicator(
      length: 30,
      color: Colors.cyanAccent,
    ),
  ];
  Rx<List<Candle>?> candles = Rx<List<Candle>?>(null);
  RxBool online = true.obs;

  /// 在tsCode和lineType改变，也就是当前数据控制器改变的情况下，加载数据，
  Future<void> reload() async {
    candles.value = null;
    StockLineController? stockLineController =
        multiStockLineController.stockLineController;
    if (stockLineController == null) {
      return;
    }
    stockLineController.clear(notify: false);
    stockLineController.count = null;
    // 判断是否有更多的数据可以加载
    List<dynamic>? data = await _findMoreData();
    if (data != null && data.isNotEmpty) {
      List<Candle> candles = _buildCandles(data);
      if (candles.isNotEmpty) {
        this.candles.value = candles;
      }
    }
  }

  /// 当前数据控制器加载更多的数据
  Future<List<dynamic>?> _findMoreData() async {
    StockLineController? stockLineController =
        multiStockLineController.stockLineController;
    if (stockLineController == null) {
      return null;
    }

    int lineType = stockLineController.lineType;
    String tsCode = stockLineController.tsCode;
    int length = stockLineController.length;
    Map<String, dynamic>? response;
    DateTime start = DateTime.now();
    if (lineType == 100) {
      if (online.value) {
        int? tradeDate;
        if (stockLineController.data.isNotEmpty) {
          Map map = JsonUtil.toJson(stockLineController.data[0]);
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
      if (online.value) {
        int? tradeDate;
        if (stockLineController.data.isNotEmpty) {
          Map map = JsonUtil.toJson(stockLineController.data[0]);
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
      if (online.value) {
        int? tradeDate;
        if (stockLineController.data.isNotEmpty) {
          Map map = JsonUtil.toJson(stockLineController.data[0]);
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
      return null;
    }
    List<dynamic>? data = response['data'];
    int? count = response['count'];
    stockLineController.count = count;
    if (data != null && data.isNotEmpty) {
      if (online.value) {
        stockLineController.replaceAll(data);
      } else {
        stockLineController.insertAll(0, data);
      }
      return data;
    }

    return null;
  }

  /// 在tsCode和lineType没有改变，也就是当前数据控制器不变的情况下，加载更多的数据，
  Future<void> loadMoreCandles() async {
    StockLineController? stockLineController =
        multiStockLineController.stockLineController;
    if (stockLineController == null) {
      return;
    }
    int length = stockLineController.data.length;
    int? count = stockLineController.count;
    // 判断是否有更多的数据可以加载
    if (count == null || length == 0 || length < count) {
      List<dynamic>? data = await _findMoreData();
      if (data != null && data.isNotEmpty) {
        List<Candle> candles = _buildCandles(data);
        if (candles.isNotEmpty && this.candles.value != null) {
          if (!online.value) {
            candles.addAll(this.candles.value!);
          }
          this.candles.value = candles;
        }
      }
    }
  }

  /// 创建图形的数据
  List<Candle> _buildCandles(List<dynamic> data) {
    List<Candle> candles = [];
    for (int i = data.length - 1; i >= 0; i--) {
      Map<String, dynamic> map = JsonUtil.toJson(data[i]);
      int tradeDate = map['trade_date'];
      int hour = 0;
      int minute = 0;
      int? tradeMinute = map['trade_minute'];
      if (tradeMinute != null) {
        hour = tradeMinute ~/ 60;
        minute = tradeMinute % 60;
      }
      DateTime date = DateUtil.toDateTime(tradeDate.toString());
      DateTime time = date.copyWith(
          year: date.year,
          month: date.month,
          day: date.day,
          hour: hour,
          minute: minute);
      num high = map['high'];
      num low = map['low'];
      num open = map['open'];
      num close = map['close'];
      num volume = map['vol'];
      Candle candle = Candle(
          date: time,
          high: high.toDouble(),
          low: low.toDouble(),
          open: open.toDouble(),
          close: close.toDouble(),
          volume: volume.toDouble());
      candles.add(candle);
    }

    return candles;
  }

  CandleSticksStyle dark() {
    return CandleSticksStyle.dark(
      primaryBull: Colors.red,
      secondaryBull: Colors.redAccent,
      primaryBear: Colors.green,
      secondaryBear: Colors.greenAccent,
    );
  }

  CandleSticksStyle light() {
    return CandleSticksStyle.light(
      primaryBull: Colors.red,
      secondaryBull: Colors.redAccent,
      primaryBear: Colors.green,
      secondaryBear: Colors.greenAccent,
    );
  }

  Widget _buildCandlesticks(BuildContext context) {
    final bool isDark = myself.getBrightness(context) == Brightness.dark;
    final style = isDark ? dark() : light();
    return Obx(
      () {
        if (candles.value == null) {
          return nil;
        }
        return Candlesticks(
          key: UniqueKey(),
          indicators:
              multiStockLineController.lineType == 100 ? null : indicators,
          loadingWidget: LoadingUtil.buildLoadingIndicator(),
          actions: <ToolBarAction>[
            ToolBarAction(
              onPressed: () {
                multiStockLineController.lineType = 100;
                reload();
              },
              child: Icon(
                Icons.lock_clock,
                color: multiStockLineController.lineType == 100
                    ? myself.primary
                    : isDark
                        ? Colors.white
                        : Colors.grey,
              ),
            ),
            ToolBarAction(
              onPressed: () {
                multiStockLineController.lineType = 101;
                reload();
              },
              child: Icon(
                Icons.calendar_view_day_outlined,
                color: multiStockLineController.lineType == 101
                    ? myself.primary
                    : isDark
                        ? Colors.white
                        : Colors.grey,
              ),
            ),
            ToolBarAction(
              onPressed: () {
                multiStockLineController.lineType = 102;
                reload();
              },
              child: Icon(
                Icons.calendar_view_week_outlined,
                color: multiStockLineController.lineType == 102
                    ? myself.primary
                    : isDark
                        ? Colors.white
                        : Colors.grey,
              ),
            ),
            ToolBarAction(
              onPressed: () {
                multiStockLineController.lineType = 103;
                reload();
              },
              child: Icon(
                Icons.calendar_view_month_outlined,
                color: multiStockLineController.lineType == 103
                    ? myself.primary
                    : isDark
                        ? Colors.white
                        : Colors.grey,
              ),
            ),
            ToolBarAction(
              onPressed: () {
                multiStockLineController.lineType = 104;
                reload();
              },
              child: Icon(
                size: 22,
                Icons.perm_contact_calendar,
                color: multiStockLineController.lineType == 104
                    ? myself.primary
                    : isDark
                        ? Colors.white
                        : Colors.grey,
              ),
            ),
            ToolBarAction(
              onPressed: () {
                multiStockLineController.lineType = 105;
                reload();
              },
              child: Icon(
                size: 22,
                Icons.calendar_month_outlined,
                color: multiStockLineController.lineType == 105
                    ? myself.primary
                    : isDark
                        ? Colors.white
                        : Colors.grey,
              ),
            ),
            ToolBarAction(
              onPressed: () {
                multiStockLineController.lineType = 106;
                reload();
              },
              child: Icon(
                size: 20,
                Icons.calendar_today_outlined,
                color: multiStockLineController.lineType == 106
                    ? myself.primary
                    : isDark
                        ? Colors.white
                        : Colors.grey,
              ),
            ),
          ],
          candles: candles.value!,
          style: style,
          chartAdjust: ChartAdjust.visibleRange,
          onLoadMoreCandles: loadMoreCandles,
          onRemoveIndicator: (String indicator) {
            indicators = [...indicators];
            indicators.removeWhere((element) => element.name == indicator);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    reload();
    Widget titleWidget = Obx(
      () {
        StockLineController? stockLineController =
            multiStockLineController.stockLineController;
        if (stockLineController == null) {
          return CommonAutoSizeText(title);
        }
        return CommonAutoSizeText(
            '${stockLineController.tsCode}-${stockLineController.name}');
      },
    );
    List<Widget> rightWidgets = [];
    Widget onlineWidget = Obx(() {
      return ToggleButtons(
        color: Colors.grey,
        selectedColor: Colors.white,
        fillColor: myself.primary,
        borderRadius: BorderRadius.circular(16.0),
        onPressed: (int value) {
          online.value = value == 0 ? true : false;
        },
        isSelected: [online.value, !online.value],
        children: const [
          Icon(Icons.book_online_outlined),
          Icon(Icons.offline_bolt_outlined)
        ],
      );
    });
    rightWidgets.add(onlineWidget);

    rightWidgets.addAll([
      IconButton(
          tooltip: AppLocalizations.t('Previous'),
          onPressed: () async {
            await multiStockLineController.previous();
            StockLineController? stockLineController =
                multiStockLineController.stockLineController;
            reload();
          },
          icon: const Icon(Icons.skip_previous_outlined)),
      IconButton(
          tooltip: AppLocalizations.t('Next'),
          onPressed: () async {
            await multiStockLineController.next();
            StockLineController? stockLineController =
                multiStockLineController.stockLineController;
            reload();
          },
          icon: const Icon(Icons.skip_next_outlined)),
    ]);
    return AppBarView(
      titleWidget: titleWidget,
      withLeading: true,
      rightWidgets: rightWidgets,
      child: Center(
        child: _buildCandlesticks(context),
      ),
    );
  }
}
