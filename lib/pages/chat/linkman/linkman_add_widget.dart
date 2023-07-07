import 'package:colla_chat/pages/chat/linkman/conference/conference_add_widget.dart';
import 'package:colla_chat/pages/chat/linkman/group/face_group_add_widget.dart';
import 'package:colla_chat/pages/chat/linkman/group/linkman_group_add_widget.dart';
import 'package:colla_chat/pages/chat/linkman/group/nearby_group_add_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman/chat_gpt_add_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman/contact_linkman_add_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman/json_linkman_add_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman/p2p_linkman_add_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

//增加联系人页面，列出了所有的增加联系人的路由
class LinkmanAddWidget extends StatelessWidget with TileDataMixin {
  final P2pLinkmanAddWidget p2pLinkmanAddWidget = P2pLinkmanAddWidget();
  final ContactLinkmanAddWidget contactLinkmanAddWidget =
      ContactLinkmanAddWidget();
  final JsonLinkmanAddWidget jsonLinkmanAddWidget = JsonLinkmanAddWidget();

  // final NearbyLinkmanAddWidget nearbyLinkmanAddWidget =
  //     NearbyLinkmanAddWidget();
  final ChatGPTAddWidget chatGPTAddWidget = const ChatGPTAddWidget();
  final LinkmanGroupAddWidget linkmanGroupAddWidget = LinkmanGroupAddWidget();
  final NearbyGroupAddWidget nearbyGroupAddWidget = NearbyGroupAddWidget();
  final FaceGroupAddWidget faceGroupAddWidget = FaceGroupAddWidget();
  final ConferenceAddWidget conferenceAddWidget = ConferenceAddWidget();
  late final List<TileData> linkmanAddTileData;

  LinkmanAddWidget({Key? key}) : super(key: key) {
    indexWidgetProvider.define(p2pLinkmanAddWidget);
    indexWidgetProvider.define(contactLinkmanAddWidget);
    indexWidgetProvider.define(jsonLinkmanAddWidget);
    //indexWidgetProvider.define(nearbyLinkmanAddWidget);
    indexWidgetProvider.define(chatGPTAddWidget);
    indexWidgetProvider.define(linkmanGroupAddWidget);
    indexWidgetProvider.define(nearbyGroupAddWidget);
    indexWidgetProvider.define(faceGroupAddWidget);
    indexWidgetProvider.define(conferenceAddWidget);
    List<TileDataMixin> mixins = [
      p2pLinkmanAddWidget,
      contactLinkmanAddWidget,
      jsonLinkmanAddWidget,
      //nearbyLinkmanAddWidget,
      chatGPTAddWidget,
      linkmanGroupAddWidget,
      nearbyGroupAddWidget,
      faceGroupAddWidget,
      conferenceAddWidget,
    ];
    linkmanAddTileData = TileData.from(mixins);
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'linkman_add';

  @override
  IconData get iconData => Icons.person;

  @override
  String get title => 'Add linkman';

  @override
  Widget build(BuildContext context) {
    Widget child = DataListView(tileData: linkmanAddTileData);
    var me = AppBarView(title: title, withLeading: true, child: child);
    return me;
  }
}
