import 'dart:typed_data';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/pages/chat/channel/channel_chat_message_controller.dart';
import 'package:colla_chat/service/chat/message_attachment.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/platform_future_builder.dart';
import 'package:colla_chat/widgets/webview/platform_webview.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

/// 发布频道消息的展示页面
class PublishedChannelMessagePreview extends StatefulWidget with TileDataMixin {
  PublishedChannelMessagePreview({super.key});

  @override
  State createState() => _PublishedChannelMessagePreviewState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'published_channel_message_preview';

  @override
  IconData get iconData => Icons.view_agenda;

  @override
  String get title => 'PublishedChannelMessagePreview';
}

class _PublishedChannelMessagePreviewState
    extends State<PublishedChannelMessagePreview>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  Future<String?> _buildHtml() async {
    var chatMessage = myChannelChatMessageController.current;
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
    var chatMessage = myChannelChatMessageController.current;
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
            return PlatformWebView(html: html);
          }),
    );
  }
}
