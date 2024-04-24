import 'package:colla_chat/plugin/logger.dart';
import 'package:another_telephony/telephony.dart';

class TelephonyUtil {
  static Telephony telephony = Telephony.backgroundInstance;

  static send(String data, String recipient) async {
    var result = telephony.sendSms(
        to: recipient,
        message: data,
        isMultipart: true,
        statusListener: (SendStatus status) {
          logger.i(status);
        });
    return result;
  }

  static Future<List<SmsMessage>> getInboxSms(
      String address, String keyword) async {
    List<SmsMessage> messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY],
        filter: SmsFilter.where(SmsColumn.ADDRESS)
            .equals(address)
            .and(SmsColumn.BODY)
            .like(keyword),
        sortOrder: [
          OrderBy(SmsColumn.ADDRESS, sort: Sort.ASC),
          OrderBy(SmsColumn.BODY)
        ]);
    return messages;
  }

  static Future<List<SmsConversation>> getConversations(
      String msgCount, String threadId) async {
    List<SmsConversation> messages = await telephony.getConversations(
        filter: ConversationFilter.where(ConversationColumn.MSG_COUNT)
            .equals(msgCount)
            .and(ConversationColumn.THREAD_ID)
            .greaterThan(threadId),
        sortOrder: [OrderBy(ConversationColumn.THREAD_ID, sort: Sort.ASC)]);
    return messages;
  }

  static register(dynamic Function(SmsMessage)? fn) {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        if (fn != null) {
          fn(message);
        }
      },
      onBackgroundMessage: fn,
    );
  }

  static Future<bool?> isSmsCapable() async {
    bool? canSendSms = await telephony.isSmsCapable;
    return canSendSms;
  }

  static Future<SimState> simState() async {
    SimState simState = await telephony.simState;

    return simState;
  }

  static Future<bool?> requestPhoneAndSmsPermissions() async {
    bool? success = await telephony.requestPhoneAndSmsPermissions;

    return success;
  }

  static Future<void> dialPhoneNumber(String mobile) async {
    return await telephony.dialPhoneNumber(mobile);
  }

  static Future<void> openDialer(String mobile) async {
    return await telephony.openDialer(mobile);
  }
}
