import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/chat_list_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/group.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/asset_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

final List<ColumnFieldDef> groupColumnFieldDefs = [
  ColumnFieldDef(
      name: 'peerId',
      label: 'PeerId',
      inputType: InputType.label,
      prefixIcon: Icon(Icons.perm_identity, color: myself.primary)),
  ColumnFieldDef(
      name: 'name',
      label: 'Name',
      prefixIcon: Icon(Icons.person, color: myself.primary)),
  ColumnFieldDef(
      name: 'alias',
      label: 'Alias',
      prefixIcon: Icon(Icons.person_pin_sharp, color: myself.primary)),
  ColumnFieldDef(
      name: 'myAlias',
      label: 'MyAlias',
      prefixIcon: Icon(Icons.person_pin, color: myself.primary)),
];

///创建和修改群，填写群的基本信息，选择群成员和群主
class LinkmanGroupAddWidget extends StatefulWidget with TileDataMixin {
  LinkmanGroupAddWidget({Key? key}) : super(key: key);

  @override
  IconData get iconData => Icons.person;

  @override
  String get routeName => 'linkman_add_group';

  @override
  String get title => 'Linkman add group';

  @override
  bool get withLeading => true;

  @override
  State<StatefulWidget> createState() => _LinkmanGroupAddWidgetState();
}

class _LinkmanGroupAddWidgetState extends State<LinkmanGroupAddWidget> {
  TextEditingController controller = TextEditingController();

  OptionController groupOwnerController = OptionController();

  //已经选择的群成员
  ValueNotifier<List<String>> groupMembers = ValueNotifier([]);

  //当前群
  ValueNotifier<Group> group = ValueNotifier(Group('', ''));

  //当前群的头像
  ValueNotifier<String?> groupAvatar = ValueNotifier(null);

  @override
  initState() {
    super.initState();
    groupController.addListener(_update);
    _buildGroupData();
  }

  _update() {
    _buildGroupData();
  }

  _buildGroupData() async {
    var current = groupController.current;
    if (current != null) {
      group.value = current;
      groupAvatar.value = current.avatar;
    } else {
      group.value = Group('', '');
      return;
    }
    if (group.value.id != null) {
      List<String> groupMembers = [];
      List<GroupMember> members =
          await groupMemberService.findByGroupId(group.value.peerId);
      if (members.isNotEmpty) {
        for (GroupMember member in members) {
          groupMembers.add(member.memberPeerId!);
        }
      }
      await _buildGroupOwnerOptions(groupMembers);
      this.groupMembers.value = groupMembers;
    }
  }

  //更新groupOwnerChoices
  _buildGroupOwnerOptions(List<String> selected) async {
    Group group = this.group.value;
    group.groupOwnerPeerId ??= myself.peerId;
    group.groupOwnerName ??= myself.name;
    List<Option<String>> groupOwnerOptions = [];
    if (selected.isNotEmpty) {
      for (String groupMemberId in selected) {
        Linkman? linkman =
            await linkmanService.findCachedOneByPeerId(groupMemberId);
        bool checked = false;
        if (linkman != null) {
          if (group.groupOwnerPeerId != null) {
            String peerId = group.groupOwnerPeerId!;
            if (linkman.peerId == peerId) {
              checked = true;
            }
          }
          Option<String> option = Option<String>(linkman.name, linkman.peerId,
              checked: checked, leading: linkman.avatarImage);
          groupOwnerOptions.add(option);
        } else {
          logger.e('Group member $groupMemberId is not linkman');
          if (mounted) {
            DialogUtil.error(context,
                content: 'Group member $groupMemberId is not linkman');
          }
        }
      }
    }
    groupOwnerController.options = groupOwnerOptions;
  }

  //群成员显示和编辑界面
  Widget _buildGroupMembersWidget(BuildContext context) {
    var selector = ValueListenableBuilder(
        valueListenable: groupMembers,
        builder:
            (BuildContext context, List<String> groupMembers, Widget? child) {
          return Container(
              padding: const EdgeInsets.symmetric(horizontal: 0.0),
              child: LinkmanGroupSearchWidget(
                key: UniqueKey(),
                selectType: SelectType.chipMultiSelectField,
                onSelected: (List<String>? selected) async {
                  if (selected != null) {
                    this.groupMembers.value = selected;
                    await _buildGroupOwnerOptions(selected);
                  }
                },
                selected: this.groupMembers.value,
                includeGroup: false,
              ));
        });

    return selector;
  }

  //群主选择界面
  Widget _buildGroupOwnerWidget(BuildContext context) {
    Group group = this.group.value;
    var selector = Container(
        padding: const EdgeInsets.symmetric(horizontal: 0.0),
        child: CustomSingleSelectField(
            title: 'GroupOwnerPeer',
            onChanged: (selected) {
              if (selected != null) {
                group.groupOwnerPeerId = selected;
                var options = groupOwnerController.options;
                for (var option in options) {
                  if (option.value == selected) {
                    group.groupOwnerName = option.label;
                    break;
                  }
                }
              } else {
                DialogUtil.error(context,
                    content: AppLocalizations.t('Must has group owner'));
              }
            },
            optionController: groupOwnerController));

    return selector;
  }

