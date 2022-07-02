import 'package:flutter/material.dart';

import '../../l10n/localization.dart';

class BlankWidget extends StatelessWidget {
  final String text = 'This is blank widget';
  const BlankWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(AppLocalizations.t(text)));
  }
}

const blankWidget = BlankWidget();
