import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/video/platform_video_player_widget.dart';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/material.dart';

class VlcMediaSource {
  static Future<Media> media({String? filename, Uint8List? data}) async {
    Media media;
    if (filename != null) {
      if (filename.startsWith('assets/')) {
        media = Media.asset(filename);
      } else if (filename.startsWith('http')) {
        media = Media.network(filename);
      } else {
        media = Media.file(File(filename));
      }
    } else {
      data = data ?? Uint8List.fromList([]);
      filename = await FileUtil.writeTempFile(data, '');
      media = Media.file(File(filename));
    }

    return media;
  }

  static Future<Playlist> playlist(List<String> filenames) async {
    List<Media> medias = [];
    for (var filename in filenames) {
      medias.add(await media(filename: filename));
    }
    final playlist = Playlist(
      medias: medias,
    );

    return playlist;
  }
}

///基于vlc实现的媒体播放器和记录器，可以截取视频文件的图片作为缩略图
///支持除macos外的平台，linux需要VLC & libVLC installed.
class VlcVideoPlayerController extends AbstractVideoPlayerController {
  late Player player;
  Playlist playlist = Playlist(medias: []);
  CurrentState current = CurrentState();
  PositionState position = PositionState();
  PlaybackState playback = PlaybackState();
  GeneralState general = GeneralState();
  VideoDimensions videoDimensions = const VideoDimensions(0, 0);
  double bufferingProgress = 0.0;
  List<Media> medias = <Media>[];
  List<Device> devices = Devices.all;

  VlcVideoPlayerController({
    int id = 0,
    bool registerTexture = true,
    VideoDimensions? videoDimensions,
    List<String>? commandlineArguments,
    dynamic bool = false,
  }) {
    player = Player(
        id: id,
        registerTexture: !platformParams.windows,
        videoDimensions: videoDimensions,
        commandlineArguments: commandlineArguments,
        bool: bool);
    player.currentStream.listen((current) {
      this.current = current;
    });
    player.positionStream.listen((position) {
      this.position = position;
    });
    player.playbackStream.listen((playback) {
      this.playback = playback;
    });
    player.generalStream.listen((general) {
      this.general = general;
    });
    player.videoDimensionsStream.listen((videoDimensions) {
      this.videoDimensions = videoDimensions;
    });
    player.bufferingProgressStream.listen(
      (bufferingProgress) {
        this.bufferingProgress = bufferingProgress;
      },
    );
    player.errorStream.listen((event) {
      logger.e('libvlc error.');
    });
    open();
  }

  @override
  open({bool autoStart = false}) {
    player.open(
      playlist,
      autoStart: autoStart,
    );
  }

  ///基本的视频控制功能
  @override
  play() {
    player.play();
  }

  @override
  seek(Duration duration) {
    player.seek(duration);
  }

  @override
  pause() {
    player.pause();
  }

  @override
  playOrPause() {
    player.playOrPause();
  }

  @override
  stop() {
    player.stop();
  }

  @override
  setVolume(double volume) {
    player.setVolume(volume);
  }

  @override
  setRate(double rate) {
    player.setRate(rate);
  }

  @override
  takeSnapshot(
    String filename,
    int width,
    int height,
  ) {
    var file = File(filename);
    player.takeSnapshot(file, width, height);
  }

  @override
  dispose() {
    player.dispose();
  }

  ///下面是播放列表的功能
  @override
  add({String? filename, Uint8List? data}) async {
    Media media = await VlcMediaSource.media(filename: filename, data: data);
    player.add(media);
  }

  @override
  remove(int index) {
    player.remove(index);
  }

  @override
  insert(int index, {String? filename, Uint8List? data}) async {
    Media media = await VlcMediaSource.media(filename: filename, data: data);
    player.insert(index, media);
  }

  @override
  next() {
    player.next();
  }

  @override
  previous() {
    player.previous();
  }

  @override
  jumpToIndex(int index) {
    player.jumpToIndex(index);
  }

