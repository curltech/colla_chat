enum MessageType { system, public, chat, group }

class MessageData {
  late String avatar;
  late String title;
  late String subTitle;
  late DateTime messageTime;
  MessageType? messageType;
}
