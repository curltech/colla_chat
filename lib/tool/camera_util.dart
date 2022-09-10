import 'package:flutter/material.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

///wechat_camera_picker
class CameraUtil {
  static pickFromCamera(
    BuildContext context, {
    CameraPickerConfig pickerConfig = const CameraPickerConfig(),
    CameraPickerState Function()? createPickerState,
    bool useRootNavigator = true,
    CameraPickerPageRoute<AssetEntity> Function(Widget)? pageRouteBuilder,
    Locale? locale,
  }) async {
    final AssetEntity? entity = await CameraPicker.pickFromCamera(context,
        pickerConfig: pickerConfig,
        createPickerState: createPickerState,
        useRootNavigator: useRootNavigator,
        pageRouteBuilder: pageRouteBuilder,
        locale: locale);
  }
}
