import 'package:colla_chat/pages/chat/chat/widget/ui.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:flutter/material.dart';

class MoreItemCard extends StatelessWidget {
  final String name, icon;
  final VoidCallback? onPressed;
  final double? keyboardHeight;

  MoreItemCard(
      {required this.name,
      required this.icon,
      this.onPressed,
      this.keyboardHeight});

  @override
  Widget build(BuildContext context) {
    double? _margin =
        keyboardHeight != null && keyboardHeight != 0.0 ? keyboardHeight : 0.0;
    double _top = _margin != 0.0 ? _margin! / 10 : 20.0;

    return Container(
      padding: EdgeInsets.only(top: _top, bottom: 5.0),
      width: (appDataProvider.size.width - 70) / 4,
      child: Column(
        children: <Widget>[
          Container(
            width: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(
                Radius.circular(10.0),
              ),
            ),
            child: FlatButton(
              onPressed: () {
                if (onPressed != null) {
                  onPressed!();
                }
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(10.0),
                ),
              ),
              padding: EdgeInsets.all(0),
              color: Colors.white,
              child: Container(
                width: 50.0,
                child: Image.asset(icon, fit: BoxFit.cover),
              ),
            ),
          ),
          Space(height: mainSpace / 2),
          Text(
            name ?? '',
            style: TextStyle(color: Colors.black, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
