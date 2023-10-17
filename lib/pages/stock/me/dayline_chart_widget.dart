import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/stock/day_line.dart';
import 'package:colla_chat/service/stock/wmqy_line.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:candlesticks/candlesticks.dart';

class DayLineController extends DataListController<dynamic> {
  String tsCode;
  String name;
  int lineType;

  int? count;

  DayLineController(this.tsCode, this.name, {this.lineType = 101});
}

class MultiDayLineController with ChangeNotifier {
  String? _tsCode;

  int _lineType = 101;

  /// 增加自选股的查询结果控制器
  final Map<String, Map<int, DayLineController>> dayLineControllers = {};

  /// 当前股票代码
  String? get tsCode {
    return _tsCode;
  }

  /// 设置当前股票代码
  set tsCode(String? tsCode) {
    if (_tsCode != tsCode) {
      _tsCode = tsCode;
      notifyListeners();
    }
  }

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
  DayLineController? get dayLineController {
    return dayLineControllers[_tsCode]?[_lineType];
  }

  /// 加入股票代码和控制器，并设置为当前
  put(String tsCode, String name) {
    if (tsCode != _tsCode) {
      _tsCode = tsCode;
      if (!dayLineControllers.containsKey(tsCode)) {
        dayLineControllers[tsCode] = {};
        dayLineControllers[tsCode]?[101] =
            DayLineController(tsCode, name, lineType: 101);
        dayLineControllers[tsCode]?[102] =
            DayLineController(tsCode, name, lineType: 102);
        dayLineControllers[tsCode]?[103] =
            DayLineController(tsCode, name, lineType: 103);
        dayLineControllers[tsCode]?[104] =
            DayLineController(tsCode, name, lineType: 104);
        dayLineControllers[tsCode]?[105] =
            DayLineController(tsCode, name, lineType: 105);
        dayLineControllers[tsCode]?[106] =
            DayLineController(tsCode, name, lineType: 106);
      }
      notifyListeners();
    }
  }

  remove(String tsCode) {
    if (dayLineControllers.containsKey(tsCode)) {
      dayLineControllers.remove(tsCode);
    }
  }
}

final MultiDayLineController multiDayLineController = MultiDayLineController();

class DayLineChartWidget extends StatefulWidget with TileDataMixin {
  const DayLineChartWidget({Key? key}) : super(key: key);

  @override
  State createState() => _DayLineChartWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'dayline_chart';

  @override
  IconData get iconData => Icons.insert_chart_outlined;

  @override
  String get title => 'DayLineChart';
}

class _DayLineChartWidgetState extends State<DayLineChartWidget> {
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
    multiDayLineController.addListener(_update);
    loadMoreCandles();
    super.initState();
  }

  _update() {
    loadMoreCandles();
  }

  Future<void> loadMoreCandles() async {
    DayLineController? dayLineController =
        multiDayLineController.dayLineController;
    if (dayLineController == null) {
      candles.clear();
      return;
    }
    String tsCode = dayLineController.tsCode;
    List<dynamic> data = dayLineController.data;
    int? count = dayLineController.count;
    if (count == null || data.length < count) {
      Map<String, dynamic> response;
      int lineType = dayLineController.lineType;
      if (lineType == 101) {
        response = await remoteDayLineService.sendFindPreceding(tsCode,
            from: data.length, limit: 100);
      } else {
        response = await remoteWmqyLineService.sendFindLinePreceding(tsCode,
            lineType: lineType, from: data.length, limit: 100);
      }
      data = response['data'];
      count = response['count'];
      dayLineController.insertAll(0, data);
      dayLineController.count = count;
    }
    if (data.isEmpty) {
      return;
    }
    data = dayLineController.data;
    candles.clear();
    for (int i = data.length - 1; i >= 0; i--) {
      Map<String, dynamic> map = data[i];
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
      primaryBear: const Color(0xFF026A69A),
      secondaryBear: const Color(0xFF8CCCC6),
    );
  }

  _buildCandlesticks(List<Candle> candles) {
    final bool isDark = myself.getBrightness(context) == Brightness.dark;
    final style = isDark ? dark() : light();
    return Candlesticks(
      indicators: indicators,
      actions: <ToolBarAction>[
        ToolBarAction(
          onPressed: () {
            multiDayLineController.lineType = 101;
          },
          child: Icon(
            Icons.calendar_view_day_outlined,
            color: multiDayLineController.lineType == 101
                ? myself.primary
                : isDark
                    ? Colors.white
                    : Colors.grey,
          ),
        ),
        ToolBarAction(
          onPressed: () {
            multiDayLineController.lineType = 102;
          },
          child: Icon(
            Icons.calendar_view_week_outlined,
            color: multiDayLineController.lineType == 102
                ? myself.primary
                : isDark
                    ? Colors.white
                    : Colors.grey,
          ),
        ),
        ToolBarAction(
          onPressed: () {
            multiDayLineController.lineType = 103;
          },
          child: Icon(
            Icons.calendar_view_month_outlined,
            color: multiDayLineController.lineType == 103
                ? myself.primary
                : isDark
                    ? Colors.white
                    : Colors.grey,
          ),
        ),
        ToolBarAction(
          onPressed: () {
            multiDayLineController.lineType = 104;
          },
          child: Icon(
            Icons.perm_contact_calendar,
            color: multiDayLineController.lineType == 104
                ? myself.primary
                : isDark
                    ? Colors.white
                    : Colors.grey,
          ),
        ),
        ToolBarAction(
          onPressed: () {
            multiDayLineController.lineType = 105;
          },
          child: Icon(
            Icons.calendar_month_outlined,
            color: multiDayLineController.lineType == 105
                ? myself.primary
                : isDark
                    ? Colors.white
                    : Colors.grey,
          ),
        ),
        ToolBarAction(
          onPressed: () {
            multiDayLineController.lineType = 106;
          },
          child: Icon(
            Icons.calendar_today_outlined,
            color: multiDayLineController.lineType == 106
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
    DayLineController? dayLineController =
        multiDayLineController.dayLineController;
    return AppBarView(
      title: '${dayLineController?.tsCode}-${dayLineController?.name}',
      withLeading: true,
      child: Center(
        child: _buildCandlesticks(candles),
      ),
    );
  }

  @override
  void dispose() {
    multiDayLineController.removeListener(_update);
    super.dispose();
  }
}
