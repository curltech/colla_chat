import 'dart:async';
import 'dart:io' as io;
import 'dart:math';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_adaptive_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/media/playlist_widget.dart';
import 'package:colla_chat/widgets/media_editor/pro_video_render.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart' hide AudioTrack;
import 'package:media_kit/src/player/player.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:pro_video_editor/pro_video_editor.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';

/// 通用的视频编辑界面，使用pro_video_editor
class ProVideoEditorWidget extends StatelessWidget with DataTileMixin {
  ProVideoEditorWidget({super.key});

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

  Duration _videoGenerationTime = Duration.zero;
  late VideoPlayerController _videoController;

  late final _audioService = AudioHelperService(
    videoController: _videoController,
  );
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

  Future<void> _setMetadata() async {
    _videoMetadata = await _videoRender.getMetadata();
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

  Future<void> initializePlayer() async {
    _videoConfigs.clipsEditor.clips.first =
        _videoConfigs.clipsEditor.clips.first.copyWith(
      duration: _videoMetadata.duration,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateThumbnails();
    });

    String? filename = playlistController.current?.filename;
    if (filename != null) {
      _videoController = VideoPlayerController.file(io.File(filename));

      await Future.wait([
        _videoController.initialize(),
        _videoController.setLooping(false),
        _videoController
            .setVolume(_videoConfigs.videoEditor.initialMuted ? 0 : 100),
        _videoConfigs.videoEditor.initialPlay
            ? _videoController.play()
            : _videoController.pause(),
        _audioService.initialize(),
      ]);
      _videoRender = ProVideoRender(videoInputPath: filename);
      _videoMetadata = await _videoRender.getMetadata();
    }
    _proVideoController = ProVideoController(
      videoPlayer: _buildVideoPlayer(),
      initialResolution: _videoMetadata.resolution,
      videoDuration: _videoMetadata.duration,
      fileSize: _videoMetadata.fileSize,
      thumbnails: _thumbnails,
    );
    _thumbnails = await _videoRender.getThumbnails(
        thumbnailCount: _thumbnailCount, height: 32, width: 32);
    _videoController.addListener(_onDurationChange);
  }

  void _onDurationChange() {
    var totalVideoDuration = _videoMetadata.duration;
    var duration = _videoController.value.position;
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

    await _videoController.pause();
    await _videoController.seekTo(span.start);

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

    _videoRender = ProVideoRender(videoInputPath: filename);

    await _setMetadata();
    await _generateThumbnails();
    await initializePlayer();

    final editor = _editorKey.currentState!;

    _proVideoController = ProVideoController(
      videoPlayer: _buildVideoPlayer(),
      initialResolution: _videoMetadata.resolution,
      videoDuration: _videoMetadata.duration,
      fileSize: _videoMetadata.fileSize,
      thumbnails: _thumbnails,
    )..initialize(
        configsFunction: () => _videoConfigs.videoEditor,
        callbacksAudioFunction: () =>
            editor.audioEditorCallbacks ?? const AudioEditorCallbacks(),
        callbacksFunction: () =>
            editor.callbacks.videoEditorCallbacks ?? VideoEditorCallbacks(),
      );

    final controller = VideoPlayerController.file(io.File(filename!));
    await controller.initialize();
    LoadingDialog.instance.hide();

    _videoController = controller;
    _videoController.addListener(_onDurationChange);
    editor.initializeVideoEditor();

    _updateClipsNotifier.value = false;
  }

