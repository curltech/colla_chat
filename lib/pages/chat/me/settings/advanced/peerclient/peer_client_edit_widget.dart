import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerclient/peer_client_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';

final List<ColumnFieldDef> peerClientColumnFieldDefs = [
  ColumnFieldDef(
      name: 'id',
      label: 'Id',
      dataType: DataType.int,
      readOnly: true,
      prefixIcon: Icon(
        Icons.perm_identity,
        color: myself.primary,
      )),
  ColumnFieldDef(
      name: 'name',
      label: 'Name',
      readOnly: true,
      prefixIcon: Icon(
        Icons.person,
        color: myself.primary,
      )),
  ColumnFieldDef(
      name: 'peerId',
      label: 'PeerId',
      readOnly: true,
      prefixIcon: Icon(
        Icons.perm_identity,
        color: myself.primary,
      )),
  ColumnFieldDef(
    name: 'email',
    label: 'Email',
    prefixIcon: Icon(
      Icons.email,
      color: myself.primary,
    ),
    textInputType: TextInputType.emailAddress,
  ),
  ColumnFieldDef(
      name: 'mobile',
      label: 'Mobile',
      prefixIcon: Icon(
        Icons.mobile_friendly,
        color: myself.primary,
      )),
  ColumnFieldDef(
      name: 'status',
      label: 'Status',
      prefixIcon: Icon(
        Icons.thermostat,
        color: myself.primary,
      )),
];

///客户端
class PeerClientEditWidget extends StatefulWidget with TileDataMixin {
  const PeerClientEditWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PeerClientEditWidgetState();

  @override
  String get routeName => 'peer_client_edit';

  @override
  bool get withLeading => true;

  @override
  IconData get iconData => Icons.desktop_windows;

  @override
  String get title => 'PeerClientEdit';
}

class _PeerClientEditWidgetState extends State<PeerClientEditWidget> {
  final FormInputController controller =
      FormInputController(peerClientColumnFieldDefs);

  @override
  initState() {
    super.initState();
    peerClientController.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  Widget _buildFormInputWidget(BuildContext context) {
    PeerClient? peerClient = peerClientController.current;
    if (peerClient != null) {
      controller.setInitValue(JsonUtil.toJson(peerClient));
    }
    var formInputWidget = FormInputWidget(
      height: 500,
      onOk: (Map<String, dynamic> values) {
        _onOk(values);
      },
      controller: controller,
    );

    return formInputWidget;
  }

  _onOk(Map<String, dynamic> values) {
    PeerClient currentPeerClient = PeerClient.fromJson(values);
    peerClientService.upsert(currentPeerClient).then((count) {
      peerClientController.update(currentPeerClient);
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
    peerClientController.removeListener(_update);
    super.dispose();
  }
}
