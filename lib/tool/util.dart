import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:colla_chat/platform.dart';
import 'package:connectivity/connectivity.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:mobile_number/mobile_number.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:package_info/package_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phone_number/phone_number.dart' as phone_number;
import 'package:phone_numbers_parser/phone_numbers_parser.dart'
    as phone_numbers_parser;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:telephony/telephony.dart';
import 'package:toast/toast.dart';

import '../provider/app_data.dart';

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
  static bool isEmpty(String? str) {
    if (str == null || str.isEmpty) {
      return true;
    }
    return false;
  }

  // 是否不是空字符串
  static bool isNotEmpty(String? str) {
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

/// 只支持android，获取手机号码
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
      logger.e("Failed to get mobile number because of '${e.toString()}'");
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
    if (StringUtil.isEmpty(mobile)) return '';
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
    } else if (entity is List<int>) {
      Map map = jsonDecode(String.fromCharCodes(entity));
      return map;
    }
    return entity.toJson();
  }

  /// 把map和一般的实体转换成json字符串
  static String toJsonString(dynamic entity) {
    Map map = toMap(entity);
    EntityUtil.removeNull(map);
    return jsonEncode(map);
  }
}

class DateUtil {
  static String currentDate() {
    var currentDate = DateTime.now().toUtc().toIso8601String();
    return currentDate;
  }

  static const String full = "yyyy-MM-dd HH:mm:ss";

  static String formatDateV(DateTime dateTime,
      {bool isUtc = true, String format = full}) {
    if (dateTime == null) return "";
    format = format ?? full;
    if (format.contains("yy")) {
      String year = dateTime.year.toString();
      if (format.contains("yyyy")) {
        format = format.replaceAll("yyyy", year);
      } else {
        format = format.replaceAll(
            "yy", year.substring(year.length - 2, year.length));
      }
    }

    format = _comFormat(dateTime.month, format, 'M', 'MM');
    format = _comFormat(dateTime.day, format, 'd', 'dd');
    format = _comFormat(dateTime.hour, format, 'H', 'HH');
    format = _comFormat(dateTime.minute, format, 'm', 'mm');
    format = _comFormat(dateTime.second, format, 's', 'ss');
    format = _comFormat(dateTime.millisecond, format, 'S', 'SSS');

    return format;
  }

  static String _comFormat(
      int value, String format, String single, String full) {
    if (format.contains(single)) {
      if (format.contains(full)) {
        format =
            format.replaceAll(full, value < 10 ? '0$value' : value.toString());
      } else {
        format = format.replaceAll(single, value.toString());
      }
    }
    return format;
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
    var currentDate = DateUtil.currentDate();
    if (entity is Map) {
      entity['createDate'] = currentDate;
      entity['updateDate'] = currentDate;
    } else {
      entity.createDate = currentDate;
      entity.updateDate = currentDate;
    }
  }

  static updateTimestamp(dynamic entity) {
    var currentDate = DateUtil.currentDate();
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
    map.removeWhere((key, value) => value == null);
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

class DialogUtil {
  /// loading框
  static loadingShow(BuildContext context, {String tip = '正在加载，请稍后...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircularProgressIndicator(),
              Padding(
                padding: EdgeInsets.only(top: 26.0),
                child: Text(tip),
              )
            ],
          ),
        );
      },
    );
  }

  /// 关闭loading框
  static loadingHide(BuildContext context) {
    Navigator.of(context).pop(true);
  }

  ///返回为true，代表按的确认
  /// 模态警告
  static Future<bool?> alert(BuildContext context,
      {Icon? icon, String title = '警告', String content = ''}) {
    Icon i;
    if (icon == null) {
      i = const Icon(Icons.warning);
    } else {
      i = icon;
    }
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Row(children: <Widget>[
            i,
            Text(title),
          ]),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
  }

  /// 模态提示
  static Future<bool?> prompt(BuildContext context,
      {Icon? icon, String title = '提示', String content = ''}) {
    return alert(context,
        title: title, content: content, icon: const Icon(Icons.info));
  }

  /// 模态提示错误
  static Future<bool?> fault(BuildContext context,
      {Icon? icon, String title = '错误', String content = ''}) {
    return alert(context,
        title: title, content: content, icon: const Icon(Icons.error));
  }

  /// 底部延时提示错误
  static error(BuildContext context, {String content = '错误'}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(content),
      backgroundColor: Colors.red,
    ));
  }

  /// 底部延时警告
  static warn(BuildContext context, {String content = '警告'}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(content),
      backgroundColor: Colors.amber,
    ));
  }

  /// 底部延时提示
  static info(BuildContext context, {String content = '提示'}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(content),
      backgroundColor: Colors.green,
    ));
  }

  /// 底部弹出半屏对话框，内部调用Navigator.of(context).pop(result)关闭
  /// result返回
  static Future<dynamic> popModalBottomSheet(BuildContext context,
      {required Widget Function(BuildContext) builder}) {
    return showModalBottomSheet(context: context, builder: builder);
  }

  /// 底部弹出全屏，返回的controller可以关闭
  static PersistentBottomSheetController<dynamic> popBottomSheet(
      BuildContext context,
      {required Widget Function(BuildContext) builder}) {
    return showBottomSheet(context: context, builder: builder);
  }

  static showToast(String msg, {int duration = 1, int gravity = 0}) {
    Toast.show(msg, duration: duration, gravity: gravity);
  }
}

class SmsUtil {
  static send(String data, String recipient) async {
    final Telephony telephony = Telephony.backgroundInstance;
    var result = telephony.sendSms(
        to: recipient,
        message: data,
        isMultipart: true,
        statusListener: (SendStatus status) {
          logger.i(status);
        });
    return result;
  }

