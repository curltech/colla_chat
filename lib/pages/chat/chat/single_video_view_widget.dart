import 'package:flutter/material.dart';

import '../../../transport/webrtc/peer_video_render.dart';
import 'controller/peer_connections_controller.dart';

///单个视频窗口
class SingleVideoViewWidget extends StatefulWidget {
  final PeerVideoRender render;
  final double? height;
  final double? width;
  final Color? color;

  const SingleVideoViewWidget(
      {Key? key, required this.render, this.height, this.width, this.color})
      : super(key: key);

  @override
  State createState() => _SingleVideoViewWidgetState();
}

class _SingleVideoViewWidgetState extends State<SingleVideoViewWidget> {
  @override
  initState() {
    super.initState();
    peerConnectionsController.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  ///单个视频窗口
  Widget _buildSingleVideoView(BuildContext context) {
    Widget videoView = widget.render.createVideoView(
        mirror: true,
        height: widget.height,
        width: widget.width,
        color: widget.color);

    return videoView;
  }

  @override
  Widget build(BuildContext context) {
    return _buildSingleVideoView(context);
  }

  @override
  void dispose() {
    peerConnectionsController.removeListener(_update);
    super.dispose();
  }
}
