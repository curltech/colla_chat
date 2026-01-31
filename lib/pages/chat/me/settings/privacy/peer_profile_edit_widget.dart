import 'package:colla_chat/entity/dht/peerprofile.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/dht/peerprofile.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_reactive_form.dart';
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
      name: 'gameSwitch',
      label: 'GameSwitch',
      inputType: InputType.switcher,
      dataType: DataType.bool,
      prefixIcon: Icon(
        Icons.gamepad_outlined,
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
class PeerProfileEditWidget extends StatelessWidget with DataTileMixin {
  PeerProfileEditWidget({super.key});

  @override
  String get routeName => 'peer_profile_edit';

  @override
  bool get withLeading => true;

  @override
  IconData get iconData => Icons.room_preferences_outlined;

  @override
  String get title => 'Privacy Setting';

  final PlatformReactiveFormController platformReactiveFormController =
      PlatformReactiveFormController(peerProfileDataFields);

  Widget _buildPlatformReactiveForm(BuildContext context) {
    PeerProfile? peerProfile = myself.myselfPeer.peerProfile;
    if (peerProfile != null) {
      platformReactiveFormController.values = JsonUtil.toJson(peerProfile);
    }
    var formInputWidget = PlatformReactiveForm(
      height: 500,
      onSubmit: (Map<String, dynamic> values) async {
        await _onOk(context, values);
      },
      platformReactiveFormController: platformReactiveFormController,
    );

    return formInputWidget;
  }

  Future<void> _onOk(BuildContext context, Map<String, dynamic> values) async {
    PeerProfile peerProfile = PeerProfile.fromJson(values);
    PeerProfile? myselfPeerProfile = myself.myselfPeer.peerProfile;
    if (myselfPeerProfile == null) {
      myselfPeerProfile = peerProfile;
      myself.myselfPeer.peerProfile = myselfPeerProfile;
    } else {
      myselfPeerProfile.vpnSwitch = peerProfile.vpnSwitch;
      myselfPeerProfile.stockSwitch = peerProfile.stockSwitch;
      myselfPeerProfile.emailSwitch = peerProfile.emailSwitch;
      myselfPeerProfile.gameSwitch = peerProfile.gameSwitch;
      if (myselfPeerProfile.developerSwitch != peerProfile.developerSwitch) {
        myselfPeerProfile.developerSwitch = peerProfile.developerSwitch;
        myself.peerProfile = myselfPeerProfile;
      }
      myselfPeerProfile.mobileVerified = peerProfile.mobileVerified;
      myselfPeerProfile.logLevel = peerProfile.logLevel;
    }
    try {
      await peerProfileService.store(myselfPeerProfile);
      DialogUtil.info(
          content:
              AppLocalizations.t('myself peerProfile has stored successfully'));
    } catch (e) {
      DialogUtil.error(
          content: AppLocalizations.t('myself peerProfile has stored failure'));
    }

    if (myselfPeerProfile.stockSwitch) {
      indexWidgetProvider.addMainView('stock');
    } else {
      indexWidgetProvider.removeMainView('stock');
    }
    if (myselfPeerProfile.emailSwitch) {
      indexWidgetProvider.addMainView('mail');
    } else {
      indexWidgetProvider.removeMainView('mail');
    }
    if (myselfPeerProfile.gameSwitch) {
      indexWidgetProvider.addMainView('game_main');
    } else {
      indexWidgetProvider.removeMainView('game_main');
    }
  }

  @override
  Widget build(BuildContext context) {
    var appBarView = AppBarView(
        title: title,
        helpPath: routeName,
        withLeading: withLeading,
        child: _buildPlatformReactiveForm(context));
    return appBarView;
  }
}
