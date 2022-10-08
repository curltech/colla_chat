import 'package:flutter/material.dart';

///消息体：网络连接消息
class UrlMessage extends StatelessWidget {
  final String url;
  final bool isMyself;

  const UrlMessage({
    Key? key,
    required this.url,
    required this.isMyself,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Text(
        url,
      ),
    );
  }
}
