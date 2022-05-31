import 'package:flutter/material.dart';
import 'package:flutter_awesome_select/flutter_awesome_select.dart';
import 'package:provider/provider.dart';
import '../../l10n/localization.dart';
import '../../provider/locale_data.dart';

class LocalePicker extends StatelessWidget {
  const LocalePicker({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<S2Choice<String>> items = [];
    for (var localeOption in localeOptions) {
      var item = S2Choice<String>(
          value: localeOption.value, title: localeOption.label);
      items.add(item);
    }
    return SmartSelect<String>.single(
      modalType: S2ModalType.bottomSheet,
      placeholder: AppLocalizations.instance.text('Please select language'),
      title: AppLocalizations.instance.text('Language'),
      selectedValue: Provider.of<LocaleDataProvider>(context).locale,
      choiceItems: items,
      onChange: (dynamic state) {
        String value = state.value;
        Provider.of<LocaleDataProvider>(context, listen: false).locale = value;
      },
    );
  }
}
