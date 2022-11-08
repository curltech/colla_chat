import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:flutter/material.dart';


///多个字段显示
class DataListShow extends StatelessWidget {
  final Map<String, dynamic> values;
  final String? avatar;
  late final Widget? avatarImage;

  DataListShow({Key? key, required this.values, this.avatar, this.avatarImage})
      : super(key: key) {
    if (avatarImage == null && avatar != null) {
      avatarImage = ImageUtil.buildImageWidget(
        image:avatar,
        width: 32,
        height: 32,
      );
    }
  }

  Widget _build(BuildContext context) {
    List<Widget> children = [];
    for (var entry in values.entries) {
      var key = entry.key;
      String value = entry.value ?? '';
      Widget label = Text(AppLocalizations.t(key) + ':' + value.toString());
      children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0), child: label));
    }
    var listShow = Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: children);
    List<Widget> rowChildren = [];
    if (avatarImage != null) {
      rowChildren.add(avatarImage!);
    }
    rowChildren.add(Expanded(child: listShow));
    var row = Row(
        crossAxisAlignment: CrossAxisAlignment.center, children: rowChildren);

    return row;
  }

  @override
  Widget build(BuildContext context) {
    return _build(context);
  }
}
