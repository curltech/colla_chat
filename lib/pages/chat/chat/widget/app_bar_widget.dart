import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

///工作区的顶部栏AppBar，定义了回退按钮
class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const AppBarWidget(
      {this.title = '',
      this.showShadow = false,
      this.rightDMActions,
      this.backgroundColor = Colors.white,
      this.mainColor = Colors.black,
      this.titleW,
      this.bottom,
      this.leadingImg = '',
      this.leadingW});

  final String title;
  final bool showShadow;
  final List<Widget>? rightDMActions;
  final Color backgroundColor;
  final Color mainColor;
  final Widget? titleW;
  final Widget? leadingW;
  final PreferredSizeWidget? bottom;
  final String leadingImg;

  @override
  Size get preferredSize => Size(100, 50);

  Widget? leading(BuildContext context) {
    final bool isShow = Navigator.canPop(context);
    if (isShow) {
      return InkWell(
        child: SizedBox(
          width: 15,
          height: 28,
          child: leadingImg != ''
              ? Image.asset(leadingImg)
              : Icon(CupertinoIcons.back, color: mainColor),
        ),
        onTap: () {
          if (Navigator.canPop(context)) {
            FocusScope.of(context).requestFocus(FocusNode());
            Navigator.pop(context);
          }
        },
      );
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return showShadow
        ? Container(
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: Colors.grey, width: showShadow ? 0.5 : 0.0))),
            child: AppBar(
              title: titleW ??
                  Text(
                    title,
                    style: TextStyle(
                        color: mainColor,
                        fontSize: 17.0,
                        fontWeight: FontWeight.w600),
                  ),
              backgroundColor: mainColor,
              elevation: 0.0,
              brightness: Brightness.light,
              leading: leadingW ?? leading(context),
              centerTitle: true,
              actions: rightDMActions ?? [Center()],
              bottom: bottom,
            ),
          )
        : AppBar(
            title: titleW ??
                Text(
                  title,
                  style: TextStyle(
                      color: mainColor,
                      fontSize: 17.0,
                      fontWeight: FontWeight.w600),
                ),
            backgroundColor: backgroundColor,
            elevation: 0.0,
            brightness: Brightness.light,
            leading: leadingW ?? leading(context),
            centerTitle: false,
            bottom: bottom,
            actions: rightDMActions ?? [Center()],
          );
  }
}
