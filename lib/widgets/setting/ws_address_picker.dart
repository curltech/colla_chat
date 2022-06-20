import 'package:flutter/material.dart';
import 'package:flutter_awesome_select/flutter_awesome_select.dart';
import 'package:provider/provider.dart';

import '../../constant/address.dart';
import '../../l10n/localization.dart';
import '../../provider/app_data_provider.dart';

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
    var defaultNodeAddress = AppDataProvider.instance.defaultNodeAddress;
    var wsConnectAddress = defaultNodeAddress.wsConnectAddress;
    if (wsConnectAddress != null) {
      _wsConnectAddress = wsConnectAddress;
    }
    _wsConnectAddressController =
        TextEditingController(text: _wsConnectAddress);
    // 初始化子项集合
    _wsConnectAddressController.addListener(() {});

    var name = defaultNodeAddress.name;
    if (name != null) {
      _name = name;
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<AppDataProvider>(context).locale;
    Provider.of<AppDataProvider>(context).themeData;
    Provider.of<AppDataProvider>(context).brightness;
    var instance = AppLocalizations.instance;
    List<S2Choice<String>> items = [];
    for (var nodeAddressOption in nodeAddressOptions.values) {
      var label = instance.text(nodeAddressOption.name);
      var item = S2Choice<String>(value: nodeAddressOption.name, title: label);
      items.add(item);
    }
    return Column(children: <Widget>[
      SmartSelect<String>.single(
        modalType: S2ModalType.bottomSheet,
        placeholder: instance.text('Please select address'),
        title: instance.text('Address'),
        selectedValue: _name,
        choiceItems: items,
        onChange: (dynamic state) {
          setState(() {
            String value = state.value;
            _name = value;
            if (value != '') {
              var nodeAddress = nodeAddressOptions[value];
              var appParams = AppDataProvider.instance;
              if (nodeAddress != null) {
                var wsConnectAddress = nodeAddress.wsConnectAddress;
                if (wsConnectAddress == null) {
                  wsConnectAddress = '';
                }
                _wsConnectAddressController.text = wsConnectAddress;
                appParams.defaultNodeAddress = nodeAddress;
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
                  var appParams = AppDataProvider.instance;
                  appParams.defaultNodeAddress = nodeAddress;
                },
                onFieldSubmitted: (String val) {},
              )),
        ),
      ),
    ]);
  }
}
