import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/localization.dart';
import '../../../../widgets/common/app_bar_view.dart';
import '../../../../widgets/common/widget_mixin.dart';
import '../../../../widgets/data_bind/data_listtile.dart';
import 'mail_address_widget.dart';
import 'mail_content_widget.dart';
import 'mail_list_widget.dart';

//邮件总体视图，带有回退回调函数
class MailView extends StatefulWidget with TileDataMixin {
  final Function? leadingCallBack;

  MailView({Key? key, this.leadingCallBack}) : super(key: key) {}

  @override
  State<StatefulWidget> createState() => _MailViewState();

  @override
  String get routeName => 'mail';

  @override
  bool get withLeading => true;

  @override
  Icon get icon => const Icon(Icons.email);

  @override
  String get title => 'Mail';
}

class _MailViewState extends State<MailView>
    with SingleTickerProviderStateMixin {
  Map<TileData, List<TileData>> mailAddressTileData = {};
  var mailAddressWidget = MailAddressWidget();
  var mailListWidget = const MailListWidget();
  var mailContentWidget = const MailContentWidget();

  @override
  initState() {
    super.initState();
    var indexWidgetProvider =
        Provider.of<IndexWidgetProvider>(context, listen: false);
    indexWidgetProvider.define(mailAddressWidget);
    indexWidgetProvider.define(mailListWidget);
    indexWidgetProvider.define(mailContentWidget);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = <Widget>[];
    children.add(SizedBox(width: 200, child: mailAddressWidget));
    children.add(SizedBox(width: 200, child: mailListWidget));
    children.add(Expanded(child: mailContentWidget));
    var row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
    var appBarView =
        AppBarView(title: Text(AppLocalizations.t('Mail')), withLeading: widget.withLeading, child: row);

    return appBarView;
  }
}
