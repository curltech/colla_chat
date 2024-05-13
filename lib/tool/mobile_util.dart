import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:mobile_number/mobile_number.dart';
import 'package:phone_number/phone_number.dart';

///手机相关的功能
class MobileUtil {
  /// 只支持android，获取手机号码
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

  /// 支持android和ios
  static Future<PhoneNumber> parse(String phoneNumberStr,
      {String? regionCode}) async {
    //phone_number.RegionInfo region = phone_number.RegionInfo(name:'US',code:'en',prefix: 1);
    PhoneNumber phoneNumber =
        await PhoneNumberUtil().parse(phoneNumberStr, regionCode: regionCode);

    return phoneNumber;
  }

  /// 支持android和ios
  static Future<bool> validate(String phoneNumberStr, String regionCode) async {
    bool isValidate = await PhoneNumberUtil()
        .validate(phoneNumberStr, regionCode: regionCode);

    return isValidate;
  }

  /// 支持android和ios
  static Future<String> format(String phoneNumberStr, String regionCode) async {
    String formatted =
        await PhoneNumberUtil().format(phoneNumberStr, regionCode);

    return formatted;
  }

  /// 支持android和ios，获取支持的地区
  static Future<List<RegionInfo>> allSupportedRegions({String? locale}) async {
    List<RegionInfo> regions =
        await PhoneNumberUtil().allSupportedRegions(locale: locale);

    return regions;
  }

  /// 支持android和ios，获取运营商代码
  static Future<String> carrierRegionCode() async {
    String code = await PhoneNumberUtil().carrierRegionCode();

    return code;
  }
}
