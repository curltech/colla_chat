import 'package:colla_chat/entity/stock/share_group.dart';
import 'package:colla_chat/l10n/localization.dart';

import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/service/stock/share.dart';

class ShareGroupService extends GeneralBaseService<ShareGroup> {
  String defaultGroupName = AppLocalizations.t('MySelection');

  /// 分组对应的tscode的字符串
  final Map<String, String> _groupSubscription = {};

  ShareGroupService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
    post = (Map map) {
      return ShareGroup.fromJson(map);
    };
  }

  Future<Map<String, String>> get groupSubscription async {
    if (_groupSubscription.isEmpty) {
      _groupSubscription[defaultGroupName] = shareService.subscription;
      List<ShareGroup> shareGroups = await findAll();
      for (var shareGroup in shareGroups) {
        _groupSubscription[shareGroup.groupName] = shareGroup.subscription;
      }
    }

    return _groupSubscription;
  }

  Future<String?> findSubscription(String groupName) async {
    String? subscription = (await groupSubscription)[groupName];
    if (subscription == null) {
      if (defaultGroupName == groupName) {
        subscription = shareService.subscription;
        _groupSubscription[groupName] = subscription;
      } else {
        List<ShareGroup> shareGroups =
            await find(where: 'groupName=?', whereArgs: [groupName]);
        if (shareGroups.isNotEmpty) {
          subscription = '';
          for (ShareGroup shareGroup in shareGroups) {
            subscription = '${shareGroup.subscription!}${subscription!},';
          }
          _groupSubscription[groupName] = subscription!;
        }
      }
    }
    return subscription;
  }

  removeShareGroup(String groupName) async {
    _groupSubscription.remove(groupName);
    delete(where: 'groupName=?', whereArgs: [groupName]);
  }

  bool add(String groupName, String tsCode) {
    String? subscription = _groupSubscription[groupName];
    subscription ??= '';
    if (!subscription.contains(tsCode)) {
      subscription = '$subscription$tsCode,';
      _groupSubscription[groupName] = subscription;
      ShareGroup shareGroup = ShareGroup(groupName);
      shareGroup.subscription = subscription;
      update(shareGroup, where: 'groupName=?', whereArgs: [groupName]);
    }
    return true;
  }

  bool remove(String groupName, String tsCode) {
    String? subscription = _groupSubscription[groupName];
    if (subscription != null) {
      if (subscription.contains(tsCode)) {
        subscription = subscription.replaceAll('$tsCode,', '');
        _groupSubscription[groupName] = subscription;
        ShareGroup shareGroup = ShareGroup(groupName);
        shareGroup.subscription = subscription;
        update(shareGroup, where: 'groupName=?', whereArgs: [groupName]);
      }
    }
    return true;
  }

  bool canBeAdd(String groupName, String tsCode) {
    String? subscription = _groupSubscription[groupName];
    if (subscription != null && subscription.isNotEmpty) {
      return !subscription.contains(tsCode);
    }
    return true;
  }

  bool canBeRemove(String groupName, String tsCode) {
    return !canBeAdd(groupName, tsCode);
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
