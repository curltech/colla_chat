import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/common/app_bar_adaptive_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/media/playlist_widget.dart';
import 'package:colla_chat/widgets/media_editor/pro_video_render.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart' hide AudioTrack;
import 'package:media_kit/src/player/player.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:pro_video_editor/pro_video_editor.dart';
import 'package:intl/intl.dart';

import 'package:colla_chat/plugin/talker_logger.dart';

/// 通用的视频编辑界面，使用pro_video_editor
class ProVideoEditorWidget extends StatelessWidget with DataTileMixin {
  ProVideoEditorWidget({super.key}) {
    _init();
  }

  @override
  String get routeName => 'pro_video_editor';

  @override
  IconData get iconData => Icons.video_camera_back_outlined;

  @override
  String get title => 'ProVideoEditor';

  @override
  bool get withLeading => true;

  final PlaylistController playlistController = PlaylistController();
  late final PlaylistWidget playlistWidget = PlaylistWidget(
    playlistController: playlistController,
  );
  String? _inputVideoFile;

  final _editorKey = GlobalKey<ProImageEditorState>();

  final _taskId = DateTime.now().microsecondsSinceEpoch.toString();

  final _outputFormat = VideoOutputFormat.mp4;

  bool _isSeeking = false;

  TrimDurationSpan? _durationSpan;

  TrimDurationSpan? _tempDurationSpan;

  ProVideoController? _proVideoController;

  List<ImageProvider>? _thumbnails;

  late VideoMetadata _videoMetadata;

  final int _thumbnailCount = 7;

  // 视频渲染类
  late final ProVideoRender _videoRender;
  String? _outputVideoFile;
  final Map<String, Uint8List> _cachedKeyFrames = {};
  final Map<String, List<Uint8List>> _cachedKeyFrameList = {};
  late final VideoController _videoController;
  late final AudioHelperService _audioService;
  final _updateClipsNotifier = ValueNotifier(false);

  late final ProImageEditorConfigs _videoConfigs = ProImageEditorConfigs(
    dialogConfigs: DialogConfigs(
      widgets: DialogWidgets(
        loadingDialog: (message, configs) => VideoProgressAlert(
          taskId: _taskId,
        ),
      ),
    ),
    mainEditor: MainEditorConfigs(
      tools: [
        SubEditorMode.videoClips,
        SubEditorMode.audio,
        SubEditorMode.paint,
        SubEditorMode.text,
        SubEditorMode.cropRotate,
        SubEditorMode.tune,
        SubEditorMode.filter,
        SubEditorMode.blur,
        SubEditorMode.emoji,
        SubEditorMode.sticker,
      ],
      widgets: MainEditorWidgets(
        removeLayerArea: (
          removeAreaKey,
          editor,
          rebuildStream,
          isLayerBeingTransformed,
        ) =>
            VideoEditorRemoveArea(
          removeAreaKey: removeAreaKey,
          editor: editor,
          rebuildStream: rebuildStream,
          isLayerBeingTransformed: isLayerBeingTransformed,
        ),
      ),
    ),
    paintEditor: const PaintEditorConfigs(
      tools: [
        PaintMode.freeStyle,
        PaintMode.arrow,
        PaintMode.line,
        PaintMode.rect,
        PaintMode.circle,
        PaintMode.dashLine,
        PaintMode.polygon,
        // Blur and pixelate are not supported.
        // PaintMode.pixelate,
        // PaintMode.blur,
        PaintMode.eraser,
      ],
    ),
    audioEditor: AudioEditorConfigs(),
    clipsEditor: ClipsEditorConfigs(
      clips: [
        VideoClip(
          id: '001',
          title: 'My awesome video',
          // subtitle: 'Optional',
          duration: Duration.zero,
          clip: EditorVideoClip.file(_videoRender.videoInputPath),
        ),
      ],
    ),
    videoEditor: const VideoEditorConfigs(
      initialMuted: false,
      initialPlay: false,
      isAudioSupported: true,
      minTrimDuration: Duration(seconds: 7),
      playTimeSmoothingDuration: Duration(milliseconds: 600),
    ),
    imageGeneration: const ImageGenerationConfigs(
      captureImageByteFormat: ImageByteFormat.rawStraightRgba,
    ),
  );

