import 'dart:async';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/message/action_message.dart';
import 'package:colla_chat/pages/chat/chat/message/audio_message.dart';
import 'package:colla_chat/pages/chat/chat/message/cancel_message.dart';
import 'package:colla_chat/pages/chat/chat/message/extended_text_message.dart';
import 'package:colla_chat/pages/chat/chat/message/file_message.dart';
import 'package:colla_chat/pages/chat/chat/message/image_message.dart';
import 'package:colla_chat/pages/chat/chat/message/location_message.dart';
import 'package:colla_chat/pages/chat/chat/message/name_card_message.dart';
import 'package:colla_chat/pages/chat/chat/message/rich_text_message.dart';
import 'package:colla_chat/pages/chat/chat/message/url_message.dart';
import 'package:colla_chat/pages/chat/chat/message/video_message.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/chat/chat.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/document_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/geolocator_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/menu_util.dart';
import 'package:colla_chat/tool/pdf_util.dart';
import 'package:colla_chat/tool/smart_dialog_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
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

  ///消息体：扩展文本，图像，声音，视频，页面，复合文本，文件，名片，位置，收藏等种类
  ///每种消息体一个类
  Future<Widget> buildMessageBody(BuildContext context) async {
    ContentType? contentType;
    if (chatMessage.contentType != null) {
      contentType = StringUtil.enumFromString(
          ContentType.values, chatMessage.contentType!);
    }
    contentType = contentType ?? ContentType.text;
    ChatMessageSubType? subMessageType;
    subMessageType = StringUtil.enumFromString(
        ChatMessageSubType.values, chatMessage.subMessageType);
    Widget body;
    if (subMessageType == ChatMessageSubType.chat) {
      switch (contentType) {
        case ContentType.text:
          body = buildExtendedTextMessageWidget(context);
          break;
        case ContentType.audio:
          body = buildAudioMessageWidget(context);
          break;
        case ContentType.video:
          body = buildVideoMessageWidget(context);
          break;
        case ContentType.file:
          body = await buildFileMessageWidget(context);
          break;
        case ContentType.image:
          body = buildImageMessageWidget(context);
          break;
        case ContentType.card:
          body = buildNameCardMessageWidget(context);
          break;
        case ContentType.rich:
          body = buildRichTextMessageWidget(context);
          break;
        case ContentType.link:
          body = buildUrlMessageWidget(context);
          break;
        case ContentType.location:
          body = buildLocationMessageWidget(context);
          break;
        default:
          body = Container();
          break;
      }
    } else if (subMessageType == ChatMessageSubType.videoChat) {
      body = buildActionMessageWidget(context, subMessageType!);
    } else if (subMessageType == ChatMessageSubType.addFriend) {
      body = buildActionMessageWidget(context, subMessageType!);
    } else if (subMessageType == ChatMessageSubType.cancel) {
      body = buildCancelMessageWidget(context, chatMessage.content!);
    } else {
      body = Container();
    }
    if (!fullScreen) {
      body = InkWell(
          onTap: () {
            chatMessageController.currentIndex = index;
            indexWidgetProvider.push('full_screen');
            openLocationMap(context);
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
        await chatMessageService.delete(entity: chatMessage);
        chatMessageController.delete(index: this.index);
        break;
      case 'Cancel':
        String? messageId = chatMessage.messageId;
        if (messageId != null) {
          await chatMessageController.sendText(
            message: messageId,
            subMessageType: ChatMessageSubType.cancel,
          );
          await chatMessageService.delete(entity: chatMessage);
          chatMessageController.delete(index: this.index);
        }
        break;
      case 'Copy':
        break;
      case 'Forward':
        List<String> selects = [];
        await DialogUtil.show(
            builder: (BuildContext context) {
              return LinkmanGroupSearchWidget(
                selectType: SelectType.multidialog,
                onSelected: (List<String> selected) {
                  selects = selected;
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
    List<int>? data;
    if (content != null) {
      data = CryptoUtil.decodeBase64(content);
      content = CryptoUtil.utf8ToString(data);
    }
    return ExtendedTextMessage(
      key: UniqueKey(),
      isMyself: isMyself,
      content: content!,
    );
  }

  ActionMessage buildActionMessageWidget(
      BuildContext context, ChatMessageSubType subMessageType) {
    return ActionMessage(
      key: UniqueKey(),
      isMyself: isMyself,
      subMessageType: subMessageType,
    );
  }

  CancelMessage buildCancelMessageWidget(BuildContext context, String content) {
    return CancelMessage(
      key: UniqueKey(),
      isMyself: isMyself,
      content: content,
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
    List<int>? data;
    if (content != null) {
      data = CryptoUtil.decodeBase64(content);
      content = CryptoUtil.utf8ToString(data);
    }
    return NameCardMessage(
      key: UniqueKey(),
      content: content!,
      isMyself: isMyself,
    );
  }

  LocationMessage buildLocationMessageWidget(BuildContext context) {
    String? content = chatMessage.content;
    List<int>? data;
    if (content != null) {
      data = CryptoUtil.decodeBase64(content);
      content = CryptoUtil.utf8ToString(data);
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
  openLocationMap(BuildContext context) {
    String? content = chatMessage.content;
    if (content == null) {
      return;
    }
    List<int>? data;
    data = CryptoUtil.decodeBase64(content);
    content = CryptoUtil.utf8ToString(data);
    Map<String, dynamic> map = JsonUtil.toJson(content);
    LocationPosition locationPosition = LocationPosition.fromJson(map);
    var latitude = locationPosition.latitude; //纬度
    var longitude = locationPosition.longitude; //经度
    if (platformParams.desktop) {
      SmartDialogUtil.show(
          context: context,
          title: AppLocalizations.t('Location map'),
          builder: (BuildContext? context) {
            return GeolocatorUtil.buildLocationPicker(
                latitude: latitude,
                longitude: longitude,
                onPicked: (PickedData data) {});
          });
      // GeolocatorUtil.launchCoordinates(latitude, longitude);
    } else {
      SmartDialogUtil.show(
          context: context,
          title: AppLocalizations.t('Location map'),
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

  ImageMessage buildImageMessageWidget(BuildContext context) {
    String? messageId = chatMessage.messageId;
    String? title = chatMessage.title;
    String? thumbnail = chatMessage.thumbnail;
    String mimeType = chatMessage.mimeType!;
    double? width;
    double? height;
    if (chatMessageController.chatView == ChatView.text) {
      width = 64;
      height = 64;
    }
    return ImageMessage(
      key: UniqueKey(),
      messageId: messageId!,
      title: title,
      image: thumbnail,
      isMyself: isMyself,
      mimeType: mimeType,
      width: width,
      height: height,
    );
  }

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

  Future<Widget> buildFileMessageWidget(BuildContext context) async {
    String? messageId = chatMessage.messageId;
    String? title = chatMessage.title;
    String? extension;
    if (title != null) {
      extension = FileUtil.extension(title);
    }
    String? mimeType = chatMessage.mimeType;
    mimeType = mimeType ?? 'text/plain';
    if (mimeType.startsWith('image')) {
      return buildImageMessageWidget(context);
    } else if (mimeType == 'application/pdf') {
      if (fullScreen) {
        return buildPdfMessageWidget(context);
      }
    } else if (mimeType.startsWith('audio')) {
      if (fullScreen) {
        return buildAudioMessageWidget(context);
      }
    } else if (mimeType.startsWith('video')) {
      if (fullScreen) {
        return buildVideoMessageWidget(context);
      }
    } else if (extension == 'docx' ||
        extension == 'doc' ||
        extension == 'xlsx' ||
        extension == 'xls' ||
        extension == 'pptx' ||
        extension == 'ppt') {
      if (fullScreen) {
        return await buildOfficeMessageWidget(context);
      }
    }
    return FileMessage(
      key: UniqueKey(),
      messageId: messageId!,
      isMyself: isMyself,
      title: title!,
      mimeType: mimeType,
    );
  }

  Future<Widget> buildPdfMessageWidget(BuildContext context) async {
    String? messageId = chatMessage.messageId;
    String? title = chatMessage.title;
    if (messageId != null) {
      String? filename =
          await messageAttachmentService.getFilename(messageId, title);
      if (filename != null && fullScreen) {
        return PdfUtil.buildPdfView(key: UniqueKey(), filename: filename);
      }
    }
    return Container();
  }

  Future<Widget> buildOfficeMessageWidget(BuildContext context) async {
    String? messageId = chatMessage.messageId;
    String? title = chatMessage.title;
    if (messageId != null) {
      String? filename =
          await messageAttachmentService.getFilename(messageId, title);
      if (filename != null && fullScreen) {
        return DocumentUtil.buildFileReaderView(
            key: UniqueKey(), filePath: filename);
      }
    }
    return Container();
  }

  /// 缺省是编辑模式，用于输入，会出现一个cancel按钮，parentMessageId为空，
  /// 会对chatMessageController.parentMessageId进行处理
  /// 当处于只读模式时，用于显示，parentMessageId不允许为空
  static Widget buildParentChatMessageWidget({
    bool readOnly = false,
    String? parentMessageId,
  }) {
    int maxLength = 30;
    if (!readOnly) {
      parentMessageId = chatMessageController.parentMessageId;
    }
    if (parentMessageId == null) {
      return Container();
    }
    return FutureBuilder(
      future: chatMessageService.findByMessageId(parentMessageId),
      builder: (BuildContext context, AsyncSnapshot<ChatMessage?> snapshot) {
        if (snapshot.hasData) {
          ChatMessage? chatMessage = snapshot.data;
          if (chatMessage != null) {
            var senderName = chatMessage.senderName ?? '';
            var subMessageType = chatMessage.subMessageType;
            var contentType = chatMessage.contentType;
            String data = '$senderName: ';
            if (subMessageType == ChatMessageSubType.chat.name &&
                contentType == ContentType.text.name) {
              var title = chatMessage.title;
              var content = chatMessage.content ?? '';
              content = chatMessageService.decodeText(content);
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
                      Expanded(child: Text(data)),
                      readOnly
                          ? Container()
                          : InkWell(
                              child: Icon(
                                //size: 16,
                                Icons.cancel,
                                color: appDataProvider
                                    .themeData.colorScheme.primary,
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
