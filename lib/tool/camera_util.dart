import 'package:flutter/material.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

///wechat_camera_picker
class CameraUtil {
  static Future<AssetEntity?> pickFromCamera(
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

    return entity;
  }

  static Future<CameraPreview?> buildCameraPreview({
    Key? key,
    Widget? child,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    List<CameraDescription> cameras = await availableCameras();
    CameraController controller =
        CameraController(cameras[0], ResolutionPreset.max);
    await controller.initialize();

    return CameraPreview(
      controller,
      key: key,
      child: child,
    );
  }
}
