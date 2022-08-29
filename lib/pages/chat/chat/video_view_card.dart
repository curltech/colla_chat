import 'package:colla_chat/pages/chat/chat/video_view_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:flutter/material.dart';

import '../../../plugin/logger.dart';
import '../../../transport/webrtc/peer_video_render.dart';
import 'controller/peer_connections_controller.dart';

///多个视频窗口的排列
class VideoViewCard extends StatefulWidget {
  const VideoViewCard({Key? key}) : super(key: key);

  @override
  State createState() => _VideoViewCardState();
}

class _VideoViewCardState extends State<VideoViewCard> {
  @override
  initState() {
    super.initState();
    peerConnectionsController.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  Size _calculateSize(int count) {
    double totalWidth = appDataProvider.mobileSize.width;
    double totalHeight = appDataProvider.mobileSize.height;
    var height = totalHeight;
    var width = totalWidth;
    if (count <= 4) {
      height = totalHeight / count;
    } else if (count <= 8) {
      width = totalWidth / 2;
      height = totalHeight / count / 2;
    } else if (count <= 12) {
      width = totalWidth / count / 3;
    } else {
      width = totalWidth / count / 4;
      height = totalHeight / 4;
    }

    return Size(width, height);
  }

  Widget _buildVideoViews(BuildContext context) {
    Map<String, PeerVideoRender> renders =
        peerConnectionsController.videoRenders();
    logger.i('peerConnectionsController videoRenders length:${renders.length}');
    Size size = _calculateSize(renders.length);
    List<Widget> videoViews = [];
    Widget videoView = VideoViewWidget(
      render: renders.values.last,
      width: size.width,
      height: size.height,
    );
    videoViews.add(videoView);
    // for (var render in renders.values) {
    //   Widget videoView = VideoViewWidget(
    //     render: render,
    //     width: size.width,
    //     height: size.height,
    //   );
    //   videoViews.add(videoView);
    // }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(2.0),
      controller: ScrollController(),
      child: Wrap(runSpacing: 2.0, spacing: 2.0, children: videoViews),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildVideoViews(context);
  }

  @override
  void dispose() {
    peerConnectionsController.removeListener(_update);
    super.dispose();
  }
}
