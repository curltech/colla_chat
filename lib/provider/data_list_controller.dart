import 'package:fluent_ui/fluent_ui.dart';

class DataListController<T> with ChangeNotifier {
  List<T> data = <T>[];
  int _currentIndex = 0;

  DataListController({List<T>? data}) {
    if (data != null && data.isNotEmpty) {
      this.data.addAll(data);
    }
  }

  T get current {
    return data[_currentIndex];
  }

  int get currentIndex {
    return _currentIndex;
  }

  set currentIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  add(List<T> ds) {
    if (ds.isNotEmpty) {
      data.addAll(ds);
      notifyListeners();
    }
  }

  T get(int index) {
    return data[index];
  }

  insert(int index, T d) {
    if (index >= 0 && index < data.length) {
      data.insert(index, d);
      notifyListeners();
    }
  }

  delete(int index) {
    if (index >= 0 && index < data.length) {
      data.removeAt(index);
      notifyListeners();
    }
  }

  update(int index, T d) {
    if (index >= 0 && index < data.length) {
      data[index] = d;
      notifyListeners();
    }
  }

  int get length => data.length;
}
