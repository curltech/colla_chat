import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/message/common_message.dart';
import 'package:colla_chat/pages/chat/linkman/conference/conference_show_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/transport/webrtc/p2p/p2p_conference_client.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:flutter/material.dart';

///消息体：命令消息，由固定文本和icon组成
class VideoChatMessage extends StatelessWidget {
  final bool fullScreen;
  final bool isMyself;
  final ChatMessage chatMessage;

  const VideoChatMessage(
      {Key? key,
      required this.isMyself,
      this.fullScreen = false,
      required this.chatMessage})
      : super(key: key);

  bool isValid(String? startDate, String? endDate) {
    bool valid = true;
    DateTime? eDate;
    if (endDate != null) {
      eDate = DateUtil.toDateTime(endDate);
    } else {
      if (startDate != null) {
        DateTime sDate = DateUtil.toDateTime(startDate);
        eDate = sDate.add(const Duration(days: 1));
      }
    }
    if (eDate != null) {
      DateTime now = DateTime.now();
      if (now.isAfter(eDate)) {
        valid = false;
      }
    }

    return valid;
  }

  @override
  Widget build(BuildContext context) {
    var title = chatMessage.title;
    String? content = chatMessage.content;
    if (content != null) {
      content = chatMessageService.recoverContent(content);
    }

    Map<String, dynamic> map = JsonUtil.toJson(content);
    Conference conference = Conference.fromJson(map);
    bool valid = isValid(conference.startDate, conference.endDate);
    var video = conference.video
        ? ChatMessageContentType.video.name
        : ChatMessageContentType.audio.name;
    Widget actionWidget;
    if (fullScreen) {
      actionWidget =
          ConferenceShowWidget(hasTitle: false, conference: conference);

      return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: const ContinuousRectangleBorder(),
          child: actionWidget);
    } else {
      String subtitle = conference.name;
      if (conference.topic != null) {
        subtitle = '$subtitle\n${conference.topic}';
      }
      var tileData = TileData(
          title: '$video chat invitation',
          subtitle: subtitle,
          dense: false,
          prefix: IconButton(
              tooltip: AppLocalizations.t('Join conference'),
              onPressed: valid
                  ? () async {
                      ChatSummary? chatSummary =
                          chatMessageController.chatSummary;
                      if (chatSummary != null) {
                        await p2pConferenceClientPool.createP2pConferenceClient(
                            chatSummary: chatSummary, chatMessage);
                        indexWidgetProvider.push('video_chat');
                      }
                    }
                  : null,
              iconSize: AppIconSize.mdSize,
              icon: Icon(
                conference.video ? Icons.video_call : Icons.multitrack_audio,
                color: valid ? myself.primary : myself.secondary,
              )));
      actionWidget = DataListTile(
          contentPadding: EdgeInsets.zero,
          horizontalTitleGap: 0.0,
          minVerticalPadding: 0.0,
          minLeadingWidth: 0.0,
          tileData: tileData);

      return CommonMessage(child: actionWidget);
    }
  }
}
