import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:flutter/material.dart';

import '../../constant/base.dart';
import '../../tool/util.dart';
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
    Widget? imageWidget;
    var image = this.image;
    if (image != null) {
      if (ImageUtil.isBase64Img(image)) {
        int pos = image.indexOf(',');
        Uint8List bytes = CryptoUtil.decodeBase64(image.substring(pos));
        imageWidget = Image.memory(bytes, fit: BoxFit.contain);
      } else if (ImageUtil.isAssetsImg(image)) {
        imageWidget = Image.asset(
          image,
          width: width,
          height: height,
          fit: width != null && height != null ? BoxFit.fill : fit,
        );
      } else if (File(image).existsSync()) {
        imageWidget = Image.file(
          File(image),
          width: width,
          height: height,
          fit: fit,
        );
      } else if (ImageUtil.isNetWorkImg(image)) {
        imageWidget = CachedNetworkImage(
          imageUrl: image,
          width: width,
          height: height,
          fit: fit,
          cacheManager: defaultCacheManager,
        );
      }
    }
    imageWidget ??= defaultImage;
    // Image.asset(
    //   defaultIcon,
    //   width: width,
    //   height: height!,
    //   fit: fit,
    // );
    if (isRadius) {
      return ClipRRect(
        borderRadius: const BorderRadius.all(
          Radius.circular(4.0),
        ),
        child: imageWidget,
      );
    }
    return imageWidget;
  }
}
