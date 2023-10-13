import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:flutter/material.dart';

///基础的数组数据控制器
class DataListController<T> with ChangeNotifier {
  Key key = UniqueKey();
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
    if (_currentIndex > -1 && data.isNotEmpty) {
      return data[_currentIndex];
    }
    return null;
  }

  set current(T? element) {
    if (element == null) {
      currentIndex = -1;
    } else {
      _currentIndex = data.indexOf(element);
      notifyListeners();
    }
  }

  int get currentIndex {
    return _currentIndex;
  }

  ///设置当前数据索引
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

  insertAll(int index, List<T> ds) {
    if (index >= 0 && index <= data.length) {
      data.insertAll(index, ds);
      _currentIndex = index;
      notifyListeners();
    }
  }

  delete({int? index}) {
    index = index ?? _currentIndex;
    if (index >= 0 && index < data.length) {
      data.removeAt(index);
      if (data.isEmpty) {
        _currentIndex = -1;
      } else if (index == 0) {
        _currentIndex = 0;
      } else {
        _currentIndex = index - 1;
      }
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

  clear({bool? notify}) {
    data.clear();
    _currentIndex = -1;
    if (notify == null || notify) {
      notifyListeners();
    }
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

  sort(String name, bool sortAscending) {
    if (sortAscending) {
      data.sort((a, b) {
        var aMap = JsonUtil.toJson(a);
        var bMap = JsonUtil.toJson(b);
        return aMap[name].compareTo(bMap[name]);
      });
    } else {
      data.sort((a, b) {
        var aMap = JsonUtil.toJson(a);
        var bMap = JsonUtil.toJson(b);
        return bMap[name].compareTo(aMap[name]);
      });
    }
    _currentIndex = 0;
    notifyListeners();
  }
}

///分页数据控制器，记录了分页的信息
///页面迁移时，其中的数组的数据被换掉
abstract class DataPageController<T> with ChangeNotifier {
  late Pagination<T> pagination;
  int _currentIndex = -1;

  DataPageController() {
    pagination = Pagination<T>(data: <T>[], rowsNumber: -1);
    first();
  }

  T? get current {
    if (_currentIndex > -1) {
      return pagination.data[_currentIndex];
    }
    return null;
  }

  int get currentIndex {
    return _currentIndex;
  }

  set currentIndex(int index) {
    if (index < -1 || index > pagination.data.length - 1) {
      return;
    }
    if (_currentIndex != index) {
      _currentIndex = index;
    }
  }

  addAll(List<T> ds) {
    if (ds.isNotEmpty) {
      _currentIndex = pagination.data.length;
      pagination.data.addAll(ds);
      notifyListeners();
    }
  }

  add(T d) {
    pagination.data.add(d);
    _currentIndex = pagination.data.length - 1;
    notifyListeners();
  }

  T get(int index) {
    return pagination.data[index];
  }

  insert(int index, T d) {
    if (index >= 0 && index < pagination.data.length) {
      pagination.data.insert(index, d);
      _currentIndex = index;
      notifyListeners();
    }
  }

  delete({int? index}) {
    index = index ?? _currentIndex;
    if (index >= 0 && index < pagination.data.length) {
      pagination.data.removeAt(index);
      _currentIndex = index - 1;
      notifyListeners();
    }
  }

  update(T d, {int? index}) {
    index = index ?? _currentIndex;
    if (index >= 0 && index < pagination.data.length) {
      pagination.data[index] = d;
      notifyListeners();
    }
  }

  clear() {
    pagination.data.clear();
    _currentIndex = -1;
    notifyListeners();
  }

  replaceAll(List<T> ds) {
    pagination.data.clear();
    pagination.data.addAll(ds);
    if (ds.isNotEmpty) {
      _currentIndex = 0;
    }
    notifyListeners();
  }

  int get length => pagination.data.length;

  Map<String, dynamic>? getInitValue(List<PlatformDataField> inputFieldDefs) {
    T? current = this.current;
    if (current != null) {
      var currentMap = JsonUtil.toJson(current);
      Map<String, dynamic> values = {};
      for (var inputFieldDef in inputFieldDefs) {
        String name = inputFieldDef.name;
        var value = currentMap[name];
        if (value != null) {
          values[name] = value;
        }
      }
      return values;
    }
    return null;
  }

  sort(String name, bool sortAscending) {
    if (sortAscending) {
      pagination.data.sort((a, b) {
        var aMap = JsonUtil.toJson(a);
        var bMap = JsonUtil.toJson(b);
        return aMap[name].compareTo(bMap[name]);
      });
    } else {
      pagination.data.sort((a, b) {
        var aMap = JsonUtil.toJson(a);
        var bMap = JsonUtil.toJson(b);
        return bMap[name].compareTo(aMap[name]);
      });
    }
    _currentIndex = 0;
    notifyListeners();
  }

  ///总页数
  int get pagesNumber {
    return pagination.pagesNumber;
  }

  int get limit {
    return pagination.rowsPerPage;
  }

  int get page {
    return pagination.page;
  }

  set page(int page) {
    if (page > 0) {
      pagination.page = page;
    }
  }

  Future<bool> previous();

  Future<bool> next();

  Future<bool> first();

  Future<bool> last();

  Future<bool> move(int index);
}

///更多数据的数据控制器
///支持通过more方法往数组中添加更多的数据
abstract class DataMoreController<T> extends DataListController<T> {
  DataMoreController({
    List<T>? data,
    int? currentIndex,
  }) : super(data: data, currentIndex: currentIndex);

  ///取更多旧的数据，添加
  Future<int> previous({int? limit});

  ///取更多新的数据，添加
  Future<int> latest({int? limit});
}
