import 'dart:async';
import 'dart:typed_data';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/message/audio_message.dart';
import 'package:colla_chat/pages/chat/chat/message/cancel_message.dart';
import 'package:colla_chat/pages/chat/chat/message/chat_receipt_message.dart';
import 'package:colla_chat/pages/chat/chat/message/common_message.dart';
import 'package:colla_chat/pages/chat/chat/message/extended_text_message.dart';
import 'package:colla_chat/pages/chat/chat/message/file_message.dart';
import 'package:colla_chat/pages/chat/chat/message/group/add_group_member_message.dart';
import 'package:colla_chat/pages/chat/chat/message/group/add_group_message.dart';
import 'package:colla_chat/pages/chat/chat/message/group/dismiss_group_message.dart';
import 'package:colla_chat/pages/chat/chat/message/group/modify_group_message.dart';
import 'package:colla_chat/pages/chat/chat/message/group/remove_group_member_message.dart';
import 'package:colla_chat/pages/chat/chat/message/image_message.dart';
import 'package:colla_chat/pages/chat/chat/message/location_message.dart';
import 'package:colla_chat/pages/chat/chat/message/name_card_message.dart';
import 'package:colla_chat/pages/chat/chat/message/request_add_friend_message.dart';
import 'package:colla_chat/pages/chat/chat/message/rich_text_message.dart';
import 'package:colla_chat/pages/chat/chat/message/url_message.dart';
import 'package:colla_chat/pages/chat/chat/message/video_chat_message.dart';
import 'package:colla_chat/pages/chat/chat/message/video_message.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/message_attachment.dart';
import 'package:colla_chat/tool/clipboard_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/geolocator_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/menu_util.dart';
import 'package:colla_chat/tool/pdf_util.dart';
import 'package:colla_chat/tool/smart_dialog_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';

final List<ActionData> messagePopActionData = [
  ActionData(
      label: 'Delete',
      tooltip: 'Delete message',
      icon: const Icon(Icons.delete)),
  ActionData(
      label: 'Cancel',
      tooltip: 'Cancel message',
      icon: const Icon(Icons.cancel)),
  ActionData(
    label: 'Refer',
    tooltip: 'Refer message',
    icon: const Icon(Icons.format_quote),
  ),
  ActionData(
    label: 'Copy',
    tooltip: 'Copy message',
    icon: const Icon(Icons.copy),
  ),
  ActionData(
      label: 'Forward',
      tooltip: 'Forward message',
      icon: const Icon(Icons.forward)),
  ActionData(
      label: 'Collect',
      tooltip: 'Collect message',
      icon: const Icon(Icons.collections)),
];

///每种消息的显示组件
class MessageWidget {
  final ChatMessage chatMessage;
  final bool fullScreen;
  final int index;
  bool? _isMyself;
  bool? _isSystem;

  MessageWidget(this.chatMessage, this.index, {this.fullScreen = false});

  bool get isMyself {
    if (_isMyself != null) {
      return _isMyself!;
    }
    var direct = chatMessage.direct;
    var senderPeerId = chatMessage.senderPeerId;
    var peerId = myself.peerId;
    if (direct == ChatDirect.send.name &&
        (senderPeerId == null || senderPeerId == peerId)) {
      _isMyself = true;
    } else {
      _isMyself = false;
    }
    return _isMyself!;
  }

  bool get isSystem {
    if (_isSystem != null) {
      return _isSystem!;
    }
    var messageType = chatMessage.messageType;
    if (messageType == ChatMessageType.system.name) {
      _isSystem = true;
    } else {
      _isSystem = false;
    }
    return _isSystem!;
  }

