import 'dart:typed_data';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/chat_list_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman/linkman_webrtc_connection_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/group.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_reactive_form.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

final Rx<Group?> groupNotifier = Rx<Group?>(null);

///创建和修改群，填写群的基本信息，选择群成员和群主
class GroupEditWidget extends StatelessWidget with DataTileMixin {
  GroupEditWidget({super.key});

  @override
  IconData get iconData => Icons.group;

  @override
  String get routeName => 'group_edit';

  @override
  String get title => 'Group edit';

  @override
  bool get withLeading => true;

  final List<PlatformDataField> groupDataFields = [
    PlatformDataField(
        name: 'id',
        label: 'Id',
        inputType: InputType.label,
        prefixIcon: Icon(Icons.numbers_outlined, color: myself.primary)),
    PlatformDataField(
        name: 'peerId',
        label: 'PeerId',
        inputType: InputType.label,
        prefixIcon: Icon(Icons.perm_identity, color: myself.primary)),
    PlatformDataField(
        name: 'name',
        label: 'Name',
        prefixIcon: Icon(Icons.person, color: myself.primary)),
    PlatformDataField(
        name: 'alias',
        label: 'Alias',
        prefixIcon: Icon(Icons.person_pin_sharp, color: myself.primary)),
    PlatformDataField(
        name: 'myAlias',
        label: 'MyAlias',
        prefixIcon: Icon(Icons.person_pin, color: myself.primary)),
  ];
  late final PlatformReactiveFormController platformReactiveFormController =
      PlatformReactiveFormController(groupDataFields);

  final OptionController groupOwnerController = OptionController();

  //已经选择的群成员
  final RxList<String> groupMembers = RxList<String>([]);

  //当前群的头像
  final Rx<String?> groupAvatar = Rx<String?>(null);

  void _initGroup() {
    Group? current = groupNotifier.value;
    if (current == null) {
      current = Group('', '');
      groupNotifier.value = current;
    }
  }

  Future<void> _buildGroupData(BuildContext context) async {
    Group? current = groupNotifier.value;
    if (current == null) {
      return;
    }
    groupAvatar.value = current.avatar;
    List<String>? participants = current.participants;
    if (participants == null) {
      participants =
          await groupMemberService.findPeerIdsByGroupId(current.peerId);
      current.participants = participants;
    }
    if (!participants.contains(myself.peerId)) {
      participants.insert(0, myself.peerId!);
    }
    groupMembers.value = participants;

    await _buildGroupOwnerOptions();
  }

  //更新groupOwnerChoices
  Future<void> _buildGroupOwnerOptions() async {
    Group? current = groupNotifier.value;
    if (current == null) {
      return;
    }
    List<String> selected = groupMembers.value;
    current.groupOwnerPeerId ??= myself.peerId;
    current.groupOwnerName ??= myself.name;
    List<Option<String>> groupOwnerOptions = [];
    if (selected.isNotEmpty) {
      for (String groupMemberId in selected) {
        Linkman? linkman =
            await linkmanService.findCachedOneByPeerId(groupMemberId);
        bool selected = false;
        if (linkman != null) {
          if (current.groupOwnerPeerId != null) {
            String peerId = current.groupOwnerPeerId!;
            if (linkman.peerId == peerId) {
              selected = true;
            }
          }
          Option<String> option = Option<String>(linkman.name, linkman.peerId,
              selected: selected,
              leading: linkman.avatarImage,
              hint: linkman.email ?? '');
          groupOwnerOptions.add(option);
        } else {
          logger.e('Group member $groupMemberId is not linkman');
          DialogUtil.error(
              content:
                  '${AppLocalizations.t('Group member')} $groupMemberId${AppLocalizations.t(' is not linkman')}');
        }
      }
    }
    groupOwnerController.options = groupOwnerOptions;
  }

  //群成员显示和编辑界面
  Widget _buildGroupMembersWidget(BuildContext context) {
    var selector = Obx(() {
      return Container(
          padding: const EdgeInsets.symmetric(horizontal: 0.0),
          child: LinkmanGroupSearchWidget(
            key: UniqueKey(),
            selectType: SelectType.chipMultiSelectField,
            onSelected: (List<String>? selected) async {
              if (selected != null) {
                if (!selected.contains(myself.peerId)) {
                  selected.add(myself.peerId!);
                }
                groupMembers.value = selected;
                await _buildGroupOwnerOptions();
              }
            },
            selected: groupMembers.value,
            includeGroup: false,
          ));
    });

    return selector;
  }

