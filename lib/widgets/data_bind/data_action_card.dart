import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/widgets/common/simple_widget.dart';
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
      this.switchEnable = false,
      this.onTap});
}

class DataActionCard extends StatelessWidget {
  final List<ActionData> actions;
  final double? height;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final Function(int index, String label, {String? value})? onPressed;

  const DataActionCard(
      {Key? key,
      required this.actions,
      this.onPressed,
      this.height,
      required this.crossAxisCount,
      this.mainAxisSpacing = 5.0,
      this.crossAxisSpacing = 5.0,
      this.childAspectRatio = 4 / 3})
      : super(key: key);

  Widget _buildIconTextButton(
      BuildContext context, ActionData actionData, int index) {
    return WidgetUtil.buildIconTextButton(
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

  Widget _buildTextFieldButton(
      BuildContext context, ActionData actionData, int index) {
    var controller = TextEditingController();
    var addFriendTextField = Container(
        padding: const EdgeInsets.all(10.0),
        child: TextFormField(
            autofocus: true,
            controller: controller,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              fillColor: Colors.black.withOpacity(0.1),
              filled: true,
              border: InputBorder.none,
              labelText: AppLocalizations.t(actionData.label),
              suffixIcon: IconButton(
                onPressed: () {
                  if (onPressed != null) {
                    onPressed!(index, actionData.label, value: controller.text);
                  } else if (actionData.onTap != null) {
                    actionData.onTap!(index, actionData.label,
                        value: controller.text);
                  }
                },
                icon: const Icon(Icons.person_add),
              ),
            )));

    return addFriendTextField;
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
        height: height,
        margin: const EdgeInsets.all(5.0),
        padding: const EdgeInsets.all(5.0),
        child: GridView.builder(
            itemCount: actionWidgets.length,
            //SliverGridDelegateWithFixedCrossAxisCount 构建一个横轴固定数量Widget
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                //横轴元素个数
                crossAxisCount: crossAxisCount,
                //纵轴间距
                mainAxisSpacing: mainAxisSpacing,
                //横轴间距
                crossAxisSpacing: crossAxisSpacing,
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
