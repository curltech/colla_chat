import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

///指定路由样式，不指定则系统判断，系统判断的方法是如果是移动则走全局路由，否则走工作区路由
enum RouteStyle { workspace, navigator }

/// 通用列表项的数据模型
class TileData {
  //可以是Widget，String，IconData
  final dynamic prefix;

  //标题
  final String title;
  final String? titleTail;
  final String? subtitle;
  final dynamic suffix;

  //路由名称，用于是否点击路由
  final String? routeName;

  //帮助文件路径，用于是否显示帮助按钮
  final String? helpPath;

  //是否缩小
  bool dense;
  bool? selected;

  final bool isThreeLine;

  //缺省行为，为空的时候，是打上选择标志，颜色变化
  Future<bool?> Function(int index, String title, {String? subtitle})?
      onTap;
  final Future<bool?> Function(int index, String title, {String? subtitle})?
      onLongPress;

  List<TileData>? slideActions;
  List<TileData>? endSlideActions;

  TileData(
      {this.prefix,
      required this.title,
      this.subtitle,
      this.titleTail,
      this.suffix,
      this.routeName,
      this.helpPath,
      this.dense = true,
      this.selected = false,
      this.isThreeLine = false,
      this.onTap,
      this.onLongPress});

  static TileData of(TileDataMixin mixin, {bool dense = false}) {
    return TileData(
        title: AppLocalizations.t(mixin.title),
        routeName: mixin.routeName,
        helpPath: mixin.routeName,
        dense: dense,
        prefix: mixin.iconData);
  }

  static List<TileData> from(List<TileDataMixin> mixins, {bool dense = false}) {
    List<TileData> tileData = [];
    if (mixins.isNotEmpty) {
      for (var mixin in mixins) {
        TileData tile = TileData.of(mixin, dense: dense);
        tileData.add(tile);
      }
    }

    return tileData;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is TileData) {
      return runtimeType == other.runtimeType && title == other.title;
    }
    return false;
  }

  @override
  int get hashCode => title.hashCode;

  Widget? getPrefixWidget(bool selected) {
    Widget? leading;
    if (prefix != null) {
      if (prefix is Widget) {
        leading = prefix;
      } else if (prefix is String) {
        leading = ImageUtil.buildImageWidget(
          imageContent: prefix,
          fit: BoxFit.contain,
        );
      } else if (prefix is IconData) {
        // leading = Icon(prefix);
        if (selected) {
          leading = Icon(prefix, color: Colors.white);
        } else {
          leading = Icon(prefix, color: myself.primary);
        }
      }
    }

    return leading;
  }
}

/// 通用列表项，用构造函数传入数据，根据数据构造列表项
class DataListTile extends StatelessWidget {
  final TileData tileData;
  final int index;
  final EdgeInsets? contentPadding;
  final double? horizontalTitleGap;
  final double? minVerticalPadding;
  final double? minLeadingWidth;

  ///如果定义了点击回调函数，序号为参数进行回调
  ///回调函数有两个，一个构造函数传入的成员变量，用于处理高亮显示
  ///二是数据项里面定义的，用于自定义的后续任务
  final Future<bool?> Function(int index, String title, {String? subtitle})?
      onTap;
  final Future<bool?> Function(int index, String title, {String? subtitle})?
      onLongPress;

  const DataListTile({
    super.key,
    required this.tileData,
    this.index = 0,
    this.onTap,
    this.onLongPress,
    this.contentPadding,
    this.horizontalTitleGap,
    this.minVerticalPadding,
    this.minLeadingWidth,
  });

  Widget _buildListTile(BuildContext context) {
    bool selected = tileData.selected ?? false;

    ///前导组件，一般是自定义图标或者图像
    Widget? leading = tileData.getPrefixWidget(selected);

    ///尾部组件数组，首先加入suffix自定义组件或者文本
    List<Widget>? trailing = <Widget>[];
    var suffix = tileData.suffix;
    if (suffix != null) {
      if (suffix is Widget) {
        trailing.add(suffix);
      } else if (suffix is String) {
        trailing.add(AutoSizeText(
          suffix,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
        ));
      }
    }

    ///然后，如果路由名称存在，加入路由图标
    if (tileData.routeName != null) {
      trailing.add(Icon(Icons.chevron_right, color: myself.primary));
    }

    ///横向排列尾部的组件
    Widget? trailingWidget;
    if (trailing.length == 1) {
      trailingWidget = trailing[0];
    } else if (trailing.length > 1) {
      trailingWidget = SizedBox(
          width: 300,
          child: Row(
              mainAxisAlignment: MainAxisAlignment.end, children: trailing));
    }
    Widget titleWidget = AutoSizeText(
      tileData.title,
      style: tileData.dense
          ? const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)
          : null,
      // softWrap: true,
      // overflow: TextOverflow.ellipsis,
    );
    if (tileData.titleTail != null) {
      titleWidget = Row(children: [
        Expanded(child: titleWidget),
        //const Spacer(),
        AutoSizeText(
          tileData.titleTail ?? '',
          style: tileData.dense
              ? const TextStyle(
                  fontSize: 12,
                )
              : null,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
          maxLines: 3,
        ),
      ]);
    }

