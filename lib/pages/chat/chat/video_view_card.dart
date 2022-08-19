import 'package:colla_chat/pages/chat/chat/video_view_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:flutter/material.dart';

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
  }

  double _calculateWidth(double totalWidth, int count) {
    if (count <= 4) {
      return totalWidth;
    }
    if (count <= 8) {
      return totalWidth / 2;
    }
    if (count <= 12) {
      return totalWidth / 3;
    }
    return totalWidth / 4;
  }

  Widget _buildVideoViews(BuildContext context) {
    Map<String, PeerVideoRender> renders =
        peerConnectionsController.videoRenders();
    double totalWidth = appDataProvider.mobileSize.width;
    double width = _calculateWidth(totalWidth, renders.length);
    List<Widget> videoViews = [];
    for (var render in renders.values) {
      Widget videoView = VideoViewWidget(render: render, width: width);
      videoViews.add(videoView);
    }
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
}
