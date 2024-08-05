import 'dart:async';
import 'dart:typed_data';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
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
import 'package:colla_chat/plugin/notification/firebase_messaging_service.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/service/chat/message_attachment.dart';
import 'package:colla_chat/tool/clipboard_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/pdf_util.dart';
import 'package:colla_chat/tool/sherpa/sherpa_speech_to_text.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/platform_future_builder.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

///每种消息的显示组件
class MessageWidget {
  final ChatMessage chatMessage;
  final bool fullScreen;
  final int index;
  bool isMyself = false;

  MessageWidget(this.chatMessage, this.index, {this.fullScreen = false}) {
    isMyself = chatMessage.isMyself;
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
    Widget body = CommonAutoSizeText(AppLocalizations.t('No content'));
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
        case ChatMessageContentType.image:
          body = buildImageMessageWidget(context);
          break;
        case ChatMessageContentType.rich:
          body = buildRichTextMessageWidget(context);
          break;
        case ChatMessageContentType.url:
          body = buildUrlMessageWidget(context);
          break;
        case ChatMessageContentType.location:
          body = buildLocationMessageWidget(context);
          break;
        case ChatMessageContentType.card:
          body = await buildNameCardMessageWidget(context);
          break;
        case ChatMessageContentType.file:
          body = await buildFileMessageWidget(context);
          break;
        default:
          if (chatMessage.mimeType != null) {
            String mainMimeType = FileUtil.mainMimeType(chatMessage.mimeType!);
            ChatMessageContentType? mimeType = StringUtil.enumFromString(
                ChatMessageContentType.values, mainMimeType);
            if (mimeType == ChatMessageContentType.image) {
              body = buildImageMessageWidget(context);
            } else if (mimeType == ChatMessageContentType.audio) {
              body = buildAudioMessageWidget(context);
            } else if (mimeType == ChatMessageContentType.video) {
              body = buildVideoMessageWidget(context);
            }
          }
          break;
      }
    } else if (subMessageType == ChatMessageSubType.videoChat) {
      body = buildVideoChatMessageWidget(context);
    } else if (subMessageType == ChatMessageSubType.addFriend) {
      body = await buildRequestAddFriendWidget(context, subMessageType!);
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
    }

    final List<ActionData> messagePopActionData = [];
    if (chatMessage.status == MessageStatus.unsent.name) {
      messagePopActionData.add(
        ActionData(
            label: 'Resend',
            tooltip: 'Resend message',
            icon: const Icon(Icons.redo_outlined)),
      );
    }
    if (subMessageType == ChatMessageSubType.chat) {
      if (contentType == ChatMessageContentType.file ||
          contentType == ChatMessageContentType.video ||
          contentType == ChatMessageContentType.audio ||
          contentType == ChatMessageContentType.media ||
          contentType == ChatMessageContentType.rich ||
          contentType == ChatMessageContentType.image) {
        messagePopActionData.add(ActionData(
            label: 'Save to file',
            tooltip: 'Save message attachment to file',
            icon: const Icon(Icons.save)));
        if (platformParams.mobile) {
          messagePopActionData.add(ActionData(
              label: 'Save to gallery',
              tooltip: 'Save message attachment to gallery',
              icon: const Icon(Icons.browse_gallery_outlined)));
        }
      }
      if (contentType == ChatMessageContentType.audio) {
        messagePopActionData.add(ActionData(
            label: 'Speech to text',
            tooltip: 'Transfer voice to text',
            icon: const Icon(Icons.text_snippet_outlined)));
      }
    }
    if (myself.peerId == chatMessage.senderPeerId &&
        subMessageType != ChatMessageSubType.cancel) {
      messagePopActionData.add(
        ActionData(
            label: 'Cancel',
            tooltip: 'Cancel message',
            icon: const Icon(Icons.cancel)),
      );
    }
    messagePopActionData.addAll([
      ActionData(
          label: 'Delete',
          tooltip: 'Delete message',
          icon: const Icon(Icons.delete)),
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
      ActionData(
          label: 'Share',
          tooltip: 'Share',
          icon: const Icon(Icons.share_outlined)),
      ActionData(
          label: 'Notify',
          tooltip: 'Notify',
          icon: const Icon(Icons.notifications)),
    ]);

    ///双击全屏
    if (!fullScreen) {
      bool canFullScreen = true;
      Linkman? linkman =
          await linkmanService.findCachedOneByPeerId(chatMessage.senderPeerId!);
      if (linkman?.linkmanStatus == LinkmanStatus.G.name) {
        canFullScreen = false;
      } else {
        linkman = await linkmanService
            .findCachedOneByPeerId(chatMessage.receiverPeerId!);
        if (linkman?.linkmanStatus == LinkmanStatus.G.name) {
          canFullScreen = false;
        }
      }
      body = InkWell(
          onDoubleTap: canFullScreen
              ? () {
                  chatMessageController.currentIndex = index;
                  indexWidgetProvider.push('full_screen_chat_message');
                }
              : null,
          onLongPress: () async {
            await DialogUtil.show(
              context: context,
              builder: (BuildContext context) {
                return Dialog(
                    elevation: 0.0,
                    insetPadding: EdgeInsets.zero,
                    child: DataActionCard(
                        onPressed: (int index, String label, {String? value}) {
                          Navigator.pop(context);
                          _onMessagePopAction(context, index, label,
                              value: value);
                        },
                        crossAxisCount: 4,
                        actions: messagePopActionData,
                        height: 200,
                        width: appDataProvider.secondaryBodyWidth,
                        iconSize: 30));
              },
            );
          },
          child: body);
    }

    return body;
  }

  _onMessagePopAction(BuildContext context, int index, String label,
      {String? value}) async {
    switch (label) {
      case 'Resend':
        await _resend(context);
      case 'Save to file':
        await _saveFile(context);
      case 'Save to gallery':
        await _saveFile(context, isFile: false);
        break;
      case 'Speech to text':
        await _asr(context);
        break;
      case 'Delete':
        await chatMessageService.remove(chatMessage);
        chatMessageController.delete(index: this.index);
        break;
      case 'Cancel':
        String? messageId = chatMessage.messageId;
        if (messageId != null) {
          chatMessageService.delete(
              where: 'messageId=?', whereArgs: [chatMessage.messageId!]);
          chatMessageController.delete(index: this.index);
          await chatMessageController.sendText(
            message: messageId,
            subMessageType: ChatMessageSubType.cancel,
          );
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
                  Navigator.pop(context, selected);
                },
                selected: const [],
              );
            },
            context: context);
        for (var selected in selects) {
          await chatMessageService.forward(chatMessage, selected);
        }
        chatMessageController.latest();
        break;
      case 'Collect':
        chatMessageService.collect(chatMessage);
        break;
      case 'Refer':
        String? messageId = chatMessage.messageId;
        chatMessageController.parentMessageId = messageId;
        break;
      case 'Share':
        await _share(context);
        break;
      case 'Notify':
        await _notify();
        break;

      default:
    }
  }

  Future<void> _resend(BuildContext context) async {
    await chatMessageService.sendAndStore(chatMessage);
    chatMessageController.latest();
  }

  Future<void> _saveFile(BuildContext context, {bool isFile = true}) async {
    String subMessageType = chatMessage.subMessageType;
    if (subMessageType == ChatMessageSubType.chat.name) {
      String contentType = chatMessage.contentType!;
      if (contentType == ChatMessageContentType.file.name ||
          contentType == ChatMessageContentType.video.name ||
          contentType == ChatMessageContentType.audio.name ||
          contentType == ChatMessageContentType.media.name ||
          contentType == ChatMessageContentType.rich.name ||
          contentType == ChatMessageContentType.image.name) {
        String? messageId = chatMessage.messageId;
        String? title = chatMessage.title;
        if (messageId == null) {
          DialogUtil.error(content: 'No source messageId');
          return;
        }
        String? filename;
        if (title != null) {
          filename = title;
        } else {
          filename = messageId;
        }
        Uint8List? bytes =
            await messageAttachmentService.findContent(messageId, title);
        if (bytes == null) {
          DialogUtil.error(content: 'No source file data');
          return;
        }
        if (!isFile) {
          await ImageUtil.saveImageGallery(bytes,
              name: filename, androidExistNotSave: true);
          DialogUtil.info(content: 'save to gallery: $filename');
        } else {
          String? dir = await FileUtil.directoryPathPicker();
          if (dir != null) {
            String path = p.join(dir, filename);
            await FileUtil.writeFileAsBytes(bytes, path);
            DialogUtil.info(content: 'save to file: $path');
          }
        }
      }
    }
  }

  Future<void> _asr(BuildContext context) async {
    String subMessageType = chatMessage.subMessageType;
    if (subMessageType == ChatMessageSubType.chat.name) {
      String contentType = chatMessage.contentType!;
      if (contentType == ChatMessageContentType.audio.name) {
        String? messageId = chatMessage.messageId;
        String? title = chatMessage.title;
        if (messageId == null) {
          DialogUtil.error(content: 'No source messageId');
          return;
        }
        String? filename;
        if (title != null) {
          filename = title;
        } else {
          filename = messageId;
        }
        Uint8List? bytes =
            await messageAttachmentService.findContent(messageId, title);
        if (bytes == null) {
          DialogUtil.error(content: 'No source file data');
          return;
        }
        SherpaSpeechToText sherpaSpeechToText = SherpaSpeechToText();
        await sherpaSpeechToText.recognize(audioData: bytes);
        DialogUtil.show(
            context: context,
            builder: (context) {
              return Dialog(
                  child: CommonAutoSizeText(sherpaSpeechToText.text!));
            });
      }
    }
  }

  Future<void> _share(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    String subMessageType = chatMessage.subMessageType;
    if (subMessageType == ChatMessageSubType.chat.name) {
      String contentType = chatMessage.contentType!;
      if (contentType == ChatMessageContentType.text.name) {
        Share.share(
          chatMessage.content!,
          subject: chatMessage.contentType,
          sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
        );
      }
      if (contentType == ChatMessageContentType.file.name ||
          contentType == ChatMessageContentType.video.name ||
          contentType == ChatMessageContentType.audio.name ||
          contentType == ChatMessageContentType.media.name ||
          contentType == ChatMessageContentType.rich.name ||
          contentType == ChatMessageContentType.image.name) {
        String? filename = await messageAttachmentService.getDecryptFilename(
            chatMessage.messageId!, chatMessage.title);
        if (filename != null) {
          Share.shareXFiles(
            [XFile(filename)],
            text: chatMessage.content,
            subject: chatMessage.contentType,
            sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
          );
        }
      }
    }
  }

  _notify() async {
    String? title = chatMessage.title;
    String? content = chatMessage.content;
    if (content != null) {
      content = chatMessageService.recoverContent(content);
    }
    String? senderName = chatMessage.senderName;
    // await localNotificationsController
    //     .showNotification(senderName ?? '', title ?? '', payload: content);
    String? fcmToken = await firebaseMessagingService.getToken();
    firebaseMessagingService.sendPushMessage(
        fcmToken!, senderName ?? '', 'chat', content);
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

  Future<RequestAddFriendMessage> buildRequestAddFriendWidget(
    BuildContext context,
    ChatMessageSubType subMessageType,
  ) async {
    var senderPeerId = chatMessage.senderPeerId!;
    bool isFriend = false;
    Linkman? linkman = await linkmanService.findCachedOneByPeerId(senderPeerId);
    if (linkman != null && linkman.linkmanStatus == LinkmanStatus.F.name) {
      isFriend = true;
    }
    return RequestAddFriendMessage(
      key: UniqueKey(),
      isMyself: isMyself,
      senderPeerId: senderPeerId,
      isFriend: isFriend,
      title: chatMessage.title,
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
    content = chatMessageService.recoverContent(content);
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

  Future<NameCardMessage> buildNameCardMessageWidget(
      BuildContext context) async {
    String? mimeType = chatMessage.mimeType;
    String? content = chatMessage.content;
    List<Linkman>? linkmen;
    List<Group>? groups;
    if (content != null) {
      content = chatMessageService.recoverContent(content);
      List<dynamic> list = JsonUtil.toJson(content);
      if (mimeType == PartyType.linkman.name) {
        linkmen = [];
        for (var map in list) {
          Linkman linkman = Linkman.fromJson(map);
          linkmen.add(linkman);
        }
      }
      if (mimeType == PartyType.group.name) {
        groups = [];
        for (var map in list) {
          Group group = Group.fromJson(map);
          groups.add(group);
        }
      }
    }
    return NameCardMessage(
      key: UniqueKey(),
      linkmen: linkmen,
      groups: groups,
      isMyself: isMyself,
      fullScreen: fullScreen,
      mimeType: mimeType,
    );
  }

  LocationMessage buildLocationMessageWidget(BuildContext context) {
    String? content = chatMessage.content;
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

  /// 非全屏场景下是缩略图
  /// 全屏下是原图
  ImageMessage buildImageMessageWidget(BuildContext context) {
    String? messageId = chatMessage.messageId;
    String? title = chatMessage.title;
    String? thumbnail = chatMessage.thumbnail;
    String? content = chatMessage.content;
    return ImageMessage(
      key: UniqueKey(),
      messageId: messageId!,
      title: title,
      thumbnail: thumbnail,
      content: content,
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
      fullScreen: fullScreen,
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
      fullScreen: fullScreen,
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
          Icons.local_post_office_outlined,
          color: myself.primary,
        ));
    var tileData = TileData(
      prefix: prefix,
      title: title ?? '',
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
    return PlatformFutureBuilder(
      future: chatMessageService.findOriginByMessageId(parentMessageId),
      builder: (BuildContext context, ChatMessage? chatMessage) {
        var senderName = chatMessage?.senderName ?? '';
        var subMessageType = chatMessage?.subMessageType;
        var contentType = chatMessage?.contentType;
        String data = '$senderName: ';
        if (subMessageType == ChatMessageSubType.chat.name &&
            contentType == ChatMessageContentType.text.name) {
          var title = chatMessage?.title;
          var content = chatMessage?.content ?? '';
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
      },
    );
  }
}
