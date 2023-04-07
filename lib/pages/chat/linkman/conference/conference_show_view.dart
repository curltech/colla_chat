import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/linkman/conference/conference_show_widget.dart';
import 'package:colla_chat/transport/webrtc/remote_video_render_controller.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

///显示群的基本信息，选择群成员和群主
class ConferenceShowView extends StatefulWidget with TileDataMixin {
  ConferenceShowView({
    Key? key,
  }) : super(key: key);

  @override
  IconData get iconData => Icons.meeting_room_outlined;

  @override
  String get routeName => 'conference_show';

  @override
  String get title => 'Conference show';

  @override
  bool get withLeading => true;

  @override
  State<StatefulWidget> createState() => _ConferenceShowViewState();
}

class _ConferenceShowViewState extends State<ConferenceShowView> {
  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var conferenceId = videoConferenceRenderPool.conferenceId;
    if (conferenceId == null) {
      return Center(
          child: CommonAutoSizeText(
        AppLocalizations.t('No current conference'),
        style: const TextStyle(color: Colors.white),
      ));
    }
    Conference? conference =
        videoConferenceRenderPool.getConference(conferenceId);
    var appBarView = AppBarView(
        title: widget.title,
        withLeading: widget.withLeading,
        child: ConferenceShowWidget(
          conference: conference!,
        ));
    return appBarView;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
