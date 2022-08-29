import 'package:colla_chat/pages/chat/chat/video_view_card.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:flutter/material.dart';

import '../../../widgets/common/widget_mixin.dart';

///视频通话窗口，显示多个小视频窗口，每个小窗口代表一个对方，其中一个是自己
class VideoChatWidget extends StatefulWidget with TileDataMixin {
  VideoChatWidget({
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VideoChatWidgetState();
  }

  @override
  bool get withLeading => false;

  @override
  String get routeName => 'video_chat';

  @override
  Icon get icon => const Icon(Icons.video_call);

  @override
  String get title => 'VideoChat';
}

class _VideoChatWidgetState extends State<VideoChatWidget> {
  @override
  void initState() {
    super.initState();
  }

  Widget _buildVideoViewCard(BuildContext context) {
    return const VideoViewCard();
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        withLeading: true,
        child: Stack(children: [
          _buildVideoViewCard(context),
        ]));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
