import 'dart:typed_data';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_view_controller.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/pages/chat/me/collection/collection_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/me/collection/collection_list_widget.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/mobile_camera_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/group.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/service/chat/message_attachment.dart';
import 'package:colla_chat/tool/asset_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/entity_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/geolocator_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/transport/smsclient.dart';
import 'package:colla_chat/transport/webrtc/remote_video_render_controller.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

final List<ActionData> defaultActionData = [
  ActionData(
      label: 'DeleteTime',
      tooltip: 'Delete time',
      icon: const Icon(Icons.timer_sharp)),
  ActionData(
      label: 'Picture',
      tooltip: 'Take a picture',
      icon: const Icon(Icons.camera)),
  ActionData(
    label: 'Video chat',
    tooltip: 'Invite video chat',
    icon: const Icon(Icons.video_call),
  ),
  ActionData(
      label: 'Location',
      tooltip: 'Geographical position',
      icon: const Icon(Icons.location_on)),
  ActionData(
      label: 'Name card',
      tooltip: 'Share name card',
      icon: const Icon(Icons.card_membership)),
  ActionData(
      label: 'File',
      tooltip: 'Pick and send file',
      icon: const Icon(Icons.file_open)),
  ActionData(
      label: 'Collection',
      tooltip: 'Collection',
      icon: const Icon(Icons.collections)),
  ActionData(
      label: 'Receive sms',
      tooltip: 'Receive sms',
      icon: const Icon(Icons.sms)),
];

///非文本的其他多种格式输入面板，包括照片等
class MoreMessageInput extends StatefulWidget {
  final Future<void> Function(int index, String name, {String? value})?
      onAction;

  const MoreMessageInput({Key? key, this.onAction}) : super(key: key);

  @override
  State createState() => _MoreMessageInputState();
}

class _MoreMessageInputState extends State<MoreMessageInput> {
  List<ActionData> actionData = [];

  @override
  initState() {
    super.initState();
    if (platformParams.ios || platformParams.android || platformParams.macos) {
      var albumActionData = ActionData(
          label: 'Album',
          tooltip: 'Photo album',
          icon: const Icon(Icons.photo_album));
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
      case 'DeleteTime':
        _onActionDeleteTime();
        break;
      case 'Album':
        _onActionAlbum();
        break;
      case 'Picture':
        _onActionPicture();
        break;
      case 'Video chat':
        _onActionVideoChat();
        break;
      case 'Location':
        _onActionLocation(context);
        break;
      case 'Name card':
        _onActionNameCard();
        break;
      case 'File':
        _onActionFile();
        break;
      case 'Collection':
        _onActionCollection();
        break;
      case 'Receive sms':
        _onActionReceiveSms();
        break;
      default:
        break;
    }
  }

  ///阅后删除时间
  _onActionDeleteTime() async {
    int? deleteTime = await DialogUtil.showSelectDialog<int>(
        context: context,
        title: const CommonAutoSizeText('Select deleteTime'),
        items: [
          _buildOption(0),
          _buildOption(15),
          _buildOption(30),
          _buildOption(300),
          _buildOption(600),
          _buildOption(1800),
        ]);
    deleteTime = deleteTime ?? 0;
    chatMessageController.deleteTime = deleteTime;
  }

  Option _buildOption(int deleteTime) {
    return Option(
      '${deleteTime}s',
      deleteTime,
      checked: chatMessageController.deleteTime == deleteTime,
    );
  }

  ///视频通话
  _onActionVideoChat() {
    chatMessageController.current = null;
    videoConferenceRenderPool.conferenceId = null;
    indexWidgetProvider.push('video_chat');
  }

