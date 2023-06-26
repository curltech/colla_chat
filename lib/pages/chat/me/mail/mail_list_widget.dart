import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/pages/chat/me/mail/mail_address_controller.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

///邮件列表子视图
class MailListWidget extends StatefulWidget {
  const MailListWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MailListWidgetState();
}

class _MailListWidgetState extends State<MailListWidget> {
  @override
  initState() {
    super.initState();
  }

  _onTap(int index, String title, {String? subtitle, TileData? group}) {
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

  Widget _buildMailListWidget(BuildContext context) {
    var currentChatMessagePages = mailAddressController.currentChatMessagePage;
    List<ChatMessage> currentChatMessages = [];
    if (currentChatMessagePages != null) {
      currentChatMessages = currentChatMessagePages;
    }
    var tiles = _convert(currentChatMessages);
    var dataListView = DataListView(onTap: _onTap, tileData: tiles);

    return dataListView;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ButtonBar(children: [
        IconButton(
            onPressed: () {}, icon: const Icon(Icons.add), tooltip: 'New mail')
      ]),
      _buildMailListWidget(context)
    ]);
  }
}
