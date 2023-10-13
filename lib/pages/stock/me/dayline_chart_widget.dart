import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/stock/share.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/loading_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:candlesticks/candlesticks.dart';

class DayLineController extends DataListController<dynamic> {
  String? _tsCode;
  String? name;
  int _lineType = 101;

  int? count;

  String? get tsCode {
    return _tsCode;
  }

  set tsCode(String? tsCode) {
    if (_tsCode != tsCode) {
      _tsCode = tsCode;
      data.clear();
      count = null;
      notifyListeners();
    }
  }

  int get lineType {
    return _lineType;
  }

  set lineType(int lineType) {
    if (_lineType != lineType) {
      _lineType = lineType;
      data.clear();
      count = null;
      notifyListeners();
    }
  }
}

/// 增加自选股的查询结果控制器
final DayLineController dayLineController = DayLineController();

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

  @override
  void initState() {
    dayLineController.addListener(_update);
    super.initState();
  }

  _update() {
    setState(() {});
  }

  Future<List<Candle>> loadMoreCandles() async {
    String? tsCode = dayLineController.tsCode;
    if (tsCode == null) {
      dayLineController.clear();
      return <Candle>[];
    }

    List<dynamic> data = dayLineController.data;
    int? count = dayLineController.count;
    if (count == null || data.length < count) {
      Map<String, dynamic> response;
      int lineType = dayLineController.lineType;
      if (lineType == 101) {
        response = await shareService.findPreceding(tsCode,
            from: data.length, limit: 100);
      } else {
        response = await shareService.findLinePreceding(tsCode,
            lineType: lineType, from: data.length, limit: 100);
      }
      data = response['data'];
      dayLineController.insertAll(0, data);
      count = response['count'];
      dayLineController.count = count;
    }
    data = dayLineController.data;
    List<Candle> candles = [];
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

    return candles;
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

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: '${dayLineController.tsCode}-${dayLineController.name}',
      withLeading: true,
      child: Center(
        child: FutureBuilder(
          future: loadMoreCandles(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              List<Candle>? candles = snapshot.data;
              if (candles != null) {
                final style = myself.getBrightness(context) == Brightness.dark
                    ? dark()
                    : light();
                return Candlesticks(
                  indicators: indicators,
                  actions: <ToolBarAction>[
                    ToolBarAction(
                      onPressed: () {},
                      child: Text(AppLocalizations.t('dayline')),
                    ),
                  ],
                  candles: candles,
                  style: style,
                  chartAdjust: ChartAdjust.visibleRange,
                  onLoadMoreCandles: loadMoreCandles,
                  onRemoveIndicator: (String indicator) {
                    setState(() {
                      indicators = [...indicators];
                      indicators
                          .removeWhere((element) => element.name == indicator);
                    });
                  },
                );
              }
            }
            return LoadingUtil.buildLoadingIndicator();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    dayLineController.removeListener(_update);
    super.dispose();
  }
}
