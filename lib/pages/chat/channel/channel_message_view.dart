import 'package:colla_chat/pages/chat/channel/channel_chat_message_controller.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/platform_webview.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

//频道消息的展示页面
class ChannelMessageView extends StatefulWidget with TileDataMixin {
  ChannelMessageView({Key? key}) : super(key: key);

  @override
  State createState() => _ChannelMessageViewState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'channel_message_view';

  @override
  IconData get iconData => Icons.view_agenda;

  @override
  String get title => 'ChannelMessageView';
}

class _ChannelMessageViewState extends State<ChannelMessageView>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var chatMessage = channelChatMessageController.current;
    return AppBarView(
        centerTitle: false,
        title: widget.title,
        child: PlatformWebView(html: chatMessage!.content));
  }
}
