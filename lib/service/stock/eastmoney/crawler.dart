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
  int? fqt; //
  String? smplmt; //
  int? lmt; //获取记录数
  int? beg; //开始日期
  int? end; //终止日期 20500101
  String? underscore; //
  String? fields; //
  int? fltt; //
  int? invt; //

  DayLineRequestParam(this.cb, this.ut);
}

class DayLineResponseData {
  String? code;
  String? market;
  String? name;
  int? decimal; //小数位
  int? dktotal; //总记录数
  double? preKPrice;
  List<String>? klines; //数据

  DayLineResponseData.fromJson(Map json)
      : code = json['code'],
        market = json['market'],
        name = json['name'],
        decimal = json['decimal'],
        dktotal = json['dktotal'],
        preKPrice = json['preKPrice'],
        klines = JsonUtil.toJson(json['klines']);
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
        data = DayLineResponseData.fromJson(json['data']);
}

class CrawlerUtil {
  static DioHttpClient client =
      httpClientPool.get('http://push2his.eastmoney.com');
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
    Response<dynamic> response = await client.get('url$args');
    if (response.statusCode == 200) {
      return response.data;
    } else {
      logger.e('DioHttpClient send err:${response.statusCode}');
    }

    return null;
  }

  static Future<String?> httpGetDayLine(
      DayLineRequestParam requestParam) async {
    String? resp = await httpGet('api/qt/stock/kline/get', requestParam);
    if (resp != null) {
      resp.substring(requestParam.cb.length, resp.length - 2);
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

  static Future<List<String>?> getKLine(
      String secId, int beg, int end, int limit, int klt) async {
    DayLineRequestParam dayLineRequestParam =
        DayLineRequestParam(dayLineCallback, dayLineToken);
    dayLineRequestParam.secId = await getSecId(secId);
    dayLineRequestParam.fields1 = "f1,f2,f3,f4,f5,f6";
    dayLineRequestParam.fields2 = "f51,f52,f53,f54,f55,f56,f57,f58,f59,f60,f61";
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

    return dayLineResponseResult.data?.klines;
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

  static Future<List<DayLine>?> getDayLine(
      String secId, int beg, int end, int limit,
      {DayLine? previous}) async {
    List<String>? klines = await getKLine(secId, beg, end, limit, 101);
    List<DayLine> dayLines = [];
    for (var kline in klines!) {
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

    return dayLines;
  }
}
