import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:colla_chat/platform.dart';
import 'package:connectivity/connectivity.dart';
import 'package:mobile_number/mobile_number.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart'
    as phone_numbers_parser;
import 'package:package_info/package_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phone_number/phone_number.dart' as phone_number;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

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

  static int firstIntValue(List<Map<String, Object?>> list) {
    if (list.isNotEmpty) {
      final firstRow = list.first;
      if (firstRow.isNotEmpty) {
        Object? o = firstRow.values.first;
        if (o != null) {
          int? v = parseInt(o);
          if (v != null) {
            return v;
          }
        }
      }
    }
    return 0;
  }
}

class StringUtil {
  // 是否是空字符串
  static bool isEmptyString(String str) {
    if (str == null || str.isEmpty) {
      return true;
    }
    return false;
  }

  // 是否不是空字符串
  static bool isNotEmptyString(String str) {
    if (str != null && str.isNotEmpty) {
      return true;
    }
    return false;
  }

  /// 匹配
  static bool matches(String regex, String input) {
    if (input == null || input.isEmpty) return false;
    return new RegExp(regex).hasMatch(input);
  }

  /// 纯数字 ^[0-9]*$
  static bool pureDigitCharacters(String input) {
    final String regex = "^[0-9]*\$";
    return matches(regex, input);
  }
}

/**
 * 只支持android，获取手机号码
 */
class MobileUtil {
  static Future<String?> getMobileNumber() async {
    String? mobileNumber = "";
    try {
      var hasPhonePermission = await MobileNumber.hasPhonePermission;
      if (!hasPhonePermission) {
        await MobileNumber.requestPhonePermission;
      }
      mobileNumber = await MobileNumber.mobileNumber;
    } on Exception catch (e) {
      print("Failed to get mobile number because of '${e.toString()}'");
    }

    return mobileNumber;
  }
}

class PhoneNumberUtil {
  static Future<phone_number.PhoneNumber> parse(String phoneNumberStr,
      {String? regionCode}) async {
    //phone_number.RegionInfo region = phone_number.RegionInfo(name:'US',code:'en',prefix: 1);
    phone_number.PhoneNumber phoneNumber = await phone_number.PhoneNumberUtil()
        .parse(phoneNumberStr, regionCode: regionCode);

    return phoneNumber;
  }

  static Future<bool> validate(String phoneNumberStr, String regionCode) async {
    bool isValidate = await phone_number.PhoneNumberUtil()
        .validate(phoneNumberStr, regionCode);

    return isValidate;
  }

  static Future<String> format(String phoneNumberStr, String regionCode) async {
    String formatted =
        await phone_number.PhoneNumberUtil().format(phoneNumberStr, regionCode);

    return formatted;
  }

  static Future<List<phone_number.RegionInfo>> allSupportedRegions(
      {String? locale}) async {
    List<phone_number.RegionInfo> regions = await phone_number.PhoneNumberUtil()
        .allSupportedRegions(locale: locale);

    return regions;
  }

  static Future<String> carrierRegionCode() async {
    String code = await phone_number.PhoneNumberUtil().carrierRegionCode();

    return code;
  }

  // 格式化手机号为344
  static String formatMobile344(String mobile) {
    if (StringUtil.isEmptyString(mobile)) return '';
    mobile =
        mobile.replaceAllMapped(new RegExp(r"(^\d{3}|\d{4}\B)"), (Match match) {
      return '${match.group(0)} ';
    });
    if (mobile.endsWith(' ')) {
      mobile = mobile.substring(0, mobile.length - 1);
    }
    return mobile;
  }

  // 电话格式化
  static String formatPhone(String zoneCode, String mobile) {
    return "+$zoneCode ${formatMobile344(mobile)}";
  }

  static phone_numbers_parser.PhoneNumber fromNational(
      phone_numbers_parser.IsoCode isoCode, String phoneNumber) {
    return phone_numbers_parser.PhoneNumber.fromNational(isoCode, phoneNumber);
  }

  static phone_numbers_parser.PhoneNumber fromIsoCode(
      phone_numbers_parser.IsoCode isoCode, String phoneNumber) {
    return phone_numbers_parser.PhoneNumber.fromNational(isoCode, phoneNumber);
  }

