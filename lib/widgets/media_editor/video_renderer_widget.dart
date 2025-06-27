import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:colla_chat/widgets/media/playlist_widget.dart';
import 'package:colla_chat/widgets/media/video/mediakit_video_player.dart';
import 'package:colla_chat/widgets/media_editor/pro_video_editor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pro_video_editor/core/models/video/video_metadata_model.dart';

/// 视频渲染处理界面，包括旋转，裁剪
class VideoRendererWidget extends StatelessWidget with TileDataMixin {
  VideoRendererWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'video_renderer';

  @override
  IconData get iconData => Icons.video_file_outlined;

  @override
  String get title => 'VideoRenderer';

  final PlaylistController playlistController = PlaylistController();
  late final PlaylistWidget playlistWidget = PlaylistWidget(
    playlistController: playlistController,
  );
  final ValueNotifier<int> index = ValueNotifier<int>(0);
  final SwiperController swiperController = SwiperController();
  late final _player = Player();
  late final _videoController = VideoController(_player);
  late final _previewPlayer = Player();
  late final _previewVideoController = VideoController(_previewPlayer);
  final ValueNotifier<bool> isExporting = ValueNotifier<bool>(false);
  final ValueNotifier<Duration> elapsedTime =
      ValueNotifier<Duration>(Duration.zero);
  late final ProVideoEditor _videoEditor;
  final ValueNotifier<VideoMetadata?> outputMetadata =
      ValueNotifier<VideoMetadata?>(null);
  final ValueNotifier<VideoMetadata?> inputMetadata =
      ValueNotifier<VideoMetadata?>(null);
  StreamBuilder? streamBuilder;

  Future<void> init() async {
    String? filename = playlistController.current?.filename;
    if (filename != null) {
      Media? media = MediaKitMediaSource.media(filename: filename);
      if (media != null) {
        _player.open(
          media,
          play: true,
        );
      }
      _videoEditor = ProVideoEditor(videoInputPath: filename);
      inputMetadata.value = await _videoEditor.getMetadata();
    }
  }

  Future<void> _renderVideo({
    int? startTimeMs,
    int? endTimeMs,
    double? blur,
    Uint8List? overlayImageBytes,
    double? playbackSpeed,
    int? bitrate,
    List<List<double>> colorMatrixList = const [],
    int? cropWidth,
    int? cropHeight,
    int? cropX,
    int? cropY,
    bool flipX = false,
    bool flipY = false,
    double? scaleX,
    double? scaleY,
    int rotateTurns = 0,
    bool enableAudio = true,
  }) async {
    isExporting.value = true;
    Stopwatch sp = Stopwatch()..start();

    final outputFilename = await _videoEditor.edit(
        startTimeMs: startTimeMs,
        endTimeMs: endTimeMs,
        blur: blur,
        overlayImageBytes: overlayImageBytes,
        playbackSpeed: playbackSpeed,
        bitrate: bitrate,
        colorMatrixList: colorMatrixList,
        cropWidth: cropWidth,
        cropHeight: cropHeight,
        cropX: cropX,
        cropY: cropY,
        flipX: flipX,
        flipY: flipY,
        scaleX: scaleX,
        scaleY: scaleY,
        rotateTurns: rotateTurns,
        enableAudio: enableAudio,
        onCreatedProgressStreamBuilder: (StreamBuilder<dynamic> streamBuilder) {
          this.streamBuilder = streamBuilder;
        });

    elapsedTime.value = sp.elapsed;
    ProVideoEditor videoEditor = ProVideoEditor(videoInputPath: outputFilename);
    outputMetadata.value = await videoEditor.getMetadata();

    Media? media = MediaKitMediaSource.media(filename: outputFilename!);
    if (media != null) {
      await _previewPlayer.open(media, play: true);
      await _previewPlayer.play();
    }
    isExporting.value = false;
  }

