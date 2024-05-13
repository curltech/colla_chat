import 'dart:io';
import 'dart:typed_data';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/chat/message_attachment.dart';
import 'package:colla_chat/entity/dht/myselfpeer.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/dht/myselfpeer.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/p2p/security_context.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/tool/archive_util.dart';
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

  ///获取加密的数据在content路径下附件的文件名称
  ///文件名是title，如果为空则是messageId
  Future<String?> getEncryptFilename(String messageId, String? title) async {
    String contentPath = p.join(myself.myPath, 'content');
    String? filename;
    if (!platformParams.web) {
      if (title != null) {
        filename = p.join(contentPath, title);
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
      filename = title;
    } else {
      filename = messageId;
    }
    String tempFilename = await FileUtil.getTempFilename(filename: filename);
    var file = File(tempFilename);
    bool exist = await file.exists();
    if (exist) {
      //file.deleteSync();
      return tempFilename;
    }
    String contentPath = p.join(myself.myPath, 'content');
    if (!platformParams.web) {
      String path = p.join(contentPath, filename);
      Uint8List? data = await FileUtil.readFileAsBytes(path);
      if (data != null) {
        data = await decryptContent(data);
        if (data != null) {
          try {
            filename =
                await FileUtil.writeTempFileAsBytes(data, filename: filename);
            return filename;
          } catch (e) {
            logger.e('writeTempFile $filename failure:$e');
          }
        }
      }
    } else {
      MessageAttachment? attachment =
          await findOne(where: 'messageId=?', whereArgs: [messageId]);
      if (attachment != null) {
        var content = attachment.content;
        if (content != null) {
          var data = CryptoUtil.decodeBase64(content);
          filename =
              await FileUtil.writeTempFileAsBytes(data, filename: filename);
          return filename;
        }
      }
    }

    return filename;
  }

  /// 获取消息附件的内容
  /// 读出文件,解密,返回二进制,继续处理的话,对字符串,需要base64处理
  Future<Uint8List?> findContent(String messageId, String? title) async {
    if (!platformParams.web) {
      final filename = await getEncryptFilename(messageId, title);
      if (filename != null) {
        Uint8List? data = await FileUtil.readFileAsBytes(filename);
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
    var result = await linkmanCryptographySecurityContextService
        .encrypt(securityContext);
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
    var result = await linkmanCryptographySecurityContextService
        .decrypt(securityContext);
    if (result) {
      var decrypted = securityContext.payload;
      return decrypted;
    }

    return null;
  }

  ///把加密的内容写入文件，或者附件记录
  ///content直接base64解码,加密,然后写入文件
  Future<String?> store(int id, String messageId, String? title, String content,
      EntityState state) async {
    String? filename;
    if (!platformParams.web) {
      filename = await getEncryptFilename(messageId, title);
      Uint8List? data = CryptoUtil.decodeBase64(content);
      if (filename != null) {
        data = await encryptContent(data);
        if (data != null) {
          await FileUtil.writeFileAsBytes(data, filename);
          logger.i(
              'message attachment writeFile filename:$filename length:${data.length}');
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

    return filename;
  }

  ///删除消息的附件
  remove(String messageId, String? title) async {
    delete(where: 'messageId=?', whereArgs: [messageId]);
    final filename = await getEncryptFilename(messageId, title);
    File file = File(filename!);
    if (file.existsSync()) {
      file.delete();
    }
  }

  ///备份附件目录
  Future<String?> backup(String peerId) async {
    MyselfPeer? myselfPeer = await myselfPeerService.findOneByPeerId(peerId);
    if (myselfPeer != null) {
      String name = myselfPeer.name;
      String contentPath = p.join(platformParams.path, name, 'content');
      var current = DateTime.now();
      var outputPath =
          '${name}_$peerId-${current.year}-${current.month}-${current.day}.tgz';
      outputPath = p.join(platformParams.path, name, outputPath);
      ArchiveUtil.compress(contentPath, outputPath);

      return outputPath;
    }
    return null;
  }

  ///恢复附件目录
  Future<String?> restore(String peerId, String inputPath) async {
    MyselfPeer? myselfPeer = await myselfPeerService.findOneByPeerId(peerId);
    if (myselfPeer != null) {
      String name = myselfPeer.name;
      String contentPath = p.join(platformParams.path, name);
      ArchiveUtil.uncompress(inputPath, contentPath);

      return contentPath;
    }
    return null;
  }
}

final messageAttachmentService = MessageAttachmentService(
    tableName: "chat_messageattachment",
    indexFields: ['ownerPeerId', 'messageId', 'createDate'],
    fields: ServiceLocator.buildFields(MessageAttachment(), []));
