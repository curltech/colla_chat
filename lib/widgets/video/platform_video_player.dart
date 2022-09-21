import 'dart:typed_data';

import 'package:colla_chat/platform.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/video/platform_flick_video_player.dart';
import 'package:colla_chat/widgets/video/platform_vlc_video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

abstract class AbstractVideoPlayerController {
  open({bool autoStart = false});

  ///基本的视频控制功能
  play();

  seek(Duration duration);

  pause();

  playOrPause();

  stop();

  setVolume(double volume);

  setRate(double rate);

  takeSnapshot(
    String filename,
    int width,
    int height,
  );

  dispose();

  ///下面是播放列表的功能
  add({String? filename, Uint8List? data});

  remove(int index);

  insert(int index, {String? filename, Uint8List? data});

  next();

  previous();

  jumpToIndex(int index);

  move(int initialIndex, int finalIndex);

  sourceFilePicker({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.video,
    List<String>? allowedExtensions,
    dynamic Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    bool allowMultiple = true,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
  }) async {
    final filenames =
        await FileUtil.pickFiles(allowMultiple: allowMultiple, type: type);
    if (filenames.isNotEmpty) {
      for (var filename in filenames) {
        add(filename: filename);
      }
    }
  }

  buildVideoWidget({
    Key? key,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    double scale = 1.0,
    bool showControls = true,
    Color? progressBarActiveColor,
    Color? progressBarInactiveColor = Colors.white24,
    Color? progressBarThumbColor,
    Color? progressBarThumbGlowColor = const Color.fromRGBO(0, 161, 214, .2),
    Color? volumeActiveColor,
    Color? volumeInactiveColor = Colors.grey,
    Color volumeBackgroundColor = const Color(0xff424242),
    Color? volumeThumbColor,
    double? progressBarThumbRadius = 10.0,
    double? progressBarThumbGlowRadius = 15.0,
    bool showTimeLeft = false,
    TextStyle progressBarTextStyle = const TextStyle(),
    FilterQuality filterQuality = FilterQuality.low,
    bool showFullscreenButton = false,
    Color fillColor = Colors.black,
  });
}

class PlatformVideoPlayerController extends AbstractVideoPlayerController {
  List<String>? _filenames;
  String? _filename;
  late AbstractVideoPlayerController controller;

  PlatformVideoPlayerController() {
    if (platformParams.ios || platformParams.android || platformParams.web) {
      controller = FlickVideoPlayerController();
    } else {
      controller = VlcVideoPlayerController();
    }
  }

  set filename(String filename) {
    _filename = filename;
  }

  @override
  add({String? filename, Uint8List? data}) {
    controller.add(filename: filename, data: data);
  }

  @override
  buildVideoWidget(
      {Key? key,
      double? width,
      double? height,
      BoxFit fit = BoxFit.contain,
      AlignmentGeometry alignment = Alignment.center,
      double scale = 1.0,
      bool showControls = true,
      Color? progressBarActiveColor,
      Color? progressBarInactiveColor = Colors.white24,
      Color? progressBarThumbColor,
      Color? progressBarThumbGlowColor = const Color.fromRGBO(0, 161, 214, .2),
      Color? volumeActiveColor,
      Color? volumeInactiveColor = Colors.grey,
      Color volumeBackgroundColor = const Color(0xff424242),
      Color? volumeThumbColor,
      double? progressBarThumbRadius = 10.0,
      double? progressBarThumbGlowRadius = 15.0,
      bool showTimeLeft = false,
      TextStyle progressBarTextStyle = const TextStyle(),
      FilterQuality filterQuality = FilterQuality.low,
      bool showFullscreenButton = false,
      Color fillColor = Colors.black}) {
    // TODO: implement buildVideoWidget
    throw UnimplementedError();
  }

  @override
  dispose() {
    controller.dispose();
  }

  @override
  insert(int index, {String? filename, Uint8List? data}) {
    controller.insert(index, filename: filename, data: data);
  }

  @override
  jumpToIndex(int index) {
    controller.jumpToIndex(index);
  }

  @override
  move(int initialIndex, int finalIndex) {
    controller.move(initialIndex, finalIndex);
  }

  @override
  next() {
    controller.next();
  }

  @override
  open({bool autoStart = false}) {
    controller.open();
  }

  @override
  pause() {
    controller.pause();
  }

  @override
  play() {
    controller.play();
  }

  @override
  playOrPause() {
    controller.playOrPause();
  }

  @override
  previous() {
    controller.previous();
  }

  @override
  remove(int index) {
    controller.remove(index);
  }

  @override
  seek(Duration duration) {
    controller.seek(duration);
  }

  @override
  setRate(double rate) {
    controller.setRate(rate);
  }

  @override
  setVolume(double volume) {
    controller.setVolume(volume);
  }

  @override
  stop() {
    controller.stop();
  }

  @override
  takeSnapshot(String filename, int width, int height) {
    controller.takeSnapshot(filename, width, height);
  }
}

///平台标准的video-player的实现，移动采用flick，桌面采用vlc
class PlatformVideoPlayer extends StatefulWidget {
  late final PlatformVideoPlayerController controller;

  PlatformVideoPlayer({Key? key, PlatformVideoPlayerController? controller})
      : super(key: key) {
    controller = controller ?? PlatformVideoPlayerController();
  }

  @override
  State createState() => _PlatformVideoPlayerState();
}

class _PlatformVideoPlayerState extends State<PlatformVideoPlayer> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    PlatformVideoPlayerController platformVideoPlayerController =
        PlatformVideoPlayerController();
    if (platformParams.ios || platformParams.android || platformParams.web) {
      var player = PlatformFlickVideoPlayer(
          controller: platformVideoPlayerController.controller
              as FlickVideoPlayerController);
      return player;
    } else {
      var player = PlatformVlcVideoPlayer(
        controller: platformVideoPlayerController.controller
            as VlcVideoPlayerController,
      );
      return player;
    }
  }
}
