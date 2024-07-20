import 'package:colla_chat/entity/stock/day_line.dart';
import 'package:colla_chat/entity/stock/share.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/service/stock/share.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/transport/httpclient.dart';
import 'package:dio/dio.dart';

class DayLineRequestParam {
  String cb;
  String? secId; //股票代码
  String ut; //token
  String? fields1; //
  String? fields2; //
  int?
      klt; //每隔时长获取一次记录，1代表一分，5代表5分钟，101代表每天，102代表每周，103代表每月，104代表每季度，105代表每半年，106代表每年
  int fqt = 1; //
  String? smplmt; //
  int? lmt; //获取记录数
  int? beg; //开始日期
  int? end; //终止日期 20500101
  String? underscore; //
  String? fields; //
  int? fltt; //
  int? invt; //

  DayLineRequestParam(this.cb, this.ut);

  Map<String, dynamic> toJson() {
    return {
      'cb': cb,
      'secId': secId,
      'ut': ut,
      'fields1': fields1,
      'fields2': fields2,
      'klt': klt,
      'fqt': fqt,
      'smplmt': smplmt,
      'lmt': lmt,
      'beg': beg,
      'end': end,
      'underscore': underscore,
      'fields': fields,
      'fltt': fltt,
      'invt': invt
    };
  }
}

class DayLineResponseData {
  String? code;
  int? market;
  String? name;
  int? decimal; //小数位
  int? dktotal; //总记录数
  double? preKPrice;
  List<String>? klines; //数据

  DayLineResponseData.fromJson(Map json) {
    code = json['code'];
    market = json['market'];
    name = json['name'];
    decimal = json['decimal'];
    dktotal = json['dktotal'];
    preKPrice = json['preKPrice'];
    List<dynamic>? klines =
        json['klines'] != null ? JsonUtil.toJson(json['klines']) : null;
    if (klines != null) {
      this.klines = [];
      for (var kline in klines) {
        this.klines!.add(kline.toString());
      }
    }
  }
}

class CurrentResponseData {
  double? f43; //close
  double? f44; //high
  double? f45; //low
  double? f46; //open
  int? f47; //vol
  double? f48; //amount
  double? f50; //qrr
  String? f57; //ts_code
  String? f58; //name
  int? f59; //
  double? f60; //preclose
  int? f107; //
  int? f152;
  double? f162; //pe
  double? f168; //turnover
  double? f169; //pct_chg
  double? f170; //close_chg
  double? f171; //
  int? f292;
}

class DayLineResponseResult {
  int? rc;
  int? rt;
  int? svr;
  int? lt;
  int? full;
  DayLineResponseData? data;

  DayLineResponseResult.fromJson(Map json)
      : rc = json['rc'],
        rt = json['rt'],
        svr = json['svr'],
        lt = json['lt'],
        full = json['full'],
        data = json['data'] != null
            ? DayLineResponseData.fromJson(json['data'])
            : null;
}

class CrawlerUtil {
  static DioHttpClient client =
      httpClientPool.get('http://push2his.eastmoney.com');
  static String dayLineUrl = '/api/qt/stock/kline/get';
  static String dayLineCallback = "jQuery112401201342267983887_1638513559390";
  static String dayLineToken = "fa5fd1943c7b386f172d6893dbfba10b";
  static String dayLineType = "1638513559443";

  static String toHttpArgs(dynamic o) {
    Map<dynamic, dynamic> map = JsonUtil.toJson(o);
    int i = 0;
    String args = '';
    for (var entry in map.entries) {
      String key = entry.key.toString();
      dynamic value = entry.value;
      if (value != null) {
        if (i == 0) {
          args = '$args?$key=$value';
        } else {
          args = '$args&$key=$value';
        }
      }
      i++;
    }
    return args;
  }

  static Future<String?> httpGet(String url, dynamic param) async {
    String args = toHttpArgs(param);
    Response<dynamic> response = await client.get('$url$args');
    if (response.statusCode == 200) {
      return response.data;
    } else {
      logger.e('DioHttpClient send err:${response.statusCode}');
    }

    return null;
  }

