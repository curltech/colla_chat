import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/pages/chat/chat/video/p2p/single_video_view_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/transport/webrtc/local_peer_media_stream_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_media_stream.dart';
import 'package:flutter/material.dart';

///多个小视频窗口的排列
class VideoViewCard extends StatefulWidget {
  final PeerMediaStreamController peerMediaStreamController;
  final Function(PeerMediaStream peerMediaStream) onClosed;

  const VideoViewCard({
    Key? key,
    required this.peerMediaStreamController,
    required this.onClosed,
  }) : super(key: key);

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
        widget.peerMediaStreamController.peerMediaStreams;
    int crossAxisCount = 1;
    double secondaryBodyWidth = appDataProvider.secondaryBodyWidth;
    double smallBreakpointLimit = AppDataProvider.smallBreakpointLimit;
    double largeBreakpointLimit = AppDataProvider.largeBreakpointLimit;
    if (secondaryBodyWidth < smallBreakpointLimit) {
      if (peerMediaStreams.length > 4) {
        crossAxisCount = 3;
      } else if (peerMediaStreams.length > 2) {
        crossAxisCount = 2;
      }
    } else if (secondaryBodyWidth >= smallBreakpointLimit &&
        secondaryBodyWidth < largeBreakpointLimit) {
      if (peerMediaStreams.length > 3) {
        crossAxisCount = 3;
      } else {
        crossAxisCount = peerMediaStreams.length;
      }
    } else if (secondaryBodyWidth >= largeBreakpointLimit) {
      if (peerMediaStreams.length > 4) {
        crossAxisCount = 4;
      } else {
        crossAxisCount = peerMediaStreams.length;
      }
    }
    List<Widget> videoViews = [];
    for (var peerMediaStream in peerMediaStreams) {
      Widget videoView = SingleVideoViewWidget(
        peerMediaStreamController: widget.peerMediaStreamController,
        onClosed: widget.onClosed,
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
