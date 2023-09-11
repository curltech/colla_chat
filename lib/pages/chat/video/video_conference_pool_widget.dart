import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/conference_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/linkman/conference/conference_show_widget.dart';
import 'package:colla_chat/pages/chat/video/video_conference_connection_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/transport/webrtc/p2p/p2p_conference_client.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

///会议池的显示界面
class VideoConferencePoolWidget extends StatelessWidget with TileDataMixin {
  final VideoConferenceConnectionWidget videoConferenceConnectionWidget =
      VideoConferenceConnectionWidget();

  VideoConferencePoolWidget({Key? key}) : super(key: key) {
    indexWidgetProvider.define(videoConferenceConnectionWidget);
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'video_conference_pool';

  @override
  IconData get iconData => Icons.meeting_room;

  @override
  String get title => 'Video conference pool';

  List<TileData> _buildConferenceTileData(BuildContext context) {
    List<P2pConferenceClient> p2pConferenceClients =
        p2pConferenceClientPool.p2pConferenceClients;
    List<TileData> tiles = [];
    if (p2pConferenceClients.isNotEmpty) {
      for (P2pConferenceClient p2pConferenceClient in p2pConferenceClients) {
        ConferenceChatMessageController conferenceChatMessageController =
            p2pConferenceClient.conferenceChatMessageController;
        Conference? conference = conferenceChatMessageController.conference;
        if (conference == null) {
          continue;
        }
        var conferenceId = conference.conferenceId;
        var conferenceName = conference.name;
        var conferenceOwnerName = conference.conferenceOwnerName;
        var topic = conference.topic;
        TileData tile = TileData(
            prefix: conference.avatarImage,
            title: conferenceName,
            titleTail: topic,
            subtitle: conferenceId,
            selected: p2pConferenceClientPool.conferenceId == conferenceId,
            isThreeLine: false,
            onTap: (int index, String title, {String? subtitle}) {},
            routeName: 'video_conference_connection');
        List<TileData> slideActions = [];
        if (p2pConferenceClientPool.conferenceId != conferenceId) {
          TileData checkSlideAction = TileData(
              title: 'Check',
              prefix: Icons.playlist_add_check_outlined,
              onTap: (int index, String label, {String? subtitle}) async {
                p2pConferenceClientPool.conferenceId = conferenceId;
                DialogUtil.info(context,
                    content:
                        '${AppLocalizations.t('Conference:')} ${conference.name}${AppLocalizations.t(' is set current')}');
              });
          slideActions.add(checkSlideAction);
        }
        TileData deleteSlideAction = TileData(
            title: 'Delete',
            prefix: Icons.playlist_remove_outlined,
            onTap: (int index, String label, {String? subtitle}) async {
              p2pConferenceClientPool.terminate(conferenceId);
              p2pConferenceClientPool.conferenceId = null;
              DialogUtil.info(context,
                  content:
                      '${AppLocalizations.t('Conference:')} ${conference.name}${AppLocalizations.t(' is closed')}');
            });
        slideActions.add(deleteSlideAction);
        TileData conferenceSlideAction = TileData(
            title: 'Conference',
            prefix: Icons.meeting_room,
            onTap: (int index, String label, {String? subtitle}) async {
              conferenceNotifier.value = conference;
              indexWidgetProvider.push('conference_show');
            });
        slideActions.add(conferenceSlideAction);
        tile.slideActions = slideActions;

        List<TileData> endSlideActions = [];
        TileData renegotiateSlideAction = TileData(
            title: 'Renegotiate',
            prefix: Icons.repeat_one_outlined,
            onTap: (int index, String label, {String? subtitle}) async {
              p2pConferenceClientPool.p2pConferenceClient?.renegotiate();
              DialogUtil.info(context,
                  content:
                      '${AppLocalizations.t('Conference:')} ${conference.name}${AppLocalizations.t(' is renegotiate')}');
            });
        endSlideActions.add(renegotiateSlideAction);
        TileData toggleIceSlideAction = TileData(
            title: 'Toggle',
            prefix: Icons.recycling_outlined,
            onTap: (int index, String label, {String? subtitle}) async {
              p2pConferenceClientPool.p2pConferenceClient
                  ?.renegotiate(toggle: true);
              DialogUtil.info(context,
                  content:
                      '${AppLocalizations.t('Conference:')} ${conference.name}${AppLocalizations.t(' is toggle renegotiate')}');
            });
        endSlideActions.add(toggleIceSlideAction);
        tile.endSlideActions = endSlideActions;

        tiles.add(tile);
      }
    }
    return tiles;
  }

  Widget _buildVideoConferenceListView(BuildContext context) {
    var conferenceView = DataListView(
      tileData: _buildConferenceTileData(context),
    );

    return conferenceView;
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: title,
      withLeading: withLeading,
      child: _buildVideoConferenceListView(context),
    );
  }
}
