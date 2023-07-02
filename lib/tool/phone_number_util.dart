import 'package:colla_chat/tool/string_util.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

class PhoneNumberUtil {
  static PhoneNumber parse(
    String phoneNumberStr, {
    IsoCode? callerCountry,
    IsoCode? destinationCountry,
  }) {
    PhoneNumber phoneNumber = PhoneNumber.parse(phoneNumberStr,
        callerCountry: callerCountry, destinationCountry: destinationCountry);

    return phoneNumber;
  }

  static PhoneNumber fromIsoCode(IsoCode isoCode, String phoneNumber) {
    return PhoneNumber.parse(
      phoneNumber,
      callerCountry: isoCode,
    );
  }

  static PhoneNumber fromRaw(String phoneNumber) {
    return PhoneNumber.parse(phoneNumber);
  }

  static bool validate(PhoneNumber phoneNumber, {PhoneNumberType? type}) {
    bool isValidate = phoneNumber.isValid(type: type);

    return isValidate;
  }

  static String format(PhoneNumber phoneNumber, {IsoCode? isoCode}) {
    String formatted = phoneNumber.getFormattedNsn(isoCode: isoCode);

    return formatted;
  }

  static List<IsoCode> allSupportedRegions() {
    return IsoCode.values;
  }

  // 格式化手机号为344
  static String formatMobile344(String mobile) {
    if (StringUtil.isEmpty(mobile)) return '';
    mobile =
        mobile.replaceAllMapped(RegExp(r"(^\d{3}|\d{4}\B)"), (Match match) {
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
}
