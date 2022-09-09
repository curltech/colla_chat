import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/widgets/common/simple_widget.dart';
import 'package:flutter/material.dart';

enum ActionType {
  iconButton,
  inkwell,
  cycleButton,
  switchButton,
  toggle,
  slider,
}

class ActionData {
  final String label;
  final ActionType actionType;
  Widget icon;
  Widget? disableIcon;
  dynamic initValue;

  //是否在enable和disable之间切换
  bool switchEnable;
  Function(int index, String label, {String value})? onTap;

  ActionData(
      {required this.label,
      this.actionType = ActionType.iconButton,
      this.initValue,
      required this.icon,
      this.disableIcon,
      this.switchEnable = false,
      this.onTap});
}

class DataActionCard extends StatelessWidget {
  final List<ActionData> actions;
  final double? height;
  final Function(int index, String label)? onPressed;

  const DataActionCard(
      {Key? key, required this.actions, this.onPressed, this.height})
      : super(key: key);

  Widget _buildIconTextButton(
      BuildContext context, ActionData actionData, int index) {
    return WidgetUtil.buildIconTextButton(
        padding: const EdgeInsets.all(5.0),
        iconColor: appDataProvider.themeData.colorScheme.primary,
        iconSize: 32,
        onPressed: () {
          if (onPressed != null) {
            onPressed!(index, actionData.label);
          } else if (actionData.onTap != null) {
            actionData.onTap!(index, actionData.label);
          }
        },
        text: actionData.label,
        textColor: Colors.black,
        icon: actionData.icon);
  }

  Widget _buildInkWell(BuildContext context, ActionData actionData, int index) {
    return WidgetUtil.buildInkWell(
        padding: const EdgeInsets.all(5.0),
        iconColor: appDataProvider.themeData.colorScheme.primary,
        iconSize: 32,
        onPressed: () {
          if (onPressed != null) {
            onPressed!(index, actionData.label);
          } else if (actionData.onTap != null) {
            actionData.onTap!(index, actionData.label);
          }
        },
        text: actionData.label,
        textColor: Colors.black,
        icon: actionData.icon);
  }

  Widget _buildCircleButton(
      BuildContext context, ActionData actionData, int index) {
    return Column(
      children: <Widget>[
        Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(
              Radius.circular(5.0),
            ),
          ),
          child: WidgetUtil.buildCircleButton(
              backgroundColor: appDataProvider.themeData.colorScheme.primary,
              onPressed: () {
                if (onPressed != null) {
                  onPressed!(index, actionData.label);
                } else if (actionData.onTap != null) {
                  actionData.onTap!(index, actionData.label);
                }
              },
              child: actionData.icon),
        ),
        const SizedBox(height: 5.0),
        Text(
          actionData.label,
          style: const TextStyle(
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildAction(BuildContext context, ActionData actionData, int index) {
    double? margin = height != null && height != 0.0 ? height : 0.0;
    double top = margin != 0.0 ? margin! / 10 : 20.0;

    Widget action;
    if (actionData.actionType == ActionType.iconButton) {
      action = _buildIconTextButton(context, actionData, index);
    } else if (actionData.actionType == ActionType.inkwell) {
      action = _buildIconTextButton(context, actionData, index);
    } else if (actionData.actionType == ActionType.cycleButton) {
      action = _buildIconTextButton(context, actionData, index);
    } else {
      action = _buildIconTextButton(context, actionData, index);
    }

    return Container(
      padding: EdgeInsets.only(top: top, bottom: 5.0),
      width: (appDataProvider.mobileSize.width - 70) / 4,
      child: action,
    );
  }

  Widget _buildActions(BuildContext context) {
    List<Widget> actionWidgets = List.generate(actions.length, (index) {
      ActionData actionData = actions[index];
      return _buildAction(context, actionData, index);
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
