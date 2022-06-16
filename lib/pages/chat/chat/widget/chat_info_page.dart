import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_bar_widget.dart';
import 'chat_mamber.dart';
import 'label_row.dart';

class ChatInfoPage extends StatefulWidget {
  final String id;

  ChatInfoPage(this.id);

  @override
  _ChatInfoPageState createState() => _ChatInfoPageState();
}

class _ChatInfoPageState extends State<ChatInfoPage> {
  var model;

  bool isRemind = false;
  bool isTop = false;
  bool isDoNotDisturb = true;

  Widget buildSwitch(item) {
    return LabelRow(
      label: item['label'],
      margin: item['label'] == '消息免打扰' ? EdgeInsets.only(top: 10.0) : null,
      isLine: item['label'] != '强提醒',
      isRight: false,
      rightW: SizedBox(
        height: 25.0,
        child: CupertinoSwitch(
          value: item['value'],
          onChanged: (v) {},
        ),
      ),
      onPressed: () {},
    );
  }

  List<Widget> body() {
    List switchItems = [
      {"label": '消息免打扰', 'value': isDoNotDisturb},
      {"label": '置顶聊天', 'value': isTop},
      {"label": '强提醒', 'value': isRemind},
    ];

    return [
      ChatMamBer(model: model),
      LabelRow(
        label: '查找聊天记录',
        margin: EdgeInsets.only(top: 10.0),
        onPressed: () {
          //routePush(SearchPage());
        },
      ),
      Column(
        children: switchItems.map(buildSwitch).toList(),
      ),
      LabelRow(
        label: '设置当前聊天背景',
        margin: EdgeInsets.only(top: 10.0),
        onPressed: () {
          //routePush(ChatBackgroundPage());
        },
      ),
      LabelRow(
        label: '清空聊天记录',
        margin: EdgeInsets.only(top: 10.0),
        onPressed: () {
          // confirmAlert(
          //   context,
          //   (isOK) {
          //     if (isOK) DialogUtil.showToast('敬请期待');
          //   },
          //   tips: '确定删除群的聊天记录吗？',
          //   okBtn: '清空',
          // );
        },
      ),
      LabelRow(
        label: '投诉',
        margin: EdgeInsets.only(top: 10.0),
        onPressed: () {
          //routePush(WebViewPage(helpUrl, '投诉'));
        },
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    getInfo();
  }

  getInfo() async {
    // final info = await getUsersProfile([widget.id]);
    // List infoList = json.decode(info);
    // setState(() {
    //   if (Platform.isIOS) {
    //     model = IPersonInfoEntity.fromJson(infoList[0]);
    //   } else {
    //     model = PersonInfoEntity.fromJson(infoList[0]);
    //   }
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.cyan,
      appBar: AppBarWidget(title: '聊天信息'),
      body: SingleChildScrollView(
        child: Column(children: body()),
      ),
    );
  }
}
