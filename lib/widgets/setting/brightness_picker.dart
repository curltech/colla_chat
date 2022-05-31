import 'package:colla_chat/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app.dart';
import '../../constant/brightness.dart';
import '../../provider/locale_data.dart';
import '../../provider/theme_data.dart';
import 'package:flutter_awesome_select/flutter_awesome_select.dart';

class BrightnessPicker extends StatelessWidget {
  const BrightnessPicker({Key? key}) : super(key: key);

  List<S2Choice<String>> _buildItems(BuildContext context) {
    var selectedLocale = Provider.of<LocaleDataProvider>(context).locale;
    logger.i('brightness will switch to ${selectedLocale.toString()}');
    var brightnessOptions = brightnessOptionsISO[selectedLocale];
    List<S2Choice<String>> items = [];
    if (brightnessOptions != null) {
      for (var brightnessOption in brightnessOptions) {
        var item = S2Choice<String>(
            value: brightnessOption.value, title: brightnessOption.label);
        items.add(item);
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    var items = _buildItems(context);
    return SmartSelect<String>.single(
      modalType: S2ModalType.bottomSheet,
      placeholder: AppLocalizations.instance.text('Please select brightness'),
      title: AppLocalizations.instance.text('Brightness'),
      selectedValue: Provider.of<ThemeDataProvider>(context).brightness,
      choiceItems: items,
      onChange: (dynamic state) {
        if (state != null) {
          String brightness = state.value;
          Provider.of<ThemeDataProvider>(context, listen: false).brightness =
              brightness;
        }
      },
    );
  }
}
