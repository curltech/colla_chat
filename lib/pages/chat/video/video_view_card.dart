import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/pages/chat/video/single_video_view_widget.dart';
import 'package:colla_chat/transport/webrtc/p2p/local_peer_media_stream_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_media_stream.dart';
import 'package:flutter/material.dart';

///多个小视频窗口的排列
class VideoViewCard extends StatefulWidget {
  final PeerMediaStreamController peerMediaStreamController;
  final Conference? conference;
  final Function(PeerMediaStream peerMediaStream) onClosed;

  const VideoViewCard(
      {Key? key,
      required this.peerMediaStreamController,
      required this.onClosed,
      this.conference})
      : super(key: key);

  @override
  State createState() => _VideoViewCardState();
}

class _VideoViewCardState extends State<VideoViewCard> {
  @override
  initState() {
    super.initState();
    widget.peerMediaStreamController.addListener(_update);
  }

  _update() {
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildVideoViews(BuildContext context, BoxConstraints constraints) {
    List<PeerMediaStream> peerMediaStreams =
        widget.peerMediaStreamController.getPeerMediaStreams().values.toList();
    int crossAxisCount = 1;
    if (peerMediaStreams.length > 1) {
      crossAxisCount = 2;
    }
    List<Widget> videoViews = [];
    for (var peerMediaStream in peerMediaStreams) {
      Widget videoView = SingleVideoViewWidget(
        peerMediaStreamController: widget.peerMediaStreamController,
        onClosed: widget.onClosed,
        conference: widget.conference,
        peerMediaStream: peerMediaStream,
        // width: size.width,
        // height: size.height,
      );
      videoViews.add(videoView);
    }
    if (videoViews.isEmpty) {
      return Container();
    }
    return GridView.builder(
        itemCount: videoViews.length,
        //SliverGridDelegateWithFixedCrossAxisCount 构建一个横轴固定数量Widget
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            //横轴元素个数
            crossAxisCount: crossAxisCount,
            //纵轴间距
            mainAxisSpacing: 1.0,
            //横轴间距
            crossAxisSpacing: 1.0,
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
    widget.peerMediaStreamController.removeListener(_update);
    super.dispose();
  }
}
