import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:floating_action_bubble/floating_action_bubble.dart';
import 'package:flutter/material.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';
import 'package:popup_menu/popup_menu.dart';

class MenuUtil {
  /// 自定义的data action弹出菜单
  static Future<void> showPopActionMenu(BuildContext context,
      {double? width,
      double? height,
      double iconSize = 32,
      required List<ActionData> actions, Function(BuildContext context, int index, String label,
              {String? value})?
          onPressed}) async {
    await DialogUtil.show(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
            elevation: 0.0,
            insetPadding: EdgeInsets.zero,
            child: DataActionCard(
                onPressed: (int index, String label, {String? value}) {
                  Navigator.pop(context);
                  onPressed?.call(context, index, label, value: value);
                },
                crossAxisCount: 4,
                actions: actions,
                height: height,
                width: width,
                iconSize: iconSize));
      },
    );
  }

  /// 使用popmenu组件弹出菜单,widgetKey:弹出菜单位置的组件的GlobalKey，比如按钮菜单
  static Future<void> showPopMenu(BuildContext context,
      {GlobalKey<State<StatefulWidget>>? widgetKey,
      double? width,
      double? height,
      MenuType type = MenuType.grid,
      double itemWidth = 72.0,
      double itemHeight = 65.0,
      double arrowHeight = 0.0,
      int maxColumn = 4,
      Color backgroundColor = Colors.grey,
      Color highlightColor = Colors.white,
      Color lineColor = Colors.white,
      TextStyle textStyle =
          const TextStyle(color: Colors.white, fontSize: 12.0),
      TextAlign textAlign = TextAlign.center,
      required List<ActionData> actions,
      required Function(BuildContext context, int index, String label,
              {String? value})?
          onPressed}) async {
    List<MenuItemProvider> items = [];
    for (var action in actions) {
      items.add(MenuItem(
          title: AppLocalizations.t(action.label),
          userInfo: action.label,
          image: action.icon));
    }
    PopupMenu menu = PopupMenu(
      context: context,
      config: MenuConfig(
        type: type,
        itemWidth: itemWidth,
        itemHeight: itemHeight,
        arrowHeight: arrowHeight,
        maxColumn: maxColumn,
        backgroundColor: backgroundColor,
        highlightColor: highlightColor,
        lineColor: lineColor,
        textStyle: textStyle,
        textAlign: textAlign,
      ),
      items: items,
      onClickMenu: (MenuItemProvider item) {
        if (onPressed != null) {
          onPressed(context, 0, item.menuUserInfo);
        }
      },
      onShow: () {},
      onDismiss: () {},
    );
    if (widgetKey != null) {
      menu.show(widgetKey: widgetKey);
    } else {
      double left = (appDataProvider.secondaryBodyWidth - width!) / 2;
      double top = (appDataProvider.totalSize.height -
              appDataProvider.toolbarHeight -
              height!) /
          2;
      menu.show(rect: Rect.fromLTWH(left, top, width, height));
    }
  }

  static Future<dynamic> popModalBottomSheet(BuildContext context,
      {double? width,
      double? height,
      double iconSize = 32,
      required List<ActionData> actions,
      Function(BuildContext context, int index, String label, {String? value})?
          onPressed}) async {
    return await DialogUtil.popModalBottomSheet(builder: (context) {
      int level = (actions.length / 4).ceil();
      height ??= 90.0 * level;
      width ??= appDataProvider.secondaryBodyWidth;
      return DataActionCard(
        showLabel: true,
        showTooltip: true,
        crossAxisCount: 4,
        actions: actions,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        height: height,
        width: width,
        iconSize: iconSize,
        onPressed: (int index, String label, {String? value}) {
          Navigator.pop(context);
          onPressed?.call(context, index, label, value: value);
        },
      );
    });
  }

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
    double verticalMargin = -10.0,
    PreferredPosition position = PreferredPosition.top,
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
