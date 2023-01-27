import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/value_listview.dart';
import 'package:flutter/material.dart';

final List<String> peerClientFields = ['id', 'name', 'peerId'];

//邮件内容组件
class PeerClientViewWidget extends StatefulWidget with TileDataMixin {
  final DataPageController<PeerClient> controller;

  const PeerClientViewWidget({Key? key, required this.controller})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _PeerClientViewWidgetState();

  @override
  String get routeName => 'peer_client_show';

  @override
  bool get withLeading => true;

  @override
  Icon get icon => const Icon(Icons.desktop_windows);

  @override
  String get title => 'PeerClientShow';
}

class _PeerClientViewWidgetState extends State<PeerClientViewWidget> {
  @override
  initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  Widget _buildValueListView(BuildContext context) {
    Map<String, dynamic> values = {};
    PeerClient? currentPeerClient = widget.controller.current;
    if (currentPeerClient != null) {
      var peerClientMap = currentPeerClient.toJson();
      for (var peerClientField in peerClientFields) {
        var label = peerClientField;
        var value = peerClientMap[peerClientField];
        value = value ?? '';
        values[label] = value;
      }
    }
    Widget valueListView = ValueListView(
      values: values,
    );
    return valueListView;
  }

  @override
  Widget build(BuildContext context) {
    var valueListView = _buildValueListView(context);
    var appBarView = AppBarView(
        title: widget.title,
        withLeading: widget.withLeading,
        child: valueListView);
    return appBarView;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }
}
