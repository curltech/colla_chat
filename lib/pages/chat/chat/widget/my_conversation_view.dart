import 'package:colla_chat/pages/chat/chat/widget/ui.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/common/image_widget.dart';
import 'content_msg.dart';

class MyConversationView extends StatefulWidget {
  final String imageUrl;
  final String title;
  final Map content;
  final Widget time;
  final bool isBorder;

  MyConversationView({
    required this.imageUrl,
    required this.title,
    required this.content,
    required this.time,
    this.isBorder = true,
  });

  @override
  _MyConversationViewState createState() => _MyConversationViewState();
}

class _MyConversationViewState extends State<MyConversationView> {
  @override
  Widget build(BuildContext context) {
    var row = Row(
      children: <Widget>[
        Space(width: mainSpace),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                widget.title ?? '',
                style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.normal),
              ),
              SizedBox(height: 2.0),
              ContentMsg(widget.content),
            ],
          ),
        ),
        Space(width: mainSpace),
        Column(
          children: [
            widget.time,
            Icon(Icons.flag, color: Colors.transparent),
          ],
        )
      ],
    );

    return Container(
      padding: EdgeInsets.only(left: 18.0),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ImageWidget(
              image: widget.imageUrl,
              height: 50.0,
              width: 50.0,
              fit: BoxFit.cover),
          Container(
            padding: EdgeInsets.only(right: 18.0, top: 12.0, bottom: 12.0),
            width: appDataProvider.size.width - 68,
            decoration: BoxDecoration(
              border: widget.isBorder
                  ? Border(
                      top: BorderSide(color: Colors.black, width: 0.2),
                    )
                  : null,
            ),
            child: row,
          )
        ],
      ),
    );
  }
}
