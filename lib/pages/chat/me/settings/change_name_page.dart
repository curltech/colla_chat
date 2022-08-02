import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/localization.dart';
import '../../../../tool/util.dart';
import '../../../../widgets/common/app_bar_view.dart';
import '../../chat/widget/main_input.dart';
import '../../chat/widget/tip_verify_Input.dart';

class ChangeNamePage extends StatefulWidget {
  final String name;

  ChangeNamePage(this.name);

  @override
  State createState() => _ChangeNamePageState();
}

class _ChangeNamePageState extends State<ChangeNamePage> {
  TextEditingController _tc = TextEditingController();
  FocusNode _f = FocusNode();

  String initContent = '';

  void setInfoMethod() {
    if (!StringUtil.isNotEmpty(_tc.text)) {
      DialogUtil.showToast('输入的内容不能为空');
      return;
    }
    if (_tc.text.length > 12) {
      DialogUtil.showToast('输入的内容太长了');
      return;
    }
  }

  Widget body() {
    var widget = TipVerifyInput(
      title: '好名字可以让你的朋友更容易记住你',
      defStr: initContent,
      controller: _tc,
      focusNode: _f,
      color: Colors.cyan,
    );

    return SingleChildScrollView(child: Column(children: [widget]));
  }

  @override
  void initState() {
    super.initState();
    initContent = widget.name;
  }

  @override
  Widget build(BuildContext context) {
    var rWidget = AppBarPopupMenu();
    // ComMomButton(
    //   text: '保存',
    //   style: TextStyle(color: Colors.white),
    //   width: 55.0,
    //   margin: EdgeInsets.only(right: 15.0, top: 10.0, bottom: 10.0),
    //   radius: 4.0,
    // );

    return AppBarView(
      title: Text(AppLocalizations.t('更改名字')),
      rightPopupMenus: [rWidget],
      child: MainInputBody(color: Colors.cyan, child: body()),
    );
  }
}