  ///消息体：扩展文本，图像，声音，视频，页面，复合文本，文件，名片，位置，收藏等种类
  ///每种消息体一个类
  Future<Widget> buildMessageBody(BuildContext context) async {
    ChatMessageContentType? contentType;
    if (chatMessage.contentType != null) {
      contentType = StringUtil.enumFromString(
          ChatMessageContentType.values, chatMessage.contentType!);
    }
    contentType = contentType ?? ChatMessageContentType.text;
    ChatMessageSubType? subMessageType;
    subMessageType = StringUtil.enumFromString(
        ChatMessageSubType.values, chatMessage.subMessageType);
    Widget body;
    if (subMessageType == ChatMessageSubType.chat) {
      switch (contentType) {
        case ChatMessageContentType.text:
          body = buildExtendedTextMessageWidget(context);
          break;
        case ChatMessageContentType.audio:
          body = buildAudioMessageWidget(context);
          break;
        case ChatMessageContentType.video:
          body = buildVideoMessageWidget(context);
          break;
        case ChatMessageContentType.file:
          body = await buildFileMessageWidget(context);
          break;
        case ChatMessageContentType.image:
          body = buildImageMessageWidget(context);
          break;
        case ChatMessageContentType.card:
          body = buildNameCardMessageWidget(context);
          break;
        case ChatMessageContentType.rich:
          body = buildRichTextMessageWidget(context);
          break;
        case ChatMessageContentType.link:
          body = buildUrlMessageWidget(context);
          break;
        case ChatMessageContentType.location:
          body = buildLocationMessageWidget(context);
          break;
        default:
          body = Container();
          break;
      }
    } else if (subMessageType == ChatMessageSubType.videoChat) {
      body = buildVideoChatMessageWidget(context);
    } else if (subMessageType == ChatMessageSubType.addFriend) {
      body = buildRequestAddFriendWidget(context, subMessageType!);
    } else if (subMessageType == ChatMessageSubType.addGroup) {
      body = buildAddGroupWidget(context, subMessageType!);
    } else if (subMessageType == ChatMessageSubType.modifyGroup) {
      body = buildModifyGroupWidget(context, subMessageType!);
    } else if (subMessageType == ChatMessageSubType.dismissGroup) {
      body = buildDismissGroupWidget(context, subMessageType!);
    } else if (subMessageType == ChatMessageSubType.addGroupMember) {
      body = buildAddGroupMemberWidget(context, subMessageType!);
    } else if (subMessageType == ChatMessageSubType.removeGroupMember) {
      body = buildRemoveGroupMemberWidget(context, subMessageType!);
    } else if (subMessageType == ChatMessageSubType.cancel) {
      body = buildCancelMessageWidget(context, chatMessage.content!);
    } else if (subMessageType == ChatMessageSubType.chatReceipt) {
      body = buildChatReceiptMessageWidget(context, chatMessage);
    } else {
      body = Container();
    }

    ///双击全屏
    if (!fullScreen) {
      body = InkWell(
          onDoubleTap: () {
            chatMessageController.currentIndex = index;
            indexWidgetProvider.push('full_screen');
          },
          child: body);

      ///长按弹出式菜单
      CustomPopupMenuController menuController = CustomPopupMenuController();
      body = MenuUtil.buildPopupMenu(
          child: body,
          controller: menuController,
          menuBuilder: () {
            return Card(
                child: DataActionCard(
                    onPressed: (int index, String label, {String? value}) {
                      menuController.hideMenu();
                      _onMessagePopAction(context, index, label, value: value);
                    },
                    crossAxisCount: 4,
                    actions: messagePopActionData,
                    height: 140,
                    width: 320,
                    size: 20));
          },
          pressType: PressType.longPress);
    }

    return body;
  }

  _onMessagePopAction(BuildContext context, int index, String label,
      {String? value}) async {
    switch (label) {
      case 'Delete':
        chatMessageService
            .remove(where: 'messageId=?', whereArgs: [chatMessage.messageId!]);
        chatMessageController.delete(index: this.index);
        break;
      case 'Cancel':
        String? messageId = chatMessage.messageId;
        if (messageId != null) {
          await chatMessageController.sendText(
            message: messageId,
            subMessageType: ChatMessageSubType.cancel,
          );
          chatMessageService.delete(
              where: 'messageId=?', whereArgs: [chatMessage.messageId!]);
          chatMessageController.delete(index: this.index);
        }
        break;
      case 'Copy':
        String? content = chatMessage.content;
        String? contentType = chatMessage.contentType;
        if (contentType == ChatMessageContentType.text.name &&
            content != null) {
          content = chatMessageService.recoverContent(content);
          await ClipboardUtil.copy(content);
        }
        break;
      case 'Forward':
        List<String> selects = [];
        await DialogUtil.show(
            builder: (BuildContext context) {
              return LinkmanGroupSearchWidget(
                selectType: SelectType.chipMultiSelect,
                onSelected: (List<String>? selected) {
                  if (selected != null) {
                    selects = selected;
                  }
                },
                selected: const [],
              );
            },
            context: context);
        for (var selected in selects) {
          await chatMessageService.forward(chatMessage, selected);
        }
        break;
      case 'Collect':
        break;
      case 'Refer':
        String? messageId = chatMessage.messageId;
        chatMessageController.parentMessageId = messageId;
        break;
      default:
    }
  }

  ExtendedTextMessage buildExtendedTextMessageWidget(BuildContext context) {
    String? content = chatMessage.content;
    if (content != null) {
      content = chatMessageService.recoverContent(content);
    }
    return ExtendedTextMessage(
      key: UniqueKey(),
      isMyself: isMyself,
      content: content!,
    );
  }

