import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:flutter/material.dart';

import '../../../widgets/common/image_widget.dart';

///视频通话拨出的对话框
class VideoDialOutDialog extends StatefulWidget {
  String peerId;
  String clientId;

  VideoDialOutDialog({Key? key, required this.peerId, required this.clientId})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VideoDialOutDialogState();
  }
}

class _VideoDialOutDialogState extends State<VideoDialOutDialog> {
  @override
  void initState() {
    super.initState();
  }

  _update() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        title: const Text(''),
        child: Stack(children: [
          Column(children: [
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
            ]),
            IconButton(
                onPressed: () {},
                icon: const Icon(Icons.call_end),
                color: Colors.red),
          ])
        ]));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