  FormInputWidget _buildFormInputWidget(BuildContext context) {
    List<PlatformDataField> dataFields = [
      PlatformDataField(
        name: 'rotateTurns',
        label: 'rotateTurns',
        inputType: InputType.text,
        initValue: 1,
        cancel: true,
        prefixIcon: Icon(
          Icons.rotate_90_degrees_ccw,
          color: myself.primary,
        ),
      ),
      PlatformDataField(
        name: 'flipX',
        label: 'flipX',
        inputType: InputType.checkbox,
        initValue: false,
        prefixIcon: Icon(
          Icons.flip,
          color: myself.primary,
        ),
      ),
      PlatformDataField(
        name: 'cropX',
        label: 'cropX',
        initValue: 100,
        inputType: InputType.text,
        cancel: true,
        prefixIcon: Icon(
          Icons.crop,
          color: myself.primary,
        ),
      ),
      PlatformDataField(
        name: 'cropY',
        label: 'cropY',
        initValue: 250,
        inputType: InputType.text,
        cancel: true,
        prefixIcon: Icon(
          Icons.crop,
          color: myself.primary,
        ),
      ),
      PlatformDataField(
        name: 'cropWidth',
        label: 'cropWidth',
        initValue: 700,
        inputType: InputType.text,
        cancel: true,
        prefixIcon: Icon(
          Icons.crop,
          color: myself.primary,
        ),
      ),
      PlatformDataField(
        name: 'cropHeight',
        label: 'cropHeight',
        initValue: 300,
        inputType: InputType.text,
        cancel: true,
        prefixIcon: Icon(
          Icons.crop,
          color: myself.primary,
        ),
      ),
      PlatformDataField(
        name: 'scaleX',
        label: 'scaleX',
        initValue: 0.2,
        inputType: InputType.text,
        cancel: true,
        prefixIcon: Icon(
          Icons.fit_screen_outlined,
          color: myself.primary,
        ),
      ),
      PlatformDataField(
        name: 'scaleY',
        label: 'scaleY',
        initValue: 0.2,
        inputType: InputType.text,
        cancel: true,
        prefixIcon: Icon(
          Icons.fit_screen_outlined,
          color: myself.primary,
        ),
      ),
      PlatformDataField(
        name: 'startTimeMs',
        label: 'startTimeMs',
        initValue: 7000,
        inputType: InputType.text,
        cancel: true,
        prefixIcon: Icon(
          Icons.content_cut_rounded,
          color: myself.primary,
        ),
      ),
      PlatformDataField(
        name: 'endTimeMs',
        label: 'endTimeMs',
        initValue: 20000,
        inputType: InputType.text,
        cancel: true,
        prefixIcon: Icon(
          Icons.content_cut_rounded,
          color: myself.primary,
        ),
      ),
      PlatformDataField(
        name: 'enableAudio',
        label: 'enableAudio',
        initValue: true,
        inputType: InputType.text,
        cancel: true,
        prefixIcon: Icon(
          Icons.volume_off_outlined,
          color: myself.primary,
        ),
      ),
      PlatformDataField(
        name: 'playbackSpeed',
        label: 'playbackSpeed',
        initValue: 2,
        inputType: InputType.text,
        cancel: true,
        prefixIcon: Icon(
          Icons.speed_outlined,
          color: myself.primary,
        ),
      ),
      PlatformDataField(
        name: 'bitrate',
        label: 'bitrate',
        initValue: 1000000,
        inputType: InputType.text,
        cancel: true,
        prefixIcon: Icon(
          Icons.animation,
          color: myself.primary,
        ),
      ),
      PlatformDataField(
        name: 'blur',
        label: 'blur',
        initValue: 5,
        inputType: InputType.text,
        cancel: true,
        prefixIcon: Icon(
          Icons.blur_circular_outlined,
          color: myself.primary,
        ),
      ),
    ];

    FormInputController formInputController = FormInputController(dataFields);

    return FormInputWidget(
      mainAxisAlignment: MainAxisAlignment.start,
      // height: appDataProvider.portraitSize.height * 0.3,
      spacing: 10.0,
      onOk: (Map<String, dynamic> values) async {
        _onOk(values);
      },
      controller: formInputController,
    );
  }

