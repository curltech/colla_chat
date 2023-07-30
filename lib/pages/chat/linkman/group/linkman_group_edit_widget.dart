import 'dart:typed_data';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/chat_summary.dart';
import 'package:colla_chat/entity/chat/group.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/chat_list_widget.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/linkman/group/group_edit_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/pages/chat/login/loading.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/group.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/loading_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';

///修改群，填写群的基本信息，选择群成员和群主
class LinkmanGroupEditWidget extends StatefulWidget with TileDataMixin {
  const LinkmanGroupEditWidget({Key? key}) : super(key: key);

  @override
  IconData get iconData => Icons.person;

  @override
  String get routeName => 'linkman_edit_group';

  @override
  String get title => 'Linkman edit group';

  @override
  bool get withLeading => true;

  @override
  State<StatefulWidget> createState() => _LinkmanGroupEditWidgetState();
}

class _LinkmanGroupEditWidgetState extends State<LinkmanGroupEditWidget> {
  @override
  initState() {
    super.initState();
  }

  Future<Group?> _findGroup() async {
    ChatSummary? chatSummary = chatMessageController.chatSummary;
    if (chatSummary != null) {
      String? partyType = chatSummary.partyType;
      String? groupId = chatSummary.peerId;
      if (partyType == PartyType.group.name && groupId != null) {
        return await groupService.findCachedOneByPeerId(groupId);
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    var appBarView = FutureBuilder(
        future: _findGroup(),
        builder: (BuildContext context, AsyncSnapshot<Group?> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            Group? group = snapshot.data;
            String title = 'Add group';
            if (group != null) {
              title = 'Edit group';
            }
            return AppBarView(
                title: title,
                withLeading: widget.withLeading,
                child: GroupEditWidget(key: UniqueKey(), group: group));
          }
          return LoadingUtil.buildCircularLoadingWidget();
        });
    return appBarView;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
