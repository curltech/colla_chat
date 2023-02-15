import 'dart:typed_data';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/chat/message_attachment.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/p2p/security_context.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:path/path.dart' as p;

class MessageAttachmentService extends GeneralBaseService<MessageAttachment> {
  MessageAttachmentService({
    required super.tableName,
    required super.fields,
    required super.indexFields,
    super.encryptFields = const ['content'],
  }) {
    post = (Map map) {
      return MessageAttachment.fromJson(map);
    };
  }

  ///获取加密的数据在content路径下附件的文件名称，
  Future<String?> getEncryptFilename(String messageId, String? title) async {
    String contentPath = p.join(myself.myPath, 'content');
    String? filename;
    if (!platformParams.web) {
      if (title != null) {
        filename = p.join(contentPath, '${messageId}_$title');
      } else {
        filename = p.join(contentPath, messageId);
      }
      return filename;
    }

    return filename;
  }

  ///获取获取的解密数据在临时目录下附件的文件名称，
  Future<String?> getDecryptFilename(String messageId, String? title) async {
    String? filename;
    if (title != null) {
      filename = '${messageId}_$title';
    } else {
      filename = messageId;
    }
    String contentPath = p.join(myself.myPath, 'content');
    if (!platformParams.web) {
      Uint8List? data = await FileUtil.readFile(p.join(contentPath, filename));
      if (data != null) {
        data = await decryptContent(data);
        if (data != null) {
          filename = await FileUtil.writeTempFile(data, filename: filename);
          return filename;
        }
      }
    } else {
      MessageAttachment? attachment =
          await findOne(where: 'messageId=?', whereArgs: [messageId]);
      if (attachment != null) {
        var content = attachment.content;
        if (content != null) {
          var data = CryptoUtil.decodeBase64(content);
          filename = await FileUtil.writeTempFile(data, filename: filename);
          return filename;
        }
      }
    }

    return filename;
  }

  /// 解密的内容
  Future<Uint8List?> findContent(String messageId, String? title) async {
    if (!platformParams.web) {
      final filename = await getEncryptFilename(messageId, title);
      if (filename != null) {
        Uint8List? data = await FileUtil.readFile(filename);
        if (data != null) {
          data = await decryptContent(data);
          if (data != null) {
            return data;
          }
        }
      }
    } else {
      MessageAttachment? attachment =
          await findOne(where: 'messageId=?', whereArgs: [messageId]);
      if (attachment != null) {
        var content = attachment.content;
        if (content != null) {
          return CryptoUtil.decodeBase64(content);
        }
      }
    }
    return null;
  }

  Future<Uint8List?> encryptContent(
    Uint8List data,
  ) async {
    SecurityContext securityContext = SecurityContext();
    securityContext.payload = data;
    var result =
        await cryptographySecurityContextService.encrypt(securityContext);
    if (result) {
      var encrypted = securityContext.payload;
      return encrypted;
    }

    return null;
  }

  Future<Uint8List?> decryptContent(
    Uint8List data,
  ) async {
    SecurityContext securityContext = SecurityContext();
    securityContext.payload = data;
    var result =
        await cryptographySecurityContextService.decrypt(securityContext);
    if (result) {
      var decrypted = securityContext.payload;
      return decrypted;
    }

    return null;
  }

  ///把加密的内容写入文件，或者附件记录
  Future<void> store(int id, String messageId, String? title, String content,
      EntityState state) async {
    if (!platformParams.web) {
      final filename = await getEncryptFilename(messageId, title);
      Uint8List? data = CryptoUtil.decodeBase64(content);
      if (filename != null) {
        data = await encryptContent(data);
        if (data != null) {
          await FileUtil.writeFile(data, filename);
          logger.i('message attachment writeFile filename:$filename');
        }
      }
    } else {
      MessageAttachment attachment = MessageAttachment();
      attachment.id = id;
      attachment.messageId = messageId;
      attachment.title = title;
      attachment.content = content;
      if (state == EntityState.insert) {
        await messageAttachmentService.insert(attachment);
      } else if (state == EntityState.update) {
        await messageAttachmentService.update(attachment);
      }
    }
  }

  ///删除消息的附件
  removeByPeerId(String peerId) async {
    await delete(where: 'groupPeerId=?', whereArgs: [peerId]);
  }
}

final messageAttachmentService = MessageAttachmentService(
    tableName: "chat_messageattachment",
    indexFields: ['ownerPeerId', 'messageId', 'createDate'],
    fields: ServiceLocator.buildFields(MessageAttachment(), []));
