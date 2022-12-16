import 'package:colla_chat/pages/chat/chat/controller/local_media_controller.dart';
import 'package:colla_chat/pages/chat/chat/video/single_video_view_widget.dart';
import 'package:colla_chat/transport/webrtc/peer_video_render.dart';
import 'package:flutter/material.dart';

///多个视频窗口的排列
class VideoViewCard extends StatefulWidget {
  final VideoRenderController videoRenderController;
  final Color? color;

  const VideoViewCard(
      {Key? key, required this.videoRenderController, this.color})
      : super(key: key);

  @override
  State createState() => _VideoViewCardState();
}

class _VideoViewCardState extends State<VideoViewCard> {
  @override
  initState() {
    super.initState();
  }

  _update() {
    setState(() {});
  }

  Widget _buildVideoViews(BuildContext context, BoxConstraints constraints) {
    List<PeerVideoRender> videoRenders =
        widget.videoRenderController.videoRenders.values.toList();
    int crossAxisCount = 1;
    if (videoRenders.length > 1) {
      crossAxisCount = 2;
    }
    List<Widget> videoViews = [];
    for (var render in videoRenders) {
      Widget videoView = SingleVideoViewWidget(
          render: render,
          // width: size.width,
          // height: size.height,
          color: widget.color);
      videoViews.add(videoView);
    }
    return GridView.builder(
        itemCount: videoRenders.length,
        //SliverGridDelegateWithFixedCrossAxisCount 构建一个横轴固定数量Widget
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            //横轴元素个数
            crossAxisCount: crossAxisCount,
            //纵轴间距
            mainAxisSpacing: 5.0,
            //横轴间距
            crossAxisSpacing: 5.0,
            //子组件宽高长度比例
            childAspectRatio: 1),
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
    super.dispose();
  }
}
