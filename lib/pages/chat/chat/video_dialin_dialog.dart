import 'package:colla_chat/widgets/common/image_widget.dart';
import 'package:flutter/material.dart';

///视频通话拨入的对话框
class VideoDialInDialog extends StatefulWidget {
  String peerId;
  String clientId;

  VideoDialInDialog({Key? key, required this.peerId, required this.clientId})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VideoDialInDialogState();
  }
}

class _VideoDialInDialogState extends State<VideoDialInDialog> {
  @override
  void initState() {
    super.initState();
  }

  _update() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 180,
        height: 80,
        child: Column(children: [
          Row(
            children: [
              const ImageWidget(image: ''),
              Column(children: const [Text('胡劲松'), Text('邀请你进行视频通话')])
            ],
          ),
          Row(children: [
            IconButton(
                onPressed: () {},
                icon: const Icon(Icons.cameraswitch),
                color: Colors.grey),
            const Text('切换语音通话'),
            IconButton(
                onPressed: () {},
                icon: const Icon(Icons.clear),
                color: Colors.red),
            IconButton(
                onPressed: () {},
                icon: const Icon(Icons.video_call),
                color: Colors.green)
          ])
        ]));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
