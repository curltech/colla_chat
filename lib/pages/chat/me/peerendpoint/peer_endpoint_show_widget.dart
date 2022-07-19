import 'package:colla_chat/pages/chat/me/peerendpoint/peer_endpoint_list_widget.dart';
import 'package:flutter/material.dart';

import '../../../../entity/dht/peerendpoint.dart';
import '../../../../widgets/common/app_bar_view.dart';
import '../../../../widgets/common/widget_mixin.dart';
import '../../../../widgets/data_bind/data_listshow.dart';

final List<String> peerEndpointFields = ['id', 'name', 'peerId'];

//邮件内容组件
class PeerEndpointShowWidget extends StatefulWidget with TileDataMixin {
  final PeerEndpointController controller;

  const PeerEndpointShowWidget({Key? key, required this.controller})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _PeerEndpointShowWidgetState();

  @override
  String get routeName => 'peer_endpoint_show';

  @override
  bool get withLeading => true;

  @override
  Icon get icon => const Icon(Icons.desktop_windows);

  @override
  String get title => 'PeerEndpointShow';
}

class _PeerEndpointShowWidgetState extends State<PeerEndpointShowWidget> {
  @override
  initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  Widget _buildDataListShow(BuildContext context) {
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
    Widget dataListShow = DataListShow(
      values: values,
    );
    return dataListShow;
  }

  @override
  Widget build(BuildContext context) {
    var dataListShow = _buildDataListShow(context);
    var appBarView = AppBarView(
        title: widget.title,
        withLeading: widget.withLeading,
        child: dataListShow);
    return appBarView;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }
}
