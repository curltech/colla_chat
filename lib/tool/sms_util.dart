class SmsUtil {
  ///支持android和ios的短信发送
  // static send(String message, List<String> recipients,
  //     {bool sendDirect = false}) async {
  //   String result = await sendSMS(
  //           message: message, recipients: recipients, sendDirect: sendDirect)
  //       .catchError((error) {
  //     logger.e(error);
  //   });
  //   return result;
  // }

  ///支持android和ios
  // static Future<List<SmsMessage>> getAllSms(
  //     String address, String keyword) async {
  //   SmsQuery query = SmsQuery();
  //   List<SmsMessage> messages = await query.getAllSms;
  //
  //   return messages;
  // }
  //
  // ///支持android和ios
  // static sendSms(String message, String recipient,
  //     {SimCard? simCard,
  //     Function(SmsMessageState state)? onStateChanged}) async {
  //   SmsSender sender = SmsSender();
  //   var sms = SmsMessage(recipient, message);
  //   sms.onStateChanged.listen((state) {
  //     if (onStateChanged != null) {
  //       onStateChanged(state);
  //     }
  //   });
  //   var result = await sender.sendSms(sms, simCard: simCard);
  //
  //   return result;
  // }
  //
  // ///支持android，不支持ios
  // static receiveSms(Function(SmsMessage msg) onSmsReceived) async {
  //   SmsReceiver receiver = SmsReceiver();
  //   receiver.onSmsReceived?.listen((SmsMessage msg) {
  //     onSmsReceived(msg);
  //   });
  // }
  //
  // ///支持android，不支持ios
  // static Future<List<SimCard>> getSimCards() async {
  //   SimCardsProvider provider = SimCardsProvider();
  //   return await provider.getSimCards();
  // }
  //
  // ///支持android，不支持ios
  // static Future<List<SmsMessage>> querySms({
  //   int? start,
  //   int? count,
  //   String? address,
  //   int? threadId,
  //   List<SmsQueryKind> kinds = const [SmsQueryKind.Inbox],
  //   bool sort = true,
  // }) async {
  //   SmsQuery query = SmsQuery();
  //   List<SmsMessage> messages = await query.querySms(
  //       start: start,
  //       count: count,
  //       address: address,
  //       threadId: threadId,
  //       kinds: kinds,
  //       sort: sort);
  //
  //   return messages;
  // }
  //
  // ///支持android，不支持ios
  // static Future<List<SmsThread>> getAllThreads() async {
  //   SmsQuery query = SmsQuery();
  //   List<SmsThread> threads = await query.getAllThreads;
  //   for (var index = threads.length; index >= threads.length; index--) {
  //     String? senderNumber = threads[index].contact?.address;
  //     String sim = threads[index].messages.first.sim.toString();
  //     String? message = threads[index].messages.first.body;
  //   }
  //
  //   return threads;
  // }
  //
  // ///支持android，不支持ios
  // static Future<Contact?> queryContact({String? address}) async {
  //   ContactQuery contactQuery = ContactQuery();
  //   Contact? contact = await contactQuery.queryContact(address);
  //
  //   return contact;
  // }
  //
  // ///支持android，不支持ios
  // static Future<UserProfile> getUserProfile() async {
  //   UserProfileProvider provider = UserProfileProvider();
  //   UserProfile profile = await provider.getUserProfile();
  //
  //   return profile;
  // }
  //
  // ///支持android，不支持ios
  // static Future<bool?> removeSms(int smsId, int threadId) async {
  //   SmsRemover smsRemover = SmsRemover();
  //   return await smsRemover.removeSmsById(smsId, threadId);
  // }
}
