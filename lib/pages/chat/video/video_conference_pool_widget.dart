import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/video_chat_message_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/chat/chat_summary.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/transport/webrtc/remote_video_render_controller.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

///联系人和群的查询界面
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
    _buildConferenceTileData();
  }

  _buildConferenceTileData() {
    Map<String, RemoteVideoRenderController> remoteVideoRenderControllers =
        videoConferenceRenderPool.remoteVideoRenderControllers;
    List<TileData> tiles = [];
    if (remoteVideoRenderControllers.isNotEmpty) {
      for (var remoteVideoRenderController
          in remoteVideoRenderControllers.values) {
        VideoChatMessageController videoChatMessageController =
            remoteVideoRenderController.videoChatMessageController;
        Conference? conference = videoChatMessageController.conference;
        if (conference == null) {
          continue;
        }
        var conferenceId = conference.conferenceId;
        var conferenceName = conference.name;
        var conferenceOwnerName = conference.conferenceOwnerName;
        var topic = conference.topic;
        TileData tile = TileData(
            prefix: conference.avatarImage ?? AppImage.lgAppImage,
            title: conferenceName,
            titleTail: conferenceOwnerName,
            subtitle: topic,
            selected: false,
            isThreeLine: false,
            routeName: 'conference_edit');
        List<TileData> slideActions = [];
        TileData deleteSlideAction = TileData(
            title: 'Delete',
            prefix: Icons.playlist_remove_outlined,
            onTap: (int index, String label, {String? subtitle}) async {
              videoConferenceRenderPool.closeConferenceId(conferenceId);
              videoConferenceRenderPool.conferenceId = null;
              if (mounted) {
                DialogUtil.info(context,
                    content:
                        '${AppLocalizations.t('Conference:')} ${conference.name}${AppLocalizations.t(' is closed')}');
              }
            });
        slideActions.add(deleteSlideAction);
        tile.slideActions = slideActions;

        List<TileData> endSlideActions = [];
        TileData chatSlideAction = TileData(
            title: 'Chat',
            prefix: Icons.chat,
            onTap: (int index, String label, {String? subtitle}) async {
              ChatSummary? chatSummary = await chatSummaryService
                  .findOneByPeerId(conference.conferenceId);
              chatSummary ??=
                  await chatSummaryService.upsertByConference(conference);
              chatMessageController.chatSummary = chatSummary;
              indexWidgetProvider.push('chat_message');
            });
        endSlideActions.add(chatSlideAction);
        tile.endSlideActions = endSlideActions;

        tiles.add(tile);
      }
    }
    _conferenceTileData.value = tiles;
  }

  Widget _buildVideoConferenceListView(BuildContext context) {
    var conferenceView = ValueListenableBuilder(
        valueListenable: _conferenceTileData,
        builder: (context, value, child) {
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
    super.dispose();
  }
}
