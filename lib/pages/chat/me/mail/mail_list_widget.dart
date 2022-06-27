import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../entity/chat/chat.dart';
import '../../../../widgets/common/app_bar_view.dart';
import '../../../../widgets/common/data_listtile.dart';
import '../../../../widgets/common/data_listview.dart';
import '../../../../widgets/common/widget_mixin.dart';
import 'mail_address_provider.dart';

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
  List<TileData> mailAddressTileData = [];
  late final DataListView dataListView;

  @override
  initState() {
    super.initState();
    dataListView = DataListView(tileData: []);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MailAddressProvider>(
        builder: (context, mailAddressProvider, child) {
      var currentChatMessages = mailAddressProvider.currentChatMessages;
      List<TileData> adds = [];
      if (currentChatMessages != null && currentChatMessages.isNotEmpty) {
        for (var i = 0;
            i <
                currentChatMessages.length -
                    dataListView.dataListViewController.tileData.length;
            ++i) {
          ChatMessage chatMessage = currentChatMessages[
              dataListView.dataListViewController.tileData.length + i];
          var title = chatMessage.title ?? '';
          TileData tile = TileData(title: title);
          adds.add(tile);
        }
      }
      dataListView.dataListViewController.add(adds);
      var appBarView = AppBarView(
          title: widget.title,
          withLeading: widget.withLeading,
          child: dataListView);

      return appBarView;
    });
  }
}
