import 'package:flutter/material.dart';

import 'app_bar_view.dart';
import 'label_row.dart';

class MoreInfoPage extends StatefulWidget {
  @override
  _MoreInfoPageState createState() => _MoreInfoPageState();
}

class _MoreInfoPageState extends State<MoreInfoPage> {
  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: '更多',
      child: Column(
        children: <Widget>[
          LabelRow(
            label: '个性签名',
            rValue: '暂无',
            isRight: false,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
