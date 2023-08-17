import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/conference_chat_message_controller.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/transport/webrtc/p2p/p2p_conference_client.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

///会议池的显示界面
class VideoConferencePoolWidget extends StatefulWidget {
  const VideoConferencePoolWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _VideoConferencePoolWidgetState();
}

class _VideoConferencePoolWidgetState extends State<VideoConferencePoolWidget> {
  final ValueNotifier<List<TileData>> _conferenceTileData =
      ValueNotifier<List<TileData>>([]);

  @override
  initState() {
    super.initState();
    p2pConferenceClientPool.addListener(_update);
    _buildConferenceTileData();
  }

  _update() {
    _buildConferenceTileData();
  }

  _buildConferenceTileData() {
    Map<String, P2pConferenceClient> remoteVideoRenderControllers =
        p2pConferenceClientPool.remoteVideoRenderControllers;
    List<TileData> tiles = [];
    if (remoteVideoRenderControllers.isNotEmpty) {
      for (var remoteVideoRenderController
          in remoteVideoRenderControllers.values) {
        ConferenceChatMessageController videoChatMessageController =
            remoteVideoRenderController.conferenceChatMessageController;
        Conference? conference = videoChatMessageController.conference;
        if (conference == null) {
          continue;
        }
        var conferenceId = conference.conferenceId;
        var conferenceName = conference.name;
        var conferenceOwnerName = conference.conferenceOwnerName;
        var topic = conference.topic;
        TileData tile = TileData(
            prefix: conference.avatarImage ?? AppImage.mdAppImage,
            title: conferenceName,
            titleTail: conferenceOwnerName,
            subtitle: topic,
            selected: p2pConferenceClientPool.conferenceId == conferenceId,
            isThreeLine: false,
            routeName: 'conference_show');
        List<TileData> slideActions = [];
        TileData deleteSlideAction = TileData(
            title: 'Delete',
            prefix: Icons.playlist_remove_outlined,
            onTap: (int index, String label, {String? subtitle}) async {
              p2pConferenceClientPool.closeConferenceId(conferenceId);
              p2pConferenceClientPool.conferenceId = null;
              if (mounted) {
                DialogUtil.info(context,
                    content:
                        '${AppLocalizations.t('Conference:')} ${conference.name}${AppLocalizations.t(' is closed')}');
              }
            });
        slideActions.add(deleteSlideAction);
        tile.slideActions = slideActions;

        tiles.add(tile);
      }
    }
    _conferenceTileData.value = tiles;
  }

  Widget _buildVideoConferenceListView(BuildContext context) {
    var conferenceView = ValueListenableBuilder(
        valueListenable: _conferenceTileData,
        builder: (context, value, child) {
          if (value.isEmpty) {
            return Center(
                child: CommonAutoSizeText(
                    AppLocalizations.t('No active conference in pool'),
                    style: const TextStyle(color: Colors.white)));
          }
          return DataListView(
            tileData: value,
          );
        });

    return conferenceView;
  }

  @override
  Widget build(BuildContext context) {
    return _buildVideoConferenceListView(context);
  }

  @override
  void dispose() {
    p2pConferenceClientPool.removeListener(_update);
    super.dispose();
  }
}
