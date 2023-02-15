import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/servicelocator.dart';

class ConferenceService extends GeneralBaseService<Conference> {
  ConferenceService({
    required super.tableName,
    required super.fields,
    required super.indexFields,
    super.encryptFields = const ['content', 'thumbBody', 'thumbnail', 'title'],
  }) {
    post = (Map map) {
      return Conference.fromJson(map);
    };
  }
}

final conferenceService = ConferenceService(
    tableName: "chat_conference",
    indexFields: [
      'ownerPeerId',
      'conferenceId',
      'peerId',
      'startDate',
      'name',
      'messageType'
    ],
    fields: ServiceLocator.buildFields(Conference(''), []));
