import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:flutter/material.dart';

class WsAddressPicker extends StatefulWidget {
  const WsAddressPicker({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _WsAddressPickerState();
  }
}

class _WsAddressPickerState extends State<WsAddressPicker> {
  String _peerId = '';
  List<Option<String>> addressOptions = [];
  String _wsConnectAddress = '';
  final TextEditingController _wsConnectAddressController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    peerEndpointController.addListener(_update);
    _init();
  }

  _init() {
    var defaultPeerEndpoint = peerEndpointController.defaultPeerEndpoint;
    if (defaultPeerEndpoint != null) {
      var wsConnectAddress = defaultPeerEndpoint.wsConnectAddress;
      if (wsConnectAddress != null) {
        _wsConnectAddress = wsConnectAddress;
      }
      _wsConnectAddressController.text = _wsConnectAddress;
      _peerId = defaultPeerEndpoint.peerId;
    }
    var peerEndpoints = peerEndpointController.data;
    List<Option<String>> addressOptions = [];
    for (var peerEndpoint in peerEndpoints) {
      Option<String> option =
          Option<String>(peerEndpoint.name, peerEndpoint.peerId);
      if (defaultPeerEndpoint?.peerId == peerEndpoint.peerId) {
        option.checked = true;
      }
      addressOptions.add(option);
    }
    this.addressOptions = addressOptions;
  }

  _update() {
    setState(() {
      _init();
    });
  }

  //群主选择界面
  Widget _buildSelectWidget(BuildContext context) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      _buildSelectWidget(context),
      const SizedBox(height: 10.0),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: TextFormField(
            controller: _wsConnectAddressController,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
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

  @override
  void dispose() {
    peerEndpointController.removeListener(_update);
    super.dispose();
  }
}
