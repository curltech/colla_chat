import 'package:colla_chat/tool/string_util.dart';
import 'package:phone_number/phone_number.dart' as phone_number;
import 'package:phone_numbers_parser/phone_numbers_parser.dart'
    as phone_numbers_parser;

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
