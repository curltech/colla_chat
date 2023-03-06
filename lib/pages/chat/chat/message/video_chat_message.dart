import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/linkman/conference/conference_show_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/transport/webrtc/remote_video_render_controller.dart';
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

  @override
  Widget build(BuildContext context) {
    var title = chatMessage.title;
    String? content = chatMessage.content;
    if (content != null) {
      content = chatMessageService.recoverContent(content);
    }
    Color primary = myself.primary;
    Map<String, dynamic> map = JsonUtil.toJson(content);
    Conference conference = Conference.fromJson(map);
    var video = conference.video
        ? ChatMessageContentType.video.name
        : ChatMessageContentType.audio.name;
    Widget actionWidget;
    if (fullScreen) {
      actionWidget = ConferenceShowWidget(conference: conference);
    } else {
      actionWidget = ListTile(
        leading: IconButton(
            onPressed: () {
              videoConferenceRenderPool.conferenceId = null;
              chatMessageController.current = chatMessage;
              indexWidgetProvider.push('video_chat');
            },
            iconSize: AppIconSize.lgSize.width,
            icon: Icon(
              conference.video ? Icons.video_call : Icons.multitrack_audio,
              color: primary,
            )),
        title: Text(
          AppLocalizations.t('$video chat invitation'),
        ),
        subtitle: Text('${conference.name}\n${conference.topic ?? ''}'),
        //dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 5.0),
        horizontalTitleGap: 0,
        minVerticalPadding: 0,
        minLeadingWidth: 5,
      );
    }
    return Card(elevation: 0, child: actionWidget);
  }
}
