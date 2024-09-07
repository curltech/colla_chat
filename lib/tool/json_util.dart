import 'dart:convert';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/tool/entity_util.dart';

/// 实体有toJason和fromJson两个方法
class JsonUtil {
  /// 把map，json字符串和一般的实体转换成map或者list，map转换成一般实体使用实体的fromJson构造函数
  static dynamic toJson(dynamic entity) {
    if (entity == null) {
      return null;
    }
    if (entity is List<int>) {
      dynamic json = jsonDecode(CryptoUtil.utf8ToString(entity));
      return json;
    } else if (entity is List) {
      return entity;
    } else if (entity is Map) {
      return entity;
    } else if (entity is String) {
      dynamic json = jsonDecode(entity);
      return json;
    }
    else if (entity is String) {
      dynamic json = jsonDecode(entity);
      return json;
    }
    return entity.toJson();
  }

  /// 把map和一般的实体转换成json字符串
  static String toJsonString(dynamic entity) {
    if (entity is List) {
      return jsonEncode(entity);
    }
    Map map = toJson(entity);
    EntityUtil.removeNull(map);

    return jsonEncode(map);
  }

  ///把任意对象转换成List<int>,字符串假设为base64字符串
  ///其他的对象先转换成json字符串，然后变成utf8字节数组
  static List<int> toUintList(dynamic entity) {
    if (entity is List<int>) {
      return entity;
    } else if (entity is String) {
      return CryptoUtil.decodeBase64(entity);
    }
    String json = toJsonString(entity);
    return CryptoUtil.stringToUtf8(json);
  }

  /// 把map，json字符串和一般的实体转换成map或者list，map转换成一般实体使用实体的fromJson构造函数
  static dynamic toRemoteJson(dynamic entity) {
    if (entity == null) {
      return null;
    }
    if (entity is List<int>) {
      dynamic json = jsonDecode(CryptoUtil.utf8ToString(entity));
      return json;
    } else if (entity is List) {
      return entity;
    } else if (entity is Map) {
      return entity;
    } else if (entity is String) {
      dynamic json = jsonDecode(entity);
      return json;
    }
    return entity.toRemoteJson();
  }

  /// 把map和一般的实体转换成json字符串
  static String toRemoteJsonString(dynamic entity) {
    if (entity is List) {
      return jsonEncode(entity);
    }
    Map map = toRemoteJson(entity);
    EntityUtil.removeNull(map);

    return jsonEncode(map);
  }

  ///把任意对象转换成List<int>,字符串假设为base64字符串
  ///其他的对象先转换成json字符串，然后变成utf8字节数组
  static List<int> toRemoteUintList(dynamic entity) {
    if (entity is List<int>) {
      return entity;
    } else if (entity is String) {
      return CryptoUtil.decodeBase64(entity);
    }
    String json = toRemoteJsonString(entity);
    return CryptoUtil.stringToUtf8(json);
  }
}
