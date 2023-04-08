import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:floating_action_bubble/floating_action_bubble.dart';
import 'package:flutter/material.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';

class MenuUtil {
  ///浮动动画按钮
  static FloatingActionBubble buildActionBubble({
    Key? key,
    required List<Bubble> items,
    required void Function() onPress,
    required Color iconColor,
    required Color backGroundColor,
    required Animation<dynamic> animation,
    Object? herotag,
    IconData? iconData,
    AnimatedIconData? animatedIconData,
  }) {
    return FloatingActionBubble(
        items: items,
        onPress: onPress,
        iconColor: iconColor,
        backGroundColor: backGroundColor,
        animation: animation,
        herotag: herotag,
        iconData: iconData,
        animatedIconData: animatedIconData);
  }

  static Bubble buildBubble({
    required IconData icon,
    required Color iconColor,
    required String title,
    required TextStyle titleStyle,
    required Color bubbleColor,
    required void Function() onPress,
  }) {
    return Bubble(
      title: title,
      iconColor: iconColor,
      bubbleColor: bubbleColor,
      icon: icon,
      titleStyle: titleStyle,
      onPress: onPress,
    );
  }

  static FocusedMenuHolder buildFocusedMenuHolder({
    Key? key,
    required Widget child,
    required Function onPressed,
    required List<FocusedMenuItem> menuItems,
    Duration? duration,
    BoxDecoration? menuBoxDecoration,
    double? menuItemExtent,
    bool? animateMenuItems,
    double? blurSize,
    Color? blurBackgroundColor,
    double? menuWidth,
    double? bottomOffsetHeight,
    double? menuOffset,
    bool openWithTap = false,
  }) {
    return FocusedMenuHolder(
      onPressed: onPressed,
      menuItems: menuItems,
      duration: duration,
      menuBoxDecoration: menuBoxDecoration,
      menuItemExtent: menuItemExtent,
      animateMenuItems: animateMenuItems,
      blurSize: blurSize,
      blurBackgroundColor: blurBackgroundColor,
      menuWidth: menuWidth,
      bottomOffsetHeight: bottomOffsetHeight,
      menuOffset: menuOffset,
      openWithTap: openWithTap,
      child: child,
    );
  }

  static FocusedMenuItem buildFocusedMenuItem({
    Color? backgroundColor,
    required Widget title,
    Icon? trailingIcon,
    required Function onPressed,
  }) {
    return FocusedMenuItem(
        backgroundColor: backgroundColor,
        title: title,
        trailingIcon: trailingIcon,
        onPressed: onPressed);
  }

  // static showPopupMenu({
  //   required BuildContext context,
  //   required List<ActionData> actions,
  //   Rect? rect,
  //   GlobalKey? widgetKey,
  //   void Function(String label)? onPressed,
  // }) {
  //   List<popup.MenuItem> actionWidgets = List.generate(actions.length, (index) {
  //     ActionData actionData = actions[index];
  //     return MenuUtil._buildMenuItem(
  //       title: actionData.label,
  //       image: actionData.icon,
  //     );
  //   });
  //   popup.PopupMenu popMenu = MenuUtil._buildPopupMenu(
  //       onClickMenu: (popup.MenuItemProvider item) {
  //         if (onPressed != null) {
  //           onPressed(item.menuTitle);
  //         }
  //       },
  //       context: context,
  //       items: actionWidgets);
  //   popMenu.show(rect: rect, widgetKey: widgetKey);
  // }
  //
  // ///PopupMenu.show()
  // static popup.PopupMenu _buildPopupMenu(
  //     {required popup.MenuClickCallback onClickMenu,
  //     required BuildContext context,
  //     VoidCallback? onDismiss,
  //     int? maxColumn,
  //     Color? backgroundColor,
  //     Color? highlightColor,
  //     Color? lineColor,
  //     popup.PopupMenuStateChanged? stateChanged,
  //     required List<popup.MenuItemProvider> items}) {
  //   popup.PopupMenu.context = context;
  //   return popup.PopupMenu(
  //       context: context,
  //       onClickMenu: onClickMenu,
  //       onDismiss: onDismiss,
  //       maxColumn: maxColumn,
  //       backgroundColor: backgroundColor,
  //       highlightColor: highlightColor,
  //       lineColor: lineColor,
  //       stateChanged: stateChanged,
  //       items: items);
  // }
  //
  // static popup.MenuItem _buildMenuItem(
  //     {required String title,
  //     required Widget image,
  //     userInfo,
  //     TextStyle? textStyle}) {
  //   return popup.MenuItem(title: title, image: image, textStyle: textStyle);
  // }

  ///弹出式菜单，在child处弹出menuBuilder的Widget
  static Widget buildPopupMenu({
    required Widget child,
    required Widget Function() menuBuilder,
    required PressType pressType,
    CustomPopupMenuController? controller,
    Color arrowColor = const Color(0xFF4C4C4C),
    bool showArrow = true,
    Color barrierColor = Colors.black12,
    double arrowSize = 10.0,
    double horizontalMargin = 10.0,
    double verticalMargin = 10.0,
    PreferredPosition? position,
    void Function(bool)? menuOnChange,
    bool enablePassEvent = true,
  }) {
    CustomPopupMenu menu = CustomPopupMenu(
      menuBuilder: menuBuilder,
      pressType: pressType,
      controller: controller,
      arrowColor: arrowColor,
      showArrow: showArrow,
      barrierColor: barrierColor,
      arrowSize: arrowSize,
      horizontalMargin: horizontalMargin,
      verticalMargin: verticalMargin,
      position: position,
      menuOnChange: menuOnChange,
      enablePassEvent: enablePassEvent,
      child: child,
    );
    return menu;
  }
}
