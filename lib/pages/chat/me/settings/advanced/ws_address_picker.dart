import 'package:colla_chat/constant/address.dart';
import 'package:colla_chat/l10n/localization.dart';
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
  String _name = '';
  String _wsConnectAddress = '';
  late TextEditingController _wsConnectAddressController;

  @override
  void initState() {
    super.initState();
    appDataProvider.addListener(_update);
    var defaultNodeAddress = appDataProvider.defaultNodeAddress;
    var wsConnectAddress = defaultNodeAddress.wsConnectAddress;
    if (wsConnectAddress != null) {
      _wsConnectAddress = wsConnectAddress;
    }
    _wsConnectAddressController =
        TextEditingController(text: _wsConnectAddress);
    _name = defaultNodeAddress.name;
  }

  _update() {
    setState(() {});
  }

  //群主选择界面
  Widget _buildSelectWidget(BuildContext context) {
    List<Option<String>>? addressChoices = [];
    for (var entry in nodeAddressOptions.entries) {
      Option<String> item = Option<String>(entry.value.name, entry.key);
      addressChoices.add(item);
    }
    return SmartSelectUtil.single<String>(
      title: 'Address',
      placeholder: 'Select one address',
      onChange: (selected) {
        if (selected != null) {
          _name = selected;
          var nodeAddress = nodeAddressOptions[selected];
          if (nodeAddress != null) {
            var wsConnectAddress = nodeAddress.wsConnectAddress;
            wsConnectAddress ??= '';
            _wsConnectAddressController.text = wsConnectAddress;
            appDataProvider.defaultNodeAddress = nodeAddress;
          }
        }
      },
      items: addressChoices,
      selectedValue: _name,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      _buildSelectWidget(context),
      const SizedBox(height: 10.0),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: TextFormField(
            controller: _wsConnectAddressController,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              labelText: AppLocalizations.t('Primary Address'),
              prefixIcon: const Icon(Icons.location_city),
            ),
            //initialValue: _wsConnectAddress,
            onChanged: (String val) {
              var nodeAddress =
                  NodeAddress(NodeAddress.defaultName, wsConnectAddress: val);
              appDataProvider.defaultNodeAddress = nodeAddress;
            },
            onFieldSubmitted: (String val) {},
          )),
    ]);
  }

  @override
  void dispose() {
    appDataProvider.removeListener(_update);
    super.dispose();
  }
}
