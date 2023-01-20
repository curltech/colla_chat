import 'package:colla_chat/pages/chat/me/mail/address/address_add.dart';
import 'package:colla_chat/pages/chat/me/mail/mail_address_widget.dart';
import 'package:colla_chat/pages/chat/me/mail/mail_list_widget.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

//mail页面
class MailWidget extends StatelessWidget with TileDataMixin {
  late final List<TileData> mailTileData;

  MailWidget({Key? key}) : super(key: key) {
    AddressAddWidget addressAddWidget = const AddressAddWidget();
    // MailView mailView = MailView();
    MailAddressWidget mailAddressWidget = const MailAddressWidget();
    MailListWidget mailListWidget = const MailListWidget();
    List<TileDataMixin> mixins = [
      addressAddWidget,
      mailAddressWidget,
      mailListWidget,
    ];
    mailTileData = TileData.from(mixins);
    for (var tile in mailTileData) {
      tile.dense = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child = DataListView(tileData: mailTileData);
    var webrtc = KeepAliveWrapper(
        child:
            AppBarView(title: title, withLeading: withLeading, child: child));
    return webrtc;
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'mail';

  @override
  Icon get icon => const Icon(Icons.email);

  @override
  String get title => 'Mail';
}
