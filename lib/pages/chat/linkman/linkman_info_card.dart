import 'package:colla_chat/widgets/common/image_widget.dart';
import 'package:flutter/material.dart';

import '../../../l10n/localization.dart';

class LinkmanInfoCard extends StatelessWidget {
  final Map<String, dynamic> values;

  const LinkmanInfoCard({Key? key, required this.values}) : super(key: key);

  Widget _build(BuildContext context) {
    List<Widget> children = [];
    for (var entry in values.entries) {
      var key = entry.key;
      if (key == 'avatar') {
        continue;
      }
      String value = entry.value ?? '';
      Widget label = Text(AppLocalizations.t(key) + ':' + value.toString());
      children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0), child: label));
    }
    var info = Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: children);
    var row = SizedBox(
        height: 180,
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          ImageWidget(
            image: values['avatar'],
            width: 32,
            height: 32,
          ),
          Expanded(child: info)
        ]));

    return row;
  }

  @override
  Widget build(BuildContext context) {
    return _build(context);
  }
}
