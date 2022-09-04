import 'package:colla_chat/l10n/localization.dart';
import 'package:flutter/material.dart';

import '../../constant/base.dart';

class DataSelect extends StatefulWidget {
  final String label;
  final String? hint;
  final List<Option> items;
  final String? initValue;
  final Function(String? value) onChanged;

  const DataSelect(
      {Key? key,
      required this.label,
      this.hint,
      required this.items,
      this.initValue,
      required this.onChanged})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _DataSelectState();
}

class _DataSelectState extends State<DataSelect> {
  String? value;

  @override
  void initState() {
    super.initState();
    value = widget.initValue;
  }

  List<DropdownMenuItem<String>> _buildMenuItems(BuildContext context) {
    List<DropdownMenuItem<String>> menuItems = [];
    for (var item in widget.items) {
      var label = AppLocalizations.t(item.label);
      var menuItem =
          DropdownMenuItem<String>(value: item.value, child: Text(label));
      menuItems.add(menuItem);
    }
    return menuItems;
  }

  @override
  Widget build(BuildContext context) {
    var menuItems = _buildMenuItems(context);
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Row(children: [
          Text(AppLocalizations.t(widget.label)),
          const Spacer(),
          DropdownButton<String>(
            dropdownColor: Colors.grey.withOpacity(0.7),
            underline: Container(),
            hint: Text(AppLocalizations.t(widget.hint ?? '')),
            elevation: 0,
            value: value,
            items: menuItems,
            onChanged: (String? value) {
              setState(() {
                this.value = value;
              });
              widget.onChanged(value);
            },
          ),
        ]));
  }
}
