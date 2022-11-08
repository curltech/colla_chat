import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:flutter/material.dart';

import '../../constant/base.dart';
import '../../transport/httpclient.dart';

///通用图像组件，经过clip处理，用于显示头像等场景，图像可以来源于网络，文件和资源
class ImageWidget extends StatelessWidget {
  final String? image;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool isRadius;

  const ImageWidget({
    Key? key,
    this.image,
    this.height,
    this.width,
    this.fit = BoxFit.fill,
    this.isRadius = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var image = this.image;
    Widget imageWidget = ImageUtil.buildImageWidget(image,
        width: width, height: height, fit: fit, isRadius: isRadius);

    return imageWidget;
  }
}