  static Future<List<SmsMessage>> getInboxSms(
      String address, String keyword) async {
    final Telephony telephony = Telephony.backgroundInstance;
    List<SmsMessage> messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY],
        filter: SmsFilter.where(SmsColumn.ADDRESS)
            .equals(address)
            .and(SmsColumn.BODY)
            .like(keyword),
        sortOrder: [
          OrderBy(SmsColumn.ADDRESS, sort: Sort.ASC),
          OrderBy(SmsColumn.BODY)
        ]);
    return messages;
  }

  static Future<List<SmsConversation>> getConversations(
      String msgCount, String threadId) async {
    final Telephony telephony = Telephony.backgroundInstance;
    List<SmsConversation> messages = await telephony.getConversations(
        filter: ConversationFilter.where(ConversationColumn.MSG_COUNT)
            .equals(msgCount)
            .and(ConversationColumn.THREAD_ID)
            .greaterThan(threadId),
        sortOrder: [OrderBy(ConversationColumn.THREAD_ID, sort: Sort.ASC)]);
    return messages;
  }

  static register(dynamic Function(SmsMessage)? fn) {
    final Telephony telephony = Telephony.backgroundInstance;
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        if (fn != null) {
          fn(message);
        }
      },
      onBackgroundMessage: fn,
    );
  }

  static Future<bool?> isSmsCapable() async {
    final Telephony telephony = Telephony.backgroundInstance;
    bool? canSendSms = await telephony.isSmsCapable;
    return canSendSms;
  }

  static Future<SimState> simState() async {
    final Telephony telephony = Telephony.backgroundInstance;
    SimState simState = await telephony.simState;

    return simState;
  }
}

class TraceUtil {
  DateTime start(String msg) {
    DateTime t = DateTime.now().toUtc();
    logger.i('$msg, trace start:${t.toIso8601String()}');
    return t;
  }

  Duration end(DateTime start, String msg) {
    DateTime t = DateTime.now().toUtc();
    Duration diff = t.difference(start);
    logger.i('$msg, trace end:${t.toIso8601String()}, interval $diff');
    return diff;
  }
}

class ImageUtil {
  /// 判断是否网络
  static bool isNetWorkImg(String img) {
    return img.startsWith('http') || img.startsWith('https');
  }

  /// 判断是否资源图片
  static bool isAssetsImg(String img) {
    return img.startsWith('asset') || img.startsWith('assets');
  }

  /// 判断是否Base64图片
  static bool isBase64Img(String img) {
    return img.startsWith('data:image/') && img.contains(';base64,');
  }
}

class ScreenUtil {
  static double winWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double winHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static double winTop(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  static double winBottom(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  static double winLeft(BuildContext context) {
    return MediaQuery.of(context).padding.left;
  }

  static double winRight(BuildContext context) {
    return MediaQuery.of(context).padding.right;
  }

  static double winKeyHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }

  static double statusBarHeight(BuildContext context) {
    return MediaQueryData.fromWindow(window).padding.top;
  }

  static double navigationBarHeight(BuildContext context) {
    return kToolbarHeight;
  }

  static double topBarHeight(BuildContext context) {
    return kToolbarHeight + MediaQueryData.fromWindow(window).padding.top;
  }
}

class CollectUtil {
  ///判断List是否为空
  static bool listNoEmpty(List? list) {
    if (list == null) return false;

    if (list.isEmpty) return false;

    return true;
  }
}

typedef void OnTimerTickCallback(int millisUntilFinished);

class TimerUtil {
  TimerUtil(
      {this.mInterval = Duration.millisecondsPerSecond,
      required this.mTotalTime});

  late OnTimerTickCallback _onTimerTickCallback;

  /// Timer是否启动.
  bool _isActive = false;

  Timer? _mTimer;

  /// Timer间隔 单位毫秒，默认1000毫秒(1秒).
  int mInterval;

  /// 倒计时总时间
  int mTotalTime; //单位毫秒

  /// 设置Timer间隔.
  void setInterval(int interval) {
    if (interval <= 0) interval = Duration.millisecondsPerSecond;
    mInterval = interval;
  }

  /// 设置倒计时总时间.
  void setTotalTime(int totalTime) {
    if (totalTime <= 0) return;
    mTotalTime = totalTime;
  }

  /// Timer是否启动.
  bool isActive() {
    return _isActive;
  }

  void _doCallback(int time) {
    if (_onTimerTickCallback != null) {
      _onTimerTickCallback(time);
    }
  }

  void startCountDown() {
    if (_isActive || mInterval <= 0 || mTotalTime <= 0) return;
    _isActive = true;
    Duration duration = Duration(milliseconds: mInterval);
    _doCallback(mTotalTime);
    _mTimer = Timer.periodic(duration, (Timer timer) {
      int time = mTotalTime - mInterval;
      mTotalTime = time;
      if (time >= mInterval) {
        _doCallback(time);
      } else if (time == 0) {
        _doCallback(time);
        cancel();
      } else {
        timer.cancel();
        Future.delayed(Duration(milliseconds: time), () {
          mTotalTime = 0;
          _doCallback(0);
          cancel();
        });
      }
    });
  }

  void cancel() {
    final _mTimer = this._mTimer;
    if (_mTimer != null) {
      _mTimer.cancel();
      this._mTimer = null;
    }
    _isActive = false;
  }

  // set timer callback.
  void setOnTimerTickCallback(OnTimerTickCallback callback) {
    _onTimerTickCallback = callback;
  }
}
