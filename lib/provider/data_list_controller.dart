import 'package:fluent_ui/fluent_ui.dart';

class DataListController<T> with ChangeNotifier {
  final List<T> data;
  int _currentIndex = 0;

  DataListController({this.data = const []});

  T getData(int index) {
    return data[index];
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

  int get length => data.length;
}
