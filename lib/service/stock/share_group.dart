import 'package:colla_chat/entity/stock/share_group.dart';
import 'package:colla_chat/l10n/localization.dart';

import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/service/stock/share.dart';

class ShareGroupService extends GeneralBaseService<ShareGroup> {
  String defaultGroupName = AppLocalizations.t('MySelection');

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
      if (defaultGroupName == groupName) {
        subscription = await shareService.findSubscription();
        groupSubscription[groupName] = subscription!;
      } else {
        List<ShareGroup> shareGroups =
            await find(where: 'groupName=?', whereArgs: [groupName]);
        if (shareGroups.isNotEmpty) {
          subscription = '';
          for (ShareGroup shareGroup in shareGroups) {
            subscription = '${shareGroup.subscription!}${subscription!},';
          }
          groupSubscription[groupName] = subscription!;
        }
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
      subscription = '$subscription$tsCode,';
      groupSubscription[groupName] = subscription;
      ShareGroup shareGroup = ShareGroup();
      shareGroup.groupName = groupName;
      shareGroup.subscription = subscription;
      update(shareGroup, where: 'groupName=?', whereArgs: [groupName]);
    }
    return true;
  }

  bool remove(String groupName, String tsCode) {
    String? subscription = groupSubscription[groupName];
    if (subscription != null) {
      if (subscription.contains(tsCode)) {
        subscription = subscription.replaceAll('$tsCode,', '');
        groupSubscription[groupName] = subscription;
        ShareGroup shareGroup = ShareGroup();
        shareGroup.groupName = groupName;
        shareGroup.subscription = subscription;
        update(shareGroup, where: 'groupName=?', whereArgs: [groupName]);
      }
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
