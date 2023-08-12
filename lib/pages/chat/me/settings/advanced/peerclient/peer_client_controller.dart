import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:flutter/material.dart';

class PeerClientController extends DataListController<PeerClient> {
  PeerClientController() : super();

  Future<List<PeerClient>> _findPage(int offset, int limit) async {
    List<PeerClient> peerClients =
        await peerClientService.find(limit: limit, offset: offset);
    if (peerClients.isNotEmpty) {
      for (var peerClient in peerClients) {
        if (peerClient.avatar != null) {
          var avatarImage = ImageUtil.buildImageWidget(
              image: peerClient.avatar,
              height: AppImageSize.mdSize,
              width: AppImageSize.mdSize,
              fit: BoxFit.contain);
          peerClient.avatarImage = avatarImage;
        }
      }
    }
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
