import 'package:permission_handler/permission_handler.dart';

class PermissionUtil {
  static Future<PermissionStatus> getPermission(Permission permission) async {
    var status = await permission.status;

    return status;
  }

  static Future<PermissionStatus> requestPermission(
      Permission permission) async {
    try {
      var status = await permission.status;
      if (!status.isGranted) {
        status = await permission.request();
      }

      return status;
    } catch (e) {
      print('requestPermission failure:$e');
    }
    return PermissionStatus.denied;
  }

  static openAppSettings(Permission permission) async {
    if (await permission.isPermanentlyDenied) {
      openAppSettings(permission);
    }
  }

  static Future<bool> isEnabled(PermissionWithService permission) async {
    if (await permission.serviceStatus.isEnabled) {
      return true;
    }

    return false;
  }
}
