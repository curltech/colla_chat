import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/chart/k_chart/kline_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class KlineToolPanelWidget extends StatelessWidget {
  const KlineToolPanelWidget({super.key});

  Widget _buildToolPanelWidget(BuildContext context) {
    return Obx(() {
      List<Widget> btns = [
        Transform.scale(
            scale: 0.7,
            child: ToggleButtons(
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
              children: [
                Tooltip(
                    message: AppLocalizations.t('online'),
                    child: const Icon(Icons.book_online_outlined)),
                Tooltip(
                    message: AppLocalizations.t('offline'),
                    child: const Icon(Icons.offline_bolt_outlined))
              ],
            )),
        IconButton(
          onPressed: multiKlineController.lineType.value != 100
              ? () {
                  multiKlineController.lineType.value = 100;
                }
              : null,
          icon: Icon(
            Icons.lock_clock,
            color: multiKlineController.lineType.value == 100
                ? Colors.yellow
                : myself.primary,
          ),
          tooltip: AppLocalizations.t('minline'),
        ),
        IconButton(
          onPressed: multiKlineController.lineType.value != 101
              ? () {
                  multiKlineController.lineType.value = 101;
                }
              : null,
          icon: Icon(
            Icons.calendar_view_day_outlined,
            color: multiKlineController.lineType.value == 101
                ? Colors.yellow
                : myself.primary,
          ),
          tooltip: AppLocalizations.t('dayline'),
        ),
        IconButton(
          onPressed: multiKlineController.lineType.value != 102
              ? () {
                  multiKlineController.lineType.value = 102;
                }
              : null,
          icon: Icon(
            Icons.calendar_view_week_outlined,
            color: multiKlineController.lineType.value == 102
                ? Colors.yellow
                : myself.primary,
          ),
          tooltip: AppLocalizations.t('weekline'),
        ),
        IconButton(
          onPressed: multiKlineController.lineType.value != 103
              ? () {
                  multiKlineController.lineType.value = 103;
                }
              : null,
          icon: Icon(
            Icons.calendar_view_month_outlined,
            color: multiKlineController.lineType.value == 103
                ? Colors.yellow
                : myself.primary,
          ),
          tooltip: AppLocalizations.t('monthline'),
        ),
        IconButton(
          onPressed: multiKlineController.lineType.value != 104
              ? () {
                  multiKlineController.lineType.value = 104;
                }
              : null,
          icon: Icon(
            size: 22,
            Icons.perm_contact_calendar,
            color: multiKlineController.lineType.value == 104
                ? Colors.yellow
                : myself.primary,
          ),
          tooltip: AppLocalizations.t('qutarline'),
        ),
        IconButton(
          onPressed: multiKlineController.lineType.value != 105
              ? () {
                  multiKlineController.lineType.value = 105;
                }
              : null,
          icon: Icon(
            size: 22,
            Icons.calendar_month_outlined,
            color: multiKlineController.lineType.value == 105
                ? Colors.yellow
                : myself.primary,
          ),
          tooltip: AppLocalizations.t('halfyearline'),
        ),
        IconButton(
          onPressed: multiKlineController.lineType.value != 106
              ? () {
                  multiKlineController.lineType.value = 106;
                }
              : null,
          icon: Icon(
            size: 20,
            Icons.calendar_today_outlined,
            color: multiKlineController.lineType.value == 106
                ? Colors.yellow
                : myself.primary,
          ),
          tooltip: AppLocalizations.t('yearline'),
        ),
        IconButton(
          tooltip: AppLocalizations.t('Previous'),
          onPressed: () async {
            await multiKlineController.previous();
          },
          icon: Icon(Icons.skip_previous_outlined, color: myself.primary),
        ),
        IconButton(
            tooltip: AppLocalizations.t('Next'),
            onPressed: () async {
              await multiKlineController.next();
            },
            icon: Icon(Icons.skip_next_outlined, color: myself.primary)),
      ];

      return Row(
        children: btns,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildToolPanelWidget(context);
  }
}
