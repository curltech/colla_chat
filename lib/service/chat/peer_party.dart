import 'package:colla_chat/entity/chat/peer_party.dart';
import 'package:colla_chat/service/dht/base.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/servicelocator.dart';

abstract class PeerPartyService<T> extends PeerEntityService<T> {
  PeerPartyService(
      {required super.tableName,
      required super.fields,
      required super.indexFields});
}

class TagService extends GeneralBaseService<Tag> {
  TagService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
    post = (Map map) {
      return Tag.fromJson(map);
    };
  }
}

final tagService = TagService(
    tableName: "chat_tag",
    indexFields: ['ownerPeerId', 'createDate', 'tag'],
    fields: ServiceLocator.buildFields(Tag(), []));

class PartyTagService extends GeneralBaseService<PartyTag> {
  PartyTagService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
    post = (Map map) {
      return PartyTag.fromJson(map);
    };
  }
}

final partyTagService = PartyTagService(
    tableName: "chat_partytag",
    indexFields: ['ownerPeerId', 'createDate', 'tag', 'partyPeerId'],
    fields: ServiceLocator.buildFields(PartyTag(), []));
