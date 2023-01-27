import 'package:colla_chat/entity/dht/peerendpoint.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_controller.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/value_listview.dart';
import 'package:flutter/material.dart';

final List<String> peerEndpointFields = ['id', 'name', 'peerId'];

//邮件内容组件
class PeerEndpointViewWidget extends StatefulWidget with TileDataMixin {
  final PeerEndpointController controller;

  const PeerEndpointViewWidget({Key? key, required this.controller})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _PeerEndpointViewWidgetState();

  @override
  String get routeName => 'peer_endpoint_view';

  @override
  bool get withLeading => true;

  @override
  Icon get icon => const Icon(Icons.desktop_windows);

  @override
  String get title => 'PeerEndpointView';
}

class _PeerEndpointViewWidgetState extends State<PeerEndpointViewWidget> {
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
    PeerEndpoint? currentPeerEndpoint = widget.controller.current;
    if (currentPeerEndpoint != null) {
      var peerEndpointMap = currentPeerEndpoint.toJson();
      for (var peerEndpointField in peerEndpointFields) {
        var label = peerEndpointField;
        var value = peerEndpointMap[peerEndpointField];
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
