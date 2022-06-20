import 'package:colla_chat/pages/chat/chat/widget/ui.dart';
import 'package:flutter/material.dart';

import '../../../../provider/app_data_provider.dart';
import '../../../../tool/util.dart';
import '../../../../widgets/common/image_widget.dart';

class ContactCard extends StatelessWidget {
  final String img, title, nickName, id, area;
  final bool isBorder;
  final double lineWidth;

  ContactCard({
    required this.img,
    required this.title,
    required this.id,
    required this.nickName,
    required this.area,
    this.isBorder = false,
    this.lineWidth = 1,
  }) : assert(id != null);

  @override
  Widget build(BuildContext context) {
    TextStyle labelStyle = TextStyle(fontSize: 14, color: Colors.black);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: isBorder
            ? Border(
                bottom: BorderSide(color: Colors.black, width: lineWidth),
              )
            : null,
      ),
      width: appDataProvider.size.width,
      padding: EdgeInsets.only(right: 15.0, left: 15.0, bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            child: ImageWidget(
                image: img, width: 55, height: 55, fit: BoxFit.cover),
            onTap: () {
              if (ImageUtil.isNetWorkImg(img)) {
                // routePush(
                //   PhotoView(
                //     imageProvider: NetworkImage(img),
                //     onTapUp: (c, f, s) => Navigator.of(context).pop(),
                //     maxScale: 3.0,
                //     minScale: 1.0,
                //   ),
                //);
              } else {
                DialogUtil.showToast('无头像');
              }
            },
          ),
          Space(width: mainSpace * 2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    title ?? '未知',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Space(width: mainSpace / 3),
                  Image.asset('assets/images/Contact_Female.webp',
                      width: 20.0, fit: BoxFit.fill),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(top: 3.0),
                child: Text("昵称：" + nickName ?? '', style: labelStyle),
              ),
              Text("微信号：" + id ?? '', style: labelStyle),
              Text("地区：" + area ?? '', style: labelStyle),
            ],
          )
        ],
      ),
    );
  }
}