  RequestAddFriendMessage buildRequestAddFriendWidget(
      BuildContext context, ChatMessageSubType subMessageType) {
    var senderPeerId = chatMessage.senderPeerId!;
    return RequestAddFriendMessage(
      key: UniqueKey(),
      isMyself: isMyself,
      senderPeerId: senderPeerId,
    );
  }

  AddGroupMessage buildAddGroupWidget(
      BuildContext context, ChatMessageSubType subMessageType) {
    String? content = chatMessage.content;
    if (content != null) {
      content = chatMessageService.recoverContent(content);
    }
    return AddGroupMessage(
      key: UniqueKey(),
      isMyself: isMyself,
      content: content!,
    );
  }

  DismissGroupMessage buildDismissGroupWidget(
      BuildContext context, ChatMessageSubType subMessageType) {
    String? content = chatMessage.content;
    if (content != null) {
      content = chatMessageService.recoverContent(content);
    }
    return DismissGroupMessage(
      key: UniqueKey(),
      isMyself: isMyself,
      content: content!,
    );
  }

  ModifyGroupMessage buildModifyGroupWidget(
      BuildContext context, ChatMessageSubType subMessageType) {
    String? content = chatMessage.content;
    if (content != null) {
      content = chatMessageService.recoverContent(content);
    }
    return ModifyGroupMessage(
      key: UniqueKey(),
      isMyself: isMyself,
      content: content!,
    );
  }

  AddGroupMemberMessage buildAddGroupMemberWidget(
      BuildContext context, ChatMessageSubType subMessageType) {
    String? content = chatMessage.content;
    if (content != null) {
      content = chatMessageService.recoverContent(content);
    }
    return AddGroupMemberMessage(
      key: UniqueKey(),
      isMyself: isMyself,
      content: content!,
    );
  }

  RemoveGroupMemberMessage buildRemoveGroupMemberWidget(
      BuildContext context, ChatMessageSubType subMessageType) {
    String? content = chatMessage.content;
    if (content != null) {
      content = chatMessageService.recoverContent(content);
    }
    return RemoveGroupMemberMessage(
      key: UniqueKey(),
      isMyself: isMyself,
      content: content!,
    );
  }

  /// 非全屏场景下是简单的文件显示
  /// 全屏场景下是根据文件的类型展示
  Future<Widget> buildFileMessageWidget(BuildContext context) async {
    String? messageId = chatMessage.messageId;
    String? title = chatMessage.title;
    String? extension;
    if (title != null) {
      extension = FileUtil.extension(title);
    }
    String? mimeType = chatMessage.mimeType;
    mimeType = mimeType ?? 'text/plain';
    Widget fileMessage = FileMessage(
      key: UniqueKey(),
      messageId: messageId!,
      isMyself: isMyself,
      title: title!,
      mimeType: mimeType,
    );
    if (!fullScreen) {
      return fileMessage;
    }
    if (mimeType.endsWith(ChatMessageMimeType.jpeg.name) ||
        mimeType.endsWith(ChatMessageMimeType.jpg.name) ||
        mimeType.endsWith(ChatMessageMimeType.png.name) ||
        mimeType.endsWith(ChatMessageMimeType.webp.name) ||
        mimeType.endsWith(ChatMessageMimeType.bmp.name) ||
        mimeType.endsWith(ChatMessageMimeType.gif.name)) {
      return buildImageMessageWidget(context);
    }
    if (mimeType.startsWith(ChatMessageContentType.audio.name)) {
      return buildAudioMessageWidget(context);
    }
    if (mimeType.endsWith(ChatMessageMimeType.midi.name) ||
        mimeType.endsWith(ChatMessageMimeType.wav.name) ||
        mimeType.endsWith(ChatMessageMimeType.mp3.name)) {
      return buildAudioMessageWidget(context);
    }
    if (mimeType.startsWith(ChatMessageContentType.video.name)) {
      return buildVideoMessageWidget(context);
    }
    if (mimeType.endsWith(ChatMessageMimeType.mpeg.name) ||
        mimeType.endsWith(ChatMessageMimeType.ogg.name) ||
        mimeType.endsWith(ChatMessageMimeType.m4a.name) ||
        mimeType.endsWith(ChatMessageMimeType.mp4.name) ||
        mimeType.endsWith(ChatMessageMimeType.mov.name)) {
      return buildVideoMessageWidget(context);
    }
    if (mimeType == 'application/pdf') {
      return buildPdfMessageWidget(context);
    }
    if (extension == 'docx' ||
        extension == 'doc' ||
        extension == 'xlsx' ||
        extension == 'xls' ||
        extension == 'pptx' ||
        extension == 'ppt') {
      return await buildOfficeMessageWidget(context);
    }
    return fileMessage;
  }

