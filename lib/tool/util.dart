import 'dart:convert';

class TypeUtil {
  static bool isString(dynamic obj) {
    return (obj is String);
  }

  static bool isArray(dynamic obj) {
    return (obj is List);
  }

  static bool isNumber(dynamic obj) {
    return (obj is int || obj is double);
  }

  static bool isDate(dynamic obj) {
    return (obj is DateTime);
  }

  static bool isFunction(dynamic obj) {
    return (obj is Function);
  }

  static int? parseInt(Object? object) {
    if (object is int) {
      return object;
    } else if (object is String) {
      try {
        return int.parse(object);
      } catch (_) {}
    }
    return null;
  }

  static int? firstIntValue(List<Map<String, Object?>> list) {
    if (list.isNotEmpty) {
      final firstRow = list.first;
      if (firstRow.isNotEmpty) {
        return parseInt(firstRow.values.first);
      }
    }
    return null;
  }
}

class MobileUtil {
  // static Future<String?> getMobileNumber() async {
  //   String? mobileNumber = "";
  //   try {
  //     var hasPhonePermission = await MobileNumber.hasPhonePermission;
  //     if (!hasPhonePermission) {
  //       await MobileNumber.requestPhonePermission;
  //     }
  //     mobileNumber = await MobileNumber.mobileNumber;
  //   } on Exception catch (e) {
  //     print("Failed to get mobile number because of '${e.toString()}'");
  //   }
  //
  //   return mobileNumber;
  // }
}

class VersionUtil {}

/// 实体有toJason和fromJson两个方法
class JsonUtil {
  /// 把map，json字符串和一般的实体转换成map，map转换成一般实体使用实体的fromJson构造函数
  static Map toMap(dynamic entity) {
    if (entity is Map) {
      return entity;
    } else if (entity is String) {
      Map map = jsonDecode(entity);
      return map;
    }
    return entity.toJson();
  }

  /// 把map和一般的实体转换成json字符串
  static String toJsonString(dynamic entity) {
    return jsonEncode(entity);
  }
}

class EntityUtil {
  static Object? getId(dynamic entity) {
    if (entity is Map) {
      return entity['id'];
    } else {
      return entity.id;
    }
  }

  static setId(dynamic entity, Object val) {
    if (entity is Map) {
      entity['id'] = val;
    } else {
      entity.id = val;
    }
  }

  static createTimestamp(dynamic entity) {
    var currentDate = DateTime.now().toIso8601String();
    if (entity is Map) {
      entity['createDate'] = currentDate;
      entity['updateDate'] = currentDate;
    } else {
      entity.createDate = currentDate;
      entity.updateDate = currentDate;
    }
  }

  static updateTimestamp(dynamic entity) {
    var currentDate = DateTime.now().toIso8601String();
    if (entity is Map) {
      entity['updateDate'] = currentDate;
    } else {
      entity.updateDate = currentDate;
    }
  }

  static removeNullId(Map map) {
    var id = getId(map);
    if (id == null) {
      map.remove('id');
    }
  }
}
