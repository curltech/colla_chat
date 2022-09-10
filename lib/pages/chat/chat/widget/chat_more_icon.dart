import 'package:colla_chat/tool/string_util.dart';
import 'package:flutter/material.dart';

import 'commom_button.dart';

class ChatMoreIcon extends StatelessWidget {
  final bool isMore;
  final String value;
  final VoidCallback onTap;
  final GestureTapCallback moreTap;

  ChatMoreIcon({
    this.isMore = false,
    required this.value,
    required this.onTap,
    required this.moreTap,
  });

  @override
  Widget build(BuildContext context) {
    return StringUtil.isNotEmpty(value)
        ? ComMomButton(
            text: '发送',
            style: TextStyle(color: Colors.white),
            width: 45.0,
            margin: EdgeInsets.all(10.0),
            radius: 4.0,
            onTap: onTap ?? () {},
          )
        : InkWell(
            child: Container(
              width: 23,
              margin: EdgeInsets.symmetric(horizontal: 5.0),
              child: Image.asset(
                'assets/images/chat/ic_chat_more.webp',
                color: Colors.black,
                fit: BoxFit.cover,
              ),
            ),
            onTap: () {
              if (moreTap != null) {
                moreTap();
              }
            },
          );
  }
}
