import 'dart:typed_data';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/pages/chat/channel/channel_chat_message_controller.dart';
import 'package:colla_chat/service/chat/message_attachment.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/platform_future_builder.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/webview/platform_webview.dart';
import 'package:flutter/material.dart';

/// 订阅频道消息的展示页面
class SubscribeChannelMessagePreview extends StatelessWidget
    with TileDataMixin {
  SubscribeChannelMessagePreview({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'subscribe_channel_message_preview';

  @override
  IconData get iconData => Icons.view_agenda;

  @override
  String get title => 'SubscribeChannelMessagePreview';

  @override
  String? get information => null;

  Future<String?> _buildHtml() async {
    ChatMessage? chatMessage = channelChatMessageController.current;
    if (chatMessage == null) {
      return null;
    }
    Uint8List? bytes = await messageAttachmentService.findContent(
        chatMessage.messageId!, chatMessage.title);
    if (bytes != null) {
      String content = CryptoUtil.utf8ToString(bytes);

      return content;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    ChatMessage? chatMessage = channelChatMessageController.current;
    if (chatMessage == null) {
      return nil;
    }

    return AppBarView(
      centerTitle: false,
      withLeading: true,
      title: chatMessage.title,
      child: PlatformFutureBuilder(
          future: _buildHtml(),
          builder: (BuildContext context, String? html) {
            return PlatformWebView(
                html: html,
                inline: true,
                webViewController: PlatformWebViewController());
          }),
    );
  }
}
