import 'package:colla_chat/entity/base.dart';

///
class QStat extends BaseEntity {
  String? tsCode;
  String? securityName;
  String? industry;
  String? sector;
  String? startDate;
  String? endDate;
  int? tradeDate;
  String? actualStartDate;
  int? term;
  String? source;
  String? sourceName;
  int? reportNumber;
  num? pe;
  num? peg;
  num? shareNumber;
  num? high;
  num? close;
  num? marketValue;
  num? yearOperateIncome;
  num? yearNetProfit;
  num? totalOperateIncome;
  num? pctChgHigh;
  num? pctChgClose;
  num? pctChgMarketValue;
  num? weightAvgRoe;
  num? grossProfitMargin;
  num? parentNetProfit;
  num? basicEps;
  num? orLastMonth;
  num? npLastMonth;
  num? yoySales;
  num? yoyDeduNp;
  num? cfps;
  num? dividendYieldRatio;

  QStat.fromJson(Map json)
      : tsCode = json['ts_code'],
        securityName = json['security_name'],
        industry = json['industry,omitempty'],
        sector = json['sector,omitempty'],
        startDate = json['start_date'],
        endDate = json['end_date'],
        tradeDate = json['trade_date'],
        actualStartDate = json['actual_start_date'],
        term = json['term'],
        source = json['source'],
        sourceName = json['source_name'],
        reportNumber = json['report_number'],
        pe = json['pe'],
        peg = json['peg'],
        shareNumber = json['share_number'],
        high = json['high'],
        close = json['close'],
        marketValue = json['market_value'],
        yearOperateIncome = json['year_operate_income'],
        yearNetProfit = json['year_net_profit'],
        totalOperateIncome = json['total_operate_income'],
        pctChgHigh = json['pct_chg_high'],
        pctChgClose = json['pct_chg_close'],
        pctChgMarketValue = json['pct_chg_market_value'],
        weightAvgRoe = json['weight_avg_roe'],
        grossProfitMargin = json['gross_profit_margin'],
        parentNetProfit = json['parent_net_profit'],
        basicEps = json['basic_eps'],
        orLastMonth = json['or_last_month'],
        npLastMonth = json['np_last_month'],
        yoySales = json['yoy_sales'],
        yoyDeduNp = json['yoy_dedu_np'],
        cfps = json['cfps'],
        dividendYieldRatio = json['dividend_yield_ratio'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'ts_code': tsCode,
      'security_name': securityName,
      'industry,omitempty': industry,
      'sector,omitempty': sector,
      'start_date': startDate,
      'end_date': endDate,
      'trade_date': tradeDate,
      'actual_start_date': actualStartDate,
      'term': term,
      'source': source,
      'source_name': sourceName,
      'report_number': reportNumber,
      'pe': pe,
      'peg': peg,
      'share_number': shareNumber,
      'high': high,
      'close': close,
      'market_value': marketValue,
      'year_operate_income': yearOperateIncome,
      'year_net_profit': yearNetProfit,
      'total_operate_income': totalOperateIncome,
      'pct_chg_high': pctChgHigh,
      'pct_chg_close': pctChgClose,
      'pct_chg_market_value': pctChgMarketValue,
      'weight_avg_roe': weightAvgRoe,
      'gross_profit_margin': grossProfitMargin,
      'parent_net_profit': parentNetProfit,
      'basic_eps': basicEps,
      'or_last_month': orLastMonth,
      'np_last_month': npLastMonth,
      'yoy_sales': yoySales,
      'yoy_dedu_np': yoyDeduNp,
      'cfps': cfps,
      'dividend_yield_ratio': dividendYieldRatio,
    });
    return json;
  }
}