  Future<void> _pickAvatar(BuildContext context) async {
    Group group = this.group.value;
    if (platformParams.desktop) {
      List<XFile> xfiles = await FileUtil.pickFiles(type: FileType.image);
      if (xfiles.isNotEmpty) {
        List<int> avatar = await xfiles[0].readAsBytes();
        group.avatar = ImageUtil.base64Img(CryptoUtil.encodeBase64(avatar));
        groupAvatar.value = group.avatar;
      }
    } else if (platformParams.mobile) {
      List<AssetEntity>? assets = await AssetUtil.pickAssets(context);
      if (assets != null && assets.isNotEmpty) {
        List<int>? avatar = await assets[0].originBytes;
        if (avatar != null) {
          group.avatar = ImageUtil.base64Img(CryptoUtil.encodeBase64(avatar));
          groupAvatar.value = group.avatar;
        }
      }
    }
  }

  Widget _buildAvatarWidget(BuildContext context) {
    Group group = this.group.value;
    var avatarWidget = ValueListenableBuilder(
        valueListenable: groupAvatar,
        builder: (BuildContext context, String? groupAvatar, Widget? child) {
          var avatar = group.avatar;
          if (avatar != null && avatar.isNotEmpty) {
            var avatarImage = ImageUtil.buildImageWidget(
                image: avatar,
                height: AppIconSize.mdSize,
                width: AppIconSize.mdSize,
                fit: BoxFit.contain);
            group.avatarImage = avatarImage;
          }
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
            child: ListTile(
                leading: Icon(Icons.image, color: myself.primary),
                title: CommonAutoSizeText(AppLocalizations.t('avatar')),
                trailing: group.avatarImage,
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
  Widget _buildFormInputWidget(BuildContext context) {
    List<Widget> children = [
      _buildGroupMembersWidget(context),
      const SizedBox(
        height: 1,
      ),
      _buildGroupOwnerWidget(context),
      const SizedBox(
        height: 1,
      ),
      _buildAvatarWidget(context),
    ];
    var formInputWidget = ValueListenableBuilder(
        valueListenable: group,
        builder: (BuildContext context, Group? group, Widget? child) {
          Map<String, dynamic>? initValues = {};
          if (group != null) {
            initValues = groupController.getInitValue(groupColumnFieldDefs,
                entity: group);
          }
          return FormInputWidget(
            height: 220,
            onOk: (Map<String, dynamic> values) {
              _onOk(values).then((group) {
                if (group != null) {
                  DialogUtil.info(context,
                      content: 'Group ${group.name} is built');
                }
              });
            },
            columnFieldDefs: groupColumnFieldDefs,
            initValues: initValues,
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
      DialogUtil.error(context,
          content: AppLocalizations.t('Must has group name'));
      return null;
    }
    if (StringUtil.isEmpty(group.value.groupOwnerPeerId)) {
      DialogUtil.error(context,
          content: AppLocalizations.t('Must has group owner'));
      return null;
    }
    var current = groupController.current;
    if (current == null) {
      current = await groupService.createGroup(currentGroup.name);
      groupModified = true;
    }
    if (current.myAlias != currentGroup.myAlias) {
      current.myAlias = currentGroup.myAlias;
      groupModified = true;
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
    bool add = true;
    if (current.id != null) {
      add = false;
    }
    current.groupOwnerPeerId = group.value.groupOwnerPeerId ?? myself.peerId;
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
    }
    current.participants = groupMembers.value;
    GroupChange groupChange = await groupService.store(current);
    group.value = current;
    var groupId = current.peerId;

    //对所有的成员发送组变更的消息
    if (add) {
      await groupService.addGroup(current);
    } else {
      if (groupModified) {
        await groupService.modifyGroup(current);
      }
    }
    //新增加的成员
    List<GroupMember>? newMembers = groupChange.addGroupMembers;
    if (newMembers is List<GroupMember> && newMembers.isNotEmpty) {
      //对增加的成员发送群消息
      List<String> peerIds = [];
      for (var newMember in newMembers) {
        peerIds.add(newMember.memberPeerId!);
      }

      //对原有的成员发送加成员消息
      await groupService.addGroupMember(current.peerId, newMembers);
    }

    List<GroupMember>? oldMembers = groupChange.removeGroupMembers;
    //处理删除的成员
    if (oldMembers is List<GroupMember> && oldMembers.isNotEmpty) {
      //对所有的成员发送组员删除的消息
      await groupService.removeGroupMember(groupId, oldMembers);
    }

    if (groupController.current == null) {
      groupController.add(current);
    }
    if (add || groupModified) {
      groupChatSummaryController.refresh();
    }

    if (add) {
      setState(() {});
    }

    return current;
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Add group';
    int? id = group.value.id;
    if (id != null) {
      title = 'Edit group';
    }
    var appBarView = AppBarView(
        title: title,
        withLeading: widget.withLeading,
        child: _buildFormInputWidget(context));
    return appBarView;
  }

  @override
  void dispose() {
    groupController.removeListener(_update);
    controller.dispose();
    super.dispose();
  }
}
