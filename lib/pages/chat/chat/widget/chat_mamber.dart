import 'dart:io';

import 'package:colla_chat/pages/chat/chat/widget/ui.dart';
import 'package:flutter/material.dart';

import '../../../../constant/base.dart';
import '../../../../provider/app_data_provider.dart';
import '../../../../tool/util.dart';
import '../../../../widgets/common/image_widget.dart';

class ChatMamBer extends StatefulWidget {
  final dynamic model;

  ChatMamBer({this.model});

  @override
  _ChatMamBerState createState() => _ChatMamBerState();
}

class _ChatMamBerState extends State<ChatMamBer> {
  @override
  Widget build(BuildContext context) {
    String face =
        Platform.isIOS ? widget.model?.faceURL : widget.model?.faceUrl;
    String name =
        Platform.isIOS ? widget.model?.nickname : widget.model?.nickName;

    List<Widget> wrap = [];

    wrap.add(
      Wrap(
        spacing: (appDataProvider.size.width - 315) / 5,
        runSpacing: 10.0,
        children: [0].map((item) {
          return InkWell(
            child: Container(
              width: 55.0,
              child: Column(
                children: <Widget>[
                  ImageWidget(
                    image: StringUtil.isNotEmpty(face) ? face : defaultIcon,
                    width: 55.0,
                    height: 55.0,
                    fit: BoxFit.cover,
                  ),
                  Space(height: mainSpace / 2),
                  Text(
                    StringUtil.isNotEmpty(name) ? name : '无名氏',
                    style: TextStyle(color: Colors.black),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            onTap: () {
              // routePush(ContactsDetailsPage(
              //     id: widget.model.identifier, title: name, avatar: face));
            },
          );
        }).toList(),
      ),
    );

    wrap.add(
      InkWell(
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 0.2)),
          child: Image.asset('assets/images/chat/ic_details_add.png',
              width: 55.0, height: 55.0, fit: BoxFit.cover),
        ),
        onTap: () {
          // routePush(GroupLaunchPage());
        },
      ),
    );

    return Container(
      color: Colors.white,
      width: appDataProvider.size.width,
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      child: Wrap(
        spacing: (appDataProvider.size.width - 315) / 5,
        runSpacing: 10.0,
        children: wrap,
      ),
    );
  }
}
