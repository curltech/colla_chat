import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_awesome_select/flutter_awesome_select.dart';

class LocalePicker extends StatefulWidget {
  const LocalePicker({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _LocalePickerState();
  }
}

class _LocalePickerState extends State<LocalePicker> {
  @override
  void initState() {
    super.initState();
    appDataProvider.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  //群主选择界面
  Widget _buildSelectWidget(BuildContext context) {
    List<Option<String>>? localeChoices = [];
    for (var localeOption in localeOptions) {
      Option<String> item = Option<String>(
        localeOption.label,
        localeOption.value,
      );
      localeChoices.add(item);
    }
    return SmartSelectUtil.single<String>(
      title: 'Locale',
      placeholder: 'Select one locale',
      onChange: (selected) {
        if (selected != null) {
          appDataProvider.locale = selected;
        }
      },
      items: localeChoices,
      selectedValue: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildSelectWidget(context);
  }

  @override
  void dispose() {
    appDataProvider.removeListener(_update);
    super.dispose();
  }
}