  _onOk(Map<String, dynamic> values) {
    int? startTimeMs = values['startTimeMs'];
    int? endTimeMs = values['endTimeMs'];
    double? blur = values['blur'];
    Uint8List? overlayImageBytes = values['overlayImageBytes'];
    double? playbackSpeed = values['playbackSpeed'];
    int? bitrate = values['bitrate'];
    int? cropWidth = values['cropWidth'];
    int? cropHeight = values['cropHeight'];
    int? cropX = values['cropX'];
    int? cropY = values['cropY'];
    bool flipX = values['flipX'];
    bool flipY = values['flipY'];
    double? scaleX = values['scaleX'];
    double? scaleY = values['scaleY'];
    int rotateTurns = values['rotateTurns'];
    bool enableAudio = values['enableAudio'];

    _renderVideo(
        startTimeMs: startTimeMs,
        endTimeMs: endTimeMs,
        blur: blur,
        overlayImageBytes: overlayImageBytes,
        playbackSpeed: playbackSpeed,
        bitrate: bitrate,
        cropWidth: cropWidth,
        cropHeight: cropHeight,
        cropX: cropX,
        cropY: cropY,
        flipX: flipX,
        flipY: flipY,
        scaleX: scaleX,
        scaleY: scaleY,
        rotateTurns: rotateTurns,
        enableAudio: enableAudio);
  }

  Widget _buildVideoPlayer(BuildContext context) {
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
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: appDataProvider.secondaryBodyWidth,
                ),
                child: _buildSourceVideoPlayer(),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: appDataProvider.secondaryBodyWidth,
                ),
                child: _buildTargetVideoPlayer(),
              ),
            ],
          );
        }
        return nilBox;
      },
    );

    return Center(
      child: mediaView,
    );
  }

  Widget _buildSourceVideoPlayer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 5,
      children: [
        const Text('Source video'),
        AspectRatio(
          aspectRatio: 1280 / 720,
          child: Video(controller: _videoController),
        ),
        Text(
          'time: ${inputMetadata.value?.duration},bytes in ${inputMetadata.value?.fileSize}',
        ),
      ],
    );
  }

  Widget _buildTargetVideoPlayer() {
    return ValueListenableBuilder(
        valueListenable: isExporting,
        builder: (BuildContext context, bool isExporting, Widget? child) {
          if (isExporting && streamBuilder != null) {
            return streamBuilder!;
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 5,
            children: [
              const Text('Target video'),
              AspectRatio(
                aspectRatio: 1280 / 720,
                child: Video(controller: _previewVideoController),
              ),
              Text(
                'time: ${outputMetadata.value?.duration},bytes in ${outputMetadata.value?.fileSize}',
              ),
            ],
          );
        });
  }

  List<Widget>? _buildRightWidgets(BuildContext context) {
    List<Widget> children = [];
    Widget btn = ValueListenableBuilder(
        valueListenable: index,
        builder: (BuildContext context, int index, Widget? child) {
          if (index == 0) {
            return Row(children: [
              IconButton(
                tooltip: AppLocalizations.t('Video render'),
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
    children.add(IconButton(
        onPressed: () {
          DialogUtil.popModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return _buildFormInputWidget(context);
              });
        },
        icon: Icon(Icons.draw_outlined)));

    return children;
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: title,
      helpPath: routeName,
      withLeading: true,
      rightWidgets: _buildRightWidgets(context),
      child: _buildVideoPlayer(context),
    );
  }

  void dispose() {
    _player.dispose();
    _previewPlayer.dispose();
  }
}