  @override
  move(int initialIndex, int finalIndex) {
    player.move(initialIndex, finalIndex);
  }

  @override
  buildVideoWidget({
    Key? key,
    int? playerId,
    Player? player,
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
  }) {
    player = player ?? this.player;
    return Video(
      key: key,
      playerId: playerId,
      player: player,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      scale: scale,
      showControls: showControls,
      progressBarActiveColor: progressBarActiveColor,
      progressBarInactiveColor: progressBarInactiveColor,
      progressBarThumbColor: progressBarThumbColor,
      progressBarThumbGlowColor: progressBarThumbGlowColor,
      volumeActiveColor: volumeActiveColor,
      volumeInactiveColor: volumeInactiveColor,
      volumeBackgroundColor: volumeBackgroundColor,
      volumeThumbColor: volumeThumbColor,
      progressBarThumbRadius: progressBarThumbRadius,
      progressBarThumbGlowRadius: progressBarThumbGlowRadius,
      showTimeLeft: showTimeLeft,
      progressBarTextStyle: progressBarTextStyle,
      filterQuality: filterQuality,
      showFullscreenButton: showFullscreenButton,
      fillColor: fillColor,
    );
  }

  NativeVideo buildNativeVideoWidget({
    Key? key,
    Player? player,
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
  }) {
    player = player ?? this.player;
    return NativeVideo(
      key: key,
      player: player,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      scale: scale,
      showControls: showControls,
      progressBarActiveColor: progressBarActiveColor,
      progressBarInactiveColor: progressBarInactiveColor,
      progressBarThumbColor: progressBarThumbColor,
      progressBarThumbGlowColor: progressBarThumbGlowColor,
      volumeActiveColor: volumeActiveColor,
      volumeInactiveColor: volumeInactiveColor,
      volumeBackgroundColor: volumeBackgroundColor,
      volumeThumbColor: volumeThumbColor,
      progressBarThumbRadius: progressBarThumbRadius,
      progressBarThumbGlowRadius: progressBarThumbGlowRadius,
      showTimeLeft: showTimeLeft,
      progressBarTextStyle: progressBarTextStyle,
      filterQuality: filterQuality,
    );
  }

  setEqualizer({double? band, double? preAmp, double? amp}) {
    Equalizer equalizer = Equalizer.createEmpty();
    if (preAmp != null) {
      equalizer.setPreAmp(preAmp);
    }
    if (band != null && amp != null) {
      equalizer.setBandAmp(band, amp);
    }
    player.setEqualizer(equalizer);
  }

  Broadcast broadcast({
    required int id,
    required Media media,
    required BroadcastConfiguration configuration,
  }) {
    final broadcast = Broadcast.create(
      id: 0,
      media: Media.file(File('C:/video.mp4')),
      configuration: const BroadcastConfiguration(
        access: 'http',
        mux: 'mpeg1',
        dst: '127.0.0.1:8080',
        vcodec: 'mp1v',
        vb: 1024,
        acodec: 'mpga',
        ab: 128,
      ),
    );
    broadcast.start();
    broadcast.dispose();
    return broadcast;
  }
}

class VlcMediaRecorder {
  Record? record;

  VlcMediaRecorder();

  start({
    int id = 0,
    required String filename,
    required File savingFile,
  }) async {
    if (record != null) {
      dispose();
    }
    Media media = await VlcMediaSource.media(filename: filename);
    record = Record.create(
      id: id,
      media: media,
      savingFile: savingFile,
    );
    record!.start();
  }

  dispose() {
    if (record != null) {
      record!.dispose();
      record = null;
    }
  }
}

class PlatformVlcVideoPlayerWidget extends StatefulWidget {
  final VlcVideoPlayerController controller;

  const PlatformVlcVideoPlayerWidget({super.key, required this.controller});

  @override
  State createState() => _PlatformVlcVideoPlayerWidgetState();
}

