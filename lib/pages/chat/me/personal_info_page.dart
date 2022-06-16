import 'package:cached_network_image/cached_network_image.dart';
import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/tool/util.dart';
import 'package:flutter/material.dart';

import '../../../constant/base.dart';
import '../../../transport/httpclient.dart';
import '../chat/widget/app_bar_widget.dart';
import '../chat/widget/label_row.dart';

class PersonalInfoPage extends StatefulWidget {
  @override
  _PersonalInfoPageState createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  @override
  void initState() {
    super.initState();
  }

  action(v) {
    if (v == '二维码名片') {
      //routePush(CodePage());
    } else {
      print(v);
    }
  }

  Widget dynamicAvatar(avatar, {size}) {
    if (ImageUtil.isNetWorkImg(avatar)) {
      return CachedNetworkImage(
          imageUrl: avatar,
          cacheManager: defaultCacheManager,
          width: size ?? null,
          height: size ?? null,
          fit: BoxFit.fill);
    } else {
      return Image.asset(avatar,
          fit: BoxFit.fill, width: size ?? null, height: size ?? null);
    }
  }

  Widget body() {
    List data = [
      {'label': '微信号', 'value': myself.peerId},
      {'label': '二维码名片', 'value': ''},
      {'label': '更多', 'value': ''},
      {'label': '我的地址', 'value': ''},
    ];

    var content = [
      LabelRow(
        label: '头像',
        isLine: true,
        isRight: true,
        rightW: SizedBox(
          width: 55.0,
          height: 55.0,
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(5.0)),
            child: Image.asset(defaultIcon, fit: BoxFit.cover),
          ),
        ),
        //onPressed: () => _openGallery(),
      ),
      LabelRow(
        label: '昵称',
        isLine: true,
        isRight: true,
        //rValue: model.nickName,
        onPressed: () {
          //routePush(ChangeNamePage(model.nickName));
        },
      ),
      Column(
        children: data.map((item) => buildContent(item)).toList(),
      ),
    ];

    return Column(children: content);
  }

  Widget buildContent(item) {
    return LabelRow(
      label: item['label'],
      rValue: item['value'],
      isLine: item['label'] == '我的地址' || item['label'] == '更多' ? false : true,
      isRight: item['label'] == '微信号' ? false : true,
      margin: EdgeInsets.only(bottom: item['label'] == '更多' ? 10.0 : 0.0),
      rightW: item['label'] == '二维码名片'
          ? Image.asset('assets/images/mine/ic_small_code.png',
              color: Colors.cyan.withOpacity(0.7))
          : Container(),
      onPressed: () => action(item['label']),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(title: '个人信息'),
      body: SingleChildScrollView(child: body()),
    );
  }
}
