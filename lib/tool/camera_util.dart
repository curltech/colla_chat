import 'package:colla_chat/plugin/logger.dart';
import 'package:flutter/material.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

///基于微信UI的Flutter相机选择器，进行拍照和录像，同时是 wechat_assets_picker的扩展
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

  Future<CameraPreview> buildCameraPreview({
    Key? key,
    int cameraIndex = 0,
    CameraDescription? description,
    ResolutionPreset resolutionPreset = ResolutionPreset.max,
    bool enableAudio = true,
    ImageFormatGroup? imageFormatGroup,
    Widget? child,
  }) async {
    List<CameraDescription> cameras = await availableCameras();
    CameraController controller =
        CameraController(cameras[cameraIndex], resolutionPreset);
    try {
      await controller.initialize();
    } catch (e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            logger.e('User denied camera access.');
            break;
          default:
            logger.e('Handle other errors.');
            break;
        }
      }
    }

    return CameraPreview(
      controller,
      key: key,
      child: child,
    );
  }
}