  void _handleCloseEditor(BuildContext context, EditorMode editorMode) async {
    if (editorMode != EditorMode.main) return Navigator.pop(context);

    if (_outputVideoFile != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PreviewVideo(
            filePath: _outputVideoFile!,
            generationTime: _videoGenerationTime,
          ),
        ),
      );
      _outputVideoFile = null;
    } else {
      return Navigator.pop(context);
    }
  }

  List<Widget>? _buildRightWidgets(BuildContext context) {
    List<Widget> children = [
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

  Widget _buildVideoEditor(BuildContext context) {
    return ProImageEditor.video(
      _proVideoController!,
      key: _editorKey,
      callbacks: ProImageEditorCallbacks(
        onCompleteWithParameters: generateVideo,
        onCloseEditor: (EditorMode editorMode) =>
            _handleCloseEditor(context, editorMode),
        videoEditorCallbacks: VideoEditorCallbacks(
          onPause: _videoController.pause,
          onPlay: _videoController.play,
          onMuteToggle: (isMuted) {
            if (isMuted) {
              _audioService.setVolume(0);
              _videoController.setVolume(0);
            } else {
              _audioService.balanceAudio();
            }
          },
          onTrimSpanUpdate: (durationSpan) {
            if (_videoController.value.isPlaying) {
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
              _videoController.seekTo(Duration.zero),
            ]);
          },
          onPlay: _audioService.play,
          onStop: (audio) => _audioService.pause(),
        ),
        clipsEditorCallbacks: ClipsEditorCallbacks(
          onBuildPlayer: (controller, videoClip) {
            return ClipsPreviewer(
              videoConfigs: _videoConfigs.videoEditor,
              proController: controller,
              videoClip: videoClip,
            );
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
                : AspectRatio(
                    aspectRatio: _videoController.value.size.aspectRatio,
                    child: VideoPlayer(
                      _videoController,
                    ),
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

class VideoInitializingWidget extends StatelessWidget {
  /// Creates a [VideoInitializingWidget] widget.
  const VideoInitializingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 30,
            children: [
              Icon(
                Icons.video_camera_back_rounded,
                size: 80,
                color: Colors.white70,
              ),
              Text(
                'Initializing Video-Editor...',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(
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
      ),
    );
  }
}

// A dialog that displays real-time export progress for video generation.
///
/// Listens to the [VideoUtilsService.progressStream] and shows a
/// circular progress indicator with percentage text.
class VideoProgressAlert extends StatelessWidget {
  /// Creates a [VideoProgressAlert] widget.
  const VideoProgressAlert({
    super.key,
    required this.taskId,
  });

  /// Optional taskId of the progress stream.
  final String taskId;

  bool get _canCancel =>
      taskId.isNotEmpty &&
      (platformParams.android || platformParams.ios || platformParams.macos);

  Future<void> _handleCancelTap(BuildContext context) async {
    try {
      await ProVideoEditor.instance.cancel(taskId);
    } catch (error, stackTrace) {
      debugPrint('Failed to cancel render: $error\n$stackTrace');
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

/// Progress indicator panel displayed while the renderer is exporting a video.
class VideoRendererProgressPanel extends StatelessWidget {
  /// Creates a [VideoRendererProgressPanel].
  const VideoRendererProgressPanel({
    super.key,
    required this.progressStream,
    required this.supportsCancel,
    this.onCancel,
  });

  /// Emits [ProgressModel] updates for the active render task.
  final Stream<ProgressModel> progressStream;

  /// Whether the current platform exposes a cancel API.
  final bool supportsCancel;

  /// Invoked when the cancel button is tapped.
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
                  // ignore: deprecated_member_use
                  year2023: false,
                ),
                Text('${(animatedValue * 100).toStringAsFixed(1)} / 100'),
                if (supportsCancel && onCancel != null)
                  FilledButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('Cancel render'),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

/// A helper service that manages audio playback alongside video playback.
class AudioHelperService {
  /// Creates an instance of [AudioHelperService] for the
  /// given [videoController].
  AudioHelperService({
    required this.videoController,
  });

  /// The internal audio player used to handle audio playback.
  final _audioPlayer = AudioPlayer();

  /// The controller managing video playback.
  final VideoPlayerController videoController;

  /// Stores the last applied audio balance between video and overlay.
  double _lastVolumeBalance = 0;

  /// Initializes the audio player with platform-specific audio context
  /// settings.
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

  /// Disposes of the audio player and releases resources.
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }

  /// Plays the given [AudioTrack] with looping enabled.
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

  /// Pauses the current audio playback.
  Future<void> pause() {
    return _audioPlayer.pause();
  }

  /// Sets the playback volume.
  ///
  /// The [volume] should be a value between `0.0` (muted) and `1.0` (maximum).
  Future<void> setVolume(double volume) {
    return _audioPlayer.setVolume(volume);
  }

  /// Seeks the audio playback to the specified [startTime].
  Future<void> seek(Duration startTime) {
    return _audioPlayer.seek(startTime);
  }

  /// Adjusts the balance between video and overlay audio.
  ///
  /// A negative [volumeBalance] lowers the overlay volume,
  /// while a positive value lowers the video volume.
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
      videoController.setVolume(originalVolume),
    ]);
    _lastVolumeBalance = volumeBalance;
  }

  /// Returns a local file path for the given [track]'s audio source.
  ///
  /// - If the audio already exists as a file, its path is returned.
  /// - Otherwise, the audio is written to a temporary file from
  ///   assets, network, or memory bytes.
  Future<String?> safeCustomAudioPath(AudioTrack? track) async {
    final directory = await getTemporaryDirectory();

    final EditorAudio? audio = track?.audio;
    if (audio == null) return null;

    if (audio.hasFile) {
      return audio.file!.path;
    } else {
      String filePath = '${directory.path}/temp-audio.mp3';

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

class ClipsPreviewer extends StatefulWidget {
  /// Creates a [ClipsPreviewer] widget.
  const ClipsPreviewer({
    super.key,
    required this.proController,
    required this.videoConfigs,
    required this.videoClip,
  });

  /// Controls video playback, rendering, and transformations.
  final ProVideoController proController;

  /// Configuration settings for the video editor.
  final VideoEditorConfigs videoConfigs;

  /// The video clip being previewed.
  final VideoClip videoClip;

  @override
  State<ClipsPreviewer> createState() => _ClipsPreviewerState();
}

class _ClipsPreviewerState extends State<ClipsPreviewer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  bool _isSeeking = false;

  /// Stores the currently selected trim duration span.
  TrimDurationSpan? _durationSpan;

  /// Temporarily stores a pending trim duration span.
  TrimDurationSpan? _tempDurationSpan;

  @override
  void initState() {
    super.initState();
    widget.proController.initialize(
      callbacksAudioFunction: () => const AudioEditorCallbacks(),
      callbacksFunction: () => VideoEditorCallbacks(
        onPause: _controller.pause,
        onPlay: _controller.play,
        onMuteToggle: (isMuted) {
          _controller.setVolume(isMuted ? 0 : 100);
        },
        onTrimSpanUpdate: (durationSpan) {
          if (_controller.value.isPlaying) {
            widget.proController.pause();
          }
        },
        onTrimSpanEnd: _seekToPosition,
      ),
      configsFunction: () => widget.videoConfigs,
    );

    _initializePlayer();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initializePlayer() async {
    final video = widget.videoClip.clip;
    if (video.hasFile) {
      _controller = VideoPlayerController.file(io.File(video.file!.path));
    } else if (video.hasAssetPath) {
      _controller = VideoPlayerController.asset(video.assetPath!);
    } else if (video.hasNetworkUrl) {
      _controller =
          VideoPlayerController.networkUrl(Uri.parse(video.networkUrl!));
    } else {
      final directory = await getApplicationCacheDirectory();
      final file = io.File('${directory.path}/temp.mp4');
      await file.writeAsBytes(video.bytes!);

      _controller = VideoPlayerController.file(file);
    }

    await Future.wait([
      //  setMetadata(),
      _controller.initialize(),
      _controller.setVolume(widget.videoConfigs.initialMuted ? 0 : 100),
    ]);
    final meta =
        await ProVideoEditor.instance.getMetadata(EditorVideo.autoSource(
      file: video.file,
      byteArray: video.bytes,
      assetPath: video.assetPath,
      networkUrl: video.networkUrl,
    ));

    /// Listen to play time
    _controller.addListener(() {
      if (!mounted) return;

      var totalVideoDuration = meta.duration;
      var duration = _controller.value.position;
      widget.proController.setPlayTime(duration);

      if (_isSeeking) return;

      if (_tempDurationSpan != null && duration >= _tempDurationSpan!.end) {
        _seekToPosition(_tempDurationSpan!);
      } else if (duration >= totalVideoDuration) {
        _seekToPosition(
          TrimDurationSpan(
            start: Duration.zero,
            end: widget.videoClip.duration,
          ),
        );
      }
    });

    _isInitialized = true;
    setState(() {});
  }

  Future<void> _seekToPosition(TrimDurationSpan span) async {
    _durationSpan = span;

    if (_isSeeking) {
      _tempDurationSpan = span; // Store the latest seek request
      return;
    }
    _isSeeking = true;

    widget.proController.pause();
    widget.proController.setPlayTime(_durationSpan!.start);

    await _controller.pause();
    await _controller.seekTo(span.start);

    _isSeeking = false;

    // Check if there's a pending seek request
    if (_tempDurationSpan != null) {
      TrimDurationSpan nextSeek = _tempDurationSpan!;
      _tempDurationSpan = null; // Clear the pending seek
      await _seekToPosition(nextSeek); // Process the latest request
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: _isInitialized ? 1 : 0,
      child: _isInitialized
          ? Center(
              child: AspectRatio(
                aspectRatio: _controller.value.size.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class PreviewVideo extends StatefulWidget {
  /// Creates a [PreviewVideo] widget.
  const PreviewVideo({
    super.key,
    required this.filePath,
    required this.generationTime,
  });

  /// The file path of the video to be previewed.
  final String filePath;

  /// The time it took to generate the video preview.
  final Duration generationTime;

  @override
  State<PreviewVideo> createState() => _PreviewVideoState();
}

class _PreviewVideoState extends State<PreviewVideo> {
  final _valueStyle = const TextStyle(fontStyle: FontStyle.italic);

  late Future<VideoMetadata> _videoMetadata;
  late final int _generationTime = widget.generationTime.inMilliseconds;
  final _player = Player();
  late final _controller = VideoController(_player);

  final _numberFormatter = NumberFormat();

  @override
  void initState() {
    super.initState();

    _videoMetadata = ProVideoEditor.instance.getMetadata(
      EditorVideo.file(widget.filePath),
    );
    _initializePlayer();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _initializePlayer() async {
    var media = Media('file://${widget.filePath}');
    await _player.open(media, play: false);
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
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Result'),
          ),
          body: CustomPaint(
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
        ),
      );
    });
  }

  Widget _buildVideoPlayer(BoxConstraints constraints) {
    return FutureBuilder<VideoMetadata>(
        future: _videoMetadata,
        builder: (context, snapshot) {
          final aspectRatio = snapshot.data?.resolution.aspectRatio ?? 1;
          final rotation = snapshot.data?.rotation ?? 0;

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
                  controller: _controller,
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
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: FutureBuilder<VideoMetadata>(
                future: _videoMetadata,
                builder: (context, snapshot) {
                  var data = snapshot.data;

                  if (data == null ||
                      snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator.adaptive();
                  }

                  return Table(
                    defaultColumnWidth: const IntrinsicColumnWidth(),
                    children: [
                      TableRow(children: [
                        const Text('Generation-Time'),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            '${_numberFormatter.format(_generationTime)} ms',
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
                            formatBytes(data.fileSize),
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
                            'video/${data.extension}',
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
                              data.resolution.width.round(),
                            )} x ${_numberFormatter.format(
                              data.resolution.height.round(),
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
                            '${data.duration.inSeconds} s',
                            style: _valueStyle,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ]),
                    ],
                  );
                }),
          ),
        ),
      ),
    );
  }
}

class PixelTransparentPainter extends CustomPainter {
  /// Creates a new [PixelTransparentPainter] with the given colors.
  ///
  /// The [primary] and [secondary] colors are used to alternate between the
  /// cells in the grid.
  const PixelTransparentPainter({
    required this.primary,
    required this.secondary,
  });

  /// The primary color used for alternating cells in the grid.
  final Color primary;

  /// The secondary color used for alternating cells in the grid.
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
