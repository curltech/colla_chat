import 'package:flutter/material.dart';

import 'commom_bar.dart';
import 'label_row.dart';

class MoreInfoPage extends StatefulWidget {
  @override
  _MoreInfoPageState createState() => _MoreInfoPageState();
}

class _MoreInfoPageState extends State<MoreInfoPage> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Colors.cyan,
      appBar: new ComMomBar(title: '更多'),
      body: new Column(
        children: <Widget>[
          new LabelRow(
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