  ///相册
  _onActionAlbum() async {
    final List<AssetEntity>? result = await AssetUtil.pickAssets(
      context,
    );
    if (result != null && result.isNotEmpty) {
      Uint8List? data = await result[0].originBytes;
      // Uint8List? thumbnail =
      //     await ImageUtil.compressThumbnail(assetEntity: result[0]);
      String? mimeType = result[0].mimeType;
      String? title = result[0].title;
      if (title != null) {
        mimeType = FileUtil.mimeType(title);
      }
      mimeType = mimeType ?? 'text/plain';
      await chatMessageController.send(
          title: result[0].title,
          content: data,
          // thumbnail: thumbnail,
          contentType: ChatMessageContentType.image,
          mimeType: mimeType);
    }
  }

  ///拍照
  _onActionPicture() async {
    XFile? mediaFile;
    await DialogUtil.show<XFile?>(
        context: context,
        builder: (BuildContext context) {
          return MobileCameraWidget(
            onFile: (XFile file) {
              mediaFile = file;
            },
          );
        });
    if (mediaFile != null) {
      Uint8List data = await mediaFile!.readAsBytes();
      // Uint8List? thumbnail =
      //     await ImageUtil.compressThumbnail(xfile: mediaFile);
      String filename = mediaFile!.name;
      String? mimeType = mediaFile!.mimeType;
      mimeType = FileUtil.mimeType(filename);
      mimeType = mimeType ?? 'text/plain';
      ChatMessageContentType contentType = ChatMessageContentType.image;
      if (mimeType.endsWith('mp4')) {
        contentType = ChatMessageContentType.video;
        mimeType = ChatMessageMimeType.mp4.name;
      }
      await chatMessageController.send(
          title: filename,
          content: data,
          // thumbnail: thumbnail,
          contentType: contentType,
          mimeType: mimeType);
    }
  }

