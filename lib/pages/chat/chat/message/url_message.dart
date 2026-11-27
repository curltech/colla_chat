import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

///消息体：网络连接消息
class UrlMessage extends StatelessWidget {
  final String url;
  final bool isMyself;

  const UrlMessage({
    super.key,
    required this.url,
    required this.isMyself,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: AutoSizeText(
        url,
      ),
    );
  }
}
