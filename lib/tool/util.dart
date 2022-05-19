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
