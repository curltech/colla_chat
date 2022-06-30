import 'package:flutter/material.dart';

import '../../constant/base.dart';
import '../../l10n/localization.dart';
import '../../tool/util.dart';

class CardTextWidget extends StatelessWidget {
  final List<Option> options;

  const CardTextWidget({Key? key, required this.options}) : super(key: key);

  Widget _build(BuildContext context) {
    List<Widget> children = [];
    for (var option in options) {
      var value = option.value;
      if (StringUtil.isNotEmpty(value)) {
        Widget label = Text(AppLocalizations.t(option.label) + ':');
        Widget value = Text(option.value);
        children.add(Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [label, value])));
      }
    }
    return ListView(children: children);
  }

  @override
  Widget build(BuildContext context) {
    return _build(context);
  }
}
