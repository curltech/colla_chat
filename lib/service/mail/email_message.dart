import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/servicelocator.dart';

final ChatMessageService emailMessageService = ChatMessageService(
    tableName: "email_message",
    indexFields: [
      'ownerPeerId',
      'transportType',
      'messageId',
      'messageType',
      'subMessageType',
      'receiverPeerId',
      'senderPeerId',
      'sendTime',
    ],
    fields: ServiceLocator.buildFields(ChatMessage(), []));
