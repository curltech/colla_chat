import 'package:colla_chat/pages/chat/me/peerclient/peer_client_list_widget.dart';
import 'package:colla_chat/pages/chat/me/peerendpoint/peer_endpoint_list_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/personal_info_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/setting_widget.dart';
import 'package:colla_chat/pages/chat/me/webrtc/webrtc_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/audio/platform_audio_player_widget.dart';
import 'package:colla_chat/widgets/audio/platform_audio_recorder_widget.dart';
import 'package:colla_chat/widgets/video/platform_video_player_widget.dart';
import 'package:flutter/material.dart';

import '../../../l10n/localization.dart';
import '../../../widgets/common/app_bar_view.dart';
import '../../../widgets/common/widget_mixin.dart';
import '../../../widgets/data_bind/data_listtile.dart';
import '../../../widgets/data_bind/data_listview.dart';
import 'collection/collection_widget.dart';
import 'mail/address/address_add.dart';
import 'mail/mail_address_widget.dart';
import 'mail/mail_list_widget.dart';
import 'me_head_widget.dart';

//我的页面，带有路由回调函数
class MeWidget extends StatelessWidget with TileDataMixin {
  final CollectionWidget collectionWidget = CollectionWidget();
  final SettingWidget settingWidget = SettingWidget();
  final PersonalInfoWidget personalInfoWidget = const PersonalInfoWidget();
  final AddressAddWidget addressAddWidget = const AddressAddWidget();

  // MailView mailView = MailView();
  final MailAddressWidget mailAddressWidget = const MailAddressWidget();
  final MailListWidget mailListWidget = const MailListWidget();
  final PeerEndpointListWidget peerEndpointListWidget =
      PeerEndpointListWidget();
  final PeerClientListWidget peerClientListWidget = PeerClientListWidget();
  final WebrtcWidget webrtcWidget = WebrtcWidget();
  final PlatformVideoPlayerWidget videoPlayerWidget =
      PlatformVideoPlayerWidget();
  final PlatformAudioPlayerWidget audioPlayerWidget =
      PlatformAudioPlayerWidget();
  final PlatformAudioRecorderWidget audioRecorderWidget =
      PlatformAudioRecorderWidget();

  late final Widget child;

  MeWidget({Key? key}) : super(key: key) {
    //logger.w('me init');
    //indexWidgetProvider.define(collectionWidget);
    indexWidgetProvider.define(settingWidget);
    indexWidgetProvider.define(personalInfoWidget);
    indexWidgetProvider.define(addressAddWidget);

    // indexWidgetProvider.define(mailView);
    indexWidgetProvider.define(mailAddressWidget);
    indexWidgetProvider.define(mailListWidget);
    indexWidgetProvider.define(peerEndpointListWidget);
    indexWidgetProvider.define(peerClientListWidget);
    indexWidgetProvider.define(webrtcWidget);
    indexWidgetProvider.define(videoPlayerWidget);
    indexWidgetProvider.define(audioPlayerWidget);
    indexWidgetProvider.define(audioRecorderWidget);
    List<TileDataMixin> mixins = [
      collectionWidget,
      addressAddWidget,
      mailAddressWidget,
      settingWidget,
      peerEndpointListWidget,
      peerClientListWidget,
      webrtcWidget,
      videoPlayerWidget,
      audioPlayerWidget,
      audioRecorderWidget
    ];
    final List<TileData> meTileData = TileData.from(mixins);
    child = Expanded(child: DataListView(tileData: meTileData));
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'me';

  @override
  Icon get icon => const Icon(Icons.person);

  @override
  String get title => 'Me';

  @override
  Widget build(BuildContext context) {
    var me = AppBarView(
        title: Text(AppLocalizations.t('Me')),
        child: Column(children: <Widget>[const MeHeadWidget(), child]));
    return me;
  }
}
