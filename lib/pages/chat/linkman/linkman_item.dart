import 'package:flutter/material.dart';

import '../../../entity/chat/contact.dart';

class LinkmanItem extends StatefulWidget {
  const LinkmanItem({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _LinkmanItemState();
  }
}

class _LinkmanItemState extends State<LinkmanItem> {
  late final Linkman linkman;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(width: 0.5, color: Colors.cyan)),
        ),
        height: 64.0,
        child: TextButton(
          onPressed: () {},
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                '',
                width: 36.0,
                height: 36.0,
                scale: 0.9,
              ),
              Container(
                margin: const EdgeInsets.only(left: 12.0),
                child: Text(
                  linkman.name,
                  style: TextStyle(fontSize: 18.0, color: Colors.cyan),
                  maxLines: 1,
                ),
              )
            ],
          ),
        ));
  }
}
