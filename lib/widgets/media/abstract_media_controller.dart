import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

enum RecorderStatus { pause, recording, stop }

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

  static Future<PlatformMediaSource> media(
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

  static Future<List<PlatformMediaSource>> playlist(
      List<String> filenames) async {
    List<PlatformMediaSource> playlist = [];
    for (var filename in filenames) {
      playlist.add(await media(filename: filename));
    }

    return playlist;
  }
}

///定义音频录音控制器的接口
///支持多种设备，windows测试通过
///Android, iOS, Linux, macOS, Windows, and web.
abstract class AbstractAudioRecorderController with ChangeNotifier {
  String? filename;
  RecorderStatus _status = RecorderStatus.stop;
  Timer? _timer;
  int _duration = -1;
  String _durationText = '';

  Future<bool> hasPermission();

  RecorderStatus get status {
    return _status;
  }

  set status(RecorderStatus status) {
    if (_status != status) {
      _status = status;
      notifyListeners();
    }
  }

  Future<void> start({String? filename}) async {
    if (filename == null) {
      final dir = await getTemporaryDirectory();
      var name = DateUtil.currentDate();
      filename = '${dir.path}/$name.mp3';
    }
    this.filename = filename;
    startTimer();
  }

  Future<String?> stop() async {
    cancelTimer();

    return null;
  }

  Future<void> pause();

  Future<void> resume();

  @override
  dispose() {
    super.dispose();
    cancelTimer();
  }

  void startTimer() {
    cancelTimer();

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (status == RecorderStatus.recording) {
        duration = duration + 1;
        notifyListeners();
      }
    });
  }

  void cancelTimer() {
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
      duration = 0;
    }
  }

  int get duration {
    return _duration;
  }

  set duration(int duration) {
    if (_duration != duration) {
      _duration = duration;
      _changeDurationText();
    }
  }

  String get durationText {
    return _durationText;
  }

  _changeDurationText() {
    var duration = Duration(seconds: _duration);
    var durationText = duration.toString();
    var pos = durationText.lastIndexOf('.');
    durationText = durationText.substring(0, pos);
    //'${duration.inHours}:${duration.inMinutes}:${duration.inSeconds}';

    _durationText = durationText;
  }
}

///定义通用媒体播放控制器的接口，包含音频和视频
abstract class AbstractMediaPlayerController with ChangeNotifier {
  List<PlatformMediaSource> playlist = [];
  bool _playlistVisible = true;
  bool _speedSlideVisible = false;
  bool _volumeSlideVisible = false;
  bool autoPlay = false;
  int? _currentIndex;
  PlayerStatus _status = PlayerStatus.init;

  bool get playlistVisible {
    return _playlistVisible;
  }

  set playlistVisible(bool playlistVisible) {
    _playlistVisible = playlistVisible;
    notifyListeners();
  }

  bool get volumeSlideVisible {
    return _volumeSlideVisible;
  }

  set volumeSlideVisible(bool volumeSlideVisible) {
    _volumeSlideVisible = volumeSlideVisible;
    if (_volumeSlideVisible) {
      _speedSlideVisible = false;
    }
    notifyListeners();
  }

  bool get speedSlideVisible {
    return _speedSlideVisible;
  }

  set speedSlideVisible(bool speedSlideVisible) {
    _speedSlideVisible = speedSlideVisible;
    if (_speedSlideVisible) {
      _volumeSlideVisible = false;
    }
    notifyListeners();
  }

  int? get currentIndex {
    return _currentIndex;
  }

  ///设置当前的通用MediaSource，子类转换成特定实现的媒体源，并进行设置
  setCurrentIndex(int? index) {
    close();
    if (index != _currentIndex) {
      _currentIndex = index;
    }
    notifyListeners();
  }

  PlatformMediaSource? get currentMediaSource {
    if (_currentIndex != null) {
      return playlist[_currentIndex!];
    }
    return null;
  }

  next() {
    if (_currentIndex != null) {
      setCurrentIndex(_currentIndex! + 1);
    }
  }

  previous() {
    if (_currentIndex != null) {
      setCurrentIndex(_currentIndex! - 1);
    }
  }

  PlayerStatus get status {
    return _status;
  }

