import 'package:colla_chat/tool/image_util.dart';
import 'package:flutter/widgets.dart';

///background opacity
class AppOpacity {
  static const double lgOpacity = 0.2;
  static const double mdOpacity = 0.5;
  static const double smOpacity = 0.8;
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
  static const xsSize = Size(16, 16);

  //sm (small),
  static const smSize = Size(24, 24);

  //md (medium),
  static const mdSize = Size(32, 32);

  //lg (large),
  static const lgSize = Size(48, 48);

  //xl (extra large)
  static const xlSize = Size(64, 64);
}

class AppImageFile {
  static const defaultAppIconFile = 'assets/icons/favicon-96x96.png';
  static const defaultAvatarFile = 'assets/images/colla-o1.png';
  static const defaultGroupAvatarFile = 'assets/images/colla-o1.png';
}

class AppImage {
  ///中等大小的app缺省图像
  static final mdAppImage = Image.asset(
    AppImageFile.defaultAppIconFile,
    key: UniqueKey(),
    width: AppIconSize.mdSize.width,
    height: AppIconSize.mdSize.height,
    fit: BoxFit.fill,
  );
}