  static Future<String?> httpGetDayLine(
      DayLineRequestParam requestParam) async {
    String? resp = await httpGet(dayLineUrl, requestParam);
    if (resp != null) {
      resp = resp.substring(requestParam.cb.length + 1, resp.length - 2);
    }

    return resp;
  }

  static Future<String> getSecId(String secId) async {
    Share? share = await shareService.findShare(secId);
    if (share != null) {
      if (share.symbol!.endsWith(".SH")) {
        return "1.$secId";
      }
    }

    return "0.$secId";
  }

  static Future<DayLineResponseData?> getKLine(String secId,
      {int beg = 19900101,
      int end = 20500101,
      int limit = 10000,
      int klt = 101}) async {
    DayLineRequestParam dayLineRequestParam =
        DayLineRequestParam(dayLineCallback, dayLineToken);
    dayLineRequestParam.secId = await getSecId(secId);
    dayLineRequestParam.fields1 = "f1%2Cf2%2Cf3%2Cf4%2Cf5%2Cf6";
    dayLineRequestParam.fields2 =
        "f51%2Cf52%2Cf53%2Cf54%2Cf55%2Cf56%2Cf57%2Cf58%2Cf59%2Cf60%2Cf61";
    dayLineRequestParam.klt = klt;
    dayLineRequestParam.beg = beg;
    if (end <= 0) {
      dayLineRequestParam.end = 20500101;
    } else {
      dayLineRequestParam.end = end;
    }
    if (limit <= 0) {
      dayLineRequestParam.lmt = 10000;
    } else {
      dayLineRequestParam.lmt = limit;
    }
    dayLineRequestParam.underscore = "1638513559443";
    String? resp = await httpGetDayLine(dayLineRequestParam);
    DayLineResponseResult dayLineResponseResult =
        DayLineResponseResult.fromJson(JsonUtil.toJson(resp));

    return dayLineResponseResult.data;
  }

  static DayLine strToDayLine(String secId, String kline) {
    List<String> kls = kline.split(',');
    int tradeDate = int.parse(kls[0].replaceAll("-", ""));
    DayLine dayLine = DayLine(secId, tradeDate);
    //"trade_date,open,close,high,low,vol,amount,nil,pct_chg%,change,turnover%"
    dayLine.open = double.parse(kls[1]);
    dayLine.close = double.parse(kls[2]);
    dayLine.high = double.parse(kls[3]);
    dayLine.low = double.parse(kls[4]);
    dayLine.vol = double.parse(kls[5]);
    dayLine.amount = double.parse(kls[6]);
    dayLine.pctChgClose = double.parse(kls[8]);
    dayLine.chgClose = double.parse(kls[9]);
    dayLine.turnover = double.parse(kls[10]);

    return dayLine;
  }

  static Future<Map<String, dynamic>?> getDayLine(String secId,
      {int beg = 19900101,
      int end = 20500101,
      int limit = 10000,
      DayLine? previous}) async {
    DayLineResponseData? data =
        await getKLine(secId, beg: beg, end: end, limit: limit, klt: 101);
    if (data == null) {
      return null;
    }
    List<String>? klines = data.klines;
    if (klines == null) {
      return null;
    }
    List<DayLine> dayLines = [];
    for (var kline in klines) {
      DayLine dayLine = strToDayLine(secId, kline);

      if (previous != null && previous.open != 0.0) {
        dayLine.pctChgOpen = dayLine.open! / previous.open! - 1;
      }
      if (previous != null && previous.high != 0.0) {
        dayLine.pctChgHigh = dayLine.high! / previous.high! - 1;
      }
      if (previous != null && previous.low != 0.0) {
        dayLine.pctChgLow = dayLine.low! / previous.low! - 1;
      }
      if (previous != null && previous.close != 0.0) {
        dayLine.pctChgClose = dayLine.close! / previous.close! - 1;
      }
      if (previous != null && previous.amount != 0.0) {
        dayLine.pctChgAmount = dayLine.amount! / previous.amount! - 1;
      }
      if (previous != null && previous.vol != 0.0) {
        dayLine.pctChgVol = dayLine.vol! / previous.vol! - 1;
      }
      if (previous != null) {
        dayLine.preClose = previous.close;
      }
      previous = dayLine;
      dayLines.add(dayLine);
    }

    return {'count': data.dktotal, 'data': dayLines};
  }
}
