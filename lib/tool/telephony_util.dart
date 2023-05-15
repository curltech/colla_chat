import 'package:colla_chat/plugin/logger.dart';
import 'package:telephony/telephony.dart';

class TelephonyUtil {
  static send(String data, String recipient) async {
    final Telephony telephony = Telephony.backgroundInstance;
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
    final Telephony telephony = Telephony.backgroundInstance;
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
    final Telephony telephony = Telephony.backgroundInstance;
    List<SmsConversation> messages = await telephony.getConversations(
        filter: ConversationFilter.where(ConversationColumn.MSG_COUNT)
            .equals(msgCount)
            .and(ConversationColumn.THREAD_ID)
            .greaterThan(threadId),
        sortOrder: [OrderBy(ConversationColumn.THREAD_ID, sort: Sort.ASC)]);
    return messages;
  }

  static register(dynamic Function(SmsMessage)? fn) {
    final Telephony telephony = Telephony.backgroundInstance;
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
    final Telephony telephony = Telephony.backgroundInstance;
    bool? canSendSms = await telephony.isSmsCapable;
    return canSendSms;
  }

  static Future<SimState> simState() async {
    final Telephony telephony = Telephony.backgroundInstance;
    SimState simState = await telephony.simState;

    return simState;
  }
}
