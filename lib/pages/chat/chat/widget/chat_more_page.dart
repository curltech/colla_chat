import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:wechat_flutter/im/message_handle.dart';
import 'package:wechat_flutter/im/send_handle.dart';
import 'package:wechat_flutter/pages/chat/shoot_page.dart';
import 'package:wechat_flutter/tools/utils/handle_util.dart';
import 'package:wechat_flutter/tools/wechat_flutter.dart';
import 'package:wechat_flutter/ui/card/more_item_card.dart';

class ChatMorePage extends StatefulWidget {
  final int index;
  final String id;
  final int type;
  final double keyboardHeight;

  ChatMorePage(
      {this.index = 0, this.id = '', this.type = 0, this.keyboardHeight = 0.0});

  @override
  _ChatMorePageState createState() => _ChatMorePageState();
}

class _ChatMorePageState extends State<ChatMorePage> {
  List data = [
    {"name": "相册", "icon": "assets/images/chat/ic_details_photo.webp"},
    {"name": "拍摄", "icon": "assets/images/chat/ic_details_camera.webp"},
    {"name": "视频通话", "icon": "assets/images/chat/ic_details_media.webp"},
    {"name": "位置", "icon": "assets/images/chat/ic_details_localtion.webp"},
    {"name": "红包", "icon": "assets/images/chat/ic_details_red.webp"},
    {"name": "转账", "icon": "assets/images/chat/ic_details_transfer.webp"},
    {"name": "语音输入", "icon": "assets/images/chat/ic_chat_voice.webp"},
    {"name": "我的收藏", "icon": "assets/images/chat/ic_details_favorite.webp"},
  ];

  List dataS = [
    {"name": "名片", "icon": "assets/images/chat/ic_details_card.webp"},
    {"name": "文件", "icon": "assets/images/chat/ic_details_file.webp"},
  ];

  List<AssetEntity> assets = <AssetEntity>[];

  action(String name) async {
    if (name == '相册') {
      AssetPicker.pickAssets(
        context,
        maxAssets: 9,
        pageSize: 320,
        pathThumbSize: 80,
        gridCount: 4,
        selectedAssets: assets,
        themeColor: Colors.green,
        // textDelegate: DefaultAssetsPickerTextDelegate(),
        routeCurve: Curves.easeIn,
        routeDuration: const Duration(milliseconds: 500),
      ).then((List<AssetEntity> result) {
        result.forEach((AssetEntity element) async {
          sendImageMsg(widget.id, widget.type, file: await element.file,
              callback: (v) {
            if (v == null) return;
            Notice.send(WeChatActions.msg(), v ?? '');
          });
          element.file;
        });
      });
    } else if (name == '拍摄') {
      try {
        List<CameraDescription> cameras;

        WidgetsFlutterBinding.ensureInitialized();
        cameras = await availableCameras();

        routePush(new ShootPage(cameras));
      } on CameraException catch (e) {
        logError(e.code, e.description);
      }
    } else if (name == '红包') {
      showToast(context, '测试发送红包消息');
      await sendTextMsg('${widget?.id}', widget.type, "测试发送红包消息");
    } else {
      showToast(context, '敬请期待$name');
    }
  }

  itemBuild(data) {
    return new Container(
      margin: EdgeInsets.all(20.0),
      padding: EdgeInsets.only(bottom: 20.0),
      child: new Wrap(
        runSpacing: 10.0,
        spacing: 10,
        children: List.generate(data.length, (index) {
          String name = data[index]['name'];
          String icon = data[index]['icon'];
          return new MoreItemCard(
            name: name,
            icon: icon,
            keyboardHeight: widget.keyboardHeight,
            onPressed: () => action(name),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.index == 0) {
      return itemBuild(data);
    } else {
      return itemBuild(dataS);
    }
  }
}
