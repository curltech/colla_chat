import 'package:colla_chat/entity/base.dart';

class Performance extends BaseEntity {
  String securityCode;
  String securityNameAbbr;
  String? tradeMarketCode;
  String? tradeMarket;
  String? securityTypeCode;
  String? securityType;
  String? newestDate;
  String? reportDate;
  num? basicEps;
  num? deductBasicEps;
  num? totalOperateIncome;
  num? parentNetProfit;
  num? weightAvgRoe;
  num? yoySales;
  num? yoyDeduNp;
  num? bps;
  num? cfps;
  num? grossProfitMargin;
  num? orLastMonth;
  num? npLastMonth;
  String? assignDscrpt;
  String? payYear;
  String? publishName;
  num? dividendYieldRatio;
  String? noticeDate;
  String? orgCode;
  String? tradeMarketZJG;
  String? isNew;
  String? qDate;
  String? nDate;
  String? dataType;
  String? dataYear;
  String? dateMmDd;
  String? eITime;
  String? secuCode;

  Performance.fromJson(super.json)
      : securityCode = json['security_code'],
        securityNameAbbr = json['security_name_abbr'],
        tradeMarketCode = json['trade_market_code'],
        tradeMarket = json['trade_market'],
        securityTypeCode = json['security_type_code'],
        securityType = json['security_type'],
        newestDate = json['newest_date'],
        reportDate = json['report_date'],
        basicEps = json['basic_eps'],
        deductBasicEps = json['deduct_basic_eps'],
        totalOperateIncome = json['total_operate_income'],
        parentNetProfit = json['parent_net_profit'],
        weightAvgRoe = json['weight_avg_roe'],
        yoySales = json['yoy_sales'],
        yoyDeduNp = json['yoy_dedu_np'],
        bps = json['bps'],
        cfps = json['cfps'],
        grossProfitMargin = json['gross_profit_margin'],
        orLastMonth = json['or_last_month'],
        npLastMonth = json['np_last_month'],
        assignDscrpt = json['assign_dscrpt'],
        payYear = json['pay_year'],
        publishName = json['publish_name'],
        dividendYieldRatio = json['dividend_yield_ratio'],
        noticeDate = json['notice_date'],
        orgCode = json['org_code'],
        tradeMarketZJG = json['trade_market_zjg'],
        isNew = json['is_new'],
        qDate = json['qdate'],
        nDate = json['ndate'],
        dataType = json['data_type'],
        dataYear = json['data_year'],
        dateMmDd = json['date_mm_dd'],
        eITime = json['ei_time'],
        secuCode = json['secu_code'],
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'security_code': securityCode,
      'security_name_abbr': securityNameAbbr,
      'trade_market_code': tradeMarketCode,
      'trade_market': tradeMarket,
      'security_type_code': securityTypeCode,
      'security_type': securityType,
      'newest_date': newestDate,
      'report_date': reportDate,
      'basic_eps': basicEps,
      'deduct_basic_eps': deductBasicEps,
      'total_operate_income': totalOperateIncome,
      'parent_net_profit': parentNetProfit,
      'weight_avg_roe': weightAvgRoe,
      'yoy_sales': yoySales,
      'yoy_dedu_np': yoyDeduNp,
      'bps': bps,
      'cfps': cfps,
      'gross_profit_margin': grossProfitMargin,
      'or_last_month': orLastMonth,
      'np_last_month': npLastMonth,
      'assign_dscrpt': assignDscrpt,
      'pay_year': payYear,
      'publish_name': publishName,
      'dividend_yield_ratio': dividendYieldRatio,
      'notice_date': noticeDate,
      'org_code': orgCode,
      'trade_market_zjg': tradeMarketZJG,
      'is_new': isNew,
      'qdate': qDate,
      'ndate': nDate,
      'data_type': dataType,
      'data_year': dataYear,
      'date_mm_dd': dateMmDd,
      'ei_time': eITime,
      'secu_code': secuCode,
    });
    return json;
  }
}
