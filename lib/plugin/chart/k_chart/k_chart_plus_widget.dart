import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/chart/k_chart/kline_controller.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:k_chart_plus/chart_translations.dart';
import 'package:k_chart_plus/k_chart_plus.dart';

class KChartPlusController {
  final RxList<KLineEntity> klines = <KLineEntity>[].obs;
  final RxBool showLoading = false.obs;
  final RxBool showVol = true.obs;
  final RxBool hideGrid = false.obs;
  final RxBool showNowPrice = true.obs;
  final RxBool isTrendLine = false.obs;
  final Rx<VerticalTextAlignment> verticalTextAlignment =
      VerticalTextAlignment.left.obs;
  final Rx<MainState> mainState = MainState.MA.obs;
  final RxList<SecondaryState> secondaryState =
      <SecondaryState>[SecondaryState.MACD].obs;
  final RxList<DepthEntity> bids = <DepthEntity>[].obs;
  final RxList<DepthEntity> asks = <DepthEntity>[].obs;

  KChartPlusController() {
    _init();
  }

  _init() {
    multiKlineController.online.addListener(() async {
      multiKlineController.klineController?.clear();
      showLoading.value = true;
      try {
        await multiKlineController.load();
        showLoading.value = false;
      } catch (e) {
        showLoading.value = false;
        logger.e('Load data failure:$e');
      }
      buildKlines();
    });
    multiKlineController.lineType.addListener(() async {
      showLoading.value = true;
      try {
        await multiKlineController.load();
        showLoading.value = false;
      } catch (e) {
        showLoading.value = false;
        logger.e('Load data failure:$e');
      }
      buildKlines();
    });
    multiKlineController.currentIndex.addListener(() async {
      showLoading.value = true;
      try {
        await multiKlineController.load();
        showLoading.value = false;
      } catch (e) {
        showLoading.value = false;
        logger.e('Load data failure:$e');
      }
      buildKlines();
    });
  }

  bool get isLine {
    KlineController? klineController = multiKlineController.klineController;
    if (klineController != null) {
      return klineController.lineType == 100;
    }

    return false;
  }

  /// 创建图形的数据
  buildKlines() {
    KlineController? klineController = multiKlineController.klineController;
    if (klineController != null) {
      double width = appDataProvider.secondaryBodyWidth;
      int gap = 1;
      if (width < 600) {
        gap = 5;
      } else if (width < 1000) {
        gap = 3;
      } else {
        gap = 2;
      }
      List<dynamic> data = klineController.data.value;
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

          if (minute % gap != 0) {
            continue;
          }
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
  }
}

/// 增强版本的k_chart
class KChartPlusWidget extends StatelessWidget {
  final KChartPlusController kChartPlusController;

  KChartPlusWidget({super.key, required this.kChartPlusController});

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
      kChartPlusController.bids.insert(0, item);
    }

    amount = 0.0;
    asks.sort((left, right) => left.price.compareTo(right.price));
    for (var item in asks) {
      amount += item.vol;
      item.vol = amount;
      kChartPlusController.asks.add(item);
    }
  }

  Widget buildVolButton() {
    return TextButton(
      onPressed: () {
        kChartPlusController.showVol.value =
            !kChartPlusController.showVol.value;
      },
      child: Text(
        AppLocalizations.t('Trade volume'),
        style: TextStyle(
          color: kChartPlusController.showVol.value
              ? myself.primary
              : Colors.white,
        ),
      ),
    );
  }

  List<Widget> buildMainButtons() {
    return MainState.values.map((e) {
      return TextButton(
        onPressed: () {
          kChartPlusController.mainState.value = e;
        },
        child: Text(
          AppLocalizations.t(e.name),
          style: TextStyle(
            color: kChartPlusController.mainState.value == e
                ? myself.primary
                : Colors.white,
          ),
        ),
      );
    }).toList();
  }

  List<Widget> buildSecondButtons() {
    return SecondaryState.values.map((e) {
      return TextButton(
        onPressed: () {
          if (kChartPlusController.secondaryState.contains(e)) {
            kChartPlusController.secondaryState.remove(e);
          } else {
            kChartPlusController.secondaryState.add(e);
          }
        },
        child: Text(
          AppLocalizations.t(e.name),
          style: TextStyle(
            color: kChartPlusController.secondaryState.contains(e)
                ? myself.primary
                : Colors.white,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildToolPanel(BuildContext context) {
    logger.i('rebuild tool panel');
    return Container(
        color: Colors.grey,
        child: Wrap(children: [
          buildVolButton(),
          ...buildMainButtons(),
          ...buildSecondButtons()
        ]));
  }

  Widget _buildDepthChart() {
    return Container(
      color: Colors.white,
      height: 320,
      width: double.infinity,
      child: DepthChart(
        kChartPlusController.bids.value,
        kChartPlusController.asks.value,
        myself.themeMode == ThemeMode.light
            ? lightChartColors
            : darkChartColors,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (kChartPlusController.klines.value.isEmpty) {
        return nilBox;
      }
      return ListView(
        shrinkWrap: true,
        children: <Widget>[
          _buildToolPanel(context),
          Stack(children: <Widget>[
            KChartWidget(
              kChartPlusController.klines.value,
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
              isLine: kChartPlusController.isLine,
              mBaseHeight: 360,
              isTrendLine: kChartPlusController.isTrendLine.value,
              mainState: kChartPlusController.mainState.value,
              volHidden: !kChartPlusController.showVol.value,
              secondaryStateLi: kChartPlusController.secondaryState.toSet(),
              showNowPrice: kChartPlusController.showNowPrice.value,
              hideGrid: kChartPlusController.hideGrid.value,
              isTapShowInfoDialog: false,
              fixedLength: 2,
              timeFormat: TimeFormat.YEAR_MONTH_DAY_WITH_HOUR,
              verticalTextAlignment:
                  kChartPlusController.verticalTextAlignment.value,
              maDayList: const [5, 10, 30],
            ),
            if (kChartPlusController.showLoading.value)
              Container(
                width: double.infinity,
                height: 450,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
          ]),
          const SizedBox(height: 30),
          if (kChartPlusController.bids.isNotEmpty &&
              kChartPlusController.asks.isNotEmpty)
            _buildDepthChart()
        ],
      );
    });
  }
}
