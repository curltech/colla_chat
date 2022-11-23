import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../entity/chat/chat.dart';
import '../../../../l10n/localization.dart';
import '../../../../widgets/common/app_bar_view.dart';
import '../../../../widgets/common/widget_mixin.dart';
import '../../../../widgets/data_bind/data_listtile.dart';
import '../../../../widgets/data_bind/data_listview.dart';
import 'mail_data_provider.dart';

//邮件列表组件，带有回退回调函数
class MailListWidget extends StatefulWidget with TileDataMixin {
  const MailListWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MailListWidgetState();

  @override
  String get routeName => 'mails';

  @override
  bool get withLeading => true;

  @override
  Icon get icon => const Icon(Icons.alternate_email);

  @override
  String get title => 'Mails';
}

class _MailListWidgetState extends State<MailListWidget> {
  late Widget dataListView;

  @override
  initState() {
    super.initState();
    dataListView = _build(context);
  }

  _onTap(int index, String title, {String? subtitle,TileData? group}) {
    logger.w('index: $index, title: $title,onTap MailListWidget');
  }

  List<TileData> _convert(List<ChatMessage> chatMessages) {
    List<TileData> tiles = [];
    if (chatMessages.isNotEmpty) {
      for (var chatMessage in chatMessages) {
        var title = chatMessage.title ?? '';
        TileData tile = TileData(title: title);
        tiles.add(tile);
      }
    }

    return tiles;
  }

  Widget _build(BuildContext context) {
    return Consumer<MailDataProvider>(
        builder: (context, mailAddressProvider, child) {
      var currentChatMessagePages = mailAddressProvider.currentChatMessagePage;
      List<ChatMessage> currentChatMessages = [];
      if (currentChatMessagePages != null) {
        currentChatMessages = currentChatMessagePages.data;
      }
      var tiles = _convert(currentChatMessages);
      var dataListView =
          KeepAliveWrapper(child: DataListView(onTap: _onTap, tileData: tiles));

      return dataListView;
    });
  }

  @override
  Widget build(BuildContext context) {
    var appBarView = AppBarView(
        title: Text(AppLocalizations.t(widget.title)),
        withLeading: widget.withLeading,
        child: dataListView);

    return appBarView;
  }
}
