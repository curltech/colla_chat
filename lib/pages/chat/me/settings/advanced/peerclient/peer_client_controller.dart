import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/service/dht/peerclient.dart';

class PeerClientController extends DataListController<PeerClient> {
  PeerClientController() : super();

  Future<List<PeerClient>> _findPage(int offset, int limit) async {
    List<PeerClient> peerClients =
        await peerClientService.find(limit: limit, offset: offset);
    return peerClients;
  }

  Future<void> more({int? limit}) async {
    var offset = data.length;
    limit = limit ?? defaultLimit;
    List<PeerClient> peerClients = await _findPage(offset, limit);
    addAll(peerClients);
  }
}

final PeerClientController peerClientController = PeerClientController();
