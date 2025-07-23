import 'dart:async';
import 'dart:io' as io;
import 'package:card_swiper/card_swiper.dart' show SwiperController, Swiper;
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/media/playlist_widget.dart';
import 'package:colla_chat/widgets/media_editor/pro_video_render.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:pro_video_editor/pro_video_editor.dart';
import 'package:video_player/video_player.dart';

class ProVideoEditorWidget extends StatelessWidget with TileDataMixin {
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
  final ValueNotifier<int> index = ValueNotifier<int>(0);
  final SwiperController swiperController = SwiperController();

  final _outputFormat = VideoOutputFormat.mp4;

  /// Video editor configuration settings.
  late final VideoEditorConfigs _videoConfigs = const VideoEditorConfigs(
    initialMuted: true,
    initialPlay: false,
    isAudioSupported: true,
    minTrimDuration: Duration(seconds: 7),
  );

  /// Indicates whether a seek operation is in progress.
  bool _isSeeking = false;

  /// Stores the currently selected trim duration span.
  TrimDurationSpan? _durationSpan;

  /// Temporarily stores a pending trim duration span.
  TrimDurationSpan? _tempDurationSpan;

  /// 控制视频的播放
  ProVideoController? _proVideoController;

  /// 保存的视频缩略图
  List<ImageProvider>? _thumbnails;

  /// 保存的视频元数据
  late VideoMetadata _videoMetadata;

  /// 缩略图的数目
  final int _thumbnailCount = 7;

  /// 视频渲染类
  late final ProVideoRender _videoRender;

  /// 保存输出的视频文件
  String? _outputVideoFile;

  /// The duration it took to generate the exported video.
  Duration _videoGenerationTime = Duration.zero;
  late VideoPlayerController _videoController;

  final _taskId = DateTime.now().microsecondsSinceEpoch.toString();

  void initializePlayer() async {
    String? filename = playlistController.current?.filename;
    if (filename != null) {
      _videoController = VideoPlayerController.file(io.File(filename));
      await Future.wait([
        _videoController.initialize(),
        _videoController.setLooping(false),
        _videoController.setVolume(_videoConfigs.initialMuted ? 0 : 100),
        _videoConfigs.initialPlay
            ? _videoController.play()
            : _videoController.pause(),
      ]);
      _videoRender = ProVideoRender(videoInputPath: filename);
      _videoMetadata = await _videoRender.getMetadata();
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

  /// 关闭视频编辑
  void onCloseEditor(EditorMode editorMode) async {
    if (editorMode != EditorMode.main) {
      await swiperController.move(0);
    }
    if (_outputVideoFile != null) {
    } else {
      await swiperController.move(0);
    }
  }

  Widget _buildVideoEditor(BuildContext context) {
    Widget mediaView = Swiper(
        itemCount: 2,
        index: index.value,
        controller: swiperController,
        onIndexChanged: (int index) {
          this.index.value = index;
        },
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return playlistWidget;
          }
          if (index == 1) {
            return _buildProImageEditor();
          }
          return nilBox;
        });

    return Center(
      child: mediaView,
    );
  }

  List<Widget>? _buildRightWidgets(BuildContext context) {
    List<Widget> children = [];
    Widget btn = ValueListenableBuilder(
        valueListenable: index,
        builder: (BuildContext context, int index, Widget? child) {
          if (index == 0) {
            return Row(children: [
              IconButton(
                tooltip: AppLocalizations.t('Pro video editor'),
                onPressed: () async {
                  await swiperController.move(1);
                },
                icon: const Icon(Icons.task_alt_outlined),
              ),
              IconButton(
                tooltip: AppLocalizations.t('More'),
                onPressed: () {
                  playlistWidget.showActionCard(context);
                },
                icon: const Icon(Icons.more_horiz_outlined),
              ),
            ]);
          } else {
            return Row(children: [
              IconButton(
                tooltip: AppLocalizations.t('Playlist'),
                onPressed: () async {
                  await swiperController.move(0);
                },
                icon: const Icon(Icons.featured_play_list_outlined),
              ),
            ]);
          }
        });
    children.add(btn);

    return children;
  }

  Widget _buildProImageEditor() {
    return ProImageEditor.video(
      _proVideoController!,
      callbacks: ProImageEditorCallbacks(
        onCompleteWithParameters: generateVideo,
        onCloseEditor: onCloseEditor,
        videoEditorCallbacks: VideoEditorCallbacks(
          onPause: _videoController.pause,
          onPlay: _videoController.play,
          onMuteToggle: (isMuted) {
            _videoController.setVolume(isMuted ? 0 : 100);
          },
          onTrimSpanUpdate: (durationSpan) {
            if (_videoController.value.isPlaying) {
              _proVideoController!.pause();
            }
          },
          onTrimSpanEnd: _seekToPosition,
        ),
      ),
      configs: ProImageEditorConfigs(
        dialogConfigs: DialogConfigs(
          widgets: DialogWidgets(
            loadingDialog: (message, configs) => VideoProgressWidget(
              taskId: _taskId,
            ),
          ),
        ),
        mainEditor: MainEditorConfigs(
          widgets: MainEditorWidgets(
            removeLayerArea: (removeAreaKey, editor, rebuildStream) =>
                VideoEditorRemoveArea(
              removeAreaKey: removeAreaKey,
              editor: editor,
              rebuildStream: rebuildStream,
            ),
          ),
        ),
        paintEditor: const PaintEditorConfigs(
          /// Blur and pixelate are not supported.
          enableModePixelate: false,
          enableModeBlur: false,
        ),
        videoEditor: _videoConfigs.copyWith(
          playTimeSmoothingDuration: const Duration(milliseconds: 600),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Center(
      child: AspectRatio(
        aspectRatio: _videoController.value.size.aspectRatio,
        child: VideoPlayer(
          _videoController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: title,
      helpPath: routeName,
      withLeading: true,
      rightWidgets: _buildRightWidgets(context),
      child: _buildVideoEditor(context),
    );
  }
}

/// 根据taskId显示视频产生的过程，
class VideoProgressWidget extends StatelessWidget {
  const VideoProgressWidget({
    super.key,
    required this.taskId,
  });

  final String taskId;

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
                  child: _buildProgressBody(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBody() {
    return StreamBuilder<ProgressModel>(
        stream: ProVideoEditor.instance.progressStreamById(taskId),
        builder: (context, snapshot) {
          var progress = snapshot.data?.progress ?? 0;
          return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 300),
              builder: (context, animatedValue, _) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  spacing: 10,
                  children: [
                    CircularProgressIndicator(
                      value: animatedValue,
                      // ignore: deprecated_member_use
                      year2023: false,
                    ),
                    Text(
                      '${(animatedValue * 100).toStringAsFixed(1)} / 100',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  ],
                );
              });
        });
  }
}
