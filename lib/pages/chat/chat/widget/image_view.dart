import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../constant/base.dart';
import '../../../../tool/util.dart';
import '../../../../transport/httpclient.dart';

///通用图像组件，经过clip处理，用于显示头像等场景，图像可以来源于网络，文件和资源
///目前还没支持base64的图像，等待完成
class ImageView extends StatelessWidget {
  final String img;
  final double width;
  final double height;
  final BoxFit fit;
  final bool isRadius;

  ImageView({
    required this.img,
    required this.height,
    required this.width,
    required this.fit,
    this.isRadius = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (ImageUtil.isNetWorkImg(img)) {
      image = new CachedNetworkImage(
        imageUrl: img,
        width: width,
        height: height,
        fit: fit,
        cacheManager: defaultCacheManager,
      );
    } else if (File(img).existsSync()) {
      image = new Image.file(
        File(img),
        width: width,
        height: height,
        fit: fit,
      );
    } else if (ImageUtil.isAssetsImg(img)) {
      image = new Image.asset(
        img,
        width: width,
        height: height,
        fit: width != null && height != null ? BoxFit.fill : fit,
      );
    } else {
      image = new Container(
        decoration: BoxDecoration(
            color: Colors.black26.withOpacity(0.1),
            border:
                Border.all(color: Colors.black.withOpacity(0.2), width: 0.3)),
        child: new Image.asset(
          defaultIcon,
          width: width - 1,
          height: height - 1,
          fit: width != null && height != null ? BoxFit.fill : fit,
        ),
      );
    }
    if (isRadius) {
      return new ClipRRect(
        borderRadius: BorderRadius.all(
          Radius.circular(4.0),
        ),
        child: image,
      );
    }
    return image;
  }
}
