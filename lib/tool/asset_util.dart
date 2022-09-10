import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

///Flutter WeChat Assets Picker
class AssetUtil {
  static pickAssets(
    BuildContext context, {
    Key? key,
    AssetPickerConfig pickerConfig = const AssetPickerConfig(),
    bool useRootNavigator = true,
    AssetPickerPageRoute<List<AssetEntity>> Function(Widget)? pageRouteBuilder,
  }) async {
    final List<AssetEntity>? result = await AssetPicker.pickAssets(
      context,
      key: key,
      pickerConfig: pickerConfig,
      useRootNavigator: useRootNavigator,
      pageRouteBuilder: pageRouteBuilder,
    );
  }
}
