import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../widgets/common/app_bar_view.dart';
import '../widgets/common/widget_mixin.dart';

class MobileVideoPlayerWidget extends StatefulWidget with TileDataMixin {
  const MobileVideoPlayerWidget({Key? key}) : super(key: key);

  @override
  State createState() => _MobileVideoPlayerWidgetState();

  @override
  String get routeName => 'video_player';

  @override
  bool get withLeading => true;

  @override
  IconData get iconData => Icons.video_call;

  @override
  String get title => 'VideoPlayer';
}

class _MobileVideoPlayerWidgetState extends State<MobileVideoPlayerWidget> {
  late FlickManager flickManager;
  late VideoPlayerController controller;
  bool startedPlaying = false;

  @override
  void initState() {
    super.initState();
    flickManager = FlickManager(
      videoPlayerController: VideoPlayerController.network("url"),
    );
    controller = VideoPlayerController.asset('assets/Butterfly-209.mp4');
    controller = VideoPlayerController.network(
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      closedCaptionFile: _loadCaptions(),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized,
        // even before the play button has been pressed.
        setState(() {});
      });
  }

  Future<ClosedCaptionFile> _loadCaptions() async {
    final String fileContents = await DefaultAssetBundle.of(context)
        .loadString('assets/bumble_bee_captions.vtt');
    return WebVTTCaptionFile(
        fileContents); // For vtt files, use WebVTTCaptionFile
  }

  Future<bool> _started() async {
    await controller.initialize();
    await controller.play();
    startedPlaying = true;
    return true;
  }

  Widget _buildVideoPlayer(BuildContext context) {
    return Center(
      child: controller.value.isInitialized
          ? AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: <Widget>[
                  VideoPlayer(controller),
                  ClosedCaption(text: controller.value.caption.text),
                  VideoProgressIndicator(controller, allowScrubbing: true),
                ],
              ),
            )
          : Container(),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget>? rightWidgets = [];
    var playBtn = InkWell(
        onTap: () {
          setState(() {
            controller.value.isPlaying ? controller.pause() : controller.play();
          });
        },
        child:
            Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow));
    rightWidgets.add(playBtn);
    var appBarView = AppBarView(
      title: widget.title,
      withLeading: widget.withLeading,
      rightWidgets: rightWidgets,
      child: FlickVideoPlayer(flickManager: flickManager),
    );

    return appBarView;
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
    flickManager.dispose();
  }
}
