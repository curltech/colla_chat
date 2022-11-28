import 'dart:async';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/message/action_message.dart';
import 'package:colla_chat/pages/chat/chat/message/audio_message.dart';
import 'package:colla_chat/pages/chat/chat/message/extended_text_message.dart';
import 'package:colla_chat/pages/chat/chat/message/file_message.dart';
import 'package:colla_chat/pages/chat/chat/message/image_message.dart';
import 'package:colla_chat/pages/chat/chat/message/location_message.dart';
import 'package:colla_chat/pages/chat/chat/message/name_card_message.dart';
import 'package:colla_chat/pages/chat/chat/message/rich_text_message.dart';
import 'package:colla_chat/pages/chat/chat/message/url_message.dart';
import 'package:colla_chat/pages/chat/chat/message/video_message.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/service/chat/chat.dart';
import 'package:colla_chat/tool/document_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/geolocator_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/pdf_util.dart';
import 'package:colla_chat/tool/smart_dialog_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';

///每种消息的显示组件
class MessageWidget {
  final ChatMessage chatMessage;

  final int index;
  bool? _isMyself;

  MessageWidget(this.chatMessage, this.index) {
    chatMessageController.chatView;
  }

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
    ChatSubMessageType? subMessageType;
    subMessageType = StringUtil.enumFromString(
        ChatSubMessageType.values, chatMessage.subMessageType);
    Widget body;
    if (subMessageType == ChatSubMessageType.chat) {
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
    } else if (subMessageType == ChatSubMessageType.videoChat) {
      body = buildActionMessageWidget(context, subMessageType!);
    } else if (subMessageType == ChatSubMessageType.addFriend) {
      body = buildActionMessageWidget(context, subMessageType!);
    } else {
      body = Container();
    }
    body = InkWell(
        onTap: () {
          chatMessageController.currentIndex = index;
          chatMessageController.chatView = ChatView.full;
          openLocationMap(context);
        },
        child: body);
    return body;
  }

  ExtendedTextMessage buildExtendedTextMessageWidget(BuildContext context) {
    String? content = chatMessage.content;
    List<int>? data;
    if (content != null) {
      data = CryptoUtil.decodeBase64(content);
      content = CryptoUtil.utf8ToString(data);
    }
    return ExtendedTextMessage(
      key: GlobalKey(),
      isMyself: isMyself,
      content: content!,
    );
  }

  ActionMessage buildActionMessageWidget(
      BuildContext context, ChatSubMessageType subMessageType) {
    return ActionMessage(
      key: GlobalKey(),
      isMyself: isMyself,
      subMessageType: subMessageType,
    );
  }

  UrlMessage buildUrlMessageWidget(BuildContext context) {
    String? title = chatMessage.title;
    return UrlMessage(
      key: GlobalKey(),
      url: title!,
      isMyself: isMyself,
    );
  }

  RichTextMessage buildRichTextMessageWidget(BuildContext context) {
    String? messageId = chatMessage.messageId;
    return RichTextMessage(
      key: GlobalKey(),
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
      key: GlobalKey(),
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
      key: GlobalKey(),
      content: content!,
      isMyself: isMyself,
      thumbnail: thumbnail,
    );
  }

  openLocationMap(BuildContext context) {
    String? content = chatMessage.content;
    if (content == null) {
      return;
    }
    List<int>? data;
    data = CryptoUtil.decodeBase64(content);
    content = CryptoUtil.utf8ToString(data);
    Map<String, dynamic> map = JsonUtil.toJson(content);
    Position position = Position.fromMap(map);
    var latitude = position.latitude; //纬度
    var longitude = position.longitude; //经度
    if (platformParams.desktop) {
      SmartDialogUtil.show(
          context: context,
          title: AppLocalizations.t('Location map'),
          builder: (BuildContext context) {
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
          builder: (BuildContext context) {
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
    String? thumbnail = chatMessage.thumbnail;
    String mimeType = chatMessage.mimeType!;
    double? width;
    double? height;
    if (chatMessageController.chatView == ChatView.text) {
      width = 64;
      height = 64;
    }
    return ImageMessage(
      key: GlobalKey(),
      messageId: messageId!,
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
    String? thumbnail = chatMessage.thumbnail;
    return VideoMessage(
      key: GlobalKey(),
      id: id!,
      messageId: messageId!,
      isMyself: isMyself,
      thumbnail: thumbnail,
    );
  }

  AudioMessage buildAudioMessageWidget(BuildContext context) {
    int? id = chatMessage.id;
    String? messageId = chatMessage.messageId;
    return AudioMessage(
      key: GlobalKey(),
      id: id!,
      messageId: messageId!,
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
      if (chatMessageController.chatView == ChatView.full) {
        return buildPdfMessageWidget(context);
      }
    } else if (mimeType.startsWith('audio')) {
      return buildAudioMessageWidget(context);
    } else if (mimeType.startsWith('video')) {
      return buildVideoMessageWidget(context);
    } else if (extension == 'docx' ||
        extension == 'doc' ||
        extension == 'xlsx' ||
        extension == 'xls' ||
        extension == 'pptx' ||
        extension == 'ppt') {
      if (chatMessageController.chatView == ChatView.full) {
        return await buildOfficeMessageWidget(context);
      }
    }
    return FileMessage(
      key: GlobalKey(),
      messageId: messageId!,
      isMyself: isMyself,
      title: title!,
      mimeType: mimeType,
    );
  }

  Future<Widget> buildPdfMessageWidget(BuildContext context) async {
    String? messageId = chatMessage.messageId;
    if (messageId != null) {
      String? filename = await messageAttachmentService.getFilename(messageId);
      if (filename != null && chatMessageController.chatView == ChatView.full) {
        return PdfUtil.buildPdfView(filename: filename);
      }
    }
    return Container();
  }

  Future<Widget> buildOfficeMessageWidget(BuildContext context) async {
    String? messageId = chatMessage.messageId;
    if (messageId != null) {
      String? filename = await messageAttachmentService.getFilename(messageId);
      if (filename != null && chatMessageController.chatView == ChatView.full) {
        return DocumentUtil.buildFileReaderView(filePath: filename);
      }
    }
    return Container();
  }
}
