import 'package:flutter/material.dart';
import 'package:pip_flutter/pipflutter_player.dart';
import 'package:pip_flutter/pipflutter_player_configuration.dart';
import 'package:pip_flutter/pipflutter_player_controller.dart';
import 'package:pip_flutter/pipflutter_player_data_source.dart';
import 'package:pip_flutter/pipflutter_player_data_source_type.dart';

/// video_player以画中画模式播放视频，很久没更新了
/// pipFlutterPlayerController.enablePictureInPicture(pipFlutterPlayerKey);
/// pipFlutterPlayerController.disablePictureInPicture();
class VideoPlayerPipWidget extends StatelessWidget {
  final GlobalKey pipFlutterPlayerKey = GlobalKey();
  late final PipFlutterPlayerController pipFlutterPlayerController;
  final PipFlutterPlayerConfiguration pipFlutterPlayerConfiguration =
      const PipFlutterPlayerConfiguration(
    aspectRatio: 16 / 9,
    fit: BoxFit.contain,
  );
  late final PipFlutterPlayerDataSource dataSource;

  VideoPlayerPipWidget(
      {required PipFlutterPlayerDataSourceType type,
      required String url,
      super.key}) {
    pipFlutterPlayerController =
        PipFlutterPlayerController(pipFlutterPlayerConfiguration);
    dataSource = PipFlutterPlayerDataSource(
      type,
      url,
    );
    pipFlutterPlayerController.setupDataSource(dataSource);
    pipFlutterPlayerController
        .setPipFlutterPlayerGlobalKey(pipFlutterPlayerKey);
  }

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: 1,
      fit: FlexFit.loose,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: PipFlutterPlayer(
          controller: pipFlutterPlayerController,
          key: pipFlutterPlayerKey,
        ),
      ),
    );
  }
}
