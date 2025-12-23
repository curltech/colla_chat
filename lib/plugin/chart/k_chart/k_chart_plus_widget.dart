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
  final List<MainIndicator> defaultMainIndicators = [
    MAIndicator(),
    EMAIndicator(),
    BOLLIndicator(),
    SARIndicator(),
  ];
  final List<SecondaryIndicator> defaultSecondaryIndicators = [
    MACDIndicator(),
    KDJIndicator(),
    RSIIndicator(),
    WRIndicator(),
    CCIIndicator(),
  ];
  final RxList<MainIndicator> mainIndicators = <MainIndicator>[
    MAIndicator(
      calcParams: [
        5,
        10,
        30,
        60
      ], // [Optional] Display of MA. Default is [5, 10, 30, 60]
    ),
    EMAIndicator(
      calcParams: [
        5,
        10,
        30,
        60
      ], // [Optional] Display of EMA. Default is [5, 10, 30, 60]
    ),
    BOLLIndicator(),
    SARIndicator(),
  ].obs;
  final RxList<SecondaryIndicator> secondaryIndicators = <SecondaryIndicator>[
    MACDIndicator(),
    KDJIndicator(),
    RSIIndicator(),
    WRIndicator(),
    CCIIndicator(),
  ].obs;
  final RxList<DepthEntity> bids = <DepthEntity>[].obs;
  final RxList<DepthEntity> asks = <DepthEntity>[].obs;
  final KChartStyle chartStyle = KChartStyle();
  final KChartColors lightChartColors = KChartColors(
    dnColor: const Color(0xFF14AD8F),
    upColor: const Color(0xFFD5405D),
    nowPriceUpColor: const Color(0xFFD5405D),
    nowPriceDnColor: const Color(0xFF14AD8F),
  );
  final KChartColors darkChartColors = KChartColors(
    bgColor: Colors.black,
    selectFillColor: Colors.black,
    dnColor: const Color(0xFF14AD8F),
    upColor: const Color(0xFFD5405D),
    nowPriceUpColor: const Color(0xFFD5405D),
    nowPriceDnColor: const Color(0xFF14AD8F),
  );

  final DepthChartColors lightDepthChartColors = DepthChartColors(
    dnColor: const Color(0xFF14AD8F),
    upColor: const Color(0xFFD5405D),
  );
  final DepthChartColors darkDepthChartColors = DepthChartColors(
    selectFillColor: Colors.black,
    dnColor: const Color(0xFF14AD8F),
    upColor: const Color(0xFFD5405D),
  );

  KChartPlusController() {
    _init();
  }

  void _init() {
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
  void buildKlines() {
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
        DataUtil.calculateAll(
            klines, mainIndicators.value, secondaryIndicators.value);
      }
      this.klines.assignAll(klines);
    }
  }
}

/// 增强版本的k_chart
class KChartPlusWidget extends StatelessWidget {
  final KChartPlusController kChartPlusController;

  const KChartPlusWidget({super.key, required this.kChartPlusController});

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