  static phone_numbers_parser.PhoneNumber fromRaw(String phoneNumber) {
    return phone_numbers_parser.PhoneNumber.fromRaw(phoneNumber);
  }

  static phone_numbers_parser.PhoneNumber fromCountryCode(
      String countryCode, String phoneNumber) {
    return phone_numbers_parser.PhoneNumber.fromCountryCode(
        countryCode, phoneNumber);
  }

  static isValid(phone_numbers_parser.PhoneNumber phoneNumber,
      phone_numbers_parser.PhoneNumberType type) {
    return phoneNumber.validate(type: type);
  }

  static formatNsn(phone_numbers_parser.PhoneNumber phoneNumber) {
    return phoneNumber.getFormattedNsn();
  }
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

  static removeNull(Map map) {
    for (var key in map.keys) {
      var value = map[key];
      if (value == null) {
        map.remove(key);
      }
    }
  }
}

class NetworkInfoUtil {
  static NetworkInfo getWifiInfo() {
    // var wifiName = await info.getWifiName(); // FooNetwork
    // var wifiBSSID = await info.getWifiBSSID(); // 11:22:33:44:55:66
    // var wifiIP = await info.getWifiIP(); // 192.168.1.43
    // var wifiIPv6 = await info.getWifiIPv6(); // 2001:0db8:85a3:0000:0000:8a2e:0370:7334
    // var wifiSubmask = await info.getWifiSubmask(); // 255.255.255.0
    // var wifiBroadcast = await info.getWifiBroadcast(); // 192.168.1.255
    // var wifiGateway = await info.getWifiGatewayIP(); // 192.168.1.1

    final info = NetworkInfo();

    return info;
  }

  static Future<String?> getWifiIp() async {
    var platformParams = await PlatformParams.instance;
    if (!platformParams.web) {
      var info = getWifiInfo();
      var wifiIp = await info.getWifiIP(); // 192.168.1.43

      return wifiIp;
    }
    return null;
  }
}

class NetworkConnectivity {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  ConnectivityResult connectivityResult = ConnectivityResult.none;

  ///当前的网络连接状态，null:未连接;mobile:wifi:
  Future<String?> connective() async {
    ConnectivityResult connectivityResult =
        await _connectivity.checkConnectivity();

    if (connectivityResult == ConnectivityResult.mobile) {
      return 'mobile';
    } else if (connectivityResult == ConnectivityResult.wifi) {
      return 'wifi';
    }

    return null;
  }

  /// 注册连接状态监听器
  register([Function(ConnectivityResult result)? fn]) {
    if (fn == null) {
      _connectivitySubscription =
          _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    } else {
      _connectivitySubscription =
          _connectivity.onConnectivityChanged.listen(fn);
    }
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    connectivityResult = result;
  }
}

final networkConnectivity = NetworkConnectivity();

class DeviceInfo {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  Future<AndroidDeviceInfo> getAndroidInfo() async {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return androidInfo;
  }

  Future<IosDeviceInfo> getIosDeviceInfo() async {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    return iosInfo;
  }

  Future<WebBrowserInfo> getWebBrowserInfo() async {
    WebBrowserInfo webBrowserInfo = await deviceInfo.webBrowserInfo;
    return webBrowserInfo;
  }

  Future<LinuxDeviceInfo> getLinuxDeviceInfo() async {
    LinuxDeviceInfo linuxDeviceInfo = await deviceInfo.linuxInfo;
    return linuxDeviceInfo;
  }

  Future<MacOsDeviceInfo> getMacOsDeviceInfo() async {
    MacOsDeviceInfo macOsDeviceInfo = await deviceInfo.macOsInfo;
    return macOsDeviceInfo;
  }

  Future<WindowsDeviceInfo> getWindowsDeviceInfo() async {
    WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
    return windowsInfo;
  }
}

final deviceInfo = DeviceInfo();

class PackageInfoUtil {
  Future<PackageInfo> getPackageInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    // String appName = packageInfo.appName;
    // String packageName = packageInfo.packageName;
    // String version = packageInfo.version;
    // String buildNumber = packageInfo.buildNumber;

