import 'package:cached_network_image/cached_network_image.dart';
import 'package:colla_chat/provider/app_data.dart';
import 'package:flutter/material.dart';

import '../../../constant/base.dart';
import '../../../tool/util.dart';
import '../chat/widget/app_bar_widget.dart';
import '../chat/widget/image_view.dart';
import '../chat/widget/ui.dart';

class QrCodePage extends StatefulWidget {
  final bool isGroup;

  QrCodePage([this.isGroup = false]);

  @override
  _QrCodePageState createState() => _QrCodePageState();
}

class _QrCodePageState extends State<QrCodePage> {
  List data = ['换个样式', '保存到手机', '扫描二维码', '重置二维码'];
  List groupData = ['保存到手机', '扫描二维码'];

  @override
  Widget build(BuildContext context) {
    var rWidget = [
      SizedBox(
        width: 60,
        child: FlatButton(
          padding: EdgeInsets.all(0),
          onPressed: () {
            // codeDialog(
            //   context,
            //   widget.isGroup ? groupData : data,
            // );
          },
          child: Image.asset('ic_contacts_details.png'),
        ),
      )
    ];

    var body = [
      Container(
        margin: EdgeInsets.only(
            left: 20.0, right: 20.0, top: appDataProvider.size.width / 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            children: <Widget>[
              SizedBox(
                width: appDataProvider.size.width - 40.0,
                child: CardPerson(
                  name: 'CrazyQ1',
                  area: '北京 海淀',
                  icon: 'assets/images/Contact_Male.webp',
                  groupName: widget.isGroup ? 'wechat_flutter 101号群' : null,
                ),
              ),
              Space(width: mainSpace),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: !widget.isGroup ? 0 : 20,
                  vertical: !widget.isGroup ? 0 : 20,
                ),
                child: CachedNetworkImage(
                  imageUrl: '',
                  fit: BoxFit.cover,
                  width: appDataProvider.size.width - 40,
                ),
              ),
              Space(height: mainSpace * 2),
              Text(
                '${widget.isGroup ? '该二维码7天内(7月1日前)有效，重新进入将更新' : '扫一扫上面的二维码图案，加我微信'}',
                style: TextStyle(color: Colors.cyan),
              ),
            ],
          ),
        ),
      )
    ];
    return Scaffold(
      backgroundColor: Colors.cyan,
      appBar: AppBarWidget(
          title: '${widget.isGroup ? '群' : ''}二维码名片', rightDMActions: rWidget),
      body: SingleChildScrollView(child: Column(children: body)),
    );
  }
}

class CardPerson extends StatelessWidget {
  final String? name, icon, area, groupName;

  CardPerson({this.name, this.icon, this.area, this.groupName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(right: 15.0),
          child: ImageView(
            img: StringUtil.isNotEmpty(groupName)
                ? defaultGroupAvatar
                : defaultAvatar,
            width: 45,
            fit: BoxFit.fill,
            height: 0,
          ),
        ),
        StringUtil.isNotEmpty(groupName)
            ? Text(
                groupName ?? '',
                style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.w600),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        name ?? '',
                        style: TextStyle(
                            fontSize: 17.0, fontWeight: FontWeight.w600),
                      ),
                      Space(width: mainSpace / 2),
                      Image.asset(
                        icon ?? '',
                        width: 18.0,
                        fit: BoxFit.cover,
                      ),
                    ],
                  ),
                  Space(height: mainSpace / 3),
                  Text(
                    area ?? '',
                    style: TextStyle(fontSize: 14.0, color: Colors.cyan),
                  ),
                ],
              )
      ],
    );
  }
}