  ///位置
  void _onActionLocation(BuildContext context) async {
    Position position = await GeolocatorUtil.currentPosition();
    double latitude = position.latitude;
    double longitude = position.longitude;
    String? address;
    List<Widget>? rightWidgets = [
      IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.close,
            color: Colors.white,
          )),
    ];

    if (mounted) {
      Widget title = AppBarWidget.buildAppBar(
        context,
        title: CommonAutoSizeText(
          AppLocalizations.t('Location map'),
          style: const TextStyle(color: Colors.white),
        ),
        rightWidgets: rightWidgets,
      );
      await DialogUtil.show(
          context: context,
          builder: (BuildContext? context) {
            return Dialog(
                child: Column(children: [
              title,
              Expanded(
                  child: GeolocatorUtil.buildLocationPicker(
                      latitude: latitude,
                      longitude: longitude,
                      onPicked: (PickedData data) {
                        longitude = data.latLong.longitude;
                        latitude = data.latLong.latitude;
                        address = data.address;
                        Navigator.pop(context!);
                      }))
            ]));
          });
      if (address == null) {
        return;
      }
      LocationPosition locationPosition;
      if (address != null) {
        locationPosition = LocationPosition(
            longitude: longitude, latitude: latitude, address: address);
      } else {
        var json = position.toJson();
        locationPosition = LocationPosition.fromJson(json);
      }
      Map<String, dynamic> map = locationPosition.toJson();
      EntityUtil.removeNull(map);
      JsonUtil.toJsonString(map);
      String content = JsonUtil.toJsonString(map);
      await chatMessageController.sendText(
          message: content, contentType: ChatMessageContentType.location);
    }
  }

  ///名片
  Future<void> _onActionNameCard() async {
    await DialogUtil.show(
        context: context,
        builder: (BuildContext context) {
          return LinkmanGroupSearchWidget(
              onSelected: (List<String>? selected) async {
                if (selected != null && selected.isNotEmpty) {
                  Linkman? linkman =
                      await linkmanService.findCachedOneByPeerId(selected[0]);
                  if (linkman != null) {
                    String content = JsonUtil.toJsonString(linkman);
                    await chatMessageController.sendText(
                        message: content,
                        contentType: ChatMessageContentType.card,
                        mimeType: PartyType.linkman.name);
                  } else {
                    Group? group =
                        await groupService.findCachedOneByPeerId(selected[0]);
                    if (group != null) {
                      String content = JsonUtil.toJsonString(group);
                      await chatMessageController.sendText(
                          message: content,
                          contentType: ChatMessageContentType.card,
                          mimeType: PartyType.group.name);
                    }
                  }
                }
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              selected: const <String>[],
              selectType: SelectType.chipMultiSelect);
        });
  }

  ///文件
  Future<void> _onActionFile() async {
    List<XFile> xfiles = await FileUtil.pickFiles();
    if (xfiles.isNotEmpty) {
      XFile xfile = xfiles[0];
      Uint8List data = await xfile.readAsBytes();
      // Uint8List? thumbnail = await ImageUtil.compressThumbnail(xfile: xfile);
      String filename = xfile.name;
      String? mimeType = xfile.mimeType;
      mimeType = FileUtil.mimeType(filename);
      mimeType = mimeType ?? 'text/plain';
      await chatMessageController.send(
          title: filename,
          content: data,
          // thumbnail: thumbnail,
          contentType: ChatMessageContentType.file,
          mimeType: mimeType);
    }
  }

  ///选择收藏，并发送收藏的内容成为消息
  Future<void> _onActionCollection() async {
    if (mounted) {
      await DialogUtil.show(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              child: Column(children: [
                AppBarWidget.buildAppBar(
                  context,
                  title: CommonAutoSizeText(
                      AppLocalizations.t('Select collect message')),
                ),
                Expanded(child: CollectionListWidget())
              ]),
            );
          });
      var collection = collectionChatMessageController.current;
      if (collection != null) {
        Uint8List? thumbnail;
        if (collection.thumbnail != null) {
          thumbnail = CryptoUtil.decodeBase64(collection.thumbnail!);
        }
        ChatMessageContentType? contentType = StringUtil.enumFromString(
            ChatMessageContentType.values, collection.contentType);
        contentType ??= ChatMessageContentType.text;
        // ChatMessageType? messageType = StringUtil.enumFromString(
        //     ChatMessageType.values, collection.messageType);
        // messageType ??= ChatMessageType.chat;
        ChatMessageSubType? subMessageType = StringUtil.enumFromString(
            ChatMessageSubType.values, collection.subMessageType);
        subMessageType ??= ChatMessageSubType.chat;
        Uint8List? content;
        if (collection.content == null) {
          content = await messageAttachmentService.findContent(
              collection.messageId!, collection.title);
        } else {
          content = CryptoUtil.decodeBase64(collection.content!);
        }
        chatMessageController.send(
          title: collection.title,
          content: content,
          thumbnail: thumbnail,
          contentType: contentType,
          mimeType: collection.mimeType,
          messageType: ChatMessageType.chat,
          subMessageType: subMessageType,
        );
      }
    }
  }

  ///接收到加密短信
  _onActionReceiveSms() async {
    TextEditingController controller = TextEditingController();
    await DialogUtil.show(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
              child: Column(children: [
            CommonAutoSizeTextFormField(
              minLines: 4,
              maxLines: 6,
              controller: controller,
            ),
            ButtonBar(children: [
              IconButton(
                  onPressed: () {
                    controller.text = '';
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.cancel_outlined,
                    color: Colors.grey,
                  )),
              IconButton(
                  onPressed: () {
                    Navigator.pop(context, controller.text);
                  },
                  icon: Icon(
                    Icons.check,
                    color: myself.primary,
                  )),
            ]),
          ]));
        });
    ChatSummary? chatSummary = chatMessageController.chatSummary;
    if (chatSummary == null) {
      return;
    }
    Linkman? linkman =
        await linkmanService.findCachedOneByPeerId(chatSummary.peerId!);
    if (linkman != null && controller.text.isNotEmpty) {
      smsClient.receiveChatMessage(linkman, controller.text);
    }
  }

  Widget _buildActionCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(0.0),
      padding: const EdgeInsets.only(bottom: 0.0),
      child: DataActionCard(
        actions: actionData,
        height: chatMessageViewController.moreMessageInputHeight,
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
