import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/service/dht/peerclient.dart';

class PeerClientDataPageController extends DataPageController<PeerClient> {
  PeerClientDataPageController() : super();

  Future<Pagination<PeerClient>> _findPage(int offset, int limit) async {
    Pagination<PeerClient> page =
        await peerClientService.findPage(limit: limit, offset: offset);
    pagination = page;
    if (page.data.isNotEmpty) {
      currentIndex = 0;
    }
    notifyListeners();
    return page;
  }

  @override
  Future<bool> first() async {
    if (pagination.rowsNumber != -1 && pagination.offset == 0) {
      return false;
    }
    var offset = 0;
    var limit = pagination.rowsPerPage;
    await _findPage(offset, limit);

    return true;
  }

  @override
  Future<bool> last() async {
    var limit = this.limit;
    var offset = pagination.rowsNumber - limit;
    if (offset < 0) {
      offset = 0;
    }
    if (offset > pagination.rowsNumber) {
      return false;
    }
    await _findPage(offset, limit);
    return true;
  }

  @override
  Future<bool> move(int index) async {
    if (index >= pagination.rowsNumber) {
      return false;
    }
    var limit = this.limit;
    var offset = index ~/ limit * limit;
    await _findPage(offset, limit);
    return true;
  }

  @override
  Future<bool> next() async {
    var limit = this.limit;
    var offset = pagination.offset + limit;
    if (offset > pagination.rowsNumber) {
      return false;
    }
    await _findPage(offset, limit);
    return true;
  }

  @override
  Future<bool> previous() async {
    var limit = this.limit;
    var offset = pagination.offset - limit;
    if (offset < 0) {
      return false;
    }
    await _findPage(offset, limit);
    return true;
  }
}

final DataPageController<PeerClient> peerClientDataPageController =
    PeerClientDataPageController();
