import 'package:colla_chat/pages/chat/chat/widget/tip_verify_Input.dart';
import 'package:colla_chat/tool/util.dart';
import 'package:flutter/material.dart';

import 'commom_bar.dart';
import 'commom_button.dart';
import 'main_input.dart';

class SetRemarkPage extends StatefulWidget {
  @override
  _SetRemarkPageState createState() => _SetRemarkPageState();
}

class _SetRemarkPageState extends State<SetRemarkPage> {
  TextEditingController _tc = new TextEditingController();
  FocusNode _f = new FocusNode();

  String initContent = '';

  Widget body() {
    return new SingleChildScrollView(
      child: new Column(
        children: [
          new TipVerifyInput(
            title: '备注',
            defStr: initContent,
            controller: _tc,
            focusNode: _f,
            color: Colors.grey,
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var rWidget = ComMomButton(
      text: '完成',
      style: TextStyle(color: Colors.white),
      width: 45.0,
      margin: EdgeInsets.all(10.0),
      radius: 4.0,
      onTap: () {
        if (!StringUtil.isNotEmpty(_tc.text)) {
          DialogUtil.showToast('输入的内容不能为空');
          return;
        }
      },
    );

    return Scaffold(
      backgroundColor: Colors.cyan,
      appBar: new ComMomBar(
        title: '设置备注和标签',
        rightDMActions: <Widget>[rWidget],
      ),
      body: MainInputBody(child: body(), color: Colors.cyan),
    );
  }
}
