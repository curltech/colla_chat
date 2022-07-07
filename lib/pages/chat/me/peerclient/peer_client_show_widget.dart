import 'package:flutter/material.dart';

import '../../../../constant/base.dart';
import '../../../../entity/dht/peerclient.dart';
import '../../../../provider/data_list_controller.dart';
import '../../../../widgets/common/app_bar_view.dart';
import '../../../../widgets/common/card_text_widget.dart';
import '../../../../widgets/common/widget_mixin.dart';

final List<String> peerClientFields = ['id', 'name', 'peerId'];

//邮件内容组件
class PeerClientShowWidget extends StatefulWidget with TileDataMixin {
  final DataPageController<PeerClient> controller;

  const PeerClientShowWidget({Key? key, required this.controller})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _PeerClientShowWidgetState();

  @override
  String get routeName => 'peer_client_show';

  @override
  bool get withLeading => true;

  @override
  Icon get icon => const Icon(Icons.desktop_windows);

  @override
  String get title => 'PeerClientShow';
}

class _PeerClientShowWidgetState extends State<PeerClientShowWidget> {
  @override
  initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  Widget _buildCardTextWidget(BuildContext context) {
    List<Option> options = [];
    PeerClient? currentPeerClient = widget.controller.current;
    if (currentPeerClient != null) {
      var peerClientMap = currentPeerClient.toJson();
      for (var peerClientField in peerClientFields) {
        var label = peerClientField;
        var value = peerClientMap[peerClientField];
        value = value ?? '';
        options.add(Option(label, value.toString()));
      }
    }
    Widget formInputWidget = CardTextWidget(
      options: options,
    );
    return formInputWidget;
  }

  @override
  Widget build(BuildContext context) {
    var cardTextWidget = _buildCardTextWidget(context);
    var appBarView = AppBarView(
        title: widget.title,
        withLeading: widget.withLeading,
        child: cardTextWidget);
    return appBarView;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }
}
