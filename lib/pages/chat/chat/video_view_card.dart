import 'package:colla_chat/pages/chat/chat/video_view_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../plugin/logger.dart';
import '../../../transport/webrtc/advanced_peer_connection.dart';
import '../../../transport/webrtc/peer_video_render.dart';
import 'controller/peer_connections_controller.dart';

///多个视频窗口的排列
class VideoViewCard extends StatefulWidget {
  const VideoViewCard({Key? key}) : super(key: key);

  @override
  State createState() => _VideoViewCardState();
}

class _VideoViewCardState extends State<VideoViewCard> {
  RTCVideoRenderer render = RTCVideoRenderer();

  @override
  initState() {
    super.initState();
    peerConnectionsController.addListener(_update);
    render.initialize();
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

  Widget _buildVideoView(BuildContext context) {
    AdvancedPeerConnection advancedPeerConnection =
        peerConnectionsController.get();
    Map<String, MediaStream> streams =
        advancedPeerConnection.basePeerConnection.streams;
    if (streams.isEmpty) {
      return Container();
    }
    render.srcObject = streams.values.last;
    var contain = FutureBuilder(
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
      if (snapshot.hasData) {
        return Container(
          margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
          width: 320.0,
          height: 240.0,
          decoration: const BoxDecoration(color: Colors.black),
          //远端视频渲染
          child: RTCVideoView(render),
        );
      } else {
        return Container();
      }
    });

    return contain;
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
    return _buildVideoView(context);
  }

  @override
  void dispose() {
    peerConnectionsController.removeListener(_update);
    super.dispose();
  }
}