class _PlatformVlcVideoPlayerWidgetState
    extends State<PlatformVlcVideoPlayerWidget> {
  MediaType mediaType = MediaType.file;
  CurrentState current = CurrentState();
  PositionState position = PositionState();
  PlaybackState playback = PlaybackState();
  GeneralState general = GeneralState();
  VideoDimensions videoDimensions = const VideoDimensions(0, 0);
  List<Media> medias = <Media>[];
  List<Device> devices = <Device>[];
  TextEditingController controller = TextEditingController();
  TextEditingController metasController = TextEditingController();
  double bufferingProgress = 0.0;
  Media? metasMedia;

  @override
  void initState() {
    super.initState();
  }

  _isTablet() {
    bool isTablet = false;
    final double devicePixelRatio = ui.window.devicePixelRatio;
    final double width = ui.window.physicalSize.width;
    final double height = ui.window.physicalSize.height;
    if (devicePixelRatio < 2 && (width >= 1000 || height >= 1000)) {
      isTablet = true;
    } else if (devicePixelRatio == 2 && (width >= 1920 || height >= 1920)) {
      isTablet = true;
    } else {
      isTablet = false;
    }

    return isTablet;
  }

  _isPhone() {
    bool isPhone = false;
    final double devicePixelRatio = ui.window.devicePixelRatio;
    final double width = ui.window.physicalSize.width;
    final double height = ui.window.physicalSize.height;
    if (devicePixelRatio < 2 && (width >= 1000 || height >= 1000)) {
      isPhone = false;
    } else if (devicePixelRatio == 2 && (width >= 1920 || height >= 1920)) {
      isPhone = false;
    } else {
      isPhone = true;
    }

    return isPhone;
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = _isTablet();
    bool isPhone = _isPhone();
    return _buildVideoView(isPhone);
  }

  Card _buildDeviceCard() {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.all(4.0),
      child: Container(
        margin: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
                Text('Playback devices.'),
                Divider(
                  height: 12.0,
                  color: Colors.transparent,
                ),
                Divider(
                  height: 12.0,
                ),
              ] +
              devices
                  .map(
                    (device) => ListTile(
                      title: Text(
                        device.name,
                        style: const TextStyle(
                          fontSize: 14.0,
                        ),
                      ),
                      subtitle: Text(
                        device.id,
                        style: const TextStyle(
                          fontSize: 14.0,
                        ),
                      ),
                      onTap: () => widget.controller.player.setDevice(device),
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }

  Card _buildEventCard() {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.all(4.0),
      child: Container(
        margin: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Playback event listeners.'),
            const Divider(
              height: 12.0,
              color: Colors.transparent,
            ),
            const Divider(
              height: 12.0,
            ),
            const Text('Playback position.'),
            const Divider(
              height: 8.0,
              color: Colors.transparent,
            ),
            Slider(
              min: 0,
              max: position.duration?.inMilliseconds.toDouble() ?? 1.0,
              value: position.position?.inMilliseconds.toDouble() ?? 0.0,
              onChanged: (double position) => widget.controller.seek(
                Duration(
                  milliseconds: position.toInt(),
                ),
              ),
            ),
            const Text('Event streams.'),
            const Divider(
              height: 8.0,
              color: Colors.transparent,
            ),
            Table(
              children: [
                TableRow(
                  children: [
                    const Text('player.general.volume'),
                    Text('${general.volume}')
                  ],
                ),
                TableRow(
                  children: [
                    const Text('player.general.rate'),
                    Text('${general.rate}')
                  ],
                ),
                TableRow(
                  children: [
                    const Text('player.position.position'),
                    Text('${position.position}')
                  ],
                ),
                TableRow(
                  children: [
                    const Text('player.position.duration'),
                    Text('${position.duration}')
                  ],
                ),
                TableRow(
                  children: [
                    const Text('player.playback.isCompleted'),
                    Text('${playback.isCompleted}')
                  ],
                ),
                TableRow(
                  children: [
                    const Text('player.playback.isPlaying'),
                    Text('${playback.isPlaying}')
                  ],
                ),
                TableRow(
                  children: [
                    const Text('player.playback.isSeekable'),
                    Text('${playback.isSeekable}')
                  ],
                ),
                TableRow(
                  children: [
                    const Text('player.current.index'),
                    Text('${current.index}')
                  ],
                ),
                TableRow(
                  children: [
                    const Text('player.current.media'),
                    Text('${current.media}')
                  ],
                ),
                TableRow(
                  children: [
                    const Text('player.current.medias'),
                    Text('${current.medias}')
                  ],
                ),
                TableRow(
                  children: [
                    const Text('player.videoDimensions'),
                    Text('${videoDimensions}')
                  ],
                ),
                TableRow(
                  children: [
                    const Text('player.bufferingProgress'),
                    Text('$bufferingProgress')
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Card _buildPlaylistCard() {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.all(4.0),
      child: Container(
        margin: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
                const Text('Playlist creation.'),
                const Divider(
                  height: 8.0,
                  color: Colors.transparent,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildMediaPath(),
                    ),
                    _buildMediaTypeSelector(),
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: _buildPlaylistButton(),
                    ),
                  ],
                ),
                const Divider(
                  height: 12.0,
                ),
                const Divider(
                  height: 8.0,
                  color: Colors.transparent,
                ),
                const Text('Playlist'),
              ] +
              medias
                  .map(
                    (media) => ListTile(
                      title: Text(
                        media.resource,
                        style: const TextStyle(
                          fontSize: 14.0,
                        ),
                      ),
                      subtitle: Text(
                        media.mediaType.toString(),
                        style: const TextStyle(
                          fontSize: 14.0,
                        ),
                      ),
                    ),
                  )
                  .toList() +
              <Widget>[
                const Divider(
                  height: 8.0,
                  color: Colors.transparent,
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => setState(
                        () {
                          widget.controller.open();
                        },
                      ),
                      child: const Text(
                        'Open into Player',
                        style: TextStyle(
                          fontSize: 14.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => medias.clear());
                      },
                      child: const Text(
                        'Clear the list',
                        style: TextStyle(
                          fontSize: 14.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
        ),
      ),
    );
  }

  ElevatedButton _buildPlaylistButton() {
    return ElevatedButton(
      onPressed: () {
        if (mediaType == MediaType.file) {
          medias.add(
            Media.file(
              File(
                controller.text.replaceAll('"', ''),
              ),
            ),
          );
        } else if (mediaType == MediaType.network) {
          medias.add(
            Media.network(
              controller.text,
            ),
          );
        }
        setState(() {});
      },
      child: const Text(
        'Add to Playlist',
        style: TextStyle(
          fontSize: 14.0,
        ),
      ),
    );
  }

  TextField _buildMediaPath() {
    return TextField(
      controller: controller,
      cursorWidth: 1.0,
      autofocus: true,
      style: const TextStyle(
        fontSize: 14.0,
      ),
      decoration: const InputDecoration.collapsed(
        hintStyle: TextStyle(
          fontSize: 14.0,
        ),
        hintText: 'Enter Media path.',
      ),
    );
  }

  Container _buildMediaTypeSelector() {
    return Container(
      width: 152.0,
      child: DropdownButton<MediaType>(
        value: mediaType,
        onChanged: (mediaType) => setState(() => this.mediaType = mediaType!),
        items: [
          DropdownMenuItem<MediaType>(
            value: MediaType.file,
            child: Text(
              MediaType.file.toString(),
              style: const TextStyle(
                fontSize: 14.0,
              ),
            ),
          ),
          DropdownMenuItem<MediaType>(
            value: MediaType.network,
            child: Text(
              MediaType.network.toString(),
              style: const TextStyle(
                fontSize: 14.0,
              ),
            ),
          ),
          DropdownMenuItem<MediaType>(
            value: MediaType.asset,
            child: Text(
              MediaType.asset.toString(),
              style: const TextStyle(
                fontSize: 14.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Row _buildVideoView(bool isPhone) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Platform.isWindows
            ? NativeVideo(
                player: widget.controller.player,
                width: isPhone ? 320 : 640,
                height: isPhone ? 180 : 360,
                volumeThumbColor: Colors.blue,
                volumeActiveColor: Colors.blue,
                showControls: true,
              )
            : Video(
                player: widget.controller.player,
                width: isPhone ? 320 : 640,
                height: isPhone ? 180 : 360,
                volumeThumbColor: Colors.blue,
                volumeActiveColor: Colors.blue,
                showControls: true,
              ),
      ],
    );
  }

  ///视频操控面板，各种操控按钮组成
  Widget _controls(BuildContext context, bool isPhone) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.all(4.0),
      child: Container(
        margin: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Playback controls.'),
            const Divider(
              height: 8.0,
              color: Colors.transparent,
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => widget.controller.play(),
                  child: const Text(
                    'play',
                    style: TextStyle(
                      fontSize: 14.0,
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                ElevatedButton(
                  onPressed: () => widget.controller.pause(),
                  child: const Text(
                    'pause',
                    style: TextStyle(
                      fontSize: 14.0,
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                ElevatedButton(
                  onPressed: () => widget.controller.playOrPause(),
                  child: const Text(
                    'playOrPause',
                    style: TextStyle(
                      fontSize: 14.0,
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
              ],
            ),
            const SizedBox(
              height: 8.0,
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => widget.controller.stop(),
                  child: const Text(
                    'stop',
                    style: TextStyle(
                      fontSize: 14.0,
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                ElevatedButton(
                  onPressed: () => widget.controller.next(),
                  child: const Text(
                    'next',
                    style: TextStyle(
                      fontSize: 14.0,
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                ElevatedButton(
                  onPressed: () => widget.controller.previous(),
                  child: const Text(
                    'previous',
                    style: TextStyle(
                      fontSize: 14.0,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(
              height: 12.0,
              color: Colors.transparent,
            ),
            const Divider(
              height: 12.0,
            ),
            const Text('Volume control.'),
            const Divider(
              height: 8.0,
              color: Colors.transparent,
            ),
            Slider(
              min: 0.0,
              max: 1.0,
              value: widget.controller.player.general.volume,
              onChanged: (volume) {
                widget.controller.setVolume(volume);
                setState(() {});
              },
            ),
            const Text('Playback rate control.'),
            const Divider(
              height: 8.0,
              color: Colors.transparent,
            ),
            Slider(
              min: 0.5,
              max: 1.5,
              value: widget.controller.general.rate,
              onChanged: (rate) {
                widget.controller.setRate(rate);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  ///播放列表，使用拖拽排序列表组件
  Widget _playlist(BuildContext context) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.all(4.0),
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(left: 16.0, top: 16.0),
              alignment: Alignment.topLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Playlist manipulation.'),
                  Divider(
                    height: 12.0,
                    color: Colors.transparent,
                  ),
                  Divider(
                    height: 12.0,
                  ),
                ],
              ),
            ),
            Container(
              height: 456.0,
              child: ReorderableListView(
                shrinkWrap: true,
                onReorder: (int initialIndex, int finalIndex) async {
                  if (finalIndex > current.medias.length) {
                    finalIndex = current.medias.length;
                  }
                  if (initialIndex < finalIndex) finalIndex--;

                  widget.controller.move(initialIndex, finalIndex);
                  setState(() {});
                },
                scrollDirection: Axis.vertical,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                children: List.generate(
                  current.medias.length,
                  (int index) => ListTile(
                    key: Key(index.toString()),
                    leading: Text(
                      index.toString(),
                      style: const TextStyle(fontSize: 14.0),
                    ),
                    title: Text(
                      current.medias[index].resource,
                      style: const TextStyle(fontSize: 14.0),
                    ),
                    subtitle: Text(
                      current.medias[index].mediaType.toString(),
                      style: const TextStyle(fontSize: 14.0),
                    ),
                  ),
                  growable: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
