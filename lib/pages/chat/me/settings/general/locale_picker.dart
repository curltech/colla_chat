import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:flutter/material.dart';

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
    myself.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  //群主选择界面
  Widget _buildSelectWidget(BuildContext context) {
    return SmartSelectUtil.single<Locale>(
      title: 'Locale',
      placeholder: 'Select one locale',
      onChange: (selected) {
        if (selected != null) {
          myself.locale = selected;
        }
      },
      items: localeOptions,
      selectedValue: myself.locale,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildSelectWidget(context);
  }

  @override
  void dispose() {
    myself.removeListener(_update);
    super.dispose();
  }
}
