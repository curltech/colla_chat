import 'package:colla_chat/tool/image_util.dart';
import 'package:flutter/widgets.dart';

///background opacity
class AppOpacity {
  static const double xlOpacity = 0;
  static const double lgOpacity = 0.2;
  static const double mdOpacity = 0.5;
  static const double smOpacity = 0.8;
  static const double xsOpacity = 1;
}

///padding
class AppPadding {
  static const double xlPadding = 30.0;
  static const double lgPadding = 15.0;
  static const double mdPadding = 10.0;
  static const double smPadding = 5.0;
  static const double xsPadding = 1.0;
}

///icon size
class AppIconSize {
  //16大小
  static const xsSize = Size(16, 16);

  //24大小
  static const smSize = Size(24, 24);

  //32大小
  static const mdSize = Size(32, 32);

  //40大小
  static const lgSize = Size(40, 40);

  //48大小
  static const xlSize = Size(48, 48);
}

class AppImageFile {
  static const xsAppIconFile = 'assets/images/app.png';
  static const mdAppIconFile = 'assets/images/app.png';
  static const defaultAvatarFile = 'assets/images/app.png';
  static const defaultGroupAvatarFile = 'assets/images/app.png';
}

class AppIcon {
  ///16大小的app缺省图标
  static final xsAppIcon = ImageIcon(
    const AssetImage(
      AppImageFile.xsAppIconFile,
    ),
    size: AppIconSize.xsSize.width,
  );

  ///24大小的app缺省图标
  static final smAppIcon = ImageIcon(
    const AssetImage(
      AppImageFile.mdAppIconFile,
    ),
    size: AppIconSize.smSize.width,
  );

  ///32大小的app缺省图标
  static final mdAppIcon = ImageIcon(
    const AssetImage(
      AppImageFile.mdAppIconFile,
    ),
    size: AppIconSize.mdSize.width,
  );

  ///48大小的app缺省图标
  static final lgAppIcon = ImageIcon(
    const AssetImage(
      AppImageFile.mdAppIconFile,
    ),
    size: AppIconSize.lgSize.width,
  );

  ///64大小的app缺省图标
  static final xlAppIcon = ImageIcon(
    const AssetImage(
      AppImageFile.mdAppIconFile,
    ),
    size: AppIconSize.xlSize.width,
  );
}

class AppImage {
  ///16大小的app缺省图像
  static final xsAppImage = ImageUtil.buildImageWidget(
    image: AppImageFile.xsAppIconFile,
    width: AppIconSize.xsSize.width,
    height: AppIconSize.xsSize.height,
    fit: BoxFit.contain,
  );

  ///24大小的app缺省图像
  static final smAppImage = ImageUtil.buildImageWidget(
    image: AppImageFile.mdAppIconFile,
    width: AppIconSize.smSize.width,
    height: AppIconSize.smSize.height,
    fit: BoxFit.contain,
  );

  ///32大小的app缺省图像
  static final mdAppImage = ImageUtil.buildImageWidget(
    image: AppImageFile.mdAppIconFile,
    width: AppIconSize.mdSize.width,
    height: AppIconSize.mdSize.height,
    fit: BoxFit.contain,
  );

  ///48大小的app缺省图像
  static final lgAppImage = ImageUtil.buildImageWidget(
    image: AppImageFile.mdAppIconFile,
    width: AppIconSize.lgSize.width,
    height: AppIconSize.lgSize.height,
    fit: BoxFit.contain,
  );

  ///64大小的app缺省图像
  static final xlAppImage = ImageUtil.buildImageWidget(
    image: AppImageFile.mdAppIconFile,
    width: AppIconSize.xlSize.width,
    height: AppIconSize.xlSize.height,
    fit: BoxFit.contain,
  );
}
