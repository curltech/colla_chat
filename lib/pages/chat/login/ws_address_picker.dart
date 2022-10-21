import 'package:colla_chat/constant/base.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../constant/address.dart';
import '../../../l10n/localization.dart';
import '../../../provider/app_data_provider.dart';
import '../../../widgets/data_bind/data_select.dart';

class WsAddressPicker extends StatefulWidget {
  const WsAddressPicker({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _WsAddressPickerState();
  }
}

class _WsAddressPickerState extends State<WsAddressPicker> {
  bool _visibility = true;
  String _name = '';
  String _wsConnectAddress = '';
  late TextEditingController _wsConnectAddressController;

  @override
  void initState() {
    super.initState();
    var defaultNodeAddress = appDataProvider.defaultNodeAddress;
    var wsConnectAddress = defaultNodeAddress.wsConnectAddress;
    if (wsConnectAddress != null) {
      _wsConnectAddress = wsConnectAddress;
    }
    _wsConnectAddressController =
        TextEditingController(text: _wsConnectAddress);
    _name = defaultNodeAddress.name;
  }

  @override
  Widget build(BuildContext context) {
    var instance = AppLocalizations.instance;
    List<Option> items = [];
    for (var entry in nodeAddressOptions.entries) {
      items.add(Option(entry.key, entry.key));
    }
    return Column(children: <Widget>[
      DataSelect(
        hint: 'Please select address',
        label: 'Address',
        initValue: _name,
        items: items,
        onChanged: (String? value) {
          setState(() {
            if (value != null) {
              _name = value;
              var nodeAddress = nodeAddressOptions[value];
              if (nodeAddress != null) {
                var wsConnectAddress = nodeAddress.wsConnectAddress;
                wsConnectAddress ??= '';
                _wsConnectAddressController.text = wsConnectAddress;
                appDataProvider.defaultNodeAddress = nodeAddress;
              }
              _visibility = true;
            } else {
              _visibility = false;
            }
          });
        },
      ),
      SizedBox(height: 10.0),
      Visibility(
        visible: _visibility,
        child: Container(
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: TextFormField(
                controller: _wsConnectAddressController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: instance.text('Primary Address'),
                  prefixIcon: Icon(Icons.location_city),
                ),
                //initialValue: _wsConnectAddress,
                onChanged: (String val) {
                  var nodeAddress = NodeAddress(NodeAddress.defaultName,
                      wsConnectAddress: val);
                  appDataProvider.defaultNodeAddress = nodeAddress;
                },
                onFieldSubmitted: (String val) {},
              )),
        ),
      ),
    ]);
  }
}
