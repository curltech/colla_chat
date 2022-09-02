import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/widgets/common/simple_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:flutter/material.dart';

class ActionCard extends StatelessWidget {
  final List<TileData> actions;
  final double? height;
  final Function(int index, String title)? onPressed;

  const ActionCard(
      {Key? key, required this.actions, this.onPressed, this.height})
      : super(key: key);

  Widget _buildAction(BuildContext context, TileData tileData, int index) {
    double? margin = height != null && height != 0.0 ? height : 0.0;
    double top = margin != 0.0 ? margin! / 10 : 20.0;

    return Container(
      padding: EdgeInsets.only(top: top, bottom: 5.0),
      width: (appDataProvider.mobileSize.width - 70) / 4,
      child: WidgetUtil.buildIconTextButton(
          padding: const EdgeInsets.all(5.0),
          iconColor: appDataProvider.themeData!.colorScheme.primary,
          iconSize: 32,
          onPressed: () {
            if (onPressed != null) {
              onPressed!(index, tileData.title);
            } else if (tileData.onTap != null) {
              tileData.onTap!(index, tileData.title);
            }
          },
          text: tileData.title ?? '',
          textColor: Colors.black,
          icon: tileData.icon!),
    );
  }

  Widget _buildActions(BuildContext context) {
    List<Widget> actionWidgets = List.generate(actions.length, (index) {
      TileData tileData = actions[index];
      return _buildAction(context, tileData, index);
    });
    return Container(
      height: height,
      margin: const EdgeInsets.all(5.0),
      padding: const EdgeInsets.only(bottom: 5.0),
      child: Wrap(runSpacing: 5.0, spacing: 5.0, children: actionWidgets),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildActions(context);
  }
}
