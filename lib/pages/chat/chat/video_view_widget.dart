import 'package:flutter/material.dart';

import '../../../transport/webrtc/peer_video_render.dart';
import 'controller/peer_connections_controller.dart';

///单个视频窗口
class VideoViewWidget extends StatefulWidget {
  final PeerVideoRender render;
  final double? height;
  final double? width;

  const VideoViewWidget(
      {Key? key, required this.render, this.height, this.width})
      : super(key: key);

  @override
  State createState() => _VideoViewWidgetState();
}

class _VideoViewWidgetState extends State<VideoViewWidget> {
  @override
  initState() {
    super.initState();
    peerConnectionsController.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  ///单个视频窗口
  Widget _buildVideoView(BuildContext context) {
    Widget videoView = widget.render.createVideoView(
        mirror: true, height: widget.height, width: widget.width);

    return videoView;
  }

  @override
  Widget build(BuildContext context) {
    return _buildVideoView(context);
  }

  @override
  void dispose() {
    peerConnectionsController.removeListener(_update);
    super.dispose();
  }
}
