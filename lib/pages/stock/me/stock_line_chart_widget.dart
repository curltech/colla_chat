import 'package:colla_chat/entity/stock/share.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/stock/day_line.dart';
import 'package:colla_chat/service/stock/share.dart';
import 'package:colla_chat/service/stock/wmqy_line.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/loading_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:candlesticks/candlesticks.dart';

class StockLineController extends DataListController<dynamic> {
  String tsCode;
  String name;
  int lineType;

  int? count;

  StockLineController(this.tsCode, this.name, {this.lineType = 101});
}

class MultiStockLineController extends DataListController<String> {
  int _lineType = 101;

  /// 增加自选股的查询结果控制器
  final Map<String, Map<int, StockLineController>> stockLineControllers = {};

  /// 当前数据类型
  int get lineType {
    return _lineType;
  }

  set lineType(int lineType) {
    if (_lineType != lineType) {
      _lineType = lineType;
      notifyListeners();
    }
  }

  /// 当前股票控制器
  StockLineController? get stockLineController {
    if (current != null) {
      return stockLineControllers[current]?[_lineType];
    }
    return null;
  }

  /// 加入股票代码和控制器，并设置为当前
  put(String tsCode, String name) {
    if (current != tsCode || !stockLineControllers.containsKey(tsCode)) {
      if (!stockLineControllers.containsKey(tsCode)) {
        stockLineControllers[tsCode] = {};
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

class StockLineChartWidget extends StatefulWidget with TileDataMixin {
  const StockLineChartWidget({Key? key}) : super(key: key);

  @override
  State createState() => _StockLineChartWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'stockline_chart';

  @override
  IconData get iconData => Icons.insert_chart_outlined;

  @override
  String get title => 'StockLineChart';
}

class _StockLineChartWidgetState extends State<StockLineChartWidget> {
  List<Indicator> indicators = [
    MovingAverageIndicator(
      length: 5,
      color: Colors.blue.shade600,
    ),
    MovingAverageIndicator(
      length: 10,
      color: Colors.yellow.shade600,
    ),
    MovingAverageIndicator(
      length: 20,
      color: Colors.purple.shade600,
    ),
    MovingAverageIndicator(
      length: 30,
      color: Colors.green.shade600,
    ),
  ];
  List<Candle> candles = [];

  @override
  void initState() {
    multiStockLineController.addListener(_update);
    reloadCandles();
    super.initState();
  }

  _update() {
    reloadCandles();
  }

  /// 重新加载数据，tsCode和lineType发生改变
  Future<void> reloadCandles() async {
    StockLineController? dayLineController =
        multiStockLineController.stockLineController;
    if (dayLineController == null) {
      return;
    }
    int length = dayLineController.data.length;
    int? count = dayLineController.count;
    // 判断是否有更多的数据可以加载
    if (count == null || length == 0) {
      await _findMoreData(dayLineController);
    }
    _buildCandles(dayLineController);
  }

  /// 加载更多的数据，tsCode和lineType没有改变
  Future<void> loadMoreCandles() async {
    StockLineController? dayLineController =
        multiStockLineController.stockLineController;
    if (dayLineController == null) {
      return;
    }
    int length = dayLineController.data.length;
    int? count = dayLineController.count;
    // 判断是否有更多的数据可以加载
    if (count == null || length < count) {
      bool hasMore = await _findMoreData(dayLineController);
      if (hasMore) {
        _buildCandles(dayLineController);
      }
    }
  }

  Future<bool> _findMoreData(StockLineController dayLineController) async {
    String tsCode = dayLineController.tsCode;
    int length = dayLineController.data.length;
    Map<String, dynamic> response;
    int lineType = dayLineController.lineType;
    if (lineType == 101) {
      response = await remoteDayLineService.sendFindPreceding(tsCode,
          from: length, limit: 100);
    } else {
      response = await remoteWmqyLineService.sendFindLinePreceding(tsCode,
          lineType: lineType, from: length, limit: 100);
    }
    List<dynamic> data = response['data'];
    int count = response['count'];
    dayLineController.count = count;
    if (data.isNotEmpty) {
      dayLineController.insertAll(0, data);
      return true;
    }

    return false;
  }

  /// 创建图形的数据
  _buildCandles(StockLineController dayLineController) {
    candles.clear();
    List<dynamic> data = dayLineController.data;
    for (int i = data.length - 1; i >= 0; i--) {
      Map<String, dynamic> map = JsonUtil.toJson(data[i]);
      int trade_date = map['trade_date'];
      DateTime tradeDate = DateUtil.toDateTime(trade_date.toString());
      num high = map['high'];
      num low = map['low'];
      num open = map['open'];
      num close = map['close'];
      num volume = map['vol'];
      Candle candle = Candle(
          date: tradeDate,
          high: high.toDouble(),
          low: low.toDouble(),
          open: open.toDouble(),
          close: close.toDouble(),
          volume: volume.toDouble());
      candles.add(candle);
    }
    setState(() {});
  }

  CandleSticksStyle dark() {
    return CandleSticksStyle.dark(
      primaryBull: const Color(0xFFEF5350),
      secondaryBull: const Color(0xFF82122B),
      primaryBear: const Color(0xFF26A69A),
      secondaryBear: const Color(0xFF005940),
    );
  }

  CandleSticksStyle light() {
    return CandleSticksStyle.light(
      primaryBull: const Color(0xFFEF5350),
      secondaryBull: const Color(0xFFF1A3A1),
      primaryBear: const Color(0xff026a69a),
      secondaryBear: const Color(0xFF8CCCC6),
    );
  }

  _buildCandlesticks(List<Candle> candles) {
    final bool isDark = myself.getBrightness(context) == Brightness.dark;
    final style = isDark ? dark() : light();
    return Candlesticks(
      key: UniqueKey(),
      indicators: indicators,
      loadingWidget: LoadingUtil.buildLoadingIndicator(),
      actions: <ToolBarAction>[
        ToolBarAction(
          onPressed: () {
            multiStockLineController.lineType = 101;
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
          },
          child: Icon(
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
          },
          child: Icon(
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
          },
          child: Icon(
            Icons.calendar_today_outlined,
            color: multiStockLineController.lineType == 106
                ? myself.primary
                : isDark
                    ? Colors.white
                    : Colors.grey,
          ),
        ),
      ],
      candles: candles,
      style: style,
      chartAdjust: ChartAdjust.visibleRange,
      onLoadMoreCandles: loadMoreCandles,
      onRemoveIndicator: (String indicator) {
        setState(() {
          indicators = [...indicators];
          indicators.removeWhere((element) => element.name == indicator);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    StockLineController? dayLineController =
        multiStockLineController.stockLineController;
    String title = widget.title;
    if (dayLineController != null) {
      title = '${dayLineController.tsCode}-${dayLineController.name}';
    }
    List<Widget> rightWidgets = [
      IconButton(
          tooltip: AppLocalizations.t('Previous'),
          onPressed: () async {
            await multiStockLineController.previous();
          },
          icon: const Icon(Icons.skip_previous_outlined)),
      IconButton(
          tooltip: AppLocalizations.t('Next'),
          onPressed: () async {
            await multiStockLineController.next();
          },
          icon: const Icon(Icons.skip_next_outlined)),
    ];
    return AppBarView(
      title: title,
      withLeading: true,
      rightWidgets: rightWidgets,
      child: Center(
        child: _buildCandlesticks(candles),
      ),
    );
  }

  @override
  void dispose() {
    multiStockLineController.removeListener(_update);
    super.dispose();
  }
}
