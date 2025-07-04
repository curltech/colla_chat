import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:flutter/material.dart';

class WsAddressPicker extends StatelessWidget {
  WsAddressPicker({super.key}) {
    _init();
  }

  ValueNotifier<List<Option<String>>> addressOptions =
      ValueNotifier<List<Option<String>>>([]);
  String _wsConnectAddress = '';
  final TextEditingController _wsConnectAddressController =
      TextEditingController();

  _init() {
    var defaultPeerEndpoint = peerEndpointController.defaultPeerEndpoint;
    if (defaultPeerEndpoint != null) {
      var wsConnectAddress = defaultPeerEndpoint.wsConnectAddress;
      if (wsConnectAddress != null) {
        _wsConnectAddress = wsConnectAddress;
      }
      _wsConnectAddressController.text = _wsConnectAddress;
    }
    var peerEndpoints = peerEndpointController.data;
    List<Option<String>> addressOptions = [];
    for (var peerEndpoint in peerEndpoints) {
      Option<String> option =
          Option<String>(peerEndpoint.name, peerEndpoint.peerId, hint: '');
      if (defaultPeerEndpoint?.peerId == peerEndpoint.peerId) {
        option.selected = true;
      }
      addressOptions.add(option);
    }
    this.addressOptions.value = addressOptions;
  }

  //群主选择界面
  Widget _buildSelectWidget(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: addressOptions,
      builder: (BuildContext context, addressOptions, Widget? child) {
        return CustomSingleSelectField(
          title: 'Address',
          optionController: OptionController(options: addressOptions),
          onChanged: (selected) {
            if (selected != null) {
              var peerEndpoints = peerEndpointController.data;
              int i = 0;
              for (var peerEndpoint in peerEndpoints) {
                if (peerEndpoint.peerId == selected) {
                  var wsConnectAddress = peerEndpoint.wsConnectAddress;
                  wsConnectAddress ??= '';
                  _wsConnectAddressController.text = wsConnectAddress;
                  peerEndpointController.defaultIndex = i;
                  break;
                }
                ++i;
              }
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      _buildSelectWidget(context),
      const SizedBox(height: AppPadding.mdPadding),
      Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppPadding.minPadding),
          child: TextFormField(
            controller: _wsConnectAddressController,
            keyboardType: TextInputType.text,
            decoration: buildInputDecoration(
              labelText: AppLocalizations.t('Primary Address'),
              prefixIcon: Icon(
                Icons.location_city,
                color: myself.primary,
              ),
            ),
            //initialValue: _wsConnectAddress,
            onChanged: (String val) {
              var defaultPeerEndpoint =
                  peerEndpointController.defaultPeerEndpoint!;
              defaultPeerEndpoint.wsConnectAddress = val;
            },
            onFieldSubmitted: (String val) {},
          )),
    ]);
  }
}
