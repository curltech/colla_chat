import 'package:colla_chat/pages/chat/me/peerendpoint/peer_endpoint_list_widget.dart';
import 'package:flutter/material.dart';

import '../../../../entity/dht/peerendpoint.dart';
import '../../../../service/dht/peerendpoint.dart';
import '../../../../widgets/common/app_bar_view.dart';
import '../../../../widgets/common/form_input_widget.dart';
import '../../../../widgets/common/input_field_widget.dart';
import '../../../../widgets/common/widget_mixin.dart';

final List<InputFieldDef> peerEndpointInputFieldDefs = [
  InputFieldDef(
      name: 'id', label: 'id', prefixIcon: const Icon(Icons.perm_identity)),
  InputFieldDef(
      name: 'name', label: 'name', prefixIcon: const Icon(Icons.person)),
  InputFieldDef(
      name: 'peerId',
      label: 'peerId',
      prefixIcon: const Icon(Icons.perm_identity)),
  InputFieldDef(
      name: 'email',
      label: 'email',
      prefixIcon: const Icon(Icons.email),
      textInputType: TextInputType.emailAddress),
  InputFieldDef(
      name: 'mobile',
      label: 'mobile',
      prefixIcon: const Icon(Icons.mobile_friendly)),
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
    widget.controller.addListener(() {
      setState(() {});
    });
  }

  Widget _buildFormInputWidget(BuildContext context) {
    widget.controller.setInitValue(peerEndpointInputFieldDefs);
    var formInputWidget = FormInputWidget(
      onOk: (Map<String, dynamic> values) {
        _onOk(values);
      },
      inputFieldDefs: peerEndpointInputFieldDefs,
    );

    return formInputWidget;
  }

  _onOk(Map<String, dynamic> values) {
    PeerEndpoint currentPeerEndpoint = PeerEndpoint.fromJson(values);
    PeerEndpointService.instance.upsert(currentPeerEndpoint).then((count) {
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
}