  //群主选择界面
  Widget _buildGroupOwnerWidget(BuildContext context) {
    Group? current = groupNotifier.value;
    if (current == null) {
      return nilBox;
    }
    var selector = Container(
        padding: const EdgeInsets.symmetric(horizontal: 0.0),
        child: CustomSingleSelectField(
            title: 'GroupOwnerPeer',
            onChanged: (selected) {
              if (selected != null) {
                current.groupOwnerPeerId = selected;
                var options = groupOwnerController.options;
                for (var option in options) {
                  if (option.value == selected) {
                    current.groupOwnerName = option.label;
                    break;
                  }
                }
              } else {
                DialogUtil.error(
                    content: AppLocalizations.t('Must has group owner'));
              }
            },
            optionController: groupOwnerController));

    return selector;
  }

  Future<void> _pickAvatar(BuildContext context) async {
    Group? current = groupNotifier.value;
    if (current == null) {
      return;
    }
    Uint8List? avatar = await ImageUtil.pickAvatar(context: context);
    if (avatar != null) {
      current.avatar = ImageUtil.base64Img(CryptoUtil.encodeBase64(avatar));
      groupAvatar.value = current.avatar;
    }
  }

  Widget _buildAvatarWidget(BuildContext context) {
    var avatarWidget = Obx(() {
      Group? current = groupNotifier.value;
      if (current == null) {
        return nilBox;
      }
      var avatar = current.avatar;
      if (avatar != null && avatar.isNotEmpty) {
        var avatarImage = ImageUtil.buildImageWidget(
            imageContent: avatar,
            height: AppIconSize.mdSize,
            width: AppIconSize.mdSize,
            fit: BoxFit.contain);
        current.avatarImage = avatarImage;
      }
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
        child: ListTile(
            leading: Icon(Icons.image, color: myself.primary),
            title: AutoSizeText(AppLocalizations.t('avatar')),
            trailing: current.avatarImage,
            minVerticalPadding: 0.0,
            minLeadingWidth: 0.0,
            onTap: () async {
              await _pickAvatar(
                context,
              );
            }),
      );
    });

