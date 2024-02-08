import 'dart:io';
import 'dart:typed_data';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/tool/photo_util.dart';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

///基于微信UI的Flutter图片选择器（同时支持视频和音频）
class AssetUtil {
  static Future<List<AssetEntity>?> pickAssets(
    BuildContext context, {
    Key? key,
    AssetPickerConfig pickerConfig = const AssetPickerConfig(),
    bool useRootNavigator = true,
    AssetPickerPageRoute<List<AssetEntity>> Function(Widget)? pageRouteBuilder,
  }) async {
    final List<AssetEntity>? result = await AssetPicker.pickAssets(
      context,
      key: key,
      pickerConfig: pickerConfig,
      useRootNavigator: useRootNavigator,
      pageRouteBuilder: pageRouteBuilder,
    );

    return result;
  }

  /// AssetEntityImage
  static Image buildAssetEntityImage(
    AssetEntity entity, {
    bool isOriginal = true,
    ThumbnailSize? thumbnailSize = const ThumbnailSize.square(200),
    ThumbnailFormat thumbnailFormat = ThumbnailFormat.png,
    Key? key,
    Widget Function(BuildContext, Widget, int?, bool)? frameBuilder,
    Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = false,
    bool isAntiAlias = false,
    FilterQuality filterQuality = FilterQuality.low,
  }) {
    return AssetEntityImage(
      entity,
      isOriginal: isOriginal,
      thumbnailSize: thumbnailSize,
      thumbnailFormat: thumbnailFormat,
      key: key,
      frameBuilder: frameBuilder,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      filterQuality: filterQuality,
    );
  }

  ///根据路径存储Image到gallery
  static Future<AssetEntity?> saveAssetEntityWithPath(
    String path, {
    required String title,
    String? desc,
    String? relativePath,
  }) async {
    final AssetEntity? fileEntity = await PhotoManager.editor.saveImageWithPath(
      path,
      title: title,
      desc: desc,
      relativePath: relativePath,
    );

    return fileEntity;
  }

  ///根据数据存储Image到gallery
  static Future<AssetEntity?> saveAssetEntity(
    Uint8List data, {
    required String title,
    String? desc,
    String? relativePath,
  }) async {
    final AssetEntity? fileEntity = await PhotoManager.editor.saveImage(
      data,
      title: title,
      desc: desc,
      relativePath: relativePath,
    );

    return fileEntity;
  }

  ///根据数据存储Video到gallery
  static Future<AssetEntity?> saveVideoAssetEntity(
    String path, {
    required String title,
    String? desc,
    String? relativePath,
  }) async {
    var file = File(path);
    final AssetEntity? fileEntity = await PhotoManager.editor.saveVideo(
      file,
      title: title,
      desc: desc,
      relativePath: relativePath,
    );

    return fileEntity;
  }

  ///删除entry
  static Future<List<String>> deleteWithIds(List<String> ids) async {
    final List<String> result = await PhotoManager.editor.deleteWithIds(ids);

    return result;
  }

  static Future<AssetEntity?> fromJson(Map json) async {
    var data = json['data'];
    var originBytes = CryptoUtil.decodeBase64(data);
    var title = json['title'];
    var desc = json['desc'];
    var relativePath = json['relativePath'];
    AssetEntity? entry = await saveAssetEntity(originBytes,
        title: title, desc: desc, relativePath: relativePath);

    return entry;
  }

  static Future<List<AssetEntity>> fromJsons(List<Map> jsons) async {
    List<AssetEntity> entries = [];
    for (var json in jsons) {
      var entry = await fromJson(json);
      entries.add(entry!);
    }

    return entries;
  }

  static Future<Map<String, dynamic>> toJson(
    AssetEntity entry, {
    String? desc,
    String? relativePath,
  }) async {
    Map<String, dynamic> map = {};
    var originBytes = await entry.originBytes;
    map['data'] = CryptoUtil.encodeBase64(originBytes!);
    map['title'] = entry.title;
    map['desc'] = desc;
    map['relativePath'] = relativePath;

    return map;
  }

  static Future<List<Map<String, dynamic>>> toJsons(
    List<AssetEntity> entries,
  ) async {
    List<Map<String, dynamic>> maps = [];
    for (var entry in entries) {
      var map = await toJson(entry);
      maps.add(map);
    }

    return maps;
  }
}
