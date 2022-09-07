import 'package:colla_chat/entity/chat/contact.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_awesome_select/flutter_awesome_select.dart';

final List<ColumnFieldDef> groupColumnFieldDefs = [
  ColumnFieldDef(
      name: 'id',
      label: 'id',
      dataType: DataType.int,
      prefixIcon: const Icon(Icons.perm_identity)),
  ColumnFieldDef(
      name: 'name', label: 'name', prefixIcon: const Icon(Icons.person)),
  ColumnFieldDef(
      name: 'peerId',
      label: 'peerId',
      prefixIcon: const Icon(Icons.perm_identity)),
  ColumnFieldDef(
      name: 'alias', label: 'alias', prefixIcon: const Icon(Icons.person_pin)),
  ColumnFieldDef(
      name: 'myAlias',
      label: 'myAlias',
      prefixIcon: const Icon(Icons.person_pin)),
  ColumnFieldDef(
      name: 'description',
      label: 'description',
      prefixIcon: const Icon(Icons.note)),
];

///增加群
class GroupAddWidget extends StatefulWidget with TileDataMixin {
  final DataListController<Linkman> controller = DataListController<Linkman>();

  GroupAddWidget({Key? key}) : super(key: key);

  @override
  Icon get icon => const Icon(Icons.person_add);

  @override
  String get routeName => 'group_add';

  @override
  String get title => 'GroupAdd';

  @override
  bool get withLeading => true;

  @override
  State<StatefulWidget> createState() => _GroupAddWidgetState();
}

class _GroupAddWidgetState extends State<GroupAddWidget> {
  List<String> selectedLinkmen = [];

  @override
  initState() {
    super.initState();
    widget.controller.addListener(_update);
    linkmanService.findAll().then((List<Linkman> linkmen) {
      if (linkmen.isNotEmpty) {
        widget.controller.addAll(linkmen);
      }
    });
  }

  _update() {
    setState(() {});
  }

  Widget _buildFormInputWidget(BuildContext context) {
    var initValues = widget.controller.getInitValue(groupColumnFieldDefs);
    var formInputWidget = FormInputWidget(
      onOk: (Map<String, dynamic> values) {
        _onOk(values);
      },
      columnFieldDefs: groupColumnFieldDefs,
      initValues: initValues,
    );

    return formInputWidget;
  }

  _onOk(Map<String, dynamic> values) {
    Group group = Group.fromJson(values);
    groupService.upsert(group).then((count) {});
  }

  Widget _buildSelect(BuildContext context) {
    List<Linkman> linkmen = widget.controller.data;
    List<S2Choice<String>> choiceItems = [];
    for (Linkman linkman in linkmen) {
      S2Choice<String> item =
          S2Choice<String>(value: linkman.peerId, title: linkman.name);
      choiceItems.add(item);
    }

    return SmartSelect<String>.multiple(
      title: 'Linkmen',
      placeholder: 'Select one or more linkman',
      selectedValue: selectedLinkmen,
      onChange: (selected) => setState(() => selectedLinkmen = selected.value),
      choiceItems: choiceItems,
      modalType: S2ModalType.bottomSheet,
      tileBuilder: (context, state) {
        return S2Tile.fromState(
          state,
          isTwoLine: true,
          leading: const Icon(Icons.person_add_alt),
          body: S2TileChips(
            chipLength: state.selected.length,
            chipLabelBuilder: (context, i) {
              return Text(state.selected.title![i]);
            },
            chipOnDelete: (i) {
              setState((){});
            },
            chipColor:appDataProvider.themeData.colorScheme.primary,
          ),
        );
      },

    );
  }

  Widget _buildGroupAdd(BuildContext context) {
    return Column(
      children: [
        _buildFormInputWidget(context),
        const SizedBox(
          height: 5,
        ),
        _buildSelect(context)
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var appBarView = AppBarView(
        title: Text(AppLocalizations.t(widget.title)),
        withLeading: widget.withLeading,
        child: _buildGroupAdd(context));
    return appBarView;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }
}
