import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:flutter/material.dart';

import '../../../../entity/chat/chat.dart';
import '../../../../transport/webrtc/advanced_peer_connection.dart';
import '../../../entity/chat/chat.dart';
import '../../../plugin/logger.dart';
import '../../../transport/webrtc/advanced_peer_connection.dart';
import '../../../transport/webrtc/peer_connection_pool.dart';
import '../../../transport/webrtc/peer_video_render.dart';
import '../../../widgets/common/image_widget.dart';
import '../../../widgets/common/widget_mixin.dart';

///视频通话控制器，内部数据为视频通话的请求消息，当有回执时触发修改
class VideoDialOutController with ChangeNotifier {
  ChatMessage? _chatMessage;

  ChatMessage? _chatReceipt;

  ChatMessage? get chatMessage {
    return _chatMessage;
  }

  set chatMessage(ChatMessage? chatMessage) {
    _chatMessage = chatMessage;
    notifyListeners();
  }

  ChatMessage? get chatReceipt {
    return _chatReceipt;
  }

  set chatReceipt(ChatMessage? chatReceipt) {
    _chatReceipt = chatReceipt;
    notifyListeners();
  }
}

final VideoDialOutController videoDialOutController = VideoDialOutController();

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
  final PeerVideoRender render = PeerVideoRender();

  @override
  void initState() {
    super.initState();
    videoDialOutController.addListener(_update);
    ChatMessage? chatMessage = videoDialOutController.chatMessage;
    if (chatMessage != null) {
      peerId = chatMessage.receiverPeerId!;
      name = chatMessage.receiverName!;
      clientId = chatMessage.receiverClientId;
    } else {
      logger.e('no video chat chatMessage');
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
      await render.createUserMedia();
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
                return Center(child: Text(AppLocalizations.t('No video data')));
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
            const Expanded(child: Center()),
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
    videoDialOutController.removeListener(_update);
    super.dispose();
  }
}
