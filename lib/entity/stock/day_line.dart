import 'package:colla_chat/entity/base.dart';

class StockLine extends BaseEntity {
  String tsCode;
  int tradeDate;
  String? name;
  num? shareNumber;
  num? open;
  num? high;
  num? low;
  num? close;
  num? vol;
  num? amount;
  num? turnover;
  num? preClose;
  num? mainNetInflow;
  num? smallNetInflow;
  num? middleNetInflow;
  num? largeNetInflow;
  num? superNetInflow;

  StockLine.fromJson(super.json)
      : tsCode = json['ts_code'],
        name = json['name'],
        tradeDate = json['trade_date'],
        shareNumber = json['share_number'],
        open = json['open'],
        high = json['high'],
        low = json['low'],
        close = json['close'],
        vol = json['vol'],
        amount = json['amount'],
        turnover = json['turnover'],
        preClose = json['pre_close'],
        mainNetInflow = json['main_net_inflow'],
        smallNetInflow = json['small_net_inflow'],
        middleNetInflow = json['middle_net_inflow'],
        largeNetInflow = json['large_net_inflow'],
        superNetInflow = json['super_net_inflow'],
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'ts_code': tsCode,
      'name': name,
      'trade_date': tradeDate,
      'share_number': shareNumber,
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'vol': vol,
      'amount': amount,
      'turnover': turnover,
      'pre_close': preClose,
      'main_net_inflow': mainNetInflow,
      'small_net_inflow': smallNetInflow,
      'middle_net_inflow': middleNetInflow,
      'large_net_inflow': largeNetInflow,
      'super_net_inflow': superNetInflow,
    });
    return json;
  }
}

class DayLine extends StockLine {
  num? pctMainNetInflow;
  num? pctSmallNetInflow;
  num? pctMiddleNetInflow;
  num? pctLargeNetInflow;
  num? pctSuperNetInflow;
  num? chgClose;
  num? pctChgOpen;
  num? pctChgHigh;
  num? pctChgLow;
  num? pctChgClose;
  num? pctChgAmount;
  num? pctChgVol;
  num? ma3Close;
  num? ma5Close;
  num? ma10Close;
  num? ma13Close;
  num? ma20Close;
  num? ma21Close;
  num? ma30Close;
  num? ma34Close;
  num? ma55Close;
  num? ma60Close;
  num? ma90Close;
  num? ma120Close;
  num? ma144Close;
  num? ma233Close;
  num? ma240Close;
  num? max3Close;
  num? max5Close;
  num? max10Close;
  num? max13Close;
  num? max20Close;
  num? max21Close;
  num? max30Close;
  num? max34Close;
  num? max55Close;
  num? max60Close;
  num? max90Close;
  num? max120Close;
  num? max144Close;
  num? max233Close;
  num? max240Close;
  num? min3Close;
  num? min5Close;
  num? min10Close;
  num? min13Close;
  num? min20Close;
  num? min21Close;
  num? min30Close;
  num? min34Close;
  num? min55Close;
  num? min60Close;
  num? min90Close;
  num? min120Close;
  num? min144Close;
  num? min233Close;
  num? min240Close;
  num? before1Ma3Close;
  num? before1Ma5Close;
  num? before1Ma10Close;
  num? before1Ma13Close;
  num? before1Ma20Close;
  num? before1Ma21Close;
  num? before1Ma30Close;
  num? before1Ma34Close;
  num? before1Ma55Close;
  num? before1Ma60Close;
  num? before3Ma3Close;
  num? before3Ma5Close;
  num? before3Ma10Close;
  num? before3Ma13Close;
  num? before3Ma20Close;
  num? before3Ma21Close;
  num? before3Ma30Close;
  num? before3Ma34Close;
  num? before3Ma55Close;
  num? before3Ma60Close;
  num? before5Ma3Close;
  num? before5Ma5Close;
  num? before5Ma10Close;
  num? before5Ma13Close;
  num? before5Ma20Close;
  num? before5Ma21Close;
  num? before5Ma30Close;
  num? before5Ma34Close;
  num? before5Ma55Close;
  num? before5Ma60Close;
  num? acc3PctChgClose;
  num? acc5PctChgClose;
  num? acc10PctChgClose;
  num? acc13PctChgClose;
  num? acc20PctChgClose;
  num? acc21PctChgClose;
  num? acc30PctChgClose;
  num? acc34PctChgClose;
  num? acc55PctChgClose;
  num? acc60PctChgClose;
  num? acc90PctChgClose;
  num? acc120PctChgClose;
  num? acc144PctChgClose;
  num? acc233PctChgClose;
  num? acc240PctChgClose;
  num? future1PctChgClose;
  num? future3PctChgClose;
  num? future5PctChgClose;
  num? future10PctChgClose;
  num? future13PctChgClose;
  num? future20PctChgClose;
  num? future21PctChgClose;
  num? future30PctChgClose;
  num? future34PctChgClose;
  num? future55PctChgClose;
  num? future60PctChgClose;
  num? future90PctChgClose;
  num? future120PctChgClose;
  num? future144PctChgClose;
  num? future233PctChgClose;
  num? future240PctChgClose;

