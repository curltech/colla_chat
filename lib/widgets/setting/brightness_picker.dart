import 'package:colla_chat/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_awesome_select/flutter_awesome_select.dart';
import 'package:provider/provider.dart';

import '../../constant/brightness.dart';
import '../../provider/app_data_provider.dart';

class BrightnessPicker extends StatelessWidget {
  const BrightnessPicker({Key? key}) : super(key: key);

  List<S2Choice<String>> _buildItems(BuildContext context) {
    List<S2Choice<String>> items = [];
    for (var brightnessOption in brightnessOptions) {
      var label = AppLocalizations.t(brightnessOption.label);
      var item = S2Choice<String>(value: brightnessOption.value, title: label);
      items.add(item);
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    var items = _buildItems(context);
    return SmartSelect<String>.single(
      modalType: S2ModalType.bottomSheet,
      placeholder: AppLocalizations.t('Please select brightness'),
      title: AppLocalizations.t('Brightness'),
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
