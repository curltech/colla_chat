import 'dart:async';
import 'dart:typed_data';

import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

enum PlayerStatus { init, buffering, pause, playing, stop, completed }

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
  final MimeType? mediaFormat;
  final MediaSourceType mediaSourceType;

  PlatformMediaSource({
    required this.filename,
    this.mediaFormat,
    required this.mediaSourceType,
  });

  static FutureOr<PlatformMediaSource> media(
      {String? filename, List<int>? data, MimeType? mediaFormat}) async {
    PlatformMediaSource mediaSource;
    if (filename != null) {
      if (mediaFormat == null) {
        int pos = filename.lastIndexOf('.');
        String extension = filename.substring(pos + 1);
        mediaFormat = StringUtil.enumFromString(MimeType.values, extension);
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
    } else {
      data = data ?? Uint8List.fromList([]);
      filename =
          await FileUtil.writeTempFile(data, extension: mediaFormat?.name);
      mediaSource = PlatformMediaSource(
          filename: filename!,
          mediaSourceType: MediaSourceType.buffer,
          mediaFormat: mediaFormat);
    }

    return mediaSource;
  }

  static FutureOr<List<PlatformMediaSource>> playlist(
      List<String> filenames) async {
    List<PlatformMediaSource> playlist = [];
    for (var filename in filenames) {
      playlist.add(await media(filename: filename));
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
  List<PlatformMediaSource> playlist = [];
  bool _playlistVisible = false;
  int _currentIndex = -1;
  FileType fileType = FileType.any;

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

  set currentIndex(int? index) {
    if (index != null && index >= -1 && index < playlist.length) {
      _currentIndex = index;
    }
  }

  ///设置当前的通用MediaSource，子类转换成特定实现的媒体源，并进行设置
  setCurrentIndex(int? index) {
    if (index != null && index >= -1 && index < playlist.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  PlatformMediaSource? get currentMediaSource {
    if (_currentIndex >= 0 && currentIndex < playlist.length) {
      return playlist[_currentIndex];
    }
    return null;
  }

  previous() {
    if (_currentIndex > 0) {
      _currentIndex = _currentIndex - 1;
    }
  }

  next() {
    if (_currentIndex >= 0 && _currentIndex! < playlist.length - 1) {
      _currentIndex = _currentIndex + 1;
    }
  }

  Future<PlatformMediaSource?> add({String? filename, List<int>? data}) async {
    for (var mediaSource in playlist) {
      var name = mediaSource.filename;
      if (name == filename) {
        return null;
      }
    }
    PlatformMediaSource mediaSource =
        await PlatformMediaSource.media(filename: filename, data: data);
    playlist.add(mediaSource);
    await setCurrentIndex(playlist.length - 1);

    return mediaSource;
  }

  Future<PlatformMediaSource?> insert(int index,
      {String? filename, List<int>? data}) async {
    for (var mediaSource in playlist) {
      var name = mediaSource.filename;
      if (name == filename) {
        return null;
      }
    }
    PlatformMediaSource mediaSource =
        await PlatformMediaSource.media(filename: filename, data: data);
    playlist.insert(index, mediaSource);
    await setCurrentIndex(index);

    return mediaSource;
  }

  remove(int index) async {
    if (index >= 0 && index < playlist.length) {
      playlist.removeAt(index);
      if (index == 0) {
        await setCurrentIndex(index);
      } else {
        await setCurrentIndex(index - 1);
      }
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
    final xfiles =
        await FileUtil.pickFiles(allowMultiple: allowMultiple, type: fileType);
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

  @override
  void dispose() {
    close();
    super.dispose();
  }
}
