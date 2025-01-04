import 'package:colla_chat/entity/stock/share_group.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/servicelocator.dart';

class ShareGroupService extends GeneralBaseService<ShareGroup> {
  static String defaultGroupName = 'MySelection';

  ShareGroupService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
    post = (Map map) {
      return ShareGroup.fromJson(map);
    };
  }

  Future<void> store(ShareGroup shareGroup) async {
    ShareGroup? old =
        await findOne(where: 'groupName=?', whereArgs: [shareGroup.groupName]);
    if (old == null) {
      shareGroup.id = null;
      await insert(shareGroup);
    } else {
      shareGroup.id = old.id;
      await update(shareGroup);
    }
  }
}

final ShareGroupService shareGroupService = ShareGroupService(
    tableName: 'stk_sharegroup',
    fields: ServiceLocator.buildFields(ShareGroup(''), []),
    indexFields: ['subscription', 'groupName']);
