import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:flutter/material.dart';

///消息体：命令消息，由固定文本和icon组成
class CommonMessage extends StatelessWidget {
  final TileData? tileData;
  final Widget? child;

  const CommonMessage({
    Key? key,
    this.tileData,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget actionWidget = Container();
    if (child != null) {
      actionWidget = child!;
    } else {
      actionWidget = DataListTile(
        tileData: tileData!,
        contentPadding: EdgeInsets.zero,
        horizontalTitleGap: 5.0,
        minVerticalPadding: 0.0,
        minLeadingWidth: 5.0,
      );
    }
    Widget tile = Center(
      child: actionWidget,
    );

    return Card(elevation: 0, margin: const EdgeInsets.all(5.0), child: tile);
  }
}
