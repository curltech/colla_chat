import 'package:colla_chat/plugin/chart/k_chart/kline_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:flutter/material.dart';
import 'package:get/state_manager.dart';
import 'package:interactive_chart/interactive_chart.dart';

class KlineChartWidget extends StatelessWidget {
  KlineChartWidget({super.key});

  Rx<List<CandleData>> candles = Rx<List<CandleData>>([]);

  _computeTrendLines() {
    final ma7 = CandleData.computeMA(candles.value, 7);
    final ma30 = CandleData.computeMA(candles.value, 30);
    final ma90 = CandleData.computeMA(candles.value, 90);

    for (int i = 0; i < candles.value.length; i++) {
      candles.value[i].trends = [ma7[i], ma30[i], ma90[i]];
    }
  }

  _removeTrendLines() {
    for (final data in candles.value) {
      data.trends = [];
    }
  }

  /// 创建图形的数据
  _buildCandles(List<dynamic> data) {
    List<CandleData> candles = [];
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
      int timestamp = date
          .copyWith(
              year: date.year,
              month: date.month,
              day: date.day,
              hour: hour,
              minute: minute)
          .millisecondsSinceEpoch;
      num high = map['high'];
      num low = map['low'];
      num open = map['open'];
      num close = map['close'];
      num volume = map['vol'];
      CandleData candle = CandleData(
          timestamp: timestamp,
          high: high.toDouble(),
          low: low.toDouble(),
          open: open.toDouble(),
          close: close.toDouble(),
          volume: volume.toDouble());
      candles.add(candle);
    }
    this.candles.value.assignAll(candles);
  }

  ChartStyle _buildChartStyle(BuildContext context) {
    final bool isDark = myself.getBrightness(context) == Brightness.dark;
    return ChartStyle(
      priceGainColor: Colors.teal[200]!,
      priceLossColor: Colors.blueGrey,
      volumeColor: Colors.teal.withOpacity(0.8),
      trendLineStyles: [
        Paint()
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round
          ..color = Colors.deepOrange,
        Paint()
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.round
          ..color = Colors.orange,
      ],
      priceGridLineColor: Colors.blue[200]!,
      priceLabelStyle: TextStyle(color: Colors.blue[200]),
      timeLabelStyle: TextStyle(color: Colors.blue[200]),
      selectionHighlightColor: Colors.red.withOpacity(0.2),
      overlayBackgroundColor: Colors.red[900]!.withOpacity(0.6),
      overlayTextStyle: TextStyle(color: Colors.red[100]),
      timeLabelHeight: 32,
      volumeHeightFactor: 0.2, // volume area is 20% of total height
    );
  }

  Widget _buildInteractiveChart(BuildContext context) {
    final ChartStyle style = _buildChartStyle(context);
    return Obx(
      () {
        if (candles.value.isEmpty) {
          return nilBox;
        }
        return Column(children: [
          InteractiveChart(
            key: UniqueKey(),
            candles: candles.value,
            style: style,
            /** Customize axis labels */
            // timeLabel: (timestamp, visibleDataCount) => "📅",
            // priceLabel: (price) => "${price.round()} 💎",
            /** Customize overlay (tap and hold to see it)
             ** Or return an empty object to disable overlay info. */
            // overlayInfo: (candle) => {
            //   "💎": "🤚    ",
            //   "Hi": "${candle.high?.toStringAsFixed(2)}",
            //   "Lo": "${candle.low?.toStringAsFixed(2)}",
            // },
            /** Callbacks */
            // onTap: (candle) => print("user tapped on $candle"),
            // onCandleResize: (width) => print("each candle is $width wide"),
          )
        ]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      KlineController? klineController = multiKlineController.klineController;
      if (klineController != null) {
        List<dynamic> data = klineController.data.value;
        _buildCandles(data);
      }
      return _buildInteractiveChart(context);
    });
  }
}
