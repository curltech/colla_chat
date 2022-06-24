import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../entity/chat/chat.dart';
import '../../../../widgets/common/data_listtile.dart';
import '../../../../widgets/common/data_listview.dart';
import '../../../../widgets/common/widget_mixin.dart';
import 'mail_address_provider.dart';

//邮件列表组件，带有回退回调函数
class MailListWidget extends StatefulWidget
    with LeadingButtonMixin, RouteNameMixin {
  final Function? backCallBack;

  MailListWidget({Key? key, this.backCallBack}) : super(key: key) {}

  @override
  State<StatefulWidget> createState() => _MailListWidgetState();

  @override
  String get routeName => 'mail';

  @override
  bool get withLeading => false;
}

class _MailListWidgetState extends State<MailListWidget> {
  List<TileData> mailAddressTileData = [];

  DataListViewController dataListViewController =
      DataListViewController(tileData: []);

  late final DataListView dataListView;

  @override
  initState() async {
    super.initState();
    dataListView = DataListView(
      dataListViewController: dataListViewController,
    );
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
                    dataListViewController.tileData.length;
            ++i) {
          ChatMessage chatMessage =
              currentChatMessages[dataListViewController.tileData.length + i];
          var title = chatMessage.title ?? '';
          TileData tile = TileData(title: title);
          adds.add(tile);
        }
      }
      dataListViewController.add(adds);
      return dataListView;
    });
  }
}
