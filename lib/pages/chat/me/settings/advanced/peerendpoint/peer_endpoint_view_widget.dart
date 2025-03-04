import 'package:colla_chat/entity/dht/peerendpoint.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_controller.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/value_listview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

final List<String> peerEndpointFields = ['id', 'name', 'peerId'];

//邮件内容组件
class PeerEndpointViewWidget extends StatelessWidget with TileDataMixin {
  final PeerEndpointController peerEndpointController;

  const PeerEndpointViewWidget(
      {super.key, required this.peerEndpointController});

  @override
  String get routeName => 'peer_endpoint_view';

  @override
  bool get withLeading => true;

  @override
  IconData get iconData => Icons.desktop_windows;

  @override
  String get title => 'PeerEndpointView';

  @override
  String? get information => null;

  Widget _buildValueListView(BuildContext context) {
    return Obx(() {
      Map<String, dynamic> values = {};
      PeerEndpoint? currentPeerEndpoint = peerEndpointController.current;
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
    });
  }

  @override
  Widget build(BuildContext context) {
    var valueListView = _buildValueListView(context);
    var appBarView = AppBarView(
        title: title, withLeading: withLeading, child: valueListView);
    return appBarView;
  }
}
