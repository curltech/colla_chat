import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/tool/entity_util.dart';
import 'package:colla_chat/tool/pagination_util.dart';
import 'package:flutter/material.dart';

///基础的数组数据控制器
class DataListController<T> with ChangeNotifier {
  Key key = UniqueKey();
  List<T> data = <T>[];
  int _currentIndex = -1;
  int? sortColumnIndex;
  String? sortColumnName;
  bool sortAscending = true;

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

  addAll(List<T> ds, {bool notify = true}) {
    if (ds.isNotEmpty) {
      _currentIndex = data.length;
      data.addAll(ds);
      if (notify) {
        notifyListeners();
      }
    }
  }

  add(T d, {bool notify = true}) {
    data.add(d);
    _currentIndex = data.length - 1;
    if (notify) {
      notifyListeners();
    }
  }

  T? get(int index) {
    if (index >= 0 && index < data.length) {
      return data[index];
    }

    return null;
  }

  insert(int index, T d) {
    if (index >= 0 && index <= data.length) {
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

  clear({bool notify = true}) {
    data.clear();
    _currentIndex = -1;
    if (notify) {
      notifyListeners();
    }
  }

  ///替换了当前的对象
  replace(T d) {
    if (_currentIndex > -1 && data.isNotEmpty) {
      data[_currentIndex] = d;
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

  move(int initialIndex, int finalIndex) {
    var mediaSource = data[initialIndex];
    data[initialIndex] = data[finalIndex];
    data[finalIndex] = mediaSource;
  }

  int get length => data.length;

  sort<S>(Comparable<S>? Function(T t) getFieldValue, int columnIndex,
      String columnName, bool ascending) {
    data.sort((T a, T b) {
      Comparable<S>? av = getFieldValue(a);
      Comparable<S>? bv = getFieldValue(b);
      if (ascending) {
        if (av == null) {
          return 0;
        }
        if (bv == null) {
          return 1;
        }
        return Comparable.compare(av, bv);
      } else {
        if (av == null) {
          return 1;
        }
        if (bv == null) {
          return 0;
        }
        return Comparable.compare(bv, av);
      }
    });

    _currentIndex = 0;
    sortColumnIndex = columnIndex;
    sortColumnName = columnName;
    sortAscending = ascending;
    notifyListeners();
  }

  List<T> get checked {
    List<T> checkedData = [];
    for (var t in data) {
      bool? checked = EntityUtil.getChecked(t);
      if (checked != null && checked) {
        checkedData.add(t);
      }
    }

    return checkedData;
  }
}

/// 分页数据控制器，记录了分页的信息
/// 页面迁移时，其中的数组的数据被换掉
class DataPageController<T> extends DataListController<T> {
  ///总行数
  int count;

  ///当前页的第一行的行号
  int offset = defaultOffset;

  ///每页行数
  int limit = defaultLimit;

  DataPageController({this.count = 0});

  reset() {
    sortColumnName = null;
    sortColumnIndex = null;
    sortAscending = true;
    count = 0;
    offset = defaultOffset;
    limit = defaultLimit;
    data.clear();
  }

  previous() {
    if (offset >= limit) {
      offset = offset - limit;
      notifyListeners();
    }
  }

  next() {
    if (offset + limit <= count) {
      offset = offset + limit;
      notifyListeners();
    }
  }

  first() {
    if (offset != 0) {
      offset = 0;
      notifyListeners();
    }
  }

  last() {
    int pageCount = PaginationUtil.getPageCount(count, limit);
    if (pageCount > 0) {
      offset = (pageCount - 1) * limit;
      notifyListeners();
    }
  }

  movePage(int index) {
    int currentPage = PaginationUtil.getCurrentPage(offset, limit);
    if (currentPage != index) {
      offset = index * limit;
      notifyListeners();
    }
  }
}

///更多数据的数据控制器
///支持通过more方法往数组中添加更多的数据
abstract class DataMoreController<T> extends DataListController<T> {
  DataMoreController({
    super.data,
    super.currentIndex,
  });

  ///取更多旧的数据，添加
  Future<int> previous({int? limit});

  ///取更多新的数据，添加
  Future<int> latest({int? limit});
}
