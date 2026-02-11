import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/number_util.dart';
import 'package:colla_chat/widgets/media_editor/ffmpeg/ffmpeg_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/tool/video_util.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/media/playlist_widget.dart';
import 'package:flutter/material.dart';

enum MediaPlayerStatus {
  none,
  init,
  buffering,
  pause,
  playing,
  stop,
  completed
}

///媒体播放器的状态参数
class MediaPlayerState {
  //状态
  MediaPlayerStatus mediaPlayerStatus = MediaPlayerStatus.none;

  //总长度
  Duration duration = Duration.zero;

  //当前播放位置
  Duration position = Duration.zero;

  //音量
  double volume = 1.0;

  //速度
  double playbackSpeed = 1.0;

  //尺寸
  Size? size;

  //方向
  int? rotationCorrection;

  String? caption;

  MediaPlayerState();

  double? get aspectRatio {
    if (size != null && size!.height > 0) {
      return size!.width / size!.height;
    }

    return null;
  }

  bool get isInitialized {
    if (mediaPlayerStatus == MediaPlayerStatus.none ||
        mediaPlayerStatus == MediaPlayerStatus.init ||
        mediaPlayerStatus == MediaPlayerStatus.buffering) {
      return false;
    }
    return true;
  }
}

///媒体源的类型
enum MediaSourceType { asset, file, network, memory, directory }

/// 平台定义的媒体源
class PlatformMediaSource {
  final String title;
  final String filename;
  final String? length;
  final String? mediaFormat;
  final MediaSourceType mediaSourceType;

  //下面两个字段用于媒体收藏功能
  String? messageId;
  Widget? thumbnailWidget;
  Uint8List? thumbnail;

  PlatformMediaSource({
    required this.title,
    required this.filename,
    this.length,
    this.mediaSourceType = MediaSourceType.memory,
    this.mediaFormat,
    this.messageId,
    this.thumbnailWidget,
    this.thumbnail,
  });

  static FutureOr<PlatformMediaSource?> mediaStream(
      {required Uint8List data,
      required ChatMessageMimeType mediaFormat}) async {
    String? filename =
        await FileUtil.writeTempFileAsBytes(data, extension: mediaFormat.name);
    PlatformMediaSource? mediaSource =
        await media(filename: filename!, mediaFormat: mediaFormat);

    return mediaSource;
  }

  static Future<PlatformMediaSource?> media(
      {required String filename,
      String? title,
      ChatMessageMimeType? mediaFormat}) async {
    PlatformMediaSource? mediaSource;
    String? extension = FileUtil.extension(filename);
    if (mediaFormat == null) {
      if (extension != null) {
        if (extension == '3gp') {
          mediaFormat = ChatMessageMimeType.mp4;
        } else {
          mediaFormat =
              StringUtil.enumFromString(ChatMessageMimeType.values, extension);
        }
      }
    }
    title ??= FileUtil.filename(filename);
    if (filename.startsWith('assets')) {
      mediaSource = PlatformMediaSource(
          title: title,
          filename: filename,
          mediaSourceType: MediaSourceType.asset,
          mediaFormat: mediaFormat == null ? extension : mediaFormat.name);
    } else if (filename.startsWith('http')) {
      mediaSource = PlatformMediaSource(
          title: title,
          filename: filename,
          mediaSourceType: MediaSourceType.network,
          mediaFormat: mediaFormat == null ? extension : mediaFormat.name);
    } else {
      if (title == '..') {
        mediaSource = PlatformMediaSource(
            title: title,
            filename: filename,
            mediaSourceType: MediaSourceType.directory);
        mediaSource.thumbnailWidget = Icon(Icons.subdirectory_arrow_left);
      } else {
        String? length;
        Directory dir = Directory(filename);
        if (dir.existsSync()) {
          FileStat stat = dir.statSync();
          if (stat.type == FileSystemEntityType.directory) {
            if (title != '..') {
              length = '${dir.listSync().length}';
            }
            mediaSource = PlatformMediaSource(
                title: title,
                filename: filename,
                length: length,
                mediaSourceType: MediaSourceType.directory);
            mediaSource.thumbnailWidget = Icon(Icons.file_copy_outlined);
          }
        } else {
          File file = File(filename);
          if (file.existsSync()) {
            FileStat stat = file.statSync();
            if (stat.type == FileSystemEntityType.file) {
              String? mimeType = FileUtil.mimeType(filename);
              if (mimeType != null &&
                  (mimeType.startsWith('video') ||
                      mimeType.startsWith('audio') ||
                      mimeType.startsWith('image'))) {
                bool exist = file.existsSync();
                if (exist) {
                  length = NumberUtil.toGMK(file.lengthSync());
                }
                mediaSource = PlatformMediaSource(
                    title: title,
                    filename: filename,
                    length: length,
                    mediaSourceType: MediaSourceType.file,
                    mediaFormat:
                        mediaFormat == null ? extension : mediaFormat.name);
                if (mimeType.startsWith('video')) {
                  try {
                    Uint8List? data;
                    if (filename.endsWith('mp4') || filename.endsWith('3gp')) {
                      data =
                          await VideoUtil.getByteThumbnail(videoFile: filename);
                    } else {
                      data = await FFMpegUtil.thumbnail(videoFile: filename);
                    }
                    if (data != null) {
                      mediaSource.thumbnailWidget =
                          ImageUtil.buildMemoryImageWidget(
                        data,
                        fit: BoxFit.cover,
                      );
                    }
                  } catch (e) {
                    logger.e('thumbnailData failure:$e');
                  }
                } else if (mimeType.startsWith('audio')) {
                } else if (mimeType.startsWith('image')) {
                  Uint8List? data = await FileUtil.readFileAsBytes(filename);
                  if (data != null) {
                    mediaSource.thumbnailWidget =
                        ImageUtil.buildMemoryImageWidget(
                      data,
                      fit: BoxFit.cover,
                    );
                  }
                }
              }
            }
          }
        }
      }
    }

    return mediaSource;
  }