  set status(PlayerStatus status) {
    if (_status != status) {
      _status = status;
      notifyListeners();
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
    playlist.removeAt(index);
    if (index == 0) {
      await setCurrentIndex(index);
    } else {
      await setCurrentIndex(index - 1);
    }
  }

  move(int initialIndex, int finalIndex) {
    var mediaSource = playlist[initialIndex];
    playlist[initialIndex] = playlist[finalIndex];
    playlist[finalIndex] = mediaSource;
  }

  play();

  pause();

  stop();

  resume();

  close();

  @override
  dispose();

  seek(Duration position, {int? index});

  setShuffleModeEnabled(bool enabled);

  Future<Duration?> getDuration();

  Future<Duration?> getPosition();

  Future<Duration?> getBufferedPosition();

  Future<double> getVolume();

  setVolume(double volume);

  Future<double> getSpeed();

  setSpeed(double speed);

  Future<List<PlatformMediaSource>> sourceFilePicker({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.audio,
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
        await FileUtil.pickFiles(allowMultiple: allowMultiple, type: type);
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

  Widget buildMediaView({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    double scale = 1.0,
    bool showControls = true,
  });

  ///异步产生波形图形组件
  Future<StreamBuilder<WaveformProgress>> buildWaveformProgress(
      String filename) async {
    var data = await FileUtil.readFile(filename);
    final progressStream = BehaviorSubject<WaveformProgress>();
    final audioFile =
        File(p.join((await getTemporaryDirectory()).path, 'waveform.mp3'));
    try {
      await audioFile.writeAsBytes(data);
      final waveFile =
          File(p.join((await getTemporaryDirectory()).path, 'waveform.wave'));
      JustWaveform.extract(
        audioInFile: audioFile,
        waveOutFile: waveFile,
        zoom: const WaveformZoom.pixelsPerSecond(100),
      );
      progressStream.listen(progressStream.add,
          onError: progressStream.addError);
    } catch (e) {
      progressStream.addError(e);
    }
    return StreamBuilder<WaveformProgress>(
      stream: progressStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: Theme.of(context).textTheme.headline6,
              textAlign: TextAlign.center,
            ),
          );
        }
        final progress = snapshot.data?.progress ?? 0.0;
        final waveform = snapshot.data?.waveform;
        if (waveform == null) {
          return Center(
            child: Text(
              '${(100 * progress).toInt()}%',
              style: Theme.of(context).textTheme.headline6,
            ),
          );
        }
        return buildAudioWaveformPainter(
          context,
          waveform: waveform,
          start: Duration.zero,
          duration: waveform.duration,
        );
      },
    );
  }

  ///波形图形组件
  Widget buildAudioWaveformPainter(
    BuildContext context, {
    required Waveform waveform,
    required Duration start,
    required Duration duration,
    Color waveColor = Colors.blue,
    double scale = 1.0,
    double strokeWidth = 5.0,
    double pixelsPerStep = 8.0,
  }) {
    return ClipRect(
      child: CustomPaint(
        painter: AudioWaveformPainter(
          waveColor: waveColor,
          waveform: waveform,
          start: start,
          duration: duration,
          scale: scale,
          strokeWidth: strokeWidth,
          pixelsPerStep: pixelsPerStep,
        ),
      ),
    );
  }
}

class AudioWaveformPainter extends CustomPainter {
  final double scale;
  final double strokeWidth;
  final double pixelsPerStep;
  final Paint wavePaint;
  final Waveform waveform;
  final Duration start;
  final Duration duration;

  AudioWaveformPainter({
    required this.waveform,
    required this.start,
    required this.duration,
    Color waveColor = Colors.blue,
    this.scale = 1.0,
    this.strokeWidth = 5.0,
    this.pixelsPerStep = 8.0,
  }) : wavePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = waveColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (duration == Duration.zero) return;

    double width = size.width;
    double height = size.height;

    final waveformPixelsPerWindow = waveform.positionToPixel(duration).toInt();
    final waveformPixelsPerDevicePixel = waveformPixelsPerWindow / width;
    final waveformPixelsPerStep = waveformPixelsPerDevicePixel * pixelsPerStep;
    final sampleOffset = waveform.positionToPixel(start);
    final sampleStart = -sampleOffset % waveformPixelsPerStep;
    for (var i = sampleStart.toDouble();
        i <= waveformPixelsPerWindow + 1.0;
        i += waveformPixelsPerStep) {
      final sampleIdx = (sampleOffset + i).toInt();
      final x = i / waveformPixelsPerDevicePixel;
      final minY = normalise(waveform.getPixelMin(sampleIdx), height);
      final maxY = normalise(waveform.getPixelMax(sampleIdx), height);
      canvas.drawLine(
        Offset(x + strokeWidth / 2, max(strokeWidth * 0.75, minY)),
        Offset(x + strokeWidth / 2, min(height - strokeWidth * 0.75, maxY)),
        wavePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AudioWaveformPainter oldDelegate) {
    return false;
  }

  double normalise(int s, double height) {
    if (waveform.flags == 0) {
      final y = 32768 + (scale * s).clamp(-32768.0, 32767.0).toDouble();
      return height - 1 - y * height / 65536;
    } else {
      final y = 128 + (scale * s).clamp(-128.0, 127.0).toDouble();
      return height - 1 - y * height / 256;
    }
  }
}
