import 'package:colla_chat/pages/chat/chat/controller/local_media_controller.dart';
import 'package:colla_chat/pages/chat/chat/video/single_video_view_widget.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/transport/webrtc/peer_video_render.dart';
import 'package:flutter/material.dart';


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

  Widget _buildVideoViews(BuildContext context, BoxConstraints constraints) {
    Map<String, PeerVideoRender> renders = widget.controller.videoRenders();
    logger.i('VideoRenderController videoRenders length:${renders.length}');
    List<Widget> videoViews = [];
    for (var render in renders.values) {
      Widget videoView = SingleVideoViewWidget(
          render: render,
          // width: size.width,
          // height: size.height,
          color: widget.color);
      videoViews.add(videoView);
    }
    return GridView.builder(
        itemCount: videoViews.length,
        //SliverGridDelegateWithFixedCrossAxisCount 构建一个横轴固定数量Widget
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            //横轴元素个数
            crossAxisCount: widget.controller.crossAxisCount,
            //纵轴间距
            mainAxisSpacing: 5.0,
            //横轴间距
            crossAxisSpacing: 5.0,
            //子组件宽高长度比例
            childAspectRatio: 9 / 16),
        itemBuilder: (BuildContext context, int index) {
          //Widget Function(BuildContext context, int index)
          return videoViews[index];
        });
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
