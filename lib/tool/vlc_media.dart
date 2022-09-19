import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/material.dart';

class VlcMedia {
  static Media media(String filename) {
    Media media;
    if (filename.startsWith('assets/')) {
      media = Media.asset(filename);
    } else if (filename.startsWith('http')) {
      media = Media.network(filename);
    } else {
      media = Media.file(File(filename));
    }

    return media;
  }

  static Playlist playlist(List<String> filenames) {
    List<Media> medias = [];
    for (var filename in filenames) {
      medias.add(media(filename));
    }
    final playlist = Playlist(
      medias: medias,
    );

    return playlist;
  }
}

///基于vlc实现的媒体播放器和记录器，可以截取视频文件的图片作为缩略图
///支持除macos外的平台，linux需要VLC & libVLC installed.
class VlcMediaPlayer {
  late Player player;

  VlcMediaPlayer({
    int id = 0,
    bool registerTexture = true,
    VideoDimensions? videoDimensions,
    List<String>? commandlineArguments,
    dynamic bool = false,
  }) {
    DartVLC.initialize();
    player = Player(
        id: id,
        registerTexture: registerTexture,
        videoDimensions: videoDimensions,
        commandlineArguments: commandlineArguments,
        bool: bool);
  }

  open(List<String> filenames, {bool autoStart = false}) async {
    final playlist = VlcMedia.playlist(filenames);
    player.open(
      playlist,
      autoStart: autoStart,
    );
  }

  play() {
    player.play();
  }

  seek(Duration duration) {
    player.seek(duration);
  }

  pause() {
    player.pause();
  }

  playOrPause() {
    player.playOrPause();
  }

  stop() {
    player.stop();
  }

  next() {
    player.next();
  }

  previous() {
    player.previous();
  }

  jumpToIndex(int index) {
    player.jumpToIndex(index);
  }

  setVolume(double volume) {
    player.setVolume(volume);
  }

  setRate(double rate) {
    player.setRate(rate);
  }

  List<Device> devices() {
    List<Device> devices = Devices.all;

    return devices;
  }

  setDevice(Device device) {
    player.setDevice(
      device,
    );
  }

  takeSnapshot(
    String filename,
    int width,
    int height,
  ) {
    var file = File(filename);
    player.takeSnapshot(file, width, height);
  }

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
    required int id,
    required Media media,
    required File savingFile,
  }) {
    record = Record.create(
      id: id,
      media: media,
      savingFile: savingFile,
    );
    record!.start();
  }

  dispose() {
    record!.dispose();
  }
}

class VlcMediaPlayerWidget extends StatefulWidget with TileDataMixin {
  const VlcMediaPlayerWidget({super.key});

  @override
  State createState() => _VlcMediaPlayerWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'vlc_media_player';

  @override
  Icon get icon => const Icon(Icons.perm_media);

  @override
  String get title => 'VLC Media Player';
}

