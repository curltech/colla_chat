import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_text_form_field.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent_ui;
import 'package:flutter/material.dart';

/// 把go代码转换成dart
class GoCodeWidget extends StatefulWidget with TileDataMixin {
  GoCodeWidget({super.key});

  @override
  State<StatefulWidget> createState() => _GoCodeWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'go_code';

  @override
  IconData get iconData => Icons.run_circle_outlined;

  @override
  String get title => 'GoCode';
}

class _GoCodeWidgetState extends State<GoCodeWidget>
    with TickerProviderStateMixin {
  final TextEditingController _goTextController = TextEditingController();

  @override
  initState() {
    super.initState();
  }

  transfer() {
    String goCode = _goTextController.text;
    List<String> lines = goCode.split('\n');
    String codes = '';
    String fromJson = '';
    String toJson = '';
    for (String line in lines) {
      line = line
          .trim()
          .replaceAll('  ', ' ')
          .replaceAll('  ', ' ')
          .replaceAll('  ', ' ')
          .replaceAll('  ', ' ')
          .replaceAll('  ', ' ');
      List<String> sources = line.split(' ');
      String name = sources[0].trim().lowercaseFirst();
      String type = sources[1].trim();
      if (type == 'float64') {
        type = 'double';
      } else if (type == 'int64') {
        type = 'int';
      } else if (type == 'string') {
        type = 'String';
      }
      String json = sources[2].trim();
      int start = json.indexOf('"');
      int end = json.lastIndexOf('"');
      json = json.substring(start + 1, end);
      String code = '$type? $name;';
      codes = '$codes$code\n';
      fromJson = '$fromJson$name = json[\'$json\'],\n';
      toJson = '$toJson\'$json\': $name,\n';
    }

    String result = '$codes\n\n$fromJson\n\n$toJson';
    _goTextController.text = result;
  }

  Widget _buildTransferView(BuildContext context) {
    return SingleChildScrollView(
        child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
            child: CommonAutoSizeTextFormField(
              controller: _goTextController,
              keyboardType: TextInputType.text,
              minLines: 10,
              suffixIcon: IconButton(
                onPressed: () {
                  transfer();
                },
                icon: Icon(
                  Icons.transfer_within_a_station_outlined,
                  color: myself.primary,
                ),
              ),
            )));
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        title: widget.title,
        withLeading: true,
        child: _buildTransferView(context));
  }
}
