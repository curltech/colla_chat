import 'package:colla_chat/provider/app_data.dart';
import 'package:flutter/material.dart';

import '../chat/widget/image_view.dart';
import '../chat/widget/ui.dart';

class ListTileView extends StatelessWidget {
  final BoxBorder? border;
  final VoidCallback? onPressed;
  final String title;
  final String? label;
  final String icon;
  final double width;
  final double horizontal;
  final TextStyle titleStyle;
  final bool isLabel;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BoxFit? fit;

  ListTileView({
    this.border,
    this.onPressed,
    required this.title,
    this.label,
    this.padding = const EdgeInsets.symmetric(vertical: 15.0),
    this.isLabel = true,
    this.icon = 'assets/images/favorite.webp',
    this.titleStyle =
        const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
    this.margin,
    this.fit,
    this.width = 45.0,
    this.horizontal = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    var text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title ?? '', style: titleStyle ?? null),
        Text(
          label ?? '',
          style: TextStyle(color: Colors.cyan, fontSize: 12),
        ),
      ],
    );

    var view = [
      isLabel ? text : Text(title, style: titleStyle),
      Spacer(),
      Container(
        width: 7.0,
        child: Image.asset(
          'assets/images/ic_right_arrow_grey.webp',
          color: Colors.cyan.withOpacity(0.5),
          fit: BoxFit.cover,
        ),
      ),
      Space(),
    ];

    var row = Row(
      children: <Widget>[
        Container(
          width: width - 5,
          margin: EdgeInsets.symmetric(horizontal: horizontal),
          child: ImageView(img: icon, width: width, fit: fit!),
        ),
        Container(
          width: appDataProvider.size.width - 60,
          padding: padding,
          decoration: BoxDecoration(border: border),
          child: Row(children: view),
        ),
      ],
    );

    return Container(
      margin: margin,
      child: FlatButton(
        color: Colors.white,
        padding: EdgeInsets.all(0),
        onPressed: onPressed ?? () {},
        child: row,
      ),
    );
  }
}
