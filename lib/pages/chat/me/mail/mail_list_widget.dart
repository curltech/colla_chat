import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../entity/chat/chat.dart';
import '../../../../provider/app_data_provider.dart';
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

///ChatMessage数组的转换器实现类
class ChatMessageTileDataConvertMixin with TileDataConvertMixin {
  List<ChatMessage> chatMessages;

  ChatMessageTileDataConvertMixin({required this.chatMessages});

  @override
  TileData getTileData(int index) {
    ChatMessage chatMessage = chatMessages[index];
    var title = chatMessage.title ?? '';
    TileData tile = TileData(title: title);

    return tile;
  }

  @override
  bool add(List<TileData> tiles) {
    return false;
  }

  @override
  int get length => chatMessages.length;
}

class _MailListWidgetState extends State<MailListWidget> {
  @override
  initState() {
    super.initState();
  }

  _onTap(int index, String title, {TileData? group}) {
    logger.w('index: $index, title: $title,onTap MailListWidget');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MailAddressProvider>(
        builder: (context, mailAddressProvider, child) {
      var currentChatMessages = mailAddressProvider.currentChatMessages;
      currentChatMessages ??= [];
      var chatMessageTileDataConvertMixin =
          ChatMessageTileDataConvertMixin(chatMessages: currentChatMessages);
      var dataListView = KeepAliveWrapper(
          child: DataListView(
              onTap: _onTap, tileDataMix: chatMessageTileDataConvertMixin));
      var appBarView = AppBarView(
          title: widget.title,
          withLeading: widget.withLeading,
          child: dataListView);

      return appBarView;
    });
  }
}
