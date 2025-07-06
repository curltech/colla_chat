import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/video/single_video_view_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/transport/webrtc/local_peer_media_stream_controller.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

///多个小视频窗口的排列
class VideoViewCard extends StatefulWidget {
  final PeerMediaStreamController peerMediaStreamController;

  const VideoViewCard({
    super.key,
    required this.peerMediaStreamController,
  });

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
    List<String>? peerIds =
        widget.peerMediaStreamController.peerMediaStreams.keys.toList();
    int crossAxisCount = 1;
    double secondaryBodyWidth = appDataProvider.secondaryBodyWidth;
    double smallBreakpointLimit = AppDataProvider.smallBreakpointLimit;
    double largeBreakpointLimit = AppDataProvider.largeBreakpointLimit;
    if (secondaryBodyWidth < smallBreakpointLimit) {
      if (peerIds.length > 4) {
        crossAxisCount = 3;
      } else if (peerIds.length > 2) {
        crossAxisCount = 2;
      } else if (secondaryBodyWidth > 450) {
        crossAxisCount = 2;
      }
    } else if (secondaryBodyWidth >= smallBreakpointLimit &&
        secondaryBodyWidth < largeBreakpointLimit) {
      if (peerIds.length > 3) {
        crossAxisCount = 3;
      } else {
        crossAxisCount = peerIds.length;
      }
    } else if (secondaryBodyWidth >= largeBreakpointLimit) {
      if (peerIds.length > 4) {
        crossAxisCount = 4;
      } else {
        crossAxisCount = peerIds.length;
      }
    }
    List<Widget> videoViews = [];
    for (var peerId in peerIds) {
      Widget videoView = SingleVideoViewWidget(
        peerMediaStreamController: widget.peerMediaStreamController,
        peerId: peerId,
        // width: size.width,
        // height: size.height,
      );
      videoViews.add(videoView);
    }
    if (videoViews.isEmpty) {
      return Center(
          child: AutoSizeText(AppLocalizations.t('No media stream')));
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
