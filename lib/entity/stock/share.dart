import 'package:colla_chat/entity/base.dart';

class Share extends StatusEntity {
  String? tsCode; //TS代码
  String? symbol; // str 股票代码
  String? name; // str 股票名称
  String? area; // str 所在地域
  String? industry; // str 所属行业
  String? sector; // str 所属细分行业行业
  String? fullName; // str 股票全称
  String? englishName; // str 英文全称
  String? market; // str 市场类型 (主板/中小板/创业板/科创板/CDR)
  String? exchange; // str 交易所代码
  String? currType; // str 交易货币
  String? listStatus; // str 上市状态: L上市 D退市 P暂停上市
  String? listDate; // str 上市日期
  String? delistDate; // str 退市日期
  String? isHs; // str 是否沪深港通标的,N否 H沪股通 S深股通
  String? pinyin;

  Share();

  /// 从服务器端获取的map转换成share对象
  Share.fromRemoteJson(Map json)
      : tsCode = json['ts_code'],
        symbol = json['symbol'],
        name = json['name'],
        area = json['area'],
        industry = json['industry'],
        sector = json['sector'],
        fullName = json['fullname'],
        englishName = json['enname'],
        market = json['market'],
        exchange = json['exchange'],
        currType = json['curr_type'],
        listStatus = json['list_status'],
        listDate = json['list_date'],
        delistDate = json['delist_date'],
        isHs = json['is_hs'],
        pinyin = json['pin_yin'],
        super.fromJson(json);

  Share.fromJson(Map json)
      : tsCode = json['tsCode'],
        symbol = json['symbol'],
        name = json['name'],
        area = json['area'],
        industry = json['industry'],
        sector = json['sector'],
        fullName = json['fullName'],
        englishName = json['englishName'],
        market = json['market'],
        exchange = json['exchange'],
        currType = json['currType'],
        listStatus = json['listStatus'],
        listDate = json['listDate'],
        delistDate = json['delistDate'],
        isHs = json['isHs'],
        pinyin = json['pinyin'],
        super.fromJson(json);

  Map<String, dynamic> toRemoteJson() {
    var json = super.toJson();
    json.addAll({
      'ts_code': tsCode,
      'symbol': symbol,
      'name': name,
      'area': area,
      'industry': industry,
      'sector': sector,
      'fullname': fullName,
      'enname': englishName,
      'market': market,
      'exchange': exchange,
      'curr_type': currType,
      'list_status': listStatus,
      'list_dDate': listDate,
      'delist_date': delistDate,
      'is_hs': isHs,
      'pin_yin': pinyin,
    });
    return json;
  }

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'tsCode': tsCode,
      'symbol': symbol,
      'name': name,
      'area': area,
      'industry': industry,
      'sector': sector,
      'fullName': fullName,
      'englishName': englishName,
      'market': market,
      'exchange': exchange,
      'currType': currType,
      'listStatus': listStatus,
      'listDate': listDate,
      'delistDate': delistDate,
      'isHs': isHs,
      'pinyin': pinyin,
    });
    return json;
  }
}
