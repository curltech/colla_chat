import 'package:colla_chat/tool/image_util.dart';
import 'package:flutter/widgets.dart';

const String appName = 'CollaChat';
const String appVersion = '1.3.0';
const String appVendor = 'CurlTech';
const String vendorUrl = 'curltech.io';

///background opacity
class AppOpacity {
  static const double maxOpacity = 0;
  static const double xlOpacity = 0.1;
  static const double lgOpacity = 0.3;
  static const double mdOpacity = 0.5;
  static const double smOpacity = 0.7;
  static const double xsOpacity = 0.9;
  static const double minOpacity = 1;
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
  static const xsAppIconFile = 'assets/images/app.png';
  static const mdAppIconFile = 'assets/images/app.png';
  static const defaultAvatarFile = 'assets/images/app.png';
  static const defaultGroupAvatarFile = 'assets/images/app.png';
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
    image: AppImageFile.xsAppIconFile,
    width: AppImageSize.minSize,
    height: AppImageSize.minSize,
    fit: BoxFit.contain,
  );

  ///24大小的app缺省图像
  static final xsAppImage = ImageUtil.buildImageWidget(
    image: AppImageFile.mdAppIconFile,
    width: AppImageSize.xsSize,
    height: AppImageSize.xsSize,
    fit: BoxFit.contain,
  );

  ///32大小的app缺省图像
  static final smAppImage = ImageUtil.buildImageWidget(
    image: AppImageFile.mdAppIconFile,
    width: AppImageSize.smSize,
    height: AppImageSize.smSize,
    fit: BoxFit.contain,
  );

  ///40大小的app缺省图像
  static final mdAppImage = ImageUtil.buildImageWidget(
    image: AppImageFile.mdAppIconFile,
    width: AppImageSize.mdSize,
    height: AppImageSize.mdSize,
    fit: BoxFit.contain,
  );

  ///64大小的app缺省图像
  static final lgAppImage = ImageUtil.buildImageWidget(
    image: AppImageFile.mdAppIconFile,
    width: AppImageSize.lgSize,
    height: AppImageSize.lgSize,
    fit: BoxFit.contain,
  );
}

const double dialogSizeIndex = 0.8;
