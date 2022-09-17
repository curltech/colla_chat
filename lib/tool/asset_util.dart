import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

///资产选择器，类似微信，可以选择图片和其他资产
class AssetUtil {
  static Future<List<AssetEntity>?> pickAssets(
    BuildContext context, {
    Key? key,
    AssetPickerConfig pickerConfig = const AssetPickerConfig(),
    bool useRootNavigator = true,
    AssetPickerPageRoute<List<AssetEntity>> Function(Widget)? pageRouteBuilder,
  }) async {
    // pickerConfig = AssetPickerConfig(
    //   maxAssets: 9,
    //   pageSize: 320,
    //   pathThumbnailSize: const ThumbnailSize(80, 80),
    //   gridCount: 4,
    //   selectedAssets: [],
    //   themeColor: appDataProvider.themeData.colorScheme.primary,
    // );
    final List<AssetEntity>? result = await AssetPicker.pickAssets(
      context,
      key: key,
      pickerConfig: pickerConfig,
      useRootNavigator: useRootNavigator,
      pageRouteBuilder: pageRouteBuilder,
    );

    return result;
  }
}
