import 'package:colla_chat/entity/base.dart';

class WmqyLine extends BaseEntity {
  String tsCode;
  int? tradeDate;
  String? name;
  String? qDate;
  num? shareNumber;
  num? open;
  num? high;
  num? low;
  num? close;
  num? vol;
  num? amount;
  num? turnover;
  num? preClose;
  num? chgClose;
  num? pctChgOpen;
  num? pctChgHigh;
  num? pctChgLow;
  num? pctChgClose;
  num? pctChgAmount;
  num? pctChgVol;
  int? lineType;

  WmqyLine.fromJson(super.json)
      : tsCode = json['ts_code'],
        name = json['name'],
        tradeDate = json['trade_date'],
        qDate = json['qdate'],
        shareNumber = json['share_number'],
        open = json['open'],
        high = json['high'],
        low = json['low'],
        close = json['close'],
        vol = json['vol'],
        amount = json['amount'],
        turnover = json['turnover'],
        preClose = json['pre_close'],
        chgClose = json['chg_close'],
        pctChgOpen = json['pct_chg_open'],
        pctChgHigh = json['pct_chg_high'],
        pctChgLow = json['pct_chg_low'],
        pctChgClose = json['pct_chg_close'],
        pctChgAmount = json['pct_chg_amount'],
        pctChgVol = json['pct_chg_vol'],
        lineType = json['line_type'],
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'ts_code': tsCode,
      'name': name,
      'trade_date': tradeDate,
      'qdate': qDate,
      'share_number': shareNumber,
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'vol': vol,
      'amount': amount,
      'turnover': turnover,
      'pre_close': preClose,
      'chg_close': chgClose,
      'pct_chg_open': pctChgOpen,
      'pct_chg_high': pctChgHigh,
      'pct_chg_low': pctChgLow,
      'pct_chg_close': pctChgClose,
      'pct_chg_amount': pctChgAmount,
      'pct_chg_vol': pctChgVol,
      'line_type': lineType,
    });
    return json;
  }
}
