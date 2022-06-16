import 'package:colla_chat/provider/app_data.dart';
import 'package:flutter/material.dart';

import '../../../tool/util.dart';
import '../chat/widget/ui.dart';

codeDialog(BuildContext context, List items) {
  Widget item(item) {
    return Container(
      width: appDataProvider.size.width,
      decoration: BoxDecoration(
        border: item != '重置二维码'
            ? Border(
                bottom: BorderSide(color: Colors.black, width: 0.2),
              )
            : null,
      ),
      child: FlatButton(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15.0),
        onPressed: () {
          Navigator.of(context).pop();
          DialogUtil.showToast('$item正在开发中');
        },
        child: Text(item),
      ),
    );
  }

  showModalBottomSheet(
    context: context,
    builder: (context) {
      return Center(
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: <Widget>[
              Expanded(
                child: InkWell(
                  child: Container(),
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.all(
                  Radius.circular(10.0),
                ),
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: <Widget>[
                      Column(children: items.map(item).toList()),
                      HorizontalLine(color: Colors.grey, height: 10.0),
                      FlatButton(
                        padding: EdgeInsets.symmetric(vertical: 15.0),
                        color: Colors.white,
                        onPressed: () => Navigator.of(context).pop(),
                        child: Container(
                          width: appDataProvider.size.width,
                          alignment: Alignment.center,
                          child: Text('取消'),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      );
    },
  );
}