  DayLine.fromJson(super.json)
      : pctMainNetInflow = json['pct_main_net_inflow'],
        pctSmallNetInflow = json['pct_small_net_inflow'],
        pctMiddleNetInflow = json['pct_middle_net_inflow'],
        pctLargeNetInflow = json['pct_large_net_inflow'],
        pctSuperNetInflow = json['pct_super_net_inflow'],
        chgClose = json['chg_close'],
        pctChgOpen = json['pct_chg_open'],
        pctChgHigh = json['pct_chg_high'],
        pctChgLow = json['pct_chg_low'],
        pctChgClose = json['pct_chg_close'],
        pctChgAmount = json['pct_chg_amount'],
        pctChgVol = json['pct_chg_vol'],
        ma3Close = json['ma3_close'],
        ma5Close = json['ma5_close'],
        ma10Close = json['ma10_close'],
        ma13Close = json['ma13_close'],
        ma20Close = json['ma20_close'],
        ma21Close = json['ma21_close'],
        ma30Close = json['ma30_close'],
        ma34Close = json['ma34_close'],
        ma55Close = json['ma55_close'],
        ma60Close = json['ma60_close'],
        ma90Close = json['ma90_close'],
        ma120Close = json['ma120_close'],
        ma144Close = json['ma144_close'],
        ma233Close = json['ma233_close'],
        ma240Close = json['ma240_close'],
        max3Close = json['max3_close'],
        max5Close = json['max5_close'],
        max10Close = json['max10_close'],
        max13Close = json['max13_close'],
        max20Close = json['max20_close'],
        max21Close = json['max21_close'],
        max30Close = json['max30_close'],
        max34Close = json['max34_close'],
        max55Close = json['max55_close'],
        max60Close = json['max60_close'],
        max90Close = json['max90_close'],
        max120Close = json['max120_close'],
        max144Close = json['max144_close'],
        max233Close = json['max233_close'],
        max240Close = json['max240_close'],
        min3Close = json['min3_close'],
        min5Close = json['min5_close'],
        min10Close = json['min10_close'],
        min13Close = json['min13_close'],
        min20Close = json['min20_close'],
        min21Close = json['min21_close'],
        min30Close = json['min30_close'],
        min34Close = json['min34_close'],
        min55Close = json['min55_close'],
        min60Close = json['min60_close'],
        min90Close = json['min90_close'],
        min120Close = json['min120_close'],
        min144Close = json['min144_close'],
        min233Close = json['min233_close'],
        min240Close = json['min240_close'],
        before1Ma3Close = json['before1_ma3_close'],
        before1Ma5Close = json['before1_ma5_close'],
        before1Ma10Close = json['before1_ma10_close'],
        before1Ma13Close = json['before1_ma13_close'],
        before1Ma20Close = json['before1_ma20_close'],
        before1Ma21Close = json['before1_ma21_close'],
        before1Ma30Close = json['before1_ma30_close'],
        before1Ma34Close = json['before1_ma34_close'],
        before1Ma55Close = json['before1_ma55_close'],
        before1Ma60Close = json['before1_ma60_close'],
        before3Ma3Close = json['before3_ma3_close'],
        before3Ma5Close = json['before3_ma5_close'],
        before3Ma10Close = json['before3_ma10_close'],
        before3Ma13Close = json['before3_ma13_close'],
        before3Ma20Close = json['before3_ma20_close'],
        before3Ma21Close = json['before3_ma21_close'],
        before3Ma30Close = json['before3_ma30_close'],
        before3Ma34Close = json['before3_ma34_close'],
        before3Ma55Close = json['before3_ma55_close'],
        before3Ma60Close = json['before3_ma60_close'],
        before5Ma3Close = json['before5_ma3_close'],
        before5Ma5Close = json['before5_ma5_close'],
        before5Ma10Close = json['before5_ma10_close'],
        before5Ma13Close = json['before5_ma13_close'],
        before5Ma20Close = json['before5_ma20_close'],
        before5Ma21Close = json['before5_ma21_close'],
        before5Ma30Close = json['before5_ma30_close'],
        before5Ma34Close = json['before5_ma34_close'],
        before5Ma55Close = json['before5_ma55_close'],
        before5Ma60Close = json['before5_ma60_close'],
        acc3PctChgClose = json['acc3_pct_chg_close'],
        acc5PctChgClose = json['acc5_pct_chg_close'],
        acc10PctChgClose = json['acc10_pct_chg_close'],
        acc13PctChgClose = json['acc13_pct_chg_close'],
        acc20PctChgClose = json['acc20_pct_chg_close'],
        acc21PctChgClose = json['acc21_pct_chg_close'],
        acc30PctChgClose = json['acc30_pct_chg_close'],
        acc34PctChgClose = json['acc34_pct_chg_close'],
        acc55PctChgClose = json['acc55_pct_chg_close'],
        acc60PctChgClose = json['acc60_pct_chg_close'],
        acc90PctChgClose = json['acc90_pct_chg_close'],
        acc120PctChgClose = json['acc120_pct_chg_close'],
        acc144PctChgClose = json['acc144_pct_chg_close'],
        acc233PctChgClose = json['acc233_pct_chg_close'],
        acc240PctChgClose = json['acc240_pct_chg_close'],
        future1PctChgClose = json['future1_pct_chg_close'],
        future3PctChgClose = json['future3_pct_chg_close'],
        future5PctChgClose = json['future5_pct_chg_close'],
        future10PctChgClose = json['future10_pct_chg_close'],
        future13PctChgClose = json['future13_pct_chg_close'],
        future20PctChgClose = json['future20_pct_chg_close'],
        future21PctChgClose = json['future21_pct_chg_close'],
        future30PctChgClose = json['future30_pct_chg_close'],
        future34PctChgClose = json['future34_pct_chg_close'],
        future55PctChgClose = json['future55_pct_chg_close'],
        future60PctChgClose = json['future60_pct_chg_close'],
        future90PctChgClose = json['future90_pct_chg_close'],
        future120PctChgClose = json['future120_pct_chg_close'],
        future144PctChgClose = json['future144_pct_chg_close'],
        future233PctChgClose = json['future233_pct_chg_close'],
        future240PctChgClose = json['future240_pct_chg_close'],
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'pct_main_net_inflow': pctMainNetInflow,
      'pct_small_net_inflow': pctSmallNetInflow,
      'pct_middle_net_inflow': pctMiddleNetInflow,
      'pct_large_net_inflow': pctLargeNetInflow,
      'pct_super_net_inflow': pctSuperNetInflow,
      'chg_close': chgClose,
      'pct_chg_open': pctChgOpen,
      'pct_chg_high': pctChgHigh,
      'pct_chg_low': pctChgLow,
      'pct_chg_close': pctChgClose,
      'pct_chg_amount': pctChgAmount,
      'pct_chg_vol': pctChgVol,
      'ma3_close': ma3Close,
      'ma5_close': ma5Close,
      'ma10_close': ma10Close,
      'ma13_close': ma13Close,
      'ma20_close': ma20Close,
      'ma21_close': ma21Close,
      'ma30_close': ma30Close,
      'ma34_close': ma34Close,
      'ma55_close': ma55Close,
      'ma60_close': ma60Close,
      'ma90_close': ma90Close,
      'ma120_close': ma120Close,
      'ma144_close': ma144Close,
      'ma233_close': ma233Close,
      'ma240_close': ma240Close,
      'max3_close': max3Close,
      'max5_close': max5Close,
      'max10_close': max10Close,
      'max13_close': max13Close,
      'max20_close': max20Close,
      'max21_close': max21Close,
      'max30_close': max30Close,
      'max34_close': max34Close,
      'max55_close': max55Close,
      'max60_close': max60Close,
      'max90_close': max90Close,
      'max120_close': max120Close,
      'max144_close': max144Close,
      'max233_close': max233Close,
      'max240_close': max240Close,
      'min3_close': min3Close,
      'min5_close': min5Close,
      'min10_close': min10Close,
      'min13_close': min13Close,
      'min20_close': min20Close,
      'min21_close': min21Close,
      'min30_close': min30Close,
      'min34_close': min34Close,
      'min55_close': min55Close,
      'min60_close': min60Close,
      'min90_close': min90Close,
      'min120_close': min120Close,
      'min144_close': min144Close,
      'min233_close': min233Close,
      'min240_close': min240Close,
      'before1_ma3_close': before1Ma3Close,
      'before1_ma5_close': before1Ma5Close,
      'before1_ma10_close': before1Ma10Close,
      'before1_ma13_close': before1Ma13Close,
      'before1_ma20_close': before1Ma20Close,
      'before1_ma21_close': before1Ma21Close,
      'before1_ma30_close': before1Ma30Close,
      'before1_ma34_close': before1Ma34Close,
      'before1_ma55_close': before1Ma55Close,
      'before1_ma60_close': before1Ma60Close,
      'before3_ma3_close': before3Ma3Close,
      'before3_ma5_close': before3Ma5Close,
      'before3_ma10_close': before3Ma10Close,
      'before3_ma13_close': before3Ma13Close,
      'before3_ma20_close': before3Ma20Close,
      'before3_ma21_close': before3Ma21Close,
      'before3_ma30_close': before3Ma30Close,
      'before3_ma34_close': before3Ma34Close,
      'before3_ma55_close': before3Ma55Close,
      'before3_ma60_close': before3Ma60Close,
      'before5_ma3_close': before5Ma3Close,
      'before5_ma5_close': before5Ma5Close,
      'before5_ma10_close': before5Ma10Close,
      'before5_ma13_close': before5Ma13Close,
      'before5_ma20_close': before5Ma20Close,
      'before5_ma21_close': before5Ma21Close,
      'before5_ma30_close': before5Ma30Close,
      'before5_ma34_close': before5Ma34Close,
      'before5_ma55_close': before5Ma55Close,
      'before5_ma60_close': before5Ma60Close,
      'acc3_pct_chg_close': acc3PctChgClose,
      'acc5_pct_chg_close': acc5PctChgClose,
      'acc10_pct_chg_close': acc10PctChgClose,
      'acc13_pct_chg_close': acc13PctChgClose,
      'acc20_pct_chg_close': acc20PctChgClose,
      'acc21_pct_chg_close': acc21PctChgClose,
      'acc30_pct_chg_close': acc30PctChgClose,
      'acc34_pct_chg_close': acc34PctChgClose,
      'acc55_pct_chg_close': acc55PctChgClose,
      'acc60_pct_chg_close': acc60PctChgClose,
      'acc90_pct_chg_close': acc90PctChgClose,
      'acc120_pct_chg_close': acc120PctChgClose,
      'acc144_pct_chg_close': acc144PctChgClose,
      'acc233_pct_chg_close': acc233PctChgClose,
      'acc240_pct_chg_close': acc240PctChgClose,
      'future1_pct_chg_close': future1PctChgClose,
      'future3_pct_chg_close': future3PctChgClose,
      'future5_pct_chg_close': future5PctChgClose,
      'future10_pct_chg_close': future10PctChgClose,
      'future13_pct_chg_close': future13PctChgClose,
      'future20_pct_chg_close': future20PctChgClose,
      'future21_pct_chg_close': future21PctChgClose,
      'future30_pct_chg_close': future30PctChgClose,
      'future34_pct_chg_close': future34PctChgClose,
      'future55_pct_chg_close': future55PctChgClose,
      'future60_pct_chg_close': future60PctChgClose,
      'future90_pct_chg_close': future90PctChgClose,
      'future120_pct_chg_close': future120PctChgClose,
      'future144_pct_chg_close': future144PctChgClose,
      'future233_pct_chg_close': future233PctChgClose,
      'future240_pct_chg_close': future240PctChgClose,
    });
    return json;
  }
}