class _VlcMediaPlayerWidgetState extends State<VlcMediaPlayerWidget> {
  Player player = Player(
    id: 0,
    videoDimensions: VideoDimensions(640, 360),
    registerTexture: !Platform.isWindows,
  );
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
    if (mounted) {
      player.currentStream.listen((current) {
        setState(() => this.current = current);
      });
      player.positionStream.listen((position) {
        setState(() => this.position = position);
      });
      player.playbackStream.listen((playback) {
        setState(() => this.playback = playback);
      });
      player.generalStream.listen((general) {
        setState(() => this.general = general);
      });
      player.videoDimensionsStream.listen((videoDimensions) {
        setState(() => this.videoDimensions = videoDimensions);
      });
      player.bufferingProgressStream.listen(
        (bufferingProgress) {
          setState(() => this.bufferingProgress = bufferingProgress);
        },
      );
      player.errorStream.listen((event) {
        logger.e('libvlc error.');
      });
      devices = Devices.all;
      Equalizer equalizer = Equalizer.createMode(EqualizerMode.live);
      equalizer.setPreAmp(10.0);
      equalizer.setBandAmp(31.25, 10.0);
      player.setEqualizer(equalizer);
    }
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
    return AppBarView(
      title: const Text('dart_vlc'),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(4.0),
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Platform.isWindows
                  ? NativeVideo(
                      player: player,
                      width: isPhone ? 320 : 640,
                      height: isPhone ? 180 : 360,
                      volumeThumbColor: Colors.blue,
                      volumeActiveColor: Colors.blue,
                      showControls: !isPhone,
                    )
                  : Video(
                      player: player,
                      width: isPhone ? 320 : 640,
                      height: isPhone ? 180 : 360,
                      volumeThumbColor: Colors.blue,
                      volumeActiveColor: Colors.blue,
                      showControls: !isPhone,
                    ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPhone) _controls(context, isPhone),
                    Card(
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
                                      child: TextField(
                                        controller: controller,
                                        cursorWidth: 1.0,
                                        autofocus: true,
                                        style: const TextStyle(
                                          fontSize: 14.0,
                                        ),
                                        decoration:
                                            const InputDecoration.collapsed(
                                          hintStyle: TextStyle(
                                            fontSize: 14.0,
                                          ),
                                          hintText: 'Enter Media path.',
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 152.0,
                                      child: DropdownButton<MediaType>(
                                        value: mediaType,
                                        onChanged: (mediaType) => setState(
                                            () => this.mediaType = mediaType!),
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
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(left: 10.0),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          if (mediaType == MediaType.file) {
                                            medias.add(
                                              Media.file(
                                                File(
                                                  controller.text
                                                      .replaceAll('"', ''),
                                                ),
                                              ),
                                            );
                                          } else if (mediaType ==
                                              MediaType.network) {
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
                                      ),
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
                                          player.open(
                                            Playlist(
                                              medias: medias,
                                              playlistMode: PlaylistMode.single,
                                            ),
                                          );
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
                                        setState(() => this.medias.clear());
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
                    ),
                    Card(
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
                              max: position.duration?.inMilliseconds
                                      .toDouble() ??
                                  1.0,
                              value: position.position?.inMilliseconds
                                      .toDouble() ??
                                  0.0,
                              onChanged: (double position) => player.seek(
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
                    ),
                    Card(
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
                                      onTap: () => player.setDevice(device),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    ),
                    Card(
                      elevation: 2.0,
                      margin: const EdgeInsets.all(4.0),
                      child: Container(
                        margin: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Metas parsing.'),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: metasController,
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
                                  ),
                                ),
                                Container(
                                  width: 152.0,
                                  child: DropdownButton<MediaType>(
                                    value: mediaType,
                                    onChanged: (mediaType) => setState(
                                        () => this.mediaType = mediaType!),
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
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 16.0),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (mediaType == MediaType.file) {
                                        metasMedia = Media.file(
                                          File(metasController.text),
                                          parse: true,
                                        );
                                      } else if (mediaType ==
                                          MediaType.network) {
                                        metasMedia = Media.network(
                                          metasController.text,
                                          parse: true,
                                        );
                                      }
                                      setState(() {});
                                    },
                                    child: const Text(
                                      'Parse',
                                      style: TextStyle(
                                        fontSize: 14.0,
                                      ),
                                    ),
                                  ),
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
                            Text(
                              const JsonEncoder.withIndent('    ')
                                  .convert(metasMedia?.metas),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isPhone) _playlist(context),
                  ],
                ),
              ),
              if (isTablet)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _controls(context, isPhone),
                      _playlist(context),
                    ],
                  ),
                ),
            ],
          )
        ],
      ),
    );
  }

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
                  onPressed: () => this.player.play(),
                  child: const Text(
                    'play',
                    style: TextStyle(
                      fontSize: 14.0,
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                ElevatedButton(
                  onPressed: () => player.pause(),
                  child: const Text(
                    'pause',
                    style: TextStyle(
                      fontSize: 14.0,
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                ElevatedButton(
                  onPressed: () => player.playOrPause(),
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
                  onPressed: () => this.player.stop(),
                  child: const Text(
                    'stop',
                    style: TextStyle(
                      fontSize: 14.0,
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                ElevatedButton(
                  onPressed: () => this.player.next(),
                  child: const Text(
                    'next',
                    style: TextStyle(
                      fontSize: 14.0,
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                ElevatedButton(
                  onPressed: () => this.player.previous(),
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
              value: this.player.general.volume,
              onChanged: (volume) {
                this.player.setVolume(volume);
                this.setState(() {});
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
              value: this.player.general.rate,
              onChanged: (rate) {
                this.player.setRate(rate);
                this.setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

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
                  /// 🙏🙏🙏
                  /// In the name of God,
                  /// With all due respect,
                  /// I ask all Flutter engineers to please fix this issue.
                  /// Peace.
                  /// 🙏🙏🙏
                  ///
                  /// Issue:
                  /// https://github.com/flutter/flutter/issues/24786
                  /// Prevention:
                  /// https://stackoverflow.com/a/54164333/12825435
                  ///
                  if (finalIndex > this.current.medias.length)
                    finalIndex = this.current.medias.length;
                  if (initialIndex < finalIndex) finalIndex--;

                  this.player.move(initialIndex, finalIndex);
                  this.setState(() {});
                },
                scrollDirection: Axis.vertical,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                children: List.generate(
                  this.current.medias.length,
                  (int index) => ListTile(
                    key: Key(index.toString()),
                    leading: Text(
                      index.toString(),
                      style: const TextStyle(fontSize: 14.0),
                    ),
                    title: Text(
                      this.current.medias[index].resource,
                      style: const TextStyle(fontSize: 14.0),
                    ),
                    subtitle: Text(
                      this.current.medias[index].mediaType.toString(),
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
