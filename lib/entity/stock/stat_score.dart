import 'package:colla_chat/entity/base.dart';

class StatScore extends BaseEntity {
  String tsCode;
  String securityName;
  String? startDate;
  String? endDate;
  int? term;
  int? reportNumber;
  int? tradeDate;
  String? industry;
  String? sector;
  String? area;
  String? market;
  int? listDate;
  String? listStatus;
  num? riskScore;
  num? rsdOrLastMonth;
  num? rsdNpLastMonth;
  num? rsdPctChgMarketValue;
  num? rsdYoySales;
  num? rsdYoyDeduNp;
  num? rsdPe;
  num? rsdWeightAvgRoe;
  num? rsdGrossprofitMargin;
  num? stableScore;
  num? meanPctChgMarketValue;
  num? meanYoySales;
  num? meanYoyDeduNp;
  num? meanOrLastMonth;
  num? meanNpLastMonth;
  num? meanPe;
  num? meanWeightAvgRoe;
  num? meanGrossprofitMargin;
  num? medianPctChgMarketValue;
  num? medianYoySales;
  num? medianYoyDeduNp;
  num? medianOrLastMonth;
  num? medianNpLastMonth;
  num? medianWeightAvgRoe;
  num? medianGrossprofitMargin;
  num? increaseScore;
  num? accPctChgMarketValue;
  num? accYoySales;
  num? accYoyDeduNp;
  num? accScore;
  num? medianPe;
  num? meanPeg;
  num? medianPeg;
  num? priceScore;
  num? corrYoySales;
  num? corrYoyDeduNp;
  num? corrYearNetProfit;
  num? corrYearOperateIncome;
  num? corrWeightAvgRoe;
  num? corrGrossprofitMargin;
  num? corrScore;
  num? lastPctChgMarketValue;
  num? lastYoySales;
  num? lastYoyDeduNp;
  num? lastOrLastMonth;
  num? lastNpLastMonth;
  num? lastMeanPe;
  num? lastMeanPeg;
  num? prosScore;
  num? trendScore;
  num? operationScore;
  num? totalScore;
  String? badTip;
  String? goodTip;
  num? percentileRiskScore;
  num? percentileStableScore;
  num? percentileIncreaseScore;
  num? percentileAccScore;
  num? percentilePriceScore;
  num? percentileCorrScore;
  num? percentileProsScore;
  num? percentileTrendScore;
  num? percentileOperationScore;
  num? percentileTotalScore;

