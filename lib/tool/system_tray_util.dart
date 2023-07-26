import 'dart:async';

import 'package:colla_chat/platform.dart';
import 'package:system_tray/system_tray.dart';

class SystemTrayUtil {
  final AppWindow _appWindow = AppWindow();
  final SystemTray _systemTray = SystemTray();
  final Menu _menuMain = Menu();
  final Menu _menuSimple = Menu();

  Timer? _timer;
  bool _toogleTrayIcon = true;

  bool _toogleMenu = true;

  Future<void> initSystemTray() async {
    String imagePath = 'assets/image/app.png';

    // We first init the systray menu and then add the menu entries
    await _systemTray.initSystemTray(iconPath: imagePath);
    _systemTray.setTitle("system tray");
    _systemTray.setToolTip("How to use system tray with Flutter");

    // handle system tray event
    _systemTray.registerSystemTrayEventHandler((eventName) {
      print("eventName: $eventName");
      if (eventName == kSystemTrayEventClick) {
        platformParams.windows
            ? _appWindow.show()
            : _systemTray.popUpContextMenu();
      } else if (eventName == kSystemTrayEventRightClick) {
        platformParams.windows
            ? _systemTray.popUpContextMenu()
            : _appWindow.show();
      }
    });

    await _menuMain.buildFrom(
      [
        MenuItemLabel(
          label: 'Change Context Menu',
          image: imagePath,
          onClicked: (menuItem) {
            print("Change Context Menu");

            _toogleMenu = !_toogleMenu;
            _systemTray.setContextMenu(_toogleMenu ? _menuMain : _menuSimple);
          },
        ),
        MenuSeparator(),
        MenuItemLabel(
            label: 'Show',
            image: imagePath,
            onClicked: (menuItem) => _appWindow.show()),
        MenuItemLabel(
            label: 'Hide',
            image: imagePath,
            onClicked: (menuItem) => _appWindow.hide()),
        MenuItemLabel(
          label: 'Start flash tray icon',
          image: imagePath,
          onClicked: (menuItem) {
            print("Start flash tray icon");

            _timer ??= Timer.periodic(
              const Duration(milliseconds: 500),
              (timer) {
                _toogleTrayIcon = !_toogleTrayIcon;
                _systemTray.setImage(_toogleTrayIcon ? "" : imagePath);
              },
            );
          },
        ),
        MenuItemLabel(
          label: 'Stop flash tray icon',
          image: imagePath,
          onClicked: (menuItem) {
            print("Stop flash tray icon");

            _timer?.cancel();
            _timer = null;

            _systemTray.setImage(imagePath);
          },
        ),
        MenuSeparator(),
        SubMenu(
          label: "Test API",
          image: imagePath,
          children: [
            SubMenu(
              label: "setSystemTrayInfo",
              image: imagePath,
              children: [
                MenuItemLabel(
                  label: 'setTitle',
                  image: imagePath,
                  onClicked: (menuItem) {
                    const String text = '';
                    print("click 'setTitle' : $text");
                    _systemTray.setTitle(text);
                  },
                ),
                MenuItemLabel(
                  label: 'setImage',
                  image: imagePath,
                  onClicked: (menuItem) {
                    String path = imagePath;
                    print("click 'setImage' : $path");
                    _systemTray.setImage(path);
                  },
                ),
                MenuItemLabel(
                  label: 'setToolTip',
                  image: imagePath,
                  onClicked: (menuItem) {
                    const String text = '';
                    print("click 'setToolTip' : $text");
                    _systemTray.setToolTip(text);
                  },
                ),
                MenuItemLabel(
                  label: 'getTitle',
                  image: imagePath,
                  onClicked: (menuItem) async {
                    String title = await _systemTray.getTitle();
                    print("click 'getTitle' : $title");
                  },
                ),
              ],
            ),
            MenuItemLabel(
                label: 'disabled Item',
                name: 'disableItem',
                image: imagePath,
                enabled: false),
          ],
        ),
        MenuSeparator(),
        MenuItemLabel(
          label: 'Set Item Image',
          onClicked: (menuItem) async {
            print("click 'SetItemImage'");

            String path = imagePath;

            await menuItem.setImage(path);
            print(
                "click name: ${menuItem.name} menuItemId: ${menuItem.menuItemId} label: ${menuItem.label} image: ${menuItem.image}");
          },
        ),
        MenuItemCheckbox(
          label: 'Checkbox 1',
          name: 'checkbox1',
          checked: true,
          onClicked: (menuItem) async {
            print("click 'Checkbox 1'");

            MenuItemCheckbox? checkbox1 =
                _menuMain.findItemByName<MenuItemCheckbox>("checkbox1");
            await checkbox1?.setCheck(!checkbox1.checked);

            MenuItemCheckbox? checkbox2 =
                _menuMain.findItemByName<MenuItemCheckbox>("checkbox2");
            await checkbox2?.setEnable(checkbox1?.checked ?? true);

            print(
                "click name: ${checkbox1?.name} menuItemId: ${checkbox1?.menuItemId} label: ${checkbox1?.label} checked: ${checkbox1?.checked}");
          },
        ),
        MenuItemCheckbox(
          label: 'Checkbox 2',
          name: 'checkbox2',
          onClicked: (menuItem) async {
            print("click 'Checkbox 2'");

            await menuItem.setCheck(!menuItem.checked);
            await menuItem.setLabel('');
            print(
                "click name: ${menuItem.name} menuItemId: ${menuItem.menuItemId} label: ${menuItem.label} checked: ${menuItem.checked}");
          },
        ),
        MenuItemCheckbox(
          label: 'Checkbox 3',
          name: 'checkbox3',
          checked: true,
          onClicked: (menuItem) async {
            print("click 'Checkbox 3'");

            await menuItem.setCheck(!menuItem.checked);
            print(
                "click name: ${menuItem.name} menuItemId: ${menuItem.menuItemId} label: ${menuItem.label} checked: ${menuItem.checked}");
          },
        ),
        MenuSeparator(),
        MenuItemLabel(
            label: 'Exit', onClicked: (menuItem) => _appWindow.close()),
      ],
    );

    await _menuSimple.buildFrom([
      MenuItemLabel(
        label: 'Change Context Menu',
        image: imagePath,
        onClicked: (menuItem) {
          print("Change Context Menu");

          _toogleMenu = !_toogleMenu;
          _systemTray.setContextMenu(_toogleMenu ? _menuMain : _menuSimple);
        },
      ),
      MenuSeparator(),
      MenuItemLabel(
          label: 'Show',
          image: imagePath,
          onClicked: (menuItem) => _appWindow.show()),
      MenuItemLabel(
          label: 'Hide',
          image: imagePath,
          onClicked: (menuItem) => _appWindow.hide()),
      MenuItemLabel(
        label: 'Exit',
        image: imagePath,
        onClicked: (menuItem) => _appWindow.close(),
      ),
    ]);

    _systemTray.setContextMenu(_menuMain);
  }
}
