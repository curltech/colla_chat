import 'package:colla_chat/pages/chat/chat/widget/ui.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:flutter/material.dart';

class TipVerifyInput extends StatefulWidget {
  final String? title;
  final String defStr;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final Color color;

  TipVerifyInput(
      {this.title,
      this.controller,
      this.defStr = '',
      this.focusNode,
      this.color = Colors.white});

  @override
  _VerifyInputState createState() => _VerifyInputState();
}

class _VerifyInputState extends State<TipVerifyInput> {
  @override
  void initState() {
    super.initState();
    widget.controller!.text = widget.defStr;
  }

  Widget contentBuild() {
    var view = [
      Expanded(
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          decoration: InputDecoration(border: InputBorder.none),
          onChanged: (text) {
            setState(() {});
          },
          onTap: () => setState(() {}),
          style: TextStyle(
            color: widget.focusNode!.hasFocus ? Colors.black : Colors.grey,
            textBaseline: TextBaseline.alphabetic,
          ),
        ),
      ),
      widget.controller!.text != ''
          ? Visibility(
              visible: widget.focusNode!.hasFocus,
              child: InkWell(
                child: Padding(
                  padding: EdgeInsets.all(2.0),
                  child: Image.asset('assets/images/ic_delete.webp'),
                ),
                onTap: () {
                  widget.controller!.text = '';
                  setState(() {});
                },
              ))
          : Container()
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Space(height: mainSpace),
        Expanded(
          child: Container(
            width: appDataProvider.size.width - 20,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: widget.focusNode!.hasFocus
                        ? Colors.green
                        : Colors.grey.withOpacity(0.5),
                    width: 0.5),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 5.0),
            alignment: Alignment.center,
            child: Row(children: view),
          ),
        ),
        Space(height: mainSpace),
        Text(
          widget.title ?? '',
          style:
              TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 15.0),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100.0,
      width: appDataProvider.size.width,
      color: widget.color,
      padding: EdgeInsets.all(10.0),
      margin: EdgeInsets.symmetric(horizontal: 10.0),
      child: contentBuild(),
    );
  }
}
