import 'package:flutter/material.dart';

import '../../../../entity/dht/peerclient.dart';
import '../../../../l10n/localization.dart';
import '../../../../provider/data_list_controller.dart';
import '../../../../service/dht/peerclient.dart';
import '../../../../widgets/common/app_bar_view.dart';
import '../../../../widgets/common/widget_mixin.dart';
import '../../../../widgets/data_bind/column_field_widget.dart';
import '../../../../widgets/data_bind/form_input_widget.dart';

final List<ColumnFieldDef> peerClientColumnFieldDefs = [
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
  final DataPageController<PeerClient> controller;

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
    widget.controller.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  Widget _buildFormInputWidget(BuildContext context) {
    var initValues = widget.controller.getInitValue(peerClientColumnFieldDefs);
    var formInputWidget = FormInputWidget(
      onOk: (Map<String, dynamic> values) {
        _onOk(values);
      },
      columnFieldDefs: peerClientColumnFieldDefs,
      initValues: initValues,
    );

    return formInputWidget;
  }

  _onOk(Map<String, dynamic> values) {
    PeerClient currentPeerClient = PeerClient.fromJson(values);
    peerClientService.upsert(currentPeerClient).then((count) {
      widget.controller.update(currentPeerClient);
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