  Widget _buildTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 12, 15),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              // color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget buildVolButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _buildButton(
            title: 'VOL',
            isActive: !kChartPlusController.showVol.value,
            onPress: () {
              kChartPlusController.showVol.value =
                  !kChartPlusController.showVol.value;
            }),
      ),
    );
  }

  Widget buildMainButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.start,
        spacing: 10,
        runSpacing: 10,
        children: kChartPlusController.defaultMainIndicators.map((e) {
          bool isActive = kChartPlusController.mainIndicators.contains(e);
          return _buildButton(
            title: e.shortName,
            isActive: isActive,
            onPress: () {
              if (isActive) {
                kChartPlusController.mainIndicators.remove(e);
              } else {
                kChartPlusController.mainIndicators.add(e);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget buildSecondButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.start,
        spacing: 10,
        runSpacing: 5,
        children: kChartPlusController.defaultSecondaryIndicators.map((e) {
          bool isActive = kChartPlusController.secondaryIndicators.contains(e);
          return _buildButton(
            title: e.shortName,
            isActive: isActive,
            onPress: () {
              if (isActive) {
                kChartPlusController.secondaryIndicators.remove(e);
              } else {
                kChartPlusController.secondaryIndicators.add(e);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildButton({
    required String title,
    required isActive,
    required Function onPress,
  }) {
    late Color? bgColor;
    if (isActive) {
      bgColor = myself.primaryColor.withAlpha(30);
    } else {
      bgColor = Colors.transparent;
    }
    return InkWell(
      onTap: () {
        onPress();
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        constraints: const BoxConstraints(minWidth: 60),
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: Text(
          title,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildToolPanel(BuildContext context) {
    logger.i('rebuild tool panel');
    return Container(
        color: Colors.grey,
        child: Wrap(children: [
          buildVolButton(),
          buildMainButtons(),
          buildSecondButtons()
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
            ? kChartPlusController.lightDepthChartColors
            : kChartPlusController.darkDepthChartColors,
        chartTranslations: DepthChartTranslations(
            // date: AppLocalizations.t('Trade date'),
            // open: AppLocalizations.t('Open price'),
            // high: AppLocalizations.t('High price'),
            // low: AppLocalizations.t('Low price'),
            // close: AppLocalizations.t('Close price'),
            // changeAmount: AppLocalizations.t('Amount change'),
            // change: AppLocalizations.t('Amount change%'),
            // amount: AppLocalizations.t('Trade amount'),
            // vol: AppLocalizations.t('Trade volume'),
            ),
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
              // Required，Data must be an ordered list，(history=>now)
              kChartPlusController.chartStyle, // Required for styling purposes
              myself.themeMode == ThemeMode.light
                  ? kChartPlusController.lightChartColors
                  : kChartPlusController
                      .darkChartColors, // Required for styling purposes
              mBaseHeight: 350,
              // height of chart (not contain Vol and Secondary)
              mSecondaryHeight: 80,
              // height of secondary chart
              isTrendLine: false,
              // You can use Trendline by long-pressing and moving your finger after setting true to isTrendLine property.
              volHidden: kChartPlusController.showVol.value,
              // hide volume
              mainIndicators: kChartPlusController.mainIndicators,
              // [mainIndicators] Decide what the main view shows
              secondaryIndicators: kChartPlusController.secondaryIndicators,
              // [secondaryIndicators] Decide what the sub view shows
              fixedLength: 6,
              showNowPrice: true,
              // show now price
              timeFormat: TimeFormat.YEAR_MONTH_DAY_WITH_HOUR,
              isOnDrag: (isDrag) {},
              // true is on Drag.Don't load data while Draging.
              xFrontPadding: 100,
              // padding in front
              detailBuilder: (entity) {
                // show detail popup
                return PopupInfoView(
                  entity: entity,
                  chartColors: myself.themeMode == ThemeMode.light
                      ? kChartPlusController.lightChartColors
                      : kChartPlusController.darkChartColors,
                  fixedLength: 2,
                );
              },
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
            _buildDepthChart(),
        ],
      );
    });
  }
}

class PopupInfoView extends StatelessWidget {
  final KLineEntity entity;
  final KChartColors chartColors;
  final int fixedLength;

  const PopupInfoView({
    super.key,
    required this.entity,
    required this.chartColors,
    required this.fixedLength,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: chartColors.selectFillColor,
          border: Border.all(color: chartColors.selectBorderColor, width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6.0, 6.0, 6.0, 0.0),
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    double upDown = entity.change ?? entity.close - entity.open;
    double upDownPercent = entity.ratio ?? (upDown / entity.open) * 100;
    final double? entityAmount = entity.amount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildItem('Date', getDate(entity.time)),
        _buildItem(
          'Open',
          NumberUtil.formatFixed(entity.open, fixedLength) ?? '--',
        ),
        _buildItem(
          'High',
          NumberUtil.formatFixed(entity.high, fixedLength) ?? '--',
        ),
        _buildItem(
          'Low',
          NumberUtil.formatFixed(entity.low, fixedLength) ?? '--',
        ),
        _buildItem(
          'Close',
          NumberUtil.formatFixed(entity.close, fixedLength) ?? '--',
        ),
        _buildColorItem(
          'Change',
          NumberUtil.formatFixed(upDown, fixedLength) ?? '--',
          upDown > 0,
        ),
        _buildColorItem(
          'Change%',
          '${upDownPercent.toStringAsFixed(2)}%',
          upDownPercent > 0,
        ),
        _buildItem(
          'Volume',
          NumberUtil.formatCompact(entity.vol),
        ),
        if (entityAmount != null)
          _buildItem(
            'Amount',
            entityAmount.toInt().toString(),
          ),
      ],
    );
  }

  Widget _buildColorItem(String label, String info, bool isUp) {
    if (isUp) {
      return _buildItem(
        label,
        '+$info',
        textColor: chartColors.upColor,
      );
    }
    return _buildItem(label, info, textColor: chartColors.dnColor);
  }

  Widget _buildItem(String label, String info, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            AppLocalizations.t(label),
            style: TextStyle(color: textColor, fontSize: 10.0),
          ),
          Expanded(
            child: Text(
              AppLocalizations.t(info),
              style: TextStyle(color: textColor, fontSize: 10.0),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String getDate(int? date) => dateFormat(
        DateTime.fromMillisecondsSinceEpoch(
            date ?? DateTime.now().millisecondsSinceEpoch),
        TimeFormat.YEAR_MONTH_DAY_WITH_HOUR,
      );
}
