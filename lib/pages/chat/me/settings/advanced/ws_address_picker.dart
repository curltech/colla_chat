import 'package:colla_chat/constant/address.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_list_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
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
  String _wsConnectAddress = '';
  late TextEditingController _wsConnectAddressController;

  @override
  void initState() {
    super.initState();
    peerEndpointController.addListener(_update);
    if (peerEndpointController.data.isNotEmpty) {
      var defaultPeerEndpoint = peerEndpointController.data[0];
      var wsConnectAddress = defaultPeerEndpoint.wsConnectAddress;
      if (wsConnectAddress != null) {
        _wsConnectAddress = wsConnectAddress;
      }
      _wsConnectAddressController =
          TextEditingController(text: _wsConnectAddress);
      _peerId = defaultPeerEndpoint.peerId;
    }
  }

  _update() {
    setState(() {});
  }

  //群主选择界面
  Widget _buildSelectWidget(BuildContext context) {
    List<Option<String>>? addressChoices = [];
    var peerEndpoints = peerEndpointController.data;
    for (var peerEndpoint in peerEndpoints) {
      Option<String> item =
          Option<String>(peerEndpoint.name, peerEndpoint.peerId);
      addressChoices.add(item);
    }
    return SmartSelectUtil.single<String>(
      title: 'Address',
      placeholder: 'Select one address',
      onChange: (selected) {
        if (selected != null) {
          _peerId = selected;
          var peerEndpoints = peerEndpointController.data;
          int i = 0;
          for (var peerEndpoint in peerEndpoints) {
            if (peerEndpoint.peerId == _peerId) {
              var wsConnectAddress = peerEndpoint.wsConnectAddress;
              wsConnectAddress ??= '';
              _wsConnectAddressController.text = wsConnectAddress;
              peerEndpointController.delete(index: i);
              peerEndpointController.insert(0, peerEndpoint);
              break;
            }
            ++i;
          }
        }
      },
      items: addressChoices,
      selectedValue: _peerId,
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
              prefixIcon: const Icon(Icons.location_city),
            ),
            //initialValue: _wsConnectAddress,
            onChanged: (String val) {
              var defaultPeerEndpoint = peerEndpointController.data[0];
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
