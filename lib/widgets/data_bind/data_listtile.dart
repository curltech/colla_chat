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
class DataTile {
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
  Future<bool?> Function(int index, String title, {String? subtitle})? onTap;
  final Future<bool?> Function(int index, String title, {String? subtitle})?
      onLongPress;

  List<DataTile>? slideActions;
  List<DataTile>? endSlideActions;

  DataTile(
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

  static DataTile of(DataTileMixin mixin, {bool dense = true}) {
    return DataTile(
        title: AppLocalizations.t(mixin.title),
        routeName: mixin.routeName,
        helpPath: mixin.routeName,
        dense: dense,
        prefix: mixin.iconData);
  }

  static List<DataTile> from(List<DataTileMixin> mixins, {bool dense = true}) {
    List<DataTile> tileData = [];
    if (mixins.isNotEmpty) {
      for (var mixin in mixins) {
        DataTile tile = DataTile.of(mixin, dense: dense);
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
    if (other is DataTile) {
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
  final DataTile dataTile;
  final int index;
  final double? dividerHeight;
  final Color? dividerColor;
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
    required this.dataTile,
    this.index = 0,
    this.dividerHeight,
    this.dividerColor,
    this.onTap,
    this.onLongPress,
    this.contentPadding,
    this.horizontalTitleGap,
    this.minVerticalPadding,
    this.minLeadingWidth,
  });

  static Widget buildListTile(
    DataTile tileData, {
    int index = 0,
    double? dividerHeight,
    Color? dividerColor,
    Future<bool?> Function(int, String, {String? subtitle})? onTap,
    Future<bool?> Function(int, String, {String? subtitle})? onLongPress,
  }) {
    var tile = DataListTile(
        dataTile: tileData,
        index: index,
        onTap: onTap,
        onLongPress: onLongPress);
    return Column(children: <Widget>[
      tile,
      Padding(
        padding: const EdgeInsets.only(left: 10.0, right: 10.0),
        child: Divider(
          height: dividerHeight ?? 1.0,
          color: dividerColor ?? Colors.grey.withAlpha(0),
        ),
      ),
    ]);
  }

  Widget _buildListTile(BuildContext context) {
    bool selected = dataTile.selected ?? false;

    ///前导组件，一般是自定义图标或者图像
    Widget? leading = dataTile.getPrefixWidget(selected);

    ///尾部组件数组，首先加入suffix自定义组件或者文本
    List<Widget>? trailing = <Widget>[];
    var suffix = dataTile.suffix;
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
    if (dataTile.routeName != null) {
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
      dataTile.title,
      style: dataTile.dense
          ? const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)
          : null,
      // softWrap: true,
      // overflow: TextOverflow.ellipsis,
    );
    if (dataTile.titleTail != null) {
      titleWidget = Row(children: [
        Expanded(child: titleWidget),
        //const Spacer(),
        AutoSizeText(
          dataTile.titleTail ?? '',
          style: dataTile.dense
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
            await fn?.call(index, dataTile.title, subtitle: dataTile.subtitle);
        if (value == false) {
          return false;
        }
      }
      if (dataTile.onTap != null) {
        var fn = dataTile.onTap;
        value =
            await fn?.call(index, dataTile.title, subtitle: dataTile.subtitle);
        if (value == false) {
          return false;
        }
      }

      ///如果路由名称存在，点击会调用路由
      if (dataTile.routeName != null) {
        indexWidgetProvider.push(dataTile.routeName!, context: context);
      }

      return value;
    }

    Future<bool?> onLongPress() async {
      bool? value;
      if (this.onLongPress != null) {
        var fn = this.onLongPress;
        value =
            await fn?.call(index, dataTile.title, subtitle: dataTile.subtitle);
        if (value == false) {
          return false;
        }
      }
      if (dataTile.onLongPress != null) {
        var fn = dataTile.onLongPress;
        value =
            await fn?.call(index, dataTile.title, subtitle: dataTile.subtitle);
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
      subtitle: dataTile.subtitle != null
          ? AutoSizeText(
              dataTile.subtitle!,
              maxLines: 2,
            )
          : null,
      trailing: trailingWidget,
      isThreeLine: dataTile.isThreeLine,
      dense: dataTile.dense,
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

  ActionPane _buildActionPane(List<DataTile>? slideActions) {
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
            slideAction.onTap!(index, dataTile.title,
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
    if (dataTile.slideActions == null && dataTile.endSlideActions == null) {
      return _buildListTile(context);
    }

    ActionPane? startActionPane;
    if (dataTile.slideActions != null && dataTile.slideActions!.isNotEmpty) {
      startActionPane = _buildActionPane(dataTile.slideActions);
    }
    ActionPane? endActionPane;
    if (dataTile.endSlideActions != null &&
        dataTile.endSlideActions!.isNotEmpty) {
      endActionPane = _buildActionPane(dataTile.endSlideActions);
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
