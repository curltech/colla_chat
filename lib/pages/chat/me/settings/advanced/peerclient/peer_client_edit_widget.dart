import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerclient/peer_client_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

///客户端
class PeerClientEditWidget extends StatelessWidget with TileDataMixin {
  PeerClientEditWidget({super.key});

  @override
  String get routeName => 'peer_client_edit';

  @override
  bool get withLeading => true;

  @override
  IconData get iconData => Icons.desktop_windows;

  @override
  String get title => 'PeerClientEdit';

  @override
  String? get information => null;

  final List<PlatformDataField> peerClientColumnField = [
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
          Icons.location_history,
          color: myself.primary,
        )),
    PlatformDataField(
        name: 'clientId',
        label: 'ClientId',
        readOnly: true,
        prefixIcon: Icon(
          Icons.token,
          color: myself.primary,
        )),
    PlatformDataField(
        name: 'connectPeerId',
        label: 'ConnectPeerId',
        readOnly: true,
        prefixIcon: Icon(
          Icons.location_history_rounded,
          color: myself.primary,
        )),
    PlatformDataField(
        name: 'connectAddress',
        label: 'ConnectAddress',
        readOnly: true,
        prefixIcon: Icon(
          Icons.location_searching,
          color: myself.primary,
        )),
    PlatformDataField(
        name: 'connectSessionId',
        label: 'ConnectSessionId',
        readOnly: true,
        prefixIcon: Icon(
          Icons.connected_tv,
          color: myself.primary,
        )),
    PlatformDataField(
      name: 'email',
      label: 'Email',
      prefixIcon: Icon(
        Icons.email,
        color: myself.primary,
      ),
      textInputType: TextInputType.emailAddress,
    ),
    PlatformDataField(
        name: 'mobile',
        label: 'Mobile',
        prefixIcon: Icon(
          Icons.mobile_friendly,
          color: myself.primary,
        )),
    PlatformDataField(
        name: 'status',
        label: 'Status',
        prefixIcon: Icon(
          Icons.thermostat,
          color: myself.primary,
        )),
    PlatformDataField(
        name: 'publicKey',
        label: 'PublicKey',
        readOnly: true,
        prefixIcon: Icon(
          Icons.vpn_key,
          color: myself.primary,
        )),
  ];

  late final FormInputController formInputController =
      FormInputController(peerClientColumnField);

  Widget _buildFormInputWidget(BuildContext context) {
    var formInputWidget = Obx(() {
      PeerClient? peerClient = peerClientController.current;
      if (peerClient != null) {
        formInputController.setValues(JsonUtil.toJson(peerClient));
      }
      return FormInputWidget(
        height: 500,
        onOk: (Map<String, dynamic> values) {
          _onOk(values);
        },
        controller: formInputController,
      );
    });

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
        title: title,
        withLeading: withLeading,
        child: _buildFormInputWidget(context));
    return appBarView;
  }
}