    return packageInfo;
  }
}

class ShareUtil {
  static Future<ShareResult> share(String text,
      {String? subject, Rect? sharePositionOrigin}) async {
    return await Share.shareWithResult(text,
        subject: subject, sharePositionOrigin: sharePositionOrigin);
  }

  static Future<ShareResult> shareFiles(
    List<String> paths, {
    List<String>? mimeTypes,
    String? subject,
    String? text,
    Rect? sharePositionOrigin,
  }) async {
    return await Share.shareFilesWithResult(paths,
        mimeTypes: mimeTypes,
        subject: subject,
        text: text,
        sharePositionOrigin: sharePositionOrigin);
  }
}

class SensorsUtil {
  static registerAccelerometerEvent([Function(AccelerometerEvent event)? fn]) {
    // [AccelerometerEvent (x: 0.0, y: 9.8, z: 0.0)]
    accelerometerEvents.listen(fn);
  }

  static registerUserAccelerometerEvent(
      [Function(UserAccelerometerEvent event)? fn]) {
    // [UserAccelerometerEvent (x: 0.0, y: 0.0, z: 0.0)]
    userAccelerometerEvents.listen(fn);
  }

  static registerGyroscopeEvent([Function(GyroscopeEvent event)? fn]) {
    // [GyroscopeEvent (x: 0.0, y: 0.0, z: 0.0)]
    gyroscopeEvents.listen(fn);
  }
}

class PathUtil {
  /// 获取文档目录文件
  static Future<Directory> getLocalDocumentFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir;
  }

  /// 获取临时目录文件
  static Future<Directory> getLocalTemporaryFile() async {
    final dir = await getTemporaryDirectory();
    return dir;
  }

  /// 获取应用程序目录文件
  static Future<Directory> getLocalSupportFile() async {
    final dir = await getApplicationSupportDirectory();
    return dir;
  }

  static Future<Directory> getLibraryDirectory() async {
    final dir = await getLibraryDirectory();
    return dir;
  }

  static Future<Directory> getExternalStorageDirectory() async {
    final dir = await getLibraryDirectory();
    return dir;
  }

  static Future<Directory> getDownloadsDirectory() async {
    final dir = await getDownloadsDirectory();
    return dir;
  }
}

class ContactUtil {
  static Future<bool> requestPermission() async {
    return await FlutterContacts.requestPermission();
  }

  static Future<List<Contact>> getContacts(
      {bool withProperties = true, bool withPhoto = true}) async {
    return await FlutterContacts.getContacts(
        withProperties: withProperties, withPhoto: withPhoto);
  }

  static Future<Contact?> getContact(
    String id, {
    bool withProperties = true,
    bool withThumbnail = true,
    bool withPhoto = true,
    bool withGroups = false,
    bool withAccounts = false,
    bool deduplicateProperties = true,
  }) async {
    return await FlutterContacts.getContact(
      id,
      withProperties: withProperties,
      withThumbnail: withThumbnail,
      withPhoto: withPhoto,
      withGroups: withGroups,
      withAccounts: withAccounts,
      deduplicateProperties: deduplicateProperties,
    );
  }

  static Future<void>? openExternalView(String id) async {
    return await FlutterContacts.openExternalView(id);
  }

  static Future<Contact?> openExternalEdit(String id) async {
    return await FlutterContacts.openExternalEdit(id);
  }

  static Future<Contact?> openExternalPick() async {
    final contact = await FlutterContacts.openExternalPick();
    return contact;
  }

  static Future<Contact?> openExternalInsert() async {
    final contact = await FlutterContacts.openExternalInsert();
    return contact;
  }

  static addListener(void Function() fn) {
    // Listen to contact database changes
    FlutterContacts.addListener(fn);
  }

// Insert new contact
// final newContact = Contact()
//   ..name.first = 'John'
//   ..name.last = 'Smith'
//   ..phones = [Phone('555-123-4567')];
// await newContact.insert();
//
// // Update contact
// contact.name.first = 'Bob';
// await contact.update();
//
// // Delete contact
// await contact.delete();
}
