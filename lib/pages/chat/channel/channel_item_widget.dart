import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/richtext/quill_richtext_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class ChannelItemWidget extends StatefulWidget with TileDataMixin {
  final DataMoreController<ChatMessage> dataMoreController;

  ChannelItemWidget({Key? key, required this.dataMoreController})
      : super(key: key);

  @override
  State createState() => _ChannelItemWidgetState();

  @override
  String get routeName => 'channel_item';

  @override
  bool get withLeading => true;

  @override
  IconData get iconData => Icons.wifi_channel;

  @override
  String get title => 'Channel Item';
}

class _ChannelItemWidgetState extends State<ChannelItemWidget> {
  quill.Document? document;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _store() async {
    final content = document!.toDelta().toJson();
    final thumbnail = document!.toPlainText();
    final title = thumbnail.substring(0, thumbnail.length);
    var data = JsonUtil.toUintList(content);
    var chatMessage = widget.dataMoreController.current;
    if (chatMessage != null) {
    } else {
      chatMessage = await chatMessageService.buildChatMessage(
        myself.peerId!,
        content: data,
        title: title,
        thumbnail: CryptoUtil.stringToUtf8(thumbnail),
        messageType: ChatMessageType.channel,
        subMessageType: ChatMessageSubType.channel,
        contentType: ContentType.rich,
      );
    }
    await chatMessageService.store(chatMessage, updateSummary: false);
  }

  _onStore(quill.Document doc) {
    document = doc;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget>? rightWidgets = [
      IconButton(
          onPressed: () async {
            await _store();
          },
          icon: const Icon(Icons.save)),
    ];
    return AppBarView(
      centerTitle: true,
      withLeading: true,
      title: widget.title,
      rightWidgets: rightWidgets,
      child: QuillRichTextWidget(
        content: widget.dataMoreController.current?.content,
        onStore: _onStore,
      ),
    );
  }
}
