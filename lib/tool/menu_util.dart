import 'dart:ui';

import 'package:floating_action_bubble/floating_action_bubble.dart';
import 'package:flutter/material.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';
import 'package:popup_menu/popup_menu.dart' as popup;

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

  ///PopupMenu.show()
  static popup.PopupMenu buildPopupMenu(
      {required popup.MenuClickCallback onClickMenu,
      required BuildContext context,
      required VoidCallback onDismiss,
      required int maxColumn,
      required Color backgroundColor,
      required Color highlightColor,
      required Color lineColor,
      required popup.PopupMenuStateChanged stateChanged,
      required List<popup.MenuItemProvider> items}) {
    popup.PopupMenu.context = context;
    return popup.PopupMenu(
        context: context,
        onClickMenu: onClickMenu,
        onDismiss: onDismiss,
        maxColumn: maxColumn,
        backgroundColor: backgroundColor,
        highlightColor: highlightColor,
        lineColor: lineColor,
        stateChanged: stateChanged,
        items: items);
  }

  static popup.MenuItem buildMenuItem(
      {required String title,
      required Widget image,
      userInfo,
      required TextStyle textStyle}) {
    return popup.MenuItem(
        title: title, image: image, textStyle: textStyle, userInfo: userInfo);
  }
}
