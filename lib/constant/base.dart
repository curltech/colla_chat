import 'package:colla_chat/tool/image_util.dart';
import 'package:flutter/widgets.dart';

///background opacity
const double lgOpacity = 0.2;
const double mdOpacity = 0.5;
const double smOpacity = 0.8;

///padding
const double xlPadding = 30.0;
const double lgPadding = 15.0;
const double mdPadding = 10.0;
const double smPadding = 5.0;
const double xsPadding = 1.0;

///icon size
//xs (extra small),
const xsSize = Size(16, 16);
//sm (small),
const smSize = Size(24, 24);
//md (medium),
const mdSize = Size(32, 32);
//lg (large),
const lgSize = Size(48, 48);
//xl (extra large)
const xlSize = Size(64, 64);

const defaultAppIconFile = 'assets/icons/favicon-96x96.png';
const defaultAvatarFile = 'assets/images/colla-o1.png';
const defaultGroupAvatarFile = 'assets/images/colla-o1.png';

///中等大小的app缺省图像
final mdAppImage = ImageUtil.buildImageWidget(
  image: defaultAppIconFile,
  width: mdSize.width,
  height: mdSize.height,
);
