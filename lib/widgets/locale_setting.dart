import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../provider/locale_data.dart';

class Settings extends StatelessWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var t = AppLocalizations.of(context)!;

    var selectedLocale = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.pageSettingsTitle),
      ),
      body: Center(
        child: Column(
          children: [
            Consumer<LocaleDataProvider>(
              builder: (context, localeData, child) => DropdownButton(
                value: selectedLocale,
                items: [
                  DropdownMenuItem(
                    value: "zh",
                    child: Text(t.pageSettingsInputLanguage),
                  ),
                  DropdownMenuItem(
                    value: "en",
                    child: Text(t.pageSettingsInputLanguage),
                  ),
                ],
                onChanged: (String? value) {
                  if (value != null) {
                    localeData.set(Locale(value));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
