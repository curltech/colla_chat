import 'package:colla_chat/entity/dht/myself.dart';
import 'package:flutter/material.dart';

import '../../../constant/base.dart';
import '../../../tool/util.dart';
import '../chat/widget/image_view.dart';
import 'list_tile_view.dart';

class MinePage extends StatefulWidget {
  const MinePage({Key? key}) : super(key: key);

  @override
  _MinePageState createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  void action(name) {
    switch (name) {
      case '收藏':
        break;
      case '设置':
        break;
      default:
        //routePush(LanguagePage());
        break;
    }
  }

  Widget buildContent(item) {
    return ListTileView(
      border: item['label'] == '支付' ||
              item['label'] == '设置' ||
              item['label'] == '表情'
          ? null
          : Border(bottom: BorderSide(color: Colors.black, width: 0.2)),
      title: item['label'],
      titleStyle: TextStyle(fontSize: 15.0),
      isLabel: false,
      padding: EdgeInsets.symmetric(vertical: 16.0),
      icon: item['icon'],
      margin: EdgeInsets.symmetric(
          vertical:
              item['label'] == '支付' || item['label'] == '设置' ? 10.0 : 0.0),
      onPressed: () => action(item['label']),
      width: 25.0,
      fit: BoxFit.cover,
      horizontal: 15.0,
    );
  }

  Widget dynamicAvatar(avatar, {size}) {
    return ImageView(
        img: avatar,
        width: size ?? null,
        height: size ?? null,
        fit: BoxFit.fill);
  }

  Widget body() {
    List data = [
      {'label': '支付', 'icon': 'assets/images/mine/ic_pay.png'},
      {'label': '收藏', 'icon': 'assets/images/favorite.webp'},
      {'label': '相册', 'icon': 'assets/images/mine/ic_card_package.png'},
      {'label': '卡片', 'icon': 'assets/images/mine/ic_card_package.png'},
      {'label': '表情', 'icon': 'assets/images/mine/ic_emoji.png'},
      {'label': '设置', 'icon': 'assets/images/mine/ic_setting.png'},
    ];

    var row = [
      SizedBox(
        width: 60.0,
        height: 60.0,
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(5.0)),
          child: Image.asset(defaultIcon, fit: BoxFit.cover),
        ),
      ),
      Container(
        margin: EdgeInsets.only(left: 15.0),
        height: 60.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              myself.peerId!,
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 20.0,
                  fontWeight: FontWeight.w500),
            ),
            Text(
              '微信号：' + myself.peerId!,
              style: TextStyle(color: Colors.cyan),
            ),
          ],
        ),
      ),
      Spacer(),
      Container(
        width: 13.0,
        margin: EdgeInsets.only(right: 12.0),
        child: Image.asset('assets/images/mine/ic_small_code.png',
            color: Colors.cyan.withOpacity(0.5), fit: BoxFit.cover),
      ),
      Image.asset('assets/images/ic_right_arrow_grey.webp',
          width: 7.0, fit: BoxFit.cover)
    ];

    return Column(
      children: <Widget>[
        InkWell(
          child: Container(
            color: Colors.white,
            height: (ScreenUtil.topBarHeight(context) * 2.5) - 10,
            padding: EdgeInsets.only(left: 20.0, right: 20.0, top: 40.0),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.center, children: row),
          ),
          onTap: () {
            //routePush(PersonalInfoPage());
          },
        ),
        Column(children: data.map(buildContent).toList()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: SingleChildScrollView(child: body()),
    );
  }
}
