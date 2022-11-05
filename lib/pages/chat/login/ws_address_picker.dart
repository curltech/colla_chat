import 'package:colla_chat/constant/address.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_awesome_select/flutter_awesome_select.dart';

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
    List<S2Choice<String>>? addressChoices = [];
    for (var entry in nodeAddressOptions.entries) {
      S2Choice<String> item =
          S2Choice<String>(value: entry.key, title: entry.value.name);
      addressChoices.add(item);
    }
    return SmartSelect<String>.single(
      title: AppLocalizations.t('Address'),
      placeholder: AppLocalizations.t('Select one address'),
      selectedValue: _name,
      onChange: (selected) {
        String value = selected.value;
        _name = value;
        var nodeAddress = nodeAddressOptions[value];
        if (nodeAddress != null) {
          var wsConnectAddress = nodeAddress.wsConnectAddress;
          wsConnectAddress ??= '';
          _wsConnectAddressController.text = wsConnectAddress;
          appDataProvider.defaultNodeAddress = nodeAddress;
        }
      },
      choiceItems: addressChoices,
      modalType: S2ModalType.bottomSheet,
      modalConfig: S2ModalConfig(
        type: S2ModalType.bottomSheet,
        useFilter: false,
        style: S2ModalStyle(
          backgroundColor: Colors.grey.withOpacity(0.5),
        ),
        headerStyle: S2ModalHeaderStyle(
          elevation: 0,
          centerTitle: false,
          backgroundColor: appDataProvider.themeData.colorScheme.primary,
          textStyle: const TextStyle(color: Colors.white),
        ),
      ),
      choiceStyle: S2ChoiceStyle(
        opacity: 0.5,
        elevation: 0,
        //titleStyle: const TextStyle(color: Colors.white),
        color: appDataProvider.themeData.colorScheme.primary,
      ),
      tileBuilder: (context, state) {
        return S2Tile.fromState(
          state,
          isTwoLine: true,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      _buildSelectWidget(context),
      SizedBox(height: 10.0),
      Container(
        child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.0),
            child: TextFormField(
              controller: _wsConnectAddressController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: AppLocalizations.t('Primary Address'),
                prefixIcon: Icon(Icons.location_city),
              ),
              //initialValue: _wsConnectAddress,
              onChanged: (String val) {
                var nodeAddress =
                    NodeAddress(NodeAddress.defaultName, wsConnectAddress: val);
                appDataProvider.defaultNodeAddress = nodeAddress;
              },
              onFieldSubmitted: (String val) {},
            )),
      ),
    ]);
  }

  @override
  void dispose() {
    appDataProvider.removeListener(_update);
    super.dispose();
  }
}
