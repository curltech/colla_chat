import 'package:flutter/material.dart';

class DocumentData {
  late final Icon icon;

  //图片
  late final List<String>? images;

  //标题
  late final String title;
  late final String? subtitle;

  DocumentData({
    required this.icon,
    this.images,
    required this.title,
    this.subtitle,
  });
}

//通用列表项
class DocumentTile extends StatelessWidget {
  //图标
  late final DocumentData _documentData;

  DocumentTile({Key? key, required DocumentData documentData})
      : super(key: key) {
    _documentData = documentData;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          _documentData.icon,
          Text(
            _documentData.title,
            style: TextStyle(fontSize: 16.0, color: Colors.cyan),
          ),
          Text(
            _documentData.subtitle!,
            style: TextStyle(fontSize: 12.0, color: Colors.cyan),
          ),
        ],
      ),
    );
  }
}