  VideoChatMessage buildVideoChatMessageWidget(BuildContext context) {
    return VideoChatMessage(
      key: UniqueKey(),
      isMyself: isMyself,
      fullScreen: fullScreen,
      chatMessage: chatMessage,
    );
  }

  CancelMessage buildCancelMessageWidget(BuildContext context, String content) {
    return CancelMessage(
      key: UniqueKey(),
      isMyself: isMyself,
      content: content,
    );
  }

  ChatReceiptMessage buildChatReceiptMessageWidget(
      BuildContext context, ChatMessage chatMessage) {
    return ChatReceiptMessage(
      key: UniqueKey(),
      isMyself: isMyself,
      chatMessage: chatMessage,
    );
  }

  UrlMessage buildUrlMessageWidget(BuildContext context) {
    String? title = chatMessage.title;
    return UrlMessage(
      key: UniqueKey(),
      url: title!,
      isMyself: isMyself,
    );
  }

  RichTextMessage buildRichTextMessageWidget(BuildContext context) {
    String? messageId = chatMessage.messageId;
    String? title = chatMessage.title;
    return RichTextMessage(
      key: UniqueKey(),
      messageId: messageId!,
      isMyself: isMyself,
    );
  }

  NameCardMessage buildNameCardMessageWidget(BuildContext context) {
    String? content = chatMessage.content;
    if (content != null) {
      content = chatMessageService.recoverContent(content);
    }
    String? mimeType = chatMessage.mimeType;
    return NameCardMessage(
      key: UniqueKey(),
      content: content!,
      isMyself: isMyself,
      fullScreen: fullScreen,
      mimeType: mimeType,
    );
  }

  LocationMessage buildLocationMessageWidget(BuildContext context) {
    String? content = chatMessage.content;
    List<int>? data;
    if (content != null) {
      content = chatMessageService.recoverContent(content);
    }
    String? thumbnail = chatMessage.thumbnail;
    return LocationMessage(
      key: UniqueKey(),
      content: content!,
      isMyself: isMyself,
      thumbnail: thumbnail,
      fullScreen: fullScreen,
    );
  }

  ///打开地图
  openLocationMap(BuildContext context) async {
    String? content = chatMessage.content;
    if (content == null) {
      return;
    }
    content = chatMessageService.recoverContent(content);
    Map<String, dynamic> map = JsonUtil.toJson(content);
    LocationPosition locationPosition = LocationPosition.fromJson(map);
    var latitude = locationPosition.latitude; //纬度
    var longitude = locationPosition.longitude; //经度
    if (platformParams.desktop) {
      await SmartDialogUtil.show(
          context: context,
          title: AppBarWidget.buildTitleBar(
              title: CommonAutoSizeText(AppLocalizations.t('Location map'))),
          builder: (BuildContext? context) {
            return GeolocatorUtil.buildLocationPicker(
                latitude: latitude,
                longitude: longitude,
                onPicked: (PickedData data) {});
          });
      // GeolocatorUtil.launchCoordinates(latitude, longitude);
    } else {
      await SmartDialogUtil.show(
          context: context,
          title: AppBarWidget.buildTitleBar(
              title: CommonAutoSizeText(AppLocalizations.t('Location map'))),
          builder: (BuildContext? context) {
            return GeolocatorUtil.buildPlatformMap(
                latitude: latitude, longitude: longitude);
          });
      // DialogUtil.show(
      //     context: context,
      //     builder: (BuildContext context) {
      //       return GeolocatorUtil.buildPlatformMap(
      //         latitude: latitude,
      //         longitude: longitude,
      //       );
      //     });
      // GeolocatorUtil.launchCoordinates(latitude, longitude);
      // GeolocatorUtil.mapLauncher(
      //     latitude: latitude, longitude: longitude, title: '');
    }
  }

  /// 非全屏场景下是缩略图
  /// 全屏下是原图
  ImageMessage buildImageMessageWidget(BuildContext context) {
    String? messageId = chatMessage.messageId;
    String? title = chatMessage.title;
    String? thumbnail = chatMessage.thumbnail;
    String? mimeType = chatMessage.mimeType;
    return ImageMessage(
      key: UniqueKey(),
      messageId: messageId!,
      title: title,
      thumbnail: thumbnail,
      isMyself: isMyself,
      fullScreen: fullScreen,
    );
  }

