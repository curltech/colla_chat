import 'package:colla_chat/tool/util.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../widgets/common/input_field_widget.dart';

class DataListController<T> with ChangeNotifier {
  List<T> data = <T>[];
  int _currentIndex = -1;

  DataListController({List<T>? data, int? currentIndex}) {
    if (data != null && data.isNotEmpty) {
      this.data.addAll(data);
      if (currentIndex == null) {
        _currentIndex = 0;
      } else {
        if (currentIndex < -1 || currentIndex > data.length - 1) {
          _currentIndex = 0;
        } else {
          _currentIndex = currentIndex;
        }
      }
    }
  }

  T? get current {
    if (_currentIndex > -1) {
      return data[_currentIndex];
    }
    return null;
  }

  int get currentIndex {
    return _currentIndex;
  }

  set currentIndex(int index) {
    if (index < -1 || index > data.length - 1) {
      return;
    }
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  addAll(List<T> ds) {
    if (ds.isNotEmpty) {
      _currentIndex = data.length;
      data.addAll(ds);
      notifyListeners();
    }
  }

  add(T d) {
    data.add(d);
    _currentIndex = data.length - 1;
    notifyListeners();
  }

  T get(int index) {
    return data[index];
  }

  insert(int index, T d) {
    if (index >= 0 && index < data.length) {
      data.insert(index, d);
      _currentIndex = index;
      notifyListeners();
    }
  }

  delete({int? index}) {
    index = index ?? _currentIndex;
    if (index >= 0 && index < data.length) {
      data.removeAt(index);
      _currentIndex = index - 1;
      notifyListeners();
    }
  }

  update(T d, {int? index}) {
    index = index ?? _currentIndex;
    if (index >= 0 && index < data.length) {
      data[index] = d;
      notifyListeners();
    }
  }

  clear() {
    data.clear();
    _currentIndex = -1;
    notifyListeners();
  }

  replaceAll(List<T> ds) {
    data.clear();
    data.addAll(ds);
    if (ds.isNotEmpty) {
      _currentIndex = 0;
    }
    notifyListeners();
  }

  int get length => data.length;

  setInitValue(List<InputFieldDef> inputFieldDefs) {
    T? current = this.current;
    if (current != null) {
      var currentMap = JsonUtil.toMap(current);
      for (var inputFieldDef in inputFieldDefs) {
        String name = inputFieldDef.name;
        var value = currentMap[name];
        if (value != null) {
          inputFieldDef.initValue = '$value';
        } else {
          inputFieldDef.initValue = '';
        }
      }
    }
  }
}
