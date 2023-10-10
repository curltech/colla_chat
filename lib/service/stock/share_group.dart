import 'package:colla_chat/entity/stock/share_group.dart';

import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/servicelocator.dart';

class ShareGroupService extends GeneralBaseService<ShareGroup> {
  String defaultGroupName = '我的自选';
  Map<String, List<String>> shareGroupCodes = {};

  ShareGroupService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
    post = (Map map) {
      return ShareGroup.fromJson(map);
    };
  }

  Future<List<String>?> findShareGroup(String groupName) async {
    List<String>? shareCodes = shareGroupCodes[groupName];
    if (shareCodes == null) {
      List<ShareGroup> shareGroups =
          await find(where: 'groupName=?', whereArgs: [groupName]);
      if (shareGroups.isNotEmpty) {
        shareCodes = [];
        for (ShareGroup shareGroup in shareGroups) {
          shareCodes.add(shareGroup.tsCode!);
        }
        shareGroupCodes[groupName] = shareCodes;
      }
    }
    return shareCodes;
  }

  removeShareGroup(String groupName) async {
    shareGroupCodes.remove(groupName);
    delete(where: 'groupName=?', whereArgs: [groupName]);
  }

  /// 获取股票所属的组
  Future<List<String>> getShareGroups(String tsCode) async {
    List<String> groupNames = [];
    List<ShareGroup> shareGroups =
        await find(where: 'tsCode=?', whereArgs: [tsCode]);
    if (shareGroups.isNotEmpty) {
      for (ShareGroup shareGroup in shareGroups) {
        groupNames.add(shareGroup.groupName!);
      }
    }

    return groupNames;
  }

  bool canBeAdd(String groupName, String tsCode) {
    List<String>? shareCodes = shareGroupCodes[groupName];
    if (shareCodes != null && shareCodes.isNotEmpty) {
      for (String shareCode in shareCodes) {
        if (shareCode == tsCode) {
          return false;
        }
      }
    }
    return false;
  }

  bool canBeRemove(String groupName, String tsCode) {
    return !canBeAdd(groupName, tsCode);
  }
}

final ShareGroupService shareGroupService = ShareGroupService(
    tableName: 'stk_shareGroup',
    fields: ServiceLocator.buildFields(ShareGroup(), []),
    indexFields: ['tsCode', 'groupName']);
