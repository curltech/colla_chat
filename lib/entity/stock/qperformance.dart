import 'package:colla_chat/entity/base.dart';

class QPerformance extends BaseEntity {
  String? tsCode;
  String? securityName;
  String? industry;
  String? sector;
  String? qDate;
  String? nDate;
  int? tradeDate;
  String? source;
  int? lineType;
  num? pe;
  num? peg;
  num? shareNumber;
  num? high;
  num? close;
  num? marketValue;
  num? yearNetProfit;
  num? yearOperateIncome;
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

  QPerformance.fromJson(super.json)
      : tsCode = json['ts_code'],
        securityName = json['security_name'],
        industry = json['industry,omitempty'],
        sector = json['sector,omitempty'],
        qDate = json['qdate'],
        nDate = json['ndate'],
        tradeDate = json['trade_date'],
        source = json['source'],
        lineType = json['line_type'],
        pe = json['pe'],
        peg = json['peg'],
        shareNumber = json['share_number'],
        high = json['high'],
        close = json['close'],
        marketValue = json['market_value'],
        yearNetProfit = json['year_net_profit'],
        yearOperateIncome = json['year_operate_income'],
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
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'ts_code': tsCode,
      'security_name': securityName,
      'industry,omitempty': industry,
      'sector,omitempty': sector,
      'qdate': qDate,
      'ndate': nDate,
      'trade_date': tradeDate,
      'source': source,
      'line_type': lineType,
      'pe': pe,
      'peg': peg,
      'share_number': shareNumber,
      'high': high,
      'close': close,
      'market_value': marketValue,
      'year_net_profit': yearNetProfit,
      'year_operate_income': yearOperateIncome,
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
