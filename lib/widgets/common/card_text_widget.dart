import 'package:flutter/material.dart';

import '../../constant/base.dart';
import '../../l10n/localization.dart';

class CardTextWidget extends StatelessWidget {
  final List<Option> options;

  const CardTextWidget({Key? key, required this.options}) : super(key: key);

  Widget _build(BuildContext context) {
    List<Widget> children = [];
    for (var option in options) {
      Widget label = Text(AppLocalizations.t(option.label));
      Widget value = Text(option.value);
      children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [label, value])));
    }
    return Column(children: children);
  }

  @override
  Widget build(BuildContext context) {
    return Card(elevation: 0.0, child: Center(child: _build(context)));
  }
}
