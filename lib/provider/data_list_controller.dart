import 'package:flutter/material.dart';

import '../constant/base.dart';
import '../datastore/datastore.dart';
import '../tool/util.dart';
import '../widgets/common/column_field_widget.dart';

///基础的数组数据控制器
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

  Map<String, dynamic>? getInitValue(List<ColumnFieldDef> inputFieldDefs) {
    T? current = this.current;
    if (current != null) {
      var currentMap = JsonUtil.toMap(current);
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
      data.sort((a, b) {
        var aMap = JsonUtil.toMap(a);
        var bMap = JsonUtil.toMap(b);
        return aMap[name].compareTo(bMap[name]);
      });
    } else {
      data.sort((a, b) {
        var aMap = JsonUtil.toMap(a);
        var bMap = JsonUtil.toMap(b);
        return bMap[name].compareTo(aMap[name]);
      });
    }
    _currentIndex = 0;
    notifyListeners();
  }
}

///分页数据控制器，记录了分页的信息
///页面迁移时，其中的数组的数据被换掉
abstract class DataPageController<T> extends DataListController<T> {
  ///总行数
  int rowsNumber;
  int offset = defaultOffset;

  ///每页的行数limit
  int rowsPerPage = 0;

  DataPageController({
    this.rowsNumber = 0,
    this.offset = 0,
    this.rowsPerPage = 10,
    List<T>? data,
    int? currentIndex,
  }) : super(data: data, currentIndex: currentIndex);

  ///总页数
  int get pagesNumber {
    return Pagination.getPagesNumber(rowsNumber, rowsPerPage);
  }

  int get limit {
    return rowsPerPage;
  }

  int get page {
    return Pagination.getPage(offset, rowsPerPage);
  }

  set page(int page) {
    if (page > 0) {
      offset = (page - 1) * rowsPerPage;
    }
  }

  ///上一页的offset
  int get previousOffset {
    if (offset < rowsPerPage) {
      return 0;
    }
    return offset - rowsPerPage;
  }

  ///下一页的offset
  int get nextOffset {
    var off = offset + rowsPerPage;
    if (off > rowsNumber) {
      return rowsNumber;
    }
    return off;
  }

  void previous();

  void next();

  void first();

  void last();

  void move(int index);
}

///更多数据的数据控制器
///支持通过more方法往数组中添加更多的数据
abstract class DataMoreController<T> extends DataListController<T> {
  int rowsNumber;
  int offset = defaultOffset;

  ///每页的行数limit
  int rowsPerPage = 0;

  DataMoreController({
    this.rowsNumber = 0,
    this.offset = 0,
    this.rowsPerPage = 10,
    List<T>? data,
    int? currentIndex,
  }) : super(data: data, currentIndex: currentIndex);

  ///对more模式的数据控制器来说，执行more操作就是offset从现有的data.length开始，
  ///limit取index-data.length+rowsPerPage,offset不变，limit变化
  int moreLimit(int index) {
    int diff = index - data.length;
    if (diff > 0) {
      int num = diff ~/ rowsPerPage;
      return (num + 1) * rowsPerPage;
    }
    return 0;
  }

  ///如果有更多数据添加，返回true，否则返回false
  bool more(int index);
}
