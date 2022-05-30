import 'package:flutter/material.dart';
import 'package:flutter_awesome_select/flutter_awesome_select.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../provider/locale_data.dart';
import '../../provider/locale_data.dart';

class LocalePicker extends StatelessWidget {
  const LocalePicker({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var t = AppLocalizations.of(context)!;
    var selectedLocale = Localizations.localeOf(context).toString();
    List<S2Choice<String>> items = [];
    for (var localeOption in localeOptions) {
      var item = S2Choice<String>(
          value: localeOption.value, title: localeOption.label);
      items.add(item);
    }
    return Consumer<LocaleDataProvider>(
      builder: (context, localeData, child) => SmartSelect<String>.single(
        modalType: S2ModalType.bottomSheet,
        placeholder: '请选择语言',
        title: '请选择语言',
        selectedValue: selectedLocale,
        choiceItems: items,
        onChange: (dynamic state) {
          String value = state.value;
          var locales = value.toString().split('_');
          localeData.locale = Locale(locales[0], locales[1]);
        },
      ),
    );
  }
}
