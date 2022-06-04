import 'package:colla_chat/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/app_data.dart';
import '../../constant/brightness.dart';
import 'package:flutter_awesome_select/flutter_awesome_select.dart';

class BrightnessPicker extends StatelessWidget {
  const BrightnessPicker({Key? key}) : super(key: key);

  List<S2Choice<String>> _buildItems(BuildContext context) {
    List<S2Choice<String>> items = [];
    for (var brightnessOption in brightnessOptions) {
      var label = AppLocalizations.instance.text(brightnessOption.label);
      var item = S2Choice<String>(value: brightnessOption.value, title: label);
      items.add(item);
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    var locale = Provider.of<AppDataProvider>(context).locale;
    var items = _buildItems(context);
    var instance = AppLocalizations.instance;
    return SmartSelect<String>.single(
      modalType: S2ModalType.bottomSheet,
      placeholder: instance.text('Please select brightness'),
      title: instance.text('Brightness'),
      selectedValue: Provider.of<AppDataProvider>(context).brightness,
      choiceItems: items,
      onChange: (dynamic state) {
        if (state != null) {
          String brightness = state.value;
          Provider.of<AppDataProvider>(context, listen: false).brightness =
              brightness;
        }
      },
    );
  }
}
