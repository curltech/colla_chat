import 'package:colla_chat/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_awesome_select/flutter_awesome_select.dart';
import 'package:provider/provider.dart';
import '../../constant/address.dart';
import '../../l10n/localization.dart';
import '../../provider/locale_data.dart';

class WsAddressPicker extends StatefulWidget {
  const WsAddressPicker({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _WsAddressPickerState();
  }
}

class _WsAddressPickerState extends State<WsAddressPicker> {
  bool _visibility = true;
  String _wsConnectAddress = AppParams.instance.wsConnectAddress[0];
  late TextEditingController _wsConnectAddressController;

  @override
  void initState() {
    super.initState();
    _wsConnectAddressController =
        TextEditingController(text: _wsConnectAddress);
    // 初始化子项集合
    _wsConnectAddressController.addListener(() {});
  }

  @override
  Widget build(BuildContext context) {
    var selectedLocale = Provider.of<LocaleDataProvider>(context).locale;
    logger.i('wsAddress will switch to ${selectedLocale.toString()}');
    var wsAddressOptions = wsAddressOptionsISO[selectedLocale];
    List<S2Choice<String>> items = [];
    if (wsAddressOptions != null) {
      for (var wsAddressOption in wsAddressOptions) {
        var item = S2Choice<String>(
            value: wsAddressOption.value, title: wsAddressOption.label);
        items.add(item);
      }
    }
    return Column(children: <Widget>[
      SmartSelect<String>.single(
        modalType: S2ModalType.bottomSheet,
        placeholder: AppLocalizations.instance.text('Please select address'),
        title: AppLocalizations.instance.text('Address'),
        selectedValue: _wsConnectAddress,
        choiceItems: items,
        onChange: (dynamic state) {
          setState(() {
            String value = state.value;
            _wsConnectAddressController.text = value;
            if (value != '') {
              _wsConnectAddress = value;
              AppParams.instance.wsConnectAddress[0] = value;
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
                  labelText: AppLocalizations.instance.text('Primary Address'),
                  prefixIcon: Icon(Icons.location_city),
                ),
                //initialValue: _wsConnectAddress,
                onChanged: (String val) {
                  var appParams = AppParams.instance;
                  appParams.wsConnectAddress[0] = val;
                },
                onFieldSubmitted: (String val) {},
              )),
        ),
      ),
    ]);
  }
}
