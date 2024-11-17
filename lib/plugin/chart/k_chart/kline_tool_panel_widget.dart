import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/chart/k_chart/kline_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:flutter/material.dart';

class KlineToolPanelWidget extends StatelessWidget {
  const KlineToolPanelWidget({super.key});

  Widget _buildToolPanelWidget(BuildContext context) {
    List<Widget> btns = [
      ToggleButtons(
        color: Colors.grey,
        selectedColor: Colors.white,
        fillColor: myself.primary,
        borderRadius: borderRadius,
        onPressed: (int value) {
          multiKlineController.online.value = value == 0 ? true : false;
        },
        isSelected: [
          multiKlineController.online.value,
          !multiKlineController.online.value
        ],
        children: const [
          Icon(Icons.book_online_outlined),
          Icon(Icons.offline_bolt_outlined)
        ],
      ),
      IconButton(
        onPressed: () {
          multiKlineController.lineType.value = 100;
        },
        icon: Icon(
          Icons.lock_clock,
          color: myself.primary,
        ),
      ),
      IconButton(
        onPressed: () {
          multiKlineController.lineType.value = 101;
        },
        icon: Icon(
          Icons.calendar_view_day_outlined,
          color: myself.primary,
        ),
      ),
      IconButton(
        onPressed: () {
          multiKlineController.lineType.value = 102;
        },
        icon: Icon(
          Icons.calendar_view_week_outlined,
          color: myself.primary,
        ),
      ),
      IconButton(
        onPressed: () {
          multiKlineController.lineType.value = 103;
        },
        icon: Icon(
          Icons.calendar_view_month_outlined,
          color: myself.primary,
        ),
      ),
      IconButton(
        onPressed: () {
          multiKlineController.lineType.value = 104;
        },
        icon: Icon(
          size: 22,
          Icons.perm_contact_calendar,
          color: myself.primary,
        ),
      ),
      IconButton(
        onPressed: () {
          multiKlineController.lineType.value = 105;
        },
        icon: Icon(
          size: 22,
          Icons.calendar_month_outlined,
          color: myself.primary,
        ),
      ),
      IconButton(
        onPressed: () {
          multiKlineController.lineType.value = 106;
        },
        icon: Icon(
          size: 20,
          Icons.calendar_today_outlined,
          color: myself.primary,
        ),
      ),
      IconButton(
          tooltip: AppLocalizations.t('Previous'),
          onPressed: () async {
            await multiKlineController.previous();
          },
          icon: const Icon(Icons.skip_previous_outlined)),
      IconButton(
          tooltip: AppLocalizations.t('Next'),
          onPressed: () async {
            await multiKlineController.next();
          },
          icon: const Icon(Icons.skip_next_outlined)),
    ];

    return Row(
      children: btns,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildToolPanelWidget(context);
  }
}
