import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:flutter/material.dart';

///消息体：命令消息，由固定文本和icon组成
class CommonMessage extends StatelessWidget {
  final DataTile? tileData;
  final Widget? child;

  const CommonMessage({
    super.key,
    this.tileData,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    Widget actionWidget;
    if (child != null) {
      actionWidget = child!;
    } else {
      actionWidget = DataListTile(
        dataTile: tileData!,
        contentPadding: EdgeInsets.zero,
        horizontalTitleGap: 0.0,
        minVerticalPadding: 0.0,
        minLeadingWidth: 0.0,
      );
    }

    return Card(
        elevation: 0,
        shape: const ContinuousRectangleBorder(),
        margin: const EdgeInsets.all(3.0),
        child: actionWidget);
  }
}
