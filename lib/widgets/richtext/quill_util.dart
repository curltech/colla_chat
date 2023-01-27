import 'dart:io';
import 'dart:typed_data';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:cross_file/cross_file.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill_extensions/embeds/embed_types.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:visual_editor/toolbar/models/media-pick.enum.dart';

class QuillUtil {
  ///打开文件选择器
  static Future<String?> openFileSystemPicker(BuildContext context) async {
    return await FileUtil.open(
      context: context,
      rootDirectory: await getApplicationDocumentsDirectory(),
      fsType: FilesystemType.file,
      fileTileSelectMode: FileTileSelectMode.wholeTile,
    );
  }

  ///打开文件选择器
  static Future<String?> pickFiles(BuildContext context) async {
    List<XFile> files = await FileUtil.pickFiles();
    if (files.isEmpty) {
      return null;
    }
    final fileName = files.first.name;
    return fileName;
  }

  ///打开文件选择器，将选择的文件输入OnImagePickCallback
  static Future<String?> webImagePickImpl(
    OnImagePickCallback onImagePickCallback,
  ) async {
    List<XFile> files = await FileUtil.pickFiles();
    if (files.isEmpty) {
      return null;
    }

    // Take first, because we don't allow picking multiple files.
    final fileName = files.first.name;
    final file = File(fileName);

    return onImagePickCallback(file);
  }

  ///拷贝文件到应用目录
  static Future<String> onImagePickCallback(File file) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final copiedFile =
        await file.copy('${appDocDir.path}/${basename(file.path)}');
    return copiedFile.path.toString();
  }

  ///拷贝文件到应用目录
  static Future<String> onVideoPickCallback(File file) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final copiedFile =
        await file.copy('${appDocDir.path}/${basename(file.path)}');
    return copiedFile.path.toString();
  }

  /// 媒体选择的类别
  static Future<MediaPickSettingE?> selectMediaPickSettingE(
          BuildContext context) =>
      showDialog<MediaPickSettingE>(
        context: context,
        builder: (ctx) => AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.collections),
                label: Text(AppLocalizations.t('Gallery')),
                onPressed: () => Navigator.pop(ctx, MediaPickSettingE.Gallery),
              ),
              TextButton.icon(
                icon: const Icon(Icons.link),
                label: Text(AppLocalizations.t('Link')),
                onPressed: () => Navigator.pop(ctx, MediaPickSettingE.Link),
              )
            ],
          ),
        ),
      );

  ///媒体的选择设置，照片廊还是url连接
  static Future<MediaPickSetting?> selectMediaPickSetting(
          BuildContext context) =>
      showDialog<MediaPickSetting>(
        context: context,
        builder: (ctx) => AlertDialog(
          contentPadding: const EdgeInsets.all(8.0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.collections),
                label: Text(AppLocalizations.t('Gallery')),
                onPressed: () => Navigator.pop(ctx, MediaPickSetting.Gallery),
              ),
              const SizedBox(
                height: 5,
              ),
              TextButton.icon(
                icon: const Icon(Icons.link),
                label: Text(AppLocalizations.t('Link')),
                onPressed: () => Navigator.pop(ctx, MediaPickSetting.Link),
              )
            ],
          ),
        ),
      );

  ///相机的媒体设置，照片还是摄像
  static Future<MediaPickSetting?> selectCameraPickSetting(
          BuildContext context) =>
      showDialog<MediaPickSetting>(
        context: context,
        builder: (ctx) => AlertDialog(
          contentPadding: const EdgeInsets.all(8.0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.camera),
                label: Text(AppLocalizations.t('Capture a photo')),
                onPressed: () => Navigator.pop(ctx, MediaPickSetting.Camera),
              ),
              const SizedBox(
                height: 5,
              ),
              TextButton.icon(
                icon: const Icon(Icons.video_call),
                label: Text(AppLocalizations.t('Capture a video')),
                onPressed: () => Navigator.pop(ctx, MediaPickSetting.Video),
              )
            ],
          ),
        ),
      );

  static Future<String> onImagePaste(Uint8List imageBytes) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final file = await File(
            '${appDocDir.path}/${basename('${DateTime.now().millisecondsSinceEpoch}.png')}')
        .writeAsBytes(imageBytes, flush: true);
    return file.path.toString();
  }
}
