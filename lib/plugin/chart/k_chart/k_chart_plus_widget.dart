import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/chart/k_chart/kline_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:k_chart_plus/chart_translations.dart';
import 'package:k_chart_plus/k_chart_plus.dart';

/// 增强版本的k_chart
class KChartPlusWidget extends StatelessWidget {
  KChartPlusWidget({super.key});

  final RxList<KLineEntity> klines = <KLineEntity>[].obs;
  final RxBool showLoading = false.obs;
  final RxBool showVol = true.obs;
  final RxBool isLine = false.obs;
  final RxBool hideGrid = true.obs;
  final RxBool showNowPrice = true.obs;
  final RxBool isTrendLine = false.obs;
  final Rx<VerticalTextAlignment> verticalTextAlignment =
      VerticalTextAlignment.left.obs;
  final Rx<MainState> mainState = MainState.MA.obs;
  final RxList<SecondaryState> secondaryState =
      <SecondaryState>[SecondaryState.MACD].obs;
  final RxList<DepthEntity> bids = <DepthEntity>[].obs;
  final RxList<DepthEntity> asks = <DepthEntity>[].obs;

  final ChartStyle chartStyle = ChartStyle();
  final ChartColors lightChartColors = ChartColors(
    dnColor: const Color(0xFF14AD8F),
    upColor: const Color(0xFFD5405D),
    nowPriceUpColor: const Color(0xFFD5405D),
    nowPriceDnColor: const Color(0xFF14AD8F),
  );
  final ChartColors darkChartColors = ChartColors(
    bgColor: Colors.black,
    selectFillColor: Colors.black,
    infoWindowNormalColor: Colors.white,
    infoWindowTitleColor: Colors.white,
    dnColor: const Color(0xFF14AD8F),
    upColor: const Color(0xFFD5405D),
    nowPriceUpColor: const Color(0xFFD5405D),
    nowPriceDnColor: const Color(0xFF14AD8F),
  );

  void initDepth(List<DepthEntity>? bids, List<DepthEntity>? asks) {
    if (bids == null || asks == null || bids.isEmpty || asks.isEmpty) return;
    double amount = 0.0;
    bids.sort((left, right) => left.price.compareTo(right.price));
    for (var item in bids.reversed) {
      amount += item.vol;
      item.vol = amount;
      this.bids.insert(0, item);
    }

    amount = 0.0;
    asks.sort((left, right) => left.price.compareTo(right.price));
    for (var item in asks) {
      amount += item.vol;
      item.vol = amount;
      this.asks.add(item);
    }
  }

  Widget buildVolButton() {
    return TextButton(
      onPressed: () {
        showVol.value = !showVol.value;
      },
      child: Text(
        AppLocalizations.t('Trade volume'),
        style: TextStyle(
          color: showVol.value ? myself.primary : Colors.white,
        ),
      ),
    );
  }

  List<Widget> buildMainButtons() {
    return MainState.values.map((e) {
      return TextButton(
        onPressed: () {
          mainState.value = e;
        },
        child: Text(
          AppLocalizations.t(e.name),
          style: TextStyle(
            color: mainState.value == e ? myself.primary : Colors.white,
          ),
        ),
      );
    }).toList();
  }

  List<Widget> buildSecondButtons() {
    return SecondaryState.values.map((e) {
      return TextButton(
        onPressed: () {
          if (secondaryState.contains(e)) {
            secondaryState.value.remove(e);
          } else {
            secondaryState.add(e);
          }
        },
        child: Text(
          AppLocalizations.t(e.name),
          style: TextStyle(
            color: secondaryState.contains(e) ? myself.primary : Colors.white,
          ),
        ),
      );
    }).toList();
  }

  /// 创建图形的数据
  _buildKlines(List<dynamic> data) {
    List<KLineEntity> klines = [];
    for (int i = 0; i < data.length; i++) {
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
      KLineEntity kline = KLineEntity.fromCustom(
          time: timestamp,
          high: high.toDouble(),
          low: low.toDouble(),
          open: open.toDouble(),
          close: close.toDouble(),
          vol: volume.toDouble());
      klines.add(kline);
    }
    if (klines.isNotEmpty) {
      DataUtil.calculate(klines, const [5, 10, 30]);
    }
    this.klines.assignAll(klines);
  }

  Widget _buildToolPanel(BuildContext context) {
    return Container(
        color: Colors.grey,
        child: Obx(() {
          return Wrap(children: [
            buildVolButton(),
            ...buildMainButtons(),
            ...buildSecondButtons()
          ]);
        }));
  }

  Widget _buildDepthChart() {
    return Container(
      color: Colors.white,
      height: 320,
      width: double.infinity,
      child: DepthChart(
        bids.value,
        asks.value,
        myself.themeMode == ThemeMode.light
            ? lightChartColors
            : darkChartColors,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      KlineController? klineController = multiKlineController.klineController;
      if (klineController != null) {
        List<dynamic> data = klineController.data.value;
        _buildKlines(data);
      }
      if (klines.value.isEmpty) {
        return nilBox;
      }
      return ListView(
        shrinkWrap: true,
        children: <Widget>[
          _buildToolPanel(context),
          Stack(children: <Widget>[
            KChartWidget(
              klines.value,
              chartStyle,
              myself.themeMode == ThemeMode.light
                  ? lightChartColors
                  : darkChartColors,
              chartTranslations: ChartTranslations(
                date: AppLocalizations.t('Trade date'),
                open: AppLocalizations.t('Open price'),
                high: AppLocalizations.t('High price'),
                low: AppLocalizations.t('Low price'),
                close: AppLocalizations.t('Close price'),
                changeAmount: AppLocalizations.t('Amount change'),
                change: AppLocalizations.t('Amount change%'),
                amount: AppLocalizations.t('Trade amount'),
                vol: AppLocalizations.t('Trade volume'),
              ),
              isLine: isLine.value,
              mBaseHeight: 360,
              isTrendLine: isTrendLine.value,
              mainState: mainState.value,
              volHidden: !showVol.value,
              secondaryStateLi: secondaryState.toSet(),
              showNowPrice: showNowPrice.value,
              hideGrid: hideGrid.value,
              isTapShowInfoDialog: false,
              fixedLength: 2,
              timeFormat: TimeFormat.YEAR_MONTH_DAY_WITH_HOUR,
              verticalTextAlignment: verticalTextAlignment.value,
              maDayList: const [5, 10, 30],
            ),
            if (showLoading.value)
              Container(
                width: double.infinity,
                height: 450,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
          ]),
          const SizedBox(height: 30),
          if (bids.isNotEmpty && asks.isNotEmpty) _buildDepthChart()
        ],
      );
    });
  }
}
