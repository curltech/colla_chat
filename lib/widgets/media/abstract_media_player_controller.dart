import 'dart:async';
import 'dart:typed_data';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:file_picker/file_picker.dart';
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
  final ChatMessageMimeType? mediaFormat;
  final MediaSourceType mediaSourceType;

  //下面两个字段用于媒体收藏功能
  String? messageId;
  Widget? thumbnail;

  PlatformMediaSource({
    required this.filename,
    required this.mediaSourceType,
    this.mediaFormat,
    this.messageId,
    this.thumbnail,
  });

  static FutureOr<PlatformMediaSource?> mediaStream(
      {required Uint8List data,
      required ChatMessageMimeType mediaFormat}) async {
    String? filename =
        await FileUtil.writeTempFile(data, extension: mediaFormat.name);
    PlatformMediaSource? mediaSource = PlatformMediaSource(
        filename: filename!,
        mediaSourceType: MediaSourceType.buffer,
        mediaFormat: mediaFormat);

    return mediaSource;
  }

  static PlatformMediaSource? media(
      {required String filename, ChatMessageMimeType? mediaFormat}) {
    PlatformMediaSource mediaSource;
    if (mediaFormat == null) {
      int pos = filename.lastIndexOf('.');
      String extension = filename.substring(pos + 1);
      mediaFormat =
          StringUtil.enumFromString(ChatMessageMimeType.values, extension);
    }
    if (mediaFormat == null) {
      return null;
    }
    if (filename.startsWith('assets')) {
      mediaSource = PlatformMediaSource(
          filename: filename,
          mediaSourceType: MediaSourceType.asset,
          mediaFormat: mediaFormat);
    } else if (filename.startsWith('http')) {
      mediaSource = PlatformMediaSource(
          filename: filename,
          mediaSourceType: MediaSourceType.network,
          mediaFormat: mediaFormat);
    } else {
      mediaSource = PlatformMediaSource(
          filename: filename,
          mediaSourceType: MediaSourceType.file,
          mediaFormat: mediaFormat);
    }

    return mediaSource;
  }

  static List<PlatformMediaSource> playlist(List<String> filenames) {
    List<PlatformMediaSource> playlist = [];
    for (var filename in filenames) {
      PlatformMediaSource? mediaSource = media(filename: filename);
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
  List<PlatformMediaSource> playlist = [];
  bool _playlistVisible = true;
  int _currentIndex = -1;
  FileType fileType = FileType.any;
  List<String>? allowedExtensions;
  MediaPlayerState mediaPlayerState = MediaPlayerState();
  bool autoplay = false;

  AbstractMediaPlayerController();

  bool get playlistVisible {
    return _playlistVisible;
  }

  set playlistVisible(bool playlistVisible) {
    _playlistVisible = playlistVisible;
    notifyListeners();
  }

  int get currentIndex {
    return _currentIndex;
  }

  setCurrentIndex(int index) async {
    if (index >= -1 && index < playlist.length && _currentIndex != index) {
      _currentIndex = index;
    }
  }

  PlatformMediaSource? get currentMediaSource {
    if (_currentIndex >= 0 && currentIndex < playlist.length) {
      return playlist[_currentIndex];
    }
    return null;
  }

  previous() async {
    if (currentIndex <= 0) {
      return;
    }
    await setCurrentIndex(_currentIndex - 1);
  }

  next() async {
    if (currentIndex == -1 || currentIndex >= playlist.length - 1) {
      return;
    }
    await setCurrentIndex(_currentIndex + 1);
  }

  Future<PlatformMediaSource?> add(
      {required String filename, String? messageId, Widget? thumbnail}) async {
    for (var mediaSource in playlist) {
      var name = mediaSource.filename;
      if (name == filename) {
        return null;
      }
    }
    PlatformMediaSource? mediaSource =
        PlatformMediaSource.media(filename: filename);
    if (mediaSource != null) {
      mediaSource.messageId = messageId;
      mediaSource.thumbnail = thumbnail;
      playlist.add(mediaSource);
      await setCurrentIndex(playlist.length - 1);
    }

    return mediaSource;
  }

  Future<List<PlatformMediaSource>> addAll(
      {required List<String> filenames,
      List<String?>? messageIds,
      List<Widget?>? thumbnails}) async {
    List<PlatformMediaSource> mediaSources =
        PlatformMediaSource.playlist(filenames);
    if (messageIds != null && messageIds.isNotEmpty) {
      for (var i = 0; i < mediaSources.length; i++) {
        var mediaSource = mediaSources[i];
        if (messageIds.length > i) {
          mediaSource.messageId = messageIds[i];
        }
        if (thumbnails != null && thumbnails.length > i) {
          mediaSource.thumbnail = thumbnails[i];
        }
      }
    }
    playlist.addAll(mediaSources);
    if (playlist.isNotEmpty) {
      await setCurrentIndex(playlist.length - 1);
    }

    return mediaSources;
  }

  clear() {
    close();
    playlist.clear();
    _currentIndex = -1;
  }

  Future<PlatformMediaSource?> insert(int index,
      {required String filename}) async {
    for (var mediaSource in playlist) {
      var name = mediaSource.filename;
      if (name == filename) {
        return null;
      }
    }
    PlatformMediaSource? mediaSource =
        PlatformMediaSource.media(filename: filename);
    if (mediaSource != null) {
      playlist.insert(index, mediaSource);
      await setCurrentIndex(index);
    }

    return mediaSource;
  }

  remove(int index) async {
    if (index >= 0 && index < playlist.length) {
      playlist.removeAt(index);
      await setCurrentIndex(index - 1);
    }
  }

  move(int initialIndex, int finalIndex) {
    var mediaSource = playlist[initialIndex];
    playlist[initialIndex] = playlist[finalIndex];
    playlist[finalIndex] = mediaSource;
  }

  Future<List<PlatformMediaSource>> sourceFilePicker({
    String? dialogTitle,
    String? initialDirectory,
    List<String>? allowedExtensions,
    dynamic Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    bool allowMultiple = true,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
  }) async {
    List<PlatformMediaSource> mediaSources = [];
    final xfiles = await FileUtil.pickFiles(
        allowMultiple: allowMultiple,
        type: fileType,
        allowedExtensions: this.allowedExtensions);
    if (xfiles.isNotEmpty) {
      for (var xfile in xfiles) {
        PlatformMediaSource? mediaSource = await add(filename: xfile.path);
        if (mediaSource != null) {
          mediaSources.add(mediaSource);
        }
      }
    }

    return mediaSources;
  }

  close() {}

  Widget buildMediaPlayer({
    Key? key,
    bool showClosedCaptionButton = true,
    bool showFullscreenButton = true,
    bool showVolumeButton = true,
  });

  String get progressText {
    return '${StringUtil.durationText(mediaPlayerState.position)}/${StringUtil.durationText(mediaPlayerState.duration)}';
  }

  @override
  void dispose() {
    close();
    super.dispose();
  }
}
