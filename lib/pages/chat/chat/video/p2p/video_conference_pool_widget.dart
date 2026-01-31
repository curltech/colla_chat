import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/conference_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/video/p2p/video_conference_connection_widget.dart';
import 'package:colla_chat/pages/chat/linkman/conference/conference_edit_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/transport/webrtc/p2p/p2p_conference_client.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

///会议池的显示界面
class VideoConferencePoolWidget extends StatelessWidget with DataTileMixin {
  final VideoConferenceConnectionWidget videoConferenceConnectionWidget =
      VideoConferenceConnectionWidget();

  VideoConferencePoolWidget({super.key}) {
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



  List<DataTile> _buildConferenceTileData(BuildContext context) {
    List<P2pConferenceClient> p2pConferenceClients =
        p2pConferenceClientPool.conferenceClients;
    List<DataTile> tiles = [];
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
        DataTile tile = DataTile(
          prefix: conference.avatarImage,
          title: conferenceName,
          titleTail: topic,
          subtitle: conferenceId,
          selected: p2pConferenceClientPool.conferenceId == conferenceId,
          isThreeLine: false,
          onTap: (int index, String title, {String? subtitle}) async {
            p2pConferenceClientPool.conferenceId == conferenceId;
            indexWidgetProvider.push('video_conference_connection');
            return null;
          },
        );
        List<DataTile> slideActions = [];
        if (p2pConferenceClientPool.conferenceId != conferenceId) {
          DataTile checkSlideAction = DataTile(
              title: 'Check',
              prefix: Icons.playlist_add_check_outlined,
              onTap: (int index, String label, {String? subtitle}) async {
                p2pConferenceClientPool.conferenceId = conferenceId;
                DialogUtil.info(
                    content:
                        '${AppLocalizations.t('Conference:')} ${conference.name}${AppLocalizations.t(' is set current')}');
              });
          slideActions.add(checkSlideAction);
        }
        DataTile deleteSlideAction = DataTile(
            title: 'Delete',
            prefix: Icons.playlist_remove_outlined,
            onTap: (int index, String label, {String? subtitle}) async {
              p2pConferenceClientPool.terminate(conferenceId: conferenceId);
              DialogUtil.info(
                  content:
                      '${AppLocalizations.t('Conference:')} ${conference.name}${AppLocalizations.t(' is closed')}');
            });
        slideActions.add(deleteSlideAction);
        DataTile conferenceSlideAction = DataTile(
            title: 'Conference',
            prefix: Icons.meeting_room,
            onTap: (int index, String label, {String? subtitle}) async {
              conferenceNotifier.value = conference;
              indexWidgetProvider.push('conference_show');
            });
        slideActions.add(conferenceSlideAction);
        tile.slideActions = slideActions;

        List<DataTile> endSlideActions = [];
        DataTile renegotiateSlideAction = DataTile(
            title: 'Renegotiate',
            prefix: Icons.repeat_one_outlined,
            onTap: (int index, String label, {String? subtitle}) async {
              p2pConferenceClientPool.conferenceClient?.renegotiate();
              DialogUtil.info(
                  content:
                      '${AppLocalizations.t('Conference:')} ${conference.name}${AppLocalizations.t(' is renegotiate')}');
            });
        endSlideActions.add(renegotiateSlideAction);
        DataTile toggleIceSlideAction = DataTile(
            title: 'Toggle',
            prefix: Icons.recycling_outlined,
            onTap: (int index, String label, {String? subtitle}) async {
              p2pConferenceClientPool.conferenceClient
                  ?.renegotiate(toggle: true);
              DialogUtil.info(
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
    List<DataTile> tileData = _buildConferenceTileData(context);
    var conferenceView = DataListView(
      itemCount: tileData.length,
      itemBuilder: (BuildContext context, int index) {
        return tileData[index];
      },
    );

    return conferenceView;
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: title,
      helpPath: routeName,
      withLeading: withLeading,
      child: _buildVideoConferenceListView(context),
    );
  }
}