  /// 非全屏场景下是视频缩略图
  /// 全屏下是原始播放界面
  VideoMessage buildVideoMessageWidget(BuildContext context) {
    int? id = chatMessage.id;
    String? messageId = chatMessage.messageId;
    String? title = chatMessage.title;
    String? thumbnail = chatMessage.thumbnail;
    return VideoMessage(
      key: UniqueKey(),
      id: id!,
      messageId: messageId!,
      title: title,
      isMyself: isMyself,
      thumbnail: thumbnail,
    );
  }

  /// 非全屏场景下是音频简单播放界面
  /// 全屏下是原始播放界面
  AudioMessage buildAudioMessageWidget(BuildContext context) {
    int? id = chatMessage.id;
    String? messageId = chatMessage.messageId;
    String? title = chatMessage.title;
    return AudioMessage(
      key: UniqueKey(),
      id: id!,
      messageId: messageId!,
      title: title,
      isMyself: isMyself,
    );
  }

  /// 全屏场景下pdf展示，是文件消息的子类型
  Future<Widget> buildPdfMessageWidget(BuildContext context) async {
    String? messageId = chatMessage.messageId;
    String? title = chatMessage.title;
    if (messageId != null) {
      Uint8List? data =
          await messageAttachmentService.findContent(messageId, title);
      // String? filename =
      //     await messageAttachmentService.getTempFilename(messageId, title);
      if (data != null && fullScreen) {
        return PdfUtil.buildPdfView(key: UniqueKey(), data: data);
      }
    }
    Widget prefix = IconButton(
        onPressed: null,
        icon: Icon(
          Icons.extension,
          color: myself.primary,
        ));
    var tileData = TileData(
      prefix: prefix,
      title: title ?? '',
      subtitle: 'Not exist',
      dense: true,
    );
    return CommonMessage(tileData: tileData);
  }

  /// 全屏场景下office文件展示，是文件消息的子类型
  Future<Widget> buildOfficeMessageWidget(BuildContext context) async {
    String? messageId = chatMessage.messageId;
    String? title = chatMessage.title;
    if (messageId != null) {
      String? filename =
          await messageAttachmentService.getDecryptFilename(messageId, title);
      // if (filename != null && fullScreen) {
      //   return DocumentUtil.buildFileReaderView(
      //       key: UniqueKey(), filePath: filename);
      // }
    }
    Widget prefix = IconButton(
        onPressed: null,
        icon: Icon(
          Icons.extension_off,
          color: myself.primary,
        ));
    var tileData = TileData(
      prefix: prefix,
      title: title ?? '',
      subtitle: 'Not exist',
      dense: true,
    );
    return CommonMessage(tileData: tileData);
  }

  /// 显示引用消息，父消息
  /// 缺省是编辑模式，用于输入，会出现一个cancel按钮，parentMessageId为空，
  /// 会对chatMessageController.parentMessageId进行处理
  /// 当处于只读模式时，用于显示，parentMessageId不允许为空
  static Widget? buildParentChatMessageWidget({
    bool readOnly = false,
    String? parentMessageId,
  }) {
    int maxLength = 30;
    if (!readOnly) {
      parentMessageId = chatMessageController.parentMessageId;
    }
    if (parentMessageId == null) {
      return null;
    }
    return FutureBuilder(
      future: chatMessageService.findOriginByMessageId(parentMessageId),
      builder: (BuildContext context, AsyncSnapshot<ChatMessage?> snapshot) {
        if (snapshot.hasData) {
          ChatMessage? chatMessage = snapshot.data;
          if (chatMessage != null) {
            var senderName = chatMessage.senderName ?? '';
            var subMessageType = chatMessage.subMessageType;
            var contentType = chatMessage.contentType;
            String data = '$senderName: ';
            if (subMessageType == ChatMessageSubType.chat.name &&
                contentType == ChatMessageContentType.text.name) {
              var title = chatMessage.title;
              var content = chatMessage.content ?? '';
              content = chatMessageService.recoverContent(content);
              if (title != null) {
                data = data + title;
              } else {
                var length = content.length;
                length = length > maxLength ? maxLength : length;
                data = '$data${content.substring(0, length)}...';
              }
            } else {
              data = data + AppLocalizations.t(contentType!);
            }
            return Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                color: Colors.grey.withOpacity(0.2),
                child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Row(children: [
                      Expanded(child: CommonAutoSizeText(data)),
                      readOnly
                          ? Container()
                          : InkWell(
                              child: Icon(
                                //size: 16,
                                Icons.cancel,
                                color: myself.primary,
                              ),
                              onTap: () {
                                chatMessageController.parentMessageId = null;
                              },
                            )
                    ])));
          }
        }
        return Container();
      },
    );
  }
}
