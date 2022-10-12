import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/pages/chat/chat/chat_message_widget.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/tool/asset_util.dart';
import 'package:colla_chat/tool/camera_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../../widgets/data_bind/data_action_card.dart';

final List<ActionData> defaultActionData = [
  ActionData(
      label: 'picture',
      tooltip: 'take picture',
      icon: const Icon(Icons.camera)),
  ActionData(
      label: 'voice',
      tooltip: 'record voice',
      icon: const Icon(Icons.voice_chat)),
  ActionData(
    label: 'video chat',
    tooltip: 'invite video chat',
    icon: const Icon(Icons.video_call),
  ),
  ActionData(
      label: 'location',
      tooltip: 'geographical position',
      icon: const Icon(Icons.location_city)),
  ActionData(
      label: 'name card',
      tooltip: 'share name card',
      icon: const Icon(Icons.card_membership)),
  ActionData(
      label: 'file',
      tooltip: 'pick and send file',
      icon: const Icon(Icons.file_open)),
  ActionData(
      label: 'collection',
      tooltip: 'collection',
      icon: const Icon(Icons.collections)),
];

///非文本的其他多种格式输入面板，包括照片等
class MoreMessageInput extends StatefulWidget {
  final double height;
  final Future<void> Function(int index, String name, {String? value})?
      onAction;

  const MoreMessageInput({Key? key, this.height = 0.0, this.onAction})
      : super(key: key);

  @override
  State createState() => _MoreMessageInputState();
}

class _MoreMessageInputState extends State<MoreMessageInput> {
  List<ActionData> actionData = [];

  @override
  initState() {
    super.initState();
    var albumActionData = ActionData(
        label: 'album',
        tooltip: 'photo album',
        icon: const Icon(Icons.photo_album));
    if (platformParams.ios || platformParams.android || platformParams.macos) {
      actionData.add(albumActionData);
    }
    actionData.addAll(defaultActionData);
  }

  _onAction(int index, String name, {String? value}) async {
    if (widget.onAction != null) {
      widget.onAction!(index, name, value: value);
      return;
    }
    switch (name) {
      case 'album':
        _onActionAlbum();
        break;
      case 'picture':
        _onActionPicture();
        break;
      case 'video chat':
        _onActionVideoChat();
        break;
      case 'location':
        _onActionLocation();
        break;
      case 'name card':
        _onActionNameCard();
        break;
      case 'file':
        _onActionFile();
        break;
      case 'voice':
        _onActionVoice();
        break;
      case 'collection':
        _onActionCollection();
        break;
      default:
        break;
    }
  }

  _onActionVideoChat() {
    chatMessageController.index = 1;
  }

  _onActionAlbum() async {
    final List<AssetEntity>? result = await AssetUtil.pickAssets(
      context,
    );
    if (result != null && result.isNotEmpty) {
      List<Map<String, dynamic>> maps = await AssetUtil.toJsons(result);
      String json = JsonUtil.toJsonString(maps);
    }
  }

  _onActionPicture() async {
    AssetEntity? entry = await CameraUtil.pickFromCamera(context);
    if (entry != null) {
      Map<String, dynamic> map = await AssetUtil.toJson(entry);
      String json = JsonUtil.toJsonString(map);
    }
  }

  void _onActionLocation() {}

  Future<void> _onActionNameCard() async {
    String content = JsonUtil.toJsonString(myself.myselfPeer);
    PeerClient peerClient = PeerClient.fromJson(JsonUtil.toJson(content));
    content = JsonUtil.toJsonString(peerClient);
    await chatMessageController.sendText(
        message: content, contentType: ContentType.card);
  }

  Future<void> _onActionFile() async {
    List<String> filenames = await FileUtil.pickFiles();
    if (filenames.isNotEmpty) {
      List<int> data = await FileUtil.readFile(filenames[0]);
      String? mimeType = FileUtil.mimeType(filenames[0]);
      await chatMessageController.send(
          title: FileUtil.filename(filenames[0]),
          data: data,
          contentType: ContentType.file,
          mimeType: mimeType);
    }
  }

  void _onActionVoice() {}

  void _onActionCollection() {}

  Widget _buildActionCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(0.0),
      padding: const EdgeInsets.only(bottom: 0.0),
      child: DataActionCard(
        actions: actionData,
        height: widget.height,
        onPressed: _onAction,
        crossAxisCount: 4,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildActionCard(context);
  }
}
