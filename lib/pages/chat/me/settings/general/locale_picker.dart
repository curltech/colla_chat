import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/locale_util.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
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
    List<Option<String>> options = [];
    for (var localeOption in localeOptions) {
      Option<String> option = Option<String>(
          localeOption.label, localeOption.value.toString(),
          hint: '');
      String tag = '${myself.locale.languageCode}_${myself.locale.countryCode}';
      if (tag == option.value) {
        option.checked = true;
      }
      options.add(option);
    }
    return CustomSingleSelectField(
      title: 'Locale',
      onChanged: (selected) {
        if (selected != null) {
          myself.locale = LocaleUtil.getLocale(selected);
        }
      },
      optionController: OptionController(options: options),
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
