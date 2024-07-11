import 'dart:async';
import 'dart:typed_data';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/ffmpeg_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/tool/video_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
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
enum MediaSourceType {
  asset,
  file,
  network,
  buffer,
}

///平台定义的媒体源
class PlatformMediaSource {
  final String filename;
  final String? mediaFormat;
  final MediaSourceType mediaSourceType;

  //下面两个字段用于媒体收藏功能
  String? messageId;
  Widget? thumbnailWidget;
  Uint8List? thumbnail;

  PlatformMediaSource({
    required this.filename,
    this.mediaSourceType = MediaSourceType.buffer,
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
      {required String filename, ChatMessageMimeType? mediaFormat}) async {
    PlatformMediaSource mediaSource;
    String? extension = FileUtil.extension(filename);
    if (mediaFormat == null) {
      if (extension != null) {
        mediaFormat =
            StringUtil.enumFromString(ChatMessageMimeType.values, extension);
      }
    }
    if (filename.startsWith('assets')) {
      mediaSource = PlatformMediaSource(
          filename: filename,
          mediaSourceType: MediaSourceType.asset,
          mediaFormat: mediaFormat == null ? extension : mediaFormat.name);
    } else if (filename.startsWith('http')) {
      mediaSource = PlatformMediaSource(
          filename: filename,
          mediaSourceType: MediaSourceType.network,
          mediaFormat: mediaFormat == null ? extension : mediaFormat.name);
    } else {
      mediaSource = PlatformMediaSource(
          filename: filename,
          mediaSourceType: MediaSourceType.file,
          mediaFormat: mediaFormat == null ? extension : mediaFormat.name);
      String? mimeType = FileUtil.mimeType(filename);
      if (mimeType != null && mimeType.startsWith('video')) {
        try {
          Uint8List? data;
          if (filename.endsWith('mp4')) {
            data = await VideoUtil.getByteThumbnail(videoFile: filename);
          } else {
            data = await FFMpegUtil.thumbnail(videoFile: filename);
          }
          if (data != null) {
            mediaSource.thumbnail ??= data;
            Widget? thumbnailWidget = ImageUtil.buildMemoryImageWidget(
              data,
              fit: BoxFit.cover,
            );
            mediaSource.thumbnailWidget ??= thumbnailWidget;
          }
        } catch (e) {
          logger.e('thumbnailData failure:$e');
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
  Key key = UniqueKey();
  final PlaylistController playlistController;
  ValueNotifier<String?> filename = ValueNotifier<String?>(null);
  bool _playlistVisible = true;
  MediaPlayerState mediaPlayerState = MediaPlayerState();
  bool autoplay = false;

  AbstractMediaPlayerController(this.playlistController);

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
  play() {
    if (playlistController.current != null) {
      playMediaSource(playlistController.current!);
    }
  }

  pause();

  resume();

  next() {
    playlistController.next();
    if (playlistController.current != null) {
      playMediaSource(playlistController.current!);
    }
  }

  previous() {
    playlistController.previous();
    if (playlistController.current != null) {
      playMediaSource(playlistController.current!);
    }
  }

  /// 停止播放
  stop();

  /// 停止播放，关闭当前播放资源
  close() async {
    await stop();
    filename.value = null;
  }

  /// 停止播放，关闭播放器，清除播放器
  @override
  void dispose() {
    close();
    super.dispose();
  }

  Widget buildMediaPlayer({
    Key? key,
    bool showClosedCaptionButton = true,
    bool showFullscreenButton = true,
    bool showVolumeButton = true,
  });

  Widget buildPlaylistController() {
    List<Widget> children = [];
    if (playlistController.currentIndex > 0) {
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
    int currentIndex = playlistController.currentIndex;
    if (currentIndex >= 0 && currentIndex < playlistController.length) {
      PlatformMediaSource? platformMediaSource =
          playlistController.get(currentIndex);
      String name = FileUtil.filename(platformMediaSource!.filename);
      children.add(CommonAutoSizeText(
        name,
        style: const TextStyle(color: Colors.white),
        maxLines: 1,
      ));
    }
    if (currentIndex > -1 && currentIndex < playlistController.length - 1) {
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

    return ButtonBar(
      alignment: MainAxisAlignment.spaceBetween,
      children: children,
    );
  }

  String get progressText {
    return '${StringUtil.durationText(mediaPlayerState.position)}/${StringUtil.durationText(mediaPlayerState.duration)}';
  }
}
