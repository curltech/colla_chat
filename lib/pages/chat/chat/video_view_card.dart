import 'package:colla_chat/pages/chat/chat/single_video_view_widget.dart';
import 'package:flutter/material.dart';

import '../../../plugin/logger.dart';
import '../../../transport/webrtc/peer_video_render.dart';
import 'controller/local_media_controller.dart';

///多个视频窗口的排列
class VideoViewCard extends StatefulWidget {
  final VideoRenderController controller;
  final Color? color;

  const VideoViewCard({Key? key, required this.controller, this.color})
      : super(key: key);

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

  Size _calculateSize(double totalWidth, double totalHeight, int count) {
    var height = totalHeight - 6;
    var width = totalWidth - 4;
    if (count <= 4) {
      height = height / count;
    } else if (count <= 8) {
      width = width / 2;
      height = height / count / 2;
    } else if (count <= 12) {
      width = width / count / 3;
    } else {
      width = width / count / 4;
      height = height / 4;
    }

    return Size(width, height);
  }

  Widget _buildVideoViews(BuildContext context, BoxConstraints constraints) {
    Map<String, PeerVideoRender> renders = widget.controller.videoRenders();
    logger.i('VideoRenderController videoRenders length:${renders.length}');
    Size size = _calculateSize(
        constraints.maxWidth, constraints.maxHeight, renders.length);
    List<Widget> videoViews = [];
    for (var render in renders.values) {
      Widget videoView = SingleVideoViewWidget(
          render: render,
          width: size.width,
          height: size.height,
          color: widget.color);
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
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return _buildVideoViews(context, constraints);
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }
}
