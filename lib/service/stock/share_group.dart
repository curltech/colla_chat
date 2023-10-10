import 'package:colla_chat/entity/stock/share_group.dart';

import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/servicelocator.dart';

class ShareGroupService extends GeneralBaseService<ShareGroup> {
  String defaultGroupName = '我的自选';

  /// 分组对应的tscode的字符串
  Map<String, String> groupSubscription = {};

  ShareGroupService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
    post = (Map map) {
      return ShareGroup.fromJson(map);
    };
  }

  Future<String?> findSubscription(String groupName) async {
    String? subscription = groupSubscription[groupName];
    if (subscription == null) {
      List<ShareGroup> shareGroups =
          await find(where: 'groupName=?', whereArgs: [groupName]);
      if (shareGroups.isNotEmpty) {
        subscription = '';
        for (ShareGroup shareGroup in shareGroups) {
          subscription = '${subscription!},${shareGroup.subscription!}';
        }
        groupSubscription[groupName] = subscription!;
      }
    }
    return subscription;
  }

  removeShareGroup(String groupName) async {
    groupSubscription.remove(groupName);
    delete(where: 'groupName=?', whereArgs: [groupName]);
  }

  bool add(String groupName, String tsCode) {
    String? subscription = groupSubscription[groupName];
    subscription ??= '';
    if (!subscription.contains(tsCode)) {
      subscription = '$subscription,$tsCode';
      groupSubscription[groupName] = subscription;
      ShareGroup shareGroup = ShareGroup();
      shareGroup.groupName = groupName;
      shareGroup.subscription = subscription;
      update(shareGroup, where: 'groupName=?', whereArgs: [groupName]);
    }
    return true;
  }

  bool canBeAdd(String groupName, String tsCode) {
    String? subscription = groupSubscription[groupName];
    if (subscription != null && subscription.isNotEmpty) {
      return !subscription.contains(tsCode);
    }
    return true;
  }

  bool canBeRemove(String groupName, String tsCode) {
    return !canBeAdd(groupName, tsCode);
  }
}

final ShareGroupService shareGroupService = ShareGroupService(
    tableName: 'stk_shareGroup',
    fields: ServiceLocator.buildFields(ShareGroup(), []),
    indexFields: ['subscription', 'groupName']);
