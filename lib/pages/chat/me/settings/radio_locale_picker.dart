import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../provider/app_data_provider.dart';

class RadioLocalePicker extends StatelessWidget {
  const RadioLocalePicker({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var body = ListView(
      children: List.generate(localeOptions.length, (index) {
        final String language = localeOptions[index].label;
        final String locale = localeOptions[index].value;
        return RadioListTile(
          value: locale,
          groupValue: Provider.of<AppDataProvider>(context).locale,
          onChanged: (String? value) {
            Provider.of<AppDataProvider>(context).locale = value!;
          },
          title: Text(language),
        );
      }),
    );
    return Scaffold(
      body: body,
    );
  }
}
