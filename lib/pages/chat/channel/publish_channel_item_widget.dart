import 'package:colla_chat/pages/chat/channel/channel_chat_message_controller.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/richtext/html_editor_widget.dart';
import 'package:flutter/material.dart';

///自己发布频道消息编辑页面
class PublishChannelItemWidget extends StatefulWidget with TileDataMixin {
  PublishChannelItemWidget({Key? key}) : super(key: key);

  @override
  State createState() => _PublishChannelItemWidgetState();

  @override
  String get routeName => 'publish_channel_item';

  @override
  bool get withLeading => true;

  @override
  IconData get iconData => Icons.edit;

  @override
  String get title => 'Publish Channel Item';
}

class _PublishChannelItemWidgetState extends State<PublishChannelItemWidget> {
  final TextEditingController textEditingController = TextEditingController();
  List<int>? thumbnail;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _store(String? result) async {
    await myChannelChatMessageController.store(
        textEditingController.text, result!, thumbnail);
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      centerTitle: false,
      withLeading: true,
      title: widget.title,
      child: HtmlEditorWidget(
        height:
            appDataProvider.actualSize.height - appDataProvider.toolbarHeight,
        onSave: _store,
      ),
    );
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }
}
