import 'package:colla_chat/tool/image_util.dart';
import 'package:flutter/widgets.dart';

const String appName = 'CollaChat';
const String appVersion = '1.7.0';
const String appVendor = 'CurlTech';
const String vendorUrl = 'curltech.io';
const bool appDebug = true;

///background opacity
class AppOpacity {
  static const int maxOpacity = 0;
  static const int xlOpacity = 26;
  static const int lgOpacity = 76;
  static const int mdOpacity = 128;
  static const int smOpacity = 180;
  static const int xsOpacity = 225;
  static const int minOpacity = 255;
}

///padding
class AppPadding {
  static const double maxPadding = 30.0;
  static const double xlPadding = 20.0;
  static const double lgPadding = 15.0;
  static const double mdPadding = 10.0;
  static const double smPadding = 5.0;
  static const double xsPadding = 1.0;
  static const double minPadding = 0.0;
}

///icon size
class AppIconSize {
  static const minSize = 8.0;

  //16大小
  static const xsSize = 16.0;

  //24大小
  static const smSize = 24.0;

  //32大小
  static const mdSize = 32.0;

  //40大小
  static const lgSize = 40.0;

  //48大小
  static const xlSize = 48.0;

  static const maxSize = 64.0;
}

///image size
class AppImageSize {
  static const minSize = 16.0;

  //24大小
  static const xsSize = 24.0;

  //32大小
  static const smSize = 32.0;

  //40大小
  static const mdSize = 40.0;

  //64大小
  static const lgSize = 64.0;

  //128大小
  static const xlSize = 128.0;

  static const maxSize = 256.0;
}

class AppFontSize {
  static const double maxFontSize = 22.0;
  static const double xlFontSize = 20.0;
  static const double lgFontSize = 18.0;
  static const double mdFontSize = 16.0;
  static const double smFontSize = 14.0;
  static const double xsFontSize = 12.0;
  static const double minFontSize = 10.0;
}

class AppImageFile {
  static const xsAppIconFile = 'assets/image/app.png';
  static const mdAppIconFile = 'assets/image/app.png';
  static const defaultAvatarFile = 'assets/image/app.png';
  static const defaultGroupAvatarFile = 'assets/image/app.png';
}

class AppIcon {
  ///16大小的app缺省图标
  static const xsAppIcon = ImageIcon(
    AssetImage(
      AppImageFile.xsAppIconFile,
    ),
    size: AppIconSize.xsSize,
  );

  ///24大小的app缺省图标
  static const smAppIcon = ImageIcon(
    AssetImage(
      AppImageFile.mdAppIconFile,
    ),
    size: AppIconSize.smSize,
  );

  ///32大小的app缺省图标
  static const mdAppIcon = ImageIcon(
    AssetImage(
      AppImageFile.mdAppIconFile,
    ),
    size: AppIconSize.mdSize,
  );

  ///48大小的app缺省图标
  static const lgAppIcon = ImageIcon(
    AssetImage(
      AppImageFile.mdAppIconFile,
    ),
    size: AppIconSize.lgSize,
  );

  ///64大小的app缺省图标
  static const xlAppIcon = ImageIcon(
    AssetImage(
      AppImageFile.mdAppIconFile,
    ),
    size: AppIconSize.xlSize,
  );
}

class AppImage {
  ///16大小的app缺省图像
  static final minAppImage = ImageUtil.buildImageWidget(
    imageContent: AppImageFile.xsAppIconFile,
    width: AppImageSize.minSize,
    height: AppImageSize.minSize,
    fit: BoxFit.contain,
  );

  ///24大小的app缺省图像
  static final xsAppImage = ImageUtil.buildImageWidget(
    imageContent: AppImageFile.mdAppIconFile,
    width: AppImageSize.xsSize,
    height: AppImageSize.xsSize,
    fit: BoxFit.contain,
  );

  ///32大小的app缺省图像
  static final smAppImage = ImageUtil.buildImageWidget(
    imageContent: AppImageFile.mdAppIconFile,
    width: AppImageSize.smSize,
    height: AppImageSize.smSize,
    fit: BoxFit.contain,
  );

  ///40大小的app缺省图像
  static final mdAppImage = ImageUtil.buildImageWidget(
    imageContent: AppImageFile.mdAppIconFile,
    width: AppImageSize.mdSize,
    height: AppImageSize.mdSize,
    fit: BoxFit.contain,
  );

  ///64大小的app缺省图像
  static final lgAppImage = ImageUtil.buildImageWidget(
    imageContent: AppImageFile.mdAppIconFile,
    width: AppImageSize.lgSize,
    height: AppImageSize.lgSize,
    fit: BoxFit.contain,
  );
}

const double dialogSizeIndex = 0.8;

final BorderRadius borderRadius = BorderRadius.circular(8.0);
