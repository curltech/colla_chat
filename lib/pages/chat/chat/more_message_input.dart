import 'dart:typed_data';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_view_controller.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/pages/chat/me/collection/collection_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/me/collection/collection_list_widget.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/macos_camera_widget.dart';
import 'package:colla_chat/plugin/mobile_camera_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/conference.dart';
import 'package:colla_chat/service/chat/message_attachment.dart';
import 'package:colla_chat/tool/asset_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/entity_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/geolocator_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/loading_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/transport/webrtc/livekit/sfu_conference_client.dart';
import 'package:colla_chat/transport/webrtc/p2p/p2p_conference_client.dart';
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

///非文本的其他多种格式输入面板，包括照片等
class MoreMessageInput extends StatefulWidget {
  final Future<void> Function(int index, String name, {String? value})?
      onAction;

  const MoreMessageInput({Key? key, this.onAction}) : super(key: key);

  @override
  State createState() => _MoreMessageInputState();
}

class _MoreMessageInputState extends State<MoreMessageInput> {
  @override
  initState() {
    super.initState();
  }

  Future<List<ActionData>> _buildActionData() async {
    List<ActionData> actionData = [];
    if (platformParams.mobile) {
      var albumActionData = ActionData(
          label: 'Album',
          tooltip: 'Photo album',
          icon: const Icon(Icons.photo_album));
      actionData.add(albumActionData);
    }
    actionData.addAll([
      ActionData(
          label: 'DeleteTime',
          tooltip: 'Delete time',
          icon: const Icon(Icons.timer_sharp)),
      ActionData(
          label: 'Picture',
          tooltip: 'Take a picture',
          icon: const Icon(Icons.camera))
    ]);
    ChatSummary? chatSummary = chatMessageController.chatSummary;
    String? partyType = chatSummary?.partyType;
    if (partyType == PartyType.conference.name) {
      /// 会议模式下会议是否有效
      Conference? conference = await conferenceService
          .findCachedOneByConferenceId(chatSummary!.messageId!);
      if (conference != null) {
        bool valid = conferenceService.isValid(conference);
        if (valid) {
          if (conference.sfu) {
            actionData.add(ActionData(
              label: 'Sfu video chat',
              tooltip: 'Invite video chat',
              icon: const Icon(Icons.missed_video_call_outlined),
            ));
          } else {
            actionData.add(ActionData(
              label: 'Video chat',
              tooltip: 'Invite video chat',
              icon: const Icon(Icons.video_call),
            ));
          }
        }
      }
    } else {
      actionData.add(ActionData(
        label: 'Sfu video chat',
        tooltip: 'Invite video chat',
        icon: const Icon(Icons.missed_video_call_outlined),
      ));
      actionData.add(ActionData(
        label: 'Video chat',
        tooltip: 'Invite video chat',
        icon: const Icon(Icons.video_call),
      ));
    }
    actionData.addAll([
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
    ]);

    return actionData;
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
      case 'Sfu video chat':
        _onActionSfuVideoChat();
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
      default:
        break;
    }
  }

  ///阅后删除时间
  _onActionDeleteTime() async {
    int? deleteTime = await DialogUtil.showSelectDialog<int>(
        context: context,
        title: CommonAutoSizeText(AppLocalizations.t('Select delete time')),
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
    return Option('${deleteTime}s', deleteTime,
        checked: chatMessageController.deleteTime == deleteTime, hint: '');
  }

  ///视频通话
  _onActionVideoChat() async {
    ChatSummary? chatSummary = chatMessageController.chatSummary;
    String? partyType = chatSummary?.partyType;
    if (partyType == PartyType.linkman.name) {
      chatMessageController.current = null;
      p2pConferenceClientPool.conferenceId = null;
      indexWidgetProvider.push('video_chat');
    } else if (partyType == PartyType.group.name) {
      chatMessageController.current = null;
      p2pConferenceClientPool.conferenceId = null;
      indexWidgetProvider.push('video_chat');
    } else if (partyType == PartyType.conference.name) {
      if (chatSummary != null) {
        String groupId = chatSummary.peerId!;
        ChatMessage? chatMessage =
            await chatMessageService.findVideoChatMessage(groupId: groupId);
        if (chatMessage != null) {
          await p2pConferenceClientPool.createConferenceClient(
              chatSummary: chatSummary, chatMessage);
          indexWidgetProvider.push('video_chat');
        }
      }
    }
  }

  _onActionSfuVideoChat() async {
    ChatSummary? chatSummary = chatMessageController.chatSummary;
    String? partyType = chatSummary?.partyType;
    if (partyType == PartyType.linkman.name) {
      chatMessageController.current = null;
      liveKitConferenceClientPool.conferenceId = null;
      indexWidgetProvider.push('sfu_video_chat');
    } else if (partyType == PartyType.group.name) {
      chatMessageController.current = null;
      liveKitConferenceClientPool.conferenceId = null;
      indexWidgetProvider.push('sfu_video_chat');
    } else if (partyType == PartyType.conference.name) {
      if (chatSummary != null) {
        String groupId = chatSummary.peerId!;
        ChatMessage? chatMessage =
            await chatMessageService.findVideoChatMessage(groupId: groupId);
        if (chatMessage != null) {
          LiveKitConferenceClient? conferenceClient =
              await liveKitConferenceClientPool.createConferenceClient(
                  chatSummary: chatSummary, chatMessage);
          if (conferenceClient != null) {
            indexWidgetProvider.push('sfu_video_chat');
          }
        }
      }
    }
  }

  ///相册
  _onActionAlbum() async {
    final List<AssetEntity>? result = await AssetUtil.pickAssets(
      context,
    );
    if (result != null && result.isNotEmpty) {
      Uint8List? data = await result[0].originBytes;
      String? mimeType = await result[0].mimeTypeAsync;
      String title = await result[0].titleAsync;
      mimeType = mimeType ?? FileUtil.mimeType(title);
      String mainMimeType = FileUtil.mainMimeType(mimeType!);
      ChatMessageContentType? contentType = StringUtil.enumFromString(
          ChatMessageContentType.values, mainMimeType);
      contentType ??= ChatMessageContentType.image;
      await chatMessageController.send(
          title: title,
          content: data,
          contentType: contentType,
          mimeType: mimeType);
    }
  }

  ///拍照
  _onActionPicture() async {
    Uint8List? data;
    String? filename;
    String? mimeType = ChatMessageMimeType.jpg.name;
    ChatMessageContentType contentType = ChatMessageContentType.image;
    if (platformParams.linux) {
      List<Uint8List>? bytes = await FileUtil.fullSelectBytes(
        context: context,
        file: true,
        image: true,
        imageCamera: true,
        videoCamera: true,
      );
      if (bytes != null && bytes.isNotEmpty) {
        data = bytes.first;
      }
    } else if (platformParams.macos) {
      await DialogUtil.show<String?>(
          context: context,
          builder: (BuildContext context) {
            return Center(child: MacosCameraWidget(
              onData: (Uint8List bytes, String type) {
                data = bytes;
                mimeType = type;
              },
            ));
          });
    } else {
      XFile? mediaFile;
      await DialogUtil.show<XFile?>(
          context: context,
          builder: (BuildContext context) {
            return Center(child: MobileCameraWidget(
              onFile: (XFile file) {
                mediaFile = file;
              },
            ));
          });
      if (mediaFile != null) {
        data = await mediaFile!.readAsBytes();
        filename = mediaFile!.name;
        mimeType = FileUtil.mimeType(filename);
      }
    }

    if (mimeType != null && mimeType!.endsWith('mp4')) {
      contentType = ChatMessageContentType.video;
      mimeType = ChatMessageMimeType.mp4.name;
    }
    if (data != null) {
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
            return Card(
                elevation: 0.0,
                margin: EdgeInsets.zero,
                shape: const ContinuousRectangleBorder(),
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
                  await _sendNameCard(selected);
                }
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              includeGroup: false,
              selected: const <String>[],
              selectType: SelectType.chipMultiSelect);
        });
  }

  ///发送linkman的消息
  Future<void> _sendNameCard(List<String> peerIds) async {
    await chatMessageController.sendNameCard(peerIds);
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
        String? thumbnail = collection.thumbnail!;
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

  Widget _buildActionCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(0.0),
      padding: const EdgeInsets.only(bottom: 0.0),
      child: FutureBuilder(
        future: _buildActionData(),
        builder:
            (BuildContext context, AsyncSnapshot<List<ActionData>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            List<ActionData>? actionData = snapshot.data;
            if (actionData != null) {
              return DataActionCard(
                actions: actionData,
                width: appDataProvider.secondaryBodyWidth * 0.9,
                height: chatMessageViewController.moreMessageInputHeight,
                onPressed: _onAction,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                crossAxisCount: 4,
              );
            }
          }

          return LoadingUtil.buildLoadingIndicator();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildActionCard(context);
  }
}
