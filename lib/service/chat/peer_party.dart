import 'package:colla_chat/entity/chat/peer_party.dart';
import 'package:colla_chat/service/dht/base.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/servicelocator.dart';

abstract class PeerPartyService<T> extends PeerEntityService<T> {
  PeerPartyService(
      {required super.tableName,
      required super.fields,
      super.uniqueFields,
      super.indexFields,
      super.encryptFields});
}

class TagService extends GeneralBaseService<Tag> {
  TagService({
    required super.tableName,
    required super.fields,
    super.indexFields = const ['ownerPeerId', 'createDate', 'tag'],
  }) {
    post = (Map map) {
      return Tag.fromJson(map);
    };
  }
}

final tagService = TagService(
    tableName: "chat_tag", fields: ServiceLocator.buildFields(Tag(), []));

class PartyTagService extends GeneralBaseService<PartyTag> {
  PartyTagService({
    required super.tableName,
    required super.fields,
    super.indexFields = const [
      'ownerPeerId',
      'createDate',
      'tag',
      'partyPeerId'
    ],
  }) {
    post = (Map map) {
      return PartyTag.fromJson(map);
    };
  }
}

final partyTagService = PartyTagService(
    tableName: "chat_partytag",
    fields: ServiceLocator.buildFields(PartyTag(), []));
