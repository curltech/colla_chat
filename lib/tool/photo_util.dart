import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

///photo_view,photo_view_gallery
class PhotoUtil {
  static requestPermissionExtend() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      // Granted.
    } else {
      // Limited(iOS) or Rejected, use `==` for more precise judgements.
      // You can call `PhotoManager.openSetting()` to open settings for further steps.
      PhotoManager.openSetting();
    }
  }

  buildPhotoView() {
    return PhotoView(
      imageProvider: null,
    );
  }

  buildPhotoViewGallery(List<String> assetNames) {
    return PhotoViewGallery.builder(
      itemCount: null,
      builder: (BuildContext context, int index) {
        return PhotoViewGalleryPageOptions(
          imageProvider: AssetImage(assetNames[index]),
          initialScale: PhotoViewComputedScale.contained * 0.8,
          heroAttributes: const PhotoViewHeroAttributes(tag: ''),
        );
      },
    );
  }
}
