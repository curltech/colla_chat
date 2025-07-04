import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:flutter/material.dart';

enum ActionType {
  iconButton,
  textFieldButton,
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
  String? tooltip;
  dynamic initValue;

  //是否在enable和disable之间切换
  bool switchEnable;
  Function(int index, String label, {String? value})? onTap;

  ActionData(
      {required this.label,
      this.actionType = ActionType.iconButton,
      this.initValue,
      required this.icon,
      this.disableIcon,
      this.tooltip,
      this.switchEnable = false,
      this.onTap});
}

class DataActionCard extends StatelessWidget {
  final List<ActionData> actions;
  late final double? height;
  late final double? width;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  late final double? mainAxisExtent;
  final double childAspectRatio;
  final double iconSize;
  final bool showLabel;
  final Color? labelColor;
  final bool showTooltip;
  final Function(int index, String label, {String? value})? onPressed;

  DataActionCard({
    super.key,
    required this.actions,
    this.onPressed,
    this.height,
    this.crossAxisCount = 4,
    this.mainAxisSpacing = 10.0,
    this.crossAxisSpacing = 10.0,
    this.mainAxisExtent,
    this.childAspectRatio = 1,
    this.iconSize = 32,
    this.showLabel = true,
    this.showTooltip = true,
    this.labelColor,
    this.width,
  }) {
    var mod = actions.length % crossAxisCount;
    int lines = (actions.length / crossAxisCount).floor();
    if (mod > 0) {
      lines++;
    }
    mainAxisExtent ??= iconSize + (showLabel ? 25 : 0);
    height ??= lines * mainAxisExtent! + 60;
    width ??= crossAxisCount * mainAxisExtent! + 60;
  }

  Widget _buildIconTextButton(
      BuildContext context, ActionData actionData, int index) {
    var label = AppLocalizations.t(actionData.label);
    var tooltip = AppLocalizations.t(actionData.tooltip ?? '');
    return IconTextButton(
        iconColor: myself.primary,
        iconSize: iconSize,
        onPressed: () {
          if (onPressed != null) {
            onPressed!(index, actionData.label);
          }
          if (actionData.onTap != null) {
            actionData.onTap!(index, actionData.label);
          }
        },
        label: showLabel ? label : null,
        tooltip: showTooltip ? tooltip : null,
        labelColor: labelColor,
        icon: actionData.icon);
  }

  Widget _buildTextFieldButton(
      BuildContext context, ActionData actionData, int index) {
    var label = AppLocalizations.t(actionData.label);
    var tooltip = AppLocalizations.t(actionData.tooltip ?? '');
    var controller = TextEditingController();
    var addFriendTextField = Container(
        padding: const EdgeInsets.all(10.0),
        child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.text,
            decoration: buildInputDecoration(
              labelText: label,
              suffixIcon: IconButton(
                onPressed: () {
                  if (onPressed != null) {
                    onPressed!(index, actionData.label, value: controller.text);
                  }
                  if (actionData.onTap != null) {
                    actionData.onTap!(index, actionData.label,
                        value: controller.text);
                  }
                },
                icon: const Icon(Icons.person_add),
              ),
            )));

    return addFriendTextField;
  }

  Widget _buildInkWellTextButton(
      BuildContext context, ActionData actionData, int index) {
    var label = AppLocalizations.t(actionData.label);
    var tooltip = AppLocalizations.t(actionData.tooltip ?? '');
    return InkWellTextButton(
        padding: const EdgeInsets.all(5.0),
        iconColor: myself.primary,
        iconSize: iconSize,
        onPressed: () {
          if (onPressed != null) {
            onPressed!(index, actionData.label);
          }
          if (actionData.onTap != null) {
            actionData.onTap!(index, actionData.label);
          }
        },
        label: label,
        labelColor: labelColor,
        icon: actionData.icon);
  }

  Widget _buildCircleTextButton(
      BuildContext context, ActionData actionData, int index) {
    var label = AppLocalizations.t(actionData.label);
    var tooltip = AppLocalizations.t(actionData.tooltip ?? '');
    return Column(
      children: <Widget>[
        Expanded(
            child: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(
              Radius.circular(5.0),
            ),
          ),
          child: CircleTextButton(
              backgroundColor: myself.primary,
              onPressed: () {
                if (onPressed != null) {
                  onPressed!(index, actionData.label);
                }
                if (actionData.onTap != null) {
                  actionData.onTap!(index, actionData.label);
                }
              },
              child: actionData.icon),
        )),
        const SizedBox(height: 5.0),
        CommonAutoSizeText(
          label,
          style: TextStyle(
            color: labelColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAction(BuildContext context, ActionData actionData, int index) {
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

    return action;
  }

  Widget _buildActions(BuildContext context) {
    List<Widget> actionWidgets = List.generate(actions.length, (index) {
      ActionData actionData = actions[index];
      return _buildAction(context, actionData, index);
    });
    return Container(
        alignment: Alignment.center,
        height: height,
        width: width,
        margin: const EdgeInsets.all(0.0),
        padding: const EdgeInsets.all(10.0),
        child: GridView.builder(
            itemCount: actionWidgets.length,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            //SliverGridDelegateWithFixedCrossAxisCount 构建一个横轴固定数量Widget
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                //横轴元素个数
                crossAxisCount: crossAxisCount,
                //纵轴间距
                mainAxisSpacing: mainAxisSpacing,
                //横轴间距
                crossAxisSpacing: crossAxisSpacing,
                mainAxisExtent: mainAxisExtent,
                //子组件宽高长度比例
                childAspectRatio: childAspectRatio),
            itemBuilder: (BuildContext context, int index) {
              //Widget Function(BuildContext context, int index)
              return actionWidgets[index];
            }));
  }

  @override
  Widget build(BuildContext context) {
    return _buildActions(context);
  }
}