  static Future<List<PlatformMediaSource>> playlist(
      List<String> filenames) async {
    List<PlatformMediaSource> playlist = [];
    for (var filename in filenames) {
      PlatformMediaSource? mediaSource = await media(filename: filename);
      if (mediaSource != null) {
        playlist.add(mediaSource);
      }
    }

    return playlist;
  }

  @override
  String toString() {
    return filename;
  }

  @override
  int get hashCode {
    return toString().hashCode;
  }

  /// 相同的牌，可能id不同
  @override
  bool operator ==(Object other) {
    return toString() == (other as PlatformMediaSource).toString();
  }
}

class PositionData {
  final Duration position;

  final Duration bufferedPosition;

  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}

///定义通用媒体播放控制器的接口，包含媒体播放列表及其操作，列表是否显示
///选择文件的功能，媒体窗口的产生方法接口
abstract class AbstractMediaPlayerController with ChangeNotifier {
  final GlobalKey key = GlobalKey();
  final PlaylistController playlistController;
  final ValueNotifier<String?> filename = ValueNotifier<String?>(null);
  bool _playlistVisible = true;
  final MediaPlayerState mediaPlayerState = MediaPlayerState();
  bool autoPlay = true;

  AbstractMediaPlayerController(this.playlistController, {bool? autoPlay});

  bool get playlistVisible {
    return _playlistVisible;
  }

  set playlistVisible(bool playlistVisible) {
    _playlistVisible = playlistVisible;
    notifyListeners();
  }

  /// 播放新的媒体文件
  Future<void> playMediaSource(PlatformMediaSource mediaSource);

  /// 如果没有播放，则播放当前文件
  void play() {
    if (playlistController.current != null) {
      playMediaSource(playlistController.current!);
    }
  }

  pause();

  resume();

  void next() {
    playlistController.next();
    if (playlistController.current != null) {
      playMediaSource(playlistController.current!);
    }
  }

  void previous() {
    playlistController.previous();
    if (playlistController.current != null) {
      playMediaSource(playlistController.current!);
    }
  }

  /// 停止播放
  stop();

  /// 停止播放，关闭当前播放资源
  Future<void> close() async {
    await stop();
    filename.value = null;
  }

  /// 停止播放，关闭播放器，清除播放器
  @override
  void dispose() {
    close();
    super.dispose();
  }

  ///选择文件加入播放列表
  Future<void> _addTempMediaSource() async {
    try {
      MediaSourceController mediaSourceController =
          MediaSourceController('temp');
      List<PlatformMediaSource>? mediaSources =
          await mediaSourceController.sourceFilePicker();
      if (mediaSources != null && mediaSources.isNotEmpty) {
        await playMediaSource(mediaSources.first);
      }
    } catch (e) {
      DialogUtil.error(content: 'add media file failure:$e');
    }
  }

  Widget buildOpenFileWidget() {
    if (filename.value == null) {
      return IconButton(
        icon: const Icon(
          Icons.playlist_add,
          color: Colors.white,
        ),
        onPressed: () async {
          await _addTempMediaSource();
        },
        tooltip: AppLocalizations.t('Open media file'),
      );
    }
    return nilBox;
  }

  Future<bool?> isPictureInPictureSupported() async {
    throw 'Not support Pip';
  }

  Future<void> enablePictureInPicture() async {
    throw 'Not support Pip';
  }

  Future<void> disablePictureInPicture() async {
    throw 'Not support Pip';
  }

  Widget buildMediaPlayer({
    Key? key,
    bool showClosedCaptionButton = true,
    bool showFullscreenButton = true,
    bool showVolumeButton = true,
  });

  Widget buildPlaylistController() {
    List<Widget> children = [];
    if (playlistController.currentIndex?.value != null &&
        playlistController.currentIndex!.value! > 0) {
      children.add(
        IconButton(
            hoverColor: myself.primary,
            onPressed: () {
              previous();
            },
            icon: const Icon(
              Icons.skip_previous,
              color: Colors.white,
            )),
      );
    } else {
      children.add(
        const IconButton(
            onPressed: null,
            icon: Icon(
              Icons.skip_previous,
              color: Colors.grey,
            )),
      );
    }
    int? currentIndex = playlistController.currentIndex?.value;
    if (currentIndex != null &&
        currentIndex >= 0 &&
        currentIndex < playlistController.length!) {
      if (filename.value != null) {
        String name = FileUtil.filename(filename.value!);
        children.add(AutoSizeText(
          name,
          style: const TextStyle(color: Colors.white),
          maxLines: 1,
        ));
      }
    }
    if (currentIndex != null && currentIndex < playlistController.length! - 1) {
      children.add(
        IconButton(
            hoverColor: myself.primary,
            onPressed: () {
              next();
            },
            icon: const Icon(Icons.skip_next, color: Colors.white)),
      );
    } else {
      children.add(
        const IconButton(
            onPressed: null,
            icon: Icon(
              Icons.skip_next,
              color: Colors.grey,
            )),
      );
    }

    return OverflowBar(
      alignment: MainAxisAlignment.spaceBetween,
      children: children,
    );
  }

  String get progressText {
    return '${StringUtil.durationText(mediaPlayerState.position)}/${StringUtil.durationText(mediaPlayerState.duration)}';
  }
}