  StatScore.fromJson(Map json)
      : tsCode = json['ts_code'],
        securityName = json['security_name'],
        startDate = json['start_date'],
        endDate = json['end_date'],
        term = json['term'],
        reportNumber = json['report_number'],
        tradeDate = json['trade_date'],
        industry = json['industry'],
        sector = json['sector,omitempty'],
        area = json['area'],
        market = json['market'],
        listDate = json['list_date'],
        listStatus = json['list_status'],
        riskScore = json['risk_score'],
        rsdOrLastMonth = json['rsd_or_last_month'],
        rsdNpLastMonth = json['rsd_np_last_month'],
        rsdPctChgMarketValue = json['rsd_pct_chg_market_value'],
        rsdYoySales = json['rsd_yoy_sales'],
        rsdYoyDeduNp = json['rsd_yoy_dedu_np'],
        rsdPe = json['rsd_pe'],
        rsdWeightAvgRoe = json['rsd_weight_avg_roe'],
        rsdGrossprofitMargin = json['rsd_gross_profit_margin'],
        stableScore = json['stable_score'],
        meanPctChgMarketValue = json['mean_pct_chg_market_value'],
        meanYoySales = json['mean_yoy_sales'],
        meanYoyDeduNp = json['mean_yoy_dedu_np'],
        meanOrLastMonth = json['mean_or_last_month'],
        meanNpLastMonth = json['mean_np_last_month'],
        meanPe = json['mean_pe'],
        meanWeightAvgRoe = json['mean_weight_avg_roe'],
        meanGrossprofitMargin = json['mean_gross_profit_margin'],
        medianPctChgMarketValue = json['median_pct_chg_market_value'],
        medianYoySales = json['median_yoy_sales'],
        medianYoyDeduNp = json['median_yoy_dedu_np'],
        medianOrLastMonth = json['median_or_last_month'],
        medianNpLastMonth = json['median_np_last_month'],
        medianWeightAvgRoe = json['median_weight_avg_roe'],
        medianGrossprofitMargin = json['median_gross_profit_margin'],
        increaseScore = json['increase_score'],
        accPctChgMarketValue = json['acc_pct_chg_market_value'],
        accYoySales = json['acc_yoy_sales'],
        accYoyDeduNp = json['acc_yoy_dedu_np'],
        accScore = json['acc_score'],
        medianPe = json['median_pe'],
        meanPeg = json['mean_peg'],
        medianPeg = json['median_peg'],
        priceScore = json['price_score'],
        corrYoySales = json['corr_yoy_sales'],
        corrYoyDeduNp = json['corr_yoy_dedu_np'],
        corrYearNetProfit = json['corr_year_net_profit'],
        corrYearOperateIncome = json['corr_year_operate_income'],
        corrWeightAvgRoe = json['corr_weight_avg_roe'],
        corrGrossprofitMargin = json['corr_gross_profit_margin'],
        corrScore = json['corr_score'],
        lastPctChgMarketValue = json['last_pct_chg_market_value'],
        lastYoySales = json['last_yoy_sales'],
        lastYoyDeduNp = json['last_yoy_dedu_np'],
        lastOrLastMonth = json['last_or_last_month'],
        lastNpLastMonth = json['last_np_last_month'],
        lastMeanPe = json['last_mean_pe'],
        lastMeanPeg = json['last_mean_peg'],
        prosScore = json['pros_score'],
        trendScore = json['trend_score'],
        operationScore = json['operation_score'],
        totalScore = json['total_score'],
        badTip = json['bad_tip'],
        goodTip = json['good_tip'],
        percentileRiskScore = json['percentile_risk_score'],
        percentileStableScore = json['percentile_stable_score'],
        percentileIncreaseScore = json['percentile_increase_score'],
        percentileAccScore = json['percentile_acc_score'],
        percentilePriceScore = json['percentile_price_score'],
        percentileCorrScore = json['percentile_corr_score'],
        percentileProsScore = json['percentile_pros_score'],
        percentileTrendScore = json['percentile_trend_score'],
        percentileOperationScore = json['percentile_operation_score'],
        percentileTotalScore = json['percentile_total_score'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'ts_code': tsCode,
      'security_name': securityName,
      'start_date': startDate,
      'end_date': endDate,
      'term': term,
      'report_number': reportNumber,
      'trade_date': tradeDate,
      'industry': industry,
      'sector,omitempty': sector,
      'area': area,
      'market': market,
      'list_date': listDate,
      'list_status': listStatus,
      'risk_score': riskScore,
      'rsd_or_last_month': rsdOrLastMonth,
      'rsd_np_last_month': rsdNpLastMonth,
      'rsd_pct_chg_market_value': rsdPctChgMarketValue,
      'rsd_yoy_sales': rsdYoySales,
      'rsd_yoy_dedu_np': rsdYoyDeduNp,
      'rsd_pe': rsdPe,
      'rsd_weight_avg_roe': rsdWeightAvgRoe,
      'rsd_gross_profit_margin': rsdGrossprofitMargin,
      'stable_score': stableScore,
      'mean_pct_chg_market_value': meanPctChgMarketValue,
      'mean_yoy_sales': meanYoySales,
      'mean_yoy_dedu_np': meanYoyDeduNp,
      'mean_or_last_month': meanOrLastMonth,
      'mean_np_last_month': meanNpLastMonth,
      'mean_pe': meanPe,
      'mean_weight_avg_roe': meanWeightAvgRoe,
      'mean_gross_profit_margin': meanGrossprofitMargin,
      'median_pct_chg_market_value': medianPctChgMarketValue,
      'median_yoy_sales': medianYoySales,
      'median_yoy_dedu_np': medianYoyDeduNp,
      'median_or_last_month': medianOrLastMonth,
      'median_np_last_month': medianNpLastMonth,
      'median_weight_avg_roe': medianWeightAvgRoe,
      'median_gross_profit_margin': medianGrossprofitMargin,
      'increase_score': increaseScore,
      'acc_pct_chg_market_value': accPctChgMarketValue,
      'acc_yoy_sales': accYoySales,
      'acc_yoy_dedu_np': accYoyDeduNp,
      'acc_score': accScore,
      'median_pe': medianPe,
      'mean_peg': meanPeg,
      'median_peg': medianPeg,
      'price_score': priceScore,
      'corr_yoy_sales': corrYoySales,
      'corr_yoy_dedu_np': corrYoyDeduNp,
      'corr_year_net_profit': corrYearNetProfit,
      'corr_year_operate_income': corrYearOperateIncome,
      'corr_weight_avg_roe': corrWeightAvgRoe,
      'corr_gross_profit_margin': corrGrossprofitMargin,
      'corr_score': corrScore,
      'last_pct_chg_market_value': lastPctChgMarketValue,
      'last_yoy_sales': lastYoySales,
      'last_yoy_dedu_np': lastYoyDeduNp,
      'last_or_last_month': lastOrLastMonth,
      'last_np_last_month': lastNpLastMonth,
      'last_mean_pe': lastMeanPe,
      'last_mean_peg': lastMeanPeg,
      'pros_score': prosScore,
      'trend_score': trendScore,
      'operation_score': operationScore,
      'total_score': totalScore,
      'bad_tip': badTip,
      'good_tip': goodTip,
      'percentile_risk_score': percentileRiskScore,
      'percentile_stable_score': percentileStableScore,
      'percentile_increase_score': percentileIncreaseScore,
      'percentile_acc_score': percentileAccScore,
      'percentile_price_score': percentilePriceScore,
      'percentile_corr_score': percentileCorrScore,
      'percentile_pros_score': percentileProsScore,
      'percentile_trend_score': percentileTrendScore,
      'percentile_operation_score': percentileOperationScore,
      'percentile_total_score': percentileTotalScore,
    });
    return json;
  }
}
