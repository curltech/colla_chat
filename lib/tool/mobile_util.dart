import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:mobile_number/mobile_number.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

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
  static PhoneNumber parse(
    String phoneNumberStr, {
    IsoCode? callerCountry,
    IsoCode? destinationCountry,
  }) {
    final phoneNumber = PhoneNumber.parse(phoneNumberStr,
        callerCountry: callerCountry, destinationCountry: destinationCountry);

    return phoneNumber;
  }

  /// 支持android和ios
  static bool validate(
    String phoneNumberStr, {
    IsoCode? callerCountry,
    IsoCode? destinationCountry,
  })  {
    final phoneNumber = PhoneNumber.parse(phoneNumberStr,
        callerCountry: callerCountry, destinationCountry: destinationCountry);
    bool isValidate = phoneNumber.isValid();

    return isValidate;
  }

  /// 支持android和ios
  static String format(String phoneNumberStr, {
    IsoCode? callerCountry,
    IsoCode? destinationCountry,
  })  {
    final phoneNumber = PhoneNumber.parse(phoneNumberStr,
        callerCountry: callerCountry, destinationCountry: destinationCountry);

    String formatted = phoneNumber.formatNsn();

    return formatted;
  }
}