    Future<bool?> onTap() async {
      bool? value;
      if (this.onTap != null) {
        var fn = this.onTap;
        value =
            await fn?.call(index, tileData.title, subtitle: tileData.subtitle);
        if (value == false) {
          return false;
        }
      }
      if (tileData.onTap != null) {
        var fn = tileData.onTap;
        value =
            await fn?.call(index, tileData.title, subtitle: tileData.subtitle);
        if (value == false) {
          return false;
        }
      }

      ///如果路由名称存在，点击会调用路由
      if (tileData.routeName != null) {
        indexWidgetProvider.push(tileData.routeName!, context: context);
      }

      return value;
    }

    Future<bool?> onLongPress() async {
      bool? value;
      if (this.onLongPress != null) {
        var fn = this.onLongPress;
        value =
            await fn?.call(index, tileData.title, subtitle: tileData.subtitle);
        if (value == false) {
          return false;
        }
      }
      if (tileData.onLongPress != null) {
        var fn = tileData.onLongPress;
        value =
            await fn?.call(index, tileData.title, subtitle: tileData.subtitle);
      }

      return value;
    }

    ///未来不使用ListTile，因为高度固定，不够灵活
    var listTile = ListTile(
      contentPadding: contentPadding,
      horizontalTitleGap: horizontalTitleGap,
      minVerticalPadding: minVerticalPadding,
      minLeadingWidth: minLeadingWidth,
      selected: selected,
      selectedColor: Colors.white,
      selectedTileColor: myself.primary,
      leading: leading,
      title: titleWidget,
      subtitle: tileData.subtitle != null
          ? AutoSizeText(
              tileData.subtitle!,
              maxLines: 2,
            )
          : null,
      trailing: trailingWidget,
      isThreeLine: tileData.isThreeLine,
      dense: tileData.dense,
      onTap: onTap,
      onLongPress: onLongPress,
    );

    if (selected) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 0.0),
        color: myself.secondary.withAlpha(50),
        child: listTile,
      );
    }

    return listTile;
  }

  ActionPane _buildActionPane(List<TileData>? slideActions) {
    List<SlidableAction> slidableActions = [];
    int i = 0;

    for (var slideAction in slideActions!) {
      Color backgroundColor = myself.primary;
      if (i == 0) {
        backgroundColor = Colors.blue;
      } else if (i == 1) {
        backgroundColor = Colors.amber;
      } else if (i == 2) {
        backgroundColor = Colors.red;
      } else if (i == 3) {
        backgroundColor = Colors.purple;
      } else if (i == 4) {
        backgroundColor = myself.primary;
      }
      SlidableAction slidableAction = SlidableAction(
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0),
        onPressed: (context) {
          if (slideAction.onTap != null) {
            slideAction.onTap!(index, tileData.title,
                subtitle: slideAction.title);
          }
        },
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        icon: slideAction.prefix,
        label: AppLocalizations.t(slideAction.title),
        borderRadius: BorderRadius.circular(0),
      );
      slidableActions.add(slidableAction);
      i++;
    }
    double extentRatio = 0.3 * slideActions.length;
    if (extentRatio < 0.3) {
      extentRatio = 0.3;
    } else if (extentRatio > 0.9) {
      extentRatio = 0.9;
    }
    ActionPane actionPane = ActionPane(
      extentRatio: extentRatio,
      motion: const DrawerMotion(),
      //BehindMotion,StretchMotion,DrawerMotion,ScrollMotion
      //dismissible: DismissiblePane(onDismissed: () {}),
      children: slidableActions,
    );

    return actionPane;
  }

  Widget _buildSlideActionListTile(BuildContext context) {
    if (tileData.slideActions == null && tileData.endSlideActions == null) {
      return _buildListTile(context);
    }

    ActionPane? startActionPane;
    if (tileData.slideActions != null && tileData.slideActions!.isNotEmpty) {
      startActionPane = _buildActionPane(tileData.slideActions);
    }
    ActionPane? endActionPane;
    if (tileData.endSlideActions != null &&
        tileData.endSlideActions!.isNotEmpty) {
      endActionPane = _buildActionPane(tileData.endSlideActions);
    }
    return Slidable(
      key: UniqueKey(),
      startActionPane: startActionPane,
      endActionPane: endActionPane,
      child: _buildListTile(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: myself,
      builder: (BuildContext context, Widget? child) {
        return _buildSlideActionListTile(context);
      },
    );
  }
}
