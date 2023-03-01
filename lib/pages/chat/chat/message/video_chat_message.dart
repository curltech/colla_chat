import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/linkman/conference/conference_show_widget.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:flutter/material.dart';

///消息体：命令消息，由固定文本和icon组成
class VideoChatMessage extends StatelessWidget {
  final bool fullScreen;
  final bool isMyself;
  final String? title;
  final String content;

  const VideoChatMessage(
      {Key? key,
      required this.isMyself,
      this.fullScreen = false,
      this.title,
      required this.content})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color primary = myself.primary;
    Map<String, dynamic> map = JsonUtil.toJson(content);
    Conference conference = Conference.fromJson(map);
    Widget actionWidget;
    if (fullScreen) {
      actionWidget = ConferenceShowWidget(conference: conference);
    } else {
      actionWidget = InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: ListTile(
              leading: Icon(
                Icons.video_call,
                color: primary,
              ),
              title: Text(
                AppLocalizations.t('Invite video chat'),
              ),
              subtitle: Text(conference.name),
              //dense: true,
              //contentPadding: EdgeInsets.zero,
              //horizontalTitleGap: 0,
              minVerticalPadding: 0,
              //minLeadingWidth: 0,
            ),
          ));
    }
    return Card(elevation: 0, child: actionWidget);
  }
}
