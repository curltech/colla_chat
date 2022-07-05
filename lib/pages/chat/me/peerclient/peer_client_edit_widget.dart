import 'package:flutter/material.dart';

import '../../../../entity/dht/peerclient.dart';
import '../../../../provider/data_list_controller.dart';
import '../../../../widgets/common/app_bar_view.dart';
import '../../../../widgets/common/column_field_widget.dart';
import '../../../../widgets/common/form_input_widget.dart';
import '../../../../widgets/common/keep_alive_wrapper.dart';
import '../../../../widgets/common/widget_mixin.dart';

final List<ColumnFieldDef> peerClientInputFieldDefs = [
  ColumnFieldDef(
      name: 'name', label: 'name', prefixIcon: const Icon(Icons.person)),
  ColumnFieldDef(
      name: 'peerId',
      label: 'peerId',
      prefixIcon: const Icon(Icons.perm_identity)),
  ColumnFieldDef(
      name: 'email',
      label: 'email',
      prefixIcon: const Icon(Icons.email),
      textInputType: TextInputType.emailAddress),
  ColumnFieldDef(
      name: 'mobile',
      label: 'mobile',
      prefixIcon: const Icon(Icons.mobile_friendly)),
];

//邮件内容组件
class PeerClientEditWidget extends StatefulWidget with TileDataMixin {
  final DataListController<PeerClient> controller;
  late final KeepAliveWrapper<FormInputWidget> formInputWidget;

  PeerClientEditWidget({Key? key, required this.controller}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PeerClientEditWidgetState();

  @override
  String get routeName => 'peer_client_edit';

  @override
  bool get withLeading => true;

  @override
  Icon get icon => const Icon(Icons.desktop_windows);

  @override
  String get title => 'PeerClientEdit';
}

class _PeerClientEditWidgetState extends State<PeerClientEditWidget> {
  @override
  initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() {});
    });
    _buildFormInputWidget(context);
  }

  Widget _buildFormInputWidget(BuildContext context) {
    var formInputWidget = FormInputWidget(
      onOk: (Map<String, dynamic> values) {
        _onOk(values);
      },
      inputFieldDefs: peerClientInputFieldDefs,
    );
    PeerClient? currentPeerClient = widget.controller.current;
    if (currentPeerClient != null) {
      var peerClient = currentPeerClient.toJson();
      formInputWidget.controller.setValues(peerClient);
    }

    widget.formInputWidget =
        KeepAliveWrapper<FormInputWidget>(child: formInputWidget);

    return widget.formInputWidget;
  }

  _onOk(Map<String, dynamic> values) {}

  @override
  Widget build(BuildContext context) {
    var appBarView = AppBarView(
        title: widget.title,
        withLeading: widget.withLeading,
        child: widget.formInputWidget);
    return appBarView;
  }
}
