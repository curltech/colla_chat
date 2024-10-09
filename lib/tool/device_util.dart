import 'package:colla_chat/platform.dart';
import 'package:flutter/services.dart';

class DeviceUtil {
  static setPreferredOrientations(List<DeviceOrientation> orientations) async {
    if (platformParams.mobile) {
      await SystemChrome.setPreferredOrientations(orientations);
    }
  }
}
