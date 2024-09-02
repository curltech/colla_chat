import 'package:colla_chat/entity/mail/mail_message.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:enough_mail/enough_mail.dart' as enough_mail;

class EmailMessageService extends GeneralBaseService<MailMessage> {
  EmailMessageService({
    required super.tableName,
    required super.fields,
    required super.indexFields,
    super.encryptFields = const [
      'content',
      'title',
    ],
  }) {
    post = (Map map) {
      return MailMessage.fromJson(map);
    };
    // timer = Timer.periodic(const Duration(seconds: 60), (timer) async {
    //   deleteTimeout();
    //   deleteSystem();
    // });
  }

  Future<bool> store(MailMessage emailMessage, {bool force = false}) async {
    int uid = emailMessage.uid;
    String? mailboxName = emailMessage.mailboxName;
    String? emailAddress = emailMessage.emailAddress;
    MailMessage? old = await findOne(
        where: 'emailAddress=? and mailboxName=? and uid=?',
        whereArgs: [emailAddress!, mailboxName!, uid]);
    if (old != null) {
      if (force) {
        emailMessage.id = old.id;
        emailMessage.createDate = old.createDate;
        await update(emailMessage);

        return true;
      }
      String? oldStatus = old.status;
      if (oldStatus == enough_mail.FetchPreference.full.name) {
        return false;
      }
      String? newStatus = emailMessage.status;
      if (newStatus == oldStatus) {
        return false;
      }
      if (newStatus == enough_mail.FetchPreference.full.name ||
          newStatus == enough_mail.FetchPreference.bodystructure.name) {
        emailMessage.id = old.id;
        emailMessage.createDate = old.createDate;
        await update(emailMessage);

        return true;
      }
    } else {
      await insert(emailMessage);
    }
    return true;
  }

  Future<bool> storeMimeMessage(
      String email,
      enough_mail.Mailbox mailbox,
      enough_mail.MimeMessage mimeMessage,
      enough_mail.FetchPreference fetchPreference,
      {bool force = false}) async {
    MailMessage emailMessage = MailMessage();
    emailMessage.emailAddress = email;
    mimeMessage.parse();
    emailMessage.subject = mimeMessage.decodeSubject();
    emailMessage.senders = mimeMessage.from;
    emailMessage.receivers = mimeMessage.to;
    emailMessage.sender = mimeMessage.sender;
    emailMessage.cc = mimeMessage.cc;
    emailMessage.bcc = mimeMessage.bcc;
    emailMessage.replyTo = mimeMessage.replyTo;
    emailMessage.sendTime = mimeMessage.decodeDate()?.toIso8601String();
    emailMessage.sendTime ??= mimeMessage.envelope?.date?.toIso8601String();
    emailMessage.uid = mimeMessage.uid ?? 0;
    emailMessage.guid = mimeMessage.guid ?? 0;
    emailMessage.sequenceId = mimeMessage.sequenceId ?? 0;
    emailMessage.messageId = mimeMessage.envelope?.messageId;
    emailMessage.inReplyTo = mimeMessage.envelope?.inReplyTo;
    emailMessage.mailboxName = mailbox.name;
    emailMessage.flags = mimeMessage.flags;
    emailMessage.status = fetchPreference.name;
    emailMessage.statusDate = DateUtil.currentDate();
    emailMessage.content = mimeMessage.renderMessage();

    return await store(emailMessage, force: force);
  }

  /// 取本地存储中更旧的邮件
  Future<List<MailMessage>> findMessages(
    String emailAddress,
    String mailboxName, {
    String? sendTime,
    int limit = 30,
    int offset = 0,
  }) async {
    String where = 'emailAddress=? and mailboxName=?';
    List<Object> whereArgs = [emailAddress, mailboxName];
    if (sendTime != null) {
      where = '$where and sendTime<?';
      whereArgs.add(sendTime);
    }
    List<MailMessage> emailMessages = await find(
        where: where,
        whereArgs: whereArgs,
        orderBy: 'sendTime desc',
        limit: limit,
        offset: offset);

    return emailMessages;
  }

  /// 取本地存储中更新的邮件
  Future<List<MailMessage>> findLatestMessages(
    String emailAddress,
    String mailboxName, {
    String? sendTime,
    int limit = 30,
    int offset = 0,
  }) async {
    String where = 'emailAddress=? and mailboxName=?';
    List<Object> whereArgs = [emailAddress, mailboxName];
    if (sendTime != null) {
      where = '$where and sendTime>?';
      whereArgs.add(sendTime);
    }
    List<MailMessage> emailMessages = await find(
        where: where,
        whereArgs: whereArgs,
        orderBy: 'sendTime desc',
        limit: limit,
        offset: offset);

    return emailMessages;
  }
}

final EmailMessageService mailMessageService = EmailMessageService(
    tableName: "chat_mailmessage",
    indexFields: [
      'ownerPeerId',
      'emailAddress',
      'uid',
      'mailboxName',
      'senderPeerId',
      'sendTime',
    ],
    fields: ServiceLocator.buildFields(MailMessage(), []));
