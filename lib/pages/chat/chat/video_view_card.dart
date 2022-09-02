import 'package:colla_chat/pages/chat/chat/single_video_view_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:flutter/material.dart';

import '../../../plugin/logger.dart';
import '../../../transport/webrtc/peer_video_render.dart';
import 'controller/local_media_controller.dart';

///多个视频窗口的排列
class VideoViewCard extends StatefulWidget {
  final VideoRenderController controller;

  const VideoViewCard({Key? key, required this.controller}) : super(key: key);

  @override
  State createState() => _VideoViewCardState();
}

class _VideoViewCardState extends State<VideoViewCard> {
  @override
  initState() {
    super.initState();
    widget.controller.addListener(_update);
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
    Map<String, PeerVideoRender> renders = widget.controller.videoRenders();
    logger.i('VideoRenderController videoRenders length:${renders.length}');
    Size size = _calculateSize(renders.length);
    List<Widget> videoViews = [];
    for (var render in renders.values) {
      Widget videoView = SingleVideoViewWidget(
        render: render,
        width: size.width,
        height: size.height,
      );
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

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }
}
