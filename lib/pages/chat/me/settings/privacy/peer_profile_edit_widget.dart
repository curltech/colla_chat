import 'package:colla_chat/entity/dht/peerprofile.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/dht/peerprofile.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';

final List<PlatformDataField> peerProfileDataFields = [
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
      name: 'clientDevice',
      label: 'ClientDevice',
      readOnly: true,
      prefixIcon: Icon(
        Icons.device_unknown_outlined,
        color: myself.primary,
      )),
  PlatformDataField(
      name: 'clientType',
      label: 'ClientType',
      readOnly: true,
      prefixIcon: Icon(
        Icons.type_specimen_outlined,
        color: myself.primary,
      )),
  PlatformDataField(
      name: 'userId',
      label: 'UserId',
      readOnly: true,
      prefixIcon: Icon(
        Icons.person,
        color: myself.primary,
      )),
  PlatformDataField(
    name: 'username',
    label: 'Username',
    readOnly: true,
    prefixIcon: Icon(
      Icons.note_alt,
      color: myself.primary,
    ),
    textInputType: TextInputType.emailAddress,
  ),
  PlatformDataField(
      name: 'vpnSwitch',
      label: 'VpnSwitch',
      inputType: InputType.switcher,
      dataType: DataType.bool,
      prefixIcon: Icon(
        Icons.vpn_key,
        color: myself.primary,
      )),
  PlatformDataField(
      name: 'stockSwitch',
      label: 'StockSwitch',
      inputType: InputType.switcher,
      dataType: DataType.bool,
      prefixIcon: Icon(
        Icons.candlestick_chart,
        color: myself.primary,
      )),
  PlatformDataField(
      name: 'emailSwitch',
      label: 'EmailSwitch',
      inputType: InputType.switcher,
      dataType: DataType.bool,
      prefixIcon: Icon(
        Icons.email_outlined,
        color: myself.primary,
      )),
  PlatformDataField(
      name: 'developerSwitch',
      label: 'DeveloperSwitch',
      inputType: InputType.switcher,
      dataType: DataType.bool,
      prefixIcon: Icon(
        Icons.developer_mode,
        color: myself.primary,
      )),
  PlatformDataField(
      name: 'mobileVerified',
      label: 'MobileVerified',
      inputType: InputType.switcher,
      dataType: DataType.bool,
      prefixIcon: Icon(
        Icons.mobile_friendly,
        color: myself.primary,
      )),
  PlatformDataField(
      name: 'logLevel',
      label: 'LogLevel',
      prefixIcon: Icon(
        Icons.class_outlined,
        color: myself.primary,
      )),
];

///客户端
class PeerProfileEditWidget extends StatefulWidget with TileDataMixin {
  const PeerProfileEditWidget({super.key});

  @override
  State<StatefulWidget> createState() => _PeerProfileEditWidgetState();

  @override
  String get routeName => 'peer_profile_edit';

  @override
  bool get withLeading => true;

  @override
  IconData get iconData => Icons.room_preferences_outlined;

  @override
  String get title => 'PeerProfileEdit';
}

class _PeerProfileEditWidgetState extends State<PeerProfileEditWidget> {
  final FormInputController controller =
      FormInputController(peerProfileDataFields);

  @override
  initState() {
    super.initState();
  }

  Widget _buildFormInputWidget(BuildContext context) {
    PeerProfile? peerProfile = myself.myselfPeer.peerProfile;
    if (peerProfile != null) {
      controller.setValues(JsonUtil.toJson(peerProfile));
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
    PeerProfile peerProfile = PeerProfile.fromJson(values);
    peerProfileService.upsert(peerProfile).then((count) async {
      PeerProfile? myselfPeerProfile = myself.myselfPeer.peerProfile;
      if (myselfPeerProfile != null) {
        myselfPeerProfile.vpnSwitch = peerProfile.vpnSwitch;
        myselfPeerProfile.stockSwitch = peerProfile.stockSwitch;
        myselfPeerProfile.emailSwitch = peerProfile.emailSwitch;
        myselfPeerProfile.developerSwitch = peerProfile.developerSwitch;
        myselfPeerProfile.mobileVerified = peerProfile.mobileVerified;
        myselfPeerProfile.logLevel = peerProfile.logLevel;
        await peerProfileService.store(myselfPeerProfile);
        setState(() {});
      }
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
