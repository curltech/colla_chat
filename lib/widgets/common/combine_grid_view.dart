import 'dart:math';

import 'package:flutter/material.dart';

///把多个组件组合在一起显示，比如图片
class CombineGridView extends StatelessWidget {
  final List<Widget> widgets;
  late double? height;
  late double? width;
  int crossAxisCount;
  final int? maxCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  late double? mainAxisExtent;
  final double childAspectRatio;

  CombineGridView({
    super.key,
    required this.widgets,
    this.height,
    this.width,
    this.crossAxisCount = 3,
    this.maxCount,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.mainAxisExtent,
    this.childAspectRatio = 1,
  }) {
    if (widgets.length <= 4) {
      crossAxisCount = 2;
    }
    if (height == null) {
      var mod = widgets.length % crossAxisCount;
      int lines = (widgets.length / crossAxisCount).floor();
      if (mod > 0) {
        lines++;
      }
      height = lines * (mainAxisExtent!) + 10;
    }
    width ??= crossAxisCount * mainAxisExtent!;
  }

  Widget _buildWidgets(BuildContext context) {
    var maxCount = this.maxCount ?? this.widgets.length;
    maxCount = min(maxCount, this.widgets.length);
    List<Widget> widgets = this.widgets.sublist(0, maxCount);
    return Container(
        height: height,
        width: width,
        margin: const EdgeInsets.all(0.0),
        padding: const EdgeInsets.all(0.0),
        child: GridView.builder(
            itemCount: widgets.length,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            //SliverGridDelegateWithFixedCrossAxisCount 构建一个横轴固定数量Widget
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                //横轴元素个数
                crossAxisCount: crossAxisCount,
                //crossAxisCount,
                //纵轴间距
                mainAxisSpacing: mainAxisSpacing,
                //横轴间距
                crossAxisSpacing: crossAxisSpacing,
                mainAxisExtent: mainAxisExtent,
                //子组件宽高长度比例
                childAspectRatio: childAspectRatio),
            itemBuilder: (BuildContext context, int index) {
              //Widget Function(BuildContext context, int index)
              return widgets[index];
            }));
  }

  @override
  Widget build(BuildContext context) {
    return _buildWidgets(context);
  }
}
