import 'package:colla_chat/entity/dht/peerendpoint.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_list_widget.dart';
import 'package:colla_chat/service/dht/peerendpoint.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';

final List<ColumnFieldDef> peerEndpointColumnFieldDefs = [
  ColumnFieldDef(
      name: 'id',
      label: 'id',
      dataType: DataType.int,
      prefixIcon: const Icon(Icons.perm_identity)),
  ColumnFieldDef(
      name: 'name', label: 'name', prefixIcon: const Icon(Icons.person)),
  ColumnFieldDef(
      name: 'peerId',
      label: 'peerId',
      prefixIcon: const Icon(Icons.perm_identity)),
  ColumnFieldDef(
      name: 'priority',
      label: 'priority',
      prefixIcon: const Icon(Icons.low_priority)),
  ColumnFieldDef(
    name: 'wsConnectAddress',
    label: 'wsConnectAddress',
    prefixIcon: const Icon(Icons.web),
  ),
  ColumnFieldDef(
      name: 'httpConnectAddress',
      label: 'httpConnectAddress',
      prefixIcon: const Icon(Icons.http)),
  ColumnFieldDef(
    name: 'libp2pConnectAddress',
    label: 'libp2pConnectAddress',
    prefixIcon: const Icon(Icons.device_hub),
  ),
  ColumnFieldDef(
      name: 'iceServers',
      label: 'iceServers',
      prefixIcon: const Icon(Icons.record_voice_over)),
];

//邮件内容组件
class PeerEndpointEditWidget extends StatefulWidget with TileDataMixin {
  final PeerEndpointController controller;

  PeerEndpointEditWidget({Key? key, required this.controller})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _PeerEndpointEditWidgetState();

  @override
  String get routeName => 'peer_endpoint_edit';

  @override
  bool get withLeading => true;

  @override
  Icon get icon => const Icon(Icons.desktop_windows);

  @override
  String get title => 'PeerEndpointEdit';
}

class _PeerEndpointEditWidgetState extends State<PeerEndpointEditWidget> {
  @override
  initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  Widget _buildFormInputWidget(BuildContext context) {
    var initValues =
        widget.controller.getInitValue(peerEndpointColumnFieldDefs);
    var formInputWidget = FormInputWidget(
      onOk: (Map<String, dynamic> values) {
        _onOk(values);
      },
      columnFieldDefs: peerEndpointColumnFieldDefs,
      initValues: initValues,
    );

    return ListView(children: <Widget>[
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
          child: formInputWidget),
      const SizedBox(
        height: 20.0,
      )
    ]);
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
        title: Text(AppLocalizations.t(widget.title)),
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
