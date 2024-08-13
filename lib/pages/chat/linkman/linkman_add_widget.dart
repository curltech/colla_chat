import 'package:colla_chat/pages/chat/linkman/conference/anonymous_conference_edit_widget.dart';
import 'package:colla_chat/pages/chat/linkman/conference/conference_edit_widget.dart';
import 'package:colla_chat/pages/chat/linkman/group/face_group_add_widget.dart';
import 'package:colla_chat/pages/chat/linkman/group/group_edit_widget.dart';
import 'package:colla_chat/pages/chat/linkman/group/nearby_group_add_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman/contact_linkman_add_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman/json_linkman_add_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman/llm_chat_add_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman/p2p_linkman_add_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_group_listview.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:flutter/material.dart';

/// 增加联系人页面，列出了所有的增加联系人的路由
class LinkmanAddWidget extends StatelessWidget with TileDataMixin {
  final P2pLinkmanAddWidget p2pLinkmanAddWidget = P2pLinkmanAddWidget();
  final ContactLinkmanAddWidget contactLinkmanAddWidget =
      ContactLinkmanAddWidget();
  final JsonLinkmanAddWidget jsonLinkmanAddWidget = JsonLinkmanAddWidget();

  // final NearbyLinkmanAddWidget nearbyLinkmanAddWidget =
  //     NearbyLinkmanAddWidget();
  final LlmChatAddWidget llmChatAddWidget = LlmChatAddWidget();
  final NearbyGroupAddWidget nearbyGroupAddWidget = NearbyGroupAddWidget();
  final FaceGroupAddWidget faceGroupAddWidget = FaceGroupAddWidget();
  final ConferenceEditWidget conferenceEditWidget = ConferenceEditWidget();
  final AnonymousConferenceEditWidget anonymousConferenceEditWidget =
      AnonymousConferenceEditWidget();

  //final NfcLinkmanAddWidget nfcLinkmanAddWidget = NfcLinkmanAddWidget();

  Map<TileData, List<TileData>> tileData = {};

  LinkmanAddWidget({super.key}) {
    indexWidgetProvider.define(p2pLinkmanAddWidget);
    indexWidgetProvider.define(contactLinkmanAddWidget);
    indexWidgetProvider.define(jsonLinkmanAddWidget);
    //indexWidgetProvider.define(nearbyLinkmanAddWidget);
    indexWidgetProvider.define(llmChatAddWidget);
    indexWidgetProvider.define(nearbyGroupAddWidget);
    indexWidgetProvider.define(faceGroupAddWidget);
    indexWidgetProvider.define(conferenceEditWidget);
    indexWidgetProvider.define(anonymousConferenceEditWidget);
    //indexWidgetProvider.define(nfcLinkmanAddWidget);

    _init();
  }

  _init() {
    final List<TileData> linkmanTileData = TileData.from([
      p2pLinkmanAddWidget,
      contactLinkmanAddWidget,
      jsonLinkmanAddWidget,
      //nearbyLinkmanAddWidget,
      //nfcLinkmanAddWidget,
      llmChatAddWidget,
    ]);
    for (var tile in linkmanTileData) {
      tile.dense = false;
      tile.selected = false;
    }
    final List<TileData> groupTileData = TileData.from([
      groupEditWidget,
      nearbyGroupAddWidget,
      faceGroupAddWidget,
    ]);
    groupTileData.first.onTap = (int index, String title, {String? subtitle}) {
      groupNotifier.value = null;
    };
    for (var tile in groupTileData) {
      tile.dense = false;
      tile.selected = false;
    }
    final List<TileData> conferenceTileData = TileData.from([
      conferenceEditWidget,
      anonymousConferenceEditWidget,
    ]);
    conferenceNotifier.value = null;
    for (var tile in conferenceTileData) {
      tile.dense = false;
      tile.selected = false;
    }
    tileData[TileData(title: 'Linkman', selected: true)] = linkmanTileData;
    tileData[TileData(title: 'Group', selected: true)] = groupTileData;
    tileData[TileData(title: 'Conference', selected: true)] =
        conferenceTileData;
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
    Widget child = GroupDataListView(tileData: tileData);
    var linkmanView = AppBarView(title: title, withLeading: true, child: child);

    return linkmanView;
  }
}
