import 'package:colla_chat/pages/chat/chat/video/livekit/livekit_sfu_participant_widget.dart';
import 'package:colla_chat/pages/chat/chat/video/livekit/livekit_sfu_room_widget.dart';
import 'package:colla_chat/pages/chat/me/collection/collection_list_view.dart';
import 'package:colla_chat/pages/chat/me/contact_widget.dart';
import 'package:colla_chat/pages/chat/me/me_head_widget.dart';
import 'package:colla_chat/pages/chat/me/personal_info_widget.dart';
import 'package:colla_chat/pages/chat/me/platform_info_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/setting_widget.dart';
import 'package:colla_chat/pages/chat/me/webrtc/local_media_stream_widget.dart';
import 'package:colla_chat/pages/index/help_information_widget.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/system_status_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

//我的页面，带有路由回调函数
class MeWidget extends StatelessWidget with TileDataMixin {
  final PersonalInfoWidget personalInfoWidget = PersonalInfoWidget();
  final CollectionListView collectionListView = CollectionListView();
  final SettingWidget settingWidget = SettingWidget();
  final LocalMediaStreamWidget localMediaStreamWidget =
      LocalMediaStreamWidget();
  final ContactWidget contactWidget = ContactWidget();
  final LiveKitSfuRoomWidget liveKitSfuRoomWidget = LiveKitSfuRoomWidget();
  final LiveKitSfuParticipantWidget liveKitSfuParticipantWidget =
      LiveKitSfuParticipantWidget();
  final PlatformInfoWidget platformInfoWidget = const PlatformInfoWidget();
  final SystemStatusWidget systemStatusWidget = SystemStatusWidget();
  final HelpInformationWidget helpInformationWidget =
      const HelpInformationWidget();

  MeWidget({super.key}) {
    indexWidgetProvider.define(collectionListView);
    indexWidgetProvider.define(settingWidget);
    indexWidgetProvider.define(personalInfoWidget);
    indexWidgetProvider.define(localMediaStreamWidget);
    indexWidgetProvider.define(contactWidget);
    indexWidgetProvider.define(liveKitSfuRoomWidget);
    indexWidgetProvider.define(liveKitSfuParticipantWidget);
    indexWidgetProvider.define(platformInfoWidget);
    indexWidgetProvider.define(systemStatusWidget);
    indexWidgetProvider.define(helpInformationWidget);
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'me';

  @override
  IconData get iconData => Icons.person;

  @override
  String get title => 'Me';

  List<TileData> _buildMeTileData(BuildContext context) {
    final bool developerSwitch = myself.peerProfile.developerSwitch;
    List<TileDataMixin> mixins = [
      settingWidget,
      collectionListView,
    ];

    mixins.add(platformInfoWidget);
    mixins.add(systemStatusWidget);
    
    if (developerSwitch) {
      mixins.addAll([
        localMediaStreamWidget,
        liveKitSfuRoomWidget,
      ]);
    }

    if (platformParams.mobile) {
      mixins.add(contactWidget);
    }

    List<TileData> meTileData = TileData.from(mixins);
    for (var tile in meTileData) {
      tile.dense = false;
      tile.selected = false;
    }

    return meTileData;
  }

  @override
  Widget build(BuildContext context) {
    List<TileData> meTileData = _buildMeTileData(context);
    Widget child = DataListView(
      itemCount: meTileData.length,
      itemBuilder: (BuildContext context, int index) {
        return meTileData[index];
      },
    );

    var me = AppBarView(
        title: title,
        helpPath: routeName,
        child: Column(
            children: <Widget>[const MeHeadWidget(), Expanded(child: child)]));
    return me;
  }
}