    return avatarWidget;
  }

  //群信息编辑界面
  Widget _buildPlatformReactiveForm(BuildContext context) {
    List<Widget> children = [
      const SizedBox(
        height: 10.0,
      ),
      _buildGroupMembersWidget(context),
      const SizedBox(
        height: 5.0,
      ),
      _buildGroupOwnerWidget(context),
      const SizedBox(
        height: 5.0,
      ),
      _buildAvatarWidget(context),
    ];
    var formInputWidget = ValueListenableBuilder(
        valueListenable: groupNotifier,
        builder: (BuildContext context, Group? group, Widget? child) {
          if (group == null) {
            return nilBox;
          }

          platformReactiveFormController.values = JsonUtil.toJson(group);
          return PlatformReactiveForm(
            height: appDataProvider.portraitSize.height * 0.5,
            spacing: 5.0,
            onSubmit: (Map<String, dynamic> values) {
              _onOk(values).then((group) {
                if (group != null) {
                  DialogUtil.info(content: 'Group ${group.name} is built');
                }
              });
            },
            platformReactiveFormController: platformReactiveFormController,
          );
        });
    children.add(formInputWidget);

    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: ListView(
          children: children,
        ));
  }

  ///修改提交，首先分清楚增加群和修改群
  ///在增加群的情况下，对所有的参与者发送群消息
  ///在修改群的情况下，如果只修改群信息，对所有参与者发送群消息
  ///在增加参与者的情况下，对增加的参与者发送群消息，参与者点击群消息，表示同意，向所有参与者发送成员增加消息
  ///在减少参与者的情况下，对所有的参与者发送成员删除消息
  Future<Group?> _onOk(Map<String, dynamic> values) async {
    bool groupModified = false;
    Group currentGroup = Group.fromJson(values);
    if (StringUtil.isEmpty(currentGroup.name)) {
      DialogUtil.error(content: AppLocalizations.t('Must has group name'));
      return null;
    }
    Group? current = groupNotifier.value;
    current ??= Group('', '');
    if (StringUtil.isEmpty(current.groupOwnerPeerId)) {
      DialogUtil.error(content: AppLocalizations.t('Must has group owner'));
      return null;
    }
    if (currentGroup.id == null) {
      current = await groupService.createGroup(currentGroup.name);
      groupModified = true;
    }
    if (current.myAlias != currentGroup.myAlias) {
      current.myAlias = currentGroup.myAlias;
    }
    if (current.alias != currentGroup.alias) {
      current.alias = currentGroup.alias;
      groupModified = true;
    }
    if (current.mobile != currentGroup.mobile) {
      current.mobile = currentGroup.mobile;
      groupModified = true;
    }
    if (current.email != currentGroup.email) {
      current.email = currentGroup.email;
      groupModified = true;
    }
    current.groupOwnerPeerId = current.groupOwnerPeerId ?? myself.peerId;
    for (var option in groupOwnerController.options) {
      if (option.value == current.groupOwnerPeerId) {
        current.groupOwnerName = option.label;
        break;
      }
    }
    var participants = groupMembers.value;
    if (!participants.contains(myself.peerId!)) {
      participants.add(myself.peerId!);
      groupMembers.value = [...participants];
      await _buildGroupOwnerOptions();
    }
    current.participants = groupMembers.value;
    GroupChange groupChange = await groupService.store(current);
    DialogUtil.info(content: AppLocalizations.t('Group has stored completely'));
    groupNotifier.value = current;

    //对所有的成员发送组变更的消息
    if (currentGroup.id == null) {
      // await groupService.addGroup(current);
    } else {
      if (groupModified) {
        bool allowed = groupService.canModifyGroup(current);
        if (!allowed) {
          DialogUtil.error(
              content: 'Not group owner or myself, can not modify group');
        } else {
          await groupService.modifyGroup(current);
        }
      }
    }
    //新增加的成员
    List<GroupMember>? newMembers = groupChange.addGroupMembers;
    if (newMembers is List<GroupMember> && newMembers.isNotEmpty) {
      if (current.id != null) {
        await groupService.addGroupMember(current, newMembers);
      }
    }

    List<GroupMember>? oldMembers = groupChange.removeGroupMembers;
    //处理删除的成员
    if (oldMembers is List<GroupMember> && oldMembers.isNotEmpty) {
      //对所有的成员发送组员删除的消息
      List<String> oldMemberIds = [];
      for (var oldMember in oldMembers) {
        oldMemberIds.add(oldMember.memberPeerId!);
      }
      bool allowed = groupService.canRemoveGroupMember(current, oldMemberIds);
      if (!allowed) {
        DialogUtil.error(
            content: 'Not group owner or myself, can not remove group member');
      } else {
        await groupService.removeGroupMember(current, oldMemberIds);
      }
    }
    if (currentGroup.id == null || groupModified) {
      groupChatSummaryController.refresh();
    }

    return current;
  }

  @override
  Widget build(BuildContext context) {
    _initGroup();
    _buildGroupData(context);
    String title = 'Add group';
    if (groupNotifier.value?.id != null) {
      title = 'Edit group';
    }
    List<Widget> rightWidgets = [
      IconButton(
        onPressed: () async {
          Group? current = groupNotifier.value;
          if (current != null) {
            List<GroupMember> members =
                await groupMemberService.findByGroupId(current.peerId);
            List<Linkman> linkmen = [];
            for (var member in members) {
              String? memberPeerId = member.memberPeerId;
              if (memberPeerId != null) {
                Linkman? linkman =
                    await linkmanService.findCachedOneByPeerId(memberPeerId);
                if (linkman != null) {
                  linkmen.add(linkman);
                }
              }
            }
            groupLinkmanController.replaceAll(linkmen);
          }
          indexWidgetProvider.push('linkman_webrtc_connection');
        },
        icon: const Icon(Icons.more_horiz_outlined),
        tooltip: AppLocalizations.t('More'),
      )
    ];
    var appBarView = AppBarView(
        title: title,
        helpPath: routeName,
        withLeading: withLeading,
        rightWidgets: rightWidgets,
        child: _buildPlatformReactiveForm(context));

    return appBarView;
  }
}
