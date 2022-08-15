import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:flutter/material.dart';

import '../../../entity/chat/chat.dart';
import '../../../plugin/logger.dart';
import '../../../transport/webrtc/advanced_peer_connection.dart';
import '../../../transport/webrtc/peer_connection_pool.dart';
import '../../../transport/webrtc/peer_video_render.dart';
import '../../../widgets/common/image_widget.dart';
import '../../../widgets/common/widget_mixin.dart';
import 'chat_message_widget.dart';

///视频通话拨出的对话框
class VideoDialOutWidget extends StatefulWidget with TileDataMixin {
  VideoDialOutWidget({
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VideoDialOutWidgetState();
  }

  @override
  bool get withLeading => false;

  @override
  String get routeName => 'video_dialout';

  @override
  Icon get icon => const Icon(Icons.video_call);

  @override
  String get title => 'VideoDialout';
}

class _VideoDialOutWidgetState extends State<VideoDialOutWidget> {
  late final String peerId;
  late final String name;
  late final String? clientId;

  @override
  void initState() {
    super.initState();
    chatMessageController.addListener(_update);
    ChatSummary? chatSummary = chatMessageController.chatSummary;
    if (chatSummary != null) {
      peerId = chatSummary.peerId!;
      name = chatSummary.name!;
      clientId = chatSummary.clientId;
    } else {
      logger.e('chatSummary is null');
    }
  }

  _update() {
    setState(() {});
  }

  Future<Widget> _buildVideoView() async {
    AdvancedPeerConnection? advancedPeerConnection =
        peerConnectionPool.getOne(peerId, clientId: clientId);
    if (advancedPeerConnection != null &&
        advancedPeerConnection.status == PeerConnectionStatus.connected) {
      PeerVideoRender render = await PeerVideoRender.from(userMedia: true);
      //advancedPeerConnection.addLocalRender(render);
      await render.bindRTCVideoRender();
      Widget? videoView = render.createVideoView(mirror: true);
      if (videoView != null) {
        return videoView;
      }
    }

    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        withLeading: true,
        child: Stack(children: [
          FutureBuilder(
            future: _buildVideoView(),
            builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
              if (snapshot.hasData) {
                return snapshot.data!;
              } else {
                return const Center(child: Text('No video data'));
              }
            },
          ),
          Column(children: [
            Row(
              children: [
                const ImageWidget(image: ''),
                Column(children: [
                  Text(name),
                  Text(AppLocalizations.t('Invite you video chat...'))
                ])
              ],
            ),
            Row(children: [
              IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.cameraswitch),
                  color: Colors.grey),
              Text(AppLocalizations.t('Switch to audio chat')),
              IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.clear),
                  color: Colors.red),
              IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.video_call),
                  color: Colors.green)
            ]),
            IconButton(
                onPressed: () {
                  indexWidgetProvider.pop();
                },
                icon: const Icon(Icons.call_end),
                color: Colors.red),
          ])
        ]));
  }

  @override
  void dispose() {
    chatMessageController.removeListener(_update);
    super.dispose();
  }
}