  /// 初始化工作
  void _init() {
    MediaKit.ensureInitialized();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateThumbnails();
    });
    _videoController = VideoController(Player());
    _audioService = AudioHelperService(
      videoController: _videoController,
    );
    _audioService.initialize();
  }

  /// Generates thumbnails for the given [_video].
  Future<void> _generateThumbnails() async {
    var imageWidth = appDataProvider.secondaryBodyWidth / _thumbnailCount;
    _thumbnails = await _videoRender.getThumbnails(
      thumbnailCount: _thumbnailCount,
      width: imageWidth,
      outputFormat: ThumbnailFormat.jpeg,
      height: imageWidth,
    );

    _videoConfigs.clipsEditor.clips.first =
        _videoConfigs.clipsEditor.clips.first.copyWith(thumbnails: _thumbnails);

    /// Optional precache every thumbnail
    // var cacheList = _thumbnails?.map((item) => precacheImage(item, context));
    // await Future.wait(cacheList);

    if (_proVideoController != null) {
      _proVideoController!.thumbnails = _thumbnails;
    }
  }

  /// 选定视频，开始编辑
  Future<void> play({String? inputVideoFile}) async {
    if (inputVideoFile != null) {
      _inputVideoFile = inputVideoFile;
    } else {
      _inputVideoFile = playlistController.current?.filename;
    }

    if (_inputVideoFile != null) {
      String? filename = _inputVideoFile!;
      _videoController.player.open(Media(filename));

      await Future.wait([
        _videoController.player.setPlaylistMode(PlaylistMode.loop),
        _videoController.player
            .setVolume(_videoConfigs.videoEditor.initialMuted ? 0 : 100),
        _videoConfigs.videoEditor.initialPlay
            ? _videoController.player.play()
            : _videoController.player.pause(),
      ]);
      _videoRender = ProVideoRender(videoInputPath: filename);
      _videoMetadata = await _videoRender.getMetadata();
      _videoConfigs.clipsEditor.clips.first =
          _videoConfigs.clipsEditor.clips.first.copyWith(
        duration: _videoMetadata.duration,
      );
    }

    _thumbnails = await _videoRender.getThumbnails(
        thumbnailCount: _thumbnailCount, height: 32, width: 32);
    _proVideoController = ProVideoController(
      videoPlayer: _buildVideoPlayer(),
      initialResolution: _videoMetadata.resolution,
      videoDuration: _videoMetadata.duration,
      fileSize: _videoMetadata.fileSize,
      thumbnails: _thumbnails,
    );
    _videoController.player.stream.duration.listen((e) {
      _onDurationChange(e);
    });
  }

  void _onDurationChange(Duration duration) {
    var totalVideoDuration = _videoMetadata.duration;
    _proVideoController!.setPlayTime(duration);

    if (_durationSpan != null && duration >= _durationSpan!.end) {
      _seekToPosition(_durationSpan!);
    } else if (duration >= totalVideoDuration) {
      _seekToPosition(
        TrimDurationSpan(start: Duration.zero, end: totalVideoDuration),
      );
    }
  }

  Future<void> _seekToPosition(TrimDurationSpan span) async {
    _durationSpan = span;

    if (_isSeeking) {
      _tempDurationSpan = span;
      return;
    }
    _isSeeking = true;

    _proVideoController!.pause();
    _proVideoController!.setPlayTime(_durationSpan!.start);

    await _videoController.player.pause();
    await _videoController.player.seek(span.start);

    _isSeeking = false;
    if (_tempDurationSpan != null) {
      TrimDurationSpan nextSeek = _tempDurationSpan!;
      _tempDurationSpan = null;
      await _seekToPosition(nextSeek);
    }
  }

  /// 渲染视频
  Future<void> generateVideo(CompleteParameters parameters) async {
    _outputVideoFile = await _videoRender.render(
      blur: parameters.blur,
      enableAudio: _proVideoController?.isAudioEnabled ?? true,
      colorMatrixList: parameters.colorFilters,
      startTimeMs: parameters.startTime?.inMilliseconds,
      endTimeMs: parameters.endTime?.inMilliseconds,
      cropWidth: parameters.cropWidth,
      cropHeight: parameters.cropHeight,
      rotateTurns: parameters.rotateTurns,
      cropX: parameters.cropX,
      cropY: parameters.cropY,
      flipX: parameters.flipX,
      flipY: parameters.flipY,
    );
  }

  Future<VideoClip?> _addClip(BuildContext context) async {
    final String name = _videoRender.videoInputPath!;
    final title = name.split('.').first;
    LoadingDialog.instance.show(context, configs: _videoConfigs);
    final meta = await _videoRender.getMetadata();
    LoadingDialog.instance.hide();

    // Create and return your video clip
    return VideoClip(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      clip: EditorVideoClip.file(_videoRender.videoInputPath!),
      duration: meta.duration,
    );
  }

  Future<void> _mergeClips(
    BuildContext context,
    List<VideoClip> clips,
    void Function(double) onProgress,
  ) async {
    LoadingDialog.instance.show(context, configs: _videoConfigs);

    _updateClipsNotifier.value = true;
    final String? filename = await _videoRender.render(
      extension: 'mp4',
      videoSegments: clips.map(
        (el) {
          final clip = el.clip;
          return VideoSegment(
            video: EditorVideo.autoSource(
              networkUrl: clip.networkUrl,
              assetPath: clip.assetPath,
              byteArray: clip.bytes,
              file: clip.file,
            ),
            startTime: el.trimSpan?.start,
            endTime: el.trimSpan?.end,
          );
        },
      ).toList(),
    );
    LoadingDialog.instance.hide();

    await play(inputVideoFile: filename);

    final editor = _editorKey.currentState!;

    _proVideoController?.initialize(
      configsFunction: () => _videoConfigs.videoEditor,
      callbacksAudioFunction: () =>
          editor.audioEditorCallbacks ?? const AudioEditorCallbacks(),
      callbacksFunction: () =>
          editor.callbacks.videoEditorCallbacks ?? VideoEditorCallbacks(),
    );

    LoadingDialog.instance.hide();
    editor.initializeVideoEditor();

    _updateClipsNotifier.value = false;
  }

  late PreviewVideo previewVideo = PreviewVideo();

  void _handleCloseEditor(BuildContext context, EditorMode editorMode) async {
    if (editorMode != EditorMode.main) return Navigator.pop(context);

    if (_outputVideoFile != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) {
          previewVideo.updateVideoFile(
              _outputVideoFile!, _videoRender.videoGenerationTime);
          return previewVideo;
        }),
      );
      _outputVideoFile = null;
    } else {
      return Navigator.pop(context);
    }
  }

  List<Widget>? _buildRightWidgets(BuildContext context) {
    List<Widget> children = [
      IconButton(
        tooltip: AppLocalizations.t('Play'),
        onPressed: () async {
          play();
        },
        icon: const Icon(Icons.play_circle_outline_outlined),
      ),
      IconButton(
        tooltip: AppLocalizations.t('More'),
        onPressed: () {
          playlistWidget.showActionCard(context);
        },
        icon: const Icon(Icons.more_horiz_outlined),
      )
    ];

    return children;
  }

  late final ClipsPreviewer clipsPreviewer = ClipsPreviewer(
    videoConfigs: _videoConfigs.videoEditor,
    proController: _proVideoController!,
  );

  Widget _buildVideoEditor(BuildContext context) {
    return ProImageEditor.video(
      _proVideoController!,
      key: _editorKey,
      callbacks: ProImageEditorCallbacks(
        onCompleteWithParameters: generateVideo,
        onCloseEditor: (EditorMode editorMode) =>
            _handleCloseEditor(context, editorMode),
        videoEditorCallbacks: VideoEditorCallbacks(
          onPause: _videoController.player.pause,
          onPlay: _videoController.player.play,
          onMuteToggle: (isMuted) {
            if (isMuted) {
              _audioService.setVolume(0);
              _videoController.player.setVolume(0);
            } else {
              _audioService.balanceAudio();
            }
          },
          onTrimSpanUpdate: (durationSpan) {
            if (_videoController.player.state.playing) {
              _proVideoController!.pause();
            }
          },
          onTrimSpanEnd: _seekToPosition,
        ),
        audioEditorCallbacks: AudioEditorCallbacks(
          onBalanceChange: _audioService.balanceAudio,
          onStartTimeChange: (startTime) async {
            await Future.value([
              _audioService.seek(startTime),
              _videoController.player.seek(Duration.zero),
            ]);
          },
          onPlay: _audioService.play,
          onStop: (audio) => _audioService.pause(),
        ),
        clipsEditorCallbacks: ClipsEditorCallbacks(
          onBuildPlayer: (controller, videoClip) {
            clipsPreviewer.updateVideoClip(videoClip);

            return clipsPreviewer;
          },
          onMergeClips: (List<VideoClip> clips, onMergeClips) =>
              _mergeClips(context, clips, onMergeClips),
          onReadKeyFrame: (source) async {
            if (_cachedKeyFrames.containsKey(source.id)) {
              return _cachedKeyFrames[source.id]!;
            }

            ProVideoRender videoRender =
                ProVideoRender(videoBytes: source.clip.bytes);

            final List<ImageProvider<Object>> result =
                await videoRender.getKeyFrames(
              maxOutputFrames: 1,
              height: 200,
              width: 200,
            );
            _cachedKeyFrames[source.id] = (result.first as MemoryImage).bytes;

            return (result.first as MemoryImage).bytes;
          },
          onReadKeyFrames: (source) async {
            if (_cachedKeyFrameList.containsKey(source.id)) {
              return _cachedKeyFrameList[source.id]!;
            }
            ProVideoRender videoRender =
                ProVideoRender(videoBytes: source.clip.bytes);
            final List<ImageProvider<Object>> result =
                await videoRender.getKeyFrames(
              maxOutputFrames: _thumbnailCount,
              height: 200,
              width: 200,
            );
            _cachedKeyFrameList[source.id] =
                result.map((p) => (p as MemoryImage).bytes).toList();

            return _cachedKeyFrameList[source.id]!;
          },
          onAddClip: () => _addClip(context),
        ),
      ),
      configs: _videoConfigs,
    );
  }

  Widget _buildVideoPlayer() {
    return ValueListenableBuilder(
        valueListenable: _updateClipsNotifier,
        builder: (_, isLoading, __) {
          return Center(
            child: isLoading
                ? const CircularProgressIndicator.adaptive()
                : Video(
                    controller: _videoController,
                  ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return AppBarAdaptiveView(
      title: title,
      helpPath: routeName,
      withLeading: true,
      rightWidgets: _buildRightWidgets(context),
      main: playlistWidget,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _proVideoController == null
            ? const VideoInitializingWidget()
            : _buildVideoEditor(context),
      ),
    );
  }
}

/// _proVideoController初始化时显示的界面
class VideoInitializingWidget extends StatelessWidget {
  const VideoInitializingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blueGrey.shade900,
            Colors.black87,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 30,
          children: [
            const Icon(
              Icons.video_camera_back_rounded,
              size: 80,
              color: Colors.white70,
            ),
            Text(
              AppLocalizations.t('Initializing Video-Editor...'),
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                color: Colors.white70,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 视频产生的时候显示的进度界面
class VideoProgressAlert extends StatelessWidget {
  const VideoProgressAlert({
    super.key,
    required this.taskId,
  });

  final String taskId;

  bool get _canCancel =>
      taskId.isNotEmpty &&
      (platformParams.android || platformParams.ios || platformParams.macos);

  Future<void> _handleCancelTap(BuildContext context) async {
    try {
      await ProVideoEditor.instance.cancel(taskId);
    } catch (error, stackTrace) {
      logger.e('Failed to cancel render: $error\n$stackTrace');
    }
    // Always close the alert so the UI reflects the canceled render.
    LoadingDialog.instance.hide();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ModalBarrier(
          onDismiss: kDebugMode ? LoadingDialog.instance.hide : null,
          color: Colors.black54,
          dismissible: kDebugMode,
        ),
        Center(
          child: Theme(
            data: Theme.of(context),
            child: AlertDialog(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: const EdgeInsets.only(top: 3.0),
                  child: _buildProgressBody(context),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBody(BuildContext context) {
    return VideoRendererProgressPanel(
      progressStream: ProVideoEditor.instance.progressStreamById(taskId),
      supportsCancel: _canCancel,
      onCancel: _canCancel ? () => _handleCancelTap(context) : null,
    );
  }
}

/// 显示视频转换的进度
class VideoRendererProgressPanel extends StatelessWidget {
  const VideoRendererProgressPanel({
    super.key,
    required this.progressStream,
    required this.supportsCancel,
    this.onCancel,
  });

  final Stream<ProgressModel> progressStream;

  final bool supportsCancel;

  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProgressModel>(
      stream: progressStream,
      builder: (context, snapshot) {
        final double progress = snapshot.data?.progress ?? 0;

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: progress),
          duration: const Duration(milliseconds: 300),
          builder: (context, animatedValue, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                CircularProgressIndicator(
                  value: animatedValue,
                  year2023: false,
                ),
                Text('${(animatedValue * 100).toStringAsFixed(1)} / 100'),
                if (supportsCancel && onCancel != null)
                  FilledButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: Text(AppLocalizations.t('Cancel render')),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

/// 辅助类管理音频回放
class AudioHelperService {
  AudioHelperService({
    required this.videoController,
  });

  final _audioPlayer = AudioPlayer();

  final VideoController videoController;

  double _lastVolumeBalance = 0;

  Future<void> initialize() {
    return _audioPlayer.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.duckOthers,
          },
        ),
      ),
    );
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }

  Future<void> play(AudioTrack track) async {
    final audio = track.audio;
    Source source;
    if (audio.hasAssetPath) {
      source = AssetSource(audio.assetPath!);
    } else if (audio.hasFile) {
      source = DeviceFileSource(audio.file!.path);
    } else if (audio.hasNetworkUrl) {
      source = UrlSource(audio.networkUrl!);
    } else {
      source = BytesSource(audio.bytes!);
    }

    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(source, position: track.startTime);
  }

  Future<void> pause() {
    return _audioPlayer.pause();
  }

  Future<void> setVolume(double volume) {
    return _audioPlayer.setVolume(volume);
  }

  Future<void> seek(Duration startTime) {
    return _audioPlayer.seek(startTime);
  }

  Future<void> balanceAudio([double? volumeBalance]) async {
    volumeBalance ??= _lastVolumeBalance;

    double overlayVolume = 1;
    double originalVolume = 1;
    if (volumeBalance < 0) {
      overlayVolume += volumeBalance;
    } else {
      originalVolume -= volumeBalance;
    }
    await Future.wait([
      setVolume(overlayVolume),
      videoController.player.setVolume(originalVolume),
    ]);
    _lastVolumeBalance = volumeBalance;
  }

  Future<String?> safeCustomAudioPath(AudioTrack? track) async {
    final EditorAudio? audio = track?.audio;
    if (audio == null) return null;

    if (audio.hasFile) {
      return audio.file!.path;
    } else {
      String filePath =
          await FileUtil.getTempFilename(filename: 'temp-audio.mp3');

      if (audio.hasNetworkUrl) {
        return (await fetchVideoToFile(audio.networkUrl!, filePath)).path;
      } else if (audio.hasAssetPath) {
        return (await writeAssetVideoToFile(
                'assets/${audio.assetPath!}', filePath))
            .path;
      } else {
        return (await writeMemoryVideoToFile(audio.bytes!, filePath)).path;
      }
    }
  }
}

/// 预览视频片段
class ClipsPreviewer extends StatelessWidget {
  ClipsPreviewer({
    super.key,
    required this.proController,
    required this.videoConfigs,
  });

  final ProVideoController proController;

  final VideoEditorConfigs videoConfigs;

  final ValueNotifier<VideoClip?> videoClip = ValueNotifier<VideoClip?>(null);

  final ValueNotifier<VideoMetadata?> videoMetadata =
      ValueNotifier<VideoMetadata?>(null);

  final Player player = Player();
  late final VideoController controller = VideoController(player);

  bool _isSeeking = false;

  TrimDurationSpan? _durationSpan;

  TrimDurationSpan? _tempDurationSpan;

  void initState() {
    proController.initialize(
      callbacksAudioFunction: () => const AudioEditorCallbacks(),
      callbacksFunction: () => VideoEditorCallbacks(
        onPause: player.pause,
        onPlay: player.play,
        onMuteToggle: (isMuted) {
          player.setVolume(isMuted ? 0 : 100);
        },
        onTrimSpanUpdate: (durationSpan) {
          if (player.state.playing) {
            proController.pause();
          }
        },
        onTrimSpanEnd: _seekToPosition,
      ),
      configsFunction: () => videoConfigs,
    );
  }

  void dispose() {
    player.dispose();
  }

  void updateVideoClip(VideoClip? videoClip) async {
    this.videoClip.value = videoClip;
    videoMetadata.value = null;
    final video = videoClip?.clip;
    if (video != null) {
      Media media;
      if (video.hasFile) {
        String filename = video.file!.path;
        media = Media(filename);
      } else if (video.hasAssetPath) {
        media = Media(video.assetPath!);
      } else if (video.hasNetworkUrl) {
        media = Media(video.networkUrl!);
      } else {
        final filename = await FileUtil.writeTempFileAsBytes(video.bytes!,
            filename: 'temp.mp3');
        media = Media(filename!);
      }

      await player.open(media, play: false);
      player.setVolume(videoConfigs.initialMuted ? 0 : 100);
      ProVideoRender videoRender = ProVideoRender(videoInputPath: media.uri);
      videoMetadata.value = await videoRender.getMetadata();
    }
  }

  Future<void> _seekToPosition(TrimDurationSpan span) async {
    _durationSpan = span;

    if (_isSeeking) {
      _tempDurationSpan = span; // Store the latest seek request
      return;
    }
    _isSeeking = true;

    proController.pause();
    proController.setPlayTime(_durationSpan!.start);

    await player.pause();
    await player.seek(span.start);

    _isSeeking = false;

    if (_tempDurationSpan != null) {
      TrimDurationSpan nextSeek = _tempDurationSpan!;
      _tempDurationSpan = null;
      await _seekToPosition(nextSeek);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: videoMetadata.value == null ? 1 : 0,
      child: videoMetadata.value != null
          ? Center(
              child: AspectRatio(
                aspectRatio: videoMetadata.value?.resolution.aspectRatio ?? 1,
                child: Video(
                  controller: controller,
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

/// 视频预览，播放视频并显示视频的基本信息
class PreviewVideo extends StatelessWidget {
  PreviewVideo({
    super.key,
  });

  final ValueNotifier<Duration> generationTime =
      ValueNotifier<Duration>(Duration.zero);

  final _valueStyle = const TextStyle(fontStyle: FontStyle.italic);

  final ValueNotifier<VideoMetadata?> videoMetadata =
      ValueNotifier<VideoMetadata?>(null);
  final Player player = Player();
  late final VideoController controller = VideoController(player);

  final _numberFormatter = NumberFormat();

  Future<void> updateVideoFile(String filename, Duration generationTime) async {
    this.generationTime.value = generationTime;
    var media = Media(filename);
    await player.open(media, play: false);
    ProVideoRender videoRender = ProVideoRender(videoInputPath: filename);
    videoMetadata.value = await videoRender.getMetadata();
  }

  void dispose() {
    player.dispose();
  }

  String formatBytes(int bytes, [int decimals = 2]) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (log(bytes) / log(1024)).floor();
    var size = bytes / pow(1024, i);
    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Theme(
        data: Theme.of(context),
        child: CustomPaint(
          painter: const PixelTransparentPainter(
            primary: Color.fromARGB(255, 17, 17, 17),
            secondary: Color.fromARGB(255, 36, 36, 37),
          ),
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              _buildVideoPlayer(constraints),
              _buildGenerationInfos(),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildVideoPlayer(BoxConstraints constraints) {
    return ListenableBuilder(
        listenable: videoMetadata,
        builder: (BuildContext context, Widget? child) {
          final aspectRatio = videoMetadata.value?.resolution.aspectRatio ?? 1;
          final rotation = videoMetadata.value?.rotation ?? 0;

          int convertedRotation = rotation % 360;

          final is90DegRotated =
              convertedRotation == 90 || convertedRotation == 270;

          final maxWidth = constraints.maxWidth;
          final maxHeight = constraints.maxHeight;

          double width = maxWidth;
          double height =
              is90DegRotated ? width * aspectRatio : width / aspectRatio;

          if (height > maxHeight) {
            height = maxHeight;
            width = height * aspectRatio;
          }
          return Center(
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: Hero(
                tag: const ProImageEditorConfigs().heroTag,
                child: Video(
                  key: const ValueKey('Preview-Video-Player'),
                  controller: controller,
                ),
              ),
            ),
          );
        });
  }

  Widget _buildGenerationInfos() {
    TableRow tableSpace = const TableRow(
      children: [SizedBox(height: 3), SizedBox()],
    );
    return ListenableBuilder(
        listenable: videoMetadata,
        builder: (BuildContext context, Widget? child) {
          return Positioned(
            top: 10,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Table(
                    defaultColumnWidth: const IntrinsicColumnWidth(),
                    children: [
                      TableRow(children: [
                        const Text('Generation-Time'),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            '${_numberFormatter.format(generationTime)} ms',
                            style: _valueStyle,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ]),
                      tableSpace,
                      TableRow(children: [
                        const Text('Video-Size'),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            formatBytes(videoMetadata.value?.fileSize ?? 0),
                            style: _valueStyle,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ]),
                      tableSpace,
                      TableRow(children: [
                        const Text('Content-Type'),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            'video/${videoMetadata.value?.extension ?? ''}',
                            style: _valueStyle,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ]),
                      tableSpace,
                      TableRow(children: [
                        const Text('Dimension'),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            '${_numberFormatter.format(
                              videoMetadata.value?.resolution.width.round(),
                            )} x ${_numberFormatter.format(
                              videoMetadata.value?.resolution.height.round(),
                            )}',
                            style: _valueStyle,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ]),
                      tableSpace,
                      TableRow(children: [
                        const Text('Video-Duration'),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            '${videoMetadata.value?.duration.inSeconds} s',
                            style: _valueStyle,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }
}

/// 马赛克
class PixelTransparentPainter extends CustomPainter {
  const PixelTransparentPainter({
    required this.primary,
    required this.secondary,
  });

  final Color primary;

  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    const cellSize = 22.0; // Size of each square
    final numCellsX = size.width / cellSize;
    final numCellsY = size.height / cellSize;

    for (int row = 0; row < numCellsY; row++) {
      for (int col = 0; col < numCellsX; col++) {
        final color = ((row + col) % 2).isEven ? primary : secondary;
        canvas.drawRect(
          Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize),
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
