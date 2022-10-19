import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/linkman/linkman/contact_linkman_add_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman/p2p_linkman_add_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman/qrcode_linkman_add_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

//增加群页面，列出了所有的增加群的路由
class GroupAddWidget extends StatelessWidget with TileDataMixin {
  final P2pLinkmanAddWidget p2pLinkmanAddWidget = P2pLinkmanAddWidget();
  final QrcodeLinkmanAddWidget qrcodeLinkmanAddWidget =
      QrcodeLinkmanAddWidget();
  final ContactLinkmanAddWidget contactLinkmanAddWidget =
      ContactLinkmanAddWidget();

  late final Widget child;

  GroupAddWidget({Key? key}) : super(key: key) {
    indexWidgetProvider.define(p2pLinkmanAddWidget);
    indexWidgetProvider.define(qrcodeLinkmanAddWidget);
    indexWidgetProvider.define(contactLinkmanAddWidget);
    List<TileDataMixin> mixins = [
      p2pLinkmanAddWidget,
      qrcodeLinkmanAddWidget,
      contactLinkmanAddWidget,
    ];
    final List<TileData> linkmanAddTileData = TileData.from(mixins);
    child = Expanded(child: DataListView(tileData: linkmanAddTileData));
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'group_add';

  @override
  Icon get icon => const Icon(Icons.person);

  @override
  String get title => 'Group Add';

  @override
  Widget build(BuildContext context) {
    var me = AppBarView(
        title: Text(AppLocalizations.t('Group Add')),
        withLeading: true,
        child: Column(children: [child]));
    return me;
  }
}
