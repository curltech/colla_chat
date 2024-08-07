import 'package:colla_chat/entity/stock/day_line.dart';

class MinLine extends StockLine {
  int? tradeMinute;

  MinLine(super.tsCode, super.tradeDate);

  MinLine.fromJson(super.json)
      : tradeMinute = json['trade_minute'],
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'trade_minute': tradeMinute,
    });
    return json;
  }
}
