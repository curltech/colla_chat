import 'package:colla_chat/plugin/logger.dart';
import 'package:mobile_number/mobile_number.dart';

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
