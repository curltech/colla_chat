import 'package:colla_chat/pages/chat/chat/widget/tip_verify_Input.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/common/app_bar_view.dart';
import 'main_input.dart';

class SetRemarkPage extends StatefulWidget {
  @override
  _SetRemarkPageState createState() => _SetRemarkPageState();
}

class _SetRemarkPageState extends State<SetRemarkPage> {
  TextEditingController _tc = TextEditingController();
  FocusNode _f = FocusNode();

  String initContent = '';

  Widget body() {
    return SingleChildScrollView(
      child: Column(
        children: [
          TipVerifyInput(
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
    var rWidget = '';
    // ComMomButton(
    //   text: '完成',
    //   style: TextStyle(color: Colors.white),
    //   width: 45.0,
    //   margin: EdgeInsets.all(10.0),
    //   radius: 4.0,
    //   onTap: () {
    //     if (!StringUtil.isNotEmpty(_tc.text)) {
    //       DialogUtil.showToast('输入的内容不能为空');
    //       return;
    //     }
    //   },
    // );

    return AppBarView(
      title: '设置备注和标签',
      rightActions: <String>[rWidget],
      child: MainInputBody(child: body(), color: Colors.cyan),
    );
  }
}
