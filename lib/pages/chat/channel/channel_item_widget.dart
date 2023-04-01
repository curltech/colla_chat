import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/richtext/html_editor_widget.dart';
import 'package:flutter/material.dart';

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
  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _store() async {}

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
      centerTitle: false,
      withLeading: true,
      title: widget.title,
      rightWidgets: rightWidgets,
      child: HtmlEdtorWidget(
        title: widget.title,
      ),
    );
  }
}
