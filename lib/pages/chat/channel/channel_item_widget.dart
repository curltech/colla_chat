import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/richtext/quill_richtext_widget.dart';
import 'package:colla_chat/widgets/richtext/visual_richtext_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ChannelItemWidget extends StatefulWidget with TileDataMixin {
  ChannelItemWidget({Key? key}) : super(key: key);

  @override
  State createState() => _ChannelItemWidgetState();

  @override
  String get routeName => 'channel_item';

  @override
  bool get withLeading => true;

  @override
  Icon get icon => const Icon(Icons.wifi_channel);

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

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      centerTitle: false,
      title: Text(
        AppLocalizations.t(widget.title),
      ),
      child: const VisualRichTextWidget(),
    );
  }
}
