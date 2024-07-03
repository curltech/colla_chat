import 'package:colla_chat/entity/dht/peerendpoint.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/dht/peerendpoint.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';

//邮件内容组件
class PeerEndpointEditWidget extends StatefulWidget with TileDataMixin {
  final PeerEndpointController controller;

  PeerEndpointEditWidget({super.key, required this.controller});

  @override
  State<StatefulWidget> createState() => _PeerEndpointEditWidgetState();

  @override
  String get routeName => 'peer_endpoint_edit';

  @override
  bool get withLeading => true;

  @override
  IconData get iconData => Icons.desktop_windows;

  @override
  String get title => 'PeerEndpointEdit';
}

class _PeerEndpointEditWidgetState extends State<PeerEndpointEditWidget> {
  final List<PlatformDataField> peerEndpointColumnField = [
    PlatformDataField(
        name: 'id',
        label: 'Id',
        dataType: DataType.int,
        readOnly: true,
        prefixIcon: Icon(
          Icons.perm_identity,
          color: myself.primary,
        )),
    PlatformDataField(
        name: 'name',
        label: 'Name',
        readOnly: true,
        prefixIcon: Icon(
          Icons.person,
          color: myself.primary,
        )),
    PlatformDataField(
        name: 'peerId',
        label: 'PeerId',
        readOnly: true,
        prefixIcon: Icon(
          Icons.perm_identity,
          color: myself.primary,
        )),
    PlatformDataField(
        name: 'priority',
        label: 'Priority',
        dataType: DataType.int,
        prefixIcon: Icon(
          Icons.low_priority,
          color: myself.primary,
        )),
    PlatformDataField(
      name: 'wsConnectAddress',
      label: 'wsConnectAddress',
      prefixIcon: Icon(
        Icons.web,
        color: myself.primary,
      ),
    ),
    PlatformDataField(
        name: 'httpConnectAddress',
        label: 'httpConnectAddress',
        prefixIcon: Icon(
          Icons.http,
          color: myself.primary,
        )),
    PlatformDataField(
      name: 'libp2pConnectAddress',
      label: 'libp2pConnectAddress',
      prefixIcon: Icon(
        Icons.device_hub,
        color: myself.primary,
      ),
    ),
    PlatformDataField(
        name: 'iceServers',
        label: 'iceServers',
        prefixIcon: Icon(
          Icons.record_voice_over,
          color: myself.primary,
        )),
    PlatformDataField(
        name: 'status',
        label: 'Status',
        readOnly: true,
        prefixIcon: Icon(
          Icons.thermostat,
          color: myself.primary,
        )),
  ];
  late final FormInputController controller =
      FormInputController(peerEndpointColumnField);

  @override
  initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  Widget _buildFormInputWidget(BuildContext context) {
    PeerEndpoint? peerEndpoint = peerEndpointController.current;
    if (peerEndpoint != null) {
      controller.setValues(JsonUtil.toJson(peerEndpoint));
    }
    var formInputWidget = FormInputWidget(
      height: 500,
      onOk: (Map<String, dynamic> values) {
        _onOk(values);
      },
      controller: controller,
    );

    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
        child: formInputWidget);
  }

  _onOk(Map<String, dynamic> values) {
    PeerEndpoint currentPeerEndpoint = PeerEndpoint.fromJson(values);
    peerEndpointService.upsert(currentPeerEndpoint).then((count) {
      widget.controller.update(currentPeerEndpoint);
    });
  }

  @override
  Widget build(BuildContext context) {
    var appBarView = AppBarView(
        title: widget.title,
        withLeading: widget.withLeading,
        child: _buildFormInputWidget(context));
    return appBarView;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }
}
