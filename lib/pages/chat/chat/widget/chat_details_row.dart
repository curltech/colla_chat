import 'package:flutter/material.dart';

import 'chat_voice.dart';

class ChatDetailsRow extends StatefulWidget {
  final GestureTapCallback voiceOnTap;
  final bool isVoice;
  final LayoutWidgetBuilder edit;
  final VoidCallback onEmojio;
  final Widget more;
  final String id;
  final int type;

  ChatDetailsRow({
    required this.voiceOnTap,
    required this.isVoice,
    required this.edit,
    required this.more,
    required this.id,
    required this.type,
    required this.onEmojio,
  });

  ChatDetailsRowState createState() => ChatDetailsRowState();
}

class ChatDetailsRowState extends State<ChatDetailsRow> {
  late String path;

  @override
  void initState() {
    super.initState();

    // Notice.addListener(WeChatActions.voiceImg(), (v) {
    //   if (!v) return;
    //   if (!strNoEmpty(path)) return;
    //   sendSoundMessages(
    //     widget.id,
    //     path,
    //     2,
    //     widget.type,
    //     (value) => Notice.send(WeChatActions.msg(), v ?? ''),
    //   );
    // });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        height: 50.0,
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border(
            top: BorderSide(color: Colors.black, width: 1),
            bottom: BorderSide(color: Colors.black, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            InkWell(
              child: Image.asset('assets/images/chat/ic_voice.webp',
                  width: 25, color: Colors.black),
              onTap: () {
                if (widget.voiceOnTap != null) {
                  widget.voiceOnTap();
                }
              },
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(
                    top: 7.0, bottom: 7.0, left: 8.0, right: 8.0),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5.0)),
                child: widget.isVoice
                    ? ChatVoice(
                        voiceFile: (path) {
                          setState(() => this.path = path);
                        },
                      )
                    : LayoutBuilder(builder: widget.edit),
              ),
            ),
            InkWell(
              child: Image.asset('assets/images/chat/ic_Emotion.webp',
                  width: 30, fit: BoxFit.cover),
              onTap: () {
                widget.onEmojio();
              },
            ),
            widget.more,
          ],
        ),
      ),
      onTap: () {},
    );
  }
}
